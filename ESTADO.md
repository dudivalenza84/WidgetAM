# Estado — MacMediaWidget

Última sessão: 2026-08-05 · #01 — Arrasto restrito ao fundo + fechar pendências abertas — concluída

## Próximo passo

Nada bloqueado. Candidato natural: tornar a barra de progresso interativa (seek
pela UI). `NowPlayingController.seek(toSeconds:)` já existe e nunca foi chamado,
embora README e CLAUDE.md anunciem "seek" como recurso entregue. Se for feito, a
barra vira controle e precisa de `.nonDraggableWindowArea()`.

## Pendências abertas (prioridade)

- [ ] Barra de progresso não é ajustável pela UI (o `seek()` existe sem chamador)
- [ ] Fallback de desenvolvimento aponta para `media-control/0.7.6` fixo, enquanto
      o `build-app.sh` usa `brew --prefix` — atualizar o brew quebra o `swift run`

## Decisões vigentes que restringem o trabalho

- Arrasto da janela por deny-list: só NSViews reais podem se excluir do arrasto;
  views SwiftUI puras não conseguem (ver DECISOES.md · 2026-08-05).
- Posição pós-seek feito dentro do Amazon Music é irrecuperável — não reinvestigar.
- `togglePlayPause` é comando global: nunca enviar sem o Amazon Music rodando.
- Volume é do sistema (global), não por-app: MediaRemote não tem comando de volume.
- O `glassEffect` vai numa camada de fundo, nunca direto na stack.

## Alertas

- `swift build` OK. O bundle `.app` não é montado pelo `fechar-sessao.sh` —
  `scripts/build-app.sh` é manual.
- Instalado em `/Applications/MacMediaWidget.app` na v1.7.0.
