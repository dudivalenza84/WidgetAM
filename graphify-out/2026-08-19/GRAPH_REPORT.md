# Graph Report - MacMediaWidget  (2026-08-11)

## Corpus Check
- 59 files · ~37,500 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 678 nodes · 1050 edges · 45 communities (40 shown, 5 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 88 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `cdbaea1a`
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

## God Nodes (most connected - your core abstractions)
1. `NowPlayingController` - 43 edges
2. `SelfTests` - 27 edges
3. `WidgetWindow` - 24 edges
4. `AppKit` - 18 edges
5. `AppMenuController` - 18 edges
6. `MediaRemotePlayer` - 17 edges
7. `Player` - 16 edges
8. `TrayController` - 16 edges
9. `Changelog — MacMediaWidget` - 16 edges
10. `AppDelegate` - 15 edges

## Surprising Connections (you probably didn't know these)
- `NowPlayingController` --references--> `mediaremote-adapter (perl + framework bridge)`  [EXTRACTED]
  Sources/MacMediaWidget/NowPlayingController.swift → README.md
- `TrayController` --references--> `Amazon Music.app (com.amazon.music)`  [INFERRED]
  Sources/MacMediaWidget/TrayController.swift → README.md
- `NowPlayingController` --references--> `Amazon Music.app (com.amazon.music)`  [EXTRACTED]
  Sources/MacMediaWidget/NowPlayingController.swift → README.md
- `Sessão 2026-06-23 #04` --references--> `PreferencesView`  [EXTRACTED]
  docs/sessions/2026-06-23-04.md → Sources/MacMediaWidget/PreferencesWindow.swift
- `VerticalVolumeSlider (NSSlider wrapper)` --conceptually_related_to--> `Controle de volume do sistema via AppleScript`  [INFERRED]
  Sources/MacMediaWidget/ContentView.swift → CHANGELOG.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Fluxo Now Playing: UI, controller, adapter e player oficial** — contentview_contentview, nowplayingcontroller_nowplayingcontroller, mediaremote_adapter, amazon_music_app [INFERRED 0.85]
- **Preferências ao vivo via AppSettings/UserDefaults** — settings_appsettings, preferenceswindow_preferencesview, widgetwindow_widgetwindow, contentview_contentview [INFERRED 0.75]

## Communities (45 total, 5 thin omitted)

### Community 0 - "Now Playing / MediaRemote"
Cohesion: 0.06
Nodes (38): ContentView (widget card UI), VerticalVolumeSlider (NSSlider wrapper), Gesture, Int, NSImage, WidgetMetrics, AdapterHealth, healthy (+30 more)

### Community 1 - "UI ContentView / Liquid Glass"
Cohesion: 0.07
Nodes (32): Color, Coordinator, CardSurface, ContentView, Coordinator, VerticalVolumeSlider, PreferencesView, NonDraggableArea (+24 more)

### Community 2 - "Ciclo de vida & Preferências (janela)"
Cohesion: 0.08
Nodes (22): App (entry point enum), AppMenuController, GlobalHotKey, App, AppDelegate, PreferencesController, WidgetWindow, NSApplicationDelegate (+14 more)

### Community 3 - "Janela do widget & Snap"
Cohesion: 0.11
Nodes (18): Equatable, Int32, NowPlayingParser, Outcome, ignored, reset, update, SelfTests (+10 more)

### Community 4 - "Menu da bandeja"
Cohesion: 0.09
Nodes (16): AppMenuController, TrayController, NSMenuDelegate, NSMenuItem, NSStatusItem, PlayerRegistry, Selector, NSMenu (+8 more)

### Community 5 - "Conceitos de arquitetura"
Cohesion: 0.18
Nodes (13): Amazon Music.app oficial (com.amazon.music), NSPanel widget de mesa (borderless, todos os Spaces), Snap por ancoragem à borda (edgeMargin), mediaremote-adapter (perl entitled), Now Playing do macOS, VerticalVolumeSlider (NSSlider via NSViewRepresentable), Autostart no login via SMAppService, Build SPM + bundle .app + codesign ad-hoc (+5 more)

### Community 6 - "Comandos de transporte"
Cohesion: 0.09
Nodes (15): AppKit, Carbon.HIToolbox, EventHandlerRef, EventHotKeyRef, GlobalHotKey, Anchor, NativeWidgetGrid, NSScreen (+7 more)

### Community 7 - "Controle de volume do sistema"
Cohesion: 0.06
Nodes (27): AnyObject, Combine, SystemVolumeController, Target, app, system, VolumeRouter, ObservableObject (+19 more)

### Community 8 - "Store de preferências (AppSettings)"
Cohesion: 0.11
Nodes (20): Sessão 2026-06-23 #04, Amazon Music.app (com.amazon.music), CaseIterable, CardSurface (Liquid Glass modifier), Identifiable, Liquid Glass nativo (glassEffect macOS 26), AppSettings, ControlMode (+12 more)

### Community 9 - "Sessão #04 & empacotamento"
Cohesion: 0.10
Nodes (15): Error, AppleMusicPlayer, AppleScriptPlayer, AppleScriptError, appNotRunning, failed, notAuthorized, AppleScriptRunner (+7 more)

### Community 10 - "Login item / autostart"
Cohesion: 0.12
Nodes (8): Foundation, AppVersion, L10n, LoginItem, ServiceManagement, String, String, Bool

### Community 15 - "Community 15"
Cohesion: 0.13
Nodes (10): Player, MediaRemoteAdapter, MediaRemotePlayer, Bool, Process, String, Double, PlayerCapabilities (+2 more)

### Community 16 - "Community 16"
Cohesion: 0.12
Nodes (16): [1.0.0] — 2026-06-22 · #01, [1.0.1] — 2026-06-22 · #02, [1.10.0] — 2026-08-10 · #01 — Multi-player, [1.11.0] — 2026-08-10 · #01 — Robustez de produto, inglês e auditoria de segurança, [1.12.0] — 2026-08-11 · #01 — Interações do widget e atalho global, [1.1.0] — 2026-06-23 · #01, [1.2.0] — 2026-06-23 · #02, [1.3.0] — 2026-06-23 · #03 (+8 more)

### Community 17 - "Community 17"
Cohesion: 0.13
Nodes (14): 2026-08-05 · #01 — Arrasto da janela por deny-list de NSViews, 2026-08-05 · #01 — `diff: false` é snapshot, e snapshot vazio zera o estado, 2026-08-05 · #01 — Posição pós-seek no Amazon Music é irrecuperável, 2026-08-05 · #02 — Não há seek: o Amazon Music ignora o comando de posicionamento, 2026-08-09 · #01 — Rumo de produto: venda direta fora da App Store, Amazon Music inegociável, 2026-08-09 · #01 — Snap na grade celular dos widgets nativos, medida via CGWindowList, 2026-08-10 · #01 — Arquitetura da Fase 1: duas camadas, dois modos de controle, 2026-08-10 · #01 — Barra de progresso volta a ser controle onde o seek funciona (+6 more)

### Community 18 - "Community 18"
Cohesion: 0.17
Nodes (11): 0. Decisões já tomadas (não reabrir), 1. A restrição que determina toda a arquitetura, 2. O que cada fonte permite, 3. Desenho proposto, 4. Ordem de implementação, 5. Riscos e pontos de atenção, 6. Roteiro de testes empíricos (executar na sessão de desenvolvimento), 7. Pré-requisitos e limites conhecidos (+3 more)

### Community 19 - "Community 19"
Cohesion: 0.20
Nodes (9): 1. Execução de script a partir de caminho gravável (Alta) — corrigido, 2. Acumulador do stream sem teto (Média) — corrigido, 3. Chave de teste ativa em release (Baixa) — corrigido, 4. Interpolação em AppleScript — sem defeito hoje, 5. Capa decodificada de base64 (Informativo) — risco aceito, 6. Persistência (Informativo) — já tratado, Auditoria de segurança do app, O que esta auditoria não cobre (+1 more)

### Community 20 - "Community 20"
Cohesion: 0.20
Nodes (9): 2026-06-22, 2026-06-23, 2026-06-24, 2026-06-26, 2026-08-05, 2026-08-09, 2026-08-10, 2026-08-11 (+1 more)

### Community 21 - "Community 21"
Cohesion: 0.20
Nodes (9): 2026-06-23 · #01 — PoC: viabilidade do player Amazon Music embutido (Widevine), Ambiente confirmado, Arquivos tocados, Contexto da decisão (substitui premissa do plano #02), Decisões aprovadas, Objetivo, Requisitos do produto (reconfirmados pelo usuário nesta sessão), Resumo do que foi feito (+1 more)

### Community 22 - "Community 22"
Cohesion: 0.22
Nodes (8): Amazon Music (`com.amazon.music`), Apple Music (`com.apple.Music`), Armadilha de teste: o falso negativo do `next`, Comportamento do sistema (não é de nenhum player específico), Evidência, Matriz de compatibilidade por player, O que falta testar, Tabela

### Community 23 - "Community 23"
Cohesion: 0.22
Nodes (8): 2026-06-22 · #02 — Recuperar ambiente e reconstrução de features (widget + .dmg), Arquivos tocados, Contexto técnico confirmado, Decisões aprovadas, Decisões técnicas relevantes, Objetivo, Plano (etapas incrementais, commit por etapa), Resumo do que foi feito

### Community 24 - "Community 24"
Cohesion: 0.22
Nodes (8): 2026-06-26 · #01 — Fix da barra de progresso + preferências de snap, Arquivos alterados, Barra de progresso, Decisões técnicas, O que foi feito, Objetivo, Observação, Preferências de snap

### Community 25 - "Community 25"
Cohesion: 0.25
Nodes (7): Build e empacotamento, Como funciona, Governança, Instalação (uso pessoal), MacMediaWidget, Requisitos, Uso

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
Cohesion: 0.29
Nodes (6): Alta, Baixa, Migradas em 2026-06-23 · #04, Média, Obsoletas — arquitetura Electron descartada (2026-06-23 · #01), Pendências Concluídas — MacMediaWidget

### Community 34 - "Community 34"
Cohesion: 0.52
Nodes (6): adapter(), np(), np_field(), osa(), resultado(), testar-player.sh script

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
Cohesion: 0.40
Nodes (4): Alta, Baixa, Média, Pendências — MacMediaWidget

### Community 43 - "Community 43"
Cohesion: 0.40
Nodes (4): Componentes que NÃO geram obrigação de atribuição, Licenças de terceiros — MacMediaWidget, mediaremote-adapter, Obrigações práticas que essa licença impõe ao produto

## Ambiguous Edges - Review These
- `package-dmg.sh` → `Amazon Music.app (com.amazon.music)`  [AMBIGUOUS]
  scripts/package-dmg.sh · relation: references

## Knowledge Gaps
- **250 isolated node(s):** `PackageDescription`, `Player`, `String`, `String`, `NowPlayingController` (+245 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `package-dmg.sh` and `Amazon Music.app (com.amazon.music)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `AppKit` connect `Comandos de transporte` to `Now Playing / MediaRemote`, `UI ContentView / Liquid Glass`, `Ciclo de vida & Preferências (janela)`, `Janela do widget & Snap`, `Menu da bandeja`, `Controle de volume do sistema`, `Sessão #04 & empacotamento`?**
  _High betweenness centrality (0.110) - this node is a cross-community bridge._
- **Why does `NowPlayingController` connect `Now Playing / MediaRemote` to `Store de preferências (AppSettings)`, `Ciclo de vida & Preferências (janela)`, `Controle de volume do sistema`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Why does `AppSettings` connect `Store de preferências (AppSettings)` to `Now Playing / MediaRemote`, `UI ContentView / Liquid Glass`, `Ciclo de vida & Preferências (janela)`, `Controle de volume do sistema`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `SelfTests` (e.g. with `NSRect` and `NSSize`) actually correct?**
  _`SelfTests` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PackageDescription`, `Player`, `String` to the rest of the system?**
  _253 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Now Playing / MediaRemote` be split into smaller, more focused modules?**
  _Cohesion score 0.06101190476190476 - nodes in this community are weakly interconnected._