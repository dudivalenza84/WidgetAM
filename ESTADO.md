# Estado — MacMediaWidget

Última sessão: 2026-08-21 · #01 — Roteiro de aceitação, oito bugs achados nele, e a dívida técnica — concluída

## Próximo passo

Ancorar a posição em **`elapsedTime + (agora − timestamp)`**, em vez do relógio local
(`NowPlayingController.handleLine`, ramo do `.streamPosition`). O par que o MediaRemote
publica é "posição medida **no instante** timestamp", e o widget hoje ancora com `Date()`.
Medido no Safari: a conta certa reconstrói a posição com **menos de 1 s de erro** em três
leituras. Vale para TIDAL, Spotify e Deezer, e destrava `.streamPosition` para o Safari.
Mexe no coração do controller — pede nova rodada do bloco 02 de
`docs/roteiro-teste-manual.md` depois.

## Pendências abertas (prioridade)

- [ ] Ancorar por `elapsedTime + (agora − timestamp)` — o próximo passo acima
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — único bloqueio do resto da Fase 4
- [ ] Migrar `SelfTests.swift` para swift-testing **se** o Xcode entrar no projeto

## Decisões vigentes que restringem o trabalho

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
- A **1.17.0 está instalada** em `/Applications` e validada pelo roteiro inteiro.
- Warning pré-existente em `ContentView.swift` (`doubleValue` main actor-isolated).
- Grafo em 3/5 no contador — sem `graphify update` nesta sessão, por desenho.
