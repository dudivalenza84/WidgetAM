#!/usr/bin/env bash
# Gera dist/MacMediaWidget.dmg a partir do bundle .app já montado por build-app.sh.
# Distribuição de uso pessoal (sem Apple Developer ID): o .app é ad-hoc, então o
# Gatekeeper exige contorno na primeira abertura (ver README).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="MacMediaWidget"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
DMG="$DIST/$APP_NAME.dmg"

if [[ ! -d "$APP" ]]; then
    echo "Bundle não encontrado em $APP. Rode scripts/build-app.sh primeiro." >&2
    exit 1
fi

# Versão lida do Info.plist do bundle, só para log.
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo '?')"

# Área de staging com o .app + atalho para /Applications (instalação por arrastar).
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> gerando $DMG (v$VERSION)"
rm -f "$DMG"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG" >/dev/null

echo "==> pronto: $DMG"
