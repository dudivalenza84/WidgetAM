# Auditoria de comercialização — MacMediaWidget 1.17.0

**Data:** 2026-08-21 · sessão #02
**Escopo:** o app inteiro — código, concorrência, segurança, performance, UI/UX,
qualidade de engenharia e prontidão para venda.
**Método:** sete auditores independentes em paralelo, cada um obrigado a sustentar
todo achado com arquivo e linha lidos no código; os achados graves passaram por um
verificador adversarial encarregado de refutá-los.
**Resultado:** 76 achados, nenhum crítico. Dos **11 altos** reportados pelos
auditores, **5 sobreviveram** à refutação — os outros 6 foram rebaixados a médio por
impacto inflado. O balanço final é 5 altos, 41 médios e 30 baixos.
**Baseline:** `scripts/verificar.sh` verde — build, 148 asserções e traduções.

O registro integral está em [`auditoria-achados-2026-08-21.md`](auditoria-achados-2026-08-21.md).
Este documento é a leitura: o que os achados significam juntos e em que ordem atacar.

---

## Veredito

O código está bom. **O produto não está pronto para venda** — e o que falta não é
majoritariamente código.

A distância entre "app funcionando" e "app vendável" tem três partes, nesta ordem de
gravidade:

1. **A casca comercial não existe.** Sem canal de atualização, sem EULA, sem política
   de privacidade, sem licenciamento, com DMG não assinado e binário só arm64. O
   `ROADMAP.md` já registra tudo isso — a auditoria confirma que nada foi feito.
2. **O build de venda tem um buraco de segurança que o build atual não tem.** Duas
   entitlements desnecessárias, aplicadas só no caminho Developer ID, reabrem injeção
   de dylib no processo que detém a permissão de Automação.
3. **O modelo de subprocesso é a dívida técnica estrutural do app.** Não é um bug: é
   um padrão repetido em cinco lugares que produz travamento, acúmulo de processos e
   consumo de energia contínuo. Foi o achado que mais dimensões independentes
   encontraram, cada uma por um caminho diferente.

O que a auditoria **não** encontrou merece registro: nenhum crash, nenhum
force-unwrap perigoso, nenhum data race clássico, nenhum vazamento estrutural de
memória, nenhuma injeção de AppleScript por metadado de mídia (a regra de
interpolação segue cumprida), e a cobertura pt-BR está completa e correta. A
disciplina de "capacidade só entra com evidência observada" está honrada no código.

---

## As seis causas-raiz

Os 76 achados não são 76 problemas. São seis, vistos de sete ângulos.

### 1. O modelo de subprocesso (a dívida estrutural)

Todo I/O de subprocesso do app segue o mesmo padrão: código síncrono bloqueante
dentro de `Task.detached`, sem timeout, com pipes que ninguém drena e sem guarda de
chamada em voo. Aparece em `AppleScriptRunner`, `SystemVolumeController`,
`MediaRemoteAdapter.isEntitled()`, nos comandos one-shot do adapter e no poll de
posição.

As consequências, cada uma achada por uma dimensão diferente:

- **Um player travado derruba o widget inteiro.** O poll de posição dispara a cada
  segundo sem verificar se o anterior voltou; cada chamada bloqueia uma thread do
  pool cooperativo do Swift Concurrency (largura = número de núcleos) em
  `waitUntilExit`, e um Apple Event a um app em beachball só falha depois de minutos.
  Com o Apple Music travado, o pool esgota em segundos e todo o trabalho assíncrono
  do app para junto — inclusive os botões de transporte.
- **Falha invisível.** Comandos one-shot ao adapter são dispara-e-esquece: sem
  `terminationHandler`, sem checagem de status, com stderr num pipe descartado. Um
  `next` que o adapter rejeitou vira "apertei e não aconteceu nada", sem uma linha de
  log para o suporte correlacionar.
- **Congelamento silencioso.** O stderr do processo de stream nunca é drenado. Se o
  perl escrever mais que o buffer do pipe, ele bloqueia no `write`, para de emitir e
  **não morre** — então o `terminationHandler` não dispara, a reconexão não roda,
  `health` fica `.healthy` e o widget exibe a última faixa para sempre.
- **`isEntitled()` sem timeout.** Se o perl pendurar na checagem inicial, o stream
  nunca abre e `health` fica em `.starting` — que o código trata como saudável. O
  usuário recebe um card eternamente vazio, exatamente o modo de falha que o enum
  `AdapterHealth` foi criado para eliminar.

