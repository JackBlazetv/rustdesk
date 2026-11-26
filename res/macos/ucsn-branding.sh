#!/bin/bash
# Aplica a identidade UCSN DESK ao app macOS ja compilado.
#
# Uso: res/macos/ucsn-branding.sh <caminho/para/UCSN.app> [icone.png]
#
# - Gera o AppIcon.icns a partir da mesma logo usada no Windows (res/icon.png).
# - Faz o Finder, o Dock e o menu mostrarem "UCSN DESK". O arquivo continua
#   UCSN.app porque o codigo (src/platform/macos.rs) monta o caminho
#   /Applications/<APP_NAME>.app para instalar o servico.
# - Reassina o app inteiro (ad-hoc). Sem isso o app fecha ao abrir:
#   o binario principal e o FlutterMacOS.framework ficam com Team IDs diferentes
#   e o "service" e copiado depois da assinatura do Xcode.
#   O passo de assinatura oficial (com certificado) reassina por cima, se existir.
set -euo pipefail

APP="${1:?informe o caminho do UCSN.app}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="${2:-$SCRIPT_DIR/../icon.png}"
DISPLAY_NAME="UCSN DESK"
BUNDLE_FILE_NAME="$(basename "$APP" .app)"

[ -d "$APP/Contents" ] || { echo "app nao encontrado: $APP" >&2; exit 1; }
[ -f "$ICON_SRC" ] || { echo "icone nao encontrado: $ICON_SRC" >&2; exit 1; }

# 1. Icone
WORK="$(mktemp -d)"
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z "$s" "$s" "$ICON_SRC" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z "$d" "$d" "$ICON_SRC" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
ICON_FILE="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIconFile' "$APP/Contents/Info.plist" 2>/dev/null || echo AppIcon)"
ICON_FILE="${ICON_FILE%.icns}.icns"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/$ICON_FILE"
rm -rf "$WORK"

# 2. Nome exibido. O nome base precisa ser igual ao nome do arquivo (.app)
#    para o macOS usar o nome localizado.
plutil -replace CFBundleDisplayName -string "$BUNDLE_FILE_NAME" "$APP/Contents/Info.plist"
plutil -replace LSHasLocalizedDisplayName -bool YES "$APP/Contents/Info.plist"
for lang in Base en pt pt-BR es fr; do
  mkdir -p "$APP/Contents/Resources/$lang.lproj"
  printf '"CFBundleDisplayName" = "%s";\n"CFBundleName" = "%s";\n' "$DISPLAY_NAME" "$DISPLAY_NAME" \
    > "$APP/Contents/Resources/$lang.lproj/InfoPlist.strings"
done

# 3. Assinatura consistente para o app abrir
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "UCSN DESK aplicado em $APP"
