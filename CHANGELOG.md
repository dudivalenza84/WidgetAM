# Changelog — MacMediaWidget

Formato semver: MINOR por release cronológica, PATCH para hotfix.
Entradas novas vão no topo.

## [1.16.0] — 2026-08-19 · #02 — Visibilidade por app e o gate de evidência dos players

**Novo: você escolhe quais apps o widget controla.** Nas Preferências, a seção
**Apps controlados** lista o catálogo e também todo app que já apareceu tocando, cada um
com um checkbox. Desmarcar tira o app do menu "Trocar app" e faz o widget ignorar o que
ele toca. O player preferido nunca pode ser ocultado, nem o último visível — não dá para
esvaziar o menu e ficar sem caminho de volta.

Com um app oculto tocando, o card não fica em branco: ele diz "X está tocando · oculto" e
oferece **Mostrar este app**. Card vazio com música no ar é indistinguível de app quebrado.

**Por dentro:** o `PlayerCatalog` passa a separar "o que o usuário pode escolher" de "quem
controla esta sessão", que era o mesmo conjunto até o YouTube Music entrar no desenho.

**Compatibilidade apurada.** Spotify, TIDAL, Deezer e navegador foram medidos contra os
apps reais e estão em `docs/compatibilidade-players.md`. Ainda **não** há suporte a esses
players no widget — a matriz é o insumo das próximas tarefas. Destaques: o Spotify aceita
tudo, inclusive comando endereçado; o Deezer não tem seek nem faixa anterior; o navegador
publica posição e estado de reprodução incorretos, e o widget vai precisar tratá-lo à parte.

> A sessão anterior reservou a 1.16.0 para a implementação dos players adicionais. Ela
> saiu antes, com a visibilidade por app, que é feature completa por si. Spotify, TIDAL,
> Deezer e navegador vão para a MINOR seguinte.

## [Não lançado] — 2026-08-19 · #01 — Planejamento dos players adicionais

Sessão de planejamento: **nenhuma mudança no app** — o binário segue na 1.15.0. A
versão 1.16.0 fica reservada para a implementação.

- Levantados Spotify, TIDAL, Deezer e YouTube Music por inspeção estática, sem enviar
  comando a nenhum player. Só o Spotify tem dicionário AppleScript (teto igual ao do
  Apple Music); TIDAL e Deezer são Electron e ficam no transporte.
- Apurado que serviço web não pode ter identidade de sessão própria: o PWA do Chrome é
  só um lançador, e o MediaRemote identifica a sessão pelo processo.
- Desenho em `docs/players-adicionais.md` e plano em `docs/plano-players-adicionais.md`.

## [1.15.0] — 2026-08-13 · #01 — Menu com largura fixa e auto-fechamento

- Menu (bandeja e contexto do widget): largura padronizada em 220 pt, independente
  do tamanho do nome da música — antes o texto da faixa esticava o menu.
- Nome de música que não cabe rola em letreiro contínuo, com fade nas bordas e
  pausa a cada volta.
- Menu da bandeja se fecha sozinho após 2 s sem interação, desde que o mouse não
  esteja sobre ele (menu de contexto do widget mantém o comportamento padrão).

## [1.14.0] — 2026-08-12 · #01 — Transporte no menu e identidade visual

- Menu (contexto do widget e bandeja): linha de status com estado e faixa atual
  ("Tocando/Pausado — música") e botões ⏮ ⏯ ⏭ lado a lado que não fecham o menu ao
  clicar — dá para pausar e pular faixas em sequência.
- Identidade visual "Órbita": ícone do app (.icns em todas as resoluções), glifo
  template na bandeja (substitui o SF Symbol genérico), favicon (PNG + ICO) e
  SVGs-fonte versionados, com pipeline reproduzível (`scripts/gerar-icones.sh`).
- Marca aplicada: cabeçalho com ícone/nome/versão nas Preferências e marca-d'água
  discreta no canto do widget.

