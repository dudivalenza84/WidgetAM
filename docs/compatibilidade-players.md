# Matriz de compatibilidade por player

Levantada com `scripts/testar-player.sh` em **2026-08-10 · #01**, em macOS 26.5.2 com
`media-control` 0.7.6. Ampliada em **2026-08-20 · #02** (TIDAL) e nas colunas novas.

Regra desta tabela: **só entra o que foi observado**. Não há célula preenchida por
dedução, por documentação do fabricante ou por "o comando não deu erro". O motivo está em
`DECISOES.md · 2026-08-05 · #02`: o `Amazon Music.app` aceita o seek do MediaRemote e o
ignora — quem olhasse só o código de retorno teria escrito "funciona".

Legenda: **sim** = observado funcionando · **não** = observado não funcionando ·
**ausente** = o mecanismo nem existe · **?** = não testado (o roteiro está no fim).

## Tabela

| Capacidade | Amazon Music | Apple Music | Spotify | TIDAL | Deezer | Navegador |
|---|---|---|---|---|---|---|
| Aparece como sessão de Now Playing | sim | sim | ? | sim | ? | sim |
| Metadados (título, artista, capa) | sim | sim | ? | sim | ? | ? |
| `elapsedTime` no stream | **não** | sim | ? | sim¹ | ? | ? |
| play/pause (MediaRemote) | sim | sim | ? | sim | ? | ? |
| next/previous (MediaRemote) | sim | sim | ? | sim | ? | ? |
| seek (MediaRemote) | **não** | sim | ? | **sim** | ? | ? |
| AppleScript | **ausente** | sim | ? | **ausente** | ? | **ausente** |
| posição real (AppleScript) | ausente | sim | ? | ausente | ? | ausente |
| seek (AppleScript) | ausente | sim | ? | ausente | ? | ausente |
| volume por-app | ausente | sim | ? | ausente | ? | ausente |
| shuffle / repeat (AppleScript) | ausente | sim | ? | ausente | ? | ausente |
| comando endereçado (sem ser a sessão) | **não** | sim | ? | **não** | ? | não |

## Evidência

¹ O `elapsedTime` do TIDAL **não é um relógio**: é uma âncora reemitida em eventos
(início de faixa e depois de um seek). Entre eventos o valor fica parado, e o consumidor
precisa estimar por tempo de parede a partir do `timestamp` que veio junto.

### Amazon Music (`com.amazon.music`)

```
sessão MediaRemote     | verificado   | bundleIdentifier=com.amazon.music
posição (MediaRemote)  | não existe   | payload sem elapsedTime
next (MediaRemote)     | verificado   | 'The Kids Aren't Alright' -> 'We Are The Champions'
previous (MediaRemote) | verificado   | 'We Are The Champions' -> 'The Kids Aren't Alright'
play/pause (MR)        | verificado   | playing True -> False
AppleScript            | não existe   | sem NSAppleScriptEnabled, sem .sdef
```

O seek saiu como *indeterminado* nesta rodada — sem `elapsedTime` publicado, o script não
tem o que comparar. Não é dúvida em aberto: `DECISOES.md · 2026-08-05 · #02` já provou que
não funciona, por teste observável (seek para 5s antes do fim, com o app tocando; a faixa
não terminou nem avançou, em duas faixas distintas).

### Apple Music (`com.apple.Music`)

```
sessão MediaRemote     | verificado   | bundleIdentifier=com.apple.Music
posição (MediaRemote)  | verificado   | elapsedTime presente no payload
play/pause (MR)        | verificado   | playing True -> False
next/previous (MR)     | verificado   | 'Don't Lie' -> 'Born Too Slow' -> 'Brisa' -> volta
posição real (AS)      | verificado   | player position=15.296999931335
seek (AS)              | verificado   | set 30 -> leu 31.062000274658
seek (MediaRemote)     | verificado   | pediu 209,1s -> elapsedTime=209.062
volume por-app (AS)    | verificado   | set 42 -> leu 42 (era 100)
shuffle (AS)           | verificado   | false -> true
repeat (AS)            | verificado   | off -> all
```

É o player mais capaz da lista: tudo o que o widget sabe fazer, ele aceita — e por dois
caminhos independentes no caso do seek.

### TIDAL (`com.tidal.desktop`)

Levantado em **2026-08-20 · #02**.

