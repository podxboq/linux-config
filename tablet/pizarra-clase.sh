#!/usr/bin/env bash
# Pizarra para clases en directo.
# Pone la tablet en "modo clase" (No molestar, horizontal fijo, app de notas)
# y la muestra en una ventana del PC para compartir en la videoconferencia.
# Al cerrar devuelve la tablet a como estaba.
set -euo pipefail

TITULO="${1:-Pizarra}"
BITRATE="${PIZARRA_BITRATE:-12M}"
APP="${PIZARRA_APP:-com.samsung.android.app.notes/.memolist.MemoListActivity}"
DND="${PIZARRA_DND:-none}"        # none = silencio total | priority = deja pasar favoritos
# Recorta la barra de estado y la barra de tareas. Va en coordenadas NATURALES
# del panel (1320x2112), no en las de la imagen horizontal: scrcpy aplica el
# recorte antes de rotar, así que los ejes están transpuestos.
CROP="${PIZARRA_CROP:-1190:2112:50:0}"

ESTADO="${XDG_CACHE_HOME:-$HOME/.cache}/pizarra-clase.estado"

estado=$(adb get-state 2>/dev/null || echo ausente)
if [ "$estado" != "device" ]; then
    echo "La tablet no está lista para adb (estado: $estado)." >&2
    echo "  offline / unauthorized -> acepta el diálogo de depuración en la tablet" >&2
    echo "  ausente                -> revisa el cable y que la depuración USB siga activa" >&2
    adb devices -l >&2
    exit 1
fi

leer() { adb shell settings get "$1" "$2" 2>/dev/null | tr -d '\r'; }

# El estado previo se guarda en disco. Si una ejecución anterior murió sin
# restaurar, el fichero sigue ahí y NO lo sobrescribimos con el estado de
# clase: así el ajuste original nunca se pierde.
if [ -f "$ESTADO" ]; then
    # shellcheck disable=SC1090
    . "$ESTADO"
    echo "Aviso: una sesión anterior no llegó a restaurar la tablet."
    echo "       Se recupera el estado guardado entonces."
else
    PREV_AUTOROT=$(leer system accelerometer_rotation)
    PREV_ROT=$(leer system user_rotation)
    PREV_ZEN=$(leer global zen_mode)
    # Valores sensatos si el ajuste no estaba definido.
    case "$PREV_AUTOROT" in 0|1) :;; *) PREV_AUTOROT=1;; esac
    case "$PREV_ROT"     in 0|1|2|3) :;; *) PREV_ROT=0;; esac
    case "$PREV_ZEN"     in 0|1|2|3) :;; *) PREV_ZEN=0;; esac
    mkdir -p "$(dirname "$ESTADO")"
    printf 'PREV_AUTOROT=%s\nPREV_ROT=%s\nPREV_ZEN=%s\n' \
        "$PREV_AUTOROT" "$PREV_ROT" "$PREV_ZEN" > "$ESTADO"
fi

restaurar() {
    case "${PREV_ZEN:-0}" in
        1) adb shell cmd notification set_dnd priority >/dev/null 2>&1 || true;;
        2) adb shell cmd notification set_dnd none     >/dev/null 2>&1 || true;;
        3) adb shell cmd notification set_dnd alarms   >/dev/null 2>&1 || true;;
        *) adb shell cmd notification set_dnd off      >/dev/null 2>&1 || true;;
    esac
    adb shell settings put system user_rotation "${PREV_ROT:-0}"              >/dev/null 2>&1 || true
    adb shell settings put system accelerometer_rotation "${PREV_AUTOROT:-1}" >/dev/null 2>&1 || true
    adb shell svc power stayon false                                          >/dev/null 2>&1 || true
    rm -f "$ESTADO"
    echo
    echo "Tablet restaurada (No molestar y rotación como estaban)."
}
trap restaurar EXIT

# --- Modo clase ---
adb shell cmd notification set_dnd "$DND"              >/dev/null 2>&1 || true
adb shell settings put system accelerometer_rotation 0 >/dev/null 2>&1 || true
adb shell settings put system user_rotation 1          >/dev/null 2>&1 || true
adb shell svc power stayon usb                         >/dev/null 2>&1 || true
adb shell am start -n "$APP"                           >/dev/null 2>&1 || true

echo "Tablet:  $(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
echo "Modo clase: No molestar ($DND) · horizontal fijo · pantalla activa"
echo "Ventana: «$TITULO» — selecciónala al compartir pantalla"
echo "(Cierra la ventana para restaurar la tablet)"
echo

args=(--window-title "$TITULO" --no-control --no-audio
      --disable-screensaver --video-bit-rate "$BITRATE" --max-fps 60)
[ -n "$CROP" ] && args+=(--crop "$CROP")

# Sin 'exec': así el trap de restauración se ejecuta al cerrar scrcpy.
scrcpy "${args[@]}"