O conserto é único e vale para todos: **uma implementação assíncrona de "rodar
subprocesso"** — fila de dispatch própria, `terminationHandler` com
`withCheckedContinuation`, os dois pipes drenados concorrentemente, watchdog com
`terminate()`, e status de saída checado e logado. Substitui as três cópias atuais e
fecha os cinco achados de uma vez.

### 2. Trabalho por tick onde deveria ser por evento (energia)

Um widget residente 24/7 precisa ficar realmente ocioso quando nada toca. Hoje ele
não fica:

- O `progressTimer` de 2 Hz publica `displayedElapsed` **incondicionalmente** — e
  `@Published` emite mesmo quando o valor não mudou. Três hierarquias SwiftUI
  reavaliam o body duas vezes por segundo, para sempre, inclusive com o widget
  oculto.
- O poll de posição faz `fork/exec` de `osascript` **uma vez por segundo mesmo com a
  música pausada**. Com o Apple Music pausado detendo a sessão, são ~86 mil
  processos por dia para reler uma posição que não se move. Este foi mantido em
  severidade alta pelo verificador adversarial.
- Os letreiros rodam a 30 Hz permanentemente — dois no card e um terceiro num item
  de menu **fechado**, animando texto que ninguém vê. O publisher é `let` de struct,
  então cada re-render do pai destrói e recria o timer.
- O `body` do `ContentView` consulta LaunchServices e `NSRunningApplication` a cada
  avaliação (ícone do player, `isRunning`, `isInstalled`), ou seja, várias chamadas
  com IPC por segundo num app parado.

Corrigidos, o app passa a consumir zero quando nada toca. É requisito mínimo de um
utilitário residente pago, e é o tipo de coisa que aparece em review.

### 3. Estado obsoleto: o widget não relê o que mostra

O slider de volume é o controle mais visível do card e exibe estado que nunca é
atualizado. `refresh()` só roda dentro de `retarget()`, e `retarget()` só dispara
quando o **bundle id** do player controlado muda. Dois defeitos daí:

- O usuário mexe no volume pelas teclas do Mac — gesto cotidiano — e o slider
  congela no valor antigo. O próximo clique salta o volume real para o valor
  obsoleto.
- Pior: a decisão de alvo (volume do app vs. do sistema) depende de `isRunning` e das
  capacidades, que mudam **sem** o bundle id mudar. Fechar o player preferido deixa o
  slider apontando para um app que não existe mais — mexe e não controla nada, com o
  tooltip ainda dizendo "Apple Music volume".

A verificação adversarial confirmou o achado e o agravou em dois pontos:

- **No modo fixo, `controlledPlayer` é sempre o preferido** — o bundle id nunca muda,
  então o alvo do volume nunca é reavaliado, em nenhuma circunstância.
- **Com a Automação negada (-1743), o slider morre para sempre.** O comentário em
  `AppleScriptPlayer.swift:157-161` afirma que, nesse caso, "o VolumeRouter passa a
  mexer no volume de saída do sistema por conta própria". Isso não acontece: as
  capacidades rebaixam, mas nada reavalia o alvo — e o volume é **o único comando sem
  fallback para o MediaRemote** (transporte e seek têm `guard !isAuthorizationDenied`,
  o volume não). Diferente do caso do app fechado, este não se autocorrige.

A correção certa não é polling: para o volume do sistema existe listener de CoreAudio
(`AudioObjectAddPropertyListenerBlock`), e para o alvo existem as notificações
`didLaunchApplication`/`didTerminateApplication` do `NSWorkspace`, mais uma
reavaliação após qualquer `-1743`.

### 4. O parser confunde snapshot com diff

`NowPlayingParser` só trata snapshot como substituição no caso 100% vazio. Um
snapshot **com** conteúdo cai no mesmo merge dos diffs, e num snapshot campo ausente
significa "não existe", não "não mudou". Resultado: capa, álbum e duração da faixa
anterior ficam grudados na nova — visível na troca de dono da sessão e em faixas sem
capa. A duração velha ainda contamina a aritmética da barra de progresso.

É a mesma família do bug de produção que motivou o `.reset` em 2026-08-05, resolvida
só para o caso extremo.

### 5. Roteamento de comando com três buracos de UX

- **Fonte oculta:** `playPause()` não passa por `canControlTransport`, então o widget
  pausa o app que o usuário mandou ignorar — e o botão mostra "play" enquanto a ação
  pausa. O `SelfTests` declara o invariante contrário na linha 710.
