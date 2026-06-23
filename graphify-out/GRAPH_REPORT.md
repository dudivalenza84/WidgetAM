# Graph Report - .  (2026-06-23)

## Corpus Check
- 14 files · ~10,213 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 177 nodes · 296 edges · 15 communities (11 shown, 4 thin omitted)
- Extraction: 94% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.8)
- Token cost: 51,786 input · 0 output

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

## God Nodes (most connected - your core abstractions)
1. `NowPlayingController` - 29 edges
2. `TrayController` - 16 edges
3. `WidgetWindow` - 15 edges
4. `AppDelegate` - 13 edges
5. `AppSettings` - 12 edges
6. `SystemVolumeController` - 11 edges
7. `TrackInfo` - 9 edges
8. `MediaCommand` - 9 edges
9. `ContentView` - 8 edges
10. `PreferencesController` - 8 edges

## Surprising Connections (you probably didn't know these)
- `NowPlayingController` --references--> `mediaremote-adapter (perl + framework bridge)`  [EXTRACTED]
  Sources/MacMediaWidget/NowPlayingController.swift → README.md
- `TrayController` --references--> `Amazon Music.app (com.amazon.music)`  [INFERRED]
  Sources/MacMediaWidget/TrayController.swift → README.md
- `NowPlayingController` --references--> `Amazon Music.app (com.amazon.music)`  [EXTRACTED]
  Sources/MacMediaWidget/NowPlayingController.swift → README.md
- `Sessão 2026-06-23 #04` --references--> `PreferencesView`  [EXTRACTED]
  docs/sessions/2026-06-23-04.md → Sources/MacMediaWidget/PreferencesWindow.swift
- `Sessão 2026-06-23 #04` --references--> `AppSettings`  [EXTRACTED]
  docs/sessions/2026-06-23-04.md → Sources/MacMediaWidget/Settings.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Fluxo Now Playing: UI, controller, adapter e player oficial** — contentview_contentview, nowplayingcontroller_nowplayingcontroller, mediaremote_adapter, amazon_music_app [INFERRED 0.85]
- **Preferências ao vivo via AppSettings/UserDefaults** — settings_appsettings, preferenceswindow_preferencesview, widgetwindow_widgetwindow, contentview_contentview [INFERRED 0.75]

## Communities (15 total, 4 thin omitted)

### Community 0 - "Now Playing / MediaRemote"
Cohesion: 0.15
Nodes (12): Data, Date, Equatable, NowPlayingController, TrackInfo, NSColor, NSImage, Process (+4 more)

### Community 1 - "UI ContentView / Liquid Glass"
Cohesion: 0.11
Nodes (17): Color, Content, Context, CardSurface, ContentView, VerticalVolumeSlider, NSSlider, NSViewRepresentable (+9 more)

### Community 2 - "Ciclo de vida & Preferências (janela)"
Cohesion: 0.14
Nodes (12): App (entry point enum), App, AppDelegate, PreferencesController, PreferencesView, NSApplicationDelegate, NSObject, NSWindow (+4 more)

### Community 3 - "Janela do widget & Snap"
Cohesion: 0.14
Nodes (14): ContentView (widget card UI), VerticalVolumeSlider (NSSlider wrapper), Int, WidgetMetrics, WidgetWindow, NSPanel, NSPoint, NSWindowDelegate (+6 more)

### Community 4 - "Menu da bandeja"
Cohesion: 0.16
Nodes (8): TrayController, NSMenu, NSMenuDelegate, NSMenuItem, NSStatusItem, Selector, String, Void

### Community 5 - "Conceitos de arquitetura"
Cohesion: 0.18
Nodes (13): Amazon Music.app oficial (com.amazon.music), NSPanel widget de mesa (borderless, todos os Spaces), Snap por ancoragem à borda (edgeMargin), mediaremote-adapter (perl entitled), Now Playing do macOS, VerticalVolumeSlider (NSSlider via NSViewRepresentable), Autostart no login via SMAppService, Build SPM + bundle .app + codesign ad-hoc (+5 more)

### Community 6 - "Comandos de transporte"
Cohesion: 0.20
Nodes (8): AppKit, Combine, MediaCommand, nextTrack, pause, play, previousTrack, togglePlayPause

### Community 7 - "Controle de volume do sistema"
Cohesion: 0.36
Nodes (5): SystemVolumeController, Bool, Double, Int, String

### Community 8 - "Store de preferências (AppSettings)"
Cohesion: 0.31
Nodes (8): AppSettings, Defaults, Keys, ObservableObject, Bool, CGFloat, Double, UserDefaults

### Community 9 - "Sessão #04 & empacotamento"
Cohesion: 0.25
Nodes (7): Sessão 2026-06-23 #04, Amazon Music.app (com.amazon.music), CardSurface (Liquid Glass modifier), Liquid Glass nativo (glassEffect macOS 26), mediaremote-adapter (perl + framework bridge), Now Playing do macOS, package-dmg.sh script

### Community 10 - "Login item / autostart"
Cohesion: 0.33
Nodes (4): Foundation, LoginItem, ServiceManagement, Bool

## Ambiguous Edges - Review These
- `package-dmg.sh` → `Amazon Music.app (com.amazon.music)`  [AMBIGUOUS]
  scripts/package-dmg.sh · relation: references

## Knowledge Gaps
- **32 isolated node(s):** `NowPlayingController`, `TrackInfo`, `RoundedRectangle`, `Content`, `NSColor` (+27 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `package-dmg.sh` and `Amazon Music.app (com.amazon.music)`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `NowPlayingController` connect `Now Playing / MediaRemote` to `Ciclo de vida & Preferências (janela)`, `Janela do widget & Snap`, `Comandos de transporte`, `Store de preferências (AppSettings)`, `Sessão #04 & empacotamento`?**
  _High betweenness centrality (0.295) - this node is a cross-community bridge._
- **Why does `AppSettings` connect `Store de preferências (AppSettings)` to `Now Playing / MediaRemote`, `Sessão #04 & empacotamento`, `Ciclo de vida & Preferências (janela)`, `Janela do widget & Snap`?**
  _High betweenness centrality (0.166) - this node is a cross-community bridge._
- **Why does `AppDelegate` connect `Ciclo de vida & Preferências (janela)` to `Now Playing / MediaRemote`, `Janela do widget & Snap`, `Menu da bandeja`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **What connects `NowPlayingController`, `TrackInfo`, `RoundedRectangle` to the rest of the system?**
  _35 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `UI ContentView / Liquid Glass` be split into smaller, more focused modules?**
  _Cohesion score 0.11333333333333333 - nodes in this community are weakly interconnected._
- **Should `Ciclo de vida & Preferências (janela)` be split into smaller, more focused modules?**
  _Cohesion score 0.1380952380952381 - nodes in this community are weakly interconnected._