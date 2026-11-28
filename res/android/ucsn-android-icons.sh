#!/bin/bash
# Troca o icone do app Android pela logo UCSN (a mesma do Windows e do macOS).
#
# Uso: res/android/ucsn-android-icons.sh [icone.png] [pasta res do Android]
#
# Gera, a partir de res/icon.png:
# - ic_launcher.png / ic_launcher_round.png (Android 7 e anteriores)
# - ic_launcher_foreground.png (icone adaptativo do Android 8+, fundo branco
#   definido em values/ic_launcher_background.xml)
# Roda no Linux do GitHub Actions com ImageMagick.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="${1:-$SCRIPT_DIR/../icon.png}"
RES_DIR="${2:-$SCRIPT_DIR/../../flutter/android/app/src/main/res}"

[ -f "$ICON_SRC" ] || { echo "icone nao encontrado: $ICON_SRC" >&2; exit 1; }
[ -d "$RES_DIR" ] || { echo "pasta res nao encontrada: $RES_DIR" >&2; exit 1; }

if command -v magick >/dev/null 2>&1; then IM=magick
elif command -v convert >/dev/null 2>&1; then IM=convert
else
  sudo apt-get update -qq && sudo apt-get install -y -qq imagemagick
  IM=convert
fi

WORK="$(mktemp -d)"
# Remove a margem transparente da logo e deixa quadrada
# o \n no final evita que o read retorne erro (set -e) por falta de quebra de linha
read -r W H < <($IM "$ICON_SRC" -trim -format '%w %h\n' info:) || true
[ -n "${W:-}" ] && [ -n "${H:-}" ] || { echo "nao consegui ler o tamanho de $ICON_SRC" >&2; exit 1; }
M=$(( W > H ? W : H ))
$IM "$ICON_SRC" -trim +repage -background none -gravity center -extent "${M}x${M}" "$WORK/logo.png"

# densidade  launcher(48dp)  foreground(108dp)
for spec in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  IFS=: read -r dens leg fg <<< "$spec"
  out="$RES_DIR/mipmap-$dens"
  mkdir -p "$out"
  # Icone antigo: logo ocupando ~84% do quadro
  inner=$(( leg * 84 / 100 ))
  $IM "$WORK/logo.png" -resize "${inner}x${inner}" -background none -gravity center \
    -extent "${leg}x${leg}" "PNG32:$out/ic_launcher.png"
  cp "$out/ic_launcher.png" "$out/ic_launcher_round.png"
  # Adaptativo: logo dentro da zona segura (66dp de 108dp)
  inner=$(( fg * 58 / 100 ))
  $IM "$WORK/logo.png" -resize "${inner}x${inner}" -background none -gravity center \
    -extent "${fg}x${fg}" "PNG32:$out/ic_launcher_foreground.png"
done
rm -rf "$WORK"
echo "Icones UCSN aplicados em $RES_DIR"
