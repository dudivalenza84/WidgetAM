# Estado — MacMediaWidget

Última sessão: 2026-08-11 · #02 — Verificar toggle do atalho global ⌃⌥⌘M — concluída

## Próximo passo

Nenhuma mudança de código nesta sessão: o toggle do ⌃⌥⌘M (2º aperto rebaixa) já
existia e foi validado ao vivo (nível da janela medido por CGWindowList alternando
`.floating` ↔ nível de mesa). Se o usuário reproduzir a "falha" com uma janela
cobrindo o widget e ainda discordar do comportamento, o ajuste é em
`WidgetWindow.bringToFront()` / `windowDidResignKey`.

O que resta trava nas mesmas três decisões de produto:

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

- Nenhum. `swift build` OK. Sem mudança de código nesta sessão; o `.app` de
  `/Applications` segue na 1.12.0, igual ao código, rodando.
