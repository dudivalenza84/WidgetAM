#!/usr/bin/env bash
# Roteiro de teste de capacidades de um player, para preencher a matriz de
# compatibilidade (docs/compatibilidade-players.md).
#
# A regra que este script existe para cumprir: **comando aceito sem erro não é comando
# funcionando**. O `Amazon Music.app` aceita o seek do MediaRemote e o ignora — e isso
# só apareceu quando alguém verificou o efeito, não o código de retorno. Por isso cada
# teste aqui lê o estado depois de agir e compara.
#
# Uso:
#   scripts/testar-player.sh <bundle-id> [nome-applescript]
#
#   scripts/testar-player.sh com.apple.Music Music
#   scripts/testar-player.sh com.amazon.music          # sem AppleScript
#
# O script MEXE na reprodução (toca, troca faixa, muda posição e volume) e tenta
# restaurar volume, shuffle e repeat ao final. Não rode em cima de algo que importa.
set -uo pipefail

BUNDLE_ID="${1:?informe o bundle id do player}"
OSA_NAME="${2:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADAPTER_PREFIX="$(brew --prefix media-control 2>/dev/null || echo /opt/homebrew/opt/media-control)"
ADAPTER_PL="$ADAPTER_PREFIX/lib/media-control/mediaremote-adapter.pl"
ADAPTER_FW="$ADAPTER_PREFIX/Frameworks/MediaRemoteAdapter.framework"

adapter() { /usr/bin/perl "$ADAPTER_PL" "$ADAPTER_FW" "$@" 2>&1; }
osa() { [[ -n "$OSA_NAME" ]] && osascript -e "tell application \"$OSA_NAME\" to $1" 2>&1; }
np() { adapter get --no-artwork; }
np_field() { np | python3 -c "import json,sys; print(json.load(sys.stdin).get('$1',''))" 2>/dev/null; }

resultado() { printf '%-22s | %-12s | %s\n' "$1" "$2" "$3"; }

echo "=== Player: $BUNDLE_ID ${OSA_NAME:+(AppleScript: $OSA_NAME)}"
echo "=== $(date '+%Y-%m-%d %H:%M') · macOS $(sw_vers -productVersion) · media-control $(brew list --versions media-control 2>/dev/null | awk '{print $2}')"
echo
printf '%-22s | %-12s | %s\n' "CAPACIDADE" "RESULTADO" "EVIDÊNCIA"
printf '%-22s-|-%-12s-|-%s\n' "----------------------" "------------" "----------------------------------------"

# --- Leitura pelo MediaRemote -------------------------------------------------
ATIVO="$(np_field bundleIdentifier)"
if [[ "$ATIVO" == "$BUNDLE_ID" ]]; then
    resultado "sessão MediaRemote" "verificado" "bundleIdentifier=$ATIVO"
else
    resultado "sessão MediaRemote" "ATENÇÃO" "sessão ativa é '$ATIVO' — toque algo neste player antes"
fi

ELAPSED="$(np_field elapsedTime)"
if [[ -n "$ELAPSED" ]]; then
    resultado "posição (MediaRemote)" "verificado" "elapsedTime=$ELAPSED"
else
    resultado "posição (MediaRemote)" "não existe" "payload sem elapsedTime"
fi

# --- Transporte ---------------------------------------------------------------
#
# ATENÇÃO AO FALSO NEGATIVO: com uma fila de uma faixa só, `next` não tem para onde ir
# e o teste acusa "não funciona" sem que o comando tenha problema algum — aconteceu no
# primeiro teste do Apple Music (2026-08-10). Antes de rodar, deixe o player tocando uma
# playlist/álbum com pelo menos três faixas, e não uma faixa avulsa.
TITULO_ANTES="$(np_field title)"
adapter send 4 >/dev/null; sleep 2
TITULO_DEPOIS="$(np_field title)"
if [[ -n "$TITULO_ANTES" && "$TITULO_ANTES" != "$TITULO_DEPOIS" ]]; then
    resultado "next (MediaRemote)" "verificado" "'$TITULO_ANTES' -> '$TITULO_DEPOIS'"
else
    resultado "next (MediaRemote)" "NÃO FUNCIONA" "faixa continuou '$TITULO_DEPOIS'"
fi

adapter send 5 >/dev/null; sleep 2
TITULO_VOLTA="$(np_field title)"
if [[ "$TITULO_VOLTA" != "$TITULO_DEPOIS" ]]; then
    resultado "previous (MediaRemote)" "verificado" "'$TITULO_DEPOIS' -> '$TITULO_VOLTA'"
else
    resultado "previous (MediaRemote)" "NÃO FUNCIONA" "faixa continuou '$TITULO_VOLTA'"
fi

TOCANDO_ANTES="$(np_field playing)"
adapter send 2 >/dev/null; sleep 1.5
TOCANDO_DEPOIS="$(np_field playing)"
if [[ "$TOCANDO_ANTES" != "$TOCANDO_DEPOIS" ]]; then
    resultado "play/pause (MR)" "verificado" "playing $TOCANDO_ANTES -> $TOCANDO_DEPOIS"
