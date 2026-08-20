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

- [ ] **Implantar os players adicionais** seguindo `docs/plano-players-adicionais.md`.
  **Tarefas 0, 1, 5, 6, 7 e 8 feitas em `2026-08-19 · #02`.** Faltam a **2**
  (`SpotifyPlayer`), a **3** (TIDAL, Deezer, navegador e o atalho do YouTube Music), a
  **4** (âncora por `elapsedTime`) e a **9** (bundle, teste manual e documentação).
  Fecha o critério de saída da Fase 1 do ROADMAP, que exigia o Spotify — `2026-08-19 · #01`

- [ ] **As capacidades das Tarefas 2 e 3 vêm da matriz, não do plano.** O
  `docs/plano-players-adicionais.md` escreveu as `PlayerCapabilities` a partir do `.sdef`,
  antes da evidência existir; `docs/compatibilidade-players.md` agora contradiz o plano em
  pontos concretos — Deezer sem seek e sem `previous`, navegador sem `next` e com
  `previous` que rebobina. Na dúvida entre os dois documentos, **manda a matriz**
  — `2026-08-19 · #02`

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

## Média

- [ ] Migrar `SelfTests.swift` para swift-testing **se** o Xcode entrar no projeto — as
  funções já são independentes, é mecânico. Enquanto não houver, `swift test` é
  impossível (CLT não trazem os frameworks; ver `DECISOES.md`) — `2026-08-10 · #01`
- [ ] Avaliar se `verificar-traducoes.sh` e `--run-tests` devem entrar no
  `fechar-sessao.sh` — hoje o encerramento só roda `swift build`, então uma chave de
  tradução quebrada ou uma asserção falhando passariam batido — `2026-08-10 · #01`
- [ ] Registrar no `README.md`/`ROADMAP` que o widget passou a ter visibilidade por app,
  quando a Fase 1 fechar (a Tarefa 9 do plano cobre isso) — `2026-08-19 · #02`

## Baixa

(vazio)
