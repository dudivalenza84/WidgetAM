# Changelog — MacMediaWidget

Formato semver: MINOR por release cronológica, PATCH para hotfix.
Entradas novas vão no topo.

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
