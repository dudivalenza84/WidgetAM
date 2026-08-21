# Estado — MacMediaWidget

Última sessão: 2026-08-21 · #03 — Guia executável da auditoria, decisões de produto e plano de execução — concluída

## Próximo passo

**Sessão 1 do plano: virar WidPlay.** Trocar `CFBundleName`, `CFBundleDisplayName` e
`CFBundleIdentifier` (`com.dudivalenza.widplay`) no `Info.plist`, mais o nome do alvo no
`Package.swift`, `scripts/build-app.sh`, README e `CLAUDE.md`. Depois de montar o `.app`,
o usuário apaga o antigo de `/Applications`, remove a entrada antiga em Ajustes ›
Privacidade › Automação, reinstala e reconfigura — a troca de bundle id reseta TCC, item
de login e preferências.

O plano inteiro (nove sessões, ordem e porquê) está no artifact
<https://claude.ai/code/artifact/300b06cd-90ef-4df9-95cf-68d8786bd903>, seção "Ordem de
trabalho"; o índice das sessões está no topo de `PENDENCIAS.md`.

## Pendências abertas (prioridade)

- [ ] **S1 — WidPlay** (tarefa 2): renomear tudo e reinstalar
- [ ] **S2 — testes da ancoragem de posição** (tarefa 21), antes de mexer no coração
- [ ] **S3 — subprocesso com prazo** (tarefa 4): fecha cinco achados; medir consumo antes
- [ ] **Busca de anterioridade de marca "WidPlay"** — não feita, bloqueia o certificado
- [ ] **Registrar `widplay.app`** (livre hoje) — serve de site e de endereço do appcast

## Decisões vigentes que restringem o trabalho

- **Nome: WidPlay, id `com.dudivalenza.widplay`. Só Apple Silicon. macOS 26+.** As duas
  últimas ainda **não estão no código** — a tarefa 3 não foi liberada, então o app segue
  declarando macOS 15.
- **O artifact é a fonte do estado de cada tarefa** (Pode fazer / Entregue / Testado);
  `PENDENCIAS.md` é a fonte do que não tem dono. Não criar uma terceira lista.
- **Ler o artifact antes de retomar**: as autorizações e os comentários do usuário estão
  gravados nele (`Artifact action:read`), não nesta conversa.
- **A auditoria produziu recomendações, não decisões.** Só o que está em `DECISOES.md`
  está decidido; tarefa não marcada como "Pode fazer" não entra.
- **Nenhuma capacidade entra no código sem evidência observada.** Onde o plano e
  `docs/compatibilidade-players.md` divergirem, **manda a matriz**.
- **O widget não afirma o que a fonte não garante**: sem `.streamPosition` não se ancora a
  barra, sem `.reliablePlaybackState` não se diz "tocando" nem se anima a barra.
- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app.
- **O conteúdo do card se contrasta com o card**, não com o tema do sistema.
- Idioma-base inglês; string nova de UI precisa de chave no `pt-BR.lproj` (+ script);
  área interativa nova precisa de `.nonDraggableWindowArea()`.
- Identidade visual é o conceito **Órbita**: na UI usar `BrandMark`, nunca PNG.

## Alertas

- **Verificação: rodar `scripts/verificar.sh`** (build + 148 asserções + traduções). O
  `fechar-sessao.sh` roda **só** `swift build`.
- **Nenhum código mudou nesta sessão** — a 1.17.0 em `/Applications` continua válida.
- Warning pré-existente em `ContentView.swift` (`doubleValue` main actor-isolated) — o
  conserto é anotar o `Coordinator` com `@MainActor`.
- **Um achado alto nunca foi refutado**: os letreiros a 30 Hz (tarefa 8). Refutar ou
  medir antes da S6, em vez de tratar como grave por herança.
- **As afirmações de energia são derivadas do código, não medidas.** Medir com
  `powermetrics` antes da S3 e depois da S6.
- Push: tentar `git push origin main` direto; só usar o contorno com
  `credential.helper=` vazio se aparecer 403 de `DuneeAdmin`.
