# Plano de implementação — players adicionais e visibilidade por app

> Plano derivado de `docs/players-adicionais.md` (desenho aprovado em `2026-08-19 · #01`).
> Steps usam checkbox (`- [ ]`) para acompanhamento. Nenhuma tarefa começa antes da
> Tarefa 0.

> **Executado.** Tarefas 0, 1, 5, 6, 7 e 8 em `2026-08-19 · #02`; **2, 3, 4 e 9 em
> `2026-08-20 · #01`** (1.17.0). Onde este plano contradisse
> `docs/compatibilidade-players.md`, valeu a matriz — as divergências e o que elas
> produziram estão em `DECISOES.md · 2026-08-20 · #01`: transporte deixou de ser um bloco
> só (`nextTrack`/`previousTrack`), o seek do MediaRemote virou caminho real, o atalho
> ganhou `catalogID` e o Safari ficou fora do catálogo por não ter sido medido.

**Objetivo:** dar suporte a Spotify, TIDAL, Deezer e YouTube Music, e deixar o usuário
escolher por checkbox quais apps o widget controla e exibe.

**Arquitetura:** um `PlayerCatalog` declarativo separa o que o usuário pode escolher do
que o `PlayerRegistry` resolve a partir da sessão de Now Playing. A visibilidade é
persistida como lista de **ocultos**, e o filtro atua em dois pontos: nas listas de
escolha (menu e preferências) e na exibição da sessão ativa.

**Stack:** Swift 6 / AppKit + SwiftUI, SPM sem Xcode. Testes em `SelfTests.swift`
(`swift run MacMediaWidget --run-tests`), **não** XCTest.

## Restrições globais

- **Nada de capacidade presumida.** Toda `PlayerCapabilities` declarada nas Tarefas 2 e
  3 vem da evidência colhida na Tarefa 0. Se um teste não foi feito, a capacidade não
  entra. Precedente: o Amazon Music aceita o seek do MediaRemote e o ignora.
- **pt-BR com acentuação** em comentários voltados ao usuário, commits e docs.
  Identificadores em inglês.
- **Idioma-base da UI é inglês:** string nova entra como `String(localized:)` no
  `L10n.swift` com a chave em inglês, e ganha tradução em
  `Resources/pt-BR.lproj/Localizable.strings`. Rodar `scripts/verificar-traducoes.sh`
  depois — chave faltando cai no inglês em silêncio.
- **Área interativa nova precisa de `.nonDraggableWindowArea()`**, senão o controle
  arrasta a janela (`DECISOES.md · 2026-08-05 · #01`).
- **Verificação por tarefa:** `swift build 2>&1 | tail -20` e
  `swift run MacMediaWidget --run-tests`. As duas verdes antes do commit.
- **Commit por tarefa**, em pt-BR, imperativo. Push só no encerramento da sessão.

---

### Tarefa 0: Colher a evidência (gate — não é código)

Sem esta tarefa as Tarefas 2 e 3 não têm o que declarar. Requer **fila com 3 ou mais
faixas** em cada player: com uma faixa só, `next` dá falso negativo (armadilha
registrada em `docs/compatibilidade-players.md`).

**Arquivos:**
- Modificar: `docs/compatibilidade-players.md` (colunas novas)

- [x] **Passo 1: Spotify — bateria completa**

```bash
scripts/testar-player.sh com.spotify.client Spotify 2>&1 | tee /tmp/teste-spotify.log
```

