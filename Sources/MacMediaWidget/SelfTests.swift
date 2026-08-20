#if DEBUG
import AppKit

// Suíte de testes do que é verificável sem UI nem subprocesso.
//
// Por que não é um `testTarget` com swift-testing ou XCTest: **as Command Line Tools não
// trazem nenhum dos dois frameworks** — eles vêm só com o Xcode completo, que este
// projeto não usa (ver CLAUDE.md, "Build"). Um `swift test` aqui falha em
// `no such module 'Testing'` antes de compilar a primeira linha.
//
// A saída foi rodar as asserções de dentro do próprio binário, atrás de `--run-tests` e
// de `#if DEBUG` — o que também dá acesso ao escopo interno sem tornar meia API pública
// só para poder testá-la. Roda com:
//
//     swift run MacMediaWidget --run-tests
//
// Migrar para swift-testing quando (e se) o Xcode entrar no projeto está em PENDENCIAS.md.

@MainActor
enum SelfTests {
    private static var falhas: [String] = []
    private static var total = 0

    /// Roda tudo e devolve o código de saída (0 = passou).
    static func run() -> Int32 {
        falhas = []
        total = 0

        parserSnapshotVazioReseta()
        parserSnapshotComFaixaAtualiza()
        parserDiffPreservaCamposAusentes()
        parserTimestampSóContaQuandoMuda()
        parserLixoÉIgnorado()
        parserSemElapsedTimeNãoInventa()

        gradeSnapAlinhaNaCélulaMaisPróxima()
        gradeSnapAceitaValoresNegativos()
        gradeGeometria()

        telaPosiçãoVisível()
        telaPosiçãoForaDeTudo()
        telaSegundoMonitor()

        playerAmazonMusicÉLimitado()
        playerAppleMusicÉCompleto()
        playerSpotifyTemCamadaAppleScript()
        playersSemAppleScriptTêmSóOMedido()
        atalhoDoYouTubeMusicNãoÉSessão()
        playerFonteDesconhecidaÉGenérica()
        playerSemSessãoNãoHáPlayer()
        playerRegistryMantémInstância()
        catálogoTemAsEntradasConhecidas()
        catálogoSeparaAppDeAtalho()
        visibilidadeProtegeOPreferido()
        visibilidadePadrãoÉTudoVisível()
        listaDeEscolhaOmiteOcultos()
        fonteOcultaTemNomeParaExibir()

        appleScriptDecimalComVírgula()
        appleScriptEntradaInválida()

        saúdeDoAdapter()

        if falhas.isEmpty {
            print("✓ \(total) verificações passaram")
            return 0
        }
        print("✗ \(falhas.count) de \(total) verificações falharam:")
        for falha in falhas { print("  - \(falha)") }
        return 1
    }

    // MARK: - Mini-harness

    private static func expect(
        _ condition: Bool,
        _ descricao: String,
        função: StaticString = #function
    ) {
        total += 1
        if !condition { falhas.append("\(função): \(descricao)") }
    }

    private static func line(_ json: String) -> Data { Data(json.utf8) }

    // MARK: - Parser do stream