```
sessão MediaRemote     | verificado   | bundleIdentifier=com.tidal.desktop
posição (MediaRemote)  | verificado   | elapsedTime=0.25261
next (MediaRemote)     | verificado   | 'Wanna Be Startin' Somethin'' -> 'The Way You Make Me Feel'
previous (MediaRemote) | verificado   | 'The Way You Make Me Feel' -> 'Wanna Be Startin' Somethin''
play/pause (MR)        | verificado   | playing True -> False
AppleScript            | não existe   | app sem dicionário (NSAppleScriptEnabled ausente)
seek (MediaRemote)     | verificado   | teste observável, abaixo
```

**O seek foi confirmado pelo teste observável**, não pelo código de retorno — é a
armadilha do Amazon Music, que aceita e ignora. Numa faixa de 30,0 s, pedido de posição
para 25,99 s: o `elapsedTime` passou a 25.99 imediatamente e a faixa **trocou 5 segundos
depois**, não 30. Duas evidências independentes na mesma medição.

Sobre o `elapsedTime` ser âncora e não relógio, medido no `stream`: com música tocando,
chega **uma linha por faixa** (`'Smooth Criminal'` 13:11:40 → `'Human Nature'` 13:12:10),
cada uma com `elapsedTime` ≈ 0,2 e o `timestamp` do início. Cinco leituras de
`media-control get` em 8 s devolveram o mesmo `0.252425` com o mesmo `timestamp`. Depois
de um seek, porém, o valor foi reemitido como 25.99 — é o que justifica ancorar no campo
em vez de assumir zero.

> **Condição da medição:** conta **não logada**, reproduzindo prévias de 30 s. Transporte,
> seek e o formato do `elapsedTime` são comportamento do canal MediaRemote e não dependem
> do conteúdo, mas as células desta coluna não foram reconferidas com faixas completas.
> `volume por-app` e `shuffle/repeat` estão como *ausente* por não haver AppleScript —
> essa é uma ausência de mecanismo, independente de login.

## Comportamento do sistema (não é de nenhum player específico)

Observado no mesmo levantamento, e vale para o desenho do widget:

- **Encerrar o app que detém a sessão devolve a sessão ao anterior.** Com `quit` no Apple
  Music, o Amazon Music voltou a ser o Now Playing, tocando, sem intervenção. É por isso
  que o widget não precisa de lógica de "reassumir".
- **Só há uma sessão.** Com Apple Music e Amazon Music abertos, quem começou a tocar por
  último ficou com ela. Enquanto o Apple Music estava aberto e parado, o Amazon manteve
  a sessão.
- **QuickTime Player toca sem publicar Now Playing.** Com o QuickTime reproduzindo
  (`playing = true`, posição 115s pelo próprio AppleScript dele), o `get` do adapter
  retornou `null` — nenhuma sessão. Ou seja: **áudio tocando no Mac não implica sessão de
  Now Playing**, e o widget vai mostrar "nada tocando" corretamente nesses casos. O teste
  de comandos contra ele ficou inconclusivo: o documento se fechou no meio da bateria.

## Armadilha de teste: o falso negativo do `next`

Na primeira rodada o Apple Music acusou **next/previous não funcionam**. Era artefato: o
teste começou com `play track 1`, que monta uma fila de uma faixa só — não havia próxima
para onde ir. Repetindo com `play library playlist 1`, os dois comandos funcionaram na
hora. O script hoje avisa disso em comentário, mas **quem rodar precisa garantir uma fila
com pelo menos três faixas**.

## O que falta testar

| Alvo | Por que não foi feito | Como fazer |
|---|---|---|
| **Spotify** | não instalado nesta máquina | instalar, tocar uma playlist com 3+ faixas, `scripts/testar-player.sh com.spotify.client Spotify` |
| **Deezer** | não instalado; e falta decidir se entra no escopo | idem, com o bundle id do app |
| **Navegador (YouTube)** | exige **um clique humano**: autoplay com som é bloqueado, e mandar a página tocar por Apple Events depende da opção "Permitir JavaScript de Apple Events" do menu Desenvolvedor, ligada à mão — inviável como recurso de produto e desnecessário como teste | abrir o vídeo, dar play manualmente e rodar `scripts/testar-player.sh com.google.Chrome` |
| **Gesto de arraste na barra do widget** | a mecânica do seek está verificada por AppleScript, mas o gesto em si é interação de UI | com o Apple Music tocando, arrastar a barra do widget e conferir se a faixa pula |
| **Automação negada** | exige revogar a permissão em Ajustes do Sistema | negar em Privacidade › Automação e conferir se o widget rebaixa as capacidades (barra deixa de ser arrastável, volume volta ao do sistema) |
