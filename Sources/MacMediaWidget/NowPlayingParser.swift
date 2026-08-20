import AppKit

/// Interpreta as linhas JSON do stream do `mediaremote-adapter`.
///
/// Está separado do `NowPlayingController` por dois motivos: é a única parte da leitura
/// que dá para testar sem UI nem subprocesso, e é onde mora a sutileza que já causou bug
/// em produção — o campo `diff` (ver `.reset`).
/// `@MainActor` por causa do `ISO8601DateFormatter` reaproveitado: ele não é `Sendable`,
/// e o parsing só acontece na main thread mesmo (o handler do stream já salta para lá).
/// A alternativa seria criar um formatter por linha, que é desperdício.
@MainActor
enum NowPlayingParser {
    enum Outcome: Equatable {
        /// Snapshot completo sem faixa alguma: não há mais sessão de Now Playing porque
        /// o app de música foi encerrado. **Precisa zerar o estado.** Tratar isso como
        /// um diff (o que o código fazia por ignorar o campo `diff`) deixava o
        /// `bundleIdentifier` antigo grudado, e o play virava um `togglePlayPause`
        /// global que o macOS entregava ao Music.app da Apple — abrindo o app errado.
        /// Ver `DECISOES.md · 2026-08-05 · #01`.
        case reset
        /// Estado novo já mesclado sobre o anterior. `newTimestamp` só vem preenchido
        /// quando o payload trouxe um timestamp diferente do último visto — é o sinal
        /// de faixa nova. `newElapsed` vem preenchido quando **esta linha** trouxe
        /// `elapsedTime`: é posição publicada pela própria fonte, e onde ela é confiável
        /// vale mais do que qualquer estimativa local.
        case update(TrackInfo, newTimestamp: Date?, newElapsed: Double?)
        /// Linha inválida ou irrelevante.
        case ignored
    }

    private static let isoFormatter = ISO8601DateFormatter()

    static func parse(
        _ data: Data,
        mergingInto current: TrackInfo,
        lastTimestamp: Date?
    ) -> Outcome {
        guard
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let payload = obj["payload"] as? [String: Any]
        else { return .ignored }

        let isSnapshot = (obj["diff"] as? Bool) == false
        if isSnapshot, payload["bundleIdentifier"] == nil, payload["title"] == nil {
            return .reset
        }

        // Fora do snapshot, o stream manda só os campos que mudaram.
        var t = current

        if let v = payload["bundleIdentifier"] as? String { t.bundleIdentifier = v }
        if let v = payload["title"] as? String { t.title = v }
        if let v = payload["artist"] as? String { t.artist = v }
        if let v = payload["album"] as? String { t.album = v }
        if let v = payload["duration"] as? Double { t.duration = v }
        var newElapsed: Double?
        if let v = payload["elapsedTime"] as? Double {
            t.elapsedTime = v
            t.timestamp = Date()
            newElapsed = v
        }
        if let v = payload["playing"] as? Bool { t.isPlaying = v }

        if let b64 = payload["artworkData"] as? String,
           let imgData = Data(base64Encoded: b64),
           let image = NSImage(data: imgData) {
            t.artwork = image
        }

        var newTimestamp: Date?
        if let raw = payload["timestamp"] as? String,
           let ts = isoFormatter.date(from: raw),
           ts != lastTimestamp {
            newTimestamp = ts
        }

        return .update(t, newTimestamp: newTimestamp, newElapsed: newElapsed)
    }
}
