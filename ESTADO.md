# Estado — MacMediaWidget

Última sessão: 2026-08-11 · #03 — Tamanho do widget configurável (1×1/2×1) + baixas de pendências — concluída

## Próximo passo

Usuário testar manualmente o formato compacto (1×1) novo, v1.13.0 já instalada e
rodando em `/Applications`: troca ao vivo nas preferências (Aparência → Tamanho do
widget), snap à grade nos dois formatos, seek/volume/transporte no layout compacto,
duplo clique e arraste. Problema no layout 1×1 se resolve em
`ContentView.compactLayout`; no redimensionamento, em `WidgetWindow.applySize`.

## Pendências abertas (prioridade)

- [ ] Testar manualmente o formato compacto 1×1 (v1.13.0)
- [ ] Instalar o Spotify — fecha o critério de saída da Fase 1
- [ ] Fase 2 restante: tradução pt-BR **na tela** (texto em arquivo já revisado, sem
  erro) e multi-monitor real
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4

## Decisões vigentes que restringem o trabalho

- Tamanhos do widget são os footprints da grade nativa (1×1/2×1), derivados de
  `NativeWidgetGrid` — sem tamanho livre.
- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app.
- Nada entra na matriz de compatibilidade sem evidência observada.
- Idioma-base do código é **inglês**; pt-BR é tradução (46 chaves, verificadas por script).
- Toda área interativa nova da UI precisa de `.nonDraggableWindowArea()`.
- Amazon Music: sem seek, sem posição, sem AppleScript, sem volume por-app.

## Alertas

- Nenhum. `swift build` OK, 53 asserções OK, traduções OK. `.app` de `/Applications`
  na 1.13.0, igual ao código, rodando.
