# Auditoria de segurança do app

Feita em **2026-08-10 · #01**, cobrindo o app inteiro e não só o diff da sessão — é o
item de auditoria da Fase 4 do `ROADMAP.md`, pré-requisito para distribuir fora da App
Store.

Escopo: subprocessos (perl e osascript), parsing da entrada do adapter, resolução de
caminhos do bundle, `UserDefaults`, permissões e dados persistidos.

## Resumo

| # | Achado | Gravidade | Situação |
|---|---|---|---|
| 1 | Fallback para `/opt/homebrew` permitia executar script de caminho gravável pelo usuário | **Alta** | corrigido |
| 2 | Acumulador do stream sem teto de tamanho | Média | corrigido |
| 3 | Chave de teste `simulateMissingApp` ativa em release | Baixa | corrigido |
| 4 | Interpolação em AppleScript | — | sem defeito hoje; regra registrada |
| 5 | Capa decodificada de base64 sem validação | Informativo | risco aceito |
| 6 | Posição da janela lida de `UserDefaults` | Informativo | já tratado |

## 1. Execução de script a partir de caminho gravável (Alta) — corrigido

`MediaRemoteAdapter` resolvia o `mediaremote-adapter.pl` e o framework primeiro no
bundle e, se não achasse, em `/opt/homebrew/opt/media-control` (ou `/usr/local` no
Intel). Esse fallback existia para o desenvolvimento, quando se roda o binário solto,
mas ia junto para o binário de release.

**Por que é sério.** No Apple Silicon, `/opt/homebrew` pertence ao usuário comum — não
precisa de `sudo` para escrever lá. Num app distribuído, bastaria que o recurso do
bundle sumisse (bundle corrompido, cópia parcial, remoção manual) para o app executar um
perl daquele caminho. Quem conseguisse plantar um arquivo ali executaria código **dentro
do processo do widget**, herdando o que ele tem: a permissão de Automação sobre os apps
de música e o acesso ao Now Playing. Não é elevação de privilégio no sistema, mas é
execução de código não confiável com as permissões TCC que o usuário concedeu ao app.

**Correção.** Os prefixos do brew agora estão sob `#if DEBUG`. Em release, o único
caminho aceito é o do bundle; faltando o recurso, o subprocesso não inicia, a saúde do
adapter vira `.unavailable` e o usuário é avisado. Falhar visivelmente é o comportamento
seguro.

## 2. Acumulador do stream sem teto (Média) — corrigido

`ingest(_:)` acumulava os bytes do stdout até encontrar `\n`. Como o adapter manda a capa
em base64 na mesma linha do JSON, linhas de centenas de KB são normais — mas não havia
limite algum. Um adapter em pânico despejando bytes sem newline faria o buffer crescer
até o app consumir a memória da máquina.

**Correção.** Teto de 8 MB por linha; ao estourar, o buffer é descartado com log. O
próximo `\n` ressincroniza o stream.

## 3. Chave de teste ativa em release (Baixa) — corrigido

`simulateMissingApp` (`UserDefaults` + variável de ambiente) força o caminho de "app não
instalado". Era lida também em release, ou seja, qualquer processo capaz de escrever no
domínio de preferências do app podia alterar seu comportamento. O efeito prático é
pequeno — um alerta indevido —, mas é superfície sem contrapartida num binário
distribuído. Agora é `false` fora de debug.

## 4. Interpolação em AppleScript — sem defeito hoje

`AppleScriptPlayer.tell` monta `tell application "<nome>" to <corpo>`. Auditado: hoje
`scriptingName` é literal do código (`"Music"`) e todo corpo é constante ou número
formatado (`Int`), nunca texto vindo de fora. Não há injeção possível.

**Regra que fica.** Nada que venha do disco, da rede, de metadados de faixa ou do nome de
um app instalado pode ser interpolado num script. Um `displayName` lido do Finder — que
`Player.localizedName` produz — parece inofensivo, mas um app chamado
`x" to (do shell script "…")--` viraria execução arbitrária. Se um dia for preciso
interpolar valor dinâmico, escapar aspas e barras invertidas antes, ou passar por
parâmetro em vez de concatenação.

## 5. Capa decodificada de base64 (Informativo) — risco aceito

`artworkData` é decodificado e entregue ao `NSImage` sem validar tamanho nem formato. A
origem é o MediaRemote do próprio macOS, mas o conteúdo nasce nos metadados de um app de
terceiros. É a mesma exposição de qualquer app que exibe capa de música, e o parser é o
do sistema. Aceito; o teto de buffer do item 2 já limita o extremo.

## 6. Persistência (Informativo) — já tratado

Só duas coisas são gravadas: preferências e a posição da janela. Nada sensível, nada de
credencial, nenhum dado pessoal. A posição vem de `UserDefaults` como string e é
convertida com `NSPointFromString`, que devolve `.zero` para lixo — tratado como "sem
posição salva". Desde `2026-08-10 · #01` também é validada contra as telas conectadas
antes de ser aplicada.

## O que esta auditoria não cobre

- **Notarização e hardened runtime**: ainda não há Developer ID (Fase 4). Com hardened
  runtime será preciso a entitlement `com.apple.security.automation.apple-events`, e vale
  reavaliar o subprocesso perl sob as restrições dele.
- **Integridade do que é distribuído**: o `.app` é assinado ad-hoc. A verificação real de
  procedência só existe com Developer ID + notarização + staple.
- **Canal de atualização**: quando entrar o Sparkle, o appcast e as chaves EdDSA viram o
  ponto mais sensível do produto — um canal de update comprometido é execução remota de
  código na máquina de todos os clientes. Auditar à parte, na Fase 4.
