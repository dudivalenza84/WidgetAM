# Decisões — MacMediaWidget

Decisões com efeito além da sessão em que foram tomadas (ADR-lite). Entradas novas
vão no topo. O que está aqui não se rediscute sem motivo novo.

## 2026-08-21 · #03 — O nome do produto é WidPlay

**Contexto.** "MacMediaWidget" fere a diretriz de marcas da Apple, que veda "Mac"
incorporado ao nome (permite "X for Mac", não "MacX"). O nome está no `CFBundleName`, no
`CFBundleDisplayName` e — o que pesa — no `CFBundleIdentifier`. Trocar o identificador
depois do lançamento reseta, na máquina de cada cliente, a permissão de Automação (TCC),
o item de login e o domínio de `UserDefaults`.

**Decisão.** O produto passa a se chamar **WidPlay**, com o identificador
`com.dudivalenza.widplay` (confirmado pelo usuário em 2026-08-21). A troca acontece
**antes** do primeiro build assinado com Developer ID e antes de qualquer material novo
sob o nome antigo.

**Alternativa descartada.** Manter "MacMediaWidget" até depois do lançamento: o custo de
migração cresce a cada cliente vendido, e o risco de notificação jurídica da Apple já
estava registrado no `ROADMAP.md`.

**Verificação feita em 2026-08-21 · #03.**

- **App Store (iOS + Mac, loja US, iTunes Search API):** nenhum app chamado WidPlay. As
  seis correspondências difusas são outros nomes (WePlay, WIDR, WIA TV).
- **Domínios (RDAP):** `widplay.com` **registrado desde 2010-07-16** (registrar
  Unstoppable Domains) e **sem DNS** — nenhum site no ar. Livres: `widplay.app`,
  `widplay.dev`, `widplay.net`, `widplay.co`, `widplay.io`.
- **Antecedente:** existiu uma **WidPlay** em Valência, Espanha — rede social com
  interface de desktop na nuvem —, registrada no Crunchbase como *permanently closed*.
  Os identificadores `@widplay` no GitHub e no X estão ocupados.
- **Marcas:** **não verificado.** Justia e uspto.report bloquearam o acesso automatizado
  (Cloudflare), e as APIs do USPTO e do TMview recusaram a consulta. Nenhum registro
  "WidPlay" apareceu na busca web, o que **não** equivale a busca de anterioridade.

**O que isso permite e o que não permite.** Permite adotar o nome no código agora: não
há conflito de app nem produto ativo com o nome. **Não** dispensa a busca de
anterioridade de marca antes do certificado Developer ID e do lançamento — fica em
`PENDENCIAS.md`.

## 2026-08-21 · #03 — O produto é só para Apple Silicon

**Contexto.** O build atual é arm64 puro (binário e framework do adapter), enquanto o
`Info.plist` declarava macOS 15 — ou seja, um cliente Intel compraria e receberia "não é
possível abrir", sem mensagem útil.

**Decisão.** Não suportar Macs Intel. A exigência entra no app e no material de venda,
para que a instalação recuse com mensagem clara. Revisível no futuro conforme o feedback
dos usuários.

**Alternativa descartada.** Build universal: exigiria o framework do adapter também em
x86_64 (não verificado) e uma máquina Intel para testar, que não existe. Prometer
suporte sem poder testá-lo é o oposto da regra do projeto de não afirmar o que não foi
observado.

## 2026-08-21 · #03 — O requisito mínimo é macOS 26

**Contexto.** O projeto declarava três coisas diferentes: `Info.plist` e `Package.swift`
em macOS 15, README em 26, e o visual Liquid Glass — que é o argumento de venda — só
existe a partir do 26, com fallback nunca testado abaixo disso.

**Decisão.** Exigir **macOS 26+**. `LSMinimumSystemVersion` e `Package.swift` sobem para
26; o README e o material de venda passam a dizer a mesma coisa. Combinado com a decisão
de arm64-only, o público-alvo fica coerente com o que o produto entrega. Revisível
conforme o feedback dos usuários.

**Alternativa descartada.** Suportar 15+: obrigaria a testar e a mostrar no material de
venda o visual de fallback, que não é o produto anunciado.

