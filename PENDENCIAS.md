# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

- [ ] **Tarefa 0 do plano — bateria de testes nos players (gate do desenvolvimento):**
  rodar `scripts/testar-player.sh` em `com.spotify.client Spotify`, `com.tidal.desktop`,
  `com.deezer.deezer-desktop` e `com.google.Chrome`, cada um com fila de **3+ faixas**
  tocando (com uma faixa só, `next` dá falso negativo). Inclui o teste observável do
  seek do Spotify (posicionar a 5 s do fim) e a leitura do bundle id que a sessão do PWA
  do YouTube Music publica. Nenhuma capacidade entra no código antes disso. Roteiro
  completo em `docs/plano-players-adicionais.md` — `2026-08-19 · #01`

- [ ] **Implantar os players adicionais** seguindo `docs/plano-players-adicionais.md`
  (Tarefas 1 a 9): catálogo, `SpotifyPlayer`, TIDAL/Deezer/navegador, âncora por
  `elapsedTime`, visibilidade por app e a seção "Apps controlados" nas Preferências.
  Fecha o critério de saída da Fase 1 do ROADMAP, que exigia o Spotify — os quatro apps
  já estão instalados — `2026-08-19 · #01`

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

## Baixa

(vazio)
