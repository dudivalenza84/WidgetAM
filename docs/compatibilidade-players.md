# Matriz de compatibilidade por player

Levantada com `scripts/testar-player.sh` em **2026-08-10 · #01**, em macOS 26.5.2 com
`media-control` 0.7.6. Ampliada em **2026-08-20 · #02** (Spotify, TIDAL, Deezer e navegador).

Regra desta tabela: **só entra o que foi observado**. Não há célula preenchida por
dedução, por documentação do fabricante ou por "o comando não deu erro". O motivo está em
`DECISOES.md · 2026-08-05 · #02`: o `Amazon Music.app` aceita o seek do MediaRemote e o
ignora — quem olhasse só o código de retorno teria escrito "funciona".

Legenda: **sim** = observado funcionando · **não** = observado não funcionando ·
**ausente** = o mecanismo nem existe · **?** = não testado (o roteiro está no fim).

## Tabela

| Capacidade | Amazon Music | Apple Music | Spotify | TIDAL | Deezer | Navegador |
|---|---|---|---|---|---|---|
| Aparece como sessão de Now Playing | sim | sim | sim | sim | sim | sim |
| Metadados (título, artista, capa) | sim | sim | sim | sim | sim | sim⁵ |
| `elapsedTime` no stream | **não** | sim | sim¹ | sim¹ | **sim⁴** | **não confiável⁶** |
| play/pause (MediaRemote) | sim | sim | sim | sim | sim | **sim** |
| next/previous (MediaRemote) | sim | sim | sim | sim | next sim / **prev não** | **next não / prev rebobina⁷** |
| seek (MediaRemote) | **não** | sim | **sim** | **sim** | **não** | **sim** |
| AppleScript | **ausente** | sim | **sim** | **ausente** | **ausente** | **ausente** |
| posição real (AppleScript) | ausente | sim | sim | ausente | ausente | ausente |
| seek (AppleScript) | ausente | sim | sim | ausente | ausente | ausente |
| volume por-app | ausente | sim | sim² | ausente | ausente | ausente |
| shuffle / repeat (AppleScript) | ausente | sim | sim³ | ausente | ausente | ausente |
| comando endereçado (sem ser a sessão) | **não** | sim | **sim** | **não** | **não** | não |

## Evidência

¹ O `elapsedTime` do TIDAL e do Spotify **não é um relógio**: é uma âncora reemitida em eventos
(início de faixa e depois de um seek). Entre eventos o valor fica parado, e o consumidor
precisa estimar por tempo de parede a partir do `timestamp` que veio junto.

² O `sound volume` do Spotify **funciona, com quantização**: `0→0` e `100→100`, mas todo
valor intermediário volta `n-1` (pedido 42 lê 41; 63 lê 62; 77 lê 76). Consequência para
o código: quem gravar e reler para confirmar vai concluir que falhou, e um slider que
exiba o valor lido recua 1 ponto a cada ajuste. Tratar como sucesso qualquer leitura
dentro de ±1 do pedido.

³ São `shuffling` e `repeating`, **não** `shuffle enabled` / `song repeat` do Apple Music.
O `scripts/testar-player.sh` usa o vocabulário do Apple Music e por isso reportou *não
existe* com `syntax error (-2740)` — falso negativo do roteiro, não ausência no app.

⁵ Do navegador vêm o título do vídeo e o canal no lugar do artista (`'Sabrina Carpenter
- Espresso'` / `'SabrinaCarpenterVEVO'`).

⁶ **O payload do navegador mente, e não só na posição.** `elapsedTime` fica em `0` com o
`timestamp` congelado enquanto o vídeo corre, e só se atualiza depois de um seek. O campo
`playing` também erra: houve leitura de `playing=True` com o vídeo comprovadamente
pausado. Consequência direta: para fonte de navegador, o widget não pode confiar em
`playing` nem em `elapsedTime` — e ancorar a posição no campo mostraria sempre zero.

⁷ `nextTrack` não tem efeito. `previousTrack` **rebobina o vídeo atual** para o início
(`t=114` → `t=0`) em vez de trocar de mídia.

⁴ O Deezer é o **único do lote cujo `elapsedTime` é um relógio de verdade**: avança
sozinho, com o `timestamp` acompanhando. Cinco leituras em 12 s sem tocar em nada:
96,2 → 99,4 → 102,6 → 104,7 → 107,9, deltas batendo com o tempo real. Para ele, ancorar
a posição no campo do stream dispensa qualquer estimativa.

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

### Spotify (`com.spotify.client`)

Levantado em **2026-08-20 · #02**, com conta logada e faixas completas (178–196 s).

```
sessão MediaRemote     | verificado   | bundleIdentifier=com.spotify.client
posição (MediaRemote)  | verificado   | elapsedTime=0.006
next (MediaRemote)     | verificado   | 'Coração Partido - Ao Vivo' -> 'Mais do Mesmo - Ao Vivo'
previous (MediaRemote) | verificado   | 'Mais do Mesmo - Ao Vivo' -> 'Coração Partido - Ao Vivo'
play/pause (MR)        | verificado   | playing True -> False
posição real (AS)      | verificado   | player position=6.050000190735
seek (AS)              | verificado   | set 30 -> leu 31.061000823975
seek (MediaRemote)     | verificado   | teste observável, abaixo
volume por-app (AS)    | verificado   | escala mapeada, abaixo
shuffling (AS)         | verificado   | false -> set true -> leu true
repeating (AS)         | verificado   | false -> set true -> leu true
comando endereçado     | verificado   | teste com outra sessão, abaixo
```

