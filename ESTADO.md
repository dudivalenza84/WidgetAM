# Estado — MacMediaWidget

Última sessão: 2026-08-21 · #02 — Auditoria completa pré-comercialização (ultracode) — concluída

## Próximo passo

O usuário está lendo o relatório da auditoria e vai voltar para conversar — **a conversa
decide o que entra primeiro**, não abrir trabalho por conta própria. Relatório em
`docs/auditoria-comercializacao.md` (síntese, seis causas-raiz, plano em 5 ondas) e
`docs/auditoria-achados-2026-08-21.md` (os 76 achados com evidência).

Se ele mandar começar sem discutir, o primeiro item é **remover as duas entitlements
dyld** de `Resources/MacMediaWidget.entitlements`: cinco minutos, risco funcional
nenhum, e é o único achado alto cuja correção não depende de decisão de produto.

## Pendências abertas (prioridade)

- [ ] **Onda 1 — antes de assinar com Developer ID**: entitlements dyld, nome/bundle id
  definitivo, requisito de sistema coerente. Depois do certificado, custam migração
  forçada de todos os clientes
- [ ] **Onda 2** — uma implementação assíncrona de subprocesso (fecha cinco achados)
- [ ] **Onda 3** — o app não fica ocioso quando nada toca
- [ ] Ancorar a posição por `elapsedTime + (agora − timestamp)` — **e cobrir com teste
  antes**, porque o bloco de reancoragem tem zero cobertura
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — segue bloqueando o resto da Fase 4

## Decisões vigentes que restringem o trabalho

- **A auditoria produziu recomendações, não decisões.** Nada dela foi registrado em
  `DECISOES.md` — o usuário ainda não decidiu. Não tratar as ondas como aprovadas.
- **Nenhuma capacidade entra no código sem evidência observada.** Onde o plano e
  `docs/compatibilidade-players.md` divergirem, **manda a matriz**.
- **O widget não afirma o que a fonte não garante**: sem `.streamPosition` não se ancora a
  barra, sem `.reliablePlaybackState` não se diz "tocando" nem se anima a barra.
- **O observador de um teste tem que ser do domínio do player.** Para navegador, é a
  página via JavaScript — e o `scripts/testar-player.sh` já escolhe sozinho pelo bundle id.
- **Uma fonte pode ter identidade dupla:** o Safari publica a sessão sob
  `com.apple.WebKit.GPU` e mora em `com.apple.Safari`; atalhos web separam `catalogID` de
  `bundleIdentifier`.
- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app; e um
  segundo player tocando **toma a sessão no meio de um teste**.
- **`.transport` é só play/pause.** Pular faixa são capacidades separadas.
- **O conteúdo do card se contrasta com o card**, não com o tema do sistema.
- Idioma-base inglês; string nova de UI precisa de chave no `pt-BR.lproj` (+ script);
  área interativa nova precisa de `.nonDraggableWindowArea()`.
- Identidade visual é o conceito **Órbita**: na UI usar `BrandMark`, nunca PNG.

## Alertas

- **Verificação: rodar `scripts/verificar.sh`** (build + 148 asserções + traduções). O
  `fechar-sessao.sh` roda **só** `swift build` — decisão do usuário de não mexer no script
  global — então asserção quebrada passaria batido no encerramento.
- **Nenhum código mudou nesta sessão.** A 1.17.0 instalada em `/Applications` continua
  válida e validada pelo roteiro inteiro; o `CHANGELOG` registra a auditoria sem versão.
- Warning pré-existente em `ContentView.swift` (`doubleValue` main actor-isolated) —
  agora com pendência própria, e o conserto é anotar o `Coordinator` com `@MainActor`.
- **Um achado alto não foi refutado**: os letreiros a 30 Hz. O verificador caiu no limite
  de sessão e não foi reexecutado — está marcado como não verificado no anexo.
- Grafo em 4/5 no contador — sem `graphify update` nesta sessão, por desenho.
- A nota final de `PENDENCIAS.md` diz "não há `ROADMAP.md` no repositório", mas há —
  a linha ficou velha e não foi corrigida para não inflar o escopo do encerramento.