## 2026-08-21 · #01 — O Safari tem identidade dupla: quem publica a sessão não é quem abre

**Contexto.** Toda a arquitetura de players assume que o `bundleIdentifier` da sessão de
Now Playing é o do app — é essa chave que liga o payload ao `Player`, e dela saem ícone,
nome e abertura. O Safari quebra a premissa: quem publica é `com.apple.WebKit.GPU`, o
processo auxiliar de mídia do WebKit, que não é app instalável, não tem ícone e cujo nome
resolve para `com.apple.WebKit.GPU.xpc`. Era assim que ele aparecia no widget.

**Decisão.** `applicationURL` vira **requisito do protocolo** `Player`, e não só default
da extension — sem isso o despacho pelo existencial ignoraria qualquer sobrescrita. O
`SafariPlayer` casa a sessão por `com.apple.WebKit.GPU` e aponta o app por
`com.apple.Safari`. As duas identidades convivem sem se misturar, como `catalogID` já faz
para os atalhos.

**Alternativa descartada.** Registrar o Safari pelo bundle id do app. Nunca casaria com a
sessão — o widget continuaria mostrando `com.apple.WebKit.GPU` como se fosse um player
desconhecido.

**Consequência medida.** Safari e Chrome **não** são o mesmo navegador para efeito de
mídia: no Safari `next`, `previous` e `seek` funcionam, e o campo `playing` não mente; no
Chrome, dois desses falham e o `playing` foi flagrado errado. Ter deixado o Safari fora do
catálogo até medir (`DECISOES.md · 2026-08-20 · #01`) evitou declarar por dedução um
perfil errado nas duas pontas.

## 2026-08-21 · #01 — O conteúdo do card se contrasta com o card, não com o tema

**Contexto.** O card é vidro tonalizado pela capa da faixa, mas texto e botões pediam suas
cores à hierarquia do sistema (`.primary`/`.secondary`), que segue o **tema** claro/escuro.
Com uma capa quase preta — o Black Album do Metallica — o tint escurecia o card e o
conteúdo continuava escuro: botões invisíveis sobre o próprio fundo.

**Decisão.** A cor do conteúdo sai da luminância percebida da capa combinada com a
opacidade do tint, sobre a luminância do vidro no tema atual (`CardContrast`). Como todo o
card já pedia cor pela hierarquia, definir os três estilos na raiz resolve título,
artista, botões, barra e volume de uma vez. Com o tint em zero nada muda — sem
tonalização, quem manda é o tema.

**Por que a conta ficou fora da view.** É pura e testável, e o modo de falhar dela — um
controle que some — não aparece em teste de UI nenhum: depende de qual capa está tocando.

## 2026-08-21 · #01 — "Trocar app" troca quem toca, até onde a plataforma deixa

**Contexto.** O item "Trocar app" definia o preferido e abria o app escolhido. No modo
automático — que é o padrão — o card espelha a **sessão** de Now Playing, e a sessão
continua com o app anterior até alguém dar play no novo. Resultado observado ao vivo: o
usuário escolhe Amazon Music, o app abre, e o widget segue mostrando o outro app. A ação
não tem efeito visível, que é o mesmo defeito que a decisão de `2026-08-11 · #01` (abrir
o app ao trocar) tentou resolver pela metade.

**Decisão.** Trocar de app passa a significar trocar quem toca: o widget silencia a
sessão atual (`pause`, que vai justamente para quem a detém) e entrega o palco ao
escolhido. Quanto ele consegue entregar depende do app:

- **endereçável** (Apple Music, Spotify): o play chega por AppleScript e o app assume a
  sessão na hora — a troca acontece de verdade;
- **os demais** (Amazon Music, TIDAL, Deezer, navegador): não há como entregar um play a
  um app específico, e um play global voltaria para a sessão antiga. A troca para em
  silenciar o anterior e trazer o novo à frente; quem completa é o usuário.

Trocar para o app que **já** detém a sessão não pausa nada — seria estragar o estado que
já estava certo.

