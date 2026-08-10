# Fase 1 — Multi-player: levantamento técnico

Levantado em `2026-08-10 · #01`, antes de escrever código. Serve de base para a
implementação e para a matriz de compatibilidade exigida pelo `ROADMAP.md`.

Tudo marcado **verificado** foi apurado nesta máquina, nesta data (macOS 26,
`media-control` 0.7.6). O que não pôde ser apurado está marcado **a testar** — e o
roteiro para apurar está na seção 6.

---

## 0. Decisões já tomadas (não reabrir)

Respondidas pelo dono do produto em `2026-08-10 · #01` e registradas em `DECISOES.md`.
São o contrato desta fase — a implementação segue daqui sem novas perguntas.

| # | Decisão |
|---|---|
| 1 | **Começar sem esperar instalação.** Amazon Music + Apple Music + navegador agora; Spotify/Deezer depois, como adaptadores adicionais. |
| 2 | **Dois modos de controle, com chave nas preferências:** automático (espelha quem toca) como padrão, fixo (sempre o player escolhido) como opção. |
| 3 | **Modo fixo com player sem AppleScript fora da sessão ativa:** play abre o app e espera virar sessão; next/prev/seek desabilitados com o motivo visível. Comando global nunca sai às cegas. |
| 4 | **Volume por-app onde existir**, sistema no resto, com o alvo indicado na UI. |
| 5 | **Barra vira controle onde houver seek comprovado**; indicador nas demais fontes. Delimita a decisão de `2026-08-05 · #02` ao Amazon Music. |
| 6 | **Testes liberados:** pode abrir apps, trocar faixa, alterar shuffle/repeat, mover posição e volume sem confirmação a cada passo. Restaurar volume e modos ao final. O prompt de Automação do macOS é a única interrupção — avisar quando aparecer. |

## 1. A restrição que determina toda a arquitetura

**O comando do MediaRemote não tem destinatário.** O `mediaremote-adapter` expõe
`send <MRCommand>`, `seek`, `shuffle`, `repeat`, `speed` — e todos atuam sobre "a"
sessão de Now Playing do sistema, seja ela qual for. Não existe parâmetro de bundle id.
(Verificado: `help` do adapter, seção `FUNCTION`/`PARAMS`.)

Consequência direta: **"escolher o player" não é escolher para onde o comando vai.**
Via MediaRemote só se controla quem *já* é a sessão ativa. Um "player preferido" só
pode significar duas coisas honestas:

1. qual app abrir quando o usuário dá play e nada está tocando;
2. filtro de exibição (mostrar/ignorar sessões de outros apps).

O **único** jeito de mandar um comando para um app específico que não é a sessão ativa é
AppleScript — que só existe em alguns players. Isso torna o comportamento
inerentemente assimétrico, e a UI precisa refletir isso em vez de esconder.

## 2. O que cada fonte permite

| Fonte | Leitura (Now Playing) | Transporte | Posição real | Seek | Volume por-app | Shuffle/Repeat |
|---|---|---|---|---|---|---|
| **Amazon Music** (`com.amazon.music`) | sim, sem `elapsedTime` | sim (MediaRemote) | **não** | **não** | **não** | a testar |
| **Apple Music** (`com.apple.Music`) | sim | sim (MediaRemote + AppleScript) | sim (AppleScript) | sim (AppleScript) | sim (AppleScript) | sim (AppleScript) |
| **Spotify** (`com.spotify.client`) | a testar | a testar | a testar | a testar | a testar | a testar |
| **Deezer** | a testar | a testar | a testar | a testar | a testar | a testar |
| **Navegador** (Chrome/Safari) | a testar | a testar | a testar | **não** | **não** | **não** |

Base de cada célula:

- **Amazon Music** — verificado e já registrado em `DECISOES.md` (`2026-08-05 · #01` e
  `#02`): não publica posição, ignora o comando de seek, e **não tem AppleScript**
  (reconfirmado hoje: `NSAppleScriptEnabled` ausente no `Info.plist`, nenhum `.sdef`).
  Logo, para ele o teto é: ler metadados + play/pause/next/prev, e volume só do sistema.
