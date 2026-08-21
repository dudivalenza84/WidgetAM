# Roteiro de teste manual — 1.17.0

Aceitação da 1.17.0 (players adicionais) **e** da 1.16.0 (visibilidade por app), que
nunca foi testada ao vivo. Executar inteiro antes do próximo bump de versão.

> Versão executável, com os itens clicáveis e progresso salvo no navegador:
> https://claude.ai/code/artifact/569417ae-075b-4f68-a72a-49408a59d0dd
> Este arquivo é a fonte; a página é um espelho para usar durante o teste.

Nada aqui repete o que as 100 asserções de `swift run MacMediaWidget --run-tests` já
cobrem. Cada item existe porque só a tela, o app real ou a permissão do sistema
respondem — é o outro lado do gate de evidência do projeto.

**Tempo estimado:** 35–50 min com todos os apps instalados. Os blocos são independentes:
dá para parar no fim de qualquer um e retomar depois.

---

## Três regras que invalidam o teste se forem quebradas

1. **Um player tocando por vez.** Quem começa a tocar por último fica com a sessão de Now
   Playing. Com dois tocando, o comando vai para o outro app e o resultado sai atribuído
   ao errado — foi assim que uma bateria inteira do Deezer se perdeu. **Pausar** os
   demais; deixar em segundo plano não basta.
2. **Fila com 3 faixas ou mais.** Com uma faixa só, "próxima" não tem para onde ir e um
   recurso que funciona parece quebrado. Tocar playlist ou álbum, nunca faixa avulsa.
3. **Onde o roteiro manda olhar o app, olhe o app.** O widget lê o Now Playing, e no
   navegador o Now Playing mente. Quem confere pela própria tela do widget testa o widget
   contra ele mesmo.

Anote qualquer coisa fora do esperado — **não conserte nada durante o teste**. O que
aparecer vira linha em `PENDENCIAS.md` depois.

---

## 00 — Preparação

- [ ] **Sair da versão instalada.** Menu da bandeja (ícone na barra) → **Sair**. Duas
      instâncias disputando a mesma janela dão sintoma que não é de nenhuma das duas.
- [ ] **Montar e instalar:**

      ```bash
      cd "/Users/dudivalenza/Projetos IA/Pessoal/MacMediaWidget"
      scripts/build-app.sh
      open dist/                       # arrastar para /Applications, substituindo
      ```

      Abrir pelo **Finder**, não por `open` no terminal: assim o LaunchServices garante
      instância única e o app herda a sessão gráfica normal.

      > O `xattr -dr com.apple.quarantine` **não** entra aqui. Bundle montado localmente
      > não tem quarentena para remover, e o comando ainda falha com *permission denied* no
      > `mediaremote-adapter.pl` (que vem com permissão 555). Ele só faz sentido para um
      > `.app` vindo de DMG ou download.

- [ ] **Confirmar a versão:** bandeja → **Preferências…** → o cabeçalho diz
      **Versão 1.17.0**.
      > Se disser 1.15.0, o app antigo continua rodando e **todo o resto do roteiro é
      > inválido**. Voltar ao primeiro passo.
- [ ] **Permissão de Automação:** na primeira vez que o widget mandar um comando para
      Apple Music ou Spotify, o macOS pergunta. **Permitir** — o Bloco 5 testa
      justamente o caminho de negar, e depois.

---

## 01 — Fumaça (2 min)

- [ ] O card aparece na mesa, sem alerta e sem janela extra.
- [ ] Sem nada tocando, o card diz **"Nada tocando"**.
- [ ] Arrastar o card pela área vazia move a janela; ele alinha à grade ao soltar.
- [ ] `⌃⌥⌘M` traz o widget à frente; de novo devolve ao nível da mesa.
- [ ] Duplo clique no card abre o player.

> Se o card ficar vazio para sempre **com música tocando**, olhar a mensagem: "O macOS não
> está permitindo a leitura do que está tocando" é falha estrutural do mecanismo, não do
> widget. Anotar e parar — o resto do roteiro depende da leitura.

---

## 02 — Um player por vez

O que esperar de cada app (a coluna é a matriz de `docs/compatibilidade-players.md`
transformada em comportamento visível):