**Alternativa descartada.** Fazer o widget exibir o app escolhido **no lugar de quem
está tocando**, no modo automático. Seria mentir sobre o que toca, e desmancharia a
distinção entre os dois modos — exibir o escolhido independente da sessão é exatamente o
que o modo fixo faz.

**Complemento (mesma sessão, decidido pelo dono do produto).** Com **ninguém** tocando não
há o que espelhar, e aí o card passa a identificar o preferido — ícone, nome e o motivo de
não haver transporte. Não há mentira possível nesse estado, e é o que dá efeito visível ao
"Trocar app" com o Mac em silêncio. Assim que qualquer app começa a tocar, o automático
volta a espelhar quem toca.

**Nota de cobertura.** Isto destravou o teste da pendência de `2026-08-19 · #02`: com
`simulateSession(bundleIdentifier:isPlaying:)` em debug, dá para montar "app X tocando" e
asserir para onde o comando vai — o que antes não tinha como.

## 2026-08-20 · #01 — O widget não afirma estado que a fonte não garante

**Contexto.** O card diz "tocando" ou "pausado" a partir do campo `playing` do stream, e
faz a barra correr com base nele. No navegador esse campo erra: houve leitura de
`playing=True` com o vídeo comprovadamente pausado, lido em `document.querySelector(
'video').paused`. O widget então mostrava o ícone de pausa, o texto "está tocando" e uma
barra avançando — três afirmações erradas com a mesma origem.

**Decisão.** Capacidade `.reliablePlaybackState`, declarada por todo app nativo medido e
ausente no `BrowserPlayer`. Sem ela o widget **para de afirmar**: o botão central vira
`playpause.fill` (que é literalmente o que ele faz — alternar), o status do menu mostra só
o nome da faixa, e a estimativa de posição não soma tempo de parede. É o mesmo princípio
de `.streamPosition`, aplicado ao outro campo que o navegador falsifica.

**Alternativa descartada.** Inferir o estado real observando a página por
`execute javascript`. Funciona como instrumento de medição e não serve como produto:
depende de "Permitir JavaScript de Apple Events", que o usuário liga à mão no menu
Desenvolvedor (`docs/fase1-multiplayer.md` §2).

**Alternativa descartada.** Manter o ícone chutando. Um botão que mostra "pausar" com a
mídia pausada não é um detalhe cosmético: é o widget afirmando o oposto do que o usuário
está vendo na tela ao lado.

## 2026-08-20 · #01 — Transporte deixa de ser um bloco só: `next` e `previous` viram capacidades separadas

**Contexto.** `PlayerCapabilities.transport` significava "play, pause, próxima, anterior"
— um pacote indivisível, presumido para qualquer fonte. A bateria de medição de
`2026-08-19 · #02` derrubou a premissa em dois lugares: o **Deezer ignora `previous`**
(com a faixa em 42,8 s o comando não trocou de faixa nem reiniciou a atual — passou em
branco) e o **navegador ignora `next`** (o vídeo seguiu correndo, `t=110` → `t=114`),
além de `previous` rebobinar a mídia atual em vez de trocar.

**Decisão.** `.transport` passa a significar só **play/pause**, e existem
`.nextTrack` e `.previousTrack` separadas, mais o atalho `.fullTransport` para quem tem
as três. Quem foi medido faltando uma peça declara o conjunto na mão. A UI (widget e
menu) desabilita o botão correspondente e explica por quê — "O Deezer não aceita este
comando" — em vez de mostrar um botão que o app engole em silêncio.

**Alternativa descartada.** Manter o bloco único e deixar o botão morto. É a mesma
mentira que a capacidade `.seek` existe para impedir: quando o app ignora o comando, quem
leva a culpa é o widget, e não há como o usuário descobrir a diferença.

## 2026-08-20 · #01 — O seek do MediaRemote entra como caminho real, com a capacidade decidindo caso a caso

**Contexto.** O widget só sabia fazer seek por AppleScript, então TIDAL e navegador —
que não têm dicionário — ficariam com a barra travada em leitura. Mas os dois **obedecem**
ao posicionamento do MediaRemote, provado por observação: no TIDAL a faixa de 30 s
posicionada em 25,99 s terminou 5 s depois; no navegador o `currentTime` do `<video>` foi
para 45 s. Amazon Music e Deezer, no mesmo teste, ignoram.

