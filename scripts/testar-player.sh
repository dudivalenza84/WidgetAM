#!/usr/bin/env bash
# Roteiro de teste de capacidades de um player, para preencher a matriz de
# compatibilidade (docs/compatibilidade-players.md).
#
# A regra que este script existe para cumprir: **comando aceito sem erro não é comando
# funcionando**. O `Amazon Music.app` aceita o seek do MediaRemote e o ignora — e isso
# só apareceu quando alguém verificou o efeito, não o código de retorno. Por isso cada
# teste aqui lê o estado depois de agir e compara.
#
# Três falsos negativos conhecidos, corrigidos em 2026-08-21 · #01 — todos descobertos
# porque o resultado foi conferido à mão (DECISOES.md · 2026-08-19 · #02):
#
#   1. **Vocabulário de shuffle/repeat.** O script falava só o dicionário do Apple Music
#      (`shuffle enabled`, `song repeat`) e reportava "não existe" com `syntax error
#      (-2740)` no Spotify, que usa `shuffling`/`repeating`. Agora tenta os dois.
#   2. **Volume comparado por igualdade exata.** O Spotify quantiza: pede 42, lê 41.
#      Agora a tolerância é ±1, que é o suficiente para distinguir "gravou" de "ignorou".
#   3. **O observador era sempre o payload do Now Playing** — que MENTE no navegador
#      (`playing=True` com o vídeo pausado). Para navegador o observador passa a ser a
#      própria página, lida por JavaScript.
#
# Uso:
#   scripts/testar-player.sh <bundle-id> [nome-applescript]
#
#   scripts/testar-player.sh com.apple.Music Music
#   scripts/testar-player.sh com.spotify.client Spotify
#   scripts/testar-player.sh com.amazon.music                # sem AppleScript
#   scripts/testar-player.sh com.google.Chrome               # observador = a página
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

# --- Observador ---------------------------------------------------------------
#
# Quem responde "o que está acontecendo agora" depois de cada comando. No caso normal é
# o payload do Now Playing. No navegador o payload mente, e o observador válido é o
# `<video>` da página — ver nota ⁶ da matriz.

BROWSER_JS_APP=""   # "chromium" | "safari" | "" (não é navegador)
BROWSER_W=""
BROWSER_T=""

case "$BUNDLE_ID" in
    com.google.Chrome|com.brave.Browser|com.microsoft.edgemac|com.vivaldi.Vivaldi)
        BROWSER_JS_APP="chromium"
        [[ -z "$OSA_NAME" ]] && OSA_NAME="$(osascript -e "get name of application id \"$BUNDLE_ID\"" 2>/dev/null)"
        ;;
    com.apple.Safari)
        BROWSER_JS_APP="safari"
        [[ -z "$OSA_NAME" ]] && OSA_NAME="Safari"
        ;;
esac

