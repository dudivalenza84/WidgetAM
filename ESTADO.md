# Estado — MacMediaWidget

Última sessão: 2026-08-05 · #02 — Seek pela UI: provar viabilidade e fechar pendências — concluída

## Próximo passo

Nada em aberto e nada bloqueado — `PENDENCIAS.md` está zerado. O widget está
funcionalmente completo para o uso pretendido, então o próximo trabalho é escolha
nova, não continuação. Candidatos: shuffle/repeat (o adapter expõe os dois comandos,
nunca testados contra o Amazon Music — vale o mesmo método empírico de #02 antes de
prometer o recurso) ou refinamento visual do card.

## Pendências abertas (prioridade)

- (nenhuma)

## Decisões vigentes que restringem o trabalho

- Não há seek: o Amazon Music ignora o comando de posicionamento do MediaRemote
  (comprovado; o QuickTime obedece ao mesmo comando). A barra de progresso é
  indicador, não controle — ver DECISOES.md · 2026-08-05 · #02.
- Posição pós-seek feito dentro do Amazon Music é irrecuperável — não reinvestigar.
  Somada à de cima: o app não expõe posição nem para leitura nem para escrita.
- Arrasto da janela por deny-list: só NSViews reais podem se excluir do arrasto;
  views SwiftUI puras não conseguem (ver DECISOES.md · 2026-08-05 · #01).
- `togglePlayPause` é comando global: nunca enviar sem o Amazon Music rodando.
- Volume é do sistema (global), não por-app: MediaRemote não tem comando de volume.
- O `glassEffect` vai numa camada de fundo, nunca direto na stack.

## Alertas

- `swift build` OK.
- **O `.app` em `/Applications` está na v1.7.0 e não foi remontado.** As mudanças de
  #02 só afetam o `swift run` e o próximo `scripts/build-app.sh` — que é manual e não
  roda no encerramento.
- Antes de prometer qualquer comando novo do adapter (shuffle, repeat, speed),
  testar contra o Amazon Music primeiro: ele aceita o comando sem erro e simplesmente
  o ignora, então "não deu erro" não é evidência de que funcionou.
