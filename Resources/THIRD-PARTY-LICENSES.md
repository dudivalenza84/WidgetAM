# Licenças de terceiros — MacMediaWidget

Este app redistribui, dentro do bundle `.app`, software de terceiros. Abaixo estão a
identificação de cada componente e o texto integral da licença correspondente, como
exigido pelas condições de redistribuição em forma binária.

Licenças não são traduzidas: o texto abaixo é o original, verbatim.

---

## mediaremote-adapter

- **Autor**: Jonas van den Berg e contribuidores (`ungive`)
- **Origem**: https://github.com/ungive/mediaremote-adapter
- **Licença**: BSD 3-Clause
- **O que é redistribuído**: `mediaremote-adapter.pl` e `MediaRemoteAdapter.framework`,
  em `MacMediaWidget.app/Contents/Resources/mediaremote-adapter/`.
- **Como chega até aqui**: os arquivos são obtidos do pacote Homebrew
  [`media-control`](https://github.com/ungive/media-control) (mesmo autor), que
  incorpora o `mediaremote-adapter` como submódulo git e declara a mesma licença e
  titularidade. O executável `media-control` em si **não** é redistribuído — só os dois
  arquivos do adapter listados acima.

```
BSD 3-Clause License

Copyright (c) 2025, Jonas van den Berg and contributors

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

### Obrigações práticas que essa licença impõe ao produto

1. **Cláusula 2** — este arquivo (ou equivalente) deve acompanhar cada distribuição
   binária. É por isso que o `scripts/build-app.sh` o copia para
   `Contents/Resources/`, e não apenas para o repositório.
2. **Cláusula 3** — o nome do titular e dos contribuidores **não** pode ser usado para
   endossar ou promover o produto. Em material de venda, site e loja: descrever o
   mecanismo é permitido; escrever ou insinuar algo como "feito/aprovado por Jonas van
   den Berg" não é.
3. Não há cláusula copyleft: o código do MacMediaWidget pode permanecer fechado.

---

## Componentes que NÃO geram obrigação de atribuição

- **`/usr/bin/perl`** e o framework privado **MediaRemote**: são parte do macOS,
  apenas invocados em runtime na máquina do usuário. Nada da Apple é redistribuído.
- **Swift, AppKit, SwiftUI, Combine, ServiceManagement**: SDK do sistema, idem.
