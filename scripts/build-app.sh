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
# A licença BSD-3-Clause do mediaremote-adapter exige (cláusula 2) que o aviso de
# copyright acompanhe a redistribuição binária — logo o arquivo vai no bundle, não
# só no repositório.
cp "$ROOT/Resources/THIRD-PARTY-LICENSES.md" "$CONTENTS/Resources/"

# Identidade visual: ícone do app (icns) e glifo template da bandeja. São gerados por
# scripts/gerar-icones.sh a partir dos SVGs de Resources/icon/ e ficam versionados.
cp "$ROOT/Resources/icon/AppIcon.icns" "$CONTENTS/Resources/"
cp "$ROOT/Resources/icon/MenuBarIcon.png" "$CONTENTS/Resources/"

# Traduções. O idioma-base do código é inglês (a chave é o próprio texto), então só os
# .lproj de tradução precisam existir — sem eles o app fica em inglês, que é o fallback
# correto. Ver Sources/MacMediaWidget/L10n.swift.
for lproj in "$ROOT"/Resources/*.lproj; do
    [[ -d "$lproj" ]] && cp -R "$lproj" "$CONTENTS/Resources/"
done

# 4. Assinatura. Ad-hoc por padrão (uso pessoal); com Developer ID quando houver.
#
#    Para assinar de verdade — pré-requisito da venda direta (Fase 4 do ROADMAP):
#      export MMW_SIGN_IDENTITY="Developer ID Application: Fulano (TEAMID)"
#      scripts/build-app.sh
#
#    E para notarizar, depois de guardar as credenciais uma vez com
#    `xcrun notarytool store-credentials`:
#      export MMW_NOTARY_PROFILE="nome-do-perfil"
#
#    `notarytool` e `stapler` vêm nas Command Line Tools — notarizar não exige o Xcode
#    completo (verificado em 2026-08-10).
ENTITLEMENTS="$ROOT/Resources/$APP_NAME.entitlements"
SIGN_IDENTITY="${MMW_SIGN_IDENTITY:-}"

if [[ -n "$SIGN_IDENTITY" ]]; then
    echo "==> codesign com Developer ID + hardened runtime"
    # Sempre de dentro para fora: assinar o app antes do framework aninhado invalidaria
    # a assinatura externa.
    codesign --force --options runtime --timestamp \
        --sign "$SIGN_IDENTITY" \
        "$CONTENTS/Resources/mediaremote-adapter/MediaRemoteAdapter.framework"
    # Sem --deep: a Apple o desaconselha há anos, porque ele reassina o que encontrar
    # com as entitlements erradas. O framework já foi assinado acima.
    codesign --force --options runtime --timestamp \
        --entitlements "$ENTITLEMENTS" \
        --sign "$SIGN_IDENTITY" \
        "$APP"
    codesign --verify --deep --strict --verbose=2 "$APP"
else
    echo "==> codesign ad-hoc (defina MMW_SIGN_IDENTITY para assinar com Developer ID)"
    codesign --force --sign - "$CONTENTS/Resources/mediaremote-adapter/MediaRemoteAdapter.framework"
    codesign --force --deep --sign - "$APP"
fi

# 5. Notarização (opcional, exige assinatura com Developer ID).
if [[ -n "${MMW_NOTARY_PROFILE:-}" ]]; then
    if [[ -z "$SIGN_IDENTITY" ]]; then
        echo "MMW_NOTARY_PROFILE definido sem MMW_SIGN_IDENTITY: a Apple recusa binário ad-hoc." >&2
        exit 1
    fi
    ZIP="$DIST/$APP_NAME-notarize.zip"
    echo "==> notarizando (pode levar alguns minutos)"
    ditto -c -k --keepParent "$APP" "$ZIP"
    xcrun notarytool submit "$ZIP" --keychain-profile "$MMW_NOTARY_PROFILE" --wait
    rm -f "$ZIP"
    # O staple grava o ticket no bundle: sem ele, a primeira abertura offline falha.
    xcrun stapler staple "$APP"
    xcrun stapler validate "$APP"
fi

echo "==> pronto: $APP"
