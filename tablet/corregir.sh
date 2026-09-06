#!/usr/bin/env bash
# Mueve PDFs entre el portátil y la tablet para corregirlos a mano con el S Pen.
#
#   ./corregir.sh up   trabajo.pdf    envía el PDF a la tablet y abre NoteIn
#   ./corregir.sh down trabajo.pdf    trae de vuelta el PDF corregido
#
# Variables: CORREGIR_DIR  carpeta de trabajo en la tablet (por defecto Download)
set -euo pipefail

DIR="${CORREGIR_DIR:-/sdcard/Download}"
APP="${PIZARRA_APP:-com.orion.notein.global/com.orion.notein.MainActivity}"

uso() {
    echo "Uso: $(basename "$0") up|down fichero.pdf" >&2
    echo "  up    envía el PDF del portátil a la tablet y abre NoteIn" >&2
    echo "  down  trae el PDF corregido de la tablet al directorio actual" >&2
    exit 1
}

[ $# -eq 2 ] || uso
ACCION="$1"
FICHERO="$2"
NOMBRE=$(basename "$FICHERO")

estado=$(adb get-state 2>/dev/null || echo ausente)
if [ "$estado" != "device" ]; then
    echo "La tablet no responde a adb (estado: $estado)." >&2
    echo "  Conecta el cable, o empareja por Wi-Fi con:  adb connect <ip>:5555" >&2
    exit 1
fi

case "$ACCION" in
  up)
    [ -f "$FICHERO" ] || { echo "No existe: $FICHERO" >&2; exit 1; }
    if ! salida=$(adb push "$FICHERO" "$DIR/$NOMBRE" 2>&1); then
        echo "Falló el envío:" >&2; echo "$salida" >&2; exit 1
    fi
    echo "Enviado a la tablet: $DIR/$NOMBRE"
    adb shell am start -n "$APP" >/dev/null 2>&1 || true
    echo "NoteIn abierto. Ábrelo desde la app y corrige con el S Pen."
    echo "Al terminar, exporta a PDF y recupéralo con:  $(basename "$0") down $NOMBRE"
    ;;
  down)
    adb shell "[ -f '$DIR/$NOMBRE' ]" 2>/dev/null || {
        echo "No está en la tablet: $DIR/$NOMBRE" >&2
        echo "PDFs disponibles allí:" >&2
        adb shell "ls -1 '$DIR'/*.pdf 2>/dev/null" 2>/dev/null | tr -d '\r' | sed 's|.*/|  |' >&2
        exit 1
    }
    # No sobrescribir el original en silencio.
    destino="$NOMBRE"
    if [ -e "$destino" ]; then
        destino="${NOMBRE%.*}-corregido.${NOMBRE##*.}"
        echo "Ya existe '$NOMBRE' aquí; se guarda como '$destino'."
    fi
    if ! salida=$(adb pull "$DIR/$NOMBRE" "$destino" 2>&1); then
        echo "Falló la descarga:" >&2; echo "$salida" >&2; exit 1
    fi
    echo "Recuperado: $destino"
    ;;
  *) uso;;
esac
