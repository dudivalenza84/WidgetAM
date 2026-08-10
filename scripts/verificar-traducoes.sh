#!/usr/bin/env bash
# Confere se as chaves de localização usadas no código existem nos arquivos de tradução,
# e vice-versa.
#
# Por que existe: `String(localized:)` cai no inglês **em silêncio** quando não acha a
# chave. Um typo de um caractere no .strings não quebra o build, não gera aviso e não
# aparece em teste — só na tela de quem usa o app em português. Sem Xcode não há
# genstrings útil aqui (ele não enxerga `String(localized:)`), então a extração é feita
# na unha a partir do L10n.swift, que é justamente o motivo de todas as strings estarem
# centralizadas nele.
#
# Uso: scripts/verificar-traducoes.sh
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import json, os, re, subprocess, sys

root = sys.argv[1]
l10n_path = os.path.join(root, "Sources/MacMediaWidget/L10n.swift")
source = open(l10n_path, encoding="utf-8").read()

# String(localized: "...") — inclusive com interpolação \(nome), que vira %@ na chave.
literais = re.findall(r'String\(localized:\s*"((?:[^"\\]|\\.)*)"\)', source)
chaves_codigo = {re.sub(r'\\\([^)]*\)', '%@', lit) for lit in literais}

if not chaves_codigo:
    print("ERRO: nenhuma chave encontrada em L10n.swift — a extração quebrou.")
    sys.exit(2)

falhou = False
lprojs = [d for d in os.listdir(os.path.join(root, "Resources")) if d.endswith(".lproj")]

if not lprojs:
    print("Nenhum .lproj em Resources/ — nada a verificar.")
    sys.exit(0)

for lproj in sorted(lprojs):
    caminho = os.path.join(root, "Resources", lproj, "Localizable.strings")
    if not os.path.exists(caminho):
        print(f"ERRO: {lproj} sem Localizable.strings")
        falhou = True
        continue

    saida = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", caminho],
        capture_output=True, text=True,
    )
    if saida.returncode != 0:
        print(f"ERRO: {lproj}/Localizable.strings não é válido:\n{saida.stderr.strip()}")
        falhou = True
        continue

    chaves_arquivo = set(json.loads(saida.stdout).keys())

    faltando = chaves_codigo - chaves_arquivo
    sobrando = chaves_arquivo - chaves_codigo

    print(f"{lproj}: {len(chaves_arquivo)} chaves, {len(chaves_codigo)} usadas no código")
    if faltando:
        falhou = True
        print(f"  SEM TRADUÇÃO ({len(faltando)}) — vão aparecer em inglês:")
        for k in sorted(faltando):
            print(f"    · {k}")
    if sobrando:
        falhou = True
        print(f"  ÓRFÃS ({len(sobrando)}) — traduzidas mas não usadas (typo ou string removida):")
        for k in sorted(sobrando):
            print(f"    · {k}")

if falhou:
    sys.exit(1)
print("✓ traduções conferem com o código")
PY