## [1.13.0] — 2026-08-11 · #03 — Tamanho do widget configurável (1×1 e 2×1)

- Preferência nova em Aparência: tamanho do widget — Compacto (1×1, uma célula da
  grade nativa, como o relógio) ou Largo (2×1, o formato original). Aplica ao vivo,
  redimensionando a janela sem sair do lugar e realinhando à grade.
- Layout compacto próprio para o quadrado de 170 pt: capa em miniatura ao lado do
  título/artista, barra de progresso e transporte com os mesmos alvos de clique, e
  volume em slider horizontal no rodapé (a sidebar vertical não cabe).

## [1.12.0] — 2026-08-11 · #01 — Interações do widget e atalho global

- Duplo clique no card abre o player que o widget está exibindo.
- Clique direito no card abre o mesmo menu da bandeja (construção unificada no novo
  `AppMenuController`).
- Submenu "Trocar app" nos dois menus: troca o player preferido e abre o app escolhido.
- Preferência nova em Posicionamento: manter o widget sobre as demais janelas.
- Atalho global ⌃⌥⌘M traz o widget à frente para operá-lo; segundo aperto devolve ao
  nível de mesa. Sem permissão de Acessibilidade (Carbon `RegisterEventHotKey`).
- Versão do app visível no topo dos menus e no rodapé das Preferências.

## [1.11.0] — 2026-08-10 · #01 — Robustez de produto, inglês e auditoria de segurança

- **Saúde do adapter.** O widget deixa de congelar quando o canal de leitura cai:
  checagem de entitlement na abertura, reconexão com backoff exponencial e aviso na UI.
  Antes, um subprocesso morto deixava o card parado na última faixa para sempre, o que
  o usuário não tinha como distinguir de "nada tocando".
- **Interface em inglês**, com pt-BR como tradução e `scripts/verificar-traducoes.sh`
  para impedir que uma chave errada caia no inglês em silêncio.
- **53 verificações automatizadas** (`swift run MacMediaWidget --run-tests`), cobrindo
  parsing do stream, grade de snap, capacidades de player e posição entre telas.
- **Multi-tela:** âncora da grade filtrada por tela e posição salva validada contra as
  telas conectadas — antes, desconectar um monitor deixava o widget invisível e sem como
  resgatar, já que o app não tem ícone no Dock.
- **Auditoria de segurança** (`docs/auditoria-seguranca.md`) com três correções. A mais
  séria: o fallback do adapter para `/opt/homebrew` — diretório gravável sem privilégio —
  ia junto para o binário de release, o que permitiria executar código dentro do processo
  do app com as permissões de Automação dele.
- **Pipeline de release** pronto para Developer ID: hardened runtime, entitlements,
  notarização e staple, tudo opcional por variável de ambiente.

## [1.10.0] — 2026-08-10 · #01 — Multi-player

- O widget deixa de ser mono-app. Duas camadas: MediaRemote como base universal (lê e
  controla qualquer fonte de Now Playing) e AppleScript como camada por app, onde
  existir — no Apple Music isso dá posição real, seek, volume do próprio app,
  shuffle/repeat e controle mesmo com outro app tocando.
- **Player preferido** e **modo de controle** (automático ou fixo) nas preferências. No
  modo fixo com um player sem AppleScript, o play abre o app e os demais controles ficam
  inativos com o motivo à vista — mandar o comando assim cairia no app errado.
- UI adaptada ao que a fonte permite: ícone da fonte ativa, barra arrastável só onde o
  seek foi comprovado, alvo do volume explícito.
- **Matriz de compatibilidade** (`docs/compatibilidade-players.md`) levantada com
  `scripts/testar-player.sh`, só com o que foi observado.
- Atribuição BSD-3-Clause do `mediaremote-adapter` agora acompanha o bundle, como a
  licença exige.

## [1.9.0] — 2026-08-09 · #01 — Grade nativa de widgets + roadmap de produto