| App | play/pause | próxima | anterior | barra anda | arrastar a barra | slider de volume |
|---|---|---|---|---|---|---|
| Amazon Music | sim | sim | sim | sim, estimada | **não** (só leitura) | Volume do sistema |
| Apple Music | sim | sim | sim | sim | **sim** | Volume do Apple Music |
| Spotify | sim | sim | sim | sim | **sim** | Volume do Spotify |
| TIDAL | sim | sim | sim | sim | **sim** | Volume do sistema |
| Deezer | sim | sim | **desligado** | sim | **não** | Volume do sistema |
| Google Chrome | sim | **desligado** | **desligado** | **parada** | **sim** | Volume do sistema |

"Desligado" significa **botão apagado e inclinado a não responder ao clique**, com o
motivo aparecendo ao pousar o mouse: *"O Deezer não aceita este comando"*. Botão que
parece ativo e não faz nada é falha — é exatamente o que a 1.17.0 veio corrigir.

### 1.1 Amazon Music

- [ ] Tocar uma playlist. Card mostra capa, título e artista.
- [ ] Play/pause no widget para e retoma **no app**.
- [ ] Próxima e anterior trocam de faixa no app.
- [ ] A barra avança sozinha e reinicia a cada faixa nova.
- [ ] Arrastar a barra **não faz nada** (aqui isso é o correto: o app ignora o comando).

### 1.2 Apple Music

- [ ] Play/pause, próxima e anterior.
- [ ] A barra bate com o tempo mostrado dentro do app (±1 s).
- [ ] **Arrastar a barra pula a faixa de verdade** — conferir no app, não no widget.
- [ ] Mudar a posição **dentro do app** move a barra do widget em até ~1 s.
- [ ] O slider diz **"Volume do Apple Music"** e mexe só no volume do app (o volume do
      Mac, na barra de menus do sistema, não se move).

### 1.3 Spotify

- [ ] Play/pause, próxima e anterior.
- [ ] Arrastar a barra pula a faixa **no app**.
- [ ] O slider diz **"Volume do Spotify"** e o volume muda no app.
      > **Atenção:** o Spotify devolve o volume 1 ponto abaixo do que recebe (pede 42,
      > lê 41). Se o slider recuar sozinho um passo depois de soltar, é essa quantização
      > já conhecida — anotar como observação, não como bug novo.

### 1.4 TIDAL

- [ ] Play/pause, próxima e anterior.
- [ ] **A barra acompanha a música** (é o recurso novo: o TIDAL não tem AppleScript, a
      posição vem do stream).
- [ ] Arrastar a barra pula a faixa **no app** — o outro recurso novo, seek sem
      AppleScript nenhum.
- [ ] O slider diz **"Volume do sistema"** (o TIDAL não tem volume próprio para o widget).

### 1.5 Deezer

- [ ] Play/pause e próxima funcionam.
- [ ] **"Anterior" aparece desligado**, e o tooltip diz que o app não aceita o comando.
- [ ] A barra acompanha a música com precisão (é o único player cuja posição é um relógio
      de verdade).
- [ ] Arrastar a barra **não faz nada** — correto, o Deezer ignora.

### 1.6 Google Chrome (vídeo do YouTube)

Este é o app que mente: abrir o vídeo numa aba e **dar play com o mouse** (autoplay com
som é bloqueado).

- [ ] Card mostra o título do vídeo, com o canal no lugar do artista.
- [ ] Play/pause do widget pausa e retoma **o vídeo na página**.
- [ ] O botão central mostra o símbolo **duplo** (▶︎❙❙), não play nem pause isolado — o
      widget não sabe o estado e não finge saber.
- [ ] O status no menu da bandeja mostra **só o nome do vídeo**, sem "Tocando" nem
      "Pausado".
- [ ] **Próxima e anterior aparecem desligados.**
- [ ] **A barra fica parada** (não corre sozinha).
- [ ] Arrastar a barra **move o vídeo** — conferir na página.

### 1.7 YouTube Music (atalho)

- [ ] Bandeja → **Trocar app** → **YouTube Music** abre o PWA; se ele estiver quebrado,
      abre `music.youtube.com` no navegador padrão. Qualquer um dos dois passa.
- [ ] Com o YouTube Music tocando, quem aparece como fonte no card é o **navegador** —
      é o esperado: o serviço não tem processo próprio.

---

## 03 — Apps controlados (visibilidade, 1.16.0)

Em **Preferências… → Apps controlados**.

- [ ] Desmarcar um app (que não seja o preferido) → ele some do submenu **Trocar app** e
      do seletor **Player preferido**, na hora, sem fechar a janela.
- [ ] Pôr **esse** app para tocar → o card mostra **"O X está tocando · oculto"** com o
      botão **"Mostrar este app"**, e o botão o traz de volta.