- **Apple Music** — verificado hoje lendo `com.apple.Music.sdef` (44,7 KB) sem executar
  nada: `NSAppleScriptEnabled = true`, e a classe `application` expõe as propriedades
  `player position` (real, **gravável** → seek), `sound volume` (integer 0–100 → volume
  por-app), `mute`, `player state`, `shuffle enabled`, `shuffle mode`, `song repeat`,
  `current track`; e os comandos `play`, `pause`, `playpause`, `next track`,
  `previous track`, `back track`, `fast forward`, `rewind`, `resume`, `stop`.
  **É o player mais capaz da lista, e está instalado** — dá para validar a camada
  AppleScript inteira sem instalar nada.
- **Spotify** — não está instalado nesta máquina (verificado por `mdfind`). É sabido que
  publica um `.sdef` com `player position` e `sound volume`, mas **a regra do projeto é
  não prometer sem testar contra o app real**, então fica como *a testar*.
- **Navegador** — Chrome e Safari têm AppleScript, mas **nenhuma capacidade de mídia**:
  verificado hoje por busca nos dois `.sdef` (`volume|player position|media` → 0
  ocorrências). O que existe é `execute javascript` (Chrome) / `do JavaScript` (Safari),
  que dependem de uma opção do menu Desenvolvedor ligada à mão pelo usuário — inviável
  como recurso de produto. Portanto, para navegador só existe o caminho MediaRemote, e o
  suporte real (quais comandos a página respeita) varia por site e precisa de teste.

## 3. Desenho proposto

Duas camadas, que espelham exatamente a assimetria da seção 1:

- **Camada universal (MediaRemote)** — já existe, é o `NowPlayingController`. Continua
  sendo a **única fonte de leitura** (metadados, capa, estado) e o transporte padrão.
  Funciona com qualquer fonte, inclusive as que ninguém previu.
- **Camada de capacidades (AppleScript), opcional e por app** — acrescenta o que o
  MediaRemote não dá: posição real, seek, volume por-app, shuffle/repeat, e comando
  direcionado a um app que não é a sessão ativa.

### Contrato

```swift
struct PlayerCapabilities: OptionSet {
    static let transport      // play/pause/next/prev
    static let realPosition   // lê a posição de verdade (não estimada)
    static let seek           // grava a posição
    static let appVolume      // volume do app, não do sistema
    static let shuffleRepeat
    static let directedControl // aceita comando sem ser a sessão ativa
}

protocol Player {
    var bundleIdentifier: String { get }
    var displayName: String { get }
    var capabilities: PlayerCapabilities { get }

    func playPause(); func next(); func previous()
    func seek(to seconds: Double)
    func position() -> Double?
    func volume() -> Double?; func setVolume(_ value: Double)
}
```

Implementações:

- `MediaRemotePlayer` — genérica, serve para qualquer bundle id desconhecido.
  Capacidades: `[.transport]`.
- `AppleScriptPlayer` — base com o runner `osascript` (já existe um em
  `SystemVolumeController`, a extrair para reuso).
- `AppleMusicPlayer`, `SpotifyPlayer` — concretas, capacidades declaradas **só depois
  de teste empírico**.
- `PlayerRegistry` — detecta instalados via
  `NSWorkspace.urlForApplication(withBundleIdentifier:)`, resolve o player efetivo a
  partir do `bundleIdentifier` do stream, e devolve `MediaRemotePlayer` como fallback.

### Arquivos

```
Sources/MacMediaWidget/Players/
├── Player.swift            # protocolo + PlayerCapabilities
├── MediaRemotePlayer.swift
├── AppleScriptPlayer.swift # runner osascript + base
├── AppleMusicPlayer.swift
├── SpotifyPlayer.swift     # só quando houver Spotify para testar
└── PlayerRegistry.swift
```

`NowPlayingController` mantém o stream e passa a delegar comandos ao player resolvido.
`ContentView` consulta `capabilities` para decidir o que renderizar.

## 4. Ordem de implementação

Cada etapa termina com `swift build` verde e o widget funcionando — sem regressão no
Amazon Music, que é o critério de saída do ROADMAP.

1. **Extração sem mudança de comportamento.** Protocolo + `MediaRemotePlayer` +
   registry; `NowPlayingController` roteia por eles. Amazon Music tem que continuar
   idêntico. Nenhuma mudança visível na UI.
2. **Fonte ativa na UI.** Ícone e nome do app da sessão (via `NSWorkspace`), a partir do
   `bundleIdentifier` que o stream já entrega.
3. **Camada AppleScript com Apple Music.** Runner extraído, `AppleMusicPlayer` com
   posição real, seek, volume por-app, shuffle/repeat. É aqui que a arquitetura se prova.
