# MacMediaWidget

Widget de mesa para macOS, com design Liquid Glass nativo, que **controla** os apps de
música pelo Now Playing do macOS — com o `Amazon Music.app` como alvo principal. O widget
não reproduz áudio: o motor de reprodução é sempre o app de música rodando em background.

## Como funciona

Um app Swift nativo (AppKit + SwiftUI) roda como _accessory_ (sem ícone no Dock) e exibe um
card de widget em nível de mesa, presente em todos os Spaces.

A integração tem **duas camadas**, e a divisão não é estética — é imposta pela plataforma:

1. **MediaRemote (universal).** O [`mediaremote-adapter`](https://github.com/ungive/mediaremote-adapter)
   bundlado roda sob `/usr/bin/perl` entitled e lê o stream do Now Playing (capa, título,
   artista, estado) de **qualquer** fonte, além de enviar comandos de transporte. O limite:
   esse comando **não tem destinatário** — ele atua sobre a sessão de Now Playing do
   sistema, seja ela qual for.
2. **AppleScript (por app, opcional).** Onde o player tem dicionário — Apple Music e
   Spotify têm, Amazon Music não —, o widget ganha posição real, seek, volume do próprio
   app, shuffle/repeat e, principalmente, **comando endereçado**: dá para controlar aquele
   app mesmo com outro tocando.

## Apps suportados

Qualquer fonte que publique Now Playing aparece no widget e aceita play/pause — inclusive
uma que este código nunca viu. O que muda por app é **quanto** dele o widget consegue
controlar, e isso só entra depois de medido contra o app real
([`docs/compatibilidade-players.md`](docs/compatibilidade-players.md)):

| App | O que o widget faz |
|---|---|
| **Amazon Music** | transporte completo; barra é só indicador (ignora seek, não publica posição) |
| **Apple Music** | tudo: posição real, seek, volume do app, shuffle/repeat, comando endereçado |
| **Spotify** | tudo, como o Apple Music — e o seek funciona pelos dois caminhos |
| **TIDAL** | transporte completo, seek e posição verdadeira vinda do stream |
| **Deezer** | play/pause, próxima e posição verdadeira; **sem** "anterior" e **sem** seek — o app ignora os dois |
| **Google Chrome** | play/pause e seek; **sem** pular faixa — `next` não faz nada e `previous` rebobina a mídia |
| **YouTube Music** | atalho: abre o PWA (ou o site). Quem toca é o navegador, então é ele que aparece como fonte |

Em **Preferências ▸ Apps controlados** dá para desmarcar o que não interessa: o app some
do seletor de preferido e do menu "Trocar app", e o card deixa de exibi-lo quando ele
toca. O preferido e o último app visível não podem ser desmarcados — seria estado sem
saída.

Daí as duas preferências: o **player preferido** (o que o widget abre no play) e o **modo
de controle** — automático, que espelha quem está tocando, ou fixo, que fica preso ao
player escolhido. No modo fixo com um player sem AppleScript, o play abre o app e os
demais controles ficam inativos enquanto ele não for a sessão; a alternativa seria mandar
um comando global que cairia no app errado.

A UI se adapta ao que a fonte permite: a barra de progresso só é arrastável onde o seek
foi comprovado, e o slider de volume diz se está mexendo no app ou no sistema. O que cada
player aceita, com evidência, está em [`docs/compatibilidade-players.md`](docs/compatibilidade-players.md).

No `Amazon Music.app` especificamente a barra é **indicador, não controle**: ele ignora o
comando de posicionamento do MediaRemote e não publica a posição da faixa. Ver `DECISOES.md`.

## Requisitos

- macOS 26 ou superior.
- Ao menos um player suportado instalado (ver a tabela acima).
- Permissão de Automação para o player, quando se usa a camada AppleScript. O macOS pede
  na primeira vez; negar não quebra o app, só rebaixa os recursos extras.
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