- [ ] O app preferido tem o checkbox travado, com a nota *"o player preferido é sempre
      exibido"*.
- [ ] Desmarcar tudo é impossível: o último visível não se deixa desmarcar.
- [ ] App não instalado aparece na lista com a nota *"não instalado"*, e o YouTube Music
      com *"abre no navegador"*.
- [ ] **Fonte descoberta:** tocar algo no **Safari** (que está fora do catálogo de
      propósito) → ele aparece na lista de apps controlados, abaixo dos conhecidos.
- [ ] **"Esquecer apps descobertos"** limpa essa lista. O botão **só existe enquanto
      houver alguma descoberta** — sem o item acima ele não aparece, e isso é o
      comportamento correto, não uma falha.

---

## 04 — Modo fixo e comando endereçado

Em **Preferências… → Modo de controle → Controlar sempre o player escolhido**.

- [ ] Preferido = **Spotify**, com o **Apple Music tocando**: o play/pause do widget age
      **no Spotify**, e o Apple Music **continua tocando**. Os dois soando ao mesmo tempo
      é a prova de que o comando teve destinatário.
- [ ] Preferido = **Amazon Music** (que não tem AppleScript), com outro app tocando: os
      controles ficam inativos e o card explica — *"O Amazon Music não está tocando"*.
- [ ] Voltar o modo para **Controlar o que estiver tocando** e conferir que o card volta
      a espelhar quem toca.

---

## 05 — Formato, marca e texto (o que só olho humano pega)

- [ ] Trocar **Tamanho do widget** entre Compacto (1×1) e Largo (2×1) ao vivo: layout
      inteiro em ambos, snap à grade funcionando nos dois.
- [ ] Título longo: o letreiro rola e volta, sem cortar no meio nem tremer.
- [ ] **Opacidade do tint** move a tonalização da capa de forma visível.
- [ ] Ícone no Finder, glifo da bandeja e cabeçalho das Preferências com a marca certa.
- [ ] Ler as telas em pt-BR procurando erro de acentuação, texto cortado ou frase que não
      faz sentido no contexto visual.
- [ ] Se houver segundo monitor: mover o widget para ele, desconectar e reconectar — o
      widget precisa reaparecer em posição visível.

---

## 06 — Degradação (fazer por último: mexe em permissão do sistema)

**Automação negada** — é o conserto principal desta versão.

- [ ] Ajustes do Sistema → Privacidade e Segurança → **Automação** → MacMediaWidget →
      **desmarcar Spotify** (ou Música).
- [ ] Com o Spotify tocando: play/pause, próxima e anterior do widget **continuam
      funcionando** (caem para o canal universal). Antes desta versão ficavam mudos.
- [ ] Arrastar a barra **continua movendo a faixa** — o Spotify obedece ao seek pelos dois
      caminhos.
- [ ] O slider passa a dizer **"Volume do sistema"**.
- [ ] **Remarcar a permissão** ao final e conferir que o volume por-app volta (pode exigir
      reabrir o widget).

> **Fora de alcance neste roteiro:** o alerta de "app não instalado" só é acionável no
> binário de desenvolvimento (`MMW_SIMULATE_MISSING_APP=1 swift run MacMediaWidget`) — o
> `.app` é compilado em release e a chave de simulação não existe nele, de propósito.

---

## 07 — Folha de resultado

Para cada item fora do esperado, anotar as cinco coisas que tornam o problema
reproduzível — sem elas, o relato vira adivinhação depois:

| Bloco/item | App e versão do app | O que fiz | O que esperava | O que aconteceu |
|---|---|---|---|---|
|  |  |  |  |  |

E o veredito por bloco:

| Bloco | Resultado |
|---|---|
| 00 — Preparação |  |
| 01 — Fumaça |  |
| 02 — Um player por vez |  |
| 03 — Apps controlados |  |
| 04 — Modo fixo |  |
| 05 — Formato e texto |  |
| 06 — Degradação |  |

**Critério para bumpar a versão:** blocos 00 a 04 e 06 sem falha. O 05 é cosmético —
falha ali vira pendência, não bloqueia.

---

## O que este roteiro não testa, e por quê

Já está coberto por asserção automática (`swift run MacMediaWidget --run-tests`), e
repetir na mão só gasta tempo: leitura do stream e o campo `diff`, alinhamento à grade,
posição entre telas, quais capacidades cada player declara, o filtro de apps ocultos, o
roteamento do transporte com a Automação negada e a conversão de números do AppleScript
em locale pt-BR.
