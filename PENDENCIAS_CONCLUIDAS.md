# Pendências Concluídas — MacMediaWidget

Histórico arquivado de pendências encerradas. Só recebe itens por migração explícita a pedido do usuário. Não é lido nem escrito no fluxo normal de sessão.

## Migradas em 2026-08-11 · #03

### Alta

- [x] **Fase 1 do ROADMAP — multi-player.** Implementada em `2026-08-10 · #01`:
  abstração `Player` + `PlayerCapabilities`, camada AppleScript (`AppleMusicPlayer` com
  posição real, seek, volume por-app, shuffle/repeat), `PlayerRegistry`, modos de
  controle automático/fixo, UI condicional por capacidade (ícone da fonte, barra
  arrastável só onde há seek, alvo do volume explícito) e matriz empírica em
  `docs/compatibilidade-players.md`. Sem regressão no Amazon Music (verificado) —
  `2026-08-09 · #01`
- [x] **Testes manuais que dependem de interação humana** (fonte de navegador, gesto
  de arraste na barra com o Apple Music, negar a permissão de Automação): executados
  pelo usuário e confirmados OK em `2026-08-11 · #03` — `2026-08-10 · #01`
- [x] Verificar no menu da bandeja se "Abrir no login" continua ligado após as trocas
  do bundle de `/Applications` (`2026-08-10 · #01` e `2026-08-11 · #01`): verificado
  pelo usuário, OK em `2026-08-11 · #03` — `2026-08-10 · #01`
- [x] Testar o retorno automático do nível do widget elevado por ⌃⌥⌘M ao clicar em
  outro app (caminho `windowDidResignKey`): testado pelo usuário junto do toggle do
  atalho, OK em `2026-08-11 · #03` — `2026-08-11 · #01`
- [x] Remontar o `.app` (v1.9.0) via `scripts/build-app.sh` e substituir o de
  `/Applications` — feito em `2026-08-10 · #01`. O `Resources/Info.plist` estava
  parado na 1.7.0 enquanto o CHANGELOG já ia na 1.9.0: bumpado para 1.9.0/9 antes de
  montar, senão o bundle sairia etiquetado errado. Binário de debug encerrado, `.app`
  instalado e em execução, adapter bundlado validado (`test` → exit 0; `get` retornou
  a faixa em reprodução) — `2026-08-09 · #01`
- [x] Testar fluxo de Amazon Music não instalado — feito por simulação (chave
  `simulateMissingApp` no UserDefaults + env `MMW_SIMULATE_MISSING_APP`), sem mexer no
  `.app` instalado. O alerta ganhou `NSApp.activate()`, senão poderia nascer atrás das
  janelas num app sem Dock — `2026-08-05 · #01`
- [x] Commit + push da verificação de app não instalado — feito junto ao encerramento
  da sessão `2026-06-26 · #01`
- [x] Confirmar URL de instalação — `music.amazon.com/download` dava 404; trocada por
  `am.app.link/zb0Bk69BNub` — `2026-06-24 · #01`

### Média

- [x] Conferir o texto exato da licença do adapter e preparar os textos de atribuição
  para o bundle de venda — feito em `2026-08-10 · #01`. As duas premissas da pendência
  estavam erradas: não é o fork do ejbills (esse é que é fork de `ungive`) e não é MIT.
  Há **um** terceiro redistribuído, não dois: o `mediaremote-adapter` de `ungive`
  (`Copyright (c) 2025, Jonas van den Berg and contributors`, BSD-3-Clause) — o
  executável `media-control` não vai no bundle. Texto integral e obrigações em
  `Resources/THIRD-PARTY-LICENSES.md`, copiado para dentro do `.app` pelo
  `build-app.sh` (cláusula 2 exige o aviso junto do binário). README e CLAUDE.md
  corrigidos. Ver `DECISOES.md` — `2026-08-09 · #01`
- [x] Barra de progresso não reflete seek feito dentro do Amazon Music — **não
  corrigível**, comprovado por captura do stream: no seek o app publica só
  `{"playing": bool}`, sem posição e sem `timestamp` novo; o `get` do adapter traz os
  mesmos campos e o app não tem AppleScript. O que era bug próprio (barra travando em
  100% por timestamp obsoleto) foi corrigido. Ver `DECISOES.md` — `2026-08-05 · #01`
- [x] Barra de progresso não é ajustável pela UI — **não implementável**, comprovado
  por teste observável: seek para 5s antes do fim da faixa, com o app tocando, não fez
  a faixa terminar nem avançar (`Welcome to Paradise` 224s→219s e `Sultans Of Swing`
  348s→340s). Contraprova no QuickTime (arquivo de 127s, seek para 100s → posição real
  101,35s) mostra que o comando funciona: quem ignora é o `Amazon Music.app`. O
  `seek(toSeconds:)` foi removido e README/CLAUDE.md corrigidos, que anunciavam um
  recurso inexistente. Ver `DECISOES.md` — `2026-08-05 · #02`

### Baixa

- [x] Fallback de desenvolvimento em `NowPlayingController` aponta para
  `media-control/0.7.6` fixo, enquanto `build-app.sh` usa `brew --prefix`: atualizar o
  brew quebra o `swift run` fora do bundle — resolvido trocando o caminho do `Cellar/`
  (que carrega a versão no nome) pelos symlinks `opt/` do brew, que a fórmula reaponta
  a cada upgrade; inclui o prefixo Intel além do Apple Silicon — `2026-08-05 · #02`

