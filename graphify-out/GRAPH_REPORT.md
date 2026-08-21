# Graph Report - MacMediaWidget  (2026-08-21)

## Corpus Check
- 86 files · ~100,571 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1127 nodes · 1683 edges · 76 communities (69 shown, 7 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 120 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4371f6c9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Now Playing  MediaRemote|Now Playing / MediaRemote]]
- [[_COMMUNITY_UI ContentView  Liquid Glass|UI ContentView / Liquid Glass]]
- [[_COMMUNITY_Ciclo de vida & Preferências (janela)|Ciclo de vida & Preferências (janela)]]
- [[_COMMUNITY_Janela do widget & Snap|Janela do widget & Snap]]
- [[_COMMUNITY_Menu da bandeja|Menu da bandeja]]
- [[_COMMUNITY_Conceitos de arquitetura|Conceitos de arquitetura]]
- [[_COMMUNITY_Comandos de transporte|Comandos de transporte]]
- [[_COMMUNITY_Controle de volume do sistema|Controle de volume do sistema]]
- [[_COMMUNITY_Store de preferências (AppSettings)|Store de preferências (AppSettings)]]
- [[_COMMUNITY_Sessão 04 & empacotamento|Sessão #04 & empacotamento]]
- [[_COMMUNITY_Login item  autostart|Login item / autostart]]
- [[_COMMUNITY_Governança de sessões|Governança de sessões]]
- [[_COMMUNITY_Manifesto SPM|Manifesto SPM]]
- [[_COMMUNITY_Script de build|Script de build]]
- [[_COMMUNITY_Sessão 2026-06-22|Sessão 2026-06-22]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]

## God Nodes (most connected - your core abstractions)
1. `SelfTests` - 51 edges
2. `NowPlayingController` - 46 edges
3. `Decisões — MacMediaWidget` - 33 edges
4. `AppMenuController` - 30 edges
5. `AppKit` - 25 edges
6. `WidgetWindow` - 25 edges
7. `MediaRemotePlayer` - 23 edges
8. `Changelog — MacMediaWidget` - 23 edges
9. `AppSettings` - 22 edges
10. `AppleScriptPlayer` - 19 edges

## Surprising Connections (you probably didn't know these)
- `TrayController` --references--> `Amazon Music.app (com.amazon.music)`  [INFERRED]
  Sources/MacMediaWidget/TrayController.swift → README.md
- `NowPlayingController` --references--> `mediaremote-adapter (perl + framework bridge)`  [EXTRACTED]
  Sources/MacMediaWidget/NowPlayingController.swift → README.md
- `Sessão 2026-06-23 #04` --references--> `PreferencesView`  [EXTRACTED]
  docs/sessions/2026-06-23-04.md → Sources/MacMediaWidget/PreferencesWindow.swift
- `Sessão 2026-06-23 #04` --references--> `AppSettings`  [EXTRACTED]
  docs/sessions/2026-06-23-04.md → Sources/MacMediaWidget/Settings.swift
- `VerticalVolumeSlider (NSSlider wrapper)` --conceptually_related_to--> `Controle de volume do sistema via AppleScript`  [INFERRED]
  Sources/MacMediaWidget/ContentView.swift → CHANGELOG.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Fluxo Now Playing: UI, controller, adapter e player oficial** — contentview_contentview, nowplayingcontroller_nowplayingcontroller, mediaremote_adapter, amazon_music_app [INFERRED 0.85]
- **Preferências ao vivo via AppSettings/UserDefaults** — settings_appsettings, preferenceswindow_preferencesview, widgetwindow_widgetwindow, contentview_contentview [INFERRED 0.75]

## Communities (76 total, 7 thin omitted)

### Community 0 - "Now Playing / MediaRemote"
Cohesion: 0.05
Nodes (45): Sessão 2026-06-23 #04, Amazon Music.app (com.amazon.music), CardSurface (Liquid Glass modifier), ContentView (widget card UI), VerticalVolumeSlider (NSSlider wrapper), Equatable, Int, Liquid Glass nativo (glassEffect macOS 26) (+37 more)

### Community 1 - "UI ContentView / Liquid Glass"
Cohesion: 0.07
Nodes (36): Color, Coordinator, Gesture, CardContrast, CardMarquee, CardSurface, ContentView, Coordinator (+28 more)

### Community 2 - "Ciclo de vida & Preferências (janela)"
Cohesion: 0.09
Nodes (21): App (entry point enum), AppMenuController, GlobalHotKey, App, AppDelegate, DuplicateInstance, PreferencesController, PreferencesView (+13 more)

### Community 3 - "Janela do widget & Snap"
Cohesion: 0.08
Nodes (16): Int32, PlayerDeTeste, SelfTests, PlayerRegistry, SpotifyPlayer, Data, Date, TrackInfo (+8 more)

### Community 4 - "Menu da bandeja"
Cohesion: 0.06
Nodes (29): AppMenuController, MarqueeText, MenuStatusView, MenuTransportView, TrayController, NSMenuDelegate, NSMenuItem, NSSize (+21 more)

### Community 5 - "Conceitos de arquitetura"
Cohesion: 0.18
Nodes (13): Amazon Music.app oficial (com.amazon.music), NSPanel widget de mesa (borderless, todos os Spaces), Snap por ancoragem à borda (edgeMargin), mediaremote-adapter (perl entitled), Now Playing do macOS, VerticalVolumeSlider (NSSlider via NSViewRepresentable), Autostart no login via SMAppService, Build SPM + bundle .app + codesign ad-hoc (+5 more)

### Community 6 - "Comandos de transporte"
Cohesion: 0.25
Nodes (6): Carbon.HIToolbox, EventHandlerRef, EventHotKeyRef, GlobalHotKey, Int, Void

### Community 7 - "Controle de volume do sistema"
Cohesion: 0.05
Nodes (30): CGRect, Combine, Foundation, AppVersion, BrandMark, PlayGlyph, LoginItem, TransportButton (+22 more)

### Community 8 - "Store de preferências (AppSettings)"
Cohesion: 0.15
Nodes (17): CaseIterable, Identifiable, AppSettings, ControlMode, automatic, fixed, Defaults, Keys (+9 more)

### Community 9 - "Sessão #04 & empacotamento"
Cohesion: 0.12
Nodes (13): Error, AppleScriptPlayer, AppleScriptError, appNotRunning, failed, notAuthorized, AppleScriptRunner, Result (+5 more)

### Community 10 - "Login item / autostart"
Cohesion: 0.09
Nodes (14): AnyObject, L10n, OptionSet, DebugFlags, Player, PlayerCapabilities, Sendable, String (+6 more)

### Community 15 - "Community 15"
Cohesion: 0.16
Nodes (7): Player, MediaRemotePlayer, Bool, Double, PlayerCapabilities, String, URL

### Community 16 - "Community 16"
Cohesion: 0.08
Nodes (23): [1.0.0] — 2026-06-22 · #01, [1.0.1] — 2026-06-22 · #02, [1.10.0] — 2026-08-10 · #01 — Multi-player, [1.11.0] — 2026-08-10 · #01 — Robustez de produto, inglês e auditoria de segurança, [1.12.0] — 2026-08-11 · #01 — Interações do widget e atalho global, [1.13.0] — 2026-08-11 · #03 — Tamanho do widget configurável (1×1 e 2×1), [1.14.0] — 2026-08-12 · #01 — Transporte no menu e identidade visual, [1.15.0] — 2026-08-13 · #01 — Menu com largura fixa e auto-fechamento (+15 more)

### Community 17 - "Community 17"
Cohesion: 0.06
Nodes (33): 2026-08-05 · #01 — Arrasto da janela por deny-list de NSViews, 2026-08-05 · #01 — `diff: false` é snapshot, e snapshot vazio zera o estado, 2026-08-05 · #01 — Posição pós-seek no Amazon Music é irrecuperável, 2026-08-05 · #02 — Não há seek: o Amazon Music ignora o comando de posicionamento, 2026-08-09 · #01 — Rumo de produto: venda direta fora da App Store, Amazon Music inegociável, 2026-08-09 · #01 — Snap na grade celular dos widgets nativos, medida via CGWindowList, 2026-08-10 · #01 — Arquitetura da Fase 1: duas camadas, dois modos de controle, 2026-08-10 · #01 — Barra de progresso volta a ser controle onde o seek funciona (+25 more)

### Community 18 - "Community 18"
Cohesion: 0.17
Nodes (11): 0. Decisões já tomadas (não reabrir), 1. A restrição que determina toda a arquitetura, 2. O que cada fonte permite, 3. Desenho proposto, 4. Ordem de implementação, 5. Riscos e pontos de atenção, 6. Roteiro de testes empíricos (executar na sessão de desenvolvimento), 7. Pré-requisitos e limites conhecidos (+3 more)

### Community 19 - "Community 19"
Cohesion: 0.20
Nodes (9): 1. Execução de script a partir de caminho gravável (Alta) — corrigido, 2. Acumulador do stream sem teto (Média) — corrigido, 3. Chave de teste ativa em release (Baixa) — corrigido, 4. Interpolação em AppleScript — sem defeito hoje, 5. Capa decodificada de base64 (Informativo) — risco aceito, 6. Persistência (Informativo) — já tratado, Auditoria de segurança do app, O que esta auditoria não cobre (+1 more)

### Community 20 - "Community 20"
Cohesion: 0.13
Nodes (14): 2026-06-22, 2026-06-23, 2026-06-24, 2026-06-26, 2026-08-05, 2026-08-09, 2026-08-10, 2026-08-11 (+6 more)

### Community 21 - "Community 21"
Cohesion: 0.20
Nodes (9): 2026-06-23 · #01 — PoC: viabilidade do player Amazon Music embutido (Widevine), Ambiente confirmado, Arquivos tocados, Contexto da decisão (substitui premissa do plano #02), Decisões aprovadas, Objetivo, Requisitos do produto (reconfirmados pelo usuário nesta sessão), Resumo do que foi feito (+1 more)

### Community 22 - "Community 22"
Cohesion: 0.13
Nodes (14): Amazon Music (`com.amazon.music`), Apple Music (`com.apple.Music`), Armadilha de teste: o falso negativo do `next`, Como esta tabela virou código, Comportamento do sistema (não é de nenhum player específico), Deezer (`com.deezer.deezer-desktop`), Evidência, Matriz de compatibilidade por player (+6 more)

### Community 23 - "Community 23"
Cohesion: 0.22
Nodes (8): 2026-06-22 · #02 — Recuperar ambiente e reconstrução de features (widget + .dmg), Arquivos tocados, Contexto técnico confirmado, Decisões aprovadas, Decisões técnicas relevantes, Objetivo, Plano (etapas incrementais, commit por etapa), Resumo do que foi feito

### Community 24 - "Community 24"
Cohesion: 0.22
Nodes (8): 2026-06-26 · #01 — Fix da barra de progresso + preferências de snap, Arquivos alterados, Barra de progresso, Decisões técnicas, O que foi feito, Objetivo, Observação, Preferências de snap

### Community 25 - "Community 25"
Cohesion: 0.22
Nodes (8): Apps suportados, Build e empacotamento, Como funciona, Governança, Instalação (uso pessoal), MacMediaWidget, Requisitos, Uso

### Community 26 - "Community 26"
Cohesion: 0.25
Nodes (7): Fase 1 — Multi-player, Fase 2 — Robustez e QA de produto, Fase 3 — Nome e identidade visual, Fase 4 — Infra de venda direta, Fase 5 — Lançamento, Registro de riscos, ROADMAP — MMC (nome de trabalho)

### Community 27 - "Community 27"
Cohesion: 0.25
Nodes (7): 2026-08-05 · #01 — Arrasto restrito ao fundo + fechar pendências abertas, Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo, Resumo

### Community 28 - "Community 28"
Cohesion: 0.25
Nodes (7): 2026-08-05 · #02 — Seek pela UI: provar viabilidade e fechar pendências, Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo, Resumo

### Community 29 - "Community 29"
Cohesion: 0.25
Nodes (7): 2026-08-09 · #01 — Visual e grade de widget nativo do macOS, Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo, Resumo

### Community 30 - "Community 30"
Cohesion: 0.25
Nodes (7): 2026-08-10 · #01 — Pendências independentes, Fase 1 (multi-player) e Fase 2 (robustez), Arquivos tocados, Decisões, Métricas, O que foi feito, Objetivo, Próximo passo

### Community 31 - "Community 31"
Cohesion: 0.25
Nodes (7): 2026-08-11 · #01 — Interações do widget: duplo clique, menu de contexto, trocar app, sempre no topo, atalho global, Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo, Resumo

### Community 32 - "Community 32"
Cohesion: 0.29
Nodes (6): CLAUDE.md — MacMediaWidget, Estrutura de arquivos esperada, O que é o projeto, Regras técnicas, Sessões, Stack

### Community 33 - "Community 33"
Cohesion: 0.24
Nodes (10): Alta, Alta, Baixa, Baixa, Migradas em 2026-06-23 · #04, Migradas em 2026-08-11 · #03, Média, Média (+2 more)

### Community 34 - "Community 34"
Cohesion: 0.25
Nodes (14): adapter(), browser_js(), np(), np_field(), obs_field(), obs_playing(), obs_position(), obs_state() (+6 more)

### Community 35 - "Community 35"
Cohesion: 0.29
Nodes (6): 2026-06-23 · #03 — Controle de volume do sistema, Arquivos principais, Decisões aprovadas, Decisões técnicas, O que foi feito, Objetivo

### Community 36 - "Community 36"
Cohesion: 0.29
Nodes (6): 2026-06-23 · #04 — Liquid Glass nativo + tela de configurações + edgeMargin ajustável, Arquivos tocados, Correções durante a sessão, Decisões aprovadas, O que foi feito, Objetivo

### Community 37 - "Community 37"
Cohesion: 0.29
Nodes (6): 2026-06-24 · #01 — Verificação de Amazon Music não instalado, Arquivos alterados, Decisões aprovadas, O que foi feito, Objetivo, Pendências

### Community 38 - "Community 38"
Cohesion: 0.33
Nodes (5): Alertas, Decisões vigentes que restringem o trabalho, Estado — MacMediaWidget, Pendências abertas (prioridade), Próximo passo

### Community 39 - "Community 39"
Cohesion: 0.33
Nodes (5): 2026-06-22 · #01 — Migração pro git/GitHub + setup do protocolo de sessões, Arquivos principais criados, Decisões aprovadas, O que foi feito, Objetivo

### Community 40 - "Community 40"
Cohesion: 0.33
Nodes (5): 2026-06-23 · #02 — Limpeza Electron + setup Swift + mediaremote-adapter, Arquivos tocados, Decisões aprovadas, Objetivo, Resumo do que foi feito

### Community 41 - "Community 41"
Cohesion: 0.33
Nodes (5): 2026-06-23 · #05 — Fix: play com app fechado abria Apple Music em vez do Amazon Music, Arquivos alterados, Decisões técnicas, O que foi feito, Objetivo

### Community 42 - "Community 42"
Cohesion: 0.18
Nodes (10): Achado grave sem segunda opinião, Alta, Baixa, Decisões em aberto (travam cinco tarefas), Fora do plano de execução — para uma sessão futura, Medição que a auditoria não fez, Média, Os 30 achados baixos que não viraram tarefa (+2 more)

### Community 43 - "Community 43"
Cohesion: 0.40
Nodes (4): Componentes que NÃO geram obrigação de atribuição, Licenças de terceiros — MacMediaWidget, mediaremote-adapter, Obrigações práticas que essa licença impõe ao produto

### Community 45 - "Community 45"
Cohesion: 0.10
Nodes (19): CGSize, WidgetMetrics, Anchor, NativeWidgetGrid, WidgetWindow, NSPanel, NSPoint, NSRect (+11 more)

### Community 46 - "Community 46"
Cohesion: 0.11
Nodes (18): 1. O que foi apurado (sem executar nada nos players), 2. Decisões do dono do produto (`2026-08-19 · #01`), 3. Por que o YouTube Music não pode ter identidade própria, 4.1 Catálogo separado do registro, 4.2 Visibilidade: blocklist, não allowlist, 4.3 Apps descobertos, 4.4 Regras de coerência, 4.5 O filtro não pode virar card vazio (+10 more)

### Community 47 - "Community 47"
Cohesion: 0.14
Nodes (13): Auto-revisão do plano, Plano de implementação — players adicionais e visibilidade por app, Restrições globais, Tarefa 0: Colher a evidência (gate — não é código), Tarefa 1: `PlayerCatalog` sem mudança de comportamento, Tarefa 2: `SpotifyPlayer`, Tarefa 3: TIDAL, Deezer, navegador e o atalho do YouTube Music, Tarefa 4: Ancorar a posição no `elapsedTime` do stream (+5 more)

### Community 48 - "Community 48"
Cohesion: 0.25
Nodes (7): 2026-08-11 · #03 — Tamanho do widget configurável (1×1/2×1) + baixas de pendências, Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo, Resumo

### Community 49 - "Community 49"
Cohesion: 0.25
Nodes (7): 2026-08-12 · #01 — Transporte e status no menu + identidade visual (Órbita), Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo, Resumo

### Community 50 - "Community 50"
Cohesion: 0.25
Nodes (7): 2026-08-19 · #01 — Planejamento: Spotify, TIDAL, Deezer e YouTube Music + visibilidade por app, Arquivos tocados, Decisões, Métricas, O que foi feito, Objetivo, Próximo passo

### Community 51 - "Community 51"
Cohesion: 0.29
Nodes (6): 2026-08-11 · #02 — Verificar toggle do atalho global ⌃⌥⌘M, Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo

### Community 52 - "Community 52"
Cohesion: 0.29
Nodes (6): 2026-08-13 · #01 — Menu: largura fixa com letreiro + auto-fechamento em 2 s, Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo

### Community 54 - "Community 54"
Cohesion: 0.11
Nodes (18): 1. O modelo de subprocesso (a dívida estrutural), 2. Trabalho por tick onde deveria ser por evento (energia), 3. Estado obsoleto: o widget não relê o que mostra, 4. O parser confunde snapshot com diff, 5. Roteamento de comando com três buracos de UX, 6. Nenhuma visibilidade de falha, A refutação valeu o custo, As seis causas-raiz (+10 more)

### Community 55 - "Community 55"
Cohesion: 0.11
Nodes (18): 00 — Preparação, 01 — Fumaça (2 min), 02 — Um player por vez, 03 — Apps controlados (visibilidade, 1.16.0), 04 — Modo fixo e comando endereçado, 05 — Formato, marca e texto (o que só olho humano pega), 06 — Degradação (fazer por último: mexe em permissão do sistema), 07 — Folha de resultado (+10 more)

### Community 56 - "Community 56"
Cohesion: 0.17
Nodes (14): MainActor, LaunchTarget, app, appElseURL, PlayerCatalog, PlayerCatalogEntry, PlayerCatalogKind, app (+6 more)

### Community 57 - "Community 57"
Cohesion: 0.13
Nodes (15): 52. [ALTO] Controles do card sem rótulos de acessibilidade — VoiceOver inutilizável no widget, 53. [MÉDIO] Permissão de Automação negada: nenhum aviso nem caminho de recuperação para o usuário, 54. [MÉDIO] Contraste do conteúdo pode cair a ~2:1 com capa de luminância média, 55. [MÉDIO] Prompt de permissão de Automação do macOS sempre em português (NSAppleEventsUsageDescription não localizada), 56. [MÉDIO] Slider de volume mostra valor obsoleto: estado nunca é relido após a inicialização, 57. [MÉDIO] Player preferido padrão é Amazon Music: primeira experiência ruim para quem não o tem, 58. [MÉDIO] Botão play vira no-op silencioso com 'abrir ao dar play' desligado, 59. [MÉDIO] Letreiros rodam a 30 Hz permanentemente, inclusive com o widget oculto (+7 more)

### Community 58 - "Community 58"
Cohesion: 0.14
Nodes (14): 39. [ALTO] Alvo do volume fica obsoleto: retarget só dispara quando o bundle id muda, mas depende de isRunning/capabilities, 40. [MÉDIO] Snapshot (diff=false) com conteúdo é mesclado como diff: artwork, álbum, duração e demais campos velhos ficam grudados, 41. [MÉDIO] playPause controla a fonte oculta (contrariando o próprio invariante testado) e o símbolo do botão faz o oposto do que promete, 42. [MÉDIO] Trocar para um atalho de serviço web pausa o próprio serviço e espera uma sessão que nunca existirá, 43. [MÉDIO] Volume exibido nunca é relido: mudanças externas (teclas de volume, ajuste dentro do app) não chegam ao slider, 44. [BAIXO] Leitura assíncrona de volume por-app pode gravar o valor de outro player (guard só confere target.isApp), 45. [BAIXO] Poll de posição em voo reancora por cima de um seek ou troca de faixa, 46. [BAIXO] Tooltip de transporte mente para fonte oculta: "X is not playing" com X tocando (+6 more)

### Community 59 - "Community 59"
Cohesion: 0.29
Nodes (6): MediaRemoteAdapter, Bool, Double, Process, String, Void

### Community 60 - "Community 60"
Cohesion: 0.15
Nodes (5): AppKit, AmazonMusicPlayer, AppleMusicPlayer, URL, PlayerCapabilities

### Community 61 - "Community 61"
Cohesion: 0.15
Nodes (13): 10. [BAIXO] Zero visibilidade de falha em produção: sem crash reporting e sem telemetria de saúde, 11. [BAIXO] Info.plist sem NSHumanReadableCopyright, 12. [BAIXO] App Store confirmadamente inviável — venda direta é o único canal, e a decisão já está registrada, 1. [ALTO] Sem canal de atualização automática — o risco estrutural do produto fica sem resposta, 2. [ALTO] Entitlements dyld desnecessárias reabrem injeção de código no build assinado para o cliente, 3. [MÉDIO] Build arm64-only: o produto não roda em Macs Intel dentro do requisito declarado, 4. [MÉDIO] DMG de distribuição não é assinado, notarizado nem grampeado, 5. [MÉDIO] Dependência de build do adapter não é pinada nem vendorizada — release comercial irreproduzível (+5 more)

### Community 62 - "Community 62"
Cohesion: 0.15
Nodes (13): 18. [ALTO] readabilityHandler nunca removido: vazamento de FileHandle/fd e disparo contínuo em EOF a cada morte do stream, 19. [ALTO] Volume por-app dispara um osascript por evento de arrasto do slider, sem coalescência nem serialização — resultado final não determinístico, 20. [MÉDIO] isEntitled() sem timeout: um perl pendurado deixa o widget cego para sempre, com health preso em .starting e aparência de normalidade, 21. [MÉDIO] Poll de posição em voo aplica valor obsoleto: reancora a barra com posição pré-seek ou de outra faixa/player, 22. [MÉDIO] Nenhuma defesa contra stream vivo-porém-mudo: recuperação depende 100% da morte do processo; sleep/wake não é observado, 23. [MÉDIO] Chamadas bloqueantes (waitUntilExit/readDataToEndOfFile) dentro de Task.detached esgotam o pool cooperativo de Swift Concurrency, 24. [BAIXO] Deadlock possível no AppleScriptRunner com stderr volumoso: leitura sequencial dos dois pipes, 25. [BAIXO] Ordem de entrega dos chunks do stream depende de comportamento não garantido de Tasks não estruturadas (+5 more)

### Community 63 - "Community 63"
Cohesion: 0.17
Nodes (12): 66. [ALTO] Caminho mais crítico e com maior histórico de bugs — a ancoragem de posição — não tem nenhum teste, 67. [MÉDIO] Snapshot não-vazio é mesclado como diff: metadados da faixa/app anterior sobrevivem no card, 68. [MÉDIO] Qualquer linha do stream marca o canal como saudável — inclusive as que o parser descarta, 69. [MÉDIO] Comandos one-shot ao adapter são fire-and-forget: falha de send/seek é invisível e indiagnosticável, 70. [MÉDIO] A dependência central (mediaremote-adapter/media-control) não é pinada nem vendorada — build irreprodutível, 71. [MÉDIO] Verificador de traduções compara chaves, mas não os format specifiers dos valores traduzidos, 72. [MÉDIO] waitForSessionThenPlay não é cancelável: trocas rápidas de app deixam loops concorrentes que podem dar play tardio, 73. [BAIXO] Warning conhecido tolerado: Coordinator.changed lê doubleValue (MainActor) de contexto nonisolated (+4 more)

### Community 64 - "Community 64"
Cohesion: 0.20
Nodes (10): 30. [ALTO] Timer de progresso publica a 2 Hz permanentemente e re-renderiza três hierarquias SwiftUI mesmo em idle total, 31. [ALTO] Poll de posição real dispara um subprocesso osascript por segundo mesmo com a música pausada, 32. [ALTO] Timers de 30 Hz do letreiro rodam permanentemente — inclusive num item de menu fechado — e são recriados a cada re-render do pai, 33. [MÉDIO] Consultas a NSWorkspace/LaunchServices (ícone, isRunning, isInstalled) executadas dentro do body do SwiftUI a 2 Hz, 34. [MÉDIO] Parse de JSON e decodificação da capa (centenas de KB de base64 + NSImage) na main thread a cada linha do stream, 35. [MÉDIO] Arrastar o slider de volume por-app dispara um processo osascript por evento de tracking, sem coalescência, 36. [MÉDIO] Chamadas bloqueantes de osascript em Task.detached sem limite de concorrência podem empilhar e esgotar o pool cooperativo, 37. [BAIXO] Sem dedup da capa: cada linha com artworkData aloca um NSImage novo e re-tonaliza o card, mesmo com a arte idêntica (+2 more)

### Community 65 - "Community 65"
Cohesion: 0.22
Nodes (8): 2026-08-19 · #02 — Visibilidade por app + gate de evidência dos players, Achados da Tarefa 0 que mudam a implementação prevista, Arquivos tocados, Decisões, Métricas, O que foi feito, Objetivo, Próximo passo

### Community 66 - "Community 66"
Cohesion: 0.22
Nodes (8): 2026-08-21 · #02 — Auditoria completa pré-comercialização (ultracode), Achados que mais importam, Arquivos tocados, Decisões, Métricas, O que foi feito, Objetivo, Próximo passo

### Community 67 - "Community 67"
Cohesion: 0.25
Nodes (7): 13. [ALTO] Entitlements de hardened runtime desnecessárias abrem injeção de dylib com as permissões TCC do widget, 14. [MÉDIO] stderr do subprocesso de stream nunca é drenado — pipe cheio congela o widget em silêncio e sem reconexão, 15. [MÉDIO] osascript sem timeout somado a polling que não espera a leitura anterior: acúmulo de subprocessos e starvation do pool de concorrência, 16. [MÉDIO] Build empacota o mediaremote-adapter direto do Homebrew sem pinagem de versão nem verificação de integridade, 17. [BAIXO] DMG de distribuição sem assinatura nem notarização própria, mesmo no fluxo Developer ID, Anexo — achados completos da auditoria de 2026-08-21 · #02, Segurança

### Community 68 - "Community 68"
Cohesion: 0.32
Nodes (5): BrowserPlayer, Bool, PlayerCapabilities, String, URL

### Community 69 - "Community 69"
Cohesion: 0.25
Nodes (7): 2026-08-20 · #01 — Players adicionais: Spotify, TIDAL, Deezer, navegador e âncora de posição, Arquivos tocados, Decisões, Métricas, O que foi feito, Objetivo, Próximo passo

### Community 70 - "Community 70"
Cohesion: 0.25
Nodes (7): 2026-08-21 · #01 — Roteiro de aceitação, oito bugs achados nele, e a dívida técnica, Arquivos tocados, Decisões, Métricas, O que foi feito, Objetivo, Próximo passo

### Community 71 - "Community 71"
Cohesion: 0.29
Nodes (6): 2026-08-21 · #03 — Guia executável da auditoria (artifact com checkboxes e comentários), Arquivos tocados, Decisões, Métricas, Objetivo, Próximo passo

### Community 72 - "Community 72"
Cohesion: 0.40
Nodes (3): DeezerPlayer, PlayerCapabilities, URL

### Community 73 - "Community 73"
Cohesion: 0.40
Nodes (3): SafariPlayer, PlayerCapabilities, URL

### Community 74 - "Community 74"
Cohesion: 0.40
Nodes (3): TidalPlayer, PlayerCapabilities, URL

## Ambiguous Edges - Review These
- `package-dmg.sh` → `Amazon Music.app (com.amazon.music)`  [AMBIGUOUS]
  scripts/package-dmg.sh · relation: references

## Knowledge Gaps
- **517 isolated node(s):** `PackageDescription`, `Bool`, `CGFloat`, `TimeInterval`, `Bool` (+512 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `package-dmg.sh` and `Amazon Music.app (com.amazon.music)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `AppKit` connect `Community 60` to `Now Playing / MediaRemote`, `UI ContentView / Liquid Glass`, `Ciclo de vida & Preferências (janela)`, `Janela do widget & Snap`, `Menu da bandeja`, `Community 68`, `Comandos de transporte`, `Controle de volume do sistema`, `Community 72`, `Community 73`, `Login item / autostart`, `Community 74`, `Community 45`, `Community 56`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Why does `NowPlayingController` connect `Now Playing / MediaRemote` to `Store de preferências (AppSettings)`, `Ciclo de vida & Preferências (janela)`, `Community 45`, `Controle de volume do sistema`?**
  _High betweenness centrality (0.063) - this node is a cross-community bridge._
- **Why does `AppSettings` connect `Store de preferências (AppSettings)` to `Now Playing / MediaRemote`, `Ciclo de vida & Preferências (janela)`, `Community 45`, `Controle de volume do sistema`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `SelfTests` (e.g. with `NSRect` and `NSSize`) actually correct?**
  _`SelfTests` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `Bool`, `CGFloat` to the rest of the system?**
  _520 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Now Playing / MediaRemote` be split into smaller, more focused modules?**
  _Cohesion score 0.05146242132543503 - nodes in this community are weakly interconnected._