# Estado — MacMediaWidget

Última sessão: 2026-08-13 · #01 — Menu: largura fixa com letreiro + auto-fechamento em 2 s — concluída

## Próximo passo

Confirmar visualmente na 1.15.0 (já instalada e rodando em `/Applications`) que o
letreiro do nome da música roda com uma faixa de nome longo — validado só por
instrumentação nesta sessão (offset avançando com o menu aberto), depois de corrigir
um bug em que o `NSHostingView` dentro de `NSMenu` ignorava a largura do frame e o
letreiro nunca via overflow (ver `DECISOES.md` · 2026-08-13 · #01). Tamanho fixo do
menu e auto-fechamento com hover-off já foram validados ao vivo pelo usuário.

## Pendências abertas (prioridade)

- [ ] Confirmar visualmente o letreiro rodando na 1.15.0
- [ ] Testar manualmente o resto da 1.14.0 (ícone Finder, glifo bandeja, Preferências, marca-d'água)
- [ ] Testar manualmente o formato compacto 1×1 (v1.13.0)
- [ ] Instalar o Spotify — fecha o critério de saída da Fase 1
- [ ] Assinar o Apple Developer Program (US$ 99/ano) — gargalo do resto da Fase 4

## Decisões vigentes que restringem o trabalho

- **O comando do MediaRemote não tem destinatário** — só AppleScript endereça um app.
- Amazon Music: sem seek, sem posição, sem AppleScript, sem volume por-app.
- View custom em `NSMenuItem`: largura vai explícita na `View`, nunca só no
  `NSHostingView.frame` — dentro de `NSMenu` o hosting ignora o frame e faz layout
  pelo tamanho ideal do conteúdo.
- Idioma-base inglês; string nova de UI precisa de chave no `pt-BR.lproj` (+ script);
  área interativa nova precisa de `.nonDraggableWindowArea()`.
- Identidade visual é o conceito **Órbita**: mudou SVG em `Resources/icon/` → rodar
  `scripts/gerar-icones.sh`; na UI usar `BrandMark`, nunca PNG.

## Alertas

- Nenhum. `swift build` OK, 53 asserções OK. `.app` de `/Applications` na 1.15.0,
  igual ao código, rodando.
