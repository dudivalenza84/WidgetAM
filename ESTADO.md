# Estado — MacMediaWidget

Última sessão: 2026-08-20 · #01 — Players adicionais: Spotify, TIDAL, Deezer, navegador e âncora de posição — concluída

## Próximo passo

Testar ao vivo a **1.17.0** (montada em `dist/`, não instalada): roteiro no passo 2 da
Tarefa 9 de `docs/plano-players-adicionais.md`. Confirmar barra acompanhando no TIDAL e no
Deezer, seek arrastando no Spotify e no TIDAL, botão "anterior" desligado no Deezer e
"próxima" desligado no Chrome (com o motivo no tooltip) e o YouTube Music abrindo o PWA ou
o site. Só isso fecha a Fase 1 de verdade — o plano dos players está executado.

## Pendências abertas (prioridade)

- [ ] Testar ao vivo a 1.17.0 (e a visibilidade por app da 1.16.0, que também nunca foi)
- [ ] Medir o Safari e decidir se ele entra no catálogo
- [ ] Atalho de serviço web como preferido no modo fixo fica sem sessão — a UI não explica
- [ ] `scripts/testar-player.sh` dá falso negativo em 3 situações — corrigir
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4

## Decisões vigentes que restringem o trabalho

- **Nenhuma capacidade entra no código sem evidência observada** contra o app real. Onde o
  plano e `docs/compatibilidade-players.md` divergirem, **manda a matriz**.
- **O widget não afirma o que a fonte não garante**: sem `.streamPosition` não se ancora a
  barra, sem `.reliablePlaybackState` não se diz "tocando" nem se anima a barra.
- **`.transport` é só play/pause.** Pular faixa são capacidades separadas, porque Deezer e
  navegador ignoram uma delas cada.
- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app; e um
  segundo player tocando **toma a sessão no meio de um teste**.
- **Atalho de serviço web se identifica por `catalogID`**, não pelo `bundleIdentifier`.
- Idioma-base inglês; string nova de UI precisa de chave no `pt-BR.lproj` (+ script);
  área interativa nova precisa de `.nonDraggableWindowArea()`.
- Identidade visual é o conceito **Órbita**: na UI usar `BrandMark`, nunca PNG.

## Alertas

- `swift build` OK, 100 verificações passando, traduções conferindo.
- O `.app` de `/Applications` segue na **1.15.0**; a **1.17.0** está em `dist/` e nunca foi
  aberta — duas versões de recursos novos (1.16.0 e 1.17.0) esperam teste ao vivo.
- Warning pré-existente em `ContentView.swift` (`doubleValue` main actor-isolated), anterior
  a estas sessões e não tratado.
- Grafo em 2/5 no contador — sem `graphify update` nesta sessão, por desenho.
