// Renderiza um SVG em PNG num tamanho dado, usando o suporte nativo do AppKit
// (CoreSVG, macOS 11+) — sem dependência externa. Uso:
//   swift scripts/render-svg.swift <entrada.svg> <saida.png> <tamanho-px>
import AppKit

let args = CommandLine.arguments
guard args.count == 4, let size = Int(args[3]) else {
    FileHandle.standardError.write(Data("uso: render-svg.swift <svg> <png> <px>\n".utf8))
    exit(2)
}
guard let image = NSImage(contentsOfFile: args[1]) else {
    FileHandle.standardError.write(Data("não consegui ler o SVG: \(args[1])\n".utf8))
    exit(1)
}
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }
rep.size = NSSize(width: size, height: size)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current?.imageInterpolation = .high
image.draw(
    in: NSRect(x: 0, y: 0, width: size, height: size),
    from: .zero, operation: .copy, fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! png.write(to: URL(fileURLWithPath: args[2]))
