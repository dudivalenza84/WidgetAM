# CLAUDE.md — MacMediaWidget

Instruções específicas deste projeto para o Claude Code. Tem precedência sobre o `CLAUDE.md` global do usuário e o `CLAUDE.md` da pasta `Pessoal` no que for específico daqui.

## O que é o projeto

Widget de desktop para macOS, com design premium (Liquid Glass), que **controla** o app oficial nativo `Amazon Music.app` via o Now Playing do macOS. O widget não reproduz áudio: o motor de reprodução é o próprio `Amazon Music.app` rodando em background. Uso pessoal individual.

> Virada de arquitetura (2026-06-23 · #01): a abordagem anterior — Electron controlando o PWA no Chrome via AppleScript — foi descartada (a Amazon bloqueia navegador desconhecido e o requisito é não depender do Chrome). Histórico Electron preservado no git.

## Stack

- **Linguagem/UI**: Swift nativo — AppKit (janela widget, tray) + SwiftUI (UI Liquid Glass).
- **Janela**: `NSWindow` em nível de desktop, sem bordas, presente em todos os Spaces, não-ativante, com snap à grade de widgets da mesa.
- **Integração com o player**: `mediaremote-adapter` (fork Swift do `ejbills`) bundlado no app, usando `/usr/bin/perl` entitled para ler o Now Playing (capa, título, artista, progresso, estado) e enviar comandos de transporte (play/pause/next/prev/seek) ao `Amazon Music.app` (`com.amazon.music`).
- **Build**: Swift Package Manager (alvo executável) + bundle `.app` montado à mão (`Info.plist` com `LSUIElement`) + codesign ad-hoc. Sem Xcode completo (apenas Command Line Tools).
- **Plataforma**: macOS 26+; requer o `Amazon Music.app` oficial instalado.

Dependências e versões fixadas são registradas em `Package.swift`.

## Estrutura de governança das sessões

Todo trabalho no projeto é organizado em **sessões**. Cada sessão tem:

- Um arquivo próprio em `docs/sessions/YYYY-MM-DD-NN.md` com objetivo, decisões, arquivos tocados, status. Esse arquivo é apenas um resumo da sessão finalizada e **não** deve ser usado para leitura antes de iniciar a próxima sessão, a não ser que o usuário solicite.
- Uma linha de índice em `SESSIONS.md` apontando para esse arquivo. Não é preciso ler o arquivo inteiro toda sessão, apenas as últimas linhas para identificar a última sessão finalizada e seu resumo.
- Pendências geradas vão para `PENDENCIAS.md` (não ficam diluídas no histórico).
- Toda alteração de código/config é versionada em git. Sem trabalho "fora do git".

`SESSIONS.md` é **apenas índice** — nunca acumula conteúdo de sessão. Isso evita que o arquivo cresça e infle contexto a cada nova sessão lida.

### Identificação e numeração

Toda sessão é identificada por `YYYY-MM-DD · #NN`:
- `YYYY-MM-DD` é a data de abertura.
- `#NN` é um sequencial de dois dígitos, **reiniciado todo dia**.
- Pode haver mais de uma sessão no mesmo dia.
- O sequencial é calculado lendo `SESSIONS.md`: se já houver entrada com a data de hoje, usa `#02`, `#03`, etc.; senão, `#01`.
- Nome do arquivo da sessão: `docs/sessions/YYYY-MM-DD-NN.md` (sem `#`, sem ponto separador).

Use o mesmo identificador (`YYYY-MM-DD · #NN`) em commits de encerramento, referências cruzadas em `PENDENCIAS.md` e qualquer documento auxiliar.

### Protocolo: início de sessão

Quando o usuário iniciar uma sessão (ou retomar trabalho), o Claude deve:

1. **Delegar a leitura inicial a um subagente `Agent` com `model: haiku`.** O subagente lê `SESSIONS.md` (índice) + **apenas o resumo** da última sessão em `docs/sessions/` (objetivo, status, "Decisões aprovadas") + `PENDENCIAS.md` e devolve um resumo consolidado (última sessão concluída, status, decisões, pendências abertas por prioridade). **Não ler o arquivo da última sessão por inteiro** — detalhamento técnico é histórico, fica no git e só se abre sob demanda. Se precisar replicar um padrão técnico, ler os arquivos de código diretamente.
2. Rodar `git status` e `git log -n 5 --oneline` para confirmar o estado real do repo.
3. Calcular o sequencial do dia conforme a regra acima.
4. Confirmar com o usuário o objetivo da sessão antes de criar a nova entrada.
5. Criar o arquivo `docs/sessions/YYYY-MM-DD-NN.md` com cabeçalho `# YYYY-MM-DD · #NN — <objetivo curto>` e status `em-andamento`.
6. Adicionar a linha correspondente no topo de `SESSIONS.md` (dentro do bloco da data).

### Protocolo: durante a sessão

- Atualizar o arquivo da sessão atual apenas na finalização ou se o usuário solicitar.
- Realizar commit apenas no final da sessão, já incluindo os arquivos atualizados de sessões e pendências. Commit durante a sessão apenas se o usuário solicitar ou se aprovar etapa que exija push para rodar fora do local.
- Mensagens de commit em pt-BR, no imperativo: `add`, `fix`, `update`, `remove`, `refactor`, `docs`. Curtas e descritivas.
- Antes de codar, sempre planejar; em caso de dúvida, fazer perguntas curtas e objetivas.
- Na finalização das etapas, apenas informar que concluiu. Se o usuário precisar testar, passar instruções diretas (passo a passo).
- Respostas curtas e objetivas. Sem bajulação, postura profissional.

### Protocolo: finalizar sessão

Quando o usuário disser que quer "finalizar a sessão" (ou "encerrar", "fechar sessão"), executar **na ordem**:

1. **Fechar o arquivo da sessão** em `docs/sessions/YYYY-MM-DD-NN.md` com:
   - Resumo do que foi feito (bullets objetivos).
   - Decisões técnicas relevantes (resumidas).
   - Nomes dos arquivos principais alterados/criados.
   - Status final (`concluída` ou `parcial`).
2. **Atualizar `SESSIONS.md`**: ajustar o status na linha de índice (`em-andamento` → `concluída`/`parcial`).
3. **Atualizar `PENDENCIAS.md`**: marcar pendências resolvidas trocando `[ ]` por `[x]` na própria linha (manter a linha), adicionar novas pendências, ajustar prioridades. **Não migrar pra `PENDENCIAS_CONCLUIDAS.md` nem ler esse arquivo** — migração só quando o usuário pedir explicitamente.
4. **Atualizar changelog**: adicionar entrada no topo de `CHANGELOG.md` (raiz) com versão semver (MINOR por release cronológica, PATCH só pra hotfix), data, identificador da sessão, título e resumo curto.
5. **Verificar estado do git**: `git status` — não pode sobrar alteração relevante fora de commit.
6. **Commitar tudo**: se houver alterações pendentes, criar commit final com mensagem do formato:
   ```
   docs: encerra sessão YYYY-MM-DD #NN — <objetivo curto>
   ```
7. **Push para origin/main**: `git push origin main`. Se houver divergência, alertar e perguntar antes de qualquer reset/force.
8. Reportar ao usuário: hash do commit final, informando que finalizou. Sem se despedir.

**Não delegar a finalização em si.** Os passos dependem do contexto da sessão, que vive no agente principal — fazer direto.

**Importante**: o Claude não decide sozinho nem sugere encerrar a sessão. Só executa o protocolo quando o usuário pede.

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
