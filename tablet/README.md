# Tablet como pizarra y digitalizadora

Configuración para usar una **Samsung Galaxy Tab S10 Lite (SM-X400)** con el
portátil Linux. Probado con Android 16 / One UI 8.5, KDE Plasma 6 sobre Wayland.

## Limitación de partida

La Tab S10 Lite **no puede enviar vídeo por USB-C**: su puerto es USB-C 2.0 sin
DisplayPort Alt Mode. No sirve como pantalla externa por cable, y los adaptadores
"USB-C a HDMI compatibles" que se venden para ella no funcionan. Tampoco soporta
DeX inalámbrico (sólo DeX en su propia pantalla).

Todo lo que sigue evita esa limitación: el vídeo viaja **de la tablet al PC**,
no al revés.

## `pizarra-clase.sh` — clases en directo

Pone la tablet en modo clase y la muestra en una ventana del PC que se comparte
en la videoconferencia. Se escribe en la tablet con el S Pen, a latencia nativa.

```sh
./pizarra-clase.sh [título-de-ventana]
```

Al arrancar: activa No molestar, mantiene la pantalla encendida y abre la app de
notas. Al cerrar la ventana lo revierte todo.

**La orientación no se toca**: la tablet queda como la coloques y scrcpy sigue
los giros automáticamente. En vertical, que es lo natural para escribir a mano,
la ventana queda alta y estrecha y en una videoconferencia 16:9 deja franjas a
los lados; en horizontal se llena el ancho pero aparecen las barras del sistema
en apps que no las oculten, y ahí entra el recorte que se explica más abajo.

### Variables de entorno

| Variable | Por defecto | Para qué |
|---|---|---|
| `PIZARRA_APP` | NoteIn | Actividad a lanzar (`paquete/.Actividad`) |
| `PIZARRA_DND` | `none` | `none` silencio total, `priority` deja pasar favoritos |
| `PIZARRA_CROP` | vacío | Recorte de barras (innecesario con NoteIn) |
| `PIZARRA_BITRATE` | `12M` | Calidad del vídeo |

Para averiguar la actividad de otra app:

```sh
adb shell cmd package resolve-activity --brief <paquete>
```

## Preparación de la tablet (una sola vez)

1. **Desactivar el bloqueo de USB**: Ajustes → Seguridad y privacidad →
   Bloqueador automático → desactivar *"Bloquear actualizaciones de software por
   cable USB"*. Sin esto la depuración USB aparece atenuada y no se puede activar.
2. **Opciones de desarrollador**: Ajustes → Acerca de la tablet → Información de
   software → pulsar 7 veces en *Número de compilación*.
3. **Depuración USB**: activarla ahí y aceptar el diálogo de autorización en la
   tablet marcando *Permitir siempre desde este equipo*.

Si se vuelve a activar el Bloqueador automático, la depuración se bloquea otra vez.

## Notas técnicas

**NoteIn no necesita recorte**: se dibuja a pantalla completa y oculta por su
cuenta la barra de estado y la de navegación. Samsung Notes sí las muestra.

**Si hace falta recortar, el `--crop` va en coordenadas naturales del panel, no
en las de la imagen que se ve.** scrcpy recorta antes de rotar, así que con la
tablet en horizontal los ejes quedan transpuestos: para quitar 50 px arriba y
80 px abajo de la imagen apaisada hay que recortar sobre la *x* natural
(`1190:2112:50:0`, panel de 1320x2112). Un recorte "intuitivo" falla con
`Crop Rect(...) exceeds the input area`.

**`policy_control` no sirve en Android 16.** Es el método clásico para el modo
inmersivo; el ajuste se guarda sin protestar pero no tiene ningún efecto. Por eso
la interfaz limpia se consigue recortando en el lado del PC.

**El estado previo del No molestar se guarda en `~/.cache/pizarra-clase.estado`.**
Si una sesión muere sin ejecutar su `trap` (cierre de sesión, tirón del cable),
el fichero sobrevive y la siguiente ejecución lo respeta en lugar de tomar el
modo clase como si fuera la configuración normal. Sin esto, el ajuste original
se perdería de forma silenciosa y permanente. Por el mismo motivo, no conviene
borrar ese fichero a mano mientras haya una sesión abierta.

**`--no-control`** deja la ventana en sólo lectura: un clic accidental del ratón
durante la clase no puede pintar en la tablet.

## Digitalizadora para corregir (pendiente de montar)

Para anotar PDFs desde el PC con el S Pen: **weylus** sirve el escritorio a la
tablet y devuelve los eventos del lápiz. Por cable se encapsula con
`adb reverse tcp:1701 tcp:1701` y `tcp:9001`, de modo que no depende de la Wi-Fi.
Weylus escucha en `0.0.0.0`, así que conviene arrancarlo siempre con
`--access-code`.

El S Pen es Wacom EMR con 4096 niveles de presión e inclinación, sin batería.
Queda por verificar que la presión llega hasta las aplicaciones (Xournal++, Krita).