    /// O bug de `DECISOES.md · 2026-08-05 · #01`: tratar o snapshot vazio como diff
    /// deixava o `bundleIdentifier` antigo grudado, e o play virava um comando global
    /// que o macOS entregava ao app errado.
    private static func parserSnapshotVazioReseta() {
        var atual = TrackInfo()
        atual.bundleIdentifier = "com.amazon.music"
        atual.title = "faixa antiga"

        let outcome = NowPlayingParser.parse(
            line(#"{"type":"data","diff":false,"payload":{}}"#),
            mergingInto: atual,
            lastTimestamp: nil
        )
        expect(outcome == .reset, "snapshot vazio deveria resetar, veio \(outcome)")
    }

    private static func parserSnapshotComFaixaAtualiza() {
        let outcome = NowPlayingParser.parse(
            line(#"{"diff":false,"payload":{"bundleIdentifier":"com.apple.Music","title":"Brisa"}}"#),
            mergingInto: TrackInfo(),
            lastTimestamp: nil
        )
        guard case .update(let track, _) = outcome else {
            expect(false, "esperava update, veio \(outcome)")
            return
        }
        expect(track.title == "Brisa", "título deveria ser Brisa")
        expect(track.bundleIdentifier == "com.apple.Music", "bundle id deveria ser o do Apple Music")
    }

    /// O stream manda só o que mudou. Perder o resto esvaziaria o card a cada pausa.
    private static func parserDiffPreservaCamposAusentes() {
        var atual = TrackInfo()
        atual.bundleIdentifier = "com.amazon.music"
        atual.title = "Overkill"
        atual.artist = "Men At Work"
        atual.duration = 230
        atual.isPlaying = true

        let outcome = NowPlayingParser.parse(
            line(#"{"diff":true,"payload":{"playing":false}}"#),
            mergingInto: atual,
            lastTimestamp: nil
        )
        guard case .update(let track, let ts) = outcome else {
            expect(false, "esperava update, veio \(outcome)")
            return
        }
        expect(track.isPlaying == false, "playing deveria virar false")
        expect(track.title == "Overkill", "título deveria sobreviver ao diff")
        expect(track.artist == "Men At Work", "artista deveria sobreviver ao diff")
        expect(track.duration == 230, "duração deveria sobreviver ao diff")
        expect(ts == nil, "sem timestamp no payload, não há timestamp novo")
    }

    private static func parserTimestampSóContaQuandoMuda() {
        let iso = "2026-08-10T21:39:55Z"
        let esperado = ISO8601DateFormatter().date(from: iso)

        let novo = NowPlayingParser.parse(
            line(#"{"diff":true,"payload":{"timestamp":"\#(iso)"}}"#),
            mergingInto: TrackInfo(),
            lastTimestamp: nil
        )
        if case .update(_, let ts) = novo {
            expect(ts == esperado, "timestamp inédito deveria ser sinalizado")
        } else {
            expect(false, "esperava update para timestamp inédito")
        }

        // Repetido não é faixa nova: reancorar aqui faria a barra saltar para trás a
        // cada atualização do stream.
        let repetido = NowPlayingParser.parse(
            line(#"{"diff":true,"payload":{"timestamp":"\#(iso)"}}"#),
            mergingInto: TrackInfo(),
            lastTimestamp: esperado
        )
        if case .update(_, let ts) = repetido {
            expect(ts == nil, "timestamp repetido não deveria ser sinalizado")
        } else {
            expect(false, "esperava update para timestamp repetido")
        }
    }

    private static func parserLixoÉIgnorado() {
        expect(
            NowPlayingParser.parse(line("não é json"), mergingInto: TrackInfo(), lastTimestamp: nil) == .ignored,
            "texto solto deveria ser ignorado"
        )
        expect(
            NowPlayingParser.parse(line("null"), mergingInto: TrackInfo(), lastTimestamp: nil) == .ignored,
            "null deveria ser ignorado"
        )
        expect(
            NowPlayingParser.parse(line("{}"), mergingInto: TrackInfo(), lastTimestamp: nil) == .ignored,
            "objeto sem payload deveria ser ignorado"
        )
    }

    /// O Amazon Music nunca publica `elapsedTime`. Se o parser preenchesse com zero, a
    /// barra mostraria a faixa reiniciando a cada diff.
    private static func parserSemElapsedTimeNãoInventa() {
        let outcome = NowPlayingParser.parse(
            line(#"{"diff":true,"payload":{"title":"x","duration":180}}"#),
            mergingInto: TrackInfo(),
            lastTimestamp: nil
        )
        guard case .update(let track, _) = outcome else {
            expect(false, "esperava update")
            return
        }
        expect(track.elapsedTime == nil, "elapsedTime ausente não deveria virar zero")
    }

    // MARK: - Grade de snap

    private static func gradeSnapAlinhaNaCélulaMaisPróxima() {
        let origem: CGFloat = 100
        expect(NativeWidgetGrid.snap(100, to: origem) == 100, "valor na âncora não se move")
        expect(NativeWidgetGrid.snap(140, to: origem) == 100, "menos de meia célula arredonda para trás")
        expect(NativeWidgetGrid.snap(191, to: origem) == 280, "mais de meia célula arredonda para a frente")
        expect(NativeWidgetGrid.snap(280, to: origem) == 280, "valor exato na malha não se move")
    }

    /// A âncora é uma célula qualquer, não a origem da tela: arrastar o widget para a
    /// esquerda dela produz deslocamentos negativos, que precisam alinhar igual.
    private static func gradeSnapAceitaValoresNegativos() {
        expect(NativeWidgetGrid.snap(-80, to: 100) == -80, "célula à esquerda da âncora")
        expect(NativeWidgetGrid.snap(-70, to: 100) == -80, "arredonda para a célula à esquerda")
        expect(NativeWidgetGrid.snap(20, to: 100) == 100, "arredonda de volta para a âncora")
    }

    /// Se a geometria mudar, o snap sai do lugar sem aviso. O teste existe para que a
    /// mudança seja deliberada, e não efeito colateral.
    private static func gradeGeometria() {
        expect(NativeWidgetGrid.pitch == 180, "célula medida em 2026-08-09 é 180pt")
        expect(NativeWidgetGrid.cardInset == 5, "inset medido em 2026-08-09 é 5pt")
    }

    // MARK: - Posição entre telas

    private static let telaPrincipal = NSRect(x: 0, y: 0, width: 1512, height: 982)
    private static let cardSize = NSSize(width: 386, height: 206)

    private static func telaPosiçãoVisível() {
        expect(
            WidgetWindow.isOnSomeScreen(
                origin: NSPoint(x: 1100, y: 700), size: cardSize, screenFrames: [telaPrincipal]
            ),
            "posição dentro da tela deveria ser considerada visível"
        )
    }

    /// O caso que motivou a checagem: monitor externo desconectado com o widget nele.
    /// A posição salva continua válida como número e aponta para lugar nenhum.
    private static func telaPosiçãoForaDeTudo() {
        expect(
            !WidgetWindow.isOnSomeScreen(
                origin: NSPoint(x: 3000, y: 400), size: cardSize, screenFrames: [telaPrincipal]
            ),
            "posição em monitor que não existe mais não é visível"
        )
        // Meio card para fora à direita: menos da metade aparece, não conta.
        expect(
            !WidgetWindow.isOnSomeScreen(
                origin: NSPoint(x: 1400, y: 400), size: cardSize, screenFrames: [telaPrincipal]
            ),
            "card quase todo fora da borda não conta como visível"
        )
    }

    private static func telaSegundoMonitor() {
        let secundária = NSRect(x: 1512, y: 0, width: 1920, height: 1080)
        expect(
            WidgetWindow.isOnSomeScreen(
                origin: NSPoint(x: 2000, y: 500), size: cardSize,
                screenFrames: [telaPrincipal, secundária]
            ),
            "posição no monitor secundário é visível quando ele está conectado"
        )
        expect(
            !WidgetWindow.isOnSomeScreen(
                origin: NSPoint(x: 2000, y: 500), size: cardSize, screenFrames: [telaPrincipal]
            ),
            "a mesma posição deixa de ser visível sem o monitor secundário"
        )
    }

    // MARK: - Players

    private static func playerAmazonMusicÉLimitado() {
        let player = AmazonMusicPlayer()
        expect(player.capabilities == .fullTransport, "Amazon Music só tem transporte")
        expect(!player.capabilities.contains(.seek), "Amazon Music não tem seek")
        expect(!player.capabilities.contains(.appVolume), "Amazon Music não tem volume por-app")
        expect(!player.capabilities.contains(.directedControl), "Amazon Music não é endereçável")
    }

    private static func playerAppleMusicÉCompleto() {
        let player = AppleMusicPlayer()
        for capacidade in [
            PlayerCapabilities.transport, .seek, .realPosition, .appVolume,
            .shuffleRepeat, .directedControl,
        ] {
            expect(player.capabilities.contains(capacidade), "Apple Music deveria ter \(capacidade)")
        }
    }

    /// O Spotify é o segundo app da lista com dicionário AppleScript — e por isso o
    /// segundo endereçável. Tudo aqui foi medido contra o app real em
    /// `docs/compatibilidade-players.md`, inclusive o seek pelos dois caminhos.
    private static func playerSpotifyTemCamadaAppleScript() {
        let player = SpotifyPlayer()
        expect(player.bundleIdentifier == "com.spotify.client", "bundle id do Spotify")
        expect(player.capabilities.contains(.directedControl), "Spotify é endereçável por AppleScript")
        expect(player.capabilities.contains(.transport), "Spotify tem transporte")
        for capacidade in [
            PlayerCapabilities.seek, .realPosition, .appVolume, .shuffleRepeat,
        ] {
            expect(player.capabilities.contains(capacidade), "Spotify deveria ter \(capacidade)")
        }
    }

    /// Electron e navegador não expõem AppleScript de mídia: sobra o que o MediaRemote
    /// dá — e nem isso vem inteiro. Cada linha aqui corresponde a uma medição de
    /// `docs/compatibilidade-players.md`, inclusive as ausências.
    private static func playersSemAppleScriptTêmSóOMedido() {
        let tidal = TidalPlayer()
        expect(tidal.capabilities == [.fullTransport, .seek], "TIDAL: transporte inteiro e seek")
        expect(!tidal.capabilities.contains(.directedControl), "TIDAL não é endereçável")

        let deezer = DeezerPlayer()
        expect(deezer.capabilities.contains(.nextTrack), "Deezer pula para a próxima")
        expect(!deezer.capabilities.contains(.previousTrack), "Deezer ignora o previous")
        expect(!deezer.capabilities.contains(.seek), "Deezer ignora o seek, como o Amazon Music")

        let navegador = BrowserPlayer(
            bundleIdentifier: PlayerCatalog.chromeID, displayName: "Google Chrome"
        )
        expect(navegador.capabilities.contains(.seek), "navegador aceita seek")
        expect(!navegador.capabilities.contains(.nextTrack), "nextTrack não faz nada no navegador")
        expect(
            !navegador.capabilities.contains(.previousTrack),
            "previousTrack rebobina em vez de trocar de mídia"
        )
    }

    /// O atalho existe no catálogo, é escolhível pelo id sintético e fica fora de
    /// `appEntries` — ele não é sessão de Now Playing, quem toca é o navegador.
    private static func atalhoDoYouTubeMusicNãoÉSessão() {
        let atalho = PlayerCatalog.entry(for: PlayerCatalog.youTubeMusicID)
        expect(atalho != nil, "YouTube Music deveria estar no catálogo")
        expect(
            !PlayerCatalog.appEntries.contains { $0.id == PlayerCatalog.youTubeMusicID },
            "YouTube Music não pode identificar sessão"
        )
        // O `bundleIdentifier` é o do PWA (de onde saem ícone e abertura); a chave de
        // escolha e de visibilidade é o id do catálogo. Trocar um pelo outro deixa a
        // preferência apontando para fora do catálogo.
        let player = PlayerRegistry.shared.player(for: PlayerCatalog.youTubeMusicID)
        expect(player?.catalogID == PlayerCatalog.youTubeMusicID, "atalho se identifica pelo id do catálogo")
        expect(
            player?.bundleIdentifier != PlayerCatalog.youTubeMusicID,
            "o bundle id do atalho é o do app que abre, não o id sintético"
        )
    }

    private static func playerFonteDesconhecidaÉGenérica() {
        let player = PlayerRegistry.shared.player(for: "com.exemplo.player.inexistente")
        expect(player != nil, "fonte desconhecida deveria ter player genérico")
        expect(player?.capabilities == .fullTransport, "player genérico só faz transporte")
    }

    private static func playerSemSessãoNãoHáPlayer() {
        expect(PlayerRegistry.shared.player(for: nil) == nil, "sem bundle id não há player")
        expect(PlayerRegistry.shared.player(for: "") == nil, "bundle id vazio não vira player")
    }

    /// Players guardam estado — a capacidade rebaixada por automação negada, por
    /// exemplo. Recriar a cada consulta apagaria isso a cada render da UI.
    private static func playerRegistryMantémInstância() {
        let a = PlayerRegistry.shared.player(for: AppleMusicPlayer.bundleID)
        let b = PlayerRegistry.shared.player(for: AppleMusicPlayer.bundleID)
        expect(a === b, "registry deveria reaproveitar a instância")
    }

    private static func catálogoTemAsEntradasConhecidas() {
        let ids = PlayerCatalog.entries.map(\.id)
        expect(ids.contains(AmazonMusicPlayer.bundleID), "catálogo deveria ter Amazon Music")
        expect(ids.contains(AppleMusicPlayer.bundleID), "catálogo deveria ter Apple Music")
        expect(ids.contains(SpotifyPlayer.bundleID), "catálogo deveria ter Spotify")
        expect(ids.contains(TidalPlayer.bundleID), "catálogo deveria ter TIDAL")
        expect(ids.contains(DeezerPlayer.bundleID), "catálogo deveria ter Deezer")
        expect(ids.contains(PlayerCatalog.chromeID), "catálogo deveria ter o Chrome")
        expect(ids.contains(PlayerCatalog.youTubeMusicID), "catálogo deveria ter YouTube Music")
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

    // MARK: - Visibilidade por app

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

    /// O plano previa este teste com o TIDAL; até a Tarefa 3 existir, o Apple Music faz
    /// o papel — não é o preferido, então é ocultável.
    private static func listaDeEscolhaOmiteOcultos() {
        let settings = AppSettings.shared
        let alvo = AppleMusicPlayer.bundleID
        let antes = settings.isHidden(alvo)
        settings.setHidden(true, for: alvo)
        let ids = PlayerRegistry.shared.selectablePlayers().map(\.catalogID)
        expect(!ids.contains(alvo), "app oculto não aparece na lista de escolha")
        settings.setHidden(antes, for: alvo)
    }

    /// Card em branco com música tocando é indistinguível de app quebrado — o widget
    /// tem que dizer que está ocultando de propósito.
    private static func fonteOcultaTemNomeParaExibir() {
        expect(
            L10n.sourceHidden("Spotify").contains("Spotify"),
            "o aviso de fonte oculta precisa nomear o app"
        )
    }

    // MARK: - AppleScript

    /// Esta é a diferença entre "o Apple Music tem posição" e "não tem" numa máquina em
    /// português: `Double("12,5")` é nil.
    private static func appleScriptDecimalComVírgula() {
        expect(AppleScriptRunner.number(from: "12,5") == 12.5, "decimal com vírgula (pt-BR)")
        expect(AppleScriptRunner.number(from: "12.5") == 12.5, "decimal com ponto")
        expect(AppleScriptRunner.number(from: "100") == 100, "inteiro")
    }

    private static func appleScriptEntradaInválida() {
        expect(AppleScriptRunner.number(from: nil) == nil, "nil vira nil")
        expect(AppleScriptRunner.number(from: "") == nil, "vazio vira nil")
        expect(AppleScriptRunner.number(from: "erro de execução") == nil, "texto vira nil")
    }

    // MARK: - Saúde do adapter

    private static func saúdeDoAdapter() {
        expect(AdapterHealth.starting.isHealthy, "starting conta como são")
        expect(AdapterHealth.healthy.isHealthy, "healthy conta como são")
        expect(!AdapterHealth.reconnecting(attempt: 1).isHealthy, "reconnecting não é são")
        expect(!AdapterHealth.unavailable("x").isHealthy, "unavailable não é são")
    }
}
#endif
