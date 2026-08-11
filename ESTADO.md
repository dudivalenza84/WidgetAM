# Estado — MacMediaWidget

Última sessão: 2026-08-11 · #01 — Interações do widget: duplo clique, menu de contexto, trocar app, sempre no topo, atalho global — concluída

## Próximo passo

Nenhum trabalho de código bloqueado por outro código. As interações novas (1.12.0)
estão instaladas e validadas pelo dono. O que resta trava nas mesmas três decisões de
produto:

- **Developer Program assinado** → exercitar `MMW_SIGN_IDENTITY` / `MMW_NOTARY_PROFILE`
  em `scripts/build-app.sh`, depois Sparkle.
- **Spotify instalado** → `scripts/testar-player.sh com.spotify.client Spotify` e criar
  `SpotifyPlayer` espelhando `AppleMusicPlayer`, capacidades **só depois** do teste.
- **Nome decidido** → Fase 3 (validação de marca, ícone, materiais).

## Pendências abertas (prioridade)

- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4
- [ ] Instalar o Spotify — fecha o critério de saída da Fase 1
- [ ] Conferir se "Abrir no login" sobreviveu às trocas do bundle (2026-08-10 e 08-11)
- [ ] Testar retorno automático do nível elevado por ⌃⌥⌘M ao clicar em outro app
- [ ] Testes manuais pendentes: tradução pt-BR na tela, arraste da barra no Apple
  Music, multi-monitor real, automação negada

## Decisões vigentes que restringem o trabalho

- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app.
- Nada entra na matriz de compatibilidade sem evidência observada.
- Idioma-base do código é **inglês**; pt-BR é tradução (42 chaves, verificadas por script).
- "Trocar app" no menu troca o preferido **e abre o app**; atalho global é fixo (⌃⌥⌘M,
  Carbon) e a elevação que ele causa é temporária, separada da preferência `keepAbove`.
- Toda área interativa nova da UI precisa de `.nonDraggableWindowArea()`.
- Amazon Music: sem seek, sem posição, sem AppleScript, sem volume por-app.

## Alertas

- Nenhum. `swift build` OK · 53 verificações OK · traduções 42/42 OK.
- O `.app` de `/Applications` está na 1.12.0, igual ao código, rodando.
