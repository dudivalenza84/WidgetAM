# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

- [ ] **Fase 1 — fechar o critério de saída do ROADMAP:** instalar Spotify (e decidir
  sobre o Deezer) e rodar `scripts/testar-player.sh com.spotify.client Spotify` para
  preencher a coluna na matriz. A arquitetura já comporta: basta um `SpotifyPlayer`
  espelhando o `AppleMusicPlayer`, com capacidades declaradas **só depois** do teste —
  `2026-08-10 · #01`
- [ ] **Testes manuais que dependem de interação humana**, listados no fim de
  `docs/compatibilidade-players.md`: (a) fonte de navegador — exige dar play num vídeo
  à mão, porque autoplay com som é bloqueado; (b) gesto de arraste na barra do widget
  com o Apple Music tocando; (c) negar a permissão de Automação em Ajustes do Sistema e
  conferir se as capacidades caem como previsto — `2026-08-10 · #01`

- [x] **Fase 1 do ROADMAP — multi-player.** Implementada em `2026-08-10 · #01`:
  abstração `Player` + `PlayerCapabilities`, camada AppleScript (`AppleMusicPlayer` com
  posição real, seek, volume por-app, shuffle/repeat), `PlayerRegistry`, modos de
  controle automático/fixo, UI condicional por capacidade (ícone da fonte, barra
  arrastável só onde há seek, alvo do volume explícito) e matriz empírica em
  `docs/compatibilidade-players.md`. Sem regressão no Amazon Music (verificado) —
  `2026-08-09 · #01`
- [ ] Verificar no menu da bandeja se "Abrir no login" continua ligado — o bundle de
  `/Applications` foi substituído inteiro em `2026-08-10 · #01` **e de novo em
  `2026-08-11 · #01`** e o registro do `SMAppService` pode não ter sobrevivido à
  troca — `2026-08-10 · #01`
- [ ] Testar o retorno automático do nível do widget elevado por ⌃⌥⌘M ao clicar em
  outro app (caminho `windowDidResignKey`): depende de o painel ter virado key na
  interação, o que não foi exercitado à mão — `2026-08-11 · #01`

- [x] Remontar o `.app` (v1.9.0) via `scripts/build-app.sh` e substituir o de
  `/Applications` — feito em `2026-08-10 · #01`. O `Resources/Info.plist` estava
  parado na 1.7.0 enquanto o CHANGELOG já ia na 1.9.0: bumpado para 1.9.0/9 antes de
  montar, senão o bundle sairia etiquetado errado. Binário de debug encerrado, `.app`
  instalado e em execução, adapter bundlado validado (`test` → exit 0; `get` retornou
  a faixa em reprodução) — `2026-08-09 · #01`

- [x] Testar fluxo de Amazon Music não instalado — feito por simulação (chave `simulateMissingApp` no UserDefaults + env `MMW_SIMULATE_MISSING_APP`), sem mexer no `.app` instalado. O alerta ganhou `NSApp.activate()`, senão poderia nascer atrás das janelas num app sem Dock — `2026-08-05 · #01`
- [x] Commit + push da verificação de app não instalado — feito junto ao encerramento da sessão `2026-06-26 · #01`
- [x] Confirmar URL de instalação — `music.amazon.com/download` dava 404; trocada por `am.app.link/zb0Bk69BNub` — `2026-06-24 · #01`

- [ ] **Fase 2 — o que ficou de fora desta rodada:** revisar a tradução pt-BR com o app
  aberto (as strings foram traduzidas mas só a consistência de chaves foi verificada por
  script, não o texto na tela); testar multi-monitor de verdade (a correção da grade por
  tela e a recuperação de posição foram feitas por leitura de código, com testes
  sintéticos — não há segundo monitor aqui) — `2026-08-10 · #01`

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

- [x] Conferir o texto exato da licença do adapter e preparar os textos de atribuição
  para o bundle de venda — feito em `2026-08-10 · #01`. As duas premissas da pendência
  estavam erradas: não é o fork do ejbills (esse é que é fork de `ungive`) e não é MIT.
  Há **um** terceiro redistribuído, não dois: o `mediaremote-adapter` de `ungive`
  (`Copyright (c) 2025, Jonas van den Berg and contributors`, BSD-3-Clause) — o
  executável `media-control` não vai no bundle. Texto integral e obrigações em
  `Resources/THIRD-PARTY-LICENSES.md`, copiado para dentro do `.app` pelo
  `build-app.sh` (cláusula 2 exige o aviso junto do binário). README e CLAUDE.md
  corrigidos. Ver `DECISOES.md` — `2026-08-09 · #01`
- [x] Barra de progresso não reflete seek feito dentro do Amazon Music — **não corrigível**, comprovado por captura do stream: no seek o app publica só `{"playing": bool}`, sem posição e sem `timestamp` novo; o `get` do adapter traz os mesmos campos e o app não tem AppleScript. O que era bug próprio (barra travando em 100% por timestamp obsoleto) foi corrigido. Ver `DECISOES.md` — `2026-08-05 · #01`
- [x] Barra de progresso não é ajustável pela UI — **não implementável**, comprovado por teste observável: seek para 5s antes do fim da faixa, com o app tocando, não fez a faixa terminar nem avançar (`Welcome to Paradise` 224s→219s e `Sultans Of Swing` 348s→340s). Contraprova no QuickTime (arquivo de 127s, seek para 100s → posição real 101,35s) mostra que o comando funciona: quem ignora é o `Amazon Music.app`. O `seek(toSeconds:)` foi removido e README/CLAUDE.md corrigidos, que anunciavam um recurso inexistente. Ver `DECISOES.md` — `2026-08-05 · #02`

## Baixa

- [x] Fallback de desenvolvimento em `NowPlayingController` aponta para `media-control/0.7.6` fixo, enquanto `build-app.sh` usa `brew --prefix`: atualizar o brew quebra o `swift run` fora do bundle — resolvido trocando o caminho do `Cellar/` (que carrega a versão no nome) pelos symlinks `opt/` do brew, que a fórmula reaponta a cada upgrade; inclui o prefixo Intel além do Apple Silicon — `2026-08-05 · #02`
