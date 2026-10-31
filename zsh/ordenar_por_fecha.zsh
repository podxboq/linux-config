#!/usr/bin/env zsh
# Mueve fotos y vídeos a carpetas AAAA/MM según su fecha de creación (metadatos).
#
# Uso: ordenar_por_fecha.zsh [-n] [directorio]
#   -n           simulación: muestra lo que haría sin mover nada
#   directorio   si se indica, se procesa de forma recursiva (con todos sus
#                subdirectorios). Sin él, solo los ficheros del directorio
#                actual, sin entrar en subdirectorios.
#
# Las carpetas AAAA/MM se crean siempre en el directorio desde el que se
# ejecuta el script, no en el subdirectorio donde estaba cada fichero.
#
# Orden de búsqueda de la fecha:
#   1. Nombre del fichero con patrón AAAAMMDD (p. ej. IMG_20240811_122803.jpg)
#   2. Imágenes: Exif.Photo.DateTimeOriginal, Exif.Image.DateTime (exiv2)
#      Vídeos:   creation_time del contenedor (ffprobe, UTC -> hora local)
#   3. Fecha de modificación del fichero

emulate -L zsh
setopt extended_glob null_glob

dry_run=0
if [[ $1 == -n ]]; then
  dry_run=1
  shift
fi

recursivo=0
(( $# )) && recursivo=1
dir=${1:-.}
[[ -d $dir ]] || { print -u2 "No existe el directorio: $dir"; exit 1 }

for cmd in exiv2 ffprobe; do
  (( $+commands[$cmd] )) || { print -u2 "Falta el programa: $cmd"; exit 1 }
done

# Imprime la fecha como "AAAA MM" o nada si no la encuentra.
fecha_de() {
  local f=$1 d=""

  # 1. Fecha en el nombre del fichero (AAAAMMDD con mes y día válidos)
  if [[ ${f:t} =~ '((19|20)[0-9]{2})(0[1-9]|1[0-2])(0[1-9]|[12][0-9]|3[01])' ]]; then
    print -- "$match[1] $match[3]"; return
  fi

  # 2. Metadatos
  case ${f:e:l} in
    jpg|jpeg|png|heic|heif|tif|tiff|dng|webp)
      d=$(exiv2 -q -K Exif.Photo.DateTimeOriginal -Pv -- $f 2>/dev/null)
      [[ -z $d ]] && d=$(exiv2 -q -K Exif.Image.DateTime -Pv -- $f 2>/dev/null)
      ;;
    mp4|mov|m4v|3gp|mkv|avi)
      d=$(ffprobe -v quiet -show_entries format_tags=creation_time \
            -of default=nw=1:nk=1 -- $f 2>/dev/null)
      # creation_time viene en UTC: se convierte a hora local
      [[ -n $d ]] && d=$(date -d $d '+%Y:%m:%d' 2>/dev/null)
      ;;
  esac

  # Descarta fechas vacías o nulas (0000:00:00)
  if [[ $d == (#b)([12][0-9][0-9][0-9])[:-]([01][0-9])* && $match[2] != 00 ]]; then
    print -- "$match[1] $match[2]"; return
  fi

  # 3. Último recurso: fecha de modificación
  date -r $f '+%Y %m'
}

movidos=0 omitidos=0
if (( recursivo )); then
  ficheros=($dir/**/*(.))
else
  ficheros=($dir/*(.))
fi

for f in $ficheros; do
  case ${f:e:l} in
    jpg|jpeg|png|heic|heif|tif|tiff|dng|webp|mp4|mov|m4v|3gp|mkv|avi) ;;
    *) continue ;;
  esac

  read -r anio mes <<< "$(fecha_de $f)"
  destino=$PWD/$anio/$mes

  if [[ -e $destino/${f:t} ]]; then
    print -u2 "OMITIDO (ya existe): $destino/${f:t}"
    (( omitidos++ ))
    continue
  fi

  print -- "${f:t} -> $anio/$mes/"
  if (( ! dry_run )); then
    mkdir -p -- $destino && mv -n -- $f $destino/ || { (( omitidos++ )); continue }
  fi
  (( movidos++ ))
done

(( dry_run )) && print "Simulación: $movidos ficheros se moverían, $omitidos omitidos." \
              || print "Hecho: $movidos ficheros movidos, $omitidos omitidos."