**Decisão.** `MediaRemotePlayer.seek(to:)` passa a mandar `seek <microssegundos>` ao
adapter, e a capacidade `.seek` continua sendo declarada só por quem foi medido
obedecendo. O comando não tem destinatário, então vale apenas enquanto o player **for** a
sessão de Now Playing — `canControlTransport` já garante isso antes da chamada.

**Alternativa descartada.** Deixar o seek exclusivo da camada AppleScript. Custaria a
barra arrastável em dois dos quatro players novos, sem ganho de segurança: a proteção
contra o "aceita e ignora" está na capacidade, não no canal.

## 2026-08-20 · #01 — Atalho de serviço web se identifica por `catalogID`, não pelo bundle id

**Contexto.** O YouTube Music entra no catálogo como atalho, com id sintético
(`service.youtube.music`), mas o `Player` que o representa precisa carregar o bundle id do
PWA — é dele que saem ícone, caminho de instalação e abertura. Os dois pontos onde o
usuário escolhe um player (o menu "Trocar app" e o seletor de preferido) gravavam
`player.bundleIdentifier`, o que salvaria o bundle do PWA como preferido: uma chave que
não existe no catálogo, e que portanto não casa com nada — nem com a lista de ocultos,
nem com a nota de "abre no navegador".

**Decisão.** `Player` ganha `catalogID`, igual ao `bundleIdentifier` em todo app de
verdade e sintético só nos atalhos. Tudo que o usuário escolhe ou oculta passa a usar
`catalogID`; o `bundleIdentifier` continua sendo o que casa com a sessão do MediaRemote.

**Alternativa descartada.** Dar ao atalho o id sintético como `bundleIdentifier`. Ele
perderia ícone e caminho de abertura, porque `applicationURL` e `icon` moram numa
extension de protocolo (despacho estático) e não dá para sobrescrevê-las por baixo do
existencial `Player`.

## 2026-08-20 · #01 — Safari fica fora do catálogo até ser medido

**Contexto.** A Tarefa 3 do plano previa Chrome e Safari como entradas do catálogo, com o
mesmo `BrowserPlayer`. Só o Chrome foi medido; o perfil dele (play/pause e seek sim,
`next`/`previous` não) é comportamento do par navegador+página, não uma constante do
canal.

**Decisão.** Só o Chrome entra. Sem entrada no catálogo, o Safari continua caindo no
`MediaRemotePlayer` genérico, exatamente como hoje — nenhuma regressão — e o usuário ainda
pode ocultá-lo pela lista de fontes descobertas. Medir o Safari está em `PENDENCIAS.md`.

**Alternativa descartada.** Copiar o perfil do Chrome para o Safari. Seria a primeira
capacidade declarada por dedução no projeto, contra a regra que originou a matriz.

## 2026-08-19 · #02 — O observador de um teste de capacidade tem que ser do domínio do player, não do MediaRemote

**Contexto.** A regra do projeto era "comando aceito sem erro não é comando funcionando",
nascida do Amazon Music, que aceita o seek e o ignora. O `scripts/testar-player.sh` a
implementa lendo o **payload do Now Playing** depois de agir. Na bateria do navegador isso
falhou pelo lado oposto: o comando funcionou e o payload mentiu. O roteiro reportou
`play/pause | NÃO FUNCIONA | playing continuou True` com o vídeo comprovadamente pausado,
lido em `document.querySelector('video').paused`.

**Decisão.** Ler o payload do MediaRemote é válido só quando o payload daquele player já
se provou confiável. Onde ele não é — navegador, hoje —, o observador tem que ser o
domínio do player: a página via `execute javascript` no Chrome, o `player state` do
AppleScript onde existe. Nenhuma célula da matriz entra com base num campo que aquele
mesmo player já foi visto publicando errado.

**Alternativa descartada:** confiar no payload e marcar o navegador como sem transporte.
Seria registrar como limitação do app um defeito do instrumento — e o widget perderia
controle de aba de navegador, que funciona.

