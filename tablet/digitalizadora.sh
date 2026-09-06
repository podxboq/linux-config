#!/usr/bin/env bash
# La tablet + S Pen como digitalizadora del portátil, vía weylus.
# Pensado para anotar PDFs en Xournal++ (corregir actividades y exámenes).
#
#   ./digitalizadora.sh            modo Wi-Fi (por defecto)
#   ./digitalizadora.sh cable      encapsula el tráfico por USB (adb reverse)
#
# Variables: LAPIZ_CODE=xxx  añade código de acceso (sin él, cualquiera de la
#            red local puede abrir la página).
set -euo pipefail

MODO="${1:-wifi}"
WEB="${LAPIZ_WEB_PORT:-1701}"
WS="${LAPIZ_WS_PORT:-9001}"
CODE="${LAPIZ_CODE:-}"

args=(--no-gui --wayland-support --web-port "$WEB" --websocket-port "$WS")
if [ -n "$CODE" ]; then args+=(--access-code "$CODE"); fi

case "$MODO" in
  cable|--cable)
    estado=$(adb get-state 2>/dev/null || echo ausente)
    if [ "$estado" != "device" ]; then
        echo "La tablet no está lista para adb (estado: $estado)." >&2
        adb devices -l >&2
        exit 1
    fi
    adb reverse tcp:"$WEB" tcp:"$WEB" >/dev/null
    adb reverse tcp:"$WS"  tcp:"$WS"  >/dev/null
    trap 'adb reverse --remove-all >/dev/null 2>&1 || true' EXIT
    URL="http://localhost:$WEB"
    echo "Modo cable: el tráfico va por USB, no por la red."
    ;;
  *)
    IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
    [ -n "$IP" ] || { echo "No se pudo determinar la IP local." >&2; exit 1; }
    URL="http://$IP:$WEB"
    echo "Modo Wi-Fi: la tablet y el portátil deben estar en la misma red."
    ;;
esac

echo "Abre en la tablet:  $URL"
if [ -n "$CODE" ]; then echo "Código de acceso:   $CODE"; fi
echo "(Ctrl-C para terminar)"
echo
echo "En la interfaz de weylus: activa el vídeo, elige la pantalla donde tengas"
echo "Xournal++ y marca Stylus."
echo

weylus "${args[@]}"