- Snap reescrito: grade celular 2D idêntica à dos widgets nativos da mesa
  (célula 180×180 pt), com âncora medida ao vivo via CGWindowList quando há
  widget nativo visível e fallback replicado quando não há.
- Card nas dimensões do widget *medium* nativo (350×170), capa e slider maiores;
  janela no mesmo nível dos widgets nativos; realinha à grade ao exibir.
- Preferências simplificadas: removidos borda de alinhamento, margem e passo
  vertical; ficou o toggle "Alinhar à grade de widgets do macOS".
- `ROADMAP.md` novo: plano de 5 fases até a venda direta (multi-player, QA,
  identidade, infra de venda, lançamento) + decisões de produto em DECISOES.md.

## [1.8.0] — 2026-08-05 · #02

- **Seek descartado como recurso: o `Amazon Music.app` ignora o comando de posicionamento do
  MediaRemote.** Comprovado por teste observável — seek para 5s antes do fim da faixa, com o app
  tocando, não fez a faixa terminar nem avançar (`Welcome to Paradise` 224s→219s e `Sultans Of
  Swing` 348s→340s). Contraprova no QuickTime Player (arquivo de 127s, `seek 100s` → posição real
  reportada de 101,35s) mostra que o comando e o adapter funcionam: quem não implementa o handler
  é o Amazon Music. O `seek(toSeconds:)` foi removido — nunca teve chamador e nunca teria
  funcionado —, e README/CLAUDE.md deixaram de anunciar `seek` entre os comandos suportados. A
  barra de progresso é indicador, não controle. Ver `DECISOES.md`.
- **Fix: o fallback de desenvolvimento quebraria no primeiro `brew upgrade`.** Fora do bundle
  (`swift run`), o adapter era procurado em `Cellar/media-control/0.7.6/…` — caminho com a versão
  no nome, que deixa de existir a cada atualização da fórmula. Como o `.app` instalado usa os
  recursos bundlados e seguiria funcionando, a falha apareceria só em desenvolvimento. Agora usa
  os symlinks `opt/` do brew, reapontados a cada upgrade, com o prefixo Intel além do Apple
  Silicon — mesma resolução do `brew --prefix` já usado pelo `scripts/build-app.sh`.

## [1.7.0] — 2026-08-05 · #01

- **Arrasto só pelo fundo do card.** Clicar num botão de transporte e mexer o mouse movia a janela
  em vez de acionar o botão, porque `isMovableByWindowBackground` fazia o card inteiro virar alça.
  Botões de transporte e sidebar de volume agora se excluem do arrasto via `NonDraggableArea`
  (`WindowDragging.swift`); capa, textos e espaços vazios continuam arrastando. Os alvos de clique
  dos botões passaram do glifo (15–18pt) para 28×28, com o espaçamento ajustado para manter o
  visual idêntico.
- **Fix: play com Amazon Music encerrado abria o Music.app da Apple.** O stream marca o fim da
  sessão com um snapshot `diff: false` vazio, mas o parser ignorava o campo `diff` e tratava tudo
  como incremental — o `bundleIdentifier` antigo ficava grudado e o play virava um
  `togglePlayPause` global. Snapshot sem faixa agora zera o estado, e o toggle global só é enviado
  com o app comprovadamente rodando. (A correção de `1.4.1` tratou o sintoma, não a causa.)
- **Fix: barra de progresso travada em 100%.** O `timestamp` do Now Playing não é reemitido ao
  pausar; numa faixa parada há horas, `now − timestamp` estourava a duração e a âncora era gravada
  já clampada, travando a barra cheia até a troca de faixa.
- **Seek dentro do Amazon Music: limitação confirmada e fechada.** Captura do stream prova que o
  app publica apenas `{"playing": bool}` no seek — sem posição e sem `timestamp` novo. Não há
  segunda fonte (o `get` traz os mesmos campos; o app não tem AppleScript). Registrado em
  `DECISOES.md` para não se reinvestigar.
