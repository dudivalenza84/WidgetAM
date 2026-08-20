# Estado — MacMediaWidget

Última sessão: 2026-08-19 · #01 — Planejamento: Spotify, TIDAL, Deezer e YouTube Music + visibilidade por app — concluída

## Próximo passo

Rodar a **Tarefa 0** de `docs/plano-players-adicionais.md` — o gate de evidência, antes
de qualquer código: `scripts/testar-player.sh` em Spotify (`com.spotify.client Spotify`),
TIDAL (`com.tidal.desktop`), Deezer (`com.deezer.deezer-desktop`) e Chrome
(`com.google.Chrome`), cada um com fila de 3+ faixas tocando, mais o teste que decide a
identidade da sessão do PWA do YouTube Music. Depois seguir o plano na ordem (Tarefa 1
em diante). Os quatro apps já estão instalados; Spotify, TIDAL e Deezer ficaram abertos.

## Pendências abertas (prioridade)

- [ ] Tarefa 0 do plano: bateria de testes nos 4 players (destrava o desenvolvimento)
- [ ] PWA do YouTube Music não abre — reinstalar pelo Chrome (não bloqueia o plano)
- [ ] Confirmar visualmente o letreiro rodando na 1.15.0
- [ ] Testar manualmente o resto da 1.14.0 e o formato compacto 1×1 (v1.13.0)
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4

## Decisões vigentes que restringem o trabalho

- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app.
- **Serviço web (YouTube Music) é atalho de lançamento, nunca identidade de sessão** —
  quem toca é o navegador, e o MediaRemote identifica pelo processo.
- **Visibilidade de player é blocklist** (lista de ocultos, padrão vazio); o preferido
  nunca pode ser ocultado.
- Nenhuma capacidade entra no código sem evidência observada contra o app real.
- Idioma-base inglês; string nova de UI precisa de chave no `pt-BR.lproj` (+ script);
  área interativa nova precisa de `.nonDraggableWindowArea()`.
- View custom em `NSMenuItem`: largura explícita na `View`, nunca só no frame.
- Identidade visual é o conceito **Órbita**: na UI usar `BrandMark`, nunca PNG.

## Alertas

- Nenhum. `swift build` OK. Sessão de planejamento: nenhum código de produção alterado,
  `.app` de `/Applications` segue na 1.15.0, igual ao código.
