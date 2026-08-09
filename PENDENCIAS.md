# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

- [ ] Remontar o `.app` (v1.9.0) via `scripts/build-app.sh` e substituir o de
  `/Applications` (está na v1.7.0; o widget roda do binário de debug desde
  2026-08-09) — `2026-08-09 · #01`
- [ ] Fase 1 do ROADMAP — multi-player: abstração `Player`, seletor de player
  preferido, matriz de compatibilidade empírica. Pré-requisito: usuário instalar
  Spotify (e Deezer, se for suportar) — `2026-08-09 · #01`

- [x] Testar fluxo de Amazon Music não instalado — feito por simulação (chave `simulateMissingApp` no UserDefaults + env `MMW_SIMULATE_MISSING_APP`), sem mexer no `.app` instalado. O alerta ganhou `NSApp.activate()`, senão poderia nascer atrás das janelas num app sem Dock — `2026-08-05 · #01`
- [x] Commit + push da verificação de app não instalado — feito junto ao encerramento da sessão `2026-06-26 · #01`
- [x] Confirmar URL de instalação — `music.amazon.com/download` dava 404; trocada por `am.app.link/zb0Bk69BNub` — `2026-06-24 · #01`

## Média

- [ ] Conferir o texto exato da licença do adapter do ejbills (MIT presumido) e
  preparar os textos de atribuição (media-control é BSD-3-Clause) para o bundle
  de venda — Fase 4 do ROADMAP — `2026-08-09 · #01`
- [x] Barra de progresso não reflete seek feito dentro do Amazon Music — **não corrigível**, comprovado por captura do stream: no seek o app publica só `{"playing": bool}`, sem posição e sem `timestamp` novo; o `get` do adapter traz os mesmos campos e o app não tem AppleScript. O que era bug próprio (barra travando em 100% por timestamp obsoleto) foi corrigido. Ver `DECISOES.md` — `2026-08-05 · #01`
- [x] Barra de progresso não é ajustável pela UI — **não implementável**, comprovado por teste observável: seek para 5s antes do fim da faixa, com o app tocando, não fez a faixa terminar nem avançar (`Welcome to Paradise` 224s→219s e `Sultans Of Swing` 348s→340s). Contraprova no QuickTime (arquivo de 127s, seek para 100s → posição real 101,35s) mostra que o comando funciona: quem ignora é o `Amazon Music.app`. O `seek(toSeconds:)` foi removido e README/CLAUDE.md corrigidos, que anunciavam um recurso inexistente. Ver `DECISOES.md` — `2026-08-05 · #02`

## Baixa

- [x] Fallback de desenvolvimento em `NowPlayingController` aponta para `media-control/0.7.6` fixo, enquanto `build-app.sh` usa `brew --prefix`: atualizar o brew quebra o `swift run` fora do bundle — resolvido trocando o caminho do `Cellar/` (que carrega a versão no nome) pelos symlinks `opt/` do brew, que a fórmula reaponta a cada upgrade; inclui o prefixo Intel além do Apple Silicon — `2026-08-05 · #02`
