# CLAUDE.md — MacMediaWidget

Instruções específicas deste projeto para o Claude Code. Tem precedência sobre o `CLAUDE.md` global do usuário e o `CLAUDE.md` da pasta `Pessoal` no que for específico daqui.

## O que é o projeto

Widget de desktop para macOS, com design premium (Liquid Glass), que **controla** o app oficial nativo `Amazon Music.app` via o Now Playing do macOS. O widget não reproduz áudio: o motor de reprodução é o próprio `Amazon Music.app` rodando em background. Uso pessoal individual.

> Virada de arquitetura (2026-06-23 · #01): a abordagem anterior — Electron controlando o PWA no Chrome via AppleScript — foi descartada (a Amazon bloqueia navegador desconhecido e o requisito é não depender do Chrome). Histórico Electron preservado no git.

## Stack

- **Linguagem/UI**: Swift nativo — AppKit (janela widget, tray) + SwiftUI (UI Liquid Glass).
- **Janela**: `NSWindow` em nível de desktop, sem bordas, presente em todos os Spaces, não-ativante, com snap à grade de widgets da mesa.
- **Integração com o player**: `mediaremote-adapter` (fork Swift do `ejbills`) bundlado no app, usando `/usr/bin/perl` entitled para ler o Now Playing (capa, título, artista, progresso, estado) e enviar comandos de transporte (play/pause/next/prev) ao `Amazon Music.app` (`com.amazon.music`). Não há seek: o app ignora o comando de posicionamento do MediaRemote (ver `DECISOES.md`).
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
- **Verificação de qualidade:** `swift build`. O `fechar-sessao.sh` detecta o
  `Package.swift` e roda sozinho — mas o bundle `.app` só é montado por
  `scripts/build-app.sh`, que **não** roda no encerramento. Testar o `.app` é manual.

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
│       ├── ContentView.swift      # UI SwiftUI Liquid Glass
│       ├── NowPlayingController.swift  # stream/comandos via mediaremote-adapter
│       └── TrayController.swift   # NSStatusItem (barra de menu)
├── Resources/
│   ├── Info.plist          # LSUIElement, bundle id, versão
│   └── mediaremote-adapter/ # framework + perl bundlados (read/comando do Now Playing)
├── scripts/
│   └── build-app.sh        # monta o bundle .app a partir do binário SPM + codesign ad-hoc
└── dist/                   # saída do .app montado (gitignored)
```