- **Verificação de app não instalado, testada.** Novo flag de simulação (`simulateMissingApp` no
  UserDefaults ou `MMW_SIMULATE_MISSING_APP` no ambiente) permite exercitar o fluxo sem mexer no
  `Amazon Music.app`. O alerta ganhou `NSApp.activate()`: num app sem Dock, ele poderia nascer
  atrás das outras janelas sem como ser resgatado.
- **Versão do bundle sincronizada.** `CFBundleShortVersionString` estava parado em `0.1.0` desde o
  início do projeto; agora acompanha o changelog.

## [1.6.0] — 2026-06-26 · #01

- **Fix: barra de progresso não preenchia.** O `Amazon Music.app` não popula `elapsedTime` no Now
  Playing info — o stream do `mediaremote-adapter` só traz `timestamp`, `duration` e `playing`. O
  cálculo passou a usar um cronômetro local ancorado no `timestamp`: semeia a posição ao entrar na
  faixa, avança só enquanto toca e congela na pausa. Limitação: seek feito dentro do app só sincroniza
  na troca de faixa.
- **Preferências de snap.** Novo toggle "Alinhar à grade" (liga/desliga o snap; desligado, o widget
  fica livre onde for solto) e picker de borda de ancoragem (Esquerda/Direita) na tela de
  Preferências. Ambos aplicam ao vivo.

## [1.5.0] — 2026-06-24 · #01

