# Decisões — MacMediaWidget

Decisões com efeito além da sessão em que foram tomadas (ADR-lite). Entradas novas
vão no topo. O que está aqui não se rediscute sem motivo novo.

## 2026-08-13 · #01 — View custom em `NSMenuItem` precisa de largura explícita na `View`, não só no `NSHostingView.frame`

**Contexto:** a linha de status do menu (nome da faixa) ganhou largura fixa e
letreiro para nome longo. Com a largura só no `NSHostingView.frame`, o letreiro
nunca detectava overflow e ficava parado — sintoma que só apareceu com instalação
real (`.app`) e virou vídeo de bug report, não em teste automatizado.

**Causa raiz:** dentro de `NSMenu`, o `NSHostingView` faz o layout do conteúdo pelo
seu tamanho ideal (`.frame(maxWidth: .infinity)` vira propostas flexíveis, não
limitadas pela largura do item) — o `frame` do `NSHostingView` em si é ignorado
para efeito de proposta de layout ao SwiftUI.

**Escolha:** a largura vai explícita como parâmetro da `View` (ex.:
`.frame(width:)` aplicado na `rootView`, ou um parâmetro de largura que a view usa
internamente para o cálculo de overflow) — nunca só no `hosting.frame`. Vale para
qualquer view custom futura num item de menu onde a largura afeta o comportamento
(não só a aparência).

**Descartado:** nada — bug de primeira implementação, não uma escolha entre
alternativas.

## 2026-08-12 · #01 — Identidade visual: conceito "Órbita", assets gerados de SVG por pipeline nativo

**Contexto:** o app não tinha ícone, favicon nem marca; a bandeja usava o SF Symbol
genérico `music.note.list`.

