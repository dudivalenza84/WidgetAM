#!/usr/bin/env bash
# Monta o bundle MacMediaWidget.app a partir do binário gerado pelo SPM.
# Copia o mediaremote-adapter (framework + script perl) para Resources e
# assina ad-hoc (uso pessoal, sem Apple Developer ID).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="MacMediaWidget"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
CONTENTS="$APP/Contents"

# 1. Compila em release.
echo "==> swift build -c release"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/$APP_NAME"
if [[ ! -f "$BIN" ]]; then
    echo "Binário não encontrado em $BIN" >&2
    exit 1
fi

# 2. Localiza os recursos do mediaremote-adapter (instalado via brew media-control).
ADAPTER_CELLAR="$(brew --prefix media-control)"
ADAPTER_PL="$ADAPTER_CELLAR/lib/media-control/mediaremote-adapter.pl"
ADAPTER_FRAMEWORK="$ADAPTER_CELLAR/Frameworks/MediaRemoteAdapter.framework"
if [[ ! -f "$ADAPTER_PL" || ! -d "$ADAPTER_FRAMEWORK" ]]; then
    echo "mediaremote-adapter não encontrado. Instale com: brew install media-control" >&2
    exit 1
fi

# 3. Monta a árvore do bundle do zero.
echo "==> montando $APP"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources/mediaremote-adapter"

cp "$BIN" "$CONTENTS/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$ADAPTER_PL" "$CONTENTS/Resources/mediaremote-adapter/"
cp -R "$ADAPTER_FRAMEWORK" "$CONTENTS/Resources/mediaremote-adapter/"

# 4. Assinatura ad-hoc (framework primeiro, depois o app inteiro).
echo "==> codesign ad-hoc"
codesign --force --sign - "$CONTENTS/Resources/mediaremote-adapter/MediaRemoteAdapter.framework"
codesign --force --deep --sign - "$APP"

echo "==> pronto: $APP"