Aceitar o prompt de Automação quando o macOS pedir ("MacMediaWidget quer controlar
Spotify"). É o único do lote que pode ganhar a camada AppleScript.

- [x] **Passo 2: Spotify — seek pelo teste observável**

Com o Spotify tocando, posicionar a 5 s do fim da faixa e observar se ela termina e
avança sozinha. Ler o código de retorno **não** serve — foi assim que o Amazon Music
passou por funcional.

- [x] **Passo 3: TIDAL e Deezer**

```bash
scripts/testar-player.sh com.tidal.desktop 2>&1 | tee /tmp/teste-tidal.log
scripts/testar-player.sh com.deezer.deezer-desktop 2>&1 | tee /tmp/teste-deezer.log
```

Anotar especialmente se `elapsedTime` **avança** com música tocando (no TIDAL o campo
existe; falta saber se o valor anda). É o que decide a Tarefa 4.

- [x] **Passo 4: Navegador**

Abrir um vídeo no Chrome, dar play **manualmente** (autoplay com som é bloqueado) e:

```bash
scripts/testar-player.sh com.google.Chrome 2>&1 | tee /tmp/teste-chrome.log
```

- [x] **Passo 5: Identidade do PWA do YouTube Music**

Reinstalar o PWA pelo Chrome (menu → Transmitir, salvar e compartilhar → Instalar página
como app), abrir, dar play e ler:

```bash
media-control get | python3 -m json.tool | grep -E "bundleIdentifier|title"
```

Esperado, pelo mecanismo da §3 do desenho: `com.google.Chrome`. **Se vier o bundle id do
PWA**, o desenho está errado neste ponto — registrar em `DECISOES.md` e promover o
YouTube Music a `kind: .app` antes de seguir.

- [x] **Passo 6: Preencher a matriz e commitar**

Cada célula recebe *verificado (com evidência)*, *não funciona (com evidência)* ou
*não existe*. Colar as linhas de evidência como nas seções já existentes.

```bash
git add docs/compatibilidade-players.md
git commit -m "docs: apura compatibilidade de Spotify, TIDAL, Deezer e navegador"
```

---

### Tarefa 1: `PlayerCatalog` sem mudança de comportamento

Refatoração pura: as duas entradas de hoje passam a vir do catálogo e nada muda para o
usuário.

**Arquivos:**
- Criar: `Sources/MacMediaWidget/Players/PlayerCatalog.swift`
- Modificar: `Sources/MacMediaWidget/Players/PlayerRegistry.swift`
- Modificar: `Sources/MacMediaWidget/SelfTests.swift`

**Interfaces:**
- Produz: `PlayerCatalog.entries`, `PlayerCatalog.entry(for:)`, `PlayerCatalog.appEntries`,
  `PlayerCatalogEntry`, `PlayerCatalogKind`, `LaunchTarget`.
- Consome: `Player`, `AmazonMusicPlayer`, `AppleMusicPlayer` (já existentes).

- [x] **Passo 1: Escrever o teste que falha**

Em `SelfTests.swift`, acrescentar à lista de chamadas em `run()` (logo depois de
`playerRegistryMantémInstância()`):

```swift
        catálogoTemAsEntradasConhecidas()
        catálogoSeparaAppDeAtalho()
```

E as funções, junto das outras de player:

```swift
    private static func catálogoTemAsEntradasConhecidas() {
        let ids = PlayerCatalog.entries.map(\.id)
        expect(ids.contains(AmazonMusicPlayer.bundleID), "catálogo deveria ter Amazon Music")
        expect(ids.contains(AppleMusicPlayer.bundleID), "catálogo deveria ter Apple Music")
        expect(Set(ids).count == ids.count, "catálogo não pode ter id repetido")
    }

    /// Um atalho é lançável mas nunca identifica sessão — se ele entrasse em
    /// `appEntries`, o widget passaria a procurar uma sessão que não existe.
    private static func catálogoSeparaAppDeAtalho() {
        for entrada in PlayerCatalog.appEntries {
            if case .shortcut = entrada.kind {
                expect(false, "atalho \(entrada.id) não pode estar em appEntries")
            }
        }
    }
```

- [x] **Passo 2: Rodar e ver falhar**

```bash
swift build 2>&1 | tail -20
```

Esperado: FALHA de compilação com `cannot find 'PlayerCatalog' in scope`.

- [x] **Passo 3: Criar o catálogo**

`Sources/MacMediaWidget/Players/PlayerCatalog.swift`:

```swift
import AppKit

/// Como abrir uma entrada do catálogo.
enum LaunchTarget {
    /// Abre pelo próprio bundle id da entrada.
    case app
    /// Tenta o bundle id informado; se ele não estiver instalado, abre a URL no
    /// navegador padrão. É o caso do YouTube Music, cujo PWA pode nem existir.
    case appElseURL(bundleID: String, url: URL)
}

/// O que uma entrada é do ponto de vista do sistema.
///
/// A distinção não é cosmética: ela existe porque um serviço que roda dentro do
/// navegador **não tem sessão de Now Playing própria** — quem reproduz é o processo do
/// navegador, e o MediaRemote identifica a sessão pelo processo. Ver
/// `DECISOES.md · 2026-08-19 · #01`.
enum PlayerCatalogKind {
    /// App nativo: identifica sessão de Now Playing e pode ser lançado.
    case app
    /// Serviço hospedado em outro app. Só lançável; nunca identifica sessão.
    case shortcut(LaunchTarget)
}

/// Uma entrada do catálogo de apps suportados.
struct PlayerCatalogEntry {
    /// Chave estável: o bundle id para `.app`, um id sintético para `.shortcut`.
    let id: String
    let displayName: String
    let kind: PlayerCatalogKind
    let installURL: URL?
    let make: @MainActor () -> Player
}

/// Catálogo declarativo do que o usuário pode escolher.
///
/// Separado do `PlayerRegistry` de propósito: o registry responde "quem controla esta
/// sessão", e o catálogo responde "o que o usuário pode escolher". Os dois conjuntos
/// deixaram de coincidir quando entrou o YouTube Music, que é escolhível e não é
/// sessão.
@MainActor
enum PlayerCatalog {
    static var entries: [PlayerCatalogEntry] {
        [
            PlayerCatalogEntry(
                id: AmazonMusicPlayer.bundleID,
                displayName: "Amazon Music",
                kind: .app,
                installURL: URL(string: "https://am.app.link/zb0Bk69BNub/?__branch_flow_type=qr_code"),
                make: { AmazonMusicPlayer() }
            ),
            PlayerCatalogEntry(
                id: AppleMusicPlayer.bundleID,
                displayName: "Apple Music",
                kind: .app,
                installURL: nil,
                make: { AppleMusicPlayer() }
            ),
        ]
    }

    static func entry(for id: String) -> PlayerCatalogEntry? {
        entries.first { $0.id == id }
    }

    /// Só as entradas que identificam sessão de Now Playing.
    static var appEntries: [PlayerCatalogEntry] {
        entries.filter { if case .app = $0.kind { return true } else { return false } }
    }
}
```

- [x] **Passo 4: Fazer o registry consultar o catálogo**

Em `PlayerRegistry.swift`, trocar o dicionário `builders` pelo catálogo e substituir
`installedKnownPlayers()` — que misturava os dois papéis:

```swift
    /// O player que controla a fonte informada. `nil` só quando não há fonte alguma.
    func player(for bundleIdentifier: String?) -> Player? {
        guard let id = bundleIdentifier, !id.isEmpty else { return nil }
        if let existing = cache[id] { return existing }
        let player = PlayerCatalog.entry(for: id)?.make() ?? MediaRemotePlayer(bundleIdentifier: id)
        cache[id] = player
        return player
    }

    /// Players do catálogo que identificam sessão, instalados nesta máquina.
    func installedCatalogPlayers() -> [Player] {
        PlayerCatalog.appEntries
            .compactMap { player(for: $0.id) }
            .filter(\.isInstalled)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
```

Atualizar as duas chamadas de `installedKnownPlayers()` (`AppMenuController.swift:191`
e `PreferencesWindow.swift:43`) para `installedCatalogPlayers()`.

- [x] **Passo 5: Verificar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
```

Esperado: build limpo e todas as verificações passando (as antigas **e** as duas novas).

- [x] **Passo 6: Commit**

```bash
git add Sources/MacMediaWidget/Players/ Sources/MacMediaWidget/SelfTests.swift \
        Sources/MacMediaWidget/AppMenuController.swift Sources/MacMediaWidget/PreferencesWindow.swift
git commit -m "refactor: separa catálogo de players da resolução de sessão"
```

---

### Tarefa 2: `SpotifyPlayer`

**Só executar depois da Tarefa 0.** As capacidades abaixo estão escritas como o `.sdef`
sugere; **conferir contra `/tmp/teste-spotify.log` e remover o que não foi observado.**

**Arquivos:**
- Criar: `Sources/MacMediaWidget/Players/SpotifyPlayer.swift`
- Modificar: `Sources/MacMediaWidget/Players/PlayerCatalog.swift`
- Modificar: `Sources/MacMediaWidget/SelfTests.swift`

**Interfaces:**
- Consome: `AppleScriptPlayer` (base), `AppleScriptRunner.number(from:)`.
- Produz: `SpotifyPlayer.bundleID`.

- [ ] **Passo 1: Escrever o teste que falha**

```swift
    private static func playerSpotifyTemCamadaAppleScript() {
        let player = SpotifyPlayer()
        expect(player.bundleIdentifier == "com.spotify.client", "bundle id do Spotify")
        expect(player.capabilities.contains(.directedControl), "Spotify é endereçável por AppleScript")
        expect(player.capabilities.contains(.transport), "Spotify tem transporte")
    }
```

Registrar a chamada em `run()`.

- [ ] **Passo 2: Rodar e ver falhar**

```bash
swift build 2>&1 | tail -20
```

Esperado: `cannot find 'SpotifyPlayer' in scope`.

- [ ] **Passo 3: Implementar**

`Sources/MacMediaWidget/Players/SpotifyPlayer.swift`:

```swift
import AppKit

/// `Spotify.app` — o único dos players adicionais com dicionário AppleScript.
///
/// O `.sdef` expõe `player position` (real, gravável), `sound volume` (integer 0–100),
/// `shuffling` e `repeating` graváveis, e os comandos de transporte. Não há `mute`, que
/// o widget não usa. Capacidades confirmadas contra o app real em `2026-08-19 · #01`
/// (ver `docs/compatibilidade-players.md`).
@MainActor
final class SpotifyPlayer: AppleScriptPlayer {
    nonisolated static let bundleID = "com.spotify.client"

    init() {
        super.init(
            bundleIdentifier: Self.bundleID,
            displayName: "Spotify",
            scriptingName: "Spotify"
        )
    }

    override var scriptedCapabilities: PlayerCapabilities {
        // AJUSTAR conforme /tmp/teste-spotify.log — remover o que não foi observado.
        [.realPosition, .seek, .appVolume, .shuffleRepeat, .directedControl]
    }

    override var installURL: URL? { URL(string: "https://www.spotify.com/download/mac/") }

    // MARK: - Transporte (endereçado, funciona fora da sessão ativa)

    override func playPause() { fireIfRunning("playpause") }
    override func play() { fire("play") }
    override func next() { fireIfRunning("next track") }
    override func previous() { fireIfRunning("previous track") }

    // MARK: - Posição

    override func position() async -> Double? {
        guard isRunning else { return nil }
        return AppleScriptRunner.number(from: await tell("get player position"))
    }

    override func seek(to seconds: Double) {
        fireIfRunning("set player position to \(Int(seconds.rounded()))")
    }

    // MARK: - Volume por-app (0–100 no dicionário, 0…1 no protocolo)

    override func volume() async -> Double? {
        guard isRunning else { return nil }
        guard let level = AppleScriptRunner.number(from: await tell("get sound volume")) else {
            return nil
        }
        return level / 100
    }

    override func setVolume(_ value: Double) {
        let level = Int((min(max(value, 0), 1) * 100).rounded())
        fireIfRunning("set sound volume to \(level)")
    }
}
```

- [ ] **Passo 4: Registrar no catálogo**

Acrescentar em `PlayerCatalog.entries`:

```swift
            PlayerCatalogEntry(
                id: SpotifyPlayer.bundleID,
                displayName: "Spotify",
                kind: .app,
                installURL: URL(string: "https://www.spotify.com/download/mac/"),
                make: { SpotifyPlayer() }
            ),
```

- [ ] **Passo 5: Verificar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
```

- [ ] **Passo 6: Commit**

```bash
git add Sources/MacMediaWidget/Players/SpotifyPlayer.swift \
        Sources/MacMediaWidget/Players/PlayerCatalog.swift Sources/MacMediaWidget/SelfTests.swift
git commit -m "feat: adiciona Spotify com camada AppleScript"
```

---

### Tarefa 3: TIDAL, Deezer, navegador e o atalho do YouTube Music

**Arquivos:**
- Criar: `Sources/MacMediaWidget/Players/TidalPlayer.swift`
- Criar: `Sources/MacMediaWidget/Players/DeezerPlayer.swift`
- Criar: `Sources/MacMediaWidget/Players/BrowserPlayer.swift`
- Modificar: `Sources/MacMediaWidget/Players/PlayerCatalog.swift`
- Modificar: `Sources/MacMediaWidget/SelfTests.swift`

**Interfaces:**
- Consome: `MediaRemotePlayer`, `PlayerCatalogKind.shortcut`, `LaunchTarget.appElseURL`.
- Produz: `TidalPlayer.bundleID`, `DeezerPlayer.bundleID`, `BrowserPlayer(bundleIdentifier:displayName:)`,
  `PlayerCatalog.youTubeMusicID`.

- [ ] **Passo 1: Escrever o teste que falha**

```swift
    /// Electron não expõe AppleScript: estes três só têm o que o MediaRemote dá.
    private static func playersSemAppleScriptSóTêmTransporte() {
        expect(TidalPlayer().capabilities == .transport, "TIDAL só tem transporte")
        expect(DeezerPlayer().capabilities == .transport, "Deezer só tem transporte")
        expect(
            BrowserPlayer(bundleIdentifier: "com.google.Chrome", displayName: "Google Chrome")
                .capabilities == .transport,
            "navegador só tem transporte"
        )
    }

    /// O atalho existe no catálogo e fica fora de `appEntries` — ele não é sessão.
    private static func atalhoDoYouTubeMusicNãoÉSessão() {
        let atalho = PlayerCatalog.entry(for: PlayerCatalog.youTubeMusicID)
        expect(atalho != nil, "YouTube Music deveria estar no catálogo")
        expect(
            !PlayerCatalog.appEntries.contains { $0.id == PlayerCatalog.youTubeMusicID },
            "YouTube Music não pode identificar sessão"
        )
    }
```

Registrar as duas chamadas em `run()`.

- [ ] **Passo 2: Rodar e ver falhar**

```bash
swift build 2>&1 | tail -20
```

Esperado: `cannot find 'TidalPlayer' in scope`.

- [ ] **Passo 3: Implementar os três players**

`TidalPlayer.swift`:

```swift
import AppKit

/// `TIDAL.app` — Electron, sem dicionário AppleScript (`NSAppleScriptEnabled` ausente,
/// nenhum `.sdef`). Sobra o transporte pela sessão ativa.
///
/// Diferença prática em relação ao Amazon Music: o TIDAL **publica `elapsedTime` e
/// `duration`** no stream do MediaRemote, então a barra de progresso mostra posição
/// verdadeira mesmo sem AppleScript (ver Tarefa 4).
@MainActor
final class TidalPlayer: MediaRemotePlayer {
    nonisolated static let bundleID = "com.tidal.desktop"

    init() {
        super.init(bundleIdentifier: Self.bundleID, displayName: "TIDAL")
    }

    override var installURL: URL? { URL(string: "https://tidal.com/download") }
}
```

`DeezerPlayer.swift`:

```swift
import AppKit

/// `Deezer.app` — Electron, sem dicionário AppleScript. Só transporte, como o TIDAL.
@MainActor
final class DeezerPlayer: MediaRemotePlayer {
    nonisolated static let bundleID = "com.deezer.deezer-desktop"

    init() {
        super.init(bundleIdentifier: Self.bundleID, displayName: "Deezer")
    }

    override var installURL: URL? { URL(string: "https://www.deezer.com/desktop") }
}
```

`BrowserPlayer.swift`:

```swift
import AppKit

/// Navegador como fonte de reprodução.
///
/// Chrome e Safari têm AppleScript, mas **nenhuma capacidade de mídia** — o que existe
/// é `execute javascript`, que depende de uma opção do menu Desenvolvedor ligada à mão
/// e por isso não serve como recurso de produto (`docs/fase1-multiplayer.md` §2). Sobra
/// o MediaRemote.
///
/// Esta classe também é o alvo dos atalhos de serviços web: quem toca é o navegador,
/// então é ele quem aparece como fonte — o widget não tem como saber qual aba está
/// tocando (`DECISOES.md · 2026-08-19 · #01`).
@MainActor
final class BrowserPlayer: MediaRemotePlayer {
    /// Abre a URL do serviço quando o atalho é acionado sem app dedicado instalado.
    private let serviceURL: URL?

    init(bundleIdentifier: String, displayName: String, serviceURL: URL? = nil) {
        self.serviceURL = serviceURL
        super.init(bundleIdentifier: bundleIdentifier, displayName: displayName)
    }

    /// Um atalho web sem app instalado ainda tem para onde ir: a página do serviço.
    @discardableResult
    override func launch() -> Bool {
        if applicationURL != nil { return super.launch() }
        guard let serviceURL else { return super.launch() }
        NSWorkspace.shared.open(serviceURL)
        return true
    }
}
```

> `MediaRemotePlayer` não declara `launch()` — ele vem da extension de `Player`, que é
> despachada estaticamente. Para o `override` acima funcionar, acrescentar em
> `MediaRemotePlayer` (junto dos outros métodos que existem lá pelo mesmo motivo):
>
> ```swift
>     @discardableResult
>     func launch() -> Bool {
>         guard !DebugFlags.simulatesMissingApp, let url = applicationURL else {
>             NSLog("MacMediaWidget: \(displayName) não encontrado (\(bundleIdentifier))")
>             promptInstall()
>             return false
>         }
>         let config = NSWorkspace.OpenConfiguration()
>         config.activates = true
>         NSWorkspace.shared.openApplication(at: url, configuration: config)
>         return true
>     }
> ```

- [ ] **Passo 4: Registrar as entradas no catálogo**

Em `PlayerCatalog`, acrescentar a constante e as quatro entradas:

```swift
    /// Id sintético: o YouTube Music não tem bundle id próprio de sessão.
    static let youTubeMusicID = "service.youtube.music"

    /// Bundle id do PWA do YouTube Music instalado pelo Chrome. Serve só para abrir —
    /// a sessão de Now Playing sai como o navegador de qualquer forma.
    private static let youTubeMusicPWA = "com.google.Chrome.app.cinhimbnkkaeohfgghhklpknlkffjgod"
```

```swift
            PlayerCatalogEntry(
                id: TidalPlayer.bundleID,
                displayName: "TIDAL",
                kind: .app,
                installURL: URL(string: "https://tidal.com/download"),
                make: { TidalPlayer() }
            ),
            PlayerCatalogEntry(
                id: DeezerPlayer.bundleID,
                displayName: "Deezer",
                kind: .app,
                installURL: URL(string: "https://www.deezer.com/desktop"),
                make: { DeezerPlayer() }
            ),
            PlayerCatalogEntry(
                id: "com.google.Chrome",
                displayName: "Google Chrome",
                kind: .app,
                installURL: URL(string: "https://www.google.com/chrome/"),
                make: { BrowserPlayer(bundleIdentifier: "com.google.Chrome", displayName: "Google Chrome") }
            ),
            PlayerCatalogEntry(
                id: "com.apple.Safari",
                displayName: "Safari",
                kind: .app,
                installURL: nil,
                make: { BrowserPlayer(bundleIdentifier: "com.apple.Safari", displayName: "Safari") }
            ),
            PlayerCatalogEntry(
                id: youTubeMusicID,
                displayName: "YouTube Music",
                kind: .shortcut(.appElseURL(
                    bundleID: youTubeMusicPWA,
                    url: URL(string: "https://music.youtube.com")!
                )),
                installURL: nil,
                make: {
                    BrowserPlayer(
                        bundleIdentifier: youTubeMusicPWA,
                        displayName: "YouTube Music",
                        serviceURL: URL(string: "https://music.youtube.com")!
                    )
                }
            ),
```

- [ ] **Passo 5: Verificar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
```

- [ ] **Passo 6: Commit**

```bash
git add Sources/MacMediaWidget/Players/ Sources/MacMediaWidget/SelfTests.swift
git commit -m "feat: adiciona TIDAL, Deezer, navegador e atalho do YouTube Music"
```

---

### Tarefa 4: Ancorar a posição no `elapsedTime` do stream

Corrige a lacuna descrita em `docs/players-adicionais.md` §4.6: o parser lê
`elapsedTime`, o controller ignora, e TIDAL/Deezer/navegador ficam com posição estimada
tendo o valor verdadeiro em mãos.

**Arquivos:**
- Modificar: `Sources/MacMediaWidget/NowPlayingParser.swift:24` e `:73`
- Modificar: `Sources/MacMediaWidget/NowPlayingController.swift:326-356`
- Modificar: `Sources/MacMediaWidget/SelfTests.swift`

**Interfaces:**
- Produz: `NowPlayingParser.Outcome.update(TrackInfo, newTimestamp: Date?, newElapsed: Double?)`.
- **Quebra**: os testes existentes do parser fazem match em `.update` com dois
  associados. Todos passam a `case .update(let t, _, _)`.

- [ ] **Passo 1: Escrever o teste que falha**

```swift
    /// TIDAL, Deezer e navegador publicam a posição de graça no stream. Ignorá-la e
    /// estimar por timestamp é errar com o número certo na mão.
    private static func parserSinalizaElapsedTimeNovo() {
        let json = #"{"diff":true,"payload":{"elapsedTime":42.5}}"#
        let resultado = NowPlayingParser.parse(line(json), mergingInto: TrackInfo(), lastTimestamp: nil)
        guard case .update(_, _, let novo) = resultado else {
            expect(false, "linha com elapsedTime deveria virar update")
            return
        }
        expect(novo == 42.5, "elapsedTime da linha deveria ser sinalizado")
    }

    private static func parserSemElapsedTimeNãoSinaliza() {
        let json = #"{"diff":true,"payload":{"title":"Faixa"}}"#
        let resultado = NowPlayingParser.parse(line(json), mergingInto: TrackInfo(), lastTimestamp: nil)
        guard case .update(_, _, let novo) = resultado else {
            expect(false, "linha sem elapsedTime ainda é update")
            return
        }
        expect(novo == nil, "sem elapsedTime não se inventa posição")
    }
```

Registrar as duas em `run()`.

- [ ] **Passo 2: Rodar e ver falhar**

```bash
swift build 2>&1 | tail -20
```

Esperado: erro de aridade no `case .update` — o enum ainda tem dois associados.

- [ ] **Passo 3: Sinalizar no parser**

Em `NowPlayingParser.swift`, o caso do enum:

```swift
        /// Estado novo já mesclado sobre o anterior. `newTimestamp` só vem preenchido
        /// quando o payload trouxe um timestamp diferente do último visto — é o sinal
        /// de faixa nova. `newElapsed` vem preenchido quando **esta linha** trouxe
        /// `elapsedTime`: é posição verdadeira, publicada pela própria fonte, e vale
        /// mais que a estimativa local.
        case update(TrackInfo, newTimestamp: Date?, newElapsed: Double?)
```

Capturar o valor onde ele já é lido:

```swift
        var newElapsed: Double?
        if let v = payload["elapsedTime"] as? Double {
            t.elapsedTime = v
            t.timestamp = Date()
            newElapsed = v
        }
```

E o retorno:

```swift
        return .update(t, newTimestamp: newTimestamp, newElapsed: newElapsed)
```

- [ ] **Passo 4: Reancorar no controller**

Em `NowPlayingController.handleLine`, o `case` passa a receber três valores e ganha um
ramo. Ordem importa: faixa nova continua mandando, porque `timestamp` marca o início
dela.

```swift
        case .update(let t, let newTimestamp, let newElapsed):
            let now = Date()
            if let ts = newTimestamp {
                // ... bloco existente, sem mudança ...
            } else if let elapsed = newElapsed {
                // Posição verdadeira publicada pela fonte: adota como âncora em vez de
                // seguir estimando. É o que dá barra correta em TIDAL, Deezer e
                // navegador, que não têm AppleScript para o poll de `realPosition`.
                anchorElapsed = elapsed
                anchorWall = now
            } else if t.isPlaying != track.isPlaying {
                // ... bloco existente, sem mudança ...
            }
```

- [ ] **Passo 5: Corrigir os matches antigos**

```bash
grep -n "case .update" Sources/MacMediaWidget/SelfTests.swift
```

Cada ocorrência com dois associados vira três (`case .update(let t, _, _)`).

- [ ] **Passo 6: Verificar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
```

- [ ] **Passo 7: Commit**

```bash
git add Sources/MacMediaWidget/NowPlayingParser.swift \
        Sources/MacMediaWidget/NowPlayingController.swift Sources/MacMediaWidget/SelfTests.swift
git commit -m "fix: ancora a posição no elapsedTime publicado pela fonte"
```

---

### Tarefa 5: Visibilidade em `AppSettings` (sem UI)

**Arquivos:**
- Modificar: `Sources/MacMediaWidget/Settings.swift`
- Modificar: `Sources/MacMediaWidget/SelfTests.swift`

**Interfaces:**
- Produz: `AppSettings.hiddenPlayerIDs`, `.discoveredPlayerIDs`, `.isHidden(_:)`,
  `.canHide(_:)`, `.setHidden(_:for:)`, `.registerDiscovered(_:)`, `.forgetDiscovered()`.

- [x] **Passo 1: Escrever o teste que falha**

```swift
    /// O preferido nunca pode ser ocultado — senão o modo fixo apontaria para um app
    /// que o widget ignora, que é estado sem saída.
    private static func visibilidadeProtegeOPreferido() {
        let settings = AppSettings.shared
        let preferido = settings.preferredPlayerBundleId
        expect(!settings.canHide(preferido), "não se pode ocultar o player preferido")
        settings.setHidden(true, for: preferido)
        expect(!settings.isHidden(preferido), "ocultar o preferido não pode ter efeito")
    }

    /// Blocklist: o padrão é tudo visível, e app nunca visto não é filtrado.
    private static func visibilidadePadrãoÉTudoVisível() {
        expect(
            !AppSettings.shared.isHidden("com.exemplo.player.novo"),
            "app desconhecido nasce visível"
        )
    }
```

Registrar em `run()`.

- [x] **Passo 2: Rodar e ver falhar**

```bash
swift build 2>&1 | tail -20
```

Esperado: `value of type 'AppSettings' has no member 'canHide'`.

- [x] **Passo 3: Implementar**

Em `Settings.swift`, as chaves:

```swift
        static let hiddenPlayerIDs = "settings.hiddenPlayerIDs"
        static let discoveredPlayerIDs = "settings.discoveredPlayerIDs"
```

As propriedades (padrão vazio nos dois — ver `DECISOES.md · 2026-08-19 · #01`):

```swift
    /// Apps que o usuário desmarcou. **Guarda os ocultos, não os escolhidos**: o
    /// catálogo não é fechado, e com allowlist todo player novo nasceria filtrado —
    /// o widget ficaria mudo diante de uma fonte que hoje ele controla sem saber o que é.
    @Published var hiddenPlayerIDs: Set<String> {
        didSet { defaults.set(Array(hiddenPlayerIDs), forKey: Keys.hiddenPlayerIDs) }
    }

    /// Fontes que já apareceram no Now Playing e não estão no catálogo.
    @Published var discoveredPlayerIDs: [String] {
        didSet { defaults.set(discoveredPlayerIDs, forKey: Keys.discoveredPlayerIDs) }
    }
```

No `init`:

```swift
        hiddenPlayerIDs = Set(defaults.stringArray(forKey: Keys.hiddenPlayerIDs) ?? [])
        discoveredPlayerIDs = defaults.stringArray(forKey: Keys.discoveredPlayerIDs) ?? []
```

E as regras de coerência:

```swift
    func isHidden(_ id: String) -> Bool { hiddenPlayerIDs.contains(id) }

    /// O preferido é intocável, e o último visível também: sem isso, o usuário poderia
    /// esvaziar o menu inteiro e ficar sem caminho de volta pela própria UI.
    func canHide(_ id: String) -> Bool {
        guard id != preferredPlayerBundleId else { return false }
        let visíveis = PlayerCatalog.entries.map(\.id).filter { !isHidden($0) }
        return visíveis.count > 1
    }

    func setHidden(_ hidden: Bool, for id: String) {
        if hidden {
            guard canHide(id) else { return }
            hiddenPlayerIDs.insert(id)
        } else {
            hiddenPlayerIDs.remove(id)
        }
    }

    /// Registra uma fonte vista no stream que não está no catálogo.
    func registerDiscovered(_ id: String) {
        guard PlayerCatalog.entry(for: id) == nil, !discoveredPlayerIDs.contains(id) else { return }
        discoveredPlayerIDs.append(id)
    }

    func forgetDiscovered() {
        hiddenPlayerIDs.subtract(discoveredPlayerIDs)
        discoveredPlayerIDs = []
    }
```

> `canHide` consulta `PlayerCatalog`, que é `@MainActor` — `AppSettings` também é, então
> não há salto de isolamento. Se o compilador reclamar do acesso a `PlayerCatalog`
> dentro do `init`, é sinal de que a chamada foi parar no lugar errado: as regras são
> métodos, nunca rodam na inicialização.

- [x] **Passo 4: Registrar descobertos no controller**

Em `NowPlayingController.handleLine`, dentro do `case .update`, depois de `track = t`:

```swift
            if let id = t.bundleIdentifier { AppSettings.shared.registerDiscovered(id) }
```

- [x] **Passo 5: Verificar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
```

- [x] **Passo 6: Commit**

```bash
git add Sources/MacMediaWidget/Settings.swift Sources/MacMediaWidget/NowPlayingController.swift \
        Sources/MacMediaWidget/SelfTests.swift
git commit -m "feat: preferência de visibilidade por app, como lista de ocultos"
```

---

### Tarefa 6: Filtrar as listas de escolha

**Arquivos:**
- Modificar: `Sources/MacMediaWidget/Players/PlayerRegistry.swift`
- Modificar: `Sources/MacMediaWidget/AppMenuController.swift:188-211`
- Modificar: `Sources/MacMediaWidget/SelfTests.swift`

**Interfaces:**
- Consome: `AppSettings.isHidden(_:)`, `PlayerCatalog.entries`.
- Produz: `PlayerRegistry.selectablePlayers()` — entradas visíveis, apps e atalhos,
  ordenadas por nome.

- [x] **Passo 1: Escrever o teste que falha**

```swift
    private static func listaDeEscolhaOmiteOcultos() {
        let settings = AppSettings.shared
        let alvo = TidalPlayer.bundleID
        let antes = settings.isHidden(alvo)
        settings.setHidden(true, for: alvo)
        let ids = PlayerRegistry.shared.selectablePlayers().map(\.bundleIdentifier)
        expect(!ids.contains(alvo), "app oculto não aparece na lista de escolha")
        settings.setHidden(antes, for: alvo)
    }
```

- [x] **Passo 2: Rodar e ver falhar**

Esperado: `has no member 'selectablePlayers'`.

- [x] **Passo 3: Implementar no registry**

```swift
    /// Entradas do catálogo que o usuário pode escolher agora: visíveis, instaladas,
    /// incluindo os atalhos (que não identificam sessão mas são lançáveis).
    func selectablePlayers() -> [Player] {
        PlayerCatalog.entries
            .filter { !AppSettings.shared.isHidden($0.id) }
            .compactMap { player(for: $0.id) }
            .filter(\.isInstalled)
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
```

> O atalho do YouTube Music tem `bundleIdentifier` do PWA, que pode não estar
> instalado — e aí `isInstalled` o derrubaria. Tratar: o filtro de instalação vale só
> para `kind == .app`; atalho sempre passa, porque tem a URL como destino garantido.

- [x] **Passo 4: Usar no menu**

Em `AppMenuController.switchAppItem()`, trocar `installedKnownPlayers()` por
`selectablePlayers()`. O resto do método fica igual.

- [x] **Passo 5: Verificar e commitar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
git add Sources/MacMediaWidget/Players/PlayerRegistry.swift \
        Sources/MacMediaWidget/AppMenuController.swift Sources/MacMediaWidget/SelfTests.swift
git commit -m "feat: submenu Trocar app respeita os apps ocultos"
```

---

### Tarefa 7: Filtro de exibição sem virar card vazio

**Arquivos:**
- Modificar: `Sources/MacMediaWidget/NowPlayingController.swift:121-146`
- Modificar: `Sources/MacMediaWidget/ContentView.swift`
- Modificar: `Sources/MacMediaWidget/MenuStatusView.swift`
- Modificar: `Sources/MacMediaWidget/L10n.swift`
- Modificar: `Sources/MacMediaWidget/SelfTests.swift`

**Interfaces:**
- Produz: `NowPlayingController.hiddenSourceName`, `L10n.sourceHidden(_:)`.

- [x] **Passo 1: Escrever o teste que falha**

```swift
    /// Card em branco com música tocando é indistinguível de app quebrado — o widget
    /// tem que dizer que está ocultando de propósito.
    private static func fonteOcultaTemNomeParaExibir() {
        expect(
            L10n.sourceHidden("Spotify").contains("Spotify"),
            "o aviso de fonte oculta precisa nomear o app"
        )
    }
```

- [x] **Passo 2: Rodar e ver falhar**

Esperado: `type 'L10n' has no member 'sourceHidden'`.

- [x] **Passo 3: String nova**

Em `L10n.swift`, na seção "Transporte indisponível":

```swift
    static func sourceHidden(_ name: String) -> String {
        String(localized: "\(name) is playing · hidden")
    }
    static var showThisApp: String { String(localized: "Show this app") }
```

Em `Resources/pt-BR.lproj/Localizable.strings`:

```
"%@ is playing · hidden" = "O %@ está tocando · oculto";
"Show this app" = "Mostrar este app";
```

- [x] **Passo 4: Filtrar no controller**

```swift
    /// A sessão atual é de um app que o usuário mandou ocultar?
    var isActiveSourceHidden: Bool {
        guard let id = track.bundleIdentifier else { return false }
        return AppSettings.shared.isHidden(id)
    }

    /// Nome do app oculto que está tocando, para a UI explicar o silêncio em vez de
    /// parecer quebrada.
    var hiddenSourceName: String? {
        guard isActiveSourceHidden, let id = track.bundleIdentifier else { return nil }
        return PlayerRegistry.shared.player(for: id)?.displayName
    }
```

Em `displayedTrack`, antes do `return track`:

```swift
        if isActiveSourceHidden { return TrackInfo() }
```

Em `canControlTransport`, na primeira linha:

```swift
        if isActiveSourceHidden { return false }
```

- [x] **Passo 5: Mostrar na UI**

Em `ContentView`, onde hoje se decide entre faixa e `L10n.nothingPlaying`, dar
precedência ao aviso:

```swift
            if let oculto = nowPlaying.hiddenSourceName {
                Text(L10n.sourceHidden(oculto))
                Button(L10n.showThisApp) {
                    if let id = nowPlaying.track.bundleIdentifier {
                        AppSettings.shared.setHidden(false, for: id)
                    }
                }
                .nonDraggableWindowArea()
            }
```

Mesmo tratamento em `MenuStatusView` (lá sem botão — o menu já leva às Preferências).

- [x] **Passo 6: Verificar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
scripts/verificar-traducoes.sh
```

- [x] **Passo 7: Commit**

```bash
git add Sources/MacMediaWidget/ Resources/pt-BR.lproj/Localizable.strings
git commit -m "feat: widget avisa quando a fonte que toca está oculta"
```

---

### Tarefa 8: Seção "Apps controlados" nas Preferências

**Arquivos:**
- Modificar: `Sources/MacMediaWidget/PreferencesWindow.swift:43` e `:74-141`
- Modificar: `Sources/MacMediaWidget/L10n.swift`
- Modificar: `Resources/pt-BR.lproj/Localizable.strings`

- [x] **Passo 1: Strings novas**

```swift
    static var sectionControlledApps: String { String(localized: "Controlled apps") }
    static var controlledAppsHelp: String {
        String(localized: "Unchecked apps disappear from the “Switch app” menu, and the widget ignores what they play.")
    }
    static var preferredCannotBeHidden: String {
        String(localized: "The preferred player is always shown")
    }
    static var notInstalled: String { String(localized: "not installed") }
    static var opensInBrowser: String { String(localized: "opens in the browser") }
    static var forgetDiscovered: String { String(localized: "Forget discovered apps") }
```

Traduções correspondentes no `.strings`.

- [x] **Passo 2: Lista deixa de ser fixa**

Hoje `PreferencesWindow.swift:43` guarda `let players = ...`, com o comentário de que
instalar app com a janela aberta é raro demais para valer um observador. Isso deixa de
valer: os checkboxes mudam a lista ao vivo. Trocar por propriedade calculada:

```swift
    /// Catálogo inteiro, inclusive o que não está instalado — a lista é também a
    /// vitrine do que o widget suporta. Calculada, não fixada: os checkboxes desta
    /// mesma tela alteram o que aparece no menu.
    private var catalogEntries: [PlayerCatalogEntry] {
        PlayerCatalog.entries.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }
```

O `Picker` de player preferido passa a usar `PlayerRegistry.shared.selectablePlayers()`.

- [x] **Passo 3: A seção**

```swift
            Section(L10n.sectionControlledApps) {
                ForEach(catalogEntries, id: \.id) { entry in
                    Toggle(isOn: Binding(
                        get: { !settings.isHidden(entry.id) },
                        set: { settings.setHidden(!$0, for: entry.id) }
                    )) {
                        HStack(spacing: 8) {
                            if let icon = PlayerRegistry.shared.player(for: entry.id)?.icon {
                                Image(nsImage: icon).resizable().frame(width: 16, height: 16)
                            }
                            Text(entry.displayName)
                            if let nota = note(for: entry) {
                                Text("· \(nota)").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(!settings.canHide(entry.id) && !settings.isHidden(entry.id))
                }

                if !settings.discoveredPlayerIDs.isEmpty {
                    Button(L10n.forgetDiscovered) { settings.forgetDiscovered() }
                }

                Text(L10n.controlledAppsHelp)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
```

Com o rótulo auxiliar:

```swift
    /// Nota curta ao lado do nome: por que o app está esmaecido, ou o que ele é.
    private func note(for entry: PlayerCatalogEntry) -> String? {
        if entry.id == settings.preferredPlayerBundleId { return L10n.preferredCannotBeHidden }
        if case .shortcut = entry.kind { return L10n.opensInBrowser }
        if PlayerRegistry.shared.player(for: entry.id)?.isInstalled == false { return L10n.notInstalled }
        return nil
    }
```

- [x] **Passo 4: Descobertos na lista**

Abaixo do `ForEach` do catálogo, um segundo `ForEach` sobre
`settings.discoveredPlayerIDs`, com o mesmo `Toggle` e o nome vindo de
`Player.localizedName(forBundleIdentifier:) ?? id`.

- [x] **Passo 5: Verificar**

```bash
swift build 2>&1 | tail -20 && swift run MacMediaWidget --run-tests
scripts/verificar-traducoes.sh
```

- [x] **Passo 6: Commit**

```bash
git add Sources/MacMediaWidget/PreferencesWindow.swift Sources/MacMediaWidget/L10n.swift \
        Resources/pt-BR.lproj/Localizable.strings
git commit -m "feat: seção Apps controlados nas preferências"
```

---

### Tarefa 9: Fechamento — bundle, teste manual e documentação

- [ ] **Passo 1: Montar o `.app` e instalar**

```bash
scripts/build-app.sh 2>&1 | tail -20
```

O `fechar-sessao.sh` roda `swift build`, **não** monta o bundle. Testar o `.app` é
manual e é aqui.

- [ ] **Passo 2: Roteiro manual**

Com o `.app` rodando:

1. Trocar app pelo menu para cada player visível — abre o app certo?
2. Desmarcar um app nas Preferências → sumiu do submenu e do seletor de preferido?
3. Pôr esse app para tocar → o card mostra "… está tocando · oculto" com o botão, e o
   botão o traz de volta?
4. O preferido tem o checkbox travado com a nota?
5. YouTube Music no menu abre o PWA (ou a página, se o PWA continuar quebrado)?
6. Barra de progresso no TIDAL e no Deezer acompanha a música (Tarefa 4)?
7. Seek arrastando a barra no Spotify move a faixa de verdade?

- [ ] **Passo 3: Atualizar a documentação**

- `docs/compatibilidade-players.md`: já preenchido na Tarefa 0 — conferir que bate com
  as capacidades declaradas no código.
- `README.md`: lista de players suportados.
- `CHANGELOG.md`: entrada `1.16.0` com data e identificador da sessão.
- `PENDENCIAS.md`: baixar a pendência "Fase 1 — fechar o critério de saída do ROADMAP".

- [ ] **Passo 4: Commit**

```bash
git add -A
git commit -m "docs: registra players adicionais e visibilidade por app"
```

---

## Auto-revisão do plano

**Cobertura do desenho:** §4.1 → Tarefa 1; §4.2 → Tarefa 5; §4.3 → Tarefa 5 (passos 3–4)
e Tarefa 8 (passo 4); §4.4 → Tarefa 5 (`canHide`); §4.5 → Tarefa 7; §4.6 → Tarefa 4;
§4.7 → Tarefa 8; §7 → Tarefa 0. Sem lacuna.

**Consistência de nomes:** `installedCatalogPlayers()` (Tarefa 1) e `selectablePlayers()`
(Tarefa 6) são funções distintas de propósito — a primeira é o rename de
`installedKnownPlayers()` e sobrevive por compatibilidade das chamadas existentes; a
segunda é a lista filtrada. **Ao terminar a Tarefa 6, `installedCatalogPlayers()` fica
sem uso** e deve ser removida no mesmo commit.

**Riscos que o plano não elimina:** a Tarefa 2 declara capacidades que só a Tarefa 0
confirma — se o teste do Spotify contrariar o `.sdef`, o passo 3 muda antes de ser
escrito. E a Tarefa 4 depende de `elapsedTime` avançar de verdade no TIDAL; se não
avançar, a tarefa continua correta (o campo é opcional) mas perde o motivo.