else
    resultado "play/pause (MR)" "NÃO FUNCIONA" "playing continuou $TOCANDO_DEPOIS"
fi
adapter send 2 >/dev/null; sleep 1  # desfaz

# --- AppleScript --------------------------------------------------------------
if [[ -z "$OSA_NAME" ]]; then
    resultado "AppleScript" "não existe" "app sem dicionário (NSAppleScriptEnabled ausente)"
else
    POS="$(osa 'get player position')"
    if [[ "$POS" =~ ^[0-9]+([.,][0-9]+)?$ ]]; then
        resultado "posição real (AS)" "verificado" "player position=$POS"

        ALVO=30
        osa "set player position to $ALVO" >/dev/null; sleep 1
        POS2="$(osa 'get player position')"
        # Tolerância: a faixa continua andando entre gravar e reler.
        if python3 -c "import sys; sys.exit(0 if abs(float('$POS2'.replace(',','.')) - $ALVO) < 4 else 1)" 2>/dev/null; then
            resultado "seek (AS)" "verificado" "set 30 -> leu $POS2"
        else
            resultado "seek (AS)" "NÃO FUNCIONA" "set 30 -> leu $POS2"
        fi
        osa "set player position to $POS" >/dev/null
    else
        resultado "posição real (AS)" "NÃO FUNCIONA" "retorno: $POS"
    fi

    VOL_ORIG="$(osa 'get sound volume')"
    if [[ "$VOL_ORIG" =~ ^[0-9]+$ ]]; then
        osa "set sound volume to 42" >/dev/null; sleep 0.5
        VOL2="$(osa 'get sound volume')"
        if [[ "$VOL2" == "42" ]]; then
            resultado "volume por-app (AS)" "verificado" "set 42 -> leu $VOL2 (era $VOL_ORIG)"
        else
            resultado "volume por-app (AS)" "NÃO FUNCIONA" "set 42 -> leu $VOL2"
        fi
        osa "set sound volume to $VOL_ORIG" >/dev/null
    else
        resultado "volume por-app (AS)" "NÃO FUNCIONA" "retorno: $VOL_ORIG"
    fi

    SHUF_ORIG="$(osa 'get shuffle enabled')"
    if [[ "$SHUF_ORIG" == "true" || "$SHUF_ORIG" == "false" ]]; then
        ALVO_SHUF=$([[ "$SHUF_ORIG" == "true" ]] && echo false || echo true)
        osa "set shuffle enabled to $ALVO_SHUF" >/dev/null; sleep 0.5
        SHUF2="$(osa 'get shuffle enabled')"
        if [[ "$SHUF2" == "$ALVO_SHUF" ]]; then
            resultado "shuffle (AS)" "verificado" "$SHUF_ORIG -> $SHUF2"
        else
            resultado "shuffle (AS)" "NÃO FUNCIONA" "pediu $ALVO_SHUF, leu $SHUF2"
        fi
        osa "set shuffle enabled to $SHUF_ORIG" >/dev/null
    else
        resultado "shuffle (AS)" "não existe" "retorno: $SHUF_ORIG"
    fi

    REP_ORIG="$(osa 'get song repeat as text')"
    if [[ -n "$REP_ORIG" && "$REP_ORIG" != *"error"* ]]; then
        osa "set song repeat to all" >/dev/null; sleep 0.5
        REP2="$(osa 'get song repeat as text')"
        if [[ "$REP2" == "all" ]]; then
            resultado "repeat (AS)" "verificado" "$REP_ORIG -> $REP2"
        else
            resultado "repeat (AS)" "NÃO FUNCIONA" "pediu all, leu $REP2"
        fi
        osa "set song repeat to $REP_ORIG" >/dev/null
    else
        resultado "repeat (AS)" "não existe" "retorno: $REP_ORIG"
    fi
fi

# --- Seek pelo MediaRemote ----------------------------------------------------
# Vale medir separado: onde o AppleScript não existe, é a única chance de seek — e é
# exatamente aqui que o Amazon Music mente (aceita e ignora).
DUR="$(np_field duration)"
if [[ -n "$DUR" && "$DUR" != "0" ]]; then
    ALVO_US="$(python3 -c "print(int(($DUR - 10) * 1000000))")"
    adapter seek "$ALVO_US" >/dev/null; sleep 2
    POS_MR="$(np_field elapsedTime)"
    if [[ -n "$POS_MR" ]]; then
        resultado "seek (MediaRemote)" "ver evidência" "pediu $(python3 -c "print(round($DUR-10,1))")s, elapsedTime=$POS_MR"
    else
        resultado "seek (MediaRemote)" "indeterminado" "sem elapsedTime: só dá para julgar observando a faixa terminar"
    fi
else
    resultado "seek (MediaRemote)" "não testado" "sem duration no payload"
fi

echo
echo "=== fim. Confira no app se o estado foi restaurado (volume, shuffle, repeat)."
