# linux-config

Personal files for linux config

## Tema global podxboq

Tema claro en blanco roto con acento verde salvia (`com.podxboq.desktop`).

- **Estilo de las aplicaciones**: QtCurve (AUR `qtcurve`), preset `qtcurve/podxboq.qtcurve`
- **Estilo de Plasma**: Breath Light (Manjaro)
- **Colores**: podxboq
- **Decoraciones de las ventanas**: Breeze, ajustes en `breeze/breezerc`
- **Tipos de letra**: Source Sans 3 10pt, JetBrains Mono 10pt
- **Iconos**: Breeze
- **Cursores**: Volantes light, 32px
- **Sonidos**: Ocean
- **Pantalla de bienvenida**: AccretionDisk (KDE Store, autor fbm224)

### Instalación

```sh
cp -r look-and-feel/podxboq ~/.local/share/plasma/look-and-feel/com.podxboq.desktop
cp colors/podxboq.colors ~/.local/share/color-schemes/
cp -r cursors/volantes_light_cursors ~/.icons/
cp qtcurve/podxboq.qtcurve ~/.config/qtcurve/stylerc
cp breeze/breezerc ~/.config/
cp -r splash/AccretionDisk ~/.local/share/plasma/look-and-feel/
plasma-apply-lookandfeel -a com.podxboq.desktop
```

El GIF de AccretionDisk (120 MB) no está en el repo por el límite de tamaño de GitHub: hay que descargarlo de la KDE Store y copiarlo a `~/.local/share/plasma/look-and-feel/AccretionDisk/contents/splash/images/BH_AccretionDisk_Sim_360_wide_16x9_1080.gif`.
