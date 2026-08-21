# CLAUDE.md — MacMediaWidget

Instruções específicas deste projeto para o Claude Code. Tem precedência sobre o `CLAUDE.md` global do usuário e o `CLAUDE.md` da pasta `Pessoal` no que for específico daqui.

## O que é o projeto

Widget de desktop para macOS, com design premium (Liquid Glass), que **controla** o app oficial nativo `Amazon Music.app` via o Now Playing do macOS. O widget não reproduz áudio: o motor de reprodução é o próprio `Amazon Music.app` rodando em background. Uso pessoal individual.

> Virada de arquitetura (2026-06-23 · #01): a abordagem anterior — Electron controlando o PWA no Chrome via AppleScript — foi descartada (a Amazon bloqueia navegador desconhecido e o requisito é não depender do Chrome). Histórico Electron preservado no git.

## Stack

- **Linguagem/UI**: Swift nativo — AppKit (janela widget, tray) + SwiftUI (UI Liquid Glass).
- **Janela**: `NSWindow` em nível de desktop, sem bordas, presente em todos os Spaces, não-ativante, com snap à grade de widgets da mesa.
- **Integração com o player**: duas camadas (ver `docs/fase1-multiplayer.md`).
  1. **MediaRemote** — `mediaremote-adapter` (de `ungive`/Jonas van den Berg, BSD-3-Clause, obtido via o pacote Homebrew `media-control` do mesmo autor) bundlado no app, usando `/usr/bin/perl` entitled. Lê o Now Playing de qualquer fonte e envia transporte. **O comando não tem destinatário**: atua sobre a sessão ativa, sem parâmetro de bundle id.
  2. **AppleScript por app** — onde existe dicionário (Apple Music sim, Amazon Music não): posição real, seek, volume por-app, shuffle/repeat e comando endereçado. Requer permissão de Automação; negada, as capacidades caem sozinhas em runtime.
  No `Amazon Music.app` (`com.amazon.music`) não há seek nem posição: ele ignora o comando de posicionamento do MediaRemote e não publica `elapsedTime` (ver `DECISOES.md`). O que cada player aceita está apurado em `docs/compatibilidade-players.md` — **nada entra lá sem evidência observada**.
- **Build**: Swift Package Manager (alvo executável) + bundle `.app` montado à mão (`Info.plist` com `LSUIElement`) + codesign ad-hoc. Sem Xcode completo (apenas Command Line Tools).
- **Plataforma**: macOS 26+; requer o `Amazon Music.app` oficial instalado.

Dependências e versões fixadas são registradas em `Package.swift`.

## Sessões

Segue o **protocolo global** (`~/.claude/PROTOCOLO-SESSOES.md`): abertura por
`abrir-sessao.sh`, encerramento por `fechar-sessao.sh`, `ESTADO.md` como snapshot de
retomada, métricas de tempo/tokens/custo por `session-usage.py`. Só o que é específico
daqui:

- **Changelog:** `CHANGELOG.md` na raiz (o app não tem changelog embutido).
- **Push:** `git push origin main`.
- **Verificação de qualidade:** `scripts/verificar.sh` roda as três de uma vez —
  `swift build`, as asserções e as traduções. O `fechar-sessao.sh` detecta o
  `Package.swift` e roda **só** o `swift build`, então asserção quebrada e chave de
  tradução faltando passariam batido no encerramento: rodar `scripts/verificar.sh` antes
  de fechar. O bundle `.app` só é montado por `scripts/build-app.sh`, que também não roda
  no encerramento — testar o `.app` é manual, com `docs/roteiro-teste-manual.md`.
- **Suíte de testes:** `swift run MacMediaWidget --run-tests` (sai 0/1). Não é
  `swift test`: as Command Line Tools não trazem XCTest nem swift-testing, então as
  asserções vivem em `SelfTests.swift`, no próprio módulo, sob `#if DEBUG`. Ver
  `DECISOES.md`.
- **Traduções:** `scripts/verificar-traducoes.sh` confere que as chaves do `L10n.swift`
  batem com cada `.lproj`. Rodar sempre que mexer em string de UI — chave errada cai no
  inglês em silêncio.
- **Matriz de players:** `scripts/testar-player.sh <bundle-id> [nome-applescript]`.
  Requer o player tocando uma fila com 3+ faixas, senão o teste de `next` dá falso
  negativo.

## Regras técnicas

- **pt-BR** em explicações, mensagens de commit, comentários voltados ao usuário, arquivos de sessão e `PENDENCIAS.md`. Identificadores de código seguem a convenção da stack (inglês).
- **Acentuação obrigatória** em pt-BR. Nunca substituir caracteres acentuados por ASCII.
- **Sem bajulação**, sinceridade técnica direta.
- **Não inflar escopo**: resolver o pedido, registrar a sessão, parar.
- **Segredos** ficam em `.env` (gitignored). Nunca commitar credenciais.
- **Economia de tokens**: output verboso → arquivo; leitura direcionada quando localizada; varredura ampla → subagente.

## Estrutura de arquivos esperada

```
MacMediaWidget/
├── CLAUDE.md              # este arquivo
├── SESSIONS.md            # índice de sessões (1 linha por sessão)
├── PENDENCIAS.md          # backlog vivo de pendências
├── PENDENCIAS_CONCLUIDAS.md  # histórico arquivado (não ler/escrever sem pedido)
├── CHANGELOG.md           # changelog do projeto
├── README.md              # descrição do projeto
├── .gitignore
├── docs/
│   └── sessions/
│       ├── 2026-06-22-01.md
│       └── ...            # um arquivo por sessão
├── Package.swift          # manifesto SPM (alvo executável)
├── Sources/
│   └── MacMediaWidget/
│       ├── App.swift              # @main, AppDelegate, ciclo de vida (LSUIElement)
│       ├── WidgetWindow.swift     # NSWindow nível desktop, todos os Spaces, não-ativante
│       ├── ContentView.swift      # UI SwiftUI Liquid Glass (condicional por capacidade)
│       ├── NowPlayingController.swift  # stream do Now Playing + roteamento de comando
│       ├── VolumeRouter.swift     # decide entre volume por-app e volume do sistema
│       ├── TrayController.swift   # NSStatusItem (barra de menu)
│       └── Players/
│           ├── Player.swift            # protocolo + PlayerCapabilities
│           ├── MediaRemoteAdapter.swift # caminhos e execução do adapter perl
│           ├── MediaRemotePlayer.swift  # player genérico (só transporte)
│           ├── AmazonMusicPlayer.swift  # sem AppleScript; URL de instalação
│           ├── AppleScriptPlayer.swift  # base da camada AppleScript
│           ├── AppleMusicPlayer.swift   # seek, volume por-app, shuffle/repeat
│           └── PlayerRegistry.swift     # bundle id -> Player
├── Resources/
│   ├── Info.plist          # LSUIElement, bundle id, versão
│   └── mediaremote-adapter/ # framework + perl bundlados (read/comando do Now Playing)
├── scripts/
│   └── build-app.sh        # monta o bundle .app a partir do binário SPM + codesign ad-hoc
└── dist/                   # saída do .app montado (gitignored)
```