**Consequência.** Vale para os dois sentidos: um "funciona" e um "não funciona" lidos no
payload de fonte não confiável são igualmente inválidos. Três células desta sessão teriam
entrado erradas sem isso.

## 2026-08-19 · #02 — Ocultar um app não pode derrubar comando endereçado

**Contexto.** O plano da Tarefa 7 mandava `canControlTransport` retornar `false` sempre
que a sessão ativa fosse de um app oculto. No modo fixo com um player endereçável
escolhido (hoje Apple Music, amanhã Spotify), o comando **não vai** para a sessão ativa —
vai por AppleScript para o app escolhido. Um app oculto tocando desligaria um transporte
que continua perfeitamente funcional.

**Decisão.** O filtro de visibilidade só se aplica quando a permissão de transporte viria
da própria sessão ativa: `if isControlledPlayerActive { return !isActiveSourceHidden }`.
Pelo mesmo motivo, `isActiveSourceHidden` é `false` no modo fixo quando o controlado não é
a sessão — senão o card avisaria "X está tocando · oculto" sobre um app que ele nem
estava exibindo.

**Alternativa descartada:** seguir o plano ao pé da letra. Simples de escrever e errado no
caso que o modo fixo existe para atender.

## 2026-08-19 · #01 — Serviço que roda dentro do navegador é atalho de lançamento, nunca identidade de sessão

**Contexto:** ao planejar a entrada do YouTube Music, a ideia inicial era tratá-lo como
app próprio, já que o PWA instalado tem bundle id (`com.google.Chrome.app.cinhim…`).
Apurado nesta sessão: o `open` do PWA não deixa processo algum, nenhum processo do
Chrome traz `--app-id`, e o shim `app_mode_loader` é apenas um lançador — quem reproduz
o áudio é o processo do Chrome. Como o MediaRemote identifica a sessão pelo processo
(o payload traz `processIdentifier` ao lado de `bundleIdentifier`), a sessão sai como
`com.google.Chrome` com ou sem PWA funcionando.

**Escolha:** o catálogo de players distingue `kind: .app` (identifica sessão **e** é
lançável) de `kind: .shortcut` (só lançável). YouTube Music é `.shortcut`, aberto por
`appElseURL(PWA, music.youtube.com)`, e a fonte continua rotulada como o navegador.

**Alternativa descartada:** rotular a sessão do Chrome como "YouTube Music" quando a
entrada estivesse ativa. Descartada porque qualquer outra aba com áudio — um vídeo,
uma videochamada, outro serviço — receberia o mesmo rótulo. O widget mostra o que sabe;
inventar identidade é a mesma classe de erro do seek do Amazon Music, que "funcionava"
até alguém olhar o resultado.

**Nota:** o PWA não abrir é defeito do shim (provável descasamento com o Chrome 151) e
se conserta reinstalando pelo Chrome. Independe do widget, e consertá-lo não mudaria
esta decisão.

## 2026-08-19 · #01 — Visibilidade de player é lista de ocultos (blocklist), não de escolhidos

**Contexto:** o dono do produto pediu checkboxes em Preferências para escolher quais
apps o widget controla, e decidiu que a marcação afeta também a exibição — app
desmarcado tocando é ignorado pelo widget.

**Escolha:** `AppSettings.hiddenPlayerIDs: Set<String>`, com padrão vazio. A UI é a
lista de checkboxes pedida; o que persiste é o complemento.

**Alternativa descartada:** guardar a lista dos marcados. Descartada porque o catálogo
não é fechado — o widget controla qualquer fonte que publique Now Playing, inclusive
apps que o código nunca viu. Com allowlist, todo player novo nasceria desmarcado e,
por causa do filtro de exibição, o widget ficaria mudo diante dele: regressão direta
sobre o comportamento atual. Com blocklist, o padrão é tudo visível e o checkbox só
subtrai.

**Consequência:** o player preferido nunca pode ser ocultado (checkbox travado) e
ocultar todos é bloqueado — assim o modo fixo apontando para app oculto deixa de ser
um estado alcançável.

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