- **Atalho web:** escolher "YouTube Music" no menu com ele já tocando pausa a música
  do usuário e espera 15 s por uma sessão que o modelo do projeto garante que nunca
  vai existir (o atalho publica como `com.google.Chrome`). A ação resulta em
  silêncio.
- **Play sem auto-launch:** com "abrir ao dar play" desligado, o botão central vira
  no-op silencioso — e nunca é desabilitado. O próprio código formula o princípio
  violado: "botão que não faz nada é pior que botão desligado".

### 6. Nenhuma visibilidade de falha

Somando: linha ignorada não gera log, comando one-shot falho não gera log,
`osascript` com exit ≠ 0 não gera log, e não existe crash reporting nem qualquer
sinal vindo das máquinas dos clientes. Para um produto cuja mitigação declarada do
risco número um é **"resposta rápida"**, descobrir uma quebra em massa por e-mail de
reclamação custa dias exatamente na única situação em que velocidade é o produto.

Não precisa de telemetria invasiva: um botão "Reportar problema" que abra e-mail com
versão do app, versão do macOS e estado do adapter já resolve a maior parte.

---

## Bloqueadores de comercialização

Estes não são bugs — são a diferença entre um app e um produto à venda.

| Bloqueador | Estado | Por que trava a venda |
|---|---|---|
| Canal de atualização (Sparkle) | Inexistente | O `ROADMAP` chama a resposta rápida de "É o produto". Sem Sparkle, o dia em que um update do macOS quebrar o adapter não tem resposta — cada cliente teria que baixar um DMG novo por conta própria. |
| Entitlements dyld | Presentes e desnecessárias | Só se aplicam no build Developer ID, ou seja, **a versão vendida é a vulnerável**, e passa pela notarização com um selo que o binário não honra. |
| DMG | Sem assinatura, notarização ou staple | O artefato que o cliente baixa é a superfície de confiança. Hoje ela não existe. |
| Arquitetura | arm64-only, plist diz macOS 15+ | Um cliente Intel compra e recebe "não é possível abrir". |
| Adapter (`media-control`) | Copiado do brew sem pin nem checksum | Release irreproduzível da peça central; impossível responder "qual versão está no .app do cliente X". O `CLAUDE.md` descreve um `Resources/mediaremote-adapter/` que não existe. |
| Nome "MacMediaWidget" | No `CFBundleIdentifier` | A diretriz de marcas da Apple veda "Mac" incorporado ao nome. Trocar o bundle id depois do lançamento reseta TCC, item de login e preferências de **todos** os clientes. |
| Requisito de sistema | Plist diz 15.0, README diz 26 | Cliente em macOS 15 compra o visual Liquid Glass anunciado e recebe o fallback. |
| EULA, privacidade, licenciamento | Inexistentes | Vender um app cujo mecanismo central é API privada sem limitação de responsabilidade é risco desnecessário. |

Duas coisas estão certas e merecem registro: a decisão de vender fora da App Store
está correta e bem fundamentada (API privada = rejeição automática), e as obrigações
da licença BSD-3-Clause do `mediaremote-adapter` estão cumpridas com rigor raro —
texto integral no bundle, cláusula 3 documentada.

---

## Plano de ação

### Onda 1 — antes de assinar com Developer ID

Coisas que precisam estar certas **antes** de o certificado existir, porque depois
custam migração de clientes.

1. **Remover as duas entitlements dyld.** Manter só
   `com.apple.security.automation.apple-events`. A justificativa no comentário é
   tecnicamente falsa: o hardened runtime não bloqueia `exec` de binário de
   plataforma, e o framework é carregado pelo processo do perl, não pelo do widget.
   Custo: cinco minutos. Risco funcional: nenhum.
2. **Decidir o nome definitivo e o bundle id.** É o único item cujo custo cresce a
   cada cliente vendido.
3. **Alinhar o requisito de sistema** entre `Info.plist`, `Package.swift`, README e
   material de venda. Decidir Intel: universal ou arm64 declarado.

### Onda 2 — a dívida estrutural

4. **Uma implementação assíncrona de subprocesso** com timeout, drenagem dos dois
   pipes e status checado, substituindo as três cópias. Fecha os cinco achados da
   causa-raiz 1.
5. **Guarda de chamada em voo no poll de posição** e gate por `isPlaying` — com poll
   lento na pausa, não ausente, para não perder seek externo.
