#!/usr/bin/env python3
"""Extrae estadísticas de uso de Claude Code para conky."""

import json
import glob
import os
import sys
from datetime import datetime, timedelta, timezone

WEEKLY_RESET_WEEKDAY = 3  # jueves (0=lunes)
WEEKLY_RESET_HOUR    = 6


def time_until(target: datetime) -> str:
    now = datetime.now(timezone.utc)
    diff = target - now
    if diff.total_seconds() <= 0:
        return "ya"
    total = int(diff.total_seconds())
    h, rem = divmod(total, 3600)
    m = rem // 60
    if h > 0:
        return f"{h}h {m:02d}m"
    return f"{m}m"


def next_thursday_reset() -> datetime:
    now = datetime.now(timezone.utc)
    days_ahead = (WEEKLY_RESET_WEEKDAY - now.weekday()) % 7
    if days_ahead == 0 and now.hour >= WEEKLY_RESET_HOUR:
        days_ahead = 7
    reset = now.replace(hour=WEEKLY_RESET_HOUR, minute=0, second=0, microsecond=0)
    reset += timedelta(days=days_ahead)
    return reset


def get_stats():
    today     = datetime.now(timezone.utc).date()
    week_ago  = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)

    msgs  = {'day': 0, 'week': 0, 'month': 0}
    tools = {'day': 0, 'week': 0, 'month': 0}
    tokens_today = 0

    sessions_dir = os.path.expanduser('~/.claude/projects')
    for jsonl in glob.glob(f'{sessions_dir}/**/*.jsonl', recursive=True):
        try:
            with open(jsonl) as f:
                for line in f:
                    obj = json.loads(line)
                    msg_type = obj.get('type')
                    if msg_type not in ('user', 'assistant'):
                        continue
                    ts = (obj.get('message', {}).get('timestamp')
                          or obj.get('timestamp'))
                    if not ts:
                        continue
                    d = datetime.fromisoformat(
                        ts.replace('Z', '+00:00')
                    ).date()
                    content  = obj.get('message', {}).get('content') or []
                    is_tool  = msg_type == 'assistant' and any(
                        isinstance(c, dict) and c.get('type') == 'tool_use'
                        for c in content
                    )
                    if msg_type == 'assistant' and d == today:
                        usage = obj.get('message', {}).get('usage') or {}
                        tokens_today += (usage.get('input_tokens', 0)
                                         + usage.get('output_tokens', 0))
                    if d == today:
                        msgs['day'] += 1
                        if is_tool: tools['day'] += 1
                    if d >= week_ago:
                        msgs['week'] += 1
                        if is_tool: tools['week'] += 1
                    if d >= month_ago:
                        msgs['month'] += 1
                        if is_tool: tools['month'] += 1
        except Exception:
            continue

    def fmt_tokens(n):
        if n >= 1_000_000: return f'{n/1_000_000:.1f}M'
        if n >= 1_000:     return f'{n/1_000:.0f}K'
        return str(n)

    print(f"Hoy    {msgs['day']:>4} & {tools['day']:>4}")
    print(f"Semana {msgs['week']:>4} & {tools['week']:>4}")
    print(f"Mes    {msgs['month']:>4} & {tools['month']:>4}")
    if tokens_today:
        print(f"Tokens {fmt_tokens(tokens_today):>6}")

    print(f"Reinicio {time_until(next_thursday_reset())}")


if __name__ == '__main__':
    try:
        get_stats()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        print("-- sin datos --")
