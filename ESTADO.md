# Estado — MacMediaWidget

Última sessão: 2026-08-10 · #01 — Pendências independentes, Fase 1 (multi-player) e Fase 2 (robustez) — concluída

## Próximo passo

Nenhum trabalho de código está bloqueado esperando outro trabalho de código: as Fases 1
e 2 do `ROADMAP.md` estão feitas e os itens da Fase 4 que não dependem de compra também.
O que resta trava em três decisões do dono do produto (ver pendências). Se ele já tiver
resolvido alguma ao retomar, o caminho é direto:

- **Developer Program assinado** → exercitar o pipeline com
  `MMW_SIGN_IDENTITY` / `MMW_NOTARY_PROFILE` em `scripts/build-app.sh`, depois Sparkle.
- **Spotify instalado** → `scripts/testar-player.sh com.spotify.client Spotify` e criar
  `SpotifyPlayer` espelhando `AppleMusicPlayer`, declarando capacidades **só depois** do
  teste.
- **Nome decidido** → Fase 3 (validação de marca, ícone, materiais).

## Pendências abertas (prioridade)

- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4
- [ ] Instalar o Spotify — fecha o critério de saída da Fase 1
- [ ] Testes manuais: tradução pt-BR na tela, arraste da barra no Apple Music, multi-monitor real, automação negada
- [ ] Conferir se "Abrir no login" sobreviveu à troca do bundle
- [ ] Avaliar se `--run-tests` e `verificar-traducoes.sh` entram no `fechar-sessao.sh`

## Decisões vigentes que restringem o trabalho

- **O comando do MediaRemote não tem destinatário** — atua na sessão de Now Playing, sem
  bundle id. Só AppleScript endereça um app. É o fato que sustenta a arquitetura inteira.
- Nada entra na matriz de compatibilidade sem evidência observada: comando aceito sem
  erro ≠ comando funcionando (lição do seek do Amazon Music).
- Idioma-base do código é **inglês** (chave = texto em inglês); pt-BR é tradução.
  Explicação, commit, doc e comentário seguem em pt-BR.
- Testes rodam com `swift run MacMediaWidget --run-tests` — as CLT não têm XCTest nem
  swift-testing, e instalar o Xcode é decisão do dono.
- Em release, o adapter só é aceito do bundle: caminho do brew é gravável sem
  privilégio e viraria execução de código no processo do app.
- Toda área interativa nova da UI precisa de `.nonDraggableWindowArea()`, senão arrasta
  a janela.
- Amazon Music: sem seek, sem posição, sem AppleScript, sem volume por-app.

## Alertas

- **6 commits sem push** até o fechamento desta sessão (o push do encerramento resolve;
  se falhar com 403, é o keychain entregando credencial que não é a `dudivalenza84`).
- `swift build` OK · 53 verificações OK · traduções 37/37 OK.
- O `.app` instalado em `/Applications` está na 1.11.0, igual ao código.