**Escolha:** conceito **Órbita** — play dentro de anel de progresso interrompido,
gradiente ciano (#22D3EE) → violeta (#8B5CF6) sobre grafite — escolhido pelo usuário
numa prancheta de 4 conceitos (artifact). A fonte da verdade são os SVGs de
`Resources/icon/` (`icon-master`, `icon-small` para 16/32 px, `menubar-template`);
**todo asset derivado sai de `scripts/gerar-icones.sh`** (icns, favicon, bandeja),
que renderiza via `scripts/render-svg.swift` usando o suporte nativo do AppKit a SVG
(CoreSVG, macOS 11+) — sem dependência de brew/rsvg. Na UI, a marca é o `BrandMark`
(vetor SwiftUI com a mesma geometria), nunca um PNG.

**Descartado:** conceitos A (tile), B (equalizador) e C (nota); renderização por
rsvg-convert/ImageMagick (dependência nova para tarefa que o AppKit já faz).

## 2026-08-12 · #01 — Transporte no menu é view custom lado a lado, e clicar não fecha o menu

**Contexto:** botões ⏮ ⏯ ⏭ no menu de contexto/bandeja podiam ser 3 itens comuns ou
uma linha custom.

**Escolha:** linha única com os três botões em `NSHostingView` dentro de `NSMenuItem`
(estilo Controle Central). View custom não dispara a seleção do menu, então ele fica
aberto — dá para pausar e pular várias faixas em sequência. Escolha do usuário entre
as duas opções.

**Descartado:** 3 `NSMenuItem` comuns — o menu fecharia a cada clique, exigindo
reabrir para cada comando.

## 2026-08-11 · #03 — Tamanhos do widget são os footprints da grade nativa (1×1 e 2×1)

**Contexto:** o usuário quer escolher entre widget largo (como o de previsão do tempo)
e compacto quadrado (como relógio/calendário nativos).

**Escolha:** a preferência `widgetSize` oferece exatamente os formatos da grade já
medida em `NativeWidgetGrid` — 1 célula (170×170 de card) ou 2 células de largura
(350×170) — e as dimensões são **derivadas** de `pitch`/`cardInset`, não constantes
soltas. No compacto, a sidebar vertical de volume vira slider horizontal no rodapé
(não cabe nos ~142 pt úteis) e a capa vira miniatura ao lado dos textos; os botões de
transporte mantêm os mesmos alvos de 28 pt. A troca aplica ao vivo preservando o canto
superior esquerdo (âncora do snap) e realinhando à grade. O snap deixou de ler
`WidgetMetrics.height` fixo e deriva a altura do card da própria janela.

**Alternativa descartada:** tamanho livre (largura/altura arbitrárias em slider).
Quebraria o alinhamento célula-a-célula com os widgets nativos, que é o diferencial
visual do produto — o card deixaria de "pertencer" à mesa.

## 2026-08-11 · #01 — "Trocar app" troca o player preferido E abre o app

**Contexto:** o submenu "Trocar app" (menu da bandeja e do clique direito) define o
player preferido. No modo automático, com outro app tocando, só trocar a preferência
não teria efeito visível nenhum — a ação pareceria quebrada.

**Escolha (do dono do produto):** além de definir o preferido, escolher no submenu
abre/traz à frente o app escolhido na hora.

**Alternativa descartada:** só trocar a preferência (comportamento idêntico ao seletor
das Preferências). Descartada pelo motivo acima.

## 2026-08-11 · #01 — Atalho global fixo ⌃⌥⌘M via Carbon; elevação temporária separada da preferência

**Contexto:** trazer o widget (janela em nível de mesa) à frente exige um atalho que
funcione com o app em background. `NSEvent.addGlobalMonitor` exige permissão de
Acessibilidade; bibliotecas de atalho seriam dependência nova embrulhando a mesma API.

**Escolha:** Carbon `RegisterEventHotKey` (`GlobalHotKey.swift`), combinação fixa
⌃⌥⌘M — três modificadores para não colidir com atalhos de outros apps. O aperto eleva
para `.floating` como estado **temporário** (`isTemporarilyRaised`), desfeito no
segundo aperto ou ao perder key; a preferência persistida `keepAbove` é outra coisa e
não é tocada pelo atalho.

**Alternativas descartadas:** atalho configurável com gravador de tecla (escopo sem
demanda; a combinação é exibida nas Preferências), monitor global de eventos (permissão
de Acessibilidade sem necessidade).

## 2026-08-10 · #01 — Testes rodam dentro do binário, porque as CLT não têm framework de teste

**Contexto.** A Fase 2 do ROADMAP pede cobertura do que é testável sem UI. O caminho
normal — `testTarget` no `Package.swift` com swift-testing ou XCTest — **não compila
neste projeto**: as Command Line Tools não trazem nenhum dos dois frameworks (só o Xcode
completo traz). `swift test` morre em `no such module 'Testing'` antes da primeira linha,
e `/Library/Developer/CommandLineTools/Library/Frameworks/` só tem `Python3.framework`.

**Escolha.** As asserções vivem em `Sources/MacMediaWidget/SelfTests.swift`, dentro do
próprio módulo, atrás de `#if DEBUG`, e rodam com `swift run MacMediaWidget --run-tests`
(saída 0/1, contagem e lista de falhas). Estar no mesmo módulo dá acesso ao escopo
interno de graça — a alternativa seria tornar pública metade da API só para poder
testá-la. `#if DEBUG` mantém tudo isso fora do `.app` de release.

**Alternativas descartadas.** (1) Exigir o Xcode completo: ~10 GB e uma dependência nova
de ambiente, decisão que é do dono do projeto e não de uma sessão de trabalho. (2) Quebrar
o app em biblioteca + executável fino para que um alvo de testes pudesse importá-lo:
refactor estrutural cuja única motivação seria contornar a ausência do framework, e que
ainda exigiria `public` em tudo que os testes tocam.

**Quando revisitar.** Se o Xcode entrar no projeto (a Fase 4 precisa dele para
notarização? não — `notarytool` vem nas CLT), migrar para swift-testing é mecânico: as
funções já são independentes. Está em `PENDENCIAS.md`.

## 2026-08-10 · #01 — Idioma-base do código passa a ser inglês

**Contexto.** A Fase 2 exige a UI em inglês para vender fora do Brasil. O código tinha as
strings em pt-BR literais, espalhadas por nove arquivos.

**Escolha.** Inglês vira o idioma-base: a **chave** de cada string é o próprio texto em
inglês, e `Resources/pt-BR.lproj/Localizable.strings` traz a tradução. Todas as strings
ficam centralizadas em `L10n.swift`. Duas consequências boas: rodando o binário solto em
desenvolvimento (sem bundle, sem `.lproj`), o fallback é a chave — ou seja, inglês legível
em vez de identificadores crus; e traduzir vira ler um arquivo, não caçar literais.

**O risco que isso cria, e a mitigação.** `String(localized:)` cai no inglês **em
silêncio** quando a chave não existe: um typo não quebra o build, não gera aviso e não
aparece em teste — só na tela de quem usa em português. Como o `genstrings` não enxerga
`String(localized:)` e não há Xcode aqui, criei `scripts/verificar-traducoes.sh`, que
extrai as chaves do `L10n.swift` e compara com cada `.lproj` nos dois sentidos (sem
tradução / órfãs). É por isso que centralizar as strings num arquivo só deixou de ser
estilo e virou requisito: a verificação depende disso.

**Isto não muda a regra de idioma do projeto.** Explicação, commit, comentário de código,
arquivo de sessão, pendência e decisão continuam em pt-BR. O que passou para inglês é a
*interface do produto* e as chaves de localização.

## 2026-08-10 · #01 — Arquitetura da Fase 1: duas camadas, dois modos de controle

**Contexto.** Levantamento completo em `docs/fase1-multiplayer.md`. O fato que determina
tudo: **o comando do MediaRemote não tem destinatário** — o adapter só atua sobre a
sessão de Now Playing do sistema, sem parâmetro de bundle id (verificado no `help` do
adapter). Direcionar comando a um app específico só é possível via AppleScript, que
Apple Music tem (`.sdef` de 44,7 KB com `player position` gravável, `sound volume`,
`shuffle`, `repeat`) e o Amazon Music não tem (reconfirmado hoje). Chrome e Safari têm
AppleScript, mas **zero** capacidade de mídia — para navegador só existe MediaRemote.

**Escolhas.**

1. **Duas camadas.** MediaRemote continua a única fonte de leitura e o transporte padrão
   (funciona com qualquer fonte, inclusive imprevista). AppleScript entra como camada
   opcional por app, só para o que o MediaRemote não dá: posição real, seek, volume
   por-app, shuffle/repeat e comando direcionado.
2. **Dois modos de controle, com chave nas preferências.** Automático (espelha quem está
   tocando) como padrão; fixo (controla sempre o player escolhido) como opção.
3. **No modo fixo, com player sem AppleScript fora da sessão ativa:** o play abre o app e
   espera ele virar a sessão antes de enviar o comando (mecânica que já existe para o
   Amazon Music); next/prev/seek ficam **desabilitados com o motivo à vista**. Comando
   global nunca sai às cegas — é o bug de `2026-08-05 · #01`, e a generalização não pode
   reintroduzi-lo.
4. **Volume por-app onde existir**, sistema no resto, com a UI indicando o alvo. Volume
   por-app é uma das duas razões de existir da camada AppleScript.
5. **Escopo da Fase 1 sem esperar instalação:** desenvolve com Amazon Music + Apple Music
   + navegador. Apple Music é o player mais capaz da lista e valida a camada inteira.
   Spotify/Deezer entram como "mais um adaptador", sem retrabalho. O critério de saída do
   ROADMAP (que exige Spotify) só fecha depois de instalado.
6. **Capacidade declarada é degradável em runtime.** Tabela de capacidades não é
   confiança: automação negada faz o AppleScript falhar em silêncio, então a capacidade
   cai sozinha. E nada entra na matriz como "presumido" — comando aceito sem erro ≠
   comando funcionando (lição do seek do Amazon).

**Alternativas descartadas.** Só modo automático: perderia o controle direcionado que o
AppleScript viabiliza em Apple Music/Spotify. Só modo fixo: no Amazon Music o mesmo
controle se comportaria diferente sem explicação. Volume sempre do sistema: jogaria fora
metade do ganho do AppleScript. JavaScript injetado para controlar mídia em navegador:
depende de uma opção do menu Desenvolvedor ligada à mão — inviável como produto.

**Custo aceito.** A Fase 1 introduz o prompt de permissão de Automação (um por app-alvo),
que o app hoje não dispara — o `set volume` fala com o sistema, não com um app. Exige
`NSAppleEventsUsageDescription` no `Info.plist` e, na Fase 4 com hardened runtime, a
entitlement `com.apple.security.automation.apple-events`.

## 2026-08-10 · #01 — Barra de progresso volta a ser controle onde o seek funciona

**Contexto.** `2026-08-05 · #02` decidiu que "a barra de progresso é indicador, e não vira
controle". A decisão foi correta, mas o contexto era mono-player: o Amazon Music ignora o
comando de posicionamento. No Apple Music o seek funciona (`player position` é gravável
via AppleScript).

**Decisão.** A decisão anterior fica **delimitada ao Amazon Music e a qualquer fonte sem
seek comprovado**. A barra vira controle arrastável apenas onde a capacidade `.seek`
existir e tiver sido verificada empiricamente; nas outras continua indicador. O
`seek(toSeconds:)` removido não volta pelo caminho do MediaRemote — volta pela camada
AppleScript do player que o suporta.

**Consequência de implementação.** A barra passa a ser área interativa, logo precisa de
`.nonDraggableWindowArea()`, senão arrasta a janela (`2026-08-05 · #01`).

## 2026-08-10 · #01 — Único terceiro redistribuído: mediaremote-adapter (ungive), BSD-3-Clause

**Contexto.** A pendência de licenças partia de duas premissas erradas: que o adapter
bundlado era "o fork do ejbills" e que a licença seria "MIT presumida"; e tratava
`media-control` e o adapter como dois terceiros distintos.

**Apuração.** Pela API do GitHub: `ungive/mediaremote-adapter` é a **origem**
(BSD-3-Clause, `Copyright (c) 2025, Jonas van den Berg and contributors`);
`ejbills/mediaremote-adapter` é **fork** dela, sem licença própria. `ungive/media-control`
é o CLI construído sobre o adapter, que ele incorpora como submódulo git, do mesmo autor
e da mesma licença (declarada no README; a fórmula do Homebrew registra BSD-3-Clause).
O `build-app.sh` copia **apenas** `mediaremote-adapter.pl` e
`MediaRemoteAdapter.framework` — o executável `media-control` não é redistribuído.

**Decisão.** Há **um** terceiro no bundle, não dois: o `mediaremote-adapter` de `ungive`,
BSD-3-Clause. Texto integral e obrigações práticas em `Resources/THIRD-PARTY-LICENSES.md`,
que o `build-app.sh` passa a copiar para dentro do `.app` — a cláusula 2 exige que o aviso
acompanhe a redistribuição binária, e um arquivo só no repositório não cumpre isso. A
cláusula 3 proíbe usar o nome do autor para endossar o produto: material de venda pode
descrever o mecanismo, não sugerir aval. Sem copyleft — o código do app segue fechado.
README e CLAUDE.md, que citavam o ejbills, foram corrigidos.

**Nota de método.** A leitura da página HTML do repositório afirmou um arquivo `LICENSE`
na raiz do `media-control` que **não existe** lá (a listagem de conteúdo da API não o
traz). O dado bom veio da API e do cabeçalho do próprio `.pl` bundlado. Resumo de página
não é evidência.

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
