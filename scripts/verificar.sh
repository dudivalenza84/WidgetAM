#!/usr/bin/env bash
# Verificação completa do projeto, em um comando.
#
# Existe porque `swift build` sozinho não é verificação suficiente aqui: as asserções
# vivem dentro do binário (`--run-tests`, ver CLAUDE.md) e as chaves de tradução são
# conferidas por script à parte. Rodar só o build deixa passar asserção quebrada e chave
# de UI faltando — que cai no inglês em silêncio.
#
# Uso:
#   scripts/verificar.sh
#
# Sai 0 se tudo passou. Saída enxuta: cada etapa reporta uma linha, e o log completo só
# aparece quando falha.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

log="${TMPDIR:-/tmp}/mmw-verificar-$$.log"
falhou=0

etapa() {
    local rotulo="$1"; shift
    if "$@" >"$log" 2>&1; then
        printf '  ok   %s\n' "$rotulo"
    else
        printf '  FALHOU %s\n' "$rotulo"
        tail -25 "$log" | sed 's/^/       /'
        falhou=1
    fi
}

echo "── verificação do MacMediaWidget"
etapa "swift build" swift build
# Só roda a suíte se o build passou: senão o erro seria o mesmo, dito duas vezes.
if [[ $falhou -eq 0 ]]; then
    etapa "asserções (--run-tests)" swift run MacMediaWidget --run-tests
fi
etapa "traduções" bash scripts/verificar-traducoes.sh

rm -f "$log"
if [[ $falhou -eq 0 ]]; then
    echo "── tudo verde"
else
    echo "── verificação falhou"
fi
exit $falhou