6. **Coalescência e serialização na escrita de volume**, nos dois caminhos.

### Onda 3 — energia e estado

7. Suspender o `progressTimer` sem reprodução e com o widget oculto; só publicar
   `displayedElapsed` quando o valor mudar.
8. Ligar os letreiros só quando há overflow e a view está visível; descartar as views
   do menu em `menuDidClose`.
9. Cachear ícone e `isRunning` por evento do `NSWorkspace`, tirando LaunchServices do
   `body`.
10. Reavaliar o alvo de volume por evento e reler o valor por listener do CoreAudio.

### Onda 4 — correção e UX

11. Snapshot com conteúdo parte de `TrackInfo()`, não do estado atual.
12. Fonte oculta, atalho web e play sem auto-launch: os três buracos de roteamento.
13. Acessibilidade: rótulos nos controles do card, barra de seek como elemento
    ajustável, `reduce motion` no letreiro. O padrão certo já existe no
    `MenuTransportView` — falta replicar no card, que é o produto.
14. `NSAppleEventsUsageDescription` em `InfoPlist.strings` por idioma — hoje todo
    usuário não-lusófono vê o prompt de permissão em português, no momento de maior
    desconfiança do fluxo.
15. Caminho de recuperação quando a Automação é negada: nota nas Preferências com
    botão que abre o painel certo.
16. Onboarding mínimo (já previsto na Fase 1 do `ROADMAP` e não implementado): o
    padrão hoje é Amazon Music, então quem não o tem recebe, de saída, um alerta
    oferecendo instalar um app que nunca pediu.

### Onda 5 — sustentação

17. Sparkle 2 com appcast e chaves EdDSA fora do repo.
18. Assinar, notarizar e grampear o **DMG**.
19. Pinar ou vendorizar o adapter, com a versão gravada no bundle.
20. Log de diagnóstico e botão "Reportar problema".
21. Testar a ancoragem de posição **antes** do refactor já agendado — extrair a
    decisão para função pura com relógio injetado. É o caminho com mais bugs
    documentados do projeto e tem zero cobertura.
22. EULA, política de privacidade, checkout e chave de licença.

---

## A refutação valeu o custo

Seis dos onze achados altos caíram para médio quando um segundo agente foi
encarregado de derrubá-los. Dois exemplos de por que isso importa:

- **O vazamento de file descriptors não existe.** O achado do `readabilityHandler`
  afirmava que cada queda do stream vazava um fd e deixava um dispatch source
  girando, acumulando ao longo de semanas. O verificador reproduziu o padrão na
  máquina: dez ciclos de spawn/morte, contando fds via `fcntl(F_GETFD)` — **delta
  zero**. O ARC libera `Pipe` → `FileHandle`, o `dealloc` cancela o source e fecha o
  fd. O que sobrou é real mas modesto: o spin de EOF queima ~1 s de um core por
  queda e **não é cumulativo**. O conserto de uma linha foi medido: 1.057.462
  invocações viram 1.
- **A não-determinância do volume não se sustenta.** O achado dizia que o arrasto do
  slider deixava o volume final num valor intermediário. O verificador mostrou que,
  justamente porque o pool satura, o executor despacha FIFO e a última tarefa quase
  sempre termina por último. O defeito real é latência e desperdício, não corrupção
  de valor.

Nos dois casos o bug é real e vale consertar — mas a severidade original teria
distorcido a fila de prioridades.

Uma discordância entre verificadores também vale registro: o achado das entitlements
foi encontrado por dois auditores independentes, e os dois refutadores chegaram a
severidades diferentes — médio pela lente de segurança pura (exploração exige código
local já em execução, e o privilégio herdado é modesto), alto pela lente de
distribuição. A segunda prevalece aqui, e o argumento é o que decide: o build
vulnerável é justamente o que vai para o cliente, notarizado.

## O que ficou de fora

Um dos achados altos — os letreiros a 30 Hz — não chegou a ser refutado; o
verificador correspondente caiu no limite de sessão e não foi reexecutado. Ele está
marcado como **não verificado** no anexo.

A auditoria leu código; não executou o app sob carga nem mediu consumo real com
`powermetrics`. As afirmações de energia são derivadas do código (frequência de
timer, spawn de processo), não medidas — coerente com a regra do projeto de não
afirmar o que não foi observado. Medir antes e depois da onda 3 é o teste honesto.
