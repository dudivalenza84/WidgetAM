# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

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

- [ ] **Medir o Safari** e decidir se ele entra no catálogo. Hoje fica de fora de
  propósito (`DECISOES.md · 2026-08-20 · #01`) e cai no `MediaRemotePlayer` genérico.
  Roteiro na última tabela de `docs/compatibilidade-players.md` — `2026-08-20 · #01`

- [ ] **Testar ao vivo a 1.17.0** — roteiro completo e executável em
  `docs/roteiro-teste-manual.md` (`2026-08-21 · #01`), que absorve também o teste
  pendente da visibilidade por app da 1.16.0. Resumo do que ele cobre: trocar de app pelo menu
  para cada player; barra acompanhando a música no TIDAL e no Deezer; seek arrastando a
  barra no Spotify e no TIDAL; botão "anterior" desligado no Deezer e "próxima" desligado
  no Chrome, com o motivo no tooltip; YouTube Music abrindo o PWA ou o site — roteiro
  completo na Tarefa 9 de `docs/plano-players-adicionais.md` — `2026-08-20 · #01`

- [ ] **Atalho de serviço web escolhido como preferido no modo fixo fica sem sessão.**
  O YouTube Music é `catalogID` sintético e `bundleIdentifier` do PWA; quem toca é o
  Chrome, então `isControlledPlayerActive` nunca casa e o card fica vazio com o transporte
  desligado. É consequência conhecida de o serviço não ter processo próprio
  (`DECISOES.md · 2026-08-19 · #01`), mas a UI não explica isso ao usuário — decidir entre
  avisar na tela ou impedir a escolha — `2026-08-20 · #01`

- [ ] **`scripts/testar-player.sh` produz falso negativo em três situações**, todas
  encontradas em `2026-08-19 · #02` só porque o resultado foi conferido à mão:
  (a) testa shuffle/repeat com o vocabulário do Apple Music (`shuffle enabled`, `song
  repeat`) e reporta *não existe* com `syntax error (-2740)` no Spotify, que usa
  `shuffling`/`repeating`; (b) compara volume por igualdade exata, e o Spotify quantiza
  em `n-1`; (c) julga o efeito lendo o payload do Now Playing, que **mente no navegador**
  (reportou play/pause quebrado com o vídeo pausado de verdade). Corrigir os três e, para
  navegador, observar a página via `execute javascript` — `2026-08-19 · #02`

- [ ] **A interação de app oculto com o modo fixo não tem teste automatizado.** A
  correção em `95eb583` (oculto não derruba comando endereçado) foi verificada por
  leitura: `NowPlayingController.track` é `private(set)` e vem do stream real, então não
  há como montar "sessão X tocando, oculta, modo fixo" no `SelfTests` sem expor um setter
  só para teste. Decidir se vale a infraestrutura — `2026-08-19 · #02`

- [ ] **Testar ao vivo a visibilidade por app** (1.16.0): desmarcar um app e conferir que
  ele some do submenu "Trocar app"; com ele tocando, ver o card mostrar "X está tocando ·
  oculto" e o botão "Mostrar este app" devolver; conferir que o preferido fica esmaecido e
  que "Esquecer apps descobertos" limpa a lista — `2026-08-19 · #02`

- [ ] **PWA do YouTube Music não abre:** o `app_mode_loader` executa e sai sem deixar
  processo (provável descasamento do shim com o Chrome 151). Conserto é reinstalar pelo
  Chrome. **Não bloqueia o plano** — a entrada do catálogo usa `appElseURL` e cai na
  página quando o PWA falha — `2026-08-19 · #01`

- [ ] **Fase 2 — o que ainda exige olho humano ou hardware:** conferir a tradução
  pt-BR **na tela** (o texto do `pt-BR.lproj` foi revisado em arquivo em
  `2026-08-11 · #03`, sem erro encontrado — falta só o contexto visual) e testar
  multi-monitor de verdade (correções feitas por leitura de código e testes
  sintéticos; não há segundo monitor aqui) — `2026-08-10 · #01`

- [ ] Testar manualmente o formato compacto (1×1) novo: troca ao vivo nas
  preferências, snap à grade nos dois formatos, seek/volume/transporte no layout
  compacto, duplo clique e arraste — `2026-08-11 · #03`

- [ ] Testar manualmente a 1.14.0: ícone novo no Finder, glifo da bandeja,
  cabeçalho das Preferências e marca-d'água do widget (ajustar opacidade se
  necessário). Linha de status e botões de transporte não fecharem o menu ao
  clicar já foi validado ao vivo — `2026-08-12 · #01`

- [ ] Confirmar visualmente o letreiro (`MarqueeText`) rodando com música de nome
  longo na 1.15.0 — validado só por instrumentação nesta sessão (offset avançando
  com o menu aberto); usuário ainda não viu o resultado após a correção do bug do
  `NSHostingView` (layout ignorava o frame, letreiro nunca via overflow) —
  `2026-08-13 · #01`

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

## Média

- [ ] Migrar `SelfTests.swift` para swift-testing **se** o Xcode entrar no projeto — as
  funções já são independentes, é mecânico. Enquanto não houver, `swift test` é
  impossível (CLT não trazem os frameworks; ver `DECISOES.md`) — `2026-08-10 · #01`
- [ ] Avaliar se `verificar-traducoes.sh` e `--run-tests` devem entrar no
  `fechar-sessao.sh` — hoje o encerramento só roda `swift build`, então uma chave de
  tradução quebrada ou uma asserção falhando passariam batido — `2026-08-10 · #01`
- [x] Registrar no `README.md`/`ROADMAP` que o widget passou a ter visibilidade por app,
  quando a Fase 1 fechar (a Tarefa 9 do plano cobre isso) — `2026-08-19 · #02` · feito em
  `2026-08-20 · #01`: o README ganhou a tabela de apps suportados e a nota de "Apps
  controlados" (não há `ROADMAP.md` no repositório)

## Baixa

(vazio)