4. **Generalizar o que hoje é hardcoded no Amazon.** `autoLaunchOnPlay`,
   `waitForAmazonMusicThenPlay`, `isAmazonMusicRunning`, `openAmazonMusic`,
   `promptInstall…` e o `simulateMissingApp` são todos específicos — passam a operar
   sobre o player preferido. **A proteção contra o comando global vazando para o player
   padrão do sistema tem que sobreviver à generalização** (é o bug de
   `DECISOES.md · 2026-08-05 · #01`).
5. **Modo automático × modo fixo** (decisão 2). Chave em `AppSettings` +
   `PreferencesView`; o roteamento de comando consulta o modo. No fixo, o estado
   "player escolhido não é a sessão ativa e não é direcionável" desabilita next/prev/seek
   com o motivo à vista, e o play usa o caminho de abrir-e-esperar (decisão 3).
6. **UI condicional por capacidade.** Barra vira controle só onde há `.seek`; o alvo do
   slider de volume fica explícito. Todo controle novo precisa de
   `.nonDraggableWindowArea()`, senão volta a arrastar a janela
   (`DECISOES.md · 2026-08-05 · #01`).
7. **Matriz de compatibilidade.** `scripts/testar-player.sh` roteirizado + resultado em
   `docs/compatibilidade-players.md`.
8. **Spotify / Deezer** quando estiverem instalados.

## 5. Riscos e pontos de atenção

- **Permissão de Automação (TCC).** A primeira vez que o app mandar AppleScript para
  outro app, o macOS mostra o prompt "MacMediaWidget quer controlar Music" e o usuário
  precisa autorizar — **um prompt por app-alvo**. Some a isso:
  - `Info.plist` precisa de `NSAppleEventsUsageDescription` (hoje **não tem**);
  - na Fase 4, com hardened runtime, precisa da entitlement
    `com.apple.security.automation.apple-events`.
  - O `set volume` de hoje **não** dispara prompt porque fala com o sistema, não com um
    app — ou seja, esse atrito é novo e é da Fase 1.
- **Negação silenciosa.** Se o usuário negar (ou já tiver negado) a automação, o
  AppleScript falha sem alarde. As capacidades declaradas precisam ser degradadas em
  runtime, não confiadas cegamente na tabela.
- **Duas fontes de posição divergindo.** Onde houver posição real (Apple Music), ela
  manda; o cronômetro estimado do `NowPlayingController` tem que ser desligado para
  aquela fonte, e não somado.
- **Polling.** Ler `player position` por AppleScript é polling (1 processo `osascript`
  por leitura). A 1 Hz já é bem mais caro que o stream. Coalescer e só rodar com o
  widget visível.
- **Prometer o que não se testou.** A tabela da seção 2 tem células "a testar" de
  propósito: pelo histórico do projeto (seek do Amazon), **comando aceito sem erro ≠
  comando funcionando**.

## 6. Roteiro de testes empíricos (executar na sessão de desenvolvimento)

Por player, com o app tocando e o stream do adapter capturado em arquivo:

1. `send 0/1/2` (play/pause/toggle) — o estado muda no app?
2. `send 4/5` (next/prev) — a faixa troca?
3. `seek <micros>` — a posição muda? (teste observável: seek para 5s antes do fim; se
   funcionar, a faixa termina e avança — foi assim que o Amazon foi desmascarado)
4. `shuffle <modo>` / `repeat <modo>` — o modo muda no app?
5. AppleScript, onde houver: `player position` (ler e gravar), `sound volume`, `mute`,
   `shuffle enabled`, `song repeat`.
6. Estado degradado: app fechado; app aberto sem tocar; dois players tocando ao mesmo
   tempo (quem vira a sessão?); permissão de automação negada.

Cada linha da matriz recebe **verificado (com evidência)**, **não funciona (com
evidência)** ou **não existe**. Nada de "presumido".

## 7. Pré-requisitos e limites conhecidos

- **Spotify e Deezer não estão instalados** nesta máquina (verificado). Sem eles, a
  Fase 1 vai até o item 6 da seção 4 cobrindo Amazon Music, Apple Music e navegador.
  O critério de saída do ROADMAP (que exige Spotify) só fecha depois da instalação.
- **Apple Music está instalado** (`/System/Applications/Music.app`) e é suficiente para
  validar toda a camada AppleScript.
- Os testes mexem na reprodução em curso: abrem apps, trocam faixa, alteram shuffle e
  volume. Precisa ser feito com o usuário ciente.
