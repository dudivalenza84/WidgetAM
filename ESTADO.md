# Estado — MacMediaWidget

Última sessão: 2026-08-09 · #01 — Visual e grade de widget nativo + roadmap de produto — concluída

## Próximo passo

Fase 1 do `ROADMAP.md` (multi-player): abstração `Player` — MediaRemote como base
universal + AppleScript como camada por app (Spotify/Apple Music têm; Amazon não) —
seletor de player preferido e matriz de compatibilidade empírica. Pré-requisito do
usuário: instalar Spotify (e Deezer, se for suportar). Antes de codar, remontar o
`.app` v1.9.0 (`scripts/build-app.sh`) — pendência Alta.

## Pendências abertas (prioridade)

- [ ] Remontar `.app` v1.9.0 e substituir o de /Applications (roda binário de debug)
- [ ] Fase 1 multi-player (ROADMAP) — depende de instalar Spotify/Deezer
- [ ] Conferir licença do adapter ejbills + textos de atribuição (Fase 4)

## Decisões vigentes que restringem o trabalho

- Produto: Amazon Music inegociável → venda direta fora da App Store; MediaRemote
  (privado) aceito como risco precificado. Nome de trabalho MMC pendente de validação.
- Snap: grade celular nativa 180×180 medida via CGWindowList (ver DECISOES.md);
  não recriar preferências de margem/passo — a grade nativa não tem esses graus.
- Não há seek nem posição no Amazon Music; volume por-app impossível para ele
  (sem AppleScript, comprovado). `togglePlayPause` é global. Volume atual é do sistema.
- Arrasto por deny-list: só NSViews reais se excluem. `glassEffect` em camada de fundo.
- Comando novo de adapter: testar contra o app real antes de prometer (aceita e ignora).

## Alertas

- **O widget está rodando do binário de debug** (`nohup .build/debug/MacMediaWidget`,
  iniciado em 2026-08-09) — proposital, para o usuário usar o visual novo; o `.app`
  de /Applications segue na v1.7.0 sem as mudanças. Remontar é a primeira pendência.
- `swift build` OK. Auditoria de segurança das mudanças da sessão: sem achados.
