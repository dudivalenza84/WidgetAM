# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

- [ ] **Fase 1 — fechar o critério de saída do ROADMAP:** instalar Spotify (e decidir
  sobre o Deezer) e rodar `scripts/testar-player.sh com.spotify.client Spotify` para
  preencher a coluna na matriz. A arquitetura já comporta: basta um `SpotifyPlayer`
  espelhando o `AppleMusicPlayer`, com capacidades declaradas **só depois** do teste —
  `2026-08-10 · #01`

- [ ] **Fase 2 — o que ainda exige olho humano ou hardware:** conferir a tradução
  pt-BR **na tela** (o texto do `pt-BR.lproj` foi revisado em arquivo em
  `2026-08-11 · #03`, sem erro encontrado — falta só o contexto visual) e testar
  multi-monitor de verdade (correções feitas por leitura de código e testes
  sintéticos; não há segundo monitor aqui) — `2026-08-10 · #01`

- [ ] Testar manualmente o formato compacto (1×1) novo: troca ao vivo nas
  preferências, snap à grade nos dois formatos, seek/volume/transporte no layout
  compacto, duplo clique e arraste — `2026-08-11 · #03`

- [ ] Testar manualmente a 1.14.0: linha de status e botões de transporte no menu
  (não deve fechar ao clicar), ícone novo no Finder, glifo da bandeja, cabeçalho das
  Preferências e marca-d'água do widget (ajustar opacidade se necessário) —
  `2026-08-12 · #01`

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