## Migradas em 2026-06-23 · #04

> **Virada de arquitetura (2026-06-23 · #01):** o projeto deixou de ser um app Electron que
> controla o PWA e passou a ser um **app Swift nativo** que controla o **app oficial
> `Amazon Music.app`** via Now Playing do macOS.

### Alta

- [x] **Limpar a base Electron** na própria pasta: remover `main.js`, `preload.js`,
  `renderer.js`, `index.html`, `style.css`, `package.json`, `package-lock.json` e
  `node_modules/`; ajustar `.gitignore` (tirar refs de pnpm/Electron, adicionar `.build/`).
  Git preserva o histórico — sem perda. (#01 2026-06-23 · feito #02)
- [x] **Atualizar `CLAUDE.md`**: seção "Stack" (Electron → Swift/AppKit + SwiftUI) e
  "Estrutura de arquivos esperada". (#01 2026-06-23 · feito #02)
- [x] **Setup do projeto Swift**: alvo executável via SPM + bundle `.app` montado à mão
  (`Info.plist` com `LSUIElement`) + codesign ad-hoc. (#01 2026-06-23 · feito #02)
- [x] **Integrar mediaremote-adapter** (fork Swift do `ejbills`): bundlar
  `MediaRemoteAdapter.framework` + perl; rodar `stream`, parsear JSON, atualizar UI; enviar
  comandos de transporte pelo mesmo canal. (#01 2026-06-23 · feito #02)

### Média

- [x] **Janela widget de mesa**: `NSWindow` em nível de desktop, presente em todos os Spaces,
  não-ativante, snap à grade com posição persistida. (#01 2026-06-23 · feito #02 — snap por
  ancoragem à borda, não grade do sistema; ver decisão na sessão)
- [x] **UI Liquid Glass nativo** (macOS 26): capa, título, artista, barra de progresso e
  botões play/pause/anterior/próxima/seek. (#01 2026-06-23 — base entregue no #02; `glassEffect`
  nativo aplicado no #04 via `CardSurface`, em camada de fundo p/ não capturar o arraste)
- [x] **Tray na barra de menu** (`NSStatusItem`): mostrar/ocultar widget, preferências, sair. (#01 2026-06-23 · feito #02)
- [x] **Autostart no login** via `SMAppService`. (#01 2026-06-23 · feito #02 — toggle no menu da bandeja)
- [x] **Tela de configurações dedicada**: janela de preferências (margem/grade, etc.). (#02 2026-06-23
  · feito #04 — `AppSettings` + `PreferencesView` abertos pela bandeja; margem, grade, opacidade do
  tint, auto-abrir Amazon Music ao play e abrir no login; aplica ao vivo)
- [x] **Botão "abrir Amazon Music"** (`NSWorkspace`, bundle `com.amazon.music`). (#01 2026-06-23 · feito #02)

### Baixa

- [x] **Persistência** (posição da janela, preferências) em `UserDefaults`. (#01 2026-06-23 —
  posição da janela feita no #02; descartado como item autônomo no #03 — preferências futuras
  ficam acopladas à "Tela de configurações dedicada")
- [x] **Empacotamento/distribuição** do `.app` (`.dmg` opcional; sem Apple Developer ID →
  contorno de Gatekeeper para uso pessoal). (#01 2026-06-23 · feito #04 — `scripts/package-dmg.sh`
  gera o `.dmg`; README com instruções de instalação e remoção da quarentena)
- [x] **Controle de volume — opção 1 (volume do sistema)**: ajustar o volume do macOS via
  AppleScript (`set volume`). Decidido no #02: é global, não por-app; volume por-app real exige
  driver de áudio virtual (fora de escopo) e o MediaRemote não tem comando de volume. (#02 2026-06-23 ·
  feito #03 — sidebar fixa com slider vertical `NSSlider` + mute; `SystemVolumeController`)
- [x] **Calibrar `edgeMargin`** do snap horizontal para casar exatamente com a coluna dos widgets
  nativos. (#02 2026-06-23 · feito #04 — `edgeMargin` virou preferência ajustável ao vivo na tela de
  configurações; calibração agora é visual, sem recompilar)

### Obsoletas — arquitetura Electron descartada (2026-06-23 · #01)

Marcadas `[x]` por encerramento (descartadas, não concluídas).

- [x] ~~Etapa 1 — Integração com o PWA via AppleScript~~ → descartada: o Amazon Music web
  bloqueia navegador desconhecido; abordagem trocada por controle do app oficial. (#02)
- [x] ~~Etapa 2 — Comportamento de widget de mesa (em Electron)~~ → substituída pela versão Swift. (#02)
- [x] ~~Etapa 3 — Liquid Glass via `vibrancy` do BrowserWindow~~ → substituída por Liquid Glass nativo (Swift). (#02)
- [x] ~~Etapa 4 — Persistência (Electron)~~ → substituída pela versão Swift. (#02)
- [x] ~~Etapa 6 — Empacotamento `.dmg` do app Electron~~ → substituída por empacotamento `.app` Swift. (#02)
