# LibreOffice con escalado fraccionario

Con KDE Plasma 6 sobre Wayland, LibreOffice usa el plugin VCL **kf6/qt6** y se
ejecuta nativo en Wayland. En una pantalla con **escalado fraccionario** (el
monitor Xiaomi 4K está a 1,15) el marco de la ventana se ve bien pero el
contenido sale encogido; con escala entera (el portátil, a 1) no pasa. Es un
fallo de la integración Qt de LibreOffice con un *devicePixelRatio* no entero.

La solución es que LibreOffice vaya por **XWayland** (`QT_QPA_PLATFORM=xcb`).
KWin ya tiene `[Xwayland] Scale=1.15` y `Xft.dpi: 110`, así que se ve nítido y
del tamaño correcto, conservando el aspecto KDE.

## `libreoffice` — envoltorio

No hay ningún ajuste del perfil (`~/.config/libreoffice`) que sirva: Qt lee la
variable al arrancar, antes que el perfil. Pero todos los `.desktop` de la suite
(Writer, Calc, Impress…) ejecutan `libreoffice …`, y en el `PATH` de Plasma
`~/.local/bin` va antes que `/usr/bin`. Un envoltorio ahí lo cubre todo: menús,
asociaciones de ficheros y terminal, sin tocar el sistema ni otras apps Qt.

```sh
ln -s ~/src/linux-config/libreoffice/libreoffice ~/.local/bin/libreoffice
ln -s ~/src/linux-config/libreoffice/libreoffice ~/.local/bin/soffice
```

Hay que cerrar todas las ventanas de LibreOffice para que el cambio se aplique
(reutiliza la instancia en marcha).
