# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

> As pendências abaixo saíram da auditoria de `2026-08-21 · #02`. O plano completo, com
> as cinco ondas e o porquê da ordem, está em `docs/auditoria-comercializacao.md`; a
> evidência de cada achado, em `docs/auditoria-achados-2026-08-21.md`. Aqui ficam só os
> itens que precisam de dono — não repetir os 76 achados neste arquivo.

> **Atualização `2026-08-21 · #03`.** A auditoria foi reescrita em linguagem executável
> no artifact "Auditoria do MacMediaWidget"
> (<https://claude.ai/code/artifact/300b06cd-90ef-4df9-95cf-68d8786bd903>), onde os 76
> achados viraram **27 itens**: 5 decisões e 22 tarefas. O usuário liberou **15 tarefas**
> e elas estão sequenciadas em **nove sessões** no próprio artifact (seção "Ordem de
> trabalho"): S1 identidade (item 2) · S2 testes de ancoragem (21) · S3 subprocesso com
> prazo (4) · S4 poll e volume (5, 6) · S5 alvo de volume e permissão negada (10, 15) ·
> S6 energia (7, 8, 9) · S7 parser e roteamento (11, 12) · S8 primeira abertura (16, 14)
> · S9 acessibilidade (13). O artifact é a fonte do estado de cada item (liberado /
> entregue / testado); este arquivo é a fonte do que ainda **não** tem dono.


- [ ] **Onda 1 — o que precisa estar certo ANTES de assinar com Developer ID.** Depois
  do certificado, estes custam migração forçada de todos os clientes:
  (a) **remover as duas entitlements dyld** de `Resources/MacMediaWidget.entitlements`
  (`allow-dyld-environment-variables` e `disable-library-validation`) — a justificativa
  no comentário é tecnicamente falsa, o hardened runtime não bloqueia `exec` de binário
  de plataforma e o framework é carregado pelo processo do perl; elas só se aplicam no
  build Developer ID, ou seja, **a versão vendida seria a vulnerável**, notarizada;
  (b) **decidir o nome definitivo e o bundle id** — "Mac" incorporado fere a diretriz de
  marcas da Apple, e trocar o id depois reseta TCC, item de login e preferências;
  (c) **alinhar o requisito de sistema** entre `Info.plist` (15.0), `Package.swift`,
  README (26) e material de venda, e decidir Intel: universal ou arm64 declarado
  — `2026-08-21 · #02`

- [ ] **Onda 2 — a dívida estrutural: uma implementação assíncrona de subprocesso.**
  Fila de dispatch própria, `terminationHandler` com `withCheckedContinuation`, os dois
  pipes drenados concorrentemente, watchdog com `terminate()` e status de saída checado
  e logado. Substitui as três cópias atuais (`AppleScriptRunner`,
  `SystemVolumeController`, `MediaRemoteAdapter`) e fecha cinco achados de uma vez —
  inclusive o congelamento silencioso por stderr não drenado do processo de stream, que
  o verificador apontou como o pior modo de falha do arquivo. Junto: guarda de chamada
  em voo no poll de posição e coalescência na escrita de volume (o padrão certo já
  existe vinte linhas ao lado, no `SystemVolumeController`) — `2026-08-21 · #02`

- [ ] **Onda 3 — o app não fica ocioso quando nada toca.** Poll de posição a 1 Hz roda
  mesmo com a música pausada (~86 mil `osascript`/dia); o timer de 2 Hz publica
  `displayedElapsed` sem checar mudança, re-renderizando três hierarquias SwiftUI
  inclusive com o widget oculto; letreiros a 30 Hz rodam num item de menu fechado; e o
  `body` do `ContentView` consulta LaunchServices a cada avaliação. Medir com
  `powermetrics` antes e depois — a auditoria leu código, não mediu — `2026-08-21 · #02`

- [ ] **O alvo do volume nunca é reavaliado, e com Automação negada o slider morre.**
  `retarget()` só dispara na troca de bundle id, mas a decisão depende de `isRunning` e
  das capacidades. No modo fixo o id nunca muda, então nunca reavalia. Pior: o
  comentário em `AppleScriptPlayer.swift:157-161` promete que após um `-1743` o router
  passa ao volume do sistema — não passa, e o volume é **o único comando sem fallback
  para o MediaRemote**. Corrigir por evento (`NSWorkspace.didLaunch`/`didTerminate` +
  reavaliação após `-1743`) e reler o valor por listener do CoreAudio, não por polling
  — `2026-08-21 · #02`

- [x] **Tarefa 0 do plano — bateria de testes nos players (gate do desenvolvimento):**
  rodar `scripts/testar-player.sh` em `com.spotify.client Spotify`, `com.tidal.desktop`,
  `com.deezer.deezer-desktop` e `com.google.Chrome`, cada um com fila de **3+ faixas**
  tocando (com uma faixa só, `next` dá falso negativo). Inclui o teste observável do
  seek do Spotify (posicionar a 5 s do fim) e a leitura do bundle id que a sessão do PWA
  do YouTube Music publica. Nenhuma capacidade entra no código antes disso. Roteiro
  completo em `docs/plano-players-adicionais.md` — `2026-08-19 · #01` · **feito em
  `2026-08-19 · #02`**: matriz completa em `docs/compatibilidade-players.md`

- [x] **Implantar os players adicionais** seguindo `docs/plano-players-adicionais.md`.
  Tarefas 0, 1, 5, 6, 7 e 8 em `2026-08-19 · #02`; **2, 3, 4 e 9 em `2026-08-20 · #01`**
  (1.17.0). Fecha o critério de saída da Fase 1 do ROADMAP, que exigia o Spotify
  — `2026-08-19 · #01`

- [x] **As capacidades das Tarefas 2 e 3 vêm da matriz, não do plano.** O
  `docs/plano-players-adicionais.md` escreveu as `PlayerCapabilities` a partir do `.sdef`,
  antes da evidência existir; `docs/compatibilidade-players.md` agora contradiz o plano em
  pontos concretos — Deezer sem seek e sem `previous`, navegador sem `next` e com
  `previous` que rebobina. Na dúvida entre os dois documentos, **manda a matriz**
  — `2026-08-19 · #02`

- [x] **Player com AppleScript perde o transporte quando a Automação é negada.**
  `AppleScriptPlayer.capabilities` rebaixa para `unscriptedCapabilities` — que inclui
  `fullTransport` —, mas `playPause`/`next`/`previous` do Apple Music e do Spotify
  continuam indo por `tell`, e `tell` retorna cedo assim que `isAuthorizationDenied` vira
  `true`. Resultado: o widget promete transporte e não faz nada. A correção é cair no
  MediaRemote (`super`) nesse estado. Bug **anterior** a esta sessão, encontrado ao mexer
  no rebaixamento — `2026-08-20 · #01` · **corrigido em `2026-08-20 · #01`**: o
  vocabulário da iTunes suite subiu para `AppleScriptPlayer`, com fallback para o
  MediaRemote em transporte e seek, coberto por teste (`MediaRemoteAdapter.commandSink`)

- [x] **O navegador mente em `playing` e o card acredita.** Houve leitura de
  `playing=True` com o vídeo comprovadamente pausado
  (`docs/compatibilidade-players.md`, nota ⁶). A posição já está protegida — o
  `BrowserPlayer` não declara `.streamPosition` —, mas o ícone play/pause e a estimativa
  da barra ainda seguem o campo. Precisa de um caminho equivalente ao da posição: não
  confiar em `playing` para fonte de navegador — `2026-08-20 · #01` · **corrigido em
  `2026-08-20 · #01`**: capacidade `.reliablePlaybackState`; sem ela o botão vira
  `playpause.fill`, o status do menu mostra só o nome da faixa e a barra não corre
  sozinha

- [x] **Medir o Safari** e decidir se ele entra no catálogo — `2026-08-20 · #01` ·
  **feito em `2026-08-21 · #01`: entrou**, e a medição mudou a premissa. A sessão dele sai
  sob `com.apple.WebKit.GPU`, não `com.apple.Safari`, e o transporte é **mais** capaz que
  o do Chrome (next e previous funcionam, seek também). Copiar o perfil do Chrome teria
  errado nas duas pontas

- [x] **Confirmar visualmente o play/pause do Safari** — `2026-08-21 · #01` · **feito na
  mesma sessão**, com o JavaScript por Apple Events ligado: o campo `playing` acompanhou a
  página nos três estados, e o `SafariPlayer` passou a declarar `.reliablePlaybackState`

- [ ] **Ancorar a posição em `elapsedTime + (agora − timestamp)`, e não no relógio local.**
  O par que o MediaRemote publica é "posição medida **no instante** timestamp", e o widget
  hoje ancora com `Date()` — o que joga fora a defasagem entre o evento e a leitura.
  Medido no Safari com âncora parada em `elapsed=40,5 @ 18:40:22Z`: a conta certa
  reconstrói a posição com **menos de 1 s de erro** em três leituras (116,5/116 ·
  122,6/122 · 128,7/129). Vale para TIDAL, Spotify e Deezer também, e destravaria
  `.streamPosition` para o Safari — hoje ele fica de fora só por causa disso. Mexe no
  coração do `NowPlayingController`, então merece sessão própria e nova rodada do roteiro
  — `2026-08-21 · #01`

- [x] **Testar ao vivo a 1.17.0** — roteiro completo e executável em
  `docs/roteiro-teste-manual.md` (`2026-08-21 · #01`), que absorve também o teste
  pendente da visibilidade por app da 1.16.0. Resumo do que ele cobre: trocar de app pelo menu
  para cada player; barra acompanhando a música no TIDAL e no Deezer; seek arrastando a
  barra no Spotify e no TIDAL; botão "anterior" desligado no Deezer e "próxima" desligado
  no Chrome, com o motivo no tooltip; YouTube Music abrindo o PWA ou o site — roteiro
  completo na Tarefa 9 de `docs/plano-players-adicionais.md` — `2026-08-20 · #01`

- [x] **Atalho de serviço web escolhido como preferido no modo fixo fica sem sessão.**
  O YouTube Music é `catalogID` sintético e `bundleIdentifier` do PWA; quem toca é o
  Chrome, então `isControlledPlayerActive` nunca casa e o card fica vazio com o transporte
  desligado. É consequência conhecida de o serviço não ter processo próprio
  (`DECISOES.md · 2026-08-19 · #01`), mas a UI não explica isso ao usuário — decidir entre
  avisar na tela ou impedir a escolha — `2026-08-20 · #01` · **resolvido em
  `2026-08-21 · #01` avisando**: impedir a escolha custaria a função legítima de o atalho
  ser o que o play abre. O card e as Preferências passam a dizer "O YouTube Music toca
  dentro do navegador — escolha o Google Chrome para controlá-lo", com teste

- [x] **`scripts/testar-player.sh` produz falso negativo em três situações**, todas
  encontradas em `2026-08-19 · #02` só porque o resultado foi conferido à mão:
  (a) testa shuffle/repeat com o vocabulário do Apple Music (`shuffle enabled`, `song
  repeat`) e reporta *não existe* com `syntax error (-2740)` no Spotify, que usa
  `shuffling`/`repeating`; (b) compara volume por igualdade exata, e o Spotify quantiza
  em `n-1`; (c) julga o efeito lendo o payload do Now Playing, que **mente no navegador**
  (reportou play/pause quebrado com o vídeo pausado de verdade). Corrigir os três e, para
  navegador, observar a página via `execute javascript` — `2026-08-19 · #02` ·
  **corrigido em `2026-08-21 · #01`**: o observador virou trocável (payload ou a própria
  página, escolhido pelo bundle id), shuffle/repeat tentam os dois vocabulários e o volume
  aceita ±1. O script também passou a distinguir "rebobina" de "não funciona" no
  `previous`, que era o caso do navegador

- [x] **A interação de app oculto com o modo fixo não tinha teste automatizado.** A
  correção em `95eb583` (oculto não derruba comando endereçado) tinha sido verificada só
  por leitura, porque `NowPlayingController.track` vem do stream real e não havia como
  montar "sessão X tocando, oculta, modo fixo" no `SelfTests` — `2026-08-19 · #02` ·
  **feito em `2026-08-21 · #01`**: `simulateSession(bundleIdentifier:isPlaying:)` em debug
  montou o estado, e os dois modos ganharam asserção

- [x] **Testar ao vivo a visibilidade por app** (1.16.0): desmarcar um app e conferir que
  ele some do submenu "Trocar app"; com ele tocando, ver o card mostrar "X está tocando ·
  oculto" e o botão "Mostrar este app" devolver; conferir que o preferido fica esmaecido e
  que "Esquecer apps descobertos" limpa a lista — `2026-08-19 · #02` · **feito em
  `2026-08-21 · #01`**, no bloco 03 do roteiro

- [x] **Fase 2 — o que exigia olho humano ou hardware.** Tradução pt-BR conferida na
  tela e **multi-monitor validado ao vivo** pelo usuário, os dois no roteiro de
  `2026-08-21 · #01`. Fecha a pendência inteira — `2026-08-10 · #01`

- [x] Testar manualmente o formato compacto (1×1) novo: troca ao vivo nas
  preferências, snap à grade nos dois formatos, seek/volume/transporte no layout
  compacto, duplo clique e arraste — `2026-08-11 · #03` · feito em `2026-08-21 · #01`

- [x] Testar manualmente a 1.14.0: ícone novo no Finder, glifo da bandeja,
  cabeçalho das Preferências e marca-d'água do widget (ajustar opacidade se
  necessário). Linha de status e botões de transporte não fecharem o menu ao
  clicar já foi validado ao vivo — `2026-08-12 · #01` · feito em `2026-08-21 · #01`

- [x] Confirmar visualmente o letreiro (`MarqueeText`) rodando com música de nome
  longo na 1.15.0 — validado só por instrumentação nesta sessão (offset avançando
  com o menu aberto); usuário ainda não viu o resultado após a correção do bug do
  `NSHostingView` (layout ignorava o frame, letreiro nunca via overflow) —
  `2026-08-13 · #01` · **feito em `2026-08-21 · #01`**, quando o letreiro também passou a
  valer no card, e não só na barra de menus

- [ ] **Fase 4 — assinar o Apple Developer Program (US$ 99/ano)**. É o único bloqueio
  real do resto da fase: o pipeline de assinatura, hardened runtime, notarização e
  staple já está pronto em `scripts/build-app.sh` (`MMW_SIGN_IDENTITY` e
  `MMW_NOTARY_PROFILE`), só falta o certificado para exercitá-lo. Sem Developer ID
  também não faz sentido montar o Sparkle — `2026-08-10 · #01`

- [x] **Três ícones na bandeja ao instalar por linha de comando.** Cada execução do
  binário criava uma instância nova, cada uma com seu `NSStatusItem`. Encontrado ao vivo
  em `2026-08-21 · #01`, durante a instalação da 1.17.0. Corrigido na mesma sessão com
  guarda de instância única em `App.swift`, verificada por execução dupla real (a segunda
  sai em 13 ms com `exit 0`)

- [x] **Apps duplicados em "Apps controlados" e janela de Preferências sem rolagem.**
  Achados no teste ao vivo em `2026-08-21 · #01` (bloco 03 do roteiro). Os cinco ids
  duplicados estavam gravados no `UserDefaults` desde a 1.16.0 — evidência direta em
  `settings.discoveredPlayerIDs`. Corrigidos na mesma sessão, com teste automatizado da
  purga

- [x] **Conteúdo do card invisível sobre capa escura e letreiro parado no widget.**
  Achados no teste ao vivo em `2026-08-21 · #01`. O contraste passou a sair da luminância
  da capa (`CardContrast`, com teste), e o `MarqueeText` da barra de menus foi
  reaproveitado no card com a largura descoberta em vez de informada

## Fora do plano de execução — para uma sessão futura

> Registrado em `2026-08-21 · #03`. Nada aqui foi recusado: são itens que ficaram de
> fora do plano das nove sessões por decisão pendente, por escolha de momento, ou por
> não terem sido promovidos a tarefa. Revisitar quando as Decisões 4 e 5 fecharem.

### Decisões em aberto (travam cinco tarefas)

- [ ] **Decisão 4 — Apple Developer Program (US$ 99/ano).** Sem a assinatura não existe
  certificado; sem certificado não há assinatura, notarização, DMG confiável nem canal
  de atualização. Decidir também **como titular**: pessoa física ou empresa — o nome
  legal aparece no Gatekeeper para o cliente, e trocar depois obriga a refazer os
  certificados. Trava as tarefas 17, 18 e, na prática, o lançamento — `2026-08-21 · #03`
- [ ] **Decisão 5 — merchant of record e casca jurídica.** Escolher Paddle ou Lemon
  Squeezy (assumem o imposto internacional), o que define como a chave de licença é
  gerada e o que o app precisa validar. Junto vêm o EULA — com cláusula explícita sobre
  a dependência de API não oficial do macOS — e a política de privacidade. Trava a
  tarefa 22 — `2026-08-21 · #03`
- [x] **Confirmar o bundle id de WidPlay** — `com.dudivalenza.widplay`, confirmado
  pelo usuário em `2026-08-21 · #03`. App Store e domínios verificados na mesma sessão
  (ver `DECISOES.md`): nenhum app com o nome, `widplay.com` registrado desde 2010 e sem
  site, `.app`/`.dev`/`.net`/`.co`/`.io` livres — `2026-08-21 · #03`
- [ ] **Busca de anterioridade de marca para "WidPlay" — não feita.** Justia e
  uspto.report bloqueiam acesso automatizado (Cloudflare) e as APIs do USPTO e do TMview
  recusaram a consulta; a ausência do nome na busca web **não** é busca de anterioridade.
  Fazer manualmente em `tmsearch.uspto.gov` e `euipo.europa.eu` (e no INPI, se a venda
  sair do Brasil) **antes** do certificado Developer ID — o nome fica gravado no
  notariado. Atenção ao antecedente: existiu uma WidPlay em Valência, Espanha, hoje
  fechada — verificar se deixou marca viva na UE — `2026-08-21 · #03`
- [ ] **Registrar `widplay.app` antes de anunciar o nome.** Está livre hoje, custa pouco
  e resolve dois problemas de uma vez: a página do produto e o endereço HTTPS estável que
  o appcast do Sparkle (tarefa 17) exige — o `.app` força HTTPS por desenho da TLD. O
  `.com` está tomado desde 2010, sem site, no Unstoppable Domains — só vale a pena
  perseguir se a marca virar negócio — `2026-08-21 · #03`

### Tarefas do plano que o usuário não liberou agora

- [ ] **Tarefa 1 — remover as duas entitlements dyld.** Cinco minutos, risco funcional
  nenhum, e é o único buraco de segurança do build de venda. Não depende de decisão
  nenhuma. (Mesmo conteúdo do item (a) da Onda 1, acima — não duplicar o trabalho:
  quando entrar, fechar os dois) — `2026-08-21 · #03`
- [ ] **Tarefa 3 — declarar no app o que já foi decidido:** `LSMinimumSystemVersion` e
  `Package.swift` em macOS 26, arm64 declarado, README e material de venda alinhados. As
  Decisões 2 e 3 já estão em `DECISOES.md`; falta escrevê-las no código. Trinta minutos
  — `2026-08-21 · #03`
- [ ] **Tarefa 17 — Sparkle 2.** Depende da Decisão 4 e de um endereço HTTPS estável
  para o appcast (GitHub Pages ou domínio do produto). Chaves EdDSA geradas pelo
  usuário, privada no Chaveiro + backup em gerenciador de senhas, **nunca no repo** —
  `2026-08-21 · #03`
- [ ] **Tarefa 18 — assinar, notarizar e grampear o DMG.** Depende da Decisão 4.
  Estender `scripts/package-dmg.sh` com o padrão de variáveis do `build-app.sh`, e
  publicar o checksum — `2026-08-21 · #03`
- [ ] **Tarefa 19 — pinar ou vendorizar o `mediaremote-adapter`.** Hoje o build copia do
  Homebrew da máquina, sem versão nem checksum: release irreproduzível da peça central.
  Criar `Resources/mediaremote-adapter/`, que o `CLAUDE.md` descreve mas não existe, e
  gravar a versão dentro do bundle — `2026-08-21 · #03`
- [ ] **Tarefa 20 — diagnóstico e botão "Reportar problema".** Log nas falhas hoje
  silenciosas (comando one-shot, `osascript` com exit ≠ 0, linha descartada) e um botão
  que abra e-mail com versão do app, versão do macOS e estado do adapter. Sem
  telemetria. Falta o usuário definir o e-mail de suporte — `2026-08-21 · #03`
- [ ] **Tarefa 22 — EULA, política de privacidade, checkout e chave de licença.**
  Depende da Decisão 5. O rascunho dos textos é meu; a revisão jurídica de verdade não —
  para venda internacional, vale modelo de fornecedor especializado — `2026-08-21 · #03`

### Achado grave sem segunda opinião

- [ ] **Letreiros a 30 Hz (tarefa 8) nunca foi refutado.** Dos 11 achados altos, 10
  passaram por um verificador adversarial; este não — o agente caiu no limite de sessão
  e não foi reexecutado. A evidência de código existe
  (`MenuStatusView.swift:80`, `AppMenuController.swift:112`), mas ele entrou no plano com
  severidade não confirmada. **Antes ou durante a S6**: refutar como os outros, ou medir
  o consumo real do timer — se o impacto for menor que o descrito, rebaixar em vez de
  tratar como grave — `2026-08-21 · #03`

### Os 30 achados baixos que não viraram tarefa

- [ ] **Não promovidos ao plano; ficam registrados para uma varredura futura de
  acabamento.** Todos com arquivo e linha em `docs/auditoria-achados-2026-08-21.md`. Os
  de maior chance de incomodar um cliente: menu da bandeja que se auto-fecha após 2 s
  sem hover, fora do padrão do macOS (#60); atalho global fixo em ⌃⌥⌘M, sem
  configuração e sem aviso quando o registro falha (#61); duplo clique para abrir o
  player sem nenhuma pista na UI (#62); rótulo "Opacidade do tint", jargão de
  implementação (#63); falha silenciosa ao alternar "Abrir no login", com o toggle
  podendo mostrar estado errado (#64); tipografia em tamanhos fixos, ignorando o ajuste
  de tamanho de texto do sistema (#65). Os demais são técnicos e sem efeito visível
  — `2026-08-21 · #03`

### Medição que a auditoria não fez

- [ ] **As afirmações de energia são derivadas do código, não medidas.** Frequência de
  timer e criação de processos foram lidas; consumo real, não. Medir com `powermetrics`
  **antes** da S3 e **depois** da S6, e registrar o antes/depois — é o teste honesto, e
  está coerente com a regra do projeto de não afirmar o que não foi observado
  — `2026-08-21 · #03`

## Média

- [ ] **Onda 4 — correção e UX da auditoria.** Snapshot com conteúdo deve partir de
  `TrackInfo()` e não do estado atual (capa e álbum da faixa anterior grudam); os três
  buracos de roteamento (fonte oculta pausada contra o invariante do `SelfTests`, atalho
  web que pausa e espera sessão impossível, play que vira no-op com auto-launch
  desligado); acessibilidade do card (rótulos, barra de seek ajustável, `reduce motion`
  — o padrão certo já existe no `MenuTransportView`); `NSAppleEventsUsageDescription` em
  `InfoPlist.strings` por idioma (hoje todo usuário não-lusófono vê o prompt de permissão
  em português); caminho de recuperação quando a Automação é negada; e o onboarding
  mínimo já previsto na Fase 1 do `ROADMAP` — hoje o padrão é Amazon Music, então quem
  não o tem recebe, de saída, um alerta oferecendo instalar um app que nunca pediu
  — `2026-08-21 · #02`

- [ ] **Onda 5 — sustentação.** Sparkle 2 com appcast e chaves EdDSA fora do repo;
  assinar/notarizar/grampear o **DMG** e não só o `.app`; pinar ou vendorizar o adapter
  com a versão gravada no bundle (hoje vem do `brew --prefix` do dia, e o `CLAUDE.md`
  descreve um `Resources/mediaremote-adapter/` que não existe); log de diagnóstico e
  botão "Reportar problema"; EULA, política de privacidade, checkout e chave de licença
  — `2026-08-21 · #02`

- [ ] **Testar a ancoragem de posição antes do refactor já agendado.** O bloco de
  reancoragem do `NowPlayingController` é o caminho com mais bugs documentados do
  projeto e tem **zero cobertura** — e a pendência de ancorar por
  `elapsedTime + (agora − timestamp)` vai mexer exatamente ali. Extrair a decisão para
  função pura com relógio injetado e cobrir os quatro ramos históricos **antes** de
  mexer — `2026-08-21 · #02`

- [ ] **Corrigir o warning conhecido e fechar a porta.** `Coordinator.changed` lê
  `doubleValue` (main actor) de contexto `nonisolated` em `ContentView.swift:471` —
  anotar a classe com `@MainActor` e, feito isso, fazer o `verificar.sh` falhar em
  qualquer warning. Warning tolerado é como o segundo aparece sem ninguém notar; em modo
  estrito de Swift 6 essa referência tende a virar erro — `2026-08-21 · #02`

- [ ] Migrar `SelfTests.swift` para swift-testing **se** o Xcode entrar no projeto — as
  funções já são independentes, é mecânico. Enquanto não houver, `swift test` é
  impossível (CLT não trazem os frameworks; ver `DECISOES.md`) — `2026-08-10 · #01`
- [x] Avaliar se `verificar-traducoes.sh` e `--run-tests` devem entrar no
  `fechar-sessao.sh` — hoje o encerramento só roda `swift build`, então uma chave de
  tradução quebrada ou uma asserção falhando passariam batido — `2026-08-10 · #01` ·
  **avaliado em `2026-08-21 · #01`**: nasceu `scripts/verificar.sh`, que roda as três de
  uma vez, e o `CLAUDE.md` manda rodá-lo antes de fechar. Falta decidir com o usuário se
  o `fechar-sessao.sh` **global** passa a preferir um `scripts/verificar.sh` do projeto
  quando ele existir — **decidido em `2026-08-21 · #01`: não.** O usuário preferiu manter
  a ferramenta global intocada; a verificação completa fica como passo explícito do
  `CLAUDE.md` daqui
- [x] Registrar no `README.md`/`ROADMAP` que o widget passou a ter visibilidade por app,
  quando a Fase 1 fechar (a Tarefa 9 do plano cobre isso) — `2026-08-19 · #02` · feito em
  `2026-08-20 · #01`: o README ganhou a tabela de apps suportados e a nota de "Apps
  controlados" (não há `ROADMAP.md` no repositório)

## Baixa

(vazio)
