# Estado — MacMediaWidget

Última sessão: 2026-08-19 · #02 — Visibilidade por app + gate de evidência dos players — concluída

## Próximo passo

Tarefa 2 de `docs/plano-players-adicionais.md` (`SpotifyPlayer`), seguida da 3, 4 e 9.
As capacidades vêm de `docs/compatibilidade-players.md`, **não** das declaradas no plano
— elas foram escritas a partir do `.sdef`, antes da evidência, e a matriz já contradiz o
plano em pontos concretos. Dois detalhes do Spotify que o plano não previa: `sound volume`
quantiza em `n-1` (aceitar ±1 ao confirmar) e as propriedades são `shuffling`/`repeating`,
não `shuffle enabled`/`song repeat`.

## Pendências abertas (prioridade)

- [ ] Tarefas 2, 3, 4 e 9 do plano dos players (o gate da Tarefa 0 já caiu)
- [ ] Testar ao vivo a visibilidade por app da 1.16.0 (montada em `dist/`, não instalada)
- [ ] `scripts/testar-player.sh` dá falso negativo em 3 situações — corrigir
- [ ] PWA do YouTube Music não abre — reinstalar pelo Chrome (não bloqueia o plano)
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4

## Decisões vigentes que restringem o trabalho

- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app.
  Corolário medido: outro player tocando **toma a sessão no meio de um teste**, e a
  evidência sai atribuída ao app errado. Pausar os demais antes de medir.
- **O observador de um teste tem que ser do domínio do player**, não o payload do
  MediaRemote, que no navegador mente em `playing` e `elapsedTime`.
- **Ocultar app não derruba comando endereçado** — o filtro só vale quando a permissão
  viria da sessão ativa.
- **Visibilidade de player é blocklist**; o preferido e o último visível não podem sumir.
- Nenhuma capacidade entra no código sem evidência observada contra o app real.
- Idioma-base inglês; string nova de UI precisa de chave no `pt-BR.lproj` (+ script);
  área interativa nova precisa de `.nonDraggableWindowArea()`.
- Identidade visual é o conceito **Órbita**: na UI usar `BrandMark`, nunca PNG.

## Alertas

- `swift build` OK, 61 verificações passando, traduções conferindo.
- O `.app` de `/Applications` segue na **1.15.0**; a **1.16.0** está montada em `dist/`
  (`scripts/build-app.sh`) e ainda não foi testada ao vivo nem instalada.
- Warning pré-existente em `ContentView.swift:412` (`doubleValue` main actor-isolated),
  anterior a esta sessão e não tratado.
