#!/usr/bin/env bash
# Gera todos os assets de identidade a partir dos SVGs-fonte de Resources/icon/:
#   AppIcon.icns          (todas as resoluções do iconset, 16→1024 px)
#   MenuBarIcon.png       (glifo template da bandeja, 36 px — exibido a 18 pt)
#   favicon/              (PNG 16/32/48 + favicon.ico)
# Os tamanhos 16/32 usam icon-small.svg (traço grosso, cor chapada); o resto usa
# icon-master.svg. Rodar sempre que um SVG-fonte mudar.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON="$ROOT/Resources/icon"
render() { swift "$ROOT/scripts/render-svg.swift" "$@"; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET" "$ICON/favicon"

# 1. Iconset: pares @1x/@2x que o iconutil exige.
render "$ICON/icon-small.svg"  "$ICONSET/icon_16x16.png"      16
render "$ICON/icon-small.svg"  "$ICONSET/icon_16x16@2x.png"   32
render "$ICON/icon-small.svg"  "$ICONSET/icon_32x32.png"      32
render "$ICON/icon-master.svg" "$ICONSET/icon_32x32@2x.png"   64
render "$ICON/icon-master.svg" "$ICONSET/icon_128x128.png"    128
render "$ICON/icon-master.svg" "$ICONSET/icon_128x128@2x.png" 256
render "$ICON/icon-master.svg" "$ICONSET/icon_256x256.png"    256
render "$ICON/icon-master.svg" "$ICONSET/icon_256x256@2x.png" 512
render "$ICON/icon-master.svg" "$ICONSET/icon_512x512.png"    512
render "$ICON/icon-master.svg" "$ICONSET/icon_512x512@2x.png" 1024
iconutil -c icns "$ICONSET" -o "$ICON/AppIcon.icns"

# 2. Bandeja: 36 px físicos, exibidos a 18 pt (nítido em retina; o downscale para
#    telas @1x é do AppKit).
render "$ICON/menubar-template.svg" "$ICON/MenuBarIcon.png" 36

# 3. Favicon: PNGs + ICO (contêiner ICO com PNGs embutidos — válido desde o Vista).
render "$ICON/icon-small.svg" "$ICON/favicon/favicon-16.png" 16
render "$ICON/icon-small.svg" "$ICON/favicon/favicon-32.png" 32
render "$ICON/icon-small.svg" "$ICON/favicon/favicon-48.png" 48
python3 - "$ICON/favicon" <<'PY'
import struct, sys, pathlib
d = pathlib.Path(sys.argv[1])
sizes = [16, 32, 48]
pngs = [(s, (d / f"favicon-{s}.png").read_bytes()) for s in sizes]
out = struct.pack("<HHH", 0, 1, len(pngs))
offset = 6 + 16 * len(pngs)
entries, blobs = b"", b""
for size, data in pngs:
    entries += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(data), offset)
    blobs += data
    offset += len(data)
(d / "favicon.ico").write_bytes(out + entries + blobs)
PY

echo "==> assets gerados em $ICON"
