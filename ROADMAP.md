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

- **Localização**: UI hoje é pt-BR; venda exige no mínimo inglês (String Catalog).
- **Multi-tela e resoluções**: grade nativa e persistência de posição com 2+
  monitores, troca de resolução/escala, notch/sem notch.
- **Estados degradados**: adapter morre ou macOS quebra o mecanismo (detectar,
  avisar o usuário, não travar); player fecha no meio; sem player instalado.
- **Saúde do adapter**: sinalização visível quando o stream cai + retomada.
- **Testes**: cobrir o que for testável sem UI (grade, parsing, settings).

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

- **Apple Developer Program** (US$ 99/ano) → certificado Developer ID.
- **Pipeline de release**: evoluir `scripts/build-app.sh` para assinar (hardened
  runtime), notarizar (`notarytool`) e grampear (staple); DMG de distribuição.
- **Updates**: Sparkle (appcast + chaves EdDSA) — crítico pelo risco de update do
  macOS quebrar o MediaRemote: a resposta rápida É o produto.
- **Licenciamento/checkout**: Paddle ou Lemon Squeezy (merchant of record — cuidam
  de imposto internacional) vs. Gumroad (mais simples). Chave de licença no app.
- **Jurídico**: EULA, política de privacidade, textos de licença de terceiros no
  bundle — **feito** em `2026-08-10 · #01`: um único terceiro redistribuído, o
  `mediaremote-adapter` de `ungive` (BSD-3-Clause), com texto integral e obrigações em
  `Resources/THIRD-PARTY-LICENSES.md`, copiado para o bundle pelo `build-app.sh`.
- **Auditoria de segurança completa do app** (não só diffs): subprocesso perl,
  parsing do JSON do adapter, resolução de caminhos do bundle, UserDefaults.
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
