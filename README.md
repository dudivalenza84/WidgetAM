# MacMediaWidget

Widget de mesa para macOS, com design Liquid Glass nativo, que **controla** o app oficial
`Amazon Music.app` pelo Now Playing do macOS. O widget não reproduz áudio — o motor de
reprodução é o próprio `Amazon Music.app` rodando em background. Uso pessoal.

## Como funciona

Um app Swift nativo (AppKit + SwiftUI) roda como _accessory_ (sem ícone no Dock) e exibe um
card de widget em nível de mesa, presente em todos os Spaces. A integração com o player usa o
[`mediaremote-adapter`](https://github.com/ejbills/mediaremote-adapter) bundlado: um
`/usr/bin/perl` entitled lê o stream do Now Playing (capa, título, artista, progresso, estado)
e envia comandos de transporte (`play`/`pause`/`next`/`prev`/`seek`) ao `com.amazon.music`. O
controle de volume atua no volume de saída do **sistema** (global), via AppleScript.

## Requisitos

- macOS 26 ou superior.
- `Amazon Music.app` oficial instalado.
- Command Line Tools (Swift 6) e [`media-control`](https://github.com/ungive/media-control)
  via Homebrew (`brew install media-control`) — para montar o bundle.

## Build e empacotamento

```bash
# Compila e monta dist/MacMediaWidget.app (codesign ad-hoc)
./scripts/build-app.sh

# Gera dist/MacMediaWidget.dmg a partir do .app montado
./scripts/package-dmg.sh
```

Para desenvolvimento, `swift build` + `swift run` rodam o binário solto (sem login item).

## Instalação (uso pessoal)

O app é assinado ad-hoc (sem Apple Developer ID), então o Gatekeeper bloqueia a primeira
abertura. Abra o `.dmg`, arraste o `MacMediaWidget.app` para `/Applications` e remova a
quarentena:

```bash
xattr -dr com.apple.quarantine /Applications/MacMediaWidget.app
open /Applications/MacMediaWidget.app
```

(Alternativa sem terminal: clicar com o botão direito no app → **Abrir** → confirmar.)

## Uso

- O widget aparece na mesa. Arraste para reposicionar — ele faz _snap_ à borda e persiste a
  posição.
- Ícone na barra de menu: mostrar/ocultar widget, abrir Amazon Music, **Preferências…**,
  abrir no login, sair.
- **Preferências…** ajusta ao vivo: margem da borda (alinhamento do _snap_), passo da grade
  vertical, opacidade da tonalização da capa, abrir o Amazon Music ao dar play (se estiver
  fechado) e abrir no login.

## Governança

O trabalho é organizado em sessões documentadas em `docs/sessions/` (índice em `SESSIONS.md`),
com backlog em `PENDENCIAS.md` e histórico em `CHANGELOG.md`. Detalhes em `CLAUDE.md`.