**Seek do MediaRemote, teste observável:** numa faixa de 178,5 s, pedido para 172,52 s —
o `elapsedTime` foi a 172.52 e a faixa **trocou 5 segundos depois**. Real, não ignorado.

**Volume:** `set sound volume` conferido em 8 pontos — `0→0`, `10→9`, `25→24`, `42→41`,
`50→49`, `63→62`, `77→76`, `100→100`. Monotônico e efetivo; ver nota ².

**Comando endereçado:** com o **Apple Music** tocando e dono da sessão
(`bundleIdentifier=com.apple.Music`), `tell application "Spotify" to play` fez o Spotify
voltar a tocar, e o Apple Music **continuou tocando**. Os dois simultâneos é a prova de
que o comando teve destinatário — é o que habilita o modo fixo com o Spotify escolhido.

O Spotify é, junto com o Apple Music, o mais capaz da lista: aceita tudo o que o widget
sabe fazer, e o seek por dois caminhos independentes.

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

### Deezer (`com.deezer.deezer-desktop`)

Levantado em **2026-08-20 · #02**, com faixas completas (177–187 s).

```
sessão MediaRemote     | verificado   | bundleIdentifier=com.deezer.deezer-desktop
posição (MediaRemote)  | verificado   | elapsedTime contínuo — ver nota ⁴
next (MediaRemote)     | verificado   | 'Só Eu Senti (Ao Vivo)' -> 'Termina Comigo Antes Ao Vivo'
previous (MediaRemote) | NÃO FUNCIONA | teste dedicado, abaixo
play/pause (MR)        | verificado   | playing True -> False
AppleScript            | não existe   | app sem dicionário (NSAppleScriptEnabled ausente)
seek (MediaRemote)     | NÃO FUNCIONA | teste observável, abaixo
```

**`previous` não funciona, e não é o caso de "reinicia a faixa atual".** Com a faixa em
42,8 s — bem fora da janela em que um player costuma reiniciar em vez de voltar —, o
comando não trocou de faixa nem zerou a posição: o tempo apenas seguiu correndo para
46,0 s. Sem efeito nenhum.

**Seek ignorado, sem ambiguidade.** Numa faixa de 187,4 s tocando em 61,4 s, pedido para
179,38 s (8 s antes do fim): a posição continuou subindo 1 s por segundo por 13 segundos
(62,4 → 74,9) e a faixa não trocou. Como aqui o `elapsedTime` é um relógio real, nem o
valor publicado se mexeu — é o mesmo desfecho do Amazon Music, por evidência mais direta.

**Armadilha de medição, registrada porque custou uma bateria inteira:** a primeira rodada
saiu inválida porque o Spotify ficou tocando em paralelo e **tomou a sessão no meio do
teste**. Os comandos do MediaRemote foram para ele, e o `next` do "Deezer" apareceu
levando a uma faixa que era do Spotify. Antes de medir um player, os outros precisam
estar **pausados** — não basta estarem em segundo plano.

### Navegador — Google Chrome (`com.google.Chrome`)

Levantado em **2026-08-20 · #02**, com vídeo do YouTube em playlist.

```
sessão MediaRemote     | verificado   | bundleIdentifier=com.google.Chrome
metadados              | verificado   | title='Sabrina Carpenter - Espresso', artist='SabrinaCarpenterVEVO'
togglePlayPause (MR)   | verificado   | tocando -> PAUSADO -> tocando (observado na página)
pause / play (MR)      | verificado   | PAUSADO / tocando (observado na página)
seek (MediaRemote)     | verificado   | pedido 45 s -> currentTime do <video> em 45 s
nextTrack (MR)         | NÃO FUNCIONA | vídeo seguiu correndo, t=110 -> t=114
previousTrack (MR)     | rebobina     | t=114 -> t=0, mesmo vídeo
AppleScript (mídia)    | não existe   | sem dicionário de reprodução
```

**Como esta linha foi medida, e por que o roteiro padrão não serve aqui.** O
`scripts/testar-player.sh` julga o efeito lendo o payload do Now Playing, e no navegador
o payload mente (nota ⁶). Rodado assim, ele reportou `play/pause | NÃO FUNCIONA |
playing continuou True` — quando o vídeo tinha pausado de verdade. A medição válida usou
a **própria página como observador**, lendo `document.querySelector('video')` por
AppleScript:

```
tell application "Google Chrome" to tell tab 1 of window 1 to execute javascript "..."
```

Duas armadilhas nesse caminho, ambas custaram medição: `active tab of window 1` pode não
ser a aba que toca — uma aba vizinha com um `<video>` parado devolve `currentTime=0` para
sempre, e a leitura parece um app quebrado. Varrer as abas e fixar a que tem vídeo
resolve. E `execute javascript ... in tab t of window w` dá `-1723`; a forma que funciona
é `tell tab t of window w to execute javascript`.

**Isto também fecha a identidade de sessão de serviço web** (§3 do desenho, e o Passo 5
da Tarefa 0): o YouTube tocando publica sob `com.google.Chrome`, com o título do vídeo.
Não há bundle id do serviço nem do PWA — quem reproduz é o processo do navegador. O
YouTube Music continua modelado como `.shortcut`, não como `.app`.

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