# Localiza a aba que tem um `<video>`, uma vez só.
#
# Duas armadilhas, ambas já custaram medição: `active tab of window 1` pode não ser a
# aba que toca — uma vizinha com vídeo parado devolve `currentTime=0` para sempre e
# parece app quebrado. E `execute javascript ... in tab t of window w` dá `-1723`; a
# forma que funciona é `tell tab t of window w to execute javascript`.
browser_find_tab() {
    local script
    if [[ "$BROWSER_JS_APP" == "chromium" ]]; then
        script="tell application \"$OSA_NAME\"
    repeat with w from 1 to (count of windows)
        repeat with t from 1 to (count of tabs of window w)
            try
                set r to (tell tab t of window w to execute javascript \"document.querySelector('video') ? '1' : '0'\")
                if r is \"1\" then return ((w as text) & \" \" & (t as text))
            end try
        end repeat
    end repeat
end tell
return \"\""
    else
        script="tell application \"Safari\"
    repeat with w from 1 to (count of windows)
        repeat with t from 1 to (count of tabs of window w)
            try
                set r to (do JavaScript \"document.querySelector('video') ? '1' : '0'\" in tab t of window w)
                if r is \"1\" then return ((w as text) & \" \" & (t as text))
            end try
        end repeat
    end repeat
end tell
return \"\""
    fi
    osascript -e "$script" 2>&1
}

# Roda JS na aba localizada e devolve o resultado cru.
browser_js() {
    local js="$1" script
    if [[ "$BROWSER_JS_APP" == "chromium" ]]; then
        script="tell application \"$OSA_NAME\" to tell tab $BROWSER_T of window $BROWSER_W to execute javascript \"$js\""
    else
        script="tell application \"Safari\" to do JavaScript \"$js\" in tab $BROWSER_T of window $BROWSER_W"
    fi
    osascript -e "$script" 2>&1
}

# Estado atual como "playing|position|title".
obs_state() {
    if [[ -n "$BROWSER_JS_APP" && -n "$BROWSER_W" ]]; then
        browser_js "(function(){var v=document.querySelector('video');if(!v)return '||';return (v.paused?'false':'true')+'|'+v.currentTime+'|'+(document.title||'');})()"
    else
        np | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin) or {}
except Exception:
    d = {}
tocando = d.get('playing')
print('%s|%s|%s' % (
    '' if tocando is None else ('true' if tocando else 'false'),
    d.get('elapsedTime', ''),
    d.get('title', ''),
))" 2>/dev/null
    fi
}

obs_field() { obs_state | cut -d'|' -f"$1"; }
obs_playing() { obs_field 1; }
obs_position() { obs_field 2; }
obs_title() { obs_field 3; }

# Compara dois números com tolerância. `perto 41 42 1` -> verdadeiro.
perto() {
    python3 -c "
import sys
try:
    a = float('$1'.replace(',', '.')); b = float('$2'.replace(',', '.'))
except ValueError:
    sys.exit(1)
sys.exit(0 if abs(a - b) <= $3 else 1)" 2>/dev/null
}

# --- Cabeçalho ----------------------------------------------------------------

echo "=== Player: $BUNDLE_ID ${OSA_NAME:+(AppleScript: $OSA_NAME)}"
echo "=== $(date '+%Y-%m-%d %H:%M') · macOS $(sw_vers -productVersion) · media-control $(brew list --versions media-control 2>/dev/null | awk '{print $2}')"

if [[ -n "$BROWSER_JS_APP" ]]; then
    read -r BROWSER_W BROWSER_T <<<"$(browser_find_tab)"
    if [[ -n "${BROWSER_W:-}" && "$BROWSER_W" =~ ^[0-9]+$ ]]; then
        echo "=== observador: a página (janela $BROWSER_W, aba $BROWSER_T) — o payload do navegador mente"
    else
        BROWSER_W=""
        echo "=== ATENÇÃO: não achei aba com <video>. Ou não há mídia aberta, ou o JavaScript por"
        echo "===          Apple Events está desligado (menu Desenvolvedor). Sem isso o observador"
        echo "===          volta a ser o payload — que MENTE no navegador. Resultado não vale."
    fi
fi

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
TITULO_ANTES="$(obs_title)"
POS_ANTES="$(obs_position)"
adapter send 4 >/dev/null; sleep 2
TITULO_DEPOIS="$(obs_title)"
if [[ -n "$TITULO_ANTES" && "$TITULO_ANTES" != "$TITULO_DEPOIS" ]]; then
    resultado "next (MediaRemote)" "verificado" "'$TITULO_ANTES' -> '$TITULO_DEPOIS'"
else
    resultado "next (MediaRemote)" "NÃO FUNCIONA" "mídia continuou '$TITULO_DEPOIS'"
fi

adapter send 5 >/dev/null; sleep 2
TITULO_VOLTA="$(obs_title)"
POS_VOLTA="$(obs_position)"
if [[ "$TITULO_VOLTA" != "$TITULO_DEPOIS" ]]; then
    resultado "previous (MediaRemote)" "verificado" "'$TITULO_DEPOIS' -> '$TITULO_VOLTA'"
elif [[ -n "$POS_VOLTA" ]] && perto "$POS_VOLTA" 0 2 && ! perto "${POS_ANTES:-99}" 0 2; then
    # O caso do navegador: não troca de mídia, rebobina a atual.
    resultado "previous (MediaRemote)" "rebobina" "mesma mídia, posição foi para $POS_VOLTA"
else
    resultado "previous (MediaRemote)" "NÃO FUNCIONA" "mídia continuou '$TITULO_VOLTA'"
fi

TOCANDO_ANTES="$(obs_playing)"
adapter send 2 >/dev/null; sleep 1.5
TOCANDO_DEPOIS="$(obs_playing)"
if [[ -n "$TOCANDO_ANTES" && "$TOCANDO_ANTES" != "$TOCANDO_DEPOIS" ]]; then
    resultado "play/pause (MR)" "verificado" "playing $TOCANDO_ANTES -> $TOCANDO_DEPOIS"
elif [[ -z "$TOCANDO_ANTES" ]]; then
    resultado "play/pause (MR)" "indeterminado" "o observador não sabe dizer se estava tocando"
else
    resultado "play/pause (MR)" "NÃO FUNCIONA" "playing continuou $TOCANDO_DEPOIS"
fi
adapter send 2 >/dev/null; sleep 1  # desfaz

# --- AppleScript --------------------------------------------------------------
#
# Um navegador tem dicionário AppleScript, mas **nenhuma capacidade de mídia**: o que ele
# expõe é `execute javascript`, usado aqui como instrumento de medição. Por isso o bloco
# abaixo não roda para navegador — não há `player position` nem `sound volume` para ler.
if [[ -z "$OSA_NAME" || -n "$BROWSER_JS_APP" ]]; then
    if [[ -n "$BROWSER_JS_APP" ]]; then
        resultado "AppleScript (mídia)" "não existe" "navegador só expõe execute javascript"
    else
        resultado "AppleScript" "não existe" "app sem dicionário (NSAppleScriptEnabled ausente)"
    fi
else
    POS="$(osa 'get player position')"
    if [[ "$POS" =~ ^[0-9]+([.,][0-9]+)?$ ]]; then
        resultado "posição real (AS)" "verificado" "player position=$POS"

        ALVO=30
        osa "set player position to $ALVO" >/dev/null; sleep 1
        POS2="$(osa 'get player position')"
        # Tolerância: a faixa continua andando entre gravar e reler.
        if perto "$POS2" "$ALVO" 4; then
            resultado "seek (AS)" "verificado" "set 30 -> leu $POS2"
        else
            resultado "seek (AS)" "NÃO FUNCIONA" "set 30 -> leu $POS2"
        fi
        osa "set player position to $POS" >/dev/null
    else
        resultado "posição real (AS)" "NÃO FUNCIONA" "retorno: $POS"
    fi

    # Volume: ±1 de tolerância. O Spotify grava o valor pedido e devolve `n-1` em todo
    # ponto intermediário (medido em 8 pontos, nota ² da matriz). Exigir igualdade exata
    # reportava "NÃO FUNCIONA" num controle que funciona.
    VOL_ORIG="$(osa 'get sound volume')"
    if [[ "$VOL_ORIG" =~ ^[0-9]+$ ]]; then
        osa "set sound volume to 42" >/dev/null; sleep 0.5
        VOL2="$(osa 'get sound volume')"
        if perto "$VOL2" 42 1; then
            EXATO=$([[ "$VOL2" == "42" ]] && echo "" || echo " (quantiza: pediu 42)")
            resultado "volume por-app (AS)" "verificado" "set 42 -> leu $VOL2$EXATO (era $VOL_ORIG)"
        else
            resultado "volume por-app (AS)" "NÃO FUNCIONA" "set 42 -> leu $VOL2"
        fi
        osa "set sound volume to $VOL_ORIG" >/dev/null
    else
        resultado "volume por-app (AS)" "NÃO FUNCIONA" "retorno: $VOL_ORIG"
    fi

    # Shuffle e repeat: cada app tem seu vocabulário. O do Apple Music (`shuffle
    # enabled` / `song repeat`) dava `syntax error (-2740)` no Spotify, que usa
    # `shuffling` / `repeating` — e o script lia isso como "o app não tem o recurso".
    testar_booleano() {
        local rotulo="$1"; shift
        local prop valor alvo lido
        for prop in "$@"; do
            valor="$(osa "get $prop")"
            [[ "$valor" == "true" || "$valor" == "false" ]] || continue

            alvo=$([[ "$valor" == "true" ]] && echo false || echo true)
            osa "set $prop to $alvo" >/dev/null; sleep 0.5
            lido="$(osa "get $prop")"
            if [[ "$lido" == "$alvo" ]]; then
                resultado "$rotulo" "verificado" "$prop: $valor -> $lido"
            else
                resultado "$rotulo" "NÃO FUNCIONA" "$prop: pediu $alvo, leu $lido"
            fi
            osa "set $prop to $valor" >/dev/null
            return 0
        done
        return 1
    }

    testar_booleano "shuffle (AS)" "shuffle enabled" "shuffling" \
        || resultado "shuffle (AS)" "não existe" "nenhum vocabulário conhecido respondeu"

    # Repeat tem duas formas: enumeração no Apple Music (off/one/all) e booleano no
    # Spotify. Tenta a enumeração primeiro; se não houver, cai no booleano.
    REP_ORIG="$(osa 'get song repeat as text')"
    if [[ -n "$REP_ORIG" && "$REP_ORIG" != *"error"* ]]; then
        osa "set song repeat to all" >/dev/null; sleep 0.5
        REP2="$(osa 'get song repeat as text')"
        if [[ "$REP2" == "all" ]]; then
            resultado "repeat (AS)" "verificado" "song repeat: $REP_ORIG -> $REP2"
        else
            resultado "repeat (AS)" "NÃO FUNCIONA" "song repeat: pediu all, leu $REP2"
        fi
        osa "set song repeat to $REP_ORIG" >/dev/null
    else
        testar_booleano "repeat (AS)" "repeating" \
            || resultado "repeat (AS)" "não existe" "nem 'song repeat' nem 'repeating' responderam"
    fi
fi

# --- Seek pelo MediaRemote ----------------------------------------------------
# Vale medir separado: onde o AppleScript não existe, é a única chance de seek — e é
# exatamente aqui que o Amazon Music mente (aceita e ignora). No navegador quem julga é
# o `<video>` da página, não o payload.
DUR="$(np_field duration)"
if [[ -n "$DUR" && "$DUR" != "0" ]]; then
    ALVO_S="$(python3 -c "print(round($DUR - 10, 1))")"
    ALVO_US="$(python3 -c "print(int(($DUR - 10) * 1000000))")"
    adapter seek "$ALVO_US" >/dev/null; sleep 2
    POS_MR="$(obs_position)"
    if [[ -n "$POS_MR" ]] && perto "$POS_MR" "$ALVO_S" 3; then
        resultado "seek (MediaRemote)" "verificado" "pediu ${ALVO_S}s -> observou $POS_MR"
    elif [[ -n "$POS_MR" ]]; then
        resultado "seek (MediaRemote)" "NÃO FUNCIONA" "pediu ${ALVO_S}s -> observou $POS_MR"
    else
        resultado "seek (MediaRemote)" "indeterminado" "sem posição observável: julgue vendo a faixa terminar"
    fi
else
    resultado "seek (MediaRemote)" "não testado" "sem duration no payload"
fi

echo
echo "=== fim. Confira no app se o estado foi restaurado (volume, shuffle, repeat)."
