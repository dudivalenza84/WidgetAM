# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

- [x] Testar fluxo de Amazon Music não instalado — feito por simulação (chave `simulateMissingApp` no UserDefaults + env `MMW_SIMULATE_MISSING_APP`), sem mexer no `.app` instalado. O alerta ganhou `NSApp.activate()`, senão poderia nascer atrás das janelas num app sem Dock — `2026-08-05 · #01`
- [x] Commit + push da verificação de app não instalado — feito junto ao encerramento da sessão `2026-06-26 · #01`
- [x] Confirmar URL de instalação — `music.amazon.com/download` dava 404; trocada por `am.app.link/zb0Bk69BNub` — `2026-06-24 · #01`

## Média

- [x] Barra de progresso não reflete seek feito dentro do Amazon Music — **não corrigível**, comprovado por captura do stream: no seek o app publica só `{"playing": bool}`, sem posição e sem `timestamp` novo; o `get` do adapter traz os mesmos campos e o app não tem AppleScript. O que era bug próprio (barra travando em 100% por timestamp obsoleto) foi corrigido. Ver `DECISOES.md` — `2026-08-05 · #01`
- [ ] Barra de progresso não é ajustável pela UI: `NowPlayingController.seek(toSeconds:)` existe e nunca foi chamado, apesar de README e CLAUDE.md anunciarem "seek" como recurso. Se implementado, a barra vira controle e precisa de `.nonDraggableWindowArea()` — `2026-08-05 · #01`

## Baixa

- [ ] Fallback de desenvolvimento em `NowPlayingController` aponta para `media-control/0.7.6` fixo, enquanto `build-app.sh` usa `brew --prefix`: atualizar o brew quebra o `swift run` fora do bundle — `2026-08-05 · #01`
