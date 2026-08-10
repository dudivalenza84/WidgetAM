# ROADMAP — MMC (nome de trabalho)

Plano macro do caminho até a venda. Criado em 2026-08-09 · #01, a partir das decisões
registradas em `DECISOES.md` (venda direta fora da App Store; Amazon Music
inegociável; multi-player). Este arquivo é o mapa — o backlog vivo continua em
`PENDENCIAS.md`; cada fase vira sessões de trabalho normais do protocolo.

Ordem pensada para: valor de produto primeiro (Fase 1), depois solidez (Fase 2),
depois casca comercial (Fases 3–5). Fases 3 e 4 podem andar em paralelo.

---

## Fase 1 — Multi-player

Transformar o controle mono-app (Amazon Music) em multi-player com seleção.

- **Arquitetura de fontes**: abstração `Player` — MediaRemote como base universal
  (lê Now Playing de qualquer fonte, inclusive abas de navegador) + camada opcional
  de capacidades AppleScript por player (seek, volume por-app) onde existir.
- **Seletor de player preferido** nas preferências (qual app abrir no play) + modo
  automático ("controla o que estiver tocando"). UI indica a fonte ativa.
- **Volume por-app** via AppleScript para Spotify e Apple Music; Amazon Music e
  demais sem scripting continuam no volume do sistema (sem promessa universal —
  não existe API pública; ver DECISOES.md).
- **Matriz de compatibilidade empírica**: instalar e testar cada player real
  (Spotify, Deezer, Apple Music, YouTube no navegador). Regra do projeto: comando
  aceito sem erro ≠ comando funcionando — testar um a um (play/pause, next/prev,
  seek, shuffle/repeat, volume) e registrar a matriz em `docs/`.
- **Onboarding mínimo**: detectar players instalados no primeiro uso.

**Critério de saída**: controlar ao menos Amazon Music + Spotify + Apple Music +
uma fonte de navegador, com a matriz documentada e sem regressão no Amazon Music.

## Fase 2 — Robustez e QA de produto

O que separa "funciona na minha máquina" de produto.
**Feita em `2026-08-10 · #01`**, exceto o que exige olho humano ou segundo monitor.

- ✅ **Localização**: inglês virou o idioma-base (a chave é o texto em inglês) e
  `pt-BR.lproj` traz a tradução, com `scripts/verificar-traducoes.sh` guardando a
  consistência. Falta revisar o texto traduzido na tela.
- ✅ **Multi-tela e resoluções**: âncora da grade filtrada por tela, posição salva
  validada contra as telas conectadas e recuperação em
  `didChangeScreenParametersNotification`. Testado por asserções sintéticas — falta um
  segundo monitor de verdade.
- ✅ **Estados degradados**: `AdapterHealth` distingue "nada tocando" de "o mecanismo
  parou", com aviso na UI; player fechado e player ausente já tratados.
- ✅ **Saúde do adapter**: checagem de entitlement na abertura, reconexão com backoff
  exponencial, sinalização visível. Verificado matando o subprocesso.
- ✅ **Testes**: 53 verificações em `SelfTests.swift` (`swift run MacMediaWidget
  --run-tests`) — não é `swift test` porque as CLT não trazem os frameworks de teste;
  ver `DECISOES.md`.

**Critério de saída**: app utilizável por um desconhecido, em inglês, sem assistência.

## Fase 3 — Nome e identidade visual

- **Validar o nome**: diretriz de marcas da Apple (veta "Mac" incorporado ao nome;
  permite "X for Mac"), colisão com a dependência `media-control` (ungive), busca
  de marca/domínio/App Store. Sigla MMC é preservável (ex.: "MMC — Media Control
  for Mac"). Decisão final é do dono do produto.
- **Identidade**: ícone macOS (`.icns` no estilo de ícone do sistema), paleta,
  tipografia, tom de voz.
- **Materiais**: screenshots, texto de site, demo.

**Critério de saída**: nome definitivo registrado em DECISOES.md + ícone no bundle.

## Fase 4 — Infra de venda direta

- **Apple Developer Program** (US$ 99/ano) → certificado Developer ID. **Depende do
  dono do produto**: é o único bloqueio real do resto desta fase.
- ✅ **Pipeline de release** (`2026-08-10 · #01`): `scripts/build-app.sh` assina com
  hardened runtime e entitlements quando `MMW_SIGN_IDENTITY` existe, notariza e grampeia
  quando `MMW_NOTARY_PROFILE` existe, e cai em ad-hoc sem nenhum dos dois. Só falta o
  certificado para exercitar o caminho completo. Dado útil: **`notarytool` e `stapler`
  vêm nas Command Line Tools** — esta fase não exige instalar o Xcode.
- **Updates**: Sparkle (appcast + chaves EdDSA) — crítico pelo risco de update do
  macOS quebrar o MediaRemote: a resposta rápida É o produto.
- **Licenciamento/checkout**: Paddle ou Lemon Squeezy (merchant of record — cuidam
  de imposto internacional) vs. Gumroad (mais simples). Chave de licença no app.
- **Jurídico**: EULA, política de privacidade, textos de licença de terceiros no
  bundle — **feito** em `2026-08-10 · #01`: um único terceiro redistribuído, o
  `mediaremote-adapter` de `ungive` (BSD-3-Clause), com texto integral e obrigações em
  `Resources/THIRD-PARTY-LICENSES.md`, copiado para o bundle pelo `build-app.sh`.
- ✅ **Auditoria de segurança completa do app** (`2026-08-10 · #01`): relatório em
  `docs/auditoria-seguranca.md`. Três correções, uma delas de gravidade alta — o
  fallback para `/opt/homebrew` (caminho gravável sem privilégio) permitiria executar
  código dentro do processo do app. Refazer quando entrar o Sparkle: canal de update é
  a superfície mais crítica de todas.
- **Modelo de preço**: decidir compra única vs. assinatura considerando o risco
  estrutural (produto pode quebrar num update do macOS e exigir manutenção contínua).

**Critério de saída**: DMG assinado/notarizado instalável numa máquina limpa,
comprável e atualizável.

## Fase 5 — Lançamento

- **Beta fechado** com usuários reais (mínimo 3 máquinas fora da sua).
- **Site + checkout** no ar; canal de suporte (e-mail).
- **Transparência do risco**: comunicar na página o que o app depende (mecanismo
  não oficial; compromisso de correção rápida) — gerencia expectativa e reduz
  reembolso/chargeback.
- **Pós-lançamento**: monitorar saúde do adapter nas versões novas de macOS
  (beta da Apple a cada ciclo), changelog público.

---

## Registro de riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Apple fecha o acesso MediaRemote num update | App de todos os clientes para de uma vez | Sparkle + resposta rápida; testar betas do macOS; comunicar transparência |
| Amazon Music muda comportamento (comandos ignorados) | Recurso silenciosamente quebrado | Matriz de compatibilidade re-testável por script |
| Marca "Mac" no nome | Notificação jurídica da Apple | Validação de nome na Fase 3 antes de qualquer material público |
| Player sem AppleScript limita volume por-app | Expectativa frustrada de cliente | UI deixa claro por player o que é possível; sem promessa universal |
