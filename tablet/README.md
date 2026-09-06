# Tablet como pizarra y para corregir

Configuración para usar una **Samsung Galaxy Tab S10 Lite (SM-X400)** con el
portátil. Probado con Android 16 / One UI 8.5, KDE Plasma 6 sobre Wayland.

## Limitación de partida

La Tab S10 Lite **no puede enviar vídeo por USB-C**: su puerto es USB-C 2.0 sin
DisplayPort Alt Mode. No sirve como pantalla externa, y los adaptadores "USB-C a
HDMI compatibles" que se venden para ella no funcionan. Tampoco soporta DeX
inalámbrico.

De ahí el enfoque de todo lo que hay aquí: **la tablet trabaja como dispositivo
autónomo**, no como periférico del PC. Escribe con su propio lápiz, a latencia
nativa, y lo que viaja son archivos o vídeo hacia el PC — nunca los trazos.

## Preparación de la tablet (una sola vez)

1. **Desactivar el bloqueo de USB**: Ajustes → Seguridad y privacidad →
   Bloqueador automático → desactivar *"Bloquear actualizaciones de software por
   cable USB"*. Sin esto la depuración USB aparece atenuada y no se puede activar.
2. **Opciones de desarrollador**: Ajustes → Acerca de la tablet → Información de
   software → pulsar 7 veces en *Número de compilación*.
3. **Depuración USB**: activarla y aceptar el diálogo en la tablet marcando
   *Permitir siempre desde este equipo*.

Si se reactiva el Bloqueador automático, la depuración se bloquea otra vez.

## `pizarra-clase.sh` — clases en directo

Pone la tablet en modo clase y la muestra en una ventana del PC que se comparte
en la videoconferencia. Se escribe en la tablet con el S Pen.

```sh
./pizarra-clase.sh [título-de-ventana]
```

Activa No molestar, mantiene la pantalla encendida y abre la app de notas; al
cerrar la ventana lo revierte. **La orientación no se toca**: la tablet queda
como la coloques y scrcpy sigue los giros.

| Variable | Por defecto | Para qué |
|---|---|---|
| `PIZARRA_APP` | NoteIn | Actividad a lanzar (`paquete/.Actividad`) |
| `PIZARRA_DND` | `none` | `none` silencio total, `priority` deja pasar favoritos |
| `PIZARRA_CROP` | vacío | Recorte de barras (innecesario con NoteIn) |
| `PIZARRA_BITRATE` | `12M` | Calidad del vídeo |

## `corregir.sh` — corregir actividades y exámenes

Mueve PDFs entre el portátil y la tablet. Se corrige a mano en NoteIn, con
presión real y sin latencia.

```sh
./corregir.sh up   trabajo.pdf     # lo envía a la tablet y abre NoteIn
./corregir.sh down trabajo.pdf     # trae de vuelta el corregido
```

Carpeta de trabajo en la tablet: `/sdcard/Download` (ajustable con
`CORREGIR_DIR`). En `down`, si ya existe un fichero con ese nombre en el
directorio actual —lo normal, es el original— **no lo sobrescribe**: guarda como
`trabajo-corregido.pdf`. Si el fichero no está en la tablet, lista los que sí hay.

`up` abre NoteIn pero no el documento: Android bloquea las URIs `file://` en los
intents desde Android 7, así que abrir el PDF directamente no es fiable.

### Calibración de NoteIn para que el PDF exportado se lea bien

Medido sobre exportaciones reales, normalizando a A4:

- **Márgenes**: desactivar los márgenes extra al exportar. Con ellos la línea
  útil era de 140 mm; sin ellos, 176 mm (unos 60 caracteres por línea, el rango
  óptimo de lectura).
- **Grosor**: el bolígrafo de 0,5 da un trazo de 0,50 mm con minúsculas de
  4,8 mm, o sea 1/10 — correcto, no hace falta tocarlo.
- **Zoom**: no controla la densidad. Al ampliar, la rejilla de puntos y la letra
  crecen por igual y el resultado en la página es el mismo. Lo que sí la
  controla es **cuántos puntos de la rejilla se dejan entre renglones**: los
  puntos están cada 6,3 mm, y escribir cada 2 (12,7 mm) da 23 líneas por A4
  frente a las 19 de escribir cada 2,4.

El exportador de NoteIn declara páginas de 1240x1754 pt (A4 a escala 2,08x). En
pantalla da igual, pero si se imprime "a tamaño real" se parte en varias hojas.

## Notas técnicas

**NoteIn no necesita recorte**: se dibuja a pantalla completa y oculta la barra
de estado y la de navegación. Samsung Notes sí las muestra.

**Si hace falta recortar, el `--crop` de scrcpy va en coordenadas naturales del
panel, no en las de la imagen visible.** Recorta antes de rotar, así que con la
tablet en horizontal los ejes quedan transpuestos: para quitar 50 px arriba y
80 px abajo hay que recortar sobre la *x* natural (`1190:2112:50:0`, panel de
1320x2112). Un recorte "intuitivo" falla con `Crop Rect(...) exceeds the input area`.

**`policy_control` no sirve en Android 16.** Es el método clásico para el modo
inmersivo; el ajuste se guarda sin protestar pero no tiene ningún efecto.

**El estado previo del No molestar se guarda en `~/.cache/pizarra-clase.estado`.**
Si una sesión muere sin ejecutar su `trap`, el fichero sobrevive y la siguiente
ejecución lo respeta en lugar de tomar el modo clase como configuración normal.
No conviene borrarlo a mano mientras haya una sesión abierta.

## `digitalizadora.sh` — descartado, no usar

Usa **weylus** para convertir la tablet en digitalizadora del PC y anotar con
Xournal++. Se deja documentado porque la idea es razonable, pero **no funciona
bien en esta configuración**:

- El trazo aterriza **desplazado**: weylus mapea la superficie de la tablet
  contra la pantalla capturada, y la escala fraccionaria de 1,15 en DP-1
  descuadra la conversión entre coordenadas lógicas y físicas.
- **No se puede corregir el mapeo desde KDE**: su configurador de tabletas usa
  `libwacom`, que identifica modelos reales por vendor/product ID y no reconoce
  dispositivos virtuales. El KCM responde "No se han encontrado tabletas".
- Compartir una ventana en lugar de la pantalla **no lo arregla**: la entrada no
  viaja por la captura, sino por un dispositivo uinput cuyo mapeo decide KWin.

Lo que sí funciona, por si se retoma en otra máquina: weylus crea un dispositivo
con presión e inclinación reales (`ABS_PRESSURE`, `ABS_TILT_X/Y`), udev lo
etiqueta `ID_INPUT_TABLET=1`, y midiendo los eventos llegan **614 valores
distintos de presión a 51 Hz**. La señal es buena; el problema es dónde aterriza.

Requiere abrir los puertos 1701 y 9001 en el cortafuegos, y hay **dos tablas
independientes** con política `drop` (`ip filter` de iptables-nft y `inet filter`
de nftables): abrir sólo una no sirve de nada.