- **Verificação de Amazon Music não instalado.** Ao apertar play (ou abrir o app pelo tray) sem o
  `Amazon Music.app` instalado, o widget agora mostra um `NSAlert` ("Amazon Music não está
  instalado") e oferece abrir a página oficial de instalação (link `am.app.link`), em vez
  de falhar em silêncio. `openAmazonMusic()` passou a retornar `Bool`, e o `play()` aborta a espera
  por Now Playing quando o app não existe. _(pendente de teste manual)_

## [1.4.1] — 2026-06-23 · #05

- **Fix: play com Amazon Music fechado abria o Music.app da Apple.** Em instalação limpa pelo
  DMG, `autoLaunchOnPlay` valia o default `false`, e o botão caía num `togglePlayPause` global que
  o macOS roteava para o player padrão. Default agora é `true` e `playPauseEnsuringApp()` só envia o
  toggle global quando a sessão de Now Playing já é o Amazon Music — caso contrário garante o app e
  só dá play quando ele vira a sessão. Fecha também o furo do app aberto porém sem sessão ativa.

## [1.4.0] — 2026-06-23 · #04

- **Liquid Glass nativo** (macOS 26): novo `CardSurface` aplica `glassEffect(.regular.tint(...))` ao
  card, com fallback para `.ultraThinMaterial` em versões anteriores. O efeito vai numa camada de
  `.background` — aplicá-lo direto na stack fazia o card inteiro virar superfície de vidro e capturar
  o arraste, roubando o clique do `NSSlider` de volume.
- **Tela de configurações dedicada**: `AppSettings` (sobre `UserDefaults`) + `PreferencesView`
  (Form agrupado), aberta pelo item "Preferências…" da bandeja. Ajusta ao vivo: margem da borda,
  passo da grade vertical, opacidade do tint, abrir Amazon Music ao dar play e abrir no login.
- **`edgeMargin` ajustável**: deixou de ser constante; `WidgetWindow` lê das preferências e re-snapa
  em tempo real (Combine). A calibração do alinhamento com a coluna dos widgets nativos virou visual.
- **Auto-abrir Amazon Music ao dar play**: com o app fechado, o play abre o `com.amazon.music`. O
  comando só é enviado quando o app já é o Now Playing (`waitForAmazonMusicThenPlay`) — evita vazar o
  `play` para o Music.app da Apple.
- **Empacotamento**: `scripts/package-dmg.sh` gera `dist/MacMediaWidget.dmg`. README reescrito para a
  stack Swift, com build, empacotamento e instalação (contorno de Gatekeeper para uso pessoal).

## [1.3.0] — 2026-06-23 · #03

- **Controle de volume do sistema** implementado (`SystemVolumeController`): leitura e ajuste do
  volume de saída via AppleScript (`set volume`), aplicação coalescida no arrasto e mute usando o
  flag do macOS (preserva o nível ao desmutar). É volume global, não por-app.
- **UI**: sidebar de volume fixa na lateral direita do card — slider vertical + ícone de mute.
  O slider é um `NSSlider` nativo (`NSViewRepresentable`), não um `Slider` SwiftUI rotacionado: a
  rotação deslocava a área de hit-test e o arrasto movia o widget (`isMovableByWindowBackground`)
  em vez de mudar o volume.
- **Persistência** descartada como item autônomo: a parte útil (posição da janela) já estava feita;
  preferências futuras ficam acopladas à "Tela de configurações dedicada".

## [1.2.0] — 2026-06-23 · #02

- **Base Electron removida** e projeto reescrito em **Swift nativo** (SPM, alvo executável +
  bundle `.app` montado por `scripts/build-app.sh` com codesign ad-hoc). `CLAUDE.md` e `.gitignore`
  migrados para a nova stack.
- **Integração com o Now Playing** via `mediaremote-adapter` bundlado: stream JSON do
  `com.amazon.music` (título, artista, capa, duração, posição, estado) e comandos de transporte
  (`play`/`pause`/`next`/`prev`/`seek`). Validado end-to-end no app oficial.
- **Widget de mesa**: `NSPanel` borderless em nível de mesa, todos os Spaces, não-ativante; UI no
  padrão dos widgets nativos (card tonalizado pela capa, progresso animado, botões centralizados);
  snap por ancoragem à borda + posição persistida em `UserDefaults`; bandeja com mostrar/ocultar,
  abrir Amazon Music e **autostart no login** (`SMAppService`).
- **Decisão — controle de volume:** adotada a opção 1 (volume do **sistema** via AppleScript). Volume
  por-app é inviável sem driver de áudio virtual; o MediaRemote não expõe comando de volume.
  Implementação fica como pendência.

## [1.1.0] — 2026-06-23 · #01

- PoC de arquitetura. Provado que **embutir o web player do Amazon Music no Electron é
  inviável**: a Amazon bloqueia navegador desconhecido (não é DRM — o Widevine via build
  Castlabs `v42.3.3+wvcus` foi instalado e funcionou).
- Descoberto que o **app oficial `Amazon Music.app`** (`com.amazon.music`) publica no
  **Now Playing do macOS**. Validados, no macOS 26.5.1: leitura completa (título, artista,
  álbum, capa JPEG, duração, posição, estado) e comandos (pause/play) via
  **`mediaremote-adapter`** (perl entitled), contornando o bloqueio da Apple (15.4+).
- **Decisão:** reescrever o widget em **Swift nativo** controlando o app oficial via Now
  Playing. Base Electron será descartada (limpeza na própria pasta). Pendências de
  implementação registradas em `PENDENCIAS.md`.

## [1.0.1] — 2026-06-22 · #02

- Recuperado o ambiente Electron quebrado pelo pnpm: removidos artefatos do pnpm, reinstalação
  via npm e extração manual do binário do Electron 31 (postinstall não completava sob Node v26).
  `npm start` volta a abrir o widget.
- `.gitignore` passa a ignorar `pnpm-*.yaml`.
- Aberta a reconstrução de features (integração PWA, widget de mesa, Liquid Glass nativo,
  empacotamento `.dmg`); etapas registradas em `PENDENCIAS.md`.

## [1.0.0] — 2026-06-22 · #01

- Projeto migrado para git e publicado no GitHub (`dudivalenza84/WidgetAM`).
- Protocolo de governança de sessões configurado (`CLAUDE.md`, `SESSIONS.md`, `PENDENCIAS.md`, `docs/sessions/`).
