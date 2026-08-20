# Players adicionais — Spotify, TIDAL, Deezer e YouTube Music

Levantamento e desenho feitos em `2026-08-19 · #01`, antes de escrever código. Fecha o
item 8 da ordem de implementação de `docs/fase1-multiplayer.md` ("Spotify / Deezer
quando estiverem instalados") e acrescenta a **visibilidade por app** pedida pelo dono
do produto.

Vale aqui a mesma regra do resto do projeto: **nada de capacidade presumida**. O que
está marcado como apurado foi observado nesta máquina, nesta data (macOS 26.5,
Chrome 151.0.7922.169). O que depende do app rodando está marcado **a testar**, e o
roteiro está na seção 7.

---

## 1. O que foi apurado (sem executar nada nos players)

Inspeção estática do `Info.plist`, do `.sdef` e dos processos. Nenhum comando foi
enviado a nenhum player.

| App | Bundle ID | AppleScript | Motor |
|---|---|---|---|
| **Spotify** | `com.spotify.client` | **sim** — `Spotify.sdef` | nativo |
| **TIDAL** | `com.tidal.desktop` | não (`NSAppleScriptEnabled` ausente, sem `.sdef`) | Electron |
| **Deezer** | `com.deezer.deezer-desktop` | não (idem) | Electron |
| **YouTube Music** | não tem — roda dentro do Chrome | irrelevante (ver §3) | PWA/Chrome |

### Spotify — o dicionário

A classe `application` do `Spotify.sdef` expõe, com acesso de escrita (ausência de
`access="r"` no atributo):

- `player position` (real, **gravável**) → candidato a `.realPosition` + `.seek`
- `sound volume` (integer, **gravável**) → candidato a `.appVolume`
- `shuffling` e `repeating` (boolean, **graváveis**), com `shuffling enabled` e
  `repeating enabled` só de leitura → candidato a `.shuffleRepeat`
- `player state` (enum `ePlS`, leitura)
- comandos `play`, `pause`, `playpause`, `next track`, `previous track`, `play track`

É o mesmo teto do Apple Music, com uma diferença: **não há `mute`**. O widget não usa
mute por-app hoje, então isso não custa nada.

### TIDAL — publica posição no stream

Observado ao vivo com `media-control get`, com o app aberto:

```json
{"bundleIdentifier":"com.tidal.desktop","title":"TIDAL","playing":false,
 "elapsedTime":0,"duration":5.384,"processIdentifier":23297}
```

O que importa não é o valor (o app estava parado), e sim que os campos **existem**:
`elapsedTime` e `duration` no payload. É o oposto do Amazon Music, que não publica
`elapsedTime` de jeito nenhum (`DECISOES.md · 2026-08-05 · #02`). Falta apurar com
música tocando se o valor avança de verdade — é o que a §7 cobre.

## 2. Decisões do dono do produto (`2026-08-19 · #01`)

| # | Decisão |
|---|---|
| 1 | **YouTube Music entra como atalho de lançamento**, com a fonte rotulada como navegador. Não se inventa identidade que o sistema não dá (ver §3). |
| 2 | **O checkbox controla a lista de escolha _e_ a exibição.** App desmarcado some do menu e do seletor, e sua sessão é ignorada pelo widget. |
| 3 | **Catálogo fixo + apps descobertos.** Além dos apps suportados, qualquer fonte que já tenha aparecido no Now Playing entra na lista de visibilidade. |
| 4 | **Apps não instalados aparecem esmaecidos**, com o caminho de instalação — a lista é também a vitrine do que o widget suporta. |

## 3. Por que o YouTube Music não pode ter identidade própria

O PWA está instalado (`~/Applications/Chrome Apps.localized/YouTube Music.app`,
bundle id `com.google.Chrome.app.cinhimbnkkaeohfgghhklpknlkffjgod`) e **não abre** —
o sintoma que o dono do produto relatou. Apurado: `open` do bundle retorna 0, o
`app_mode_loader` sai sem deixar processo, e nenhum dos 20 processos do Chrome traz
`--app-id` ou o hash do app. A causa provável é descasamento entre o shim e a versão
atual do Chrome; **o conserto é reinstalar o PWA pelo próprio Chrome**, e não tem nada
a ver com o widget.

Consertá-lo, porém, não resolveria o que se queria dele. O shim do Chrome é só um
lançador: ele manda o Chrome abrir uma janela em modo app, e **quem reproduz o áudio é
o processo do Chrome**. O MediaRemote identifica a sessão pelo processo — o payload
traz `processIdentifier` ao lado de `bundleIdentifier` —, então a sessão sai como
`com.google.Chrome` com ou sem PWA.

Rotular a sessão do Chrome como "YouTube Music" seria mentira barata: qualquer outra
aba com áudio (um vídeo, uma videochamada, outro serviço de streaming) receberia o
mesmo rótulo. O widget mostra o que sabe.

Daí a distinção que estrutura o desenho: **como se lança um serviço** e **como se
identifica a sessão dele** são coisas diferentes, e o YouTube Music só participa da
primeira.

## 4. Desenho

### 4.1 Catálogo separado do registro

Hoje `PlayerRegistry.builders` acumula dois papéis: resolver *quem controla* um bundle
id que apareceu no stream, e definir *o que o usuário pode escolher*. Com seis entradas
e visibilidade configurável, os dois conjuntos deixam de coincidir — o YouTube Music
está num e não no outro.

Entra um **`PlayerCatalog`** declarativo, e o `PlayerRegistry` fica só com a resolução
de sessão → player.

```swift
/// O que uma entrada do catálogo é, do ponto de vista do sistema.
enum PlayerCatalogKind {
    /// App nativo com bundle id próprio: identifica sessão de Now Playing
    /// e pode ser lançado.
    case app
    /// Serviço que roda dentro de outro app (navegador). Pode ser lançado;
    /// nunca identifica uma sessão — ver §3.
    case shortcut(LaunchTarget)
}

/// Como abrir a entrada.
enum LaunchTarget {
    case app                        // pelo próprio bundleID da entrada
    case appElseURL(String, URL)    // tenta o bundle id; se ausente, abre a URL
}

struct PlayerCatalogEntry {
    let id: String                  // chave estável (bundle id, ou id sintético do atalho)
    let displayName: String
    let kind: PlayerCatalogKind
    let installURL: URL?
    let make: () -> Player
}
```

Entradas iniciais:

| Entrada | `id` | Kind | Classe | Capacidades |
|---|---|---|---|---|
| Amazon Music | `com.amazon.music` | app | `AmazonMusicPlayer` | apuradas: `.transport` |
| Apple Music | `com.apple.Music` | app | `AppleMusicPlayer` | apuradas: tudo |
| Spotify | `com.spotify.client` | app | `SpotifyPlayer` (novo) | **a apurar** |
| TIDAL | `com.tidal.desktop` | app | `TidalPlayer` (novo) | **a apurar** |
| Deezer | `com.deezer.deezer-desktop` | app | `DeezerPlayer` (novo) | **a apurar** |
| Google Chrome | `com.google.Chrome` | app | `BrowserPlayer` (novo) | **a apurar** |
| Safari | `com.apple.Safari` | app | `BrowserPlayer` (novo) | **a apurar** |
| YouTube Music | `service.youtube.music` | shortcut | `BrowserPlayer` | herda do navegador |

Chrome e Safari são **entradas separadas**, uma por bundle id, compartilhando a classe
`BrowserPlayer`. Uma entrada única "Navegador" cobrindo os dois quebraria a chave
estável do catálogo e impediria ocultar um sem o outro — que é um caso real: quem usa
o Safari para vídeo e o Chrome para música quer ver só um dos dois no widget.

`SpotifyPlayer` herda `AppleScriptPlayer` com `scriptingName: "Spotify"`. `TidalPlayer`
e `DeezerPlayer` herdam `MediaRemotePlayer` apenas para fixar nome e `installURL` — a
mesma forma do `AmazonMusicPlayer` de hoje.

A entrada do YouTube Music usa `appElseURL(pwaBundleID, https://music.youtube.com)`:
tenta o PWA e, se ele não estiver instalado ou não abrir, cai na URL no navegador
padrão. Assim o conserto do PWA é um bônus, não um pré-requisito.

### 4.2 Visibilidade: blocklist, não allowlist

**A preferência guarda os apps _ocultos_, não os visíveis.** A UI é a que foi pedida —
uma lista de checkboxes — mas o que vai para o `UserDefaults` é o conjunto dos
desmarcados:

```swift
@Published var hiddenPlayerIDs: Set<String>   // settings.hiddenPlayerIDs, default vazio
```

O motivo é a decisão 3 combinada com a 2. Guardando os marcados, todo app ainda não
conhecido nasceria desmarcado — e como o filtro também esconde a exibição, o widget
ficaria mudo diante de qualquer player novo. Isso é regressão direta sobre o
comportamento de hoje, em que **qualquer** fonte funciona, inclusive as que o código
nunca ouviu falar. Guardando os ocultos, o padrão é tudo visível, app novo aparece
sozinho, e o checkbox só subtrai.

O efeito de ocultar depende do `kind`, e a assimetria é real:

| Kind | Oculto significa |
|---|---|
| `app` | some do menu "Trocar app" e do seletor de preferido **e** sua sessão é ignorada |
| `shortcut` | some do menu e do seletor apenas — não há sessão própria para filtrar (§3) |

### 4.3 Apps descobertos

Toda fonte que aparecer no stream com um bundle id fora do catálogo é registrada:

```swift
@Published var discoveredPlayerIDs: [String]  // settings.discoveredPlayerIDs
```

Nome e ícone saem do `Player.localizedName(forBundleIdentifier:)` e do
`NSWorkspace`, que já existem. A lista só cresce com o que **de fato** publicou Now
Playing — o QuickTime, por exemplo, nunca entraria, porque reproduz sem publicar sessão
(apurado em `docs/compatibilidade-players.md`). Uma linha em Preferências permite
esquecer as entradas descobertas.

### 4.4 Regras de coerência

Estados impossíveis eliminados por construção, não por validação espalhada:

- **O player preferido não pode ser ocultado.** Checkbox travado, com o motivo visível.
  A alternativa (ocultar e realocar a preferência sozinho) mexe na escolha do usuário
  sem ele pedir.
- **Ocultar tudo é bloqueado** — o último visível trava junto.
- **Modo fixo apontando para app oculto** deixa de ser alcançável, já que o preferido
  nunca está oculto.

### 4.5 O filtro não pode virar card vazio

Com filtro de exibição, um app oculto tocando deixaria o widget em branco —
indistinguível de "não estou ouvindo nada" e de app quebrado. O card precisa dizer o
que está acontecendo:

> ♪ Spotify está tocando · oculto

com ação para reexibir. O mecanismo já existe: é o mesmo padrão de
`transportUnavailableReason`, que hoje explica por que o transporte está indisponível
em vez de só apagar os botões. Acrescenta-se um `hiddenSourceName` ao
`NowPlayingController`, lido pelo `ContentView` e pela `MenuStatusView`.

### 4.6 Posição pelo stream — lacuna encontrada no código atual

`NowPlayingParser` lê `elapsedTime` do payload para dentro do `TrackInfo`
(`NowPlayingParser.swift:54`), mas `NowPlayingController.handleLine` **nunca usa esse
valor para ancorar o cronômetro**: ancora pelo `timestamp` de início de faixa ou pela
transição play/pause. O único caminho com posição verdadeira é
`pollRealPositionIfNeeded()`, que exige `.realPosition` — ou seja, AppleScript.

Consequência: TIDAL, Deezer e navegador publicam `elapsedTime` de graça no stream e o
widget ignoraria, estimando a posição quando tem o número verdadeiro na mão. O Apple
Music não sofre disso porque o poll de AppleScript reancora logo em seguida; o Amazon
Music não sofre porque não publica o campo.

Correção proposta, sem capacidade nova (é característica da **sessão**, não do player):
`Outcome.update` passa a sinalizar `newElapsed: Double?` quando a linha trouxe
`elapsedTime`, e `handleLine` reancora com ele. Precedência: um `timestamp` de faixa
nova continua mandando — ele indica troca de faixa, e o `elapsedTime` da mesma linha
se refere à faixa nova de qualquer modo.

### 4.7 UI das Preferências

Seção nova em `PreferencesView`, abaixo de "Player":

```
Apps controlados
  ☑  Amazon Music                    (preferido — não pode ser ocultado)
  ☑  Apple Music
  ☑  Spotify
  ☑  TIDAL
  ☐  Deezer
  ☐  Google Chrome
  ☐  Safari                          (esmaecido — não instalado)
  ☑  YouTube Music                   (abre no navegador)
  ─────
  Descobertos: ☑ VLC   [Esquecer descobertos]

  Apps desmarcados somem do menu "Trocar app" e o widget ignora o que eles tocam.
```

Um detalhe de implementação que precisa mudar junto: hoje
`PreferencesView.players` é um `let` fixado na criação da janela
(`PreferencesWindow.swift:43`), com o comentário de que instalar um app com as
preferências abertas é raro. Com checkboxes que alteram a lista ao vivo, isso deixa de
valer — a lista passa a derivar de `@ObservedObject`.

## 5. Arquivos

```
Sources/MacMediaWidget/Players/
├── PlayerCatalog.swift      # NOVO — catálogo declarativo, kind, LaunchTarget
├── SpotifyPlayer.swift      # NOVO — AppleScriptPlayer
├── TidalPlayer.swift        # NOVO — MediaRemotePlayer (nome + installURL)
├── DeezerPlayer.swift       # NOVO — MediaRemotePlayer (nome + installURL)
├── BrowserPlayer.swift      # NOVO — Chrome/Safari + alvo do atalho YouTube Music
├── PlayerRegistry.swift     # passa a consultar o catálogo; installedKnownPlayers sai
└── Player.swift             # sem mudança de contrato

Sources/MacMediaWidget/
├── Settings.swift           # hiddenPlayerIDs, discoveredPlayerIDs + regras
├── PreferencesWindow.swift  # seção "Apps controlados"; lista deixa de ser `let`
├── AppMenuController.swift  # submenu filtrado; atalhos separados dos apps
├── NowPlayingController.swift # filtro de exibição, hiddenSourceName, âncora por elapsedTime
├── NowPlayingParser.swift   # Outcome.update ganha newElapsed
├── ContentView.swift        # estado "fonte oculta"
├── MenuStatusView.swift     # idem no menu
├── L10n.swift               # chaves novas
└── SelfTests.swift          # asserções novas

Resources/pt-BR.lproj/Localizable.strings   # traduções
docs/compatibilidade-players.md             # colunas novas, só com evidência
```

## 6. Ordem de implementação

Cada etapa termina com `swift build` verde e `--run-tests` passando, sem regressão em
Amazon Music e Apple Music.

1. **Testes empíricos primeiro (gate).** §7. Sem isso não se declara capacidade
   nenhuma, e as etapas 3 e 4 não têm o que preencher.
2. **`PlayerCatalog` + refatoração do `PlayerRegistry`**, sem mudança de comportamento:
   as duas entradas de hoje passam pelo catálogo e tudo continua idêntico.
3. **Players novos** com as capacidades apuradas na etapa 1.
4. **Âncora por `elapsedTime` do stream** (§4.6) — melhora TIDAL, Deezer e navegador.
5. **Visibilidade em `AppSettings`** (blocklist + descobertos + regras de coerência),
   ainda sem UI.
6. **Filtro no menu e no seletor de preferido.**
7. **Filtro de exibição + estado "fonte oculta"** na UI (§4.5).
8. **Seção "Apps controlados" nas Preferências** (§4.7).
9. **Traduções** (`scripts/verificar-traducoes.sh`), asserções novas e atualização de
   `docs/compatibilidade-players.md`.

## 7. Roteiro de testes empíricos (gate da etapa 1)

Requer fila com **3 ou mais faixas** em cada player — com uma faixa só, `next` dá falso
negativo, armadilha já documentada em `docs/compatibilidade-players.md`.

Por app, via `scripts/testar-player.sh <bundle-id> [nome-applescript]`:

| Alvo | Comando | O que decide |
|---|---|---|
| Spotify | `scripts/testar-player.sh com.spotify.client Spotify` | todas as capacidades do `.sdef`; é o único do lote que pode ganhar a camada rica |
| TIDAL | `scripts/testar-player.sh com.tidal.desktop` | transporte e, principalmente, se `elapsedTime` **avança** com música tocando |
| Deezer | `scripts/testar-player.sh com.deezer.deezer-desktop` | transporte e presença de `elapsedTime` |
| Navegador | `scripts/testar-player.sh com.google.Chrome` | transporte a partir de uma aba tocando (exige play manual) |

Além da bateria padrão, dois testes específicos desta rodada:

1. **Identidade do PWA.** Reinstalar o PWA do YouTube Music pelo Chrome, dar play e ler
   `media-control get`. O esperado, pelo mecanismo da §3, é `com.google.Chrome`. Se vier
   o bundle id do PWA, a §3 está errada e o YouTube Music vira app de primeira classe —
   registrar e refazer o desenho da entrada.
2. **Seek do Spotify pelo teste observável.** Posicionar a 5 s do fim com o app tocando
   e verificar se a faixa termina e avança. É o teste que desmascarou o Amazon Music;
   ler o código de retorno não serve.

Cada célula da matriz recebe **verificado (com evidência)**, **não funciona (com
evidência)** ou **não existe**.

## 8. Riscos e pontos de atenção

- **Prompt de Automação por app-alvo.** O Spotify traz um prompt novo do TCC
  ("MacMediaWidget quer controlar Spotify"). `NSAppleEventsUsageDescription` e a
  entitlement `com.apple.security.automation.apple-events` já estão no bundle
  (conferido), então é só o prompt mesmo — mas negá-lo tem que rebaixar as capacidades,
  caminho que o `AppleScriptPlayer` já implementa e que precisa ser exercitado no teste.
- **Electron não é garantia de nada.** TIDAL e Deezer podem publicar Now Playing
  parcial, ou aceitar `next` e ignorar. É exatamente o caso Amazon Music — só o teste
  observável decide.
- **O PWA pode continuar sem abrir.** O `appElseURL` cobre isso por desenho, mas o
  fallback muda o comportamento (abre aba comum em vez de janela de app). Aceito.
- **Lista de descobertos pode acumular ruído.** Mitigado por só registrar quem publica
  Now Playing e pelo botão de esquecer.
- **Custo de polling não muda.** Só Spotify entra no caminho de `.realPosition` por
  AppleScript, e o poll já é limitado a 1 Hz com o widget visível.
