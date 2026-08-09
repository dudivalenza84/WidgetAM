# Decisões — MacMediaWidget

Decisões com efeito além da sessão em que foram tomadas (ADR-lite). Entradas novas
vão no topo. O que está aqui não se rediscute sem motivo novo.

## 2026-08-09 · #01 — Rumo de produto: venda direta fora da App Store, Amazon Music inegociável

**Contexto.** O app vai virar produto à venda. O MediaRemote é framework privado,
acessado via perl entitled — inviável na Mac App Store (revisão rejeita API privada e
o sandbox proíbe o mecanismo). A alternativa MAS exigiria abrir mão do Amazon Music.

**Escolha.** (1) Suporte ao Amazon Music é **inegociável** — é o motivo do app existir.
(2) Logo, distribuição é **venda direta fora da App Store**: Developer ID, hardened
runtime, notarização, updates via Sparkle, checkout próprio. (3) O risco de a Apple
fechar o acesso ao MediaRemote em updates do macOS é aceito e deve ser precificado no
modelo de negócio (resposta rápida a quebras; ver ROADMAP.md). (4) Nome de trabalho:
**MMC** ("Midia MacControl" na proposta original) — a forma final precisa de validação
de marca: a diretriz da Apple veta "Mac" incorporado ao nome (permite "X for Mac"), e
há colisão com a dependência open-source `media-control`. Escopo de produto ampliado:
multi-player (Spotify, Deezer, browser/YouTube etc.) com seletor, mantendo MediaRemote
como base e AppleScript como camada de capacidades extras por player (seek/volume
por-app onde existir — Amazon Music não tem AppleScript, comprovado em 2026-08-09).

**Alternativa descartada.** Reescrever só com APIs públicas para entrar na MAS:
perderia o Amazon Music. Volume por-app universal via driver de áudio virtual:
engenharia pesada e frágil, fora do escopo.

## 2026-08-09 · #01 — Snap na grade celular dos widgets nativos, medida via CGWindowList

**Contexto.** O snap anterior era "âncora na borda esquerda/direita + passo vertical
livre" com margem e passo configuráveis — não correspondia à grade real dos widgets
da mesa do macOS, que é celular e 2D.

**Escolha.** Grade medida empiricamente (2026-08-09, macOS 26): célula de 180×180 pt
sem gutter externo; o respiro entre cards é o inset interno de ~5 pt; um widget
*medium* ocupa 2 células (footprint 360×180, card visível ~350×170). A âncora é lida
ao vivo das janelas dos widgets nativos via `CGWindowListCopyWindowInfo` (nível
`desktopIcon + 2`, tamanho múltiplo exato de 180 — o filtro de tamanho descarta o
chrome de hover da Central de Notificações). Sem widget nativo na mesa, fallback
replicado: coluna a 8 pt da borda direita, primeira linha 24 pt abaixo da menu bar.
O card adota as dimensões *medium* (350×170) e a janela o mesmo nível dos nativos.
As preferências `snapEdge`, `edgeMargin` e `gridStepY` foram removidas — a grade
nativa não tem esses graus de liberdade; ficou só o toggle `snapToGrid`.

**Alternativa descartada.** Manter constantes hardcoded sem medição ao vivo: quebraria
em resolução/escala diferente e nunca alinharia pixel-perfect com widgets nativos
presentes. A leitura via CGWindowList não exige permissão de gravação de tela para
bounds/layer, então o custo é só uma consulta no momento do snap.

## 2026-08-05 · #02 — Não há seek: o Amazon Music ignora o comando de posicionamento

**Contexto.** `NowPlayingController.seek(toSeconds:)` existia sem nenhum chamador, e
README e CLAUDE.md anunciavam `seek` entre os comandos de transporte suportados. A
pendência "tornar a barra de progresso ajustável pela UI" seguia aberta partindo do
princípio de que bastaria ligar a função a um gesto na barra. Não bastava — a função
nunca teria funcionado.

**Evidência.** Teste desenhado para ser observável sem depender da posição publicada
(que o app não publica): mandar o seek para poucos segundos antes do fim da faixa,
com o app tocando. Se o comando fosse aceito, a faixa terminaria e o app avançaria
para a próxima — e troca de faixa aparece no stream.

- `Welcome to Paradise` (224s) → `seek 219s`, 20s tocando: faixa não terminou, não trocou.
- `Sultans Of Swing` (348s) → `seek 340s`, 15s tocando: faixa não terminou, não trocou.
- Contraprova em app neutro: QuickTime Player, arquivo local de 127s → `seek 100s`;
  o próprio QuickTime reportou `current time = 101,35s`. **O comando funciona.**

**Conclusão.** O `mediaremote-adapter` implementa o seek corretamente e o macOS o
entrega. Quem não implementa o handler é o `Amazon Music.app`. Isso é escolha do app
— nada no widget, no adapter ou na forma de chamar muda o resultado.

