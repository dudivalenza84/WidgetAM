# Estado — MacMediaWidget

Última sessão: 2026-08-12 · #01 — Transporte e status no menu + identidade visual (Órbita) — concluída

## Próximo passo

Testar manualmente a 1.14.0, já instalada e rodando em `/Applications`: menu
(contexto e bandeja) com linha de status e botões ⏮ ⏯ ⏭ que não fecham ao clicar,
ícone novo no Finder, glifo da bandeja, cabeçalho das Preferências e marca-d'água no
canto do widget (opacidade em `ContentView`, overlay `BrandMark`, se precisar ajuste).
Também segue pendente o teste manual do formato 1×1 (1.13.0).

## Pendências abertas (prioridade)

- [ ] Testar manualmente a 1.14.0 (menu, ícone, bandeja, preferências, marca-d'água)
- [ ] Testar manualmente o formato compacto 1×1 (v1.13.0)
- [ ] Instalar o Spotify — fecha o critério de saída da Fase 1
- [ ] Fase 2 restante: tradução pt-BR **na tela** e multi-monitor real
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4

## Decisões vigentes que restringem o trabalho

- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app.
- Amazon Music: sem seek, sem posição, sem AppleScript, sem volume por-app.
- Nada entra na matriz de compatibilidade sem evidência observada.
- Idioma-base inglês; string nova de UI precisa de chave no `pt-BR.lproj` (+ script);
  área interativa nova precisa de `.nonDraggableWindowArea()`.
- Identidade visual é o conceito **Órbita**: mudou SVG em `Resources/icon/` → rodar
  `scripts/gerar-icones.sh`; na UI usar `BrandMark`, nunca PNG.

## Alertas

- Nenhum. `swift build` OK, 53 asserções OK, traduções OK. `.app` de `/Applications`
  na 1.14.0, igual ao código, rodando.