**Decisão.** Não haverá seek enquanto o player for o Amazon Music. A barra de
progresso é indicador, e não vira controle. O `seek(toSeconds:)` foi removido em vez
de mantido como código morto, porque a sua presença é o que sustentava a suposição
errada. README e CLAUDE.md corrigidos.

**Relação com a decisão de #01.** São limitações distintas do mesmo app: `#01`
concluiu que a *leitura* da posição após um seek feito dentro do app é irrecuperável;
esta conclui que a *escrita* da posição também é impossível. O app não expõe posição
em nenhuma direção. Reabrir só faz sentido se uma versão futura do Amazon Music
passar a responder ao comando — verificável em um minuto repetindo o teste acima.

## 2026-08-05 · #01 — Arrasto da janela por deny-list de NSViews

**Contexto.** O widget arrastava por qualquer ponto do card, porque
`isMovableByWindowBackground = true` é a única mecânica de arrasto e o AppKit
pergunta ao resultado do `hitTest` se ele permite mover a janela. Como o SwiftUI no
macOS desenha `Text`/`Image`/`Button` em camadas — e não em NSViews —, esse
resultado era sempre o `NSHostingView` inteiro, que responde `true`. Clicar num
botão de transporte e mexer o mouse movia a janela.

**Restrição de plataforma (o ponto que não muda).** `mouseDownCanMoveWindow` é
propriedade da view, não função da posição do clique. **Não existe caminho puramente
SwiftUI para restringir o arrasto por região.** Granularidade por área só se obtém
inserindo uma NSView real na área — o mesmo motivo pelo qual o `NSSlider` de volume
já não arrastava a janela.

**Escolha.** Deny-list: `isMovableByWindowBackground` continua `true`, e cada área de
controle se exclui com `.nonDraggableWindowArea()` (`WindowDragging.swift`), que
injeta uma `NonDraggableNSView` em `.background`. Consequência prática: **toda área
interativa nova da UI precisa desse modifier**, senão volta a arrastar a janela.

- `.background` e nunca `.overlay`: abaixo do conteúdo, o hit-test do SwiftUI segue
  entregando o clique ao controle enquanto o do AppKit encontra a NSView. Em
  `.overlay` a view tampa o controle, e corrigir com `.allowsHitTesting(false)`
  desliga a própria proteção.
- `acceptsFirstMouse` é obrigatório na NSView: a janela é uma `NSPanel` não-ativante,
  e sem isso o primeiro clique com o widget não-key seria consumido só para torná-lo key.

**Alternativas descartadas.** Alça dedicada no topo (allow-list) exigiria cobrir uma
região irregular — capa, coluna de texto, espaços e a moldura de 18pt —, e qualquer
buraco vira área morta. `DragGesture` do SwiftUI compete com o gesto do `Button` e
mede translação em coordenadas que se movem junto com a janela.

## 2026-08-05 · #01 — Posição pós-seek no Amazon Music é irrecuperável

**Contexto.** A barra de progresso não refletia seek feito dentro do
`Amazon Music.app`, o que era registrado como limitação suposta desde `2026-06-26 · #01`.

**Evidência (captura do stream do `mediaremote-adapter`).** Durante o seek, o app
publica exclusivamente:

```
diff=True  {"playing": true}
diff=True  {"playing": false}
```

Sem posição e sem `timestamp` novo. Só na troca de faixa vem um snapshot completo com
`timestamp` fresco. Além disso: o comando `get` do adapter devolve exatamente os
mesmos campos do `stream` (nada de `elapsedTime`), e o `Amazon Music.app` não expõe
dicionário AppleScript (`NSAppleScriptEnabled` ausente, sem `.sdef`).

**Decisão.** Não há segunda fonte de posição. A dessincronia após seek é aceita como
permanente e **não deve ser reinvestigada**. O que era corrigível — a barra travando
em 100% — era bug próprio e foi corrigido (ver abaixo).

## 2026-08-05 · #01 — `diff: false` é snapshot, e snapshot vazio zera o estado

**Contexto.** `handleLine` ignorava o campo `diff` do stream e tratava todo payload
como incremental. Quando o Amazon Music era encerrado, chegava
`{"type":"data","diff":false,"payload":{}}` — "não há sessão de Now Playing" — e o
merge não mudava nada: o `bundleIdentifier` antigo ficava grudado. O play do widget
então caía no `togglePlayPause`, que é **global**, e o macOS o entregava ao Music.app
da Apple, abrindo o app errado.

Isso é o mesmo sintoma que `2026-06-23 · #05` tratou mexendo no default de
`autoLaunchOnPlay` — sem tocar na causa, que ficou latente até ser exposta pelo teste
do app ausente.

**Decisão.** Um snapshot (`diff: false`) sem faixa alguma zera o `TrackInfo`. E
`togglePlayPause` só é enviado com o Amazon Music comprovadamente em execução, como
rede de segurança — comando global nunca sai com o app morto.
