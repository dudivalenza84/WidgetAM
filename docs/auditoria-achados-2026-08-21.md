# Anexo — achados completos da auditoria de 2026-08-21 · #02
Registro integral dos 76 achados devolvidos pelos sete auditores. A síntese, a priorização
e o plano de ação estão em `docs/auditoria-comercializacao.md` — este arquivo é a evidência bruta.
Cada achado traz arquivo e linha lidos no código. Onde há **Veredito adversarial**, um segundo
agente tentou refutar o achado lendo o mesmo código; a severidade ajustada por ele prevalece.

---

## Distribuição e comercialização

*12 achados — 2 alto · 7 médio · 3 baixo*

Auditoria de DISTRIBUIÇÃO do MacMediaWidget 1.17.0. O projeto está honesto consigo mesmo — o ROADMAP registra os riscos certos — mas o estado atual NÃO está pronto para venda. O pipeline Developer ID/notarização existe em build-app.sh (bem desenhado: assinatura de dentro para fora, sem --deep, staple com validação), porém nunca foi exercitado por falta do certificado, e carrega um defeito sério: as entitlements allow-dyld-environment-variables + disable-library-validation são desnecessárias (a justificativa no arquivo confunde hardened runtime com sandbox — o perl filho roda com assinatura própria) e juntas reabrem DYLD_INSERT_LIBRARIES contra o build notarizado, entregando a permissão de Automação do app a qualquer processo local. Bloqueadores de comercialização: sem Sparkle (a 'resposta rápida' que o próprio ROADMAP chama de 'o produto' não tem canal), DMG sem assinatura/notarização, build arm64-only com plist declarando macOS 15+ (Intel compraria e não abriria), adapter copiado do brew sem pin/vendoring (release irreproduzível; o diretório Resources/mediaremote-adapter prometido pelo CLAUDE.md não existe no repo), nome 'MacMediaWidget' ferindo a diretriz de marcas da Apple com bundle id que resetará TCC se trocado após o lançamento, e casca jurídica/comercial ausente (EULA, privacidade, licenciamento). Pontos fortes reais: obrigações da BSD-3-Clause do mediaremote-adapter cumpridas com rigor raro (texto integral no bundle via build-app.sh:46, cláusula 3 documentada), health check isEntitled() distinguindo 'nada tocando' de 'mecanismo morto', e a decisão fundamentada de vender fora da App Store (API privada torna a loja inviável). Nenhum achado critical isolado, mas o conjunto Sparkle+entitlements+DMG+arquitetura precisa ser fechado antes do primeiro cliente pago.

### 1. [ALTO] Sem canal de atualização automática — o risco estrutural do produto fica sem resposta

**Onde:** `Package.swift:9`

O produto inteiro depende de um framework privado (MediaRemote) que a Apple pode fechar em qualquer update do macOS — risco que o próprio projeto registra como 'app de todos os clientes para de uma vez'. A mitigação declarada é 'Sparkle + resposta rápida', mas não existe nenhum mecanismo de atualização no código: o Package.swift não tem dependência alguma (nem Sparkle), não há appcast, não há chave EdDSA, não há verificação de versão. Vender hoje significa que, no dia em que um update do macOS quebrar o adapter, não há como entregar a correção aos clientes a não ser esperando que cada um baixe manualmente um novo DMG — o oposto da 'resposta rápida' que o ROADMAP chama de 'É o produto'.

**Evidência:** Package.swift:9-14 — targets sem nenhuma dependência externa. ROADMAP.md:77-78: 'Updates: Sparkle (appcast + chaves EdDSA) — crítico pelo risco de update do macOS quebrar o MediaRemote: a resposta rápida É o produto.' ROADMAP.md:112 (registro de riscos): 'Apple fecha o acesso MediaRemote num update | App de todos os clientes para de uma vez | Sparkle + resposta rápida'. Grep por 'sparkle/update' no código: zero ocorrências em Sources/.

**Recomendação:** Integrar Sparkle 2 (via SPM) antes de qualquer venda: appcast hospedado, chaves EdDSA geradas e guardadas fora do repo, e o item de menu 'Verificar atualizações'. Refazer a auditoria de segurança sobre o canal de update, como o próprio ROADMAP.md:88 já prevê. Isso é pré-requisito de lançamento, não pós-lançamento.

**Veredito adversarial:** confirmado — severidade ajustada: **ALTO**. Evidência confirmada linha a linha: Package.swift (linhas 9-15) não declara nenhuma dependência — nem Sparkle nem qualquer outra; grep por sparkle/appcast/autoupdate/checkForUpdate/EdDSA em Sources/, scripts/ e Resources/ retorna zero ocorrências, ou seja, não existe nenhum mecanismo de atualização no app. ROADMAP.md:77-78 e ROADMAP.md:112 contêm exatamente os trechos citados: o canal de update via Sparkle é declarado "crítico" e é a mitigação registrada para o risco número um do produto ("Apple fecha o acesso MediaRemote num update → app de todos os clientes para de uma vez"). O achado é real. Não sobe a critical porque não é defeito no código em execução, e sim pré-requisito de comercialização ainda não implementado — o app tampouco está à venda hoje, e o mesmo ROADMAP mostra outros bloqueios abertos na mesma fase (certificado Developer ID, checkout). Mas high se sustenta: pela régua de comercialização pedida, distribuir sem canal de atualização deixa o risco estrutural central do produto sem a única mitigação que o próprio projeto definiu, e o impacto descrito não está inflado.

### 2. [ALTO] Entitlements dyld desnecessárias reabrem injeção de código no build assinado para o cliente

**Onde:** `Resources/MacMediaWidget.entitlements:15`

O arquivo de entitlements usado no caminho Developer ID declara com.apple.security.cs.allow-dyld-environment-variables e com.apple.security.cs.disable-library-validation, justificadas pelo comentário de que 'o hardened runtime impede que um processo assinado lance binários que não herdam a sua assinatura'. Essa justificativa é tecnicamente errada: o hardened runtime restringe operações de dyld e debugging DENTRO do próprio processo — ele não impede spawn de subprocessos. O /usr/bin/perl é binário de plataforma assinado pela Apple, roda com a própria assinatura e carrega o MediaRemoteAdapter.framework no processo DELE, não no do widget; as entitlements do pai não participam disso (a restrição a subprocessos existe no App Sandbox, que este app não usa). O custo de mantê-las é concreto: com as duas ativas, DYLD_INSERT_LIBRARIES volta a funcionar contra o app assinado/notarizado — qualquer processo local sem privilégio pode injetar uma dylib no widget e herdar a permissão de Automação (TCC) sobre os apps de música. É exatamente o vetor de 'código dentro do processo do app' que a auditoria interna fechou ao remover o fallback /opt/homebrew em release (MediaRemoteAdapter.swift:33-38), reaberto por outra porta na versão que vai para o cliente.

**Evidência:** Resources/MacMediaWidget.entitlements:11-18 — comentário 'O hardened runtime, por padrão, impede que um processo assinado lance binários que não herdam a sua assinatura' seguido de allow-dyld-environment-variables=true e disable-library-validation=true. Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:146-149 — o framework é passado como argumento ao perl (process.arguments = [scriptPath(), frameworkPath()] + arguments), ou seja, é carregado pelo subprocesso, nunca pelo widget. scripts/build-app.sh:84-87 aplica essas entitlements no codesign Developer ID. ROADMAP.md:70-71 confirma que o caminho assinado nunca foi exercitado ('Só falta o certificado').

**Recomendação:** Remover as duas entitlements, mantendo apenas com.apple.security.automation.apple-events, e validar o build assinado com certificado real assim que ele existir (o caminho Developer ID de build-app.sh nunca rodou de verdade). Se algum cenário concreto provar que o adapter não inicia sem elas, documentar a evidência observada — o padrão do próprio projeto — antes de reintroduzir qualquer uma.

**Veredito adversarial:** confirmado — severidade ajustada: **ALTO**. Tentei refutar e não consegui — cada elo da cadeia se confirma no código. (1) Evidência textual: Resources/MacMediaWidget.entitlements:11-18 contém exatamente o comentário citado ("o hardened runtime, por padrão, impede que um processo assinado lance binários que não herdam a sua assinatura") seguido de com.apple.security.cs.allow-dyld-environment-variables=true e com.apple.security.cs.disable-library-validation=true. (2) A justificativa do comentário é tecnicamente falsa: o hardened runtime restringe dyld/debugging no próprio processo; não bloqueia posix_spawn/fork-exec de subprocessos (essa restrição é do App Sandbox, ausente aqui — não há com.apple.security.app-sandbox no arquivo). /usr/bin/perl e /usr/bin/osascript são binários de plataforma assinados pela Apple que rodam sob a própria assinatura; as entitlements do pai não participam. (3) O widget nunca carrega o framework no próprio processo: MediaRemoteAdapter.swift:149 passa o framework como argumento ao perl (process.arguments = [scriptPath(), frameworkPath()] + arguments), e todo AppleScript vai por subprocesso /usr/bin/osascript (AppleScriptRunner.swift:23, SystemVolumeController.swift:89) — o código até documenta que evita NSAppleScript de propósito. Logo nenhuma das duas entitlements tem uso legítimo: são 100% superfície de ataque sem contrapartida funcional. (4) O impacto não está inflado: com as duas juntas, DYLD_INSERT_LIBRARIES volta a funcionar contra o binário assinado/notarizado (allow-dyld reabilita as variáveis, disable-library-validation permite carregar dylib de outro time), e a dylib injetada roda com a identidade de código do app, herdando os grants de TCC/Automação já concedidos e podendo disparar novos prompts em nome do widget. É exatamente o vetor que o próprio projeto fechou ao restringir o fallback /opt/homebrew a DEBUG (MediaRemoteAdapter.swift:31-38, com justificativa de segurança explícita sobre "código dentro do processo do widget herdando Automação") — reaberto por outra porta. (5) O buraco atinge só o build comercial: o codesign ad-hoc (build-app.sh:91-92) não aplica entitlements; o caminho Developer ID (build-app.sh:84-87) aplica — ou seja, a versão vendida é a vulnerável, e a notarização passa com essas entitlements, dando ao cliente um selo de segurança que o binário não honra. Severidade high se sustenta: defeito real no build de venda, contradiz o modelo de ameaça documentado do próprio projeto, e a correção (remover as duas chaves) é sem risco funcional. Não é critical porque a exploração exige código local já em execução e o privilégio herdado (Automação sobre players de mídia) é modesto.

### 3. [MÉDIO] Build arm64-only: o produto não roda em Macs Intel dentro do requisito declarado

**Onde:** `scripts/build-app.sh:17`

O build-app.sh compila com 'swift build -c release' sem --arch, o que produz binário apenas da arquitetura da máquina de build, e copia o MediaRemoteAdapter.framework da bottle do Homebrew local — também de arquitetura única. O bundle atual em dist/ é thin arm64 (binário e framework). Como o Info.plist declara LSMinimumSystemVersion 15.0 e o macOS 26 ainda suporta uma leva de Macs Intel, existe um conjunto real de clientes potenciais que compraria e receberia 'não é possível abrir' — falha silenciosa de distribuição, sem mensagem útil.

**Evidência:** scripts/build-app.sh:17-19 — 'swift build -c release' e BIN="$(swift build -c release --show-bin-path)/$APP_NAME", sem flags de arquitetura. Verificado no artefato: 'lipo -info dist/MacMediaWidget.app/Contents/MacOS/MacMediaWidget' → 'Non-fat file: ... architecture: arm64'; idem para o MediaRemoteAdapter.framework/MediaRemoteAdapter. Resources/Info.plist:35-36 — LSMinimumSystemVersion 15.0.

**Recomendação:** Decidir explicitamente o suporte a Intel. Se sim: 'swift build -c release --arch arm64 --arch x86_64' e obter/lipo o framework universal (verificar se a bottle do media-control oferece x86_64). Se não: subir LSMinimumSystemVersion e declarar arm64-only na página de venda, para que o Gatekeeper/instalação recuse com mensagem clara em vez de falhar no cliente.

### 4. [MÉDIO] DMG de distribuição não é assinado, notarizado nem grampeado

**Onde:** `scripts/package-dmg.sh:31`

O package-dmg.sh gera o DMG com hdiutil e para aí: nenhum codesign, nenhuma submissão ao notarytool, nenhum staple no DMG — o cabeçalho do script ainda assume o cenário ad-hoc de uso pessoal e não participa do fluxo Developer ID que o build-app.sh já prevê. Um app grampeado dentro de DMG sem assinatura até passa no Gatekeeper, mas o contêiner fica adulterável (qualquer intermediário pode trocar o .app dentro do DMG sem invalidar nada do DMG em si), e a prática recomendada pela Apple para venda direta é assinar e notarizar o próprio DMG. Para um produto pago, o artefato que o cliente baixa é a superfície de confiança — hoje ela não existe.

**Evidência:** scripts/package-dmg.sh:1-37 — arquivo inteiro; linhas 31-35 fazem apenas 'hdiutil create ... -format UDZO'; não há codesign/notarytool/stapler em nenhuma linha. Linhas 3-4 do cabeçalho: 'Distribuição de uso pessoal (sem Apple Developer ID): o .app é ad-hoc'. Em contraste, scripts/build-app.sh:75-108 já tem o fluxo Developer ID/notarização para o .app.

**Recomendação:** Estender package-dmg.sh com o mesmo padrão de variáveis do build-app.sh: quando MMW_SIGN_IDENTITY existir, 'codesign --sign' no DMG, 'notarytool submit' e 'stapler staple' no DMG (a Apple aceita e recomenda notarizar o contêiner). Publicar também o checksum do DMG na página de download.

### 5. [MÉDIO] Dependência de build do adapter não é pinada nem vendorizada — release comercial irreproduzível

**Onde:** `scripts/build-app.sh:26`

O bundle comercial embute mediaremote-adapter.pl e MediaRemoteAdapter.framework copiados de 'brew --prefix media-control' — ou seja, da versão que estiver instalada na máquina de build naquele dia, sem pin de versão, sem checksum, sem registro de qual versão entrou em qual release. Consequências para um produto vendido: (a) builds irreproduzíveis — impossível saber qual adapter está no 1.17.0 de um cliente; (b) um 'brew upgrade' silencioso muda o comportamento do componente mais crítico do app entre dois releases; (c) superfície de supply chain — a fórmula/bottle do Homebrew vira parte da cadeia de build do produto sem verificação de integridade. Agrava que o CLAUDE.md do projeto descreve 'Resources/mediaremote-adapter/ # framework + perl bundlados' como estrutura esperada do repositório, mas esse diretório não existe — o vendoring que a documentação promete nunca aconteceu.

**Evidência:** scripts/build-app.sh:26-32 — ADAPTER_CELLAR="$(brew --prefix media-control)" e cópia direta de ADAPTER_PL/ADAPTER_FRAMEWORK, sem verificação de versão ou hash. Verificado: 'ls Resources/' contém apenas Info.plist, entitlements, THIRD-PARTY-LICENSES.md, icon/ e pt-BR.lproj — não há Resources/mediaremote-adapter/, ao contrário do que CLAUDE.md (seção 'Estrutura de arquivos esperada') declara.

**Recomendação:** Vendorizar o adapter no repositório (ou num submódulo pinado por commit do upstream ungive/mediaremote-adapter), registrando versão e checksum; o build passa a copiar do repo, não do brew. No mínimo, o build-app.sh deve gravar a versão da fórmula ('brew list --versions media-control') num arquivo dentro do bundle e recusar build de release sem versão conhecida.

### 6. [MÉDIO] Nome 'MacMediaWidget' fere a diretriz de marcas da Apple e o bundle id herda o problema

**Onde:** `Resources/Info.plist:10`

A diretriz de marcas da Apple veda incorporar 'Mac' ao nome do produto (permite 'X for Mac', não 'MacX') — risco que o próprio ROADMAP registra como 'notificação jurídica da Apple'. O problema já passou de nome de trabalho: o Info.plist distribui CFBundleName/CFBundleDisplayName 'MacMediaWidget' e, pior, o CFBundleIdentifier com.dudivalenza.macmediawidget carrega o nome. Trocar o bundle id depois do lançamento reseta a permissão de Automação (TCC) de todos os clientes, o item de login e o domínio de UserDefaults (posição do widget, preferências) — uma migração dolorosa que cresce a cada cliente vendido. O ícone e a identidade já foram produzidos sob esse nome.

**Evidência:** Resources/Info.plist:5-10 — CFBundleName 'MacMediaWidget', CFBundleDisplayName 'MacMediaWidget', CFBundleIdentifier 'com.dudivalenza.macmediawidget'. ROADMAP.md:58-61 — 'Validar o nome: diretriz de marcas da Apple (veta "Mac" incorporado ao nome...)'; ROADMAP.md:114 — risco 'Marca "Mac" no nome | Notificação jurídica da Apple'. NSAppleEventsUsageDescription e prompts de TCC ficam vinculados ao bundle id atual.

**Recomendação:** Resolver a Fase 3 (nome definitivo) ANTES do primeiro build assinado com Developer ID e do primeiro cliente: o bundle id definitivo precisa nascer com o certificado, porque é ele que fica gravado no TCC e no notariado. Não produzir mais nenhum material (ícone, site, DMG) sob 'MacMediaWidget'.

### 7. [MÉDIO] Requisito de sistema incoerente: plist diz macOS 15, documentação diz macOS 26

**Onde:** `Resources/Info.plist:36`

O Info.plist declara LSMinimumSystemVersion 15.0 e o Package.swift fixa .macOS(.v15), mas o README exige 'macOS 26 ou superior' e o CLAUDE.md do projeto afirma 'Plataforma: macOS 26+'. O código tem exatamente um guard #available(macOS 26) (o glassEffect do card, com fallback para ultraThinMaterial), o que sugere que macOS 15 tecnicamente funciona — porém nada indica que o app tenha sido testado em 15, e o visual 'Liquid Glass' que define o produto não existe lá. Para venda isso é uma decisão de mercado sem dono: ou o produto suporta 15-25 (e precisa de QA e screenshots honestos do fallback), ou exige 26 (e o plist precisa dizer isso para o instalador recusar com mensagem clara). Hoje um cliente em macOS 15 compra o visual premium anunciado e recebe outro.

**Evidência:** Resources/Info.plist:35-36 — LSMinimumSystemVersion '15.0'. Package.swift:7 — .macOS(.v15). README.md:61 — 'macOS 26 ou superior.' Sources/MacMediaWidget/ContentView.swift:418-434 — único '#available(macOS 26, *)' do código, com fallback visual; grep em Sources/ mostra só essa ocorrência.

**Recomendação:** Escolher e alinhar: se o produto é macOS 26+, subir LSMinimumSystemVersion para 26.0 e .macOS(.v26); se suporta 15+, corrigir README/materiais e incluir macOS 15 no roteiro de teste manual antes de vender.

### 8. [MÉDIO] Casca comercial ausente: sem EULA, sem política de privacidade, sem licenciamento/checkout

**Onde:** `ROADMAP.md:79`

Da Fase 4 ('Infra de venda direta'), o único item jurídico concluído é a atribuição de terceiros (THIRD-PARTY-LICENSES.md). Não existe EULA, não existe política de privacidade e não existe mecanismo de chave de licença ou integração de checkout em lugar nenhum do repositório — a busca por 'eula/privacidade/privacy' em docs/ só encontra referências ao painel de Privacidade do macOS. Sem EULA, a venda de um app cujo mecanismo central é uma API privada que pode morrer num update do sistema fica sem limitação de responsabilidade nem gestão de expectativa contratual; sem verificação de licença, não há o que impedir redistribuição do DMG.

**Evidência:** ROADMAP.md:79-84 — 'Licenciamento/checkout: Paddle ou Lemon Squeezy... Chave de licença no app' listado como pendente; o 'feito' do item Jurídico refere-se explicitamente só ao THIRD-PARTY-LICENSES.md. Verificado: 'ls' na raiz e em docs/ não mostra EULA nem política de privacidade; grep -ri 'eula|privacy|privacidade' em docs/*.md e README.md retorna apenas menções ao painel Privacidade › Automação do macOS.

**Recomendação:** Antes do primeiro real cobrado: EULA com disclaimer explícito da dependência de mecanismo não oficial e limitação de responsabilidade; política de privacidade (mesmo que para dizer 'não coletamos nada'); e decidir o merchant of record (Paddle/Lemon Squeezy resolvem imposto internacional) com a validação de chave de licença no app.

### 9. [MÉDIO] Dependência dupla de componentes que a Apple pode remover: /usr/bin/perl hardcoded + framework privado

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:22`

Todo o mecanismo de leitura/comando roda por /usr/bin/perl hardcoded. A Apple avisa desde o macOS Catalina (release notes de 2019) que runtimes de linguagens de script estão deprecados e deixarão de vir por padrão em versões futuras — Python já foi removido no Monterey; perl segue vivo no macOS 26, mas é remoção anunciada, não hipotética. Somado ao risco já registrado de fechamento do MediaRemote, o produto tem dois pontos únicos de falha fora do seu controle. O tratamento em runtime é bom — isEntitled() distingue 'nada tocando' de 'mecanismo morto' e a UI avisa — mas detectar a morte não é um plano de contingência: sem canal de update (achado do Sparkle) e sem caminho alternativo de execução do adapter, a detecção só informa ao cliente que o produto que ele pagou parou.

**Evidência:** Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:22 — 'private static let perlPath = "/usr/bin/perl"'; linhas 146-149 — todo processo do adapter nasce de perlPath. Linhas 129-144 — isEntitled() e o comentário que reconhece: 'o risco estrutural do produto, já que o MediaRemote é framework privado e a Apple pode fechar o acesso num update do macOS'. ROADMAP.md:103-104 — mitigação limitada a 'monitorar saúde do adapter nas versões novas de macOS'.

**Recomendação:** Duas frentes: (1) acompanhar o upstream ungive/mediaremote-adapter, que é quem terá de portar o mecanismo se o perl sumir (existe caminho conhecido: um helper binário próprio entitled, em vez do perl — avaliar adotar antes da remoção, não depois); (2) tratar cada beta de macOS como gate de release: rodar o roteiro de teste no beta 1 de cada ciclo, com o Sparkle já operante para responder. Registrar isso como processo, não como intenção.

### 10. [BAIXO] Zero visibilidade de falha em produção: sem crash reporting e sem telemetria de saúde

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:97`

Não há nenhum mecanismo de crash reporting ou telemetria no app — as falhas viram no máximo NSLog local (ex.: 'falha ao enviar comando ao adapter'). Para a maioria dos apps isso seria neutro (e é um ponto positivo de privacidade), mas este produto tem um modo de falha estrutural conhecido (adapter morrer num update do macOS) cuja mitigação declarada é 'resposta rápida'. Sem qualquer sinal vindo das máquinas dos clientes, a detecção de uma quebra em massa depende de e-mail de reclamação — dias de atraso na única situação em que velocidade é o produto. O ROADMAP prevê monitorar betas da Apple, o que ajuda, mas não cobre quebra que só se manifesta em configurações que o desenvolvedor não tem.

**Evidência:** Grep em Sources/ por crash/telemetry/analytics/report: zero ocorrências além de NSLog. Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:96-98 — erro de comando vai só para NSLog. ROADMAP.md:103-104 — pós-lançamento limitado a monitoramento manual de betas. Nenhuma dependência em Package.swift:9-14.

**Recomendação:** Não precisa de telemetria invasiva: um ping opcional (opt-in) de 'saúde do adapter' (versão do macOS + resultado do isEntitled), ou no mínimo um botão 'Reportar problema' que abra e-mail com diagnóstico anexado (versão do app/macOS, estado do adapter). Declarar o que for coletado na política de privacidade.

### 11. [BAIXO] Info.plist sem NSHumanReadableCopyright

**Onde:** `Resources/Info.plist:4`

O Info.plist não declara NSHumanReadableCopyright. O painel 'Obter Informações' do Finder e caixas About padrão exibem esse campo; num produto vendido, a ausência é descuido visível e a linha de copyright é parte do posicionamento jurídico mínimo do software proprietário (que também não tem declaração de licença própria em nenhum arquivo do repo).

**Evidência:** Resources/Info.plist:1-42 — arquivo completo lido; não contém NSHumanReadableCopyright (grep confirmou zero ocorrências no repo). 'ls' na raiz: não existe LICENSE nem COPYING declarando os termos do próprio produto.

**Recomendação:** Adicionar NSHumanReadableCopyright ('© 2026 <titular>. All rights reserved.') e, quando o EULA existir, referenciá-lo como a licença do produto.

### 12. [BAIXO] App Store confirmadamente inviável — venda direta é o único canal, e a decisão já está registrada

**Onde:** `DECISOES.md:494`

Registro de confirmação da auditoria, não defeito novo: a distribuição via Mac App Store é impossível por construção — o app carrega o framework privado MediaRemote via subprocesso perl (rejeição automática de API privada na revisão), e o App Sandbox obrigatório da loja quebraria o spawn de /usr/bin/perl com framework arbitrário, os Apple Events de Automação irrestritos e a janela em nível de desktop presente em todos os Spaces. O projeto já sabe e já decidiu: venda direta fora da loja. A decisão está correta e registrada; o que ela custa é justamente o resto desta auditoria — Gatekeeper via Developer ID + notarização, updates próprios (Sparkle), checkout próprio e jurídico próprio, tudo por conta do produto.

**Evidência:** DECISOES.md:494 — '...acessado via perl entitled — inviável na Mac App Store (revisão rejeita API privada...)'. Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:146-149 — spawn de /usr/bin/perl carregando MediaRemoteAdapter.framework. Resources/Info.plist:37-38 — LSUIElement. ROADMAP.md:3-4 — 'venda direta fora da App Store' como decisão de base.

**Recomendação:** Nenhuma ação no código. Manter a decisão e garantir que os materiais de venda nunca prometam presença na App Store; concluir os itens que a venda direta exige (achados sobre Sparkle, DMG, EULA, Developer ID).

---

## Segurança

*5 achados — 1 alto · 3 médio · 1 baixo*

Auditoria de segurança do MacMediaWidget (dimensão SEGURANÇA), lida contra docs/auditoria-seguranca.md para não repetir o já aceito. A regra de interpolação em AppleScript segue cumprida: todo corpo de `tell` em AppleScriptPlayer/SystemVolumeController é constante ou inteiro formatado, `scriptingName` é literal do código e nenhum metadado de mídia (título/artista/bundle id do stream) alcança osascript, JavaScript ou shell; as URLs abertas são todas constantes. Os achados novos: (1) ALTO — as entitlements `disable-library-validation` + `allow-dyld-environment-variables` foram adicionadas sob premissa técnica errada (hardened runtime não bloqueia exec de /usr/bin/perl), não servem ao subprocesso e abrem injeção de dylib no processo do widget herdando a permissão de Automação TCC — reabre a classe de risco que a auditoria anterior fechou no item 1; (2) MÉDIO — stderr do processo de stream do adapter nunca é drenado: pipe cheio congela o widget em silêncio, sem disparar a reconexão; (3) MÉDIO — osascript sem timeout combinado com polling de posição que não espera a leitura anterior acumula subprocessos pendurados e esgota o pool cooperativo de Swift Concurrency quando um player trava; (4) MÉDIO — o build embarca o mediaremote-adapter direto do Homebrew sem pinagem nem verificação de hash (supply chain do componente mais privilegiado); (5) BAIXO — o DMG não é assinado nem notarizado mesmo no fluxo Developer ID. Settings/UserDefaults não persistem nada sensível (sem mudança desde a auditoria) e o Info.plist traz a NSAppleEventsUsageDescription correta.

### 13. [ALTO] Entitlements de hardened runtime desnecessárias abrem injeção de dylib com as permissões TCC do widget

**Onde:** `Resources/MacMediaWidget.entitlements:15`

O arquivo declara `com.apple.security.cs.allow-dyld-environment-variables` e `com.apple.security.cs.disable-library-validation` com a justificativa (no comentário das linhas 11–14) de que 'o hardened runtime impede que um processo assinado lance binários que não herdam a sua assinatura'. Essa premissa é falsa: o hardened runtime não restringe `fork`/`exec` de binários de plataforma — `/usr/bin/perl` e `/usr/bin/osascript` são processos separados, com assinatura própria da Apple, e as entitlements do app pai não se aplicam nem são necessárias a eles. O `MediaRemoteAdapter.framework` é carregado pelo processo do perl, não pelo do widget (MediaRemoteAdapter.swift:146–153 passa o framework como argumento do script). O app em si não faz `dlopen` de nada de terceiros. Ou seja: as duas entitlements não habilitam nada que o produto precise — e, combinadas, formam o vetor clássico de injeção: qualquer processo local sem privilégio pode lançar o widget com `DYLD_INSERT_LIBRARIES` apontando para um dylib não assinado, que executa dentro do processo do app herdando a permissão de Automação sobre os apps de música (`com.apple.security.automation.apple-events`) e o acesso ao Now Playing que o usuário concedeu. É exatamente a classe de risco que a auditoria de 2026-08-10 fechou no item 1 ('execução de código não confiável com as permissões TCC que o usuário concedeu ao app'), reaberta por outro caminho. A auditoria anterior listou o hardened runtime como não coberto, então este achado é novo.

**Evidência:** Resources/MacMediaWidget.entitlements:11–18: "<!-- O app roda /usr/bin/perl e /usr/bin/osascript como subprocessos. O hardened runtime, por padrão, impede que um processo assinado lance binários que não herdam a sua assinatura. [...] --> <key>com.apple.security.cs.allow-dyld-environment-variables</key><true/> <key>com.apple.security.cs.disable-library-validation</key><true/>". As entitlements são aplicadas ao bundle em scripts/build-app.sh:84–87 (`codesign ... --entitlements "$ENTITLEMENTS"` no fluxo Developer ID + hardened runtime).

**Recomendação:** Remover as duas entitlements e manter só `com.apple.security.automation.apple-events`. Validar num build assinado com Developer ID + hardened runtime que o adapter perl continua iniciando (vai continuar: exec de binário de plataforma não é afetado, e o framework é carregado no processo do perl). Se algum dia o app precisar carregar dylib de terceiros no próprio processo, assinar o dylib com o mesmo Team ID em vez de desligar a validação.

**Veredito adversarial:** confirmado — severidade ajustada: **MÉDIO**. Achado tecnicamente correto e verificado no código. As entitlements `com.apple.security.cs.allow-dyld-environment-variables` e `com.apple.security.cs.disable-library-validation` (Resources/MacMediaWidget.entitlements:15-18) são de fato desnecessárias para o propósito documentado nas linhas 11-14. A premissa do comentário é falsa: `/usr/bin/perl` (codesign mostra Identifier=com.apple.perl, binário de plataforma da Apple) e `/usr/bin/osascript` são subprocessos com assinatura própria; o hardened runtime não bloqueia exec de binários de plataforma e as entitlements do processo pai não se propagam ao filho. O framework é carregado pelo processo do perl, não pelo app (MediaRemoteAdapter.swift:149 passa frameworkPath() como argumento do script). O app não faz dlopen de código de terceiros (grep em Sources/ não achou dlopen/DYLD/Bundle load; só subprocessos osascript/perl). E makeProcess (linhas 146-153) não injeta nenhuma variável DYLD_* no subprocesso, então allow-dyld-environment-variables também não é usado. As entitlements são aplicadas em build-app.sh:84-87 (fluxo Developer ID + --options runtime). O par disable-library-validation + allow-dyld-environment-variables é o vetor clássico de injeção de dylib em app com hardened runtime, e mantê-lo num produto comercial é expansão gratuita de superfície de ataque — o comentário com justificativa incorreta é a armadilha que garante que fiquem lá.\n\nRebaixo de high para medium por dois motivos que limitam o impacto real: (1) o pré-requisito do ataque é execução de código local do mesmo usuário, capaz de relançar o binário com DYLD_INSERT_LIBRARIES num ambiente forjado — estado já comprometido; e (2) o que a injeção herda é estreito: a grant de Automação sobre apps de música e a leitura de Now Playing, sem acesso a disco/acessibilidade/câmera/mic. É bypass de TCC de baixo valor (controlar player, ler metadado), não escalonamento amplo. Correção legítima de endurecimento a fazer antes de comercializar, mas não é quebra explorável da função central do produto.

### 14. [MÉDIO] stderr do subprocesso de stream nunca é drenado — pipe cheio congela o widget em silêncio e sem reconexão

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:151`

`makeProcess` conecta `standardError` a um `Pipe()` que ninguém jamais lê. Para os comandos one-shot isso é inofensivo (saída mínima, processo curto), mas o mesmo construtor monta o processo de stream de longa duração (`makeStreamProcess`, consumido em NowPlayingController.openStream), onde só o stdout ganha `readabilityHandler`. Se o adapter perl escrever mais do que a capacidade do buffer do pipe (~64 KB) em stderr ao longo da sessão — warnings do perl, diagnósticos, saída corrompida —, o processo filho bloqueia no `write(2)` e para de emitir linhas. O stream congela sem morrer: `terminationHandler` nunca dispara, o backoff de reconexão (NowPlayingController.swift:285–299) nunca roda, `health` permanece `.healthy` e o widget exibe a última faixa para sempre. É o mesmo modo de falha que o comentário de AppleScriptRunner.swift:36–37 reconhece e evita para o osascript ('um pipe cheio bloqueia o processo filho'), mas não foi aplicado ao subprocesso mais crítico do produto.

**Evidência:** MediaRemoteAdapter.swift:146–153: `process.standardOutput = Pipe(); process.standardError = Pipe()` sem leitor. NowPlayingController.swift:258–267: apenas `stdout.fileHandleForReading.readabilityHandler` é instalado; nenhuma referência ao stderr do processo de stream em todo o código.

**Recomendação:** No processo de stream, apontar `standardError` para `FileHandle.nullDevice` (ou instalar um `readabilityHandler` que descarte/logue com teto). Alternativamente, drenar o stderr e usá-lo no diagnóstico de saúde do adapter — mas o mínimo comercializável é garantir que ele nunca encha.

### 15. [MÉDIO] osascript sem timeout somado a polling que não espera a leitura anterior: acúmulo de subprocessos e starvation do pool de concorrência

**Onde:** `Sources/MacMediaWidget/Players/AppleScriptRunner.swift:38`

`AppleScriptRunner.run` bloqueia em `readDataToEndOfFile()`/`waitUntilExit()` sem nenhum timeout. Um Apple Event para um app travado (Music.app em beachball, Spotify carregando) só falha no timeout padrão de AppleEvents (~2 minutos) — durante esse tempo a chamada segura um thread. O agravante está no chamador: `pollRealPositionIfNeeded` (NowPlayingController.swift:327–344) grava `lastPositionPoll = now` ANTES de a leitura terminar, então com o player alvo travado ele dispara um novo `Task.detached { AppleScriptRunner.run(...) }` por segundo, sem esperar o anterior. Resultado: até ~120 processos osascript simultâneos pendurados e, pior, cada `Task.detached` bloqueado em I/O síncrono ocupa um thread do pool cooperativo de Swift Concurrency (largura = número de núcleos) — com poucos travados, todo trabalho assíncrono não-MainActor do app para junto (volume do sistema, checagem de entitlement, demais `tell`). Para um produto comercial, um player de terceiros travado não pode degradar o widget inteiro.

**Evidência:** AppleScriptRunner.swift:38–40: `let outData = stdout.fileHandleForReading.readDataToEndOfFile(); let errData = stderr.fileHandleForReading.readDataToEndOfFile(); process.waitUntilExit()` — sem timeout. NowPlayingController.swift:334–336: `guard now.timeIntervalSince(lastPositionPoll) >= 1 else { return }; lastPositionPoll = now` seguido de `Task { ... await player.position() }` — o carimbo é gravado antes de a leitura concluir, permitindo N leituras em voo. AppleScriptPlayer.swift:52: cada `tell` roda em `Task.detached`.

**Recomendação:** Dar watchdog ao osascript (ex.: `DispatchSourceTimer` que chama `process.terminate()` após 5–10 s, tratando como `.failed`) e marcar o poll como em-voo (flag booleana zerada no término) para nunca haver mais de uma leitura de posição pendente por player. Considerar `-e 'with timeout of N seconds ...'` como cinto e suspensório.

### 16. [MÉDIO] Build empacota o mediaremote-adapter direto do Homebrew sem pinagem de versão nem verificação de integridade

**Onde:** `scripts/build-app.sh:26`

O `build-app.sh` copia para dentro do bundle o `mediaremote-adapter.pl` e o `MediaRemoteAdapter.framework` de `$(brew --prefix media-control)` — o que quer que esteja instalado na máquina de build, na versão que estiver. Não há pinagem de versão, checagem de hash nem registro do que foi embarcado. Esse componente é o mais privilegiado do produto (roda com o entitlement do MediaRemote via /usr/bin/perl e alimenta todo o parsing do app): um `brew upgrade` troca silenciosamente o código que vai para o cliente por uma versão nunca auditada, e um comprometimento da fórmula/upstream vira código malicioso assinado com o Developer ID do produto e notarizado. A auditoria anterior tratou do canal de atualização (Sparkle) como ponto sensível futuro, mas não da procedência do adapter no build — que já existe hoje.

**Evidência:** scripts/build-app.sh:26–32 e 41–42: `ADAPTER_CELLAR="$(brew --prefix media-control)"; ADAPTER_PL="$ADAPTER_CELLAR/lib/media-control/mediaremote-adapter.pl"; ADAPTER_FRAMEWORK="$ADAPTER_CELLAR/Frameworks/MediaRemoteAdapter.framework" [...] cp "$ADAPTER_PL" ...; cp -R "$ADAPTER_FRAMEWORK" ...` — nenhuma verificação além de existência do arquivo.

**Recomendação:** Fixar a versão auditada: vendorizar o adapter no repositório (a licença BSD-3-Clause permite) ou, no mínimo, verificar no build um SHA-256 conhecido do `.pl` e do binário do framework e falhar em divergência, gravando a versão embarcada num arquivo dentro de Resources. Reauditar a cada bump deliberado.

### 17. [BAIXO] DMG de distribuição sem assinatura nem notarização própria, mesmo no fluxo Developer ID

**Onde:** `scripts/package-dmg.sh:31`

O `package-dmg.sh` gera o `.dmg` com `hdiutil` e para aí — não existe caminho que assine o DMG (`codesign -s "Developer ID"`) nem que o submeta à notarização e staple. O `build-app.sh` já tem o fluxo Developer ID completo para o `.app`, mas o artefato que o cliente de fato baixa é o DMG: sem assinatura e ticket no próprio DMG, o Gatekeeper avalia só o `.app` interno (que funciona, pelo staple), mas perde-se a verificação de integridade do contêiner de download e a melhor experiência de primeira abertura — e um DMG adulterado no caminho de download não é detectável antes da montagem. A auditoria anterior registrou a lacuna de integridade apenas para o cenário ad-hoc; o fluxo comercial com Developer ID também está incompleto nesta ponta.

**Evidência:** scripts/package-dmg.sh:29–37: `hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG"` é a última operação sobre o artefato — nenhuma chamada a `codesign`, `notarytool` ou `stapler` sobre `$DMG` em nenhum script.

**Recomendação:** No fluxo com `MMW_SIGN_IDENTITY`: `codesign --sign "$SIGN_IDENTITY" "$DMG"`, submeter o DMG ao `notarytool` e `stapler staple "$DMG"` (a Apple recomenda notarizar o contêiner de distribuição, não só o app). Publicar também o SHA-256 do DMG na página de download.

---

## Concorrência e ciclo de vida

*12 achados — 2 alto · 4 médio · 6 baixo*

Auditoria de concorrência e ciclo de vida de processos do MacMediaWidget (12 arquivos lidos na íntegra nos pontos críticos). O desenho geral é são — estado de UI confinado ao MainActor, closures com [weak self], timers invalidados, guarda de instância única e terminação do perl no quit — mas há dois defeitos de peso para um produto comercial que roda semanas: (1) o readabilityHandler do stream nunca é removido, vazando FileHandle/fd e deixando um dispatch source disparando em EOF a cada morte do adapter, que o próprio código declara ser o modo de falha rotineiro — degradação acumulativa garantida; (2) o volume por-app dispara um osascript por evento de arrasto do slider contínuo, sem coalescência nem serialização — dezenas de subprocessos concorrentes terminando fora de ordem deixam o volume final não determinístico e esgotam o pool cooperativo. No nível médio: isEntitled() sem timeout pode deixar o widget cego para sempre com aparência de normalidade (.starting conta como saudável); polls de posição em voo reancoram a barra com valores obsoletos após seek/troca de faixa; a recuperação do stream depende 100% da morte do processo, sem observação de sleep/wake nem heartbeat contra o stream vivo-porém-mudo; e todo I/O de subprocesso bloqueia threads do pool cooperativo via waitUntilExit dentro de Task.detached. Cinco achados low completam: deadlock teórico na leitura sequencial de pipes do AppleScriptRunner, ordem de chunks dependente de comportamento não garantido de Tasks, buffer de linha não limpo na reconexão, views do menu fechado tiquetaqueando a 30 Hz fora da tela, e comandos one-shot do adapter sem observação de término. Nenhum data race clássico (mutação cross-thread sem sincronização) foi encontrado; os problemas são de ordenação, cancelamento e ciclo de vida de subprocessos.

### 18. [ALTO] readabilityHandler nunca removido: vazamento de FileHandle/fd e disparo contínuo em EOF a cada morte do stream

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:261`

O handler é instalado em openStream() (linha 261) e nunca é posto em nil — nem em stop() (247–253), nem em handleStreamTermination() (285–299), nem dentro do próprio handler quando availableData chega vazio (263, o sinal de EOF). Dois efeitos: (1) o dispatch source interno do FileHandle retém o handle enquanto o handler estiver instalado (a documentação da Apple manda explicitamente setar nil para parar), então cada Pipe de um stream morto vaza um file descriptor e um source vivos; (2) com o fd em EOF permanente, o source continua disparando o handler repetidamente com dados vazios — o guard da linha 263 retorna cedo mas não interrompe o ciclo, virando busy-loop numa fila de dispatch. O próprio código declara que 'o perl morrer é o modo de falha esperado, não o excepcional' (269–271): num app comercial rodando semanas, cada reconexão acumula um fd vazado e um handler girando. É degradação garantida com o tempo, no caminho que o projeto assume como rotineiro.

**Evidência:** NowPlayingController.swift:261-267: `stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in / let chunk = handle.availableData / guard !chunk.isEmpty else { return } ... }`. stop() (247–253) faz apenas `streamProcess?.terminate(); streamProcess = nil`; handleStreamTermination() (285–287) faz apenas `streamProcess = nil` e agenda reconexão. Nenhum ponto do arquivo atribui `readabilityHandler = nil` (grep confirma: única ocorrência é a instalação na linha 261).

**Recomendação:** No handler, ao receber chunk vazio (EOF), fazer `handle.readabilityHandler = nil` antes de retornar; e em stop()/handleStreamTermination() capturar o pipe do processo corrente e limpar o handler explicitamente antes de soltar a referência ao Process. Guardar a Pipe do stream ativo numa propriedade facilita isso.

**Veredito adversarial:** confirmado com impacto reduzido — severidade ajustada: **MÉDIO**. O verificador reproduziu o padrão na máquina (macOS 26.5.2, Swift 6.3.3). (a) Confirmado: o handler é instalado em `:261` e nunca vai a nil, em nenhum caminho. (b) **Refutado o vazamento de fd:** 10 ciclos de spawn/morte/`streamProcess = nil`, contando fds via `fcntl(F_GETFD)` — delta de fds **zero** em todos. Quando a última referência ao `Process` cai, o ARC libera `Pipe` → `FileHandle`, o `dealloc` cancela o dispatch source e fecha o fd; o `Process` é local a `openStream()` e só é retido por `streamProcess`, que `handleStreamTermination():286` zera primeiro — não há ciclo de retenção. (c) **Spin de EOF é real mas autolimitado:** ~1,05 milhão de invocações vazias por queda, a 100% de um core, porém com custo invariante à janela de observação (0,99 s / 1,00 s / 1,00 s medidos em janelas de 2 s, 6 s e 15 s) — o spin morre sozinho em ~1 s, quando o cancel do source vence a saturação da fila privada do `FileHandle`. Não é cumulativo entre reconexões. (d) Pior caso realista (adapter quebrado, perl morrendo ao subir, backoff saturando em 30 s): ~1 s de core a cada 30 s ≈ 3% de um core contínuo. **Conserto de uma linha, medido:** `handle.readabilityHandler = nil` dentro do guard de `:263` derruba de 1.057.462 invocações para **1**, e o CPU para 0,00 s. O verificador acrescentou que o stderr não drenado do processo de stream (`MediaRemoteAdapter.swift:151`) é um modo de falha mais grave que este — já registrado como achado próprio na dimensão de segurança.

### 19. [ALTO] Volume por-app dispara um osascript por evento de arrasto do slider, sem coalescência nem serialização — resultado final não determinístico

**Onde:** `Sources/MacMediaWidget/VolumeRouter.swift:95`

O NSSlider é contínuo (padrão da NSSliderCell; nada em VolumeSlider muda isso), então Coordinator.changed dispara a cada movimento do mouse. No alvo por-app, VolumeRouter.setVolume chama appPlayer.setVolume diretamente a cada tick (95–99) → AppleScriptPlayer.fireIfRunning → fire → `Task { await tell }` → `Task.detached { AppleScriptRunner.run }`, um fork/exec de osascript por evento, sem nenhuma coalescência (o comentário do SystemVolumeController diz que a aplicação é coalescida, mas isso só vale para o caminho do volume de sistema). Um arrasto gera dezenas de subprocessos osascript concorrentes; como cada um leva ~50–200 ms e nada os serializa, eles terminam fora de ordem e o último `set sound volume` aplicado pode ser um valor intermediário obsoleto — o volume final não corresponde à posição em que o usuário soltou o slider. De quebra, cada Task.detached bloqueia uma thread do pool cooperativo (largura = nº de núcleos) em waitUntilExit, então a rajada esgota o pool e trava todo o resto do trabalho assíncrono do app durante o arrasto. Mesmo o caminho de sistema, embora coalescido por ciclo de run loop (SystemVolumeController.swift:67–80), lança Task.detached concorrentes (76–78) sem garantia de ordem entre si.

**Evidência:** ContentView.swift:348/365: `VolumeSlider(value: volume.volume, ...) { volume.setVolume($0) }`; ContentView.swift:471: `@objc func changed(_ sender: NSSlider) { onChange(sender.doubleValue) }` (slider contínuo). VolumeRouter.swift:95-99: `if let appPlayer { appPlayer.setVolume(clamped) } else { system.setVolume(clamped) }` — sem coalescência. AppleScriptPlayer.swift:70-72: `func fire(_ body: String) { Task { await tell(body) } }`; 170-173: `override func setVolume(...) { fireIfRunning("set sound volume to \(level)") }`; 52: `await Task.detached { AppleScriptRunner.run(source) }.value` com waitUntilExit síncrono (AppleScriptRunner.swift:40).

**Recomendação:** Aplicar ao volume por-app a mesma coalescência do SystemVolumeController (guardar só o último valor pendente e aplicar um de cada vez), e serializar a aplicação: só disparar o próximo osascript quando o anterior terminar, sempre com o valor mais recente. Isso resolve a ordem, o flood de processos e a pressão no pool de uma vez.

**Veredito adversarial:** confirmado — severidade ajustada: **MÉDIO**. Fatos mecânicos confirmados: `VolumeSlider` (`ContentView.swift:445-473`) não seta `isContinuous` e o default do `NSSlider` é `true`; `VolumeRouter.setVolume` (`:95-99`) chama `appPlayer.setVolume` cru, sem coalescência, até o `fork/exec` com `waitUntilExit` (`AppleScriptRunner.swift:21-40`). O contraste prova intenção: `SystemVolumeController` (`:18-19, 67-80`) tem `pendingVolume`/`applyScheduled` com o comentário explícito "para o slider não disparar um osascript por frame de arrasto" — o autor conhecia o problema e não aplicou o mesmo cuidado ao caminho por-app. Atinge Apple Music e Spotify, não é caso de canto. **Refutado o não-determinismo do valor final:** justamente porque o pool satura, o executor global despacha FIFO e a última tarefa quase sempre termina por último; o risco se restringe ao último lote de ~W tarefas concorrentes. O esgotamento do pool também não trava a UI (o MainActor é o thread principal), mas mata as demais tasks detached. O efeito real é latência e desperdício, não corrupção — daí medium. **Nota adjacente do verificador:** `seek` (`AppleScriptPlayer.swift:151-154`) tem exatamente a mesma forma e o mesmo risco se a barra virar arrastável.

### 20. [MÉDIO] isEntitled() sem timeout: um perl pendurado deixa o widget cego para sempre, com health preso em .starting e aparência de normalidade

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:135`

start() delega a checagem de entitlement a um Task.detached (NowPlayingController.swift:234–244) que chama isEntitled(), e este faz `process.run(); process.waitUntilExit()` sem watchdog nenhum (MediaRemoteAdapter.swift:135–144). Se o subprocesso perl pendurar — carga do framework privado que trava, stall do XPC do MediaRemote após um update do macOS, exatamente o cenário estrutural que essa checagem existe para detectar —, o waitUntilExit nunca retorna: o stream nunca abre, não há retry, e `health` fica em `.starting`, que `AdapterHealth.isHealthy` trata como saudável (linha 37: `self == .healthy || self == .starting`), então a UI não avisa nada. O usuário fica com um card eternamente vazio, que é precisamente o sintoma que o enum AdapterHealth foi criado para eliminar (comentário nas linhas 22–27). Além disso, os dois Pipes criados por makeProcess nunca são drenados: se o comando `test` escrever mais que o buffer do pipe (64 KB) em stdout/stderr, o filho bloqueia na escrita e o waitUntilExit trava por esse segundo caminho também. Uma thread do pool cooperativo fica presa junto, para sempre.

**Evidência:** MediaRemoteAdapter.swift:135-144: `nonisolated static func isEntitled() -> Bool { let process = makeProcess(["test"]); do { try process.run(); process.waitUntilExit(); return process.terminationStatus == 0 } catch { return false } }` — sem timeout e sem leitura dos pipes criados em makeProcess (150-151). NowPlayingController.swift:37: `.starting` conta como isHealthy; 234-244: o resultado do detached é o único gatilho de openStream()/`.unavailable`.

**Recomendação:** Impor prazo à checagem: ler os pipes de forma assíncrona e correr o waitUntilExit contra um timeout (p.ex. 10 s via terminationHandler + Task com deadline); estourando, matar o processo com terminate()/SIGKILL e tratar como `.unavailable`. Alternativamente, drenar stdout/stderr com readabilityHandler descartável e usar terminationHandler em vez de waitUntilExit.

### 21. [MÉDIO] Poll de posição em voo aplica valor obsoleto: reancora a barra com posição pré-seek ou de outra faixa/player

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:337`

pollRealPositionIfNeeded() lança um Task não estruturado que, ao retornar de `await player.position()` (um osascript que pode levar mais de 1 s), aplica o valor incondicionalmente em anchorElapsed/anchorWall (340–342). Não há cancelamento nem validação de contexto: (1) após seek(to:), o código reancora na hora e seta `lastPositionPoll = Date()` (488–490), mas isso só atrasa o *próximo* poll — um poll iniciado antes do seek e ainda em voo aterrissa depois e devolve a âncora à posição antiga, fazendo a barra pular de volta logo após o usuário soltar o dedo (exatamente o defeito que o comentário da linha 487 diz evitar); (2) com polls espaçados por 1 s e AppleScript ocasionalmente mais lento que isso, dois polls concorrentes podem completar fora de ordem, reancorando com o valor mais velho; (3) se a faixa ou a sessão trocar entre o disparo e a resposta, a posição do player antigo é aplicada à faixa nova — o Task não confere se `activePlayer`/faixa ainda são os mesmos.

**Evidência:** NowPlayingController.swift:337-344: `Task { [weak self] in guard let value = await player.position() else { return }; guard let self else { return }; self.anchorElapsed = value; self.anchorWall = Date(); ... }` — sem verificação de faixa/player nem geração/cancelamento. 481-492 (seek): `anchorElapsed = seconds; anchorWall = Date(); lastPositionPoll = Date()` — não cancela poll em voo. AppleScriptPlayer.swift:142-145: position() roda osascript por subprocesso (latência variável).

**Recomendação:** Versionar a âncora: um contador (ou o par bundleIdentifier+título) capturado no disparo do poll e conferido na chegada — descartar a resposta se o seek/troca de faixa incrementou a versão nesse meio-tempo. Incrementar a versão em seek(), no case .reset e na troca de faixa.

### 22. [MÉDIO] Nenhuma defesa contra stream vivo-porém-mudo: recuperação depende 100% da morte do processo; sleep/wake não é observado

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:285`

O único caminho de recuperação do canal de leitura é o terminationHandler (272–274 → handleStreamTermination, 285–299): se o perl continuar vivo mas parar de emitir — conexão XPC/MediaRemote invalidada após sleep/wake prolongado, logout/login, restart do mediaremoted sem derrubar o cliente —, o widget fica congelado na última faixa com `health = .healthy` para sempre, sem reconexão e sem aviso. O grep do projeto confirma que não há nenhum observador de NSWorkspace.willSleepNotification/didWakeNotification nem heartbeat/staleness check sobre o stream. O comentário nas linhas 269–271 assume que toda falha se manifesta como morte do processo; um app comercial que roda semanas atravessa dezenas de ciclos de sleep e não pode apostar tudo nessa premissa — o modo de falha silencioso é justamente o que o enum AdapterHealth (22–27) existe para não deixar acontecer.

**Evidência:** NowPlayingController.swift:272-274: `process.terminationHandler = { ... handleStreamTermination() }` é o único gatilho de reconexão; 385-390: `health = .healthy` só muda com linha chegando; grep por `willSleep|didWake|NSWorkspace.shared.notificationCenter` em Sources/ não retorna nenhuma ocorrência.

**Recomendação:** Observar NSWorkspace.didWakeNotification e, no wake, reciclar o stream (terminate + reabrir — barato e determinístico). Complementarmente, um watchdog simples: se o stream não emitir nada por N minutos com um app de mídia rodando, derrubar e reabrir o subprocesso.

### 23. [MÉDIO] Chamadas bloqueantes (waitUntilExit/readDataToEndOfFile) dentro de Task.detached esgotam o pool cooperativo de Swift Concurrency

**Onde:** `Sources/MacMediaWidget/Players/AppleScriptRunner.swift:38`

Todo o I/O de subprocesso do app roda como código síncrono bloqueante dentro de tasks de Swift Concurrency: AppleScriptRunner.run (readDataToEndOfFile ×2 + waitUntilExit, linhas 38–40) chamado via `Task.detached` em AppleScriptPlayer.tell (52); SystemVolumeController.runOsascript idem (96–97) via Task.detached (33, 60, 76); MediaRemoteAdapter.isEntitled (139) via Task.detached (NowPlayingController.swift:234). O pool cooperativo tem largura fixa igual ao número de núcleos e o contrato da linguagem proíbe bloqueá-lo. Com poll de posição a 1 Hz, leituras de volume, comandos tell e um arrasto de slider simultâneos, poucas operações lentas de osascript (um player de mídia ocupado responde em centenas de ms, às vezes segundos) bastam para ocupar todas as threads e estagnar qualquer outro trabalho assíncrono do app — inclusive os próprios comandos de transporte disparados por fire(). É degradação sistêmica sob carga, invisível em teste rápido.

**Evidência:** AppleScriptRunner.swift:38-40: `let outData = stdout.fileHandleForReading.readDataToEndOfFile(); let errData = stderr.fileHandleForReading.readDataToEndOfFile(); process.waitUntilExit()`; AppleScriptPlayer.swift:52: `await Task.detached { AppleScriptRunner.run(source) }.value`; SystemVolumeController.swift:33/60/76: `Task.detached { _ = Self.runOsascript(...) }` com waitUntilExit na linha 97; NowPlayingController.swift:234: `Task.detached { let entitled = MediaRemoteAdapter.isEntitled() ... }`.

**Recomendação:** Tirar o bloqueio do pool: executar os subprocessos numa fila de dispatch própria (DispatchQueue serial/concorrente dedicada) e fazer a ponte para async com withCheckedContinuation acionada pelo terminationHandler do Process, lendo os pipes com readabilityHandler — nenhum waitUntilExit em thread do pool. Uma única implementação async de 'rodar subprocesso' substituiria as três cópias.

### 24. [BAIXO] Deadlock possível no AppleScriptRunner com stderr volumoso: leitura sequencial dos dois pipes

**Onde:** `Sources/MacMediaWidget/Players/AppleScriptRunner.swift:38`

O comentário nas linhas 36–37 mostra consciência do problema clássico ('ler antes de esperar'), mas a solução implementada só cobre metade: stdout e stderr são lidos sequencialmente. readDataToEndOfFile(stdout) só retorna quando o filho fecha stdout (ao sair); se antes disso o filho encher o buffer do pipe de stderr (64 KB) — um AppleScript que gere erro extenso ou logue muito —, ele bloqueia na escrita, nunca sai, stdout nunca fecha, e a chamada trava para sempre, levando junto a thread que a executa (do pool cooperativo, pelo achado anterior). Com as mensagens de erro curtas do osascript o caso é raro, por isso low — mas é um travamento permanente sem recuperação quando ocorre.

**Evidência:** AppleScriptRunner.swift:38-40: `let outData = stdout.fileHandleForReading.readDataToEndOfFile()` (bloqueia até EOF de stdout) seguido de `let errData = stderr.fileHandleForReading.readDataToEndOfFile()` — stderr só é drenado depois que stdout fecha; o filho bloqueado escrevendo em stderr impede exatamente esse fechamento.

**Recomendação:** Drenar os dois pipes concorrentemente (readabilityHandler em ambos acumulando em buffers, ou ler stderr numa fila paralela) antes do waitUntilExit — resolve junto com a refatoração do achado sobre o pool cooperativo.

### 25. [BAIXO] Ordem de entrega dos chunks do stream depende de comportamento não garantido de Tasks não estruturadas

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:264`

Cada invocação do readabilityHandler cria um `Task { @MainActor in self?.ingest(chunk) }` independente (264–266). O runtime atual enfileira jobs no MainActor na ordem de criação, mas a linguagem não garante FIFO entre tasks não estruturadas — é comportamento de implementação, não contrato. Como uma linha do adapter carrega a capa em base64 (centenas de KB, dezenas de chunks de pipe, conforme o próprio comentário das linhas 359–363), dois chunks ingeridos fora de ordem corromperiam a remontagem de linha em ingest(): o JSON falha o parse e a atualização (ou a capa) se perde silenciosamente. Hoje funciona; é fragilidade de contrato que uma mudança de runtime pode transformar em bug intermitente impossível de reproduzir.

**Evidência:** NowPlayingController.swift:261-267: um Task independente por chunk: `stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in let chunk = handle.availableData; guard !chunk.isEmpty else { return }; Task { @MainActor in self?.ingest(chunk) } }`; 366-383: ingest() remonta linhas por concatenação, dependente da ordem dos chunks.

**Recomendação:** Garantir a ordem estruturalmente: acumular os bytes numa fila serial própria (ou AsyncStream alimentado pelo handler, consumido por uma única task no MainActor). O AsyncStream preserva FIFO por construção e elimina a dependência do detalhe de runtime.

### 26. [BAIXO] Cadeias waitForSessionThenPlay sem cancelamento: play atrasado em até 15 s pode disparar contra a intenção atual do usuário

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:567`

waitForSessionThenPlay reagenda a si mesma via DispatchQueue.main.asyncAfter por até 30 tentativas (~15 s) sem nenhum token de cancelamento. switchTo() e playPause() podem iniciar cadeias concorrentes; nada invalida uma cadeia antiga quando o usuário muda de ideia. Cenário concreto: usuário aciona 'Trocar app' para o player B (abre B, cadeia esperando B virar sessão), desiste e volta ao player A dando play nele; se dentro da janela de 15 s o B terminar de abrir e assumir a sessão momentaneamente pausado, a cadeia obsoleta dispara `player.play()` — reprodução que ninguém pediu, segundos depois da última ação. As cadeias também sobrevivem a stop().

**Evidência:** NowPlayingController.swift:567-577: `private func waitForSessionThenPlay(_ player: Player, attempt: Int = 0) { ... if track.bundleIdentifier == player.bundleIdentifier { if !track.isPlaying { player.play() }; return } ... DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.waitForSessionThenPlay(player, attempt: attempt + 1) } }` — sem geração/cancelamento; chamadores em 527 (switchTo) e 559 (playPause).

**Recomendação:** Um contador de geração no controller: cada switchTo()/playPause() incrementa; a cadeia captura a geração no início e aborta se ela mudou. Alternativa: trocar a recursão por uma única Task armazenada em propriedade, cancelada ao iniciar intenção nova e em stop().

### 27. [BAIXO] Buffer de linha não é limpo na queda do stream: resto de linha do processo morto contamina a primeira linha do novo

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:285`

handleStreamTermination() zera streamProcess e agenda a reconexão, mas não limpa `buffer` (59). Se o perl morrer no meio de uma linha (caso típico de crash), o fragmento fica no acumulador e é concatenado ao primeiro chunk do stream novo: a linha híbrida falha o parse e a primeira atualização real pós-reconexão é descartada em silêncio — o widget mostra dado velho até a emissão seguinte. Autocorrige na próxima newline, por isso low, mas é sujeira de estado atravessando gerações de processo. stop() tem a mesma lacuna para o ciclo stop()/start().

**Evidência:** NowPlayingController.swift:285-299: handleStreamTermination() faz `streamProcess = nil`, atualiza health e agenda openStream — nenhuma menção a `buffer`; 366-383: ingest() concatena qualquer chunk ao acumulador existente e só descarta no parse falho da linha híbrida.

**Recomendação:** `buffer.removeAll(keepingCapacity: false)` em handleStreamTermination() e em stop().

### 28. [BAIXO] Menu da bandeja fechado mantém views SwiftUI vivas: timer de 30 Hz do letreiro e re-render a 2 Hz continuam rodando fora da tela

**Onde:** `Sources/MacMediaWidget/AppMenuController.swift:112`

O menu da bandeja é persistente (pendurado no NSStatusItem, statusMenu na linha 53) e populate() instala nele NSMenuItems com NSHostingViews (MenuStatusView na 117–121, MenuTransportView na 129–132). Quando o menu fecha, esses hosting views continuam vivos até a próxima abertura repopular: a assinatura do MarqueeText — Timer.publish a 30 Hz com autoconnect (MenuStatusView.swift:80–82) — segue disparando, e a MenuStatusView, observando o NowPlayingController, é invalidada a cada atualização de `displayedElapsed`, que o progressTimer publica a cada 0,5 s incondicionalmente (a atribuição de @Published emite objectWillChange mesmo com valor igual). Resultado: depois da primeira abertura do menu, o app carrega permanentemente um tick de 30 Hz e re-renders de views que ninguém vê. Custo individual pequeno, mas é consumo de CPU/energia contínuo e gratuito num app residente que roda semanas.

**Evidência:** AppMenuController.swift:49-55: menu persistente com delegate; 79-90 + 112-123: populate() cria os NSHostingViews que ficam pendurados no menu fechado. MenuStatusView.swift:80-82: `private let clock = Timer.publish(every: Self.tickInterval, on: .main, in: .common).autoconnect()` (tickInterval = 1/30 s, linha 74) com onReceive na 106. NowPlayingController.swift:304-308 + 317-318: displayedElapsed reatribuído a cada 0,5 s.

**Recomendação:** Em menuDidClose, substituir as views custom por itens vazios (ou repopular com placeholders) para derrubar os hosting views; ou dar ao MarqueeText/MenuStatusView um sinal de 'ativo' controlado por menuWillOpen/menuDidClose que pare o clock. Complemento barato: só reatribuir displayedElapsed quando o valor mudar.

### 29. [BAIXO] Comandos one-shot do adapter são dispara-e-esquece: processo pendurado nunca é observado nem colhido por watchdog

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:92`

run() faz try process.run() e abandona o Process: sem terminationHandler, sem timeout, e os dois Pipes criados em makeProcess (150–151) nunca são drenados. Falha episódica (exit ≠ 0) passa em silêncio — um next/pause que o adapter rejeitou vira botão que 'não fez nada' sem nenhum log além do catch de lançamento. E um perl que pendure conversando com o MediaRemote (o mesmo cenário do achado do isEntitled) fica residente para sempre, um por comando afetado; se escrever mais de 64 KB num pipe não lido, o bloqueio na escrita garante que nunca sai. Em uso normal a saída é minúscula e o processo termina rápido — por isso low —, mas transporte é a operação mais frequente do produto e não ter nenhuma observação de término é dívida que esconde falhas do usuário e do desenvolvedor.

**Evidência:** MediaRemoteAdapter.swift:92-99: `static func run(_ arguments: [String]) { let process = makeProcess(arguments); do { try process.run() } catch { NSLog(...) } }` — nenhuma referência retida, nenhum terminationHandler, nenhum timeout; 146-153: makeProcess cria `Pipe()` para stdout e stderr que ninguém lê.

**Recomendação:** Instalar terminationHandler que logue exit ≠ 0 (com o stderr curto lido no próprio handler) e um timeout que mate o processo após alguns segundos. Trocar os Pipes por FileHandle.nullDevice se a saída realmente não interessa — elimina o risco de bloqueio por buffer cheio.

---

## Performance e energia

*9 achados — 3 alto · 4 médio · 2 baixo*

Auditoria de performance do MacMediaWidget (widget 24/7). O padrão dominante é trabalho por tick onde deveria haver trabalho por evento: (1) o timer de progresso publica `displayedElapsed` a 2 Hz incondicionalmente — @Published emite mesmo sem mudança de valor — re-renderizando o card, o item de status do menu (cujo NSHostingView vive desde o launch, com o menu fechado) e o transporte do menu, 24/7, inclusive com o widget oculto; (2) o poll de posição real dispara um osascript por segundo mesmo com a música pausada (~86 mil processos/dia com Apple Music/Spotify pausado detendo a sessão); (3) os letreiros usam timers de 30 Hz sempre ativos — dois no card e um num item de menu invisível — recriados a cada re-render do pai. Achados médios: consultas NSWorkspace/LaunchServices (ícone, isRunning, isInstalled) dentro do body SwiftUI a 2 Hz; parse de JSON + decode de capa (centenas de KB base64 → NSImage) na main thread por linha do stream, sem dedup; arraste do volume por-app gerando um osascript por evento de tracking sem coalescência; e osascript bloqueante em Task.detached sem guarda de in-flight nem timeout, capaz de esgotar o pool cooperativo diante de um app travado. Baixos: redecodificação de capa idêntica com re-tint do card e varredura quadrática do buffer de linha na main thread. Nenhum vazamento de memória estrutural encontrado (registry com cache, buffer com teto de 8 MB); o custo de spawn por comando one-shot do adapter é decisão de arquitetura documentada e ficou fora dos achados. Correções nos três achados altos levam o app a idle de fato quando nada toca — o requisito mínimo para um utilitário residente comercial.

### 30. [ALTO] Timer de progresso publica a 2 Hz permanentemente e re-renderiza três hierarquias SwiftUI mesmo em idle total

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:304`

O `progressTimer` de 0,5 s é criado em `start()` e só morre em `stop()` (encerramento do app). A cada tick, `refreshDisplayedElapsed()` atribui `displayedElapsed` (@Published, linha 53) incondicionalmente — e `@Published` emite `objectWillChange` em toda atribuição, mesmo quando o valor não mudou (pausado, nada tocando, `displayedElapsed = 0` repetido). Três hierarquias observam o controller e reavaliam o body 2×/s, 24/7: o `ContentView` do card (ContentView.swift:30), o `MenuStatusView` do menu da bandeja — cujo `NSHostingView` é criado no launch (AppMenuController.swift:117-122, via App.swift:74) e fica vivo e observando com o menu fechado — e o `MenuTransportView` (AppMenuController.swift:129). O timer também não para quando o widget está oculto: `isWidgetVisible` só bloqueia o poll de posição (linha 328), não o tick nem a publicação. Num widget de desktop que roda 24/7, isso é CPU e wake-up constantes sem nenhuma mudança visível na tela.

**Evidência:** NowPlayingController.swift:302-309 — `let timer = Timer(timeInterval: 0.5, repeats: true) { ... refreshDisplayedElapsed() }` + `RunLoop.main.add(timer, forMode: .common)`; :317-320 — `displayedElapsed = estimatedElapsed(...)` sem comparação de igualdade; :53 — `@Published private(set) var displayedElapsed`; :247-253 — `stop()` é o único invalidate. AppMenuController.swift:112-123 — hosting view persistente do menu observando `nowPlaying`.

**Recomendação:** Só atribuir `displayedElapsed` quando o valor arredondado (ex.: para o 0,5 s da barra) mudou; pausar o timer quando `!isEffectivelyPlaying` e religar em transição de play (evento do stream), e pausar quando `isWidgetVisible == false`. Com isso o app fica de fato ocioso quando não há reprodução.

**Veredito adversarial:** confirmado — severidade ajustada: **MÉDIO**. Mecanismo confirmado linha a linha: o progressTimer de 0,5 s (NowPlayingController.swift:302-309) vive de start() a stop() (só no encerramento do app); refreshDisplayedElapsed() (:317-320) atribui o @Published displayedElapsed (:53) sem checar igualdade, e @Published emite objectWillChange em toda atribuição; isWidgetVisible (:328) só bloqueia o poll de posição, não o tick; três hierarquias observam o controller (ContentView.swift:30, MenuStatusView.swift:9, MenuTransportView.swift:8), com os hosting views do menu criados no launch (App.swift:74 → AppMenuController.swift:117-129) e vivos com o menu fechado. Porém o impacto está inflado: 2 Hz de reavaliação de body em três hierarquias pequenas custa frações de milissegundo, e como o output é idêntico em idle o diff do SwiftUI não comete layers — não há redraw nem custo de WindowServer/GPU; os hosting views fora de janela adiam commit. O timer permanente durante reprodução é necessário por desenho (Amazon Music não publica elapsedTime), então o desperdício real se limita a pausado/idle/oculto e é de magnitude pequena (faixa "Low" de energia). É defeito real de eficiência para um widget comercial 24/7, com correção trivial (guarda de igualdade + suspender timer sem reprodução/visibilidade), mas sem sintoma visível, jank ou dreno mensurável — impacto limitado: medium, não high.

### 31. [ALTO] Poll de posição real dispara um subprocesso osascript por segundo mesmo com a música pausada

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:330`

`pollRealPositionIfNeeded()` guarda apenas `isWidgetVisible` e a capacidade `.realPosition` — não verifica `track.isPlaying`. Com Apple Music ou Spotify detendo a sessão em pausa (situação comum: usuário pausa e deixa o app aberto por horas/dias), o widget faz fork/exec de `/usr/bin/osascript` + Apple Event ao player a cada 1 s, indefinidamente — ~86.000 processos por dia para reler uma posição que não se move. É custo de energia e CPU contínuo que o Activity Monitor/powermetrics atribui ao produto, fatal para um app comercial que vive em background.

**Evidência:** NowPlayingController.swift:327-344 — `guard isWidgetVisible, let player = activePlayer, player.capabilities.contains(.realPosition) else { return }` (sem checagem de isPlaying), seguido de `Task { await player.position() }` a cada 1 s; AppleScriptPlayer.swift:142-145 — `position()` → `tell("get player position")` → AppleScriptRunner.swift:21-41 — spawn de osascript por chamada.

**Recomendação:** Acrescentar `track.isPlaying` (ou `isEffectivelyPlaying`) ao guard. Um seek externo com a mídia pausada é coberto reancorando no próximo evento do stream ou com um único poll na transição pausa→play.

**Veredito adversarial:** confirmado — severidade ajustada: **ALTO**. Confirmado no código real. NowPlayingController.swift:327-335: o guard de pollRealPositionIfNeeded() checa apenas isWidgetVisible, activePlayer e .realPosition — sem nenhuma checagem de track.isPlaying/isEffectivelyPlaying. O progressTimer (linhas 302-309) roda a 0,5s permanentemente e chama o poll a cada tick, com throttle de 1/s (linha 334). AppleScriptPlayer.position() (linhas 142-144) só barra app fechado (guard isRunning) — app pausado passa e executa tell("get player position"), que em AppleScriptRunner.run (linhas 21-40) é fork/exec de /usr/bin/osascript por chamada, como o próprio comentário do arquivo admite ("cada chamada custa um fork/exec... usar com parcimônia"). Apple Music e Spotify declaram .realPosition (AppleMusicPlayer.swift:23, SpotifyPlayer.swift:30), e a sessão pausada persiste por horas (o comentário na linha 426 do controller reconhece "faixa parada há horas"). Refutações testadas e descartadas: isWidgetVisible só vira false ao ocultar pela bandeja (WidgetWindow.swift:207/218) — em uso normal o widget desktop fica "visível" sempre, inclusive coberto ou com tela bloqueada; isRunning não cobre pausa. O projeto inclusive gateia o mesmo custo por visibilidade ("não faz sentido pagá-lo por uma barra que ninguém está vendo") e congela a barra na pausa, mas esqueceu o estado pausado no poll — o mais duradouro. Único exagero é o adjetivo "fatal"; o defeito é real: subprocesso + Apple Event por segundo, indefinidamente, em app comercial always-on, com custo de energia/CPU contínuo atribuível ao produto. Nota para a correção: gate puro em isPlaying perderia seek feito no player pausado — o certo é poll mais lento na pausa, não ausente. Severidade high mantida.

### 32. [ALTO] Timers de 30 Hz do letreiro rodam permanentemente — inclusive num item de menu fechado — e são recriados a cada re-render do pai

**Onde:** `Sources/MacMediaWidget/MenuStatusView.swift:80`

`MarqueeText` cria `Timer.publish(every: 1/30, on: .main, in: .common).autoconnect()` como propriedade da view e assina via `onReceive` (linha 106) incondicionalmente — o timer dispara 30×/s mesmo quando o texto cabe (`tick()` retorna cedo, mas o wake-up do processo já aconteceu). O card tem dois `CardMarquee` (título e artista, ContentView.swift:160 e 214) = 60 wake-ups/s contínuos com o widget na mesa. Pior: o menu da bandeja é persistente e seu `MenuStatusView` fica vivo com o menu fechado (AppMenuController.swift:49-55, 112-123), então há um terceiro timer de 30 Hz ticando para uma view invisível — e com título longo em exibição, `tick()` muta `offset` (@State) 30×/s, animando um letreiro que ninguém vê, para sempre. Além disso, `clock` é `let` de struct: cada reavaliação do body do pai (2×/s pelo achado do `displayedElapsed`) recria o publisher e força o `onReceive` a cancelar e reassinar um Timer novo — churn permanente de criação/destruição de timers no run loop principal.

**Evidência:** MenuStatusView.swift:74-82 — `tickInterval = 1.0/30.0` e `private let clock = Timer.publish(every: Self.tickInterval, on: .main, in: .common).autoconnect()`; :106-108 — `.onReceive(clock)` sem condição; :111-113 — `tick()` só então checa `overflows`. AppMenuController.swift:117-122 — `NSHostingView(rootView: MenuStatusView(...))` no menu persistente criado no launch (App.swift:74). ContentView.swift:545-565 — `CardMarquee` usa o mesmo `MarqueeText`.

**Recomendação:** Ligar o timer apenas quando `overflows == true` e a view está visível (ex.: `TimelineView(.animation(paused:))`, ou assinar/cancelar o publisher com `onChange(of: overflows)`); no menu, criar as views custom em `menuWillOpen` e descartá-las em `menuDidClose` em vez de mantê-las vivas o tempo todo; mover o publisher para `@State` para não recriá-lo a cada init da struct.

### 33. [MÉDIO] Consultas a NSWorkspace/LaunchServices (ícone, isRunning, isInstalled) executadas dentro do body do SwiftUI a 2 Hz

**Onde:** `Sources/MacMediaWidget/ContentView.swift:169`

Como o body do `ContentView` reavalia 2×/s (achado do `displayedElapsed`), tudo que ele computa vira custo recorrente: `titleRow` chama `sourcePlayer?.icon`, que a cada acesso faz `NSWorkspace.shared.urlForApplication` + `NSWorkspace.shared.icon(forFile:)` (Player.swift:143-146) e devolve um `NSImage` novo — além do custo da consulta ao LaunchServices, a identidade nova a cada render impede o diff do SwiftUI e o ícone é redesenhado a cada tick. `controls` avalia `skipUnavailableReason` ×2 → `canControlTransport` → `controlledPlayer.isRunning`, que enumera `NSRunningApplication.runningApplications(withBundleIdentifier:)` (Player.swift:137-140); `subtitlePlaceholder` → `transportUnavailableReason` ainda soma `isInstalled` (urlForApplication) quando não há sessão. Resultado: várias chamadas com IPC por segundo, para sempre, num app ocioso.

**Evidência:** ContentView.swift:169 — `else if let icon = sourcePlayer?.icon`; Player.swift:143-146 — `var icon: NSImage? { ... NSWorkspace.shared.icon(forFile: url.path) }` (computed, sem cache); Player.swift:137-140 — `isRunning` enumera runningApplications a cada acesso; NowPlayingController.swift:175-181, 205-217 — `canControlTransport`/`transportUnavailableReason` acessam `isRunning`/`isInstalled` por avaliação.

**Recomendação:** Cachear o ícone por bundle id (dicionário estático ou no próprio Player, invalidando raramente); manter `isRunning` como estado atualizado por notificações do `NSWorkspace` (`didLaunchApplication`/`didTerminateApplication`) em vez de consulta por render. Resolver o achado do timer de 2 Hz reduz o sintoma, mas o cache é o conserto correto — o body deve ser barato por construção.

### 34. [MÉDIO] Parse de JSON e decodificação da capa (centenas de KB de base64 + NSImage) na main thread a cada linha do stream

**Onde:** `Sources/MacMediaWidget/NowPlayingParser.swift:64`

O handler do stream salta para a MainActor com o chunk cru (NowPlayingController.swift:264-266) e todo o pipeline roda na main thread: `JSONSerialization` sobre a linha inteira — que carrega a capa como base64, centenas de KB segundo o próprio comentário do teto de buffer (NowPlayingController.swift:359-363) —, depois `Data(base64Encoded:)` e `NSImage(data:)`. Numa troca de faixa isso é parse de JSON grande + decode de base64 + decodificação de imagem, tudo bloqueando a thread de UI; o hitch coincide exatamente com o momento em que o card anima a transição de faixa. Não há dedup: se o adapter reenviar `artworkData` idêntico (snapshot completo), paga-se o decode inteiro de novo, com um `NSImage` novo que também dispara o `.task(id: track.artwork)` e um novo `averageColor()` (desenho da imagem inteira com interpolação alta, ContentView.swift:478-500).

**Evidência:** NowPlayingController.swift:261-267 — `readabilityHandler` → `Task { @MainActor in self?.ingest(chunk) }`; NowPlayingParser.swift:11 — `@MainActor enum NowPlayingParser`; :39 — `JSONSerialization.jsonObject(with: data)`; :64-67 — `Data(base64Encoded: b64)` + `NSImage(data: imgData)` por linha com artworkData; ContentView.swift:81-89 — `.task(id: track.artwork)` com identidade de objeto NSImage.

**Recomendação:** Fazer parse e decode da capa fora da main thread (o parser já é isolado da UI; trocar o `ISO8601DateFormatter` compartilhado por um por-instância ou `Date.ISO8601FormatStyle`, que é Sendable, remove o motivo do @MainActor) e publicar só o resultado pronto. Deduplicar a capa por hash dos bytes antes de decodificar, evitando redecodificar e re-tonalizar a mesma arte.

### 35. [MÉDIO] Arrastar o slider de volume por-app dispara um processo osascript por evento de tracking, sem coalescência

**Onde:** `Sources/MacMediaWidget/VolumeRouter.swift:96`

No caminho por-app, `VolumeRouter.setVolume` chama `appPlayer.setVolume(clamped)` direto a cada evento do `NSSlider` (ação contínua, um evento por ciclo de tracking do mouse), e `AppleScriptPlayer.setVolume` → `fireIfRunning` cria um `Task` que faz fork/exec de osascript por chamada — dezenas de processos por segundo durante um arraste. O `SystemVolumeController` até tenta coalescer (comentário nas linhas 9-10 mostra que o risco era conhecido), mas a coalescência via `DispatchQueue.main.async` só funde eventos do mesmo ciclo de run loop — entre ciclos ela não segura nada — e o caminho por-app não tem coalescência alguma. Em máquinas mais lentas isso empilha processos e o volume do app 'anda sozinho' processando a fila depois que o usuário soltou.

**Evidência:** VolumeRouter.swift:89-100 — `setVolume` chama `appPlayer.setVolume(clamped)` sem throttle; AppleScriptPlayer.swift:170-173 — `setVolume` → `fireIfRunning("set sound volume to \(level)")` → :70-72 `fire` cria Task → AppleScriptRunner spawn; SystemVolumeController.swift:65-80 — coalescência apenas intra-ciclo (`applyScheduled` resetado no mesmo `DispatchQueue.main.async`); ContentView.swift:448-472 — NSSlider com action contínua padrão.

**Recomendação:** Aplicar throttle com borda de saída (~100 ms) na escrita de volume dos dois caminhos: guardar o último valor pedido e só disparar um novo osascript quando o anterior terminar ou após o intervalo — uma fila de profundidade 1, igual à intenção do `pendingVolume`, mas atravessando ciclos de run loop.

### 36. [MÉDIO] Chamadas bloqueantes de osascript em Task.detached sem limite de concorrência podem empilhar e esgotar o pool cooperativo

**Onde:** `Sources/MacMediaWidget/Players/AppleScriptPlayer.swift:52`

`tell()` executa `AppleScriptRunner.run` — que bloqueia em `waitUntilExit` — dentro de `Task.detached`, ocupando uma thread do pool cooperativo do Swift Concurrency (largura = número de núcleos) durante toda a vida do subprocesso. O poll de posição lança uma chamada nova a cada segundo sem verificar se a anterior terminou (`lastPositionPoll` limita o lançamento, não o in-flight — NowPlayingController.swift:333-343), e um Apple Event a um app travado/beachball não tem timeout: os osascript penduram, as tasks se acumulam a 1/s e, com poucos travamentos simultâneos, o pool cooperativo inteiro fica bloqueado — todo o trabalho async do app (leitura de volume, `isEntitled`, etc.) para, além do acúmulo sem teto de processos osascript vivos.

**Evidência:** AppleScriptPlayer.swift:52 — `let result = await Task.detached { AppleScriptRunner.run(source) }.value`; AppleScriptRunner.swift:38-40 — `readDataToEndOfFile()` + `waitUntilExit()` bloqueantes; NowPlayingController.swift:333-343 — throttle por `lastPositionPoll` sem guarda de tarefa em voo.

**Recomendação:** Guardar um flag de poll em voo (pular o tick se o anterior não voltou) e impor timeout ao osascript (terminate após N segundos, como o próprio protocolo de sessões faz com watchdog). Idealmente, mover a execução para uma fila serial própria (Dispatch) ou usar `terminationHandler` assíncrono em vez de bloquear thread do pool cooperativo.

### 37. [BAIXO] Sem dedup da capa: cada linha com artworkData aloca um NSImage novo e re-tonaliza o card, mesmo com a arte idêntica

**Onde:** `Sources/MacMediaWidget/NowPlayingParser.swift:67`

`parse` cria um `NSImage` novo para toda linha que traga `artworkData`, sem comparar com a arte já exibida. Como `TrackInfo.artwork` participa do `Equatable` por identidade de objeto e o `.task(id: track.artwork)` do ContentView usa essa identidade, qualquer reemissão da mesma capa (snapshot completo do adapter, reconexão do stream) gera decode + alocação de centenas de KB + novo `averageColor()` (desenho da imagem inteira) + reavaliação do vidro do card. Também é churn de memória a cada troca de faixa: a imagem antiga só é liberada quando a nova a substitui em todos os observadores.

**Evidência:** NowPlayingParser.swift:64-67 — decode incondicional de `artworkData`; ContentView.swift:81-89 — `.task(id: track.artwork)` refaz tint por identidade de NSImage; NowPlayingController.swift:359-363 — comentário confirma capas de centenas de KB por linha.

**Recomendação:** Guardar um hash (ou o próprio Data base64 truncado) da última capa e só decodificar quando os bytes mudarem; reutilizar a instância NSImage anterior quando iguais, preservando a identidade e evitando o re-tint.

### 38. [BAIXO] Acumulador do stream re-escaneia e desloca o buffer a cada chunk de linha grande

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:376`

`ingest` procura `\n` com `firstIndex` a partir do início do buffer a cada chunk recebido e remove a linha com `removeSubrange(startIndex...idx)`, que desloca todos os bytes restantes. Para as linhas com capa (centenas de KB chegando em chunks de pipe de ~64 KB), o prefixo acumulado é re-escaneado a cada chunk e o restante é copiado a cada linha consumida — custo quadrático no tamanho da linha. O teto de 8 MB limita o pior caso e `memchr` é rápido, então o impacto real é pequeno; registra-se como dívida porque roda na main thread, somado ao parse do achado de decodificação.

**Evidência:** NowPlayingController.swift:366-383 — `buffer.append(chunk)`; `while let idx = buffer.firstIndex(of: newline)` re-escaneando desde `startIndex`; `buffer.removeSubrange(buffer.startIndex...idx)` deslocando o restante; `Data(lineData)` copiando a linha.

**Recomendação:** Manter um índice de varredura persistente (só escanear os bytes novos do chunk) e consumir o buffer por offset, compactando de vez em quando — ou trocar por um framing que leia com `FileHandle.bytes.lines` fora da main thread.

---

## Correção e lógica

*13 achados — 1 alto · 4 médio · 8 baixo*

Auditoria de correção do MacMediaWidget (13 achados, todos com evidência lida no código). O mais grave é a integração VolumeRouter↔UI: o alvo do volume só é reavaliado quando o bundle id do player controlado muda, mas depende de isRunning/capabilities — fechar o player preferido deixa o slider morto apontando para um app que não existe mais (high), e o valor exibido nunca é relido após a leitura inicial, ignorando mudanças externas de volume (medium). No parsing, snapshots (diff=false) com conteúdo são mesclados como diffs, deixando artwork/álbum/duração da faixa anterior grudados — capa errada no card e aritmética de barra contaminada (medium). No roteamento de comandos: playPause ignora o gate de fonte oculta que o próprio SelfTests declara como invariante, com o símbolo do botão mostrando \"play\" e a ação pausando (medium); e trocar para um atalho web (YouTube Music) pausa o próprio serviço e espera 15 s por uma sessão que o modelo do projeto garante que nunca existirá (medium). Os demais são races de leitura assíncrona (volume de outro app, poll de posição atropelando seek), mensagens/estado de saúde enganosos, o antipadrão de pipe não drenado que o próprio projeto documenta em outro arquivo, campos mortos com semântica errada em TrackInfo e uma tabela de compatibilidade defasada em relação ao código do Safari. Nenhum crash ou force-unwrap perigoso encontrado; a disciplina de capabilities-por-evidência está, no geral, corretamente refletida no código.

### 39. [ALTO] Alvo do volume fica obsoleto: retarget só dispara quando o bundle id muda, mas depende de isRunning/capabilities

**Onde:** `Sources/MacMediaWidget/ContentView.swift:92`

O único ponto que chama VolumeRouter.retarget é `.task(id: nowPlaying.controlledPlayer.bundleIdentifier)` (ContentView.swift:92). Mas a decisão do alvo depende de `player.isRunning` e de `capabilities.contains(.appVolume)` (VolumeRouter.swift:57-63), que mudam sem o bundle id mudar. Caso concreto e cotidiano: player preferido = Apple Music tocando (alvo = volume do app); o usuário fecha o Apple Music; a sessão reseta e `controlledPlayer` volta a ser o preferido — o MESMO bundle id — então o task não reexecuta. O `target` continua `.app`, `appPlayer` continua setado, e `setVolume` cai em `fireIfRunning`, que é no-op com o app fechado (AppleScriptPlayer.swift:79-81). Resultado: o slider de volume mexe visualmente e não controla nada, com o tooltip ainda dizendo "Apple Music volume". O inverso também ocorre (app abre depois e o alvo fica preso no sistema), e o rebaixamento por Automação negada tampouco reavalia o alvo — contrariando o comentário de AppleScriptPlayer.swift:158-161 de que "o VolumeRouter passa a mexer no volume de saída do sistema por conta própria".

**Evidência:** ContentView.swift:92 `.task(id: nowPlaying.controlledPlayer.bundleIdentifier) { volume.retarget(to: nowPlaying.controlledPlayer) }`; VolumeRouter.swift:57-63 `let usesAppVolume = player?.capabilities.contains(.appVolume) == true && player?.isRunning == true`; AppleScriptPlayer.swift:79-81 `func fireIfRunning(_ body: String) { guard isRunning else { return } ... }` — nenhum outro call site de retarget/refresh no projeto (grep confirmou ContentView:92 como único).

**Recomendação:** Reavaliar o alvo em evento, não só por id: chamar `retarget` também quando `isRunning`/`capabilities` do player controlado mudarem — por exemplo, num timer leve junto do progressTimer, ou observando NSWorkspace.didLaunch/didTerminateApplicationNotification para o bundle id controlado, e após qualquer rebaixamento por -1743.

**Veredito adversarial:** confirmado — severidade mantida: **ALTO**. Os quatro elos se confirmam. (a) `retarget` existe só em `VolumeRouter.swift:57` e é chamado só em `ContentView.swift:93`. (b) `.task(id:)` só reinicia quando o id ou a identidade da view muda; nada aqui recria a identidade. (c) Confirmado e pior: em `NowPlayingController.swift:103-108`, no modo **fixo** `controlledPlayer` é sempre o preferido — o bundle id nunca muda, então fechar/abrir o player nunca reavalia o alvo. `PlayerRegistry.swift:18-27` mantém cache por id, então `appPlayer` é a mesma instância e `isRunning` vira false sem notificar ninguém. (d) `setVolume` cai em `fireIfRunning` → `guard isRunning else { return }` (`AppleScriptPlayer.swift:79-81`): no-op silencioso, com o slider sempre habilitado e `.help` ainda rotulando o app errado. **Refutação do "impacto inflado" não se sustenta:** o caso da Automação negada é permanente. O comentário em `AppleScriptPlayer.swift:157-161` promete que o router passa ao volume do sistema após `-1743` — falso: as capacidades rebaixam, mas nada reavalia o alvo, e o volume é o único comando sem fallback para o MediaRemote (transporte e seek têm `guard !isAuthorizationDenied`). Quem nega a permissão fica com o slider morto e rotulado errado para sempre.

### 40. [MÉDIO] Snapshot (diff=false) com conteúdo é mesclado como diff: artwork, álbum, duração e demais campos velhos ficam grudados

**Onde:** `Sources/MacMediaWidget/NowPlayingParser.swift:49`

O parser só trata o snapshot como substituição no caso do reset total (sem bundleIdentifier e sem title). Qualquer outro snapshot cai em `var t = current` e mescla campo a campo — semanticamente errado: num snapshot, campo ausente significa "não existe", não "não mudou". Consequência visível: `artwork` nunca é limpo fora do reset (linhas 64-68 só atribuem), então uma faixa/fonte sem capa exibe a capa da faixa anterior indefinidamente; `album`, `duration` e `elapsedTime` idem. Duração velha ainda contamina a aritmética da âncora no controller (`if let dur = t.duration ?? track.duration, sinceStart > dur` em NowPlayingController.swift:428) e a fração da barra de progresso (ContentView.swift:270-274). O cenário típico é a troca de dono da sessão (ex.: Amazon Music → Chrome, cujo payload não traz álbum) ou faixa sem capa depois de uma com capa.

**Evidência:** NowPlayingParser.swift:43-49 `let isSnapshot = (obj["diff"] as? Bool) == false; if isSnapshot, payload["bundleIdentifier"] == nil, payload["title"] == nil { return .reset }` seguido de `var t = current` — o merge roda igual para snapshot e diff; NowPlayingParser.swift:64-68 só define `t.artwork` quando `artworkData` chega, nunca limpa.

**Recomendação:** Quando `diff == false` e o payload tem conteúdo, partir de `TrackInfo()` (preservando no máximo o que o snapshot traz) em vez de mesclar sobre `current`. No mínimo, limpar `artwork`, `album`, `duration` e `elapsedTime` quando o snapshot não os traz, e limpar `artwork` quando o `bundleIdentifier` ou o par título/artista muda sem nova capa.

### 41. [MÉDIO] playPause controla a fonte oculta (contrariando o próprio invariante testado) e o símbolo do botão faz o oposto do que promete

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:541`

O SelfTests afirma o desenho: fonte oculta tocando → `!controller.canControlTransport` ("nem controla o que decidiu não exibir", SelfTests.swift:710). Mas `playPause()` não passa por `canControlTransport`: no modo automático com um app oculto tocando, `isControlledPlayerActive` é true e `target.isRunning` é true, então o branch 1 dispara o toggle global e pausa/despausa o app que o usuário mandou o widget ignorar. Pior: `playPauseSymbol` lê `displayedTrack.isPlaying`, que é o TrackInfo vazio nesse estado — o botão mostra "play.fill" e o clique PAUSA a música. O mesmo descompasso símbolo/ação ocorre no modo fixo quando o player escolhido toca sem ser a sessão. O botão central nunca é desabilitado na UI (ContentView.swift:328-330, sem .disabled).

**Evidência:** NowPlayingController.swift:541-544 `if isControlledPlayerActive, target.isRunning { target.playPause(); return }` (sem checar isActiveSourceHidden); :158-161 `return displayedTrack.isPlaying ? "pause.fill" : "play.fill"` com displayedTrack vazio para fonte oculta (:121-127); SelfTests.swift:710 `expect(!controller.canControlTransport, "nem controla o que decidiu não exibir")`.

**Recomendação:** Em `playPause()`, tratar a fonte oculta explicitamente (não mandar toggle global quando `isActiveSourceHidden`, ou cair no fluxo de assumir o player preferido), e derivar o símbolo do mesmo estado que a ação vai usar — se a ação é sobre a sessão real, o símbolo deve ler `track`, não `displayedTrack`.

### 42. [MÉDIO] Trocar para um atalho de serviço web pausa o próprio serviço e espera uma sessão que nunca existirá

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:512`

`switchTo` decide "já é a sessão" comparando `track.bundleIdentifier != player.bundleIdentifier`. Para o atalho YouTube Music, `player.bundleIdentifier` é o PWA (`com.google.Chrome.app.cinh…`), mas a sessão publica como `com.google.Chrome` — pelo modelo do próprio projeto, o atalho NUNCA identifica sessão (PlayerCatalog.swift:47-49 e teste `atalhoDoYouTubeMusicNãoÉSessão`). Logo: com o YouTube Music já tocando no Chrome, escolher "YouTube Music" no menu pausa a música do usuário (o `pause` global da linha 519 vai exatamente para ela), abre o PWA/página, e `waitForSessionThenPlay` fica 15 s esperando `track.bundleIdentifier == PWA-id`, condição impossível — desiste sem retomar nada. A ação do menu resulta em silêncio.

**Evidência:** NowPlayingController.swift:512 `guard track.bundleIdentifier != player.bundleIdentifier else { ... }`; :519 `if track.isPlaying { MediaRemoteAdapter.send(.pause) }`; :569 `if track.bundleIdentifier == player.bundleIdentifier` no wait; PlayerCatalog.swift:47-49 "a sessão de Now Playing sai como o navegador de qualquer forma"; SelfTests.swift:451-457 confirma que o atalho nunca é sessão.

**Recomendação:** Tratar `PlayerCatalog.isShortcut(player.catalogID)` em `switchTo`: para atalho, comparar a sessão com o bundle do navegador hospedeiro (ou não pausar) e não entrar em `waitForSessionThenPlay` — apenas trazer a página/PWA à frente, que é o máximo que a plataforma permite.

### 43. [MÉDIO] Volume exibido nunca é relido: mudanças externas (teclas de volume, ajuste dentro do app) não chegam ao slider

**Onde:** `Sources/MacMediaWidget/VolumeRouter.swift:74`

`refresh()` só é chamado dentro de `retarget`, e `retarget` só roda quando o bundle id do player controlado muda (ContentView.swift:92). `SystemVolumeController.readCurrentState` roda no init e comenta "pode ser rechamado quando o widget reaparece", mas ninguém rechama. Resultado: o usuário mexe no volume pelas teclas do Mac (ou dentro do Apple Music/Spotify) e o slider do widget fica congelado no valor antigo; o próximo clique no slider salta o volume real para o valor obsoleto exibido. Num widget sempre visível cujo controle central é volume, é um defeito de produto perceptível no primeiro dia de uso.

**Evidência:** Grep no projeto: único call site de `retarget`/`refresh` é ContentView.swift:92-94; VolumeRouter.swift:73-85 `refresh()` chamado apenas em `retarget` (linha 70); SystemVolumeController.swift:29-30 comentário admite a necessidade de reler sem que exista chamador.

**Recomendação:** Reler o estado do alvo periodicamente enquanto o widget está visível (o progressTimer de 0,5 s do controller já existe como carona; 1 leitura/2 s basta) ou, para o volume do sistema, ouvir as notificações de mudança de volume do CoreAudio em vez de osascript.

### 44. [BAIXO] Leitura assíncrona de volume por-app pode gravar o valor de outro player (guard só confere target.isApp)

**Onde:** `Sources/MacMediaWidget/VolumeRouter.swift:81`

`refresh()` captura `appPlayer` e, ao voltar do subprocesso AppleScript, só confere `self.target.isApp` — não se o alvo ainda é O MESMO app. Numa troca rápida Apple Music → Spotify, dois `refresh` ficam em voo; se o do player antigo retornar por último, o slider exibe o volume do app errado, e como `refresh` só roda no `retarget`, o valor errado persiste até a próxima troca de fonte.

**Evidência:** VolumeRouter.swift:79-84 `Task { guard let value = await appPlayer.volume() else { return }; guard let self, self.target.isApp else { return }; self.volume = value ... }` — nenhuma comparação entre o `appPlayer` capturado e o `self.appPlayer` atual.

**Recomendação:** No retorno do Task, comparar identidade: `guard self.appPlayer === appPlayer else { return }` (além do `target.isApp`).

### 45. [BAIXO] Poll de posição em voo reancora por cima de um seek ou troca de faixa

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:340`

`pollRealPositionIfNeeded` dispara um Task que espera um subprocesso AppleScript. `seek(to:)` ajusta `lastPositionPoll` para suprimir o PRÓXIMO poll, mas não invalida o que já está em voo: o valor velho retorna depois do seek e sobrescreve `anchorElapsed`, fazendo a barra saltar de volta por até ~1 s até o poll seguinte corrigir. O mesmo vale para troca de faixa/reset: o resultado da faixa anterior pode reancorar a nova. Autocorrige em ~1 s, por isso severidade baixa — mas é exatamente o pulo que o comentário da linha 487 diz querer evitar.

**Evidência:** NowPlayingController.swift:337-343 `Task { guard let value = await player.position() else { return } ... self.anchorElapsed = value }` sem token de geração; :486-491 `seek` só faz `lastPositionPoll = Date()`, que não alcança o Task pendente.

**Recomendação:** Guardar um contador de geração da âncora (incrementado em seek/reset/troca de faixa) e descartar o resultado do poll se a geração mudou entre o disparo e o retorno.

### 46. [BAIXO] Tooltip de transporte mente para fonte oculta: "X is not playing" com X tocando

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:216`

Com a sessão de um app oculto tocando (modo automático), `canControlTransport` é false por causa de `isActiveSourceHidden`, mas `transportUnavailableReason` não considera esse caso: o app está instalado e rodando, então a cadeia cai em `playerNotPlaying(name)` — "Amazon Music is not playing" — enquanto ele está tocando. A mensagem aparece nos tooltips dos botões prev/next desabilitados (ContentView.swift:321-333).

**Evidência:** NowPlayingController.swift:179 `if isControlledPlayerActive { return !isActiveSourceHidden }`; :205-217 a cadeia de motivos testa shortcut/instalado/rodando e termina em `L10n.playerNotPlaying(name)` sem ramo para fonte oculta.

**Recomendação:** Adicionar um ramo no início de `transportUnavailableReason`: se `isActiveSourceHidden`, devolver `L10n.sourceHidden(name)` (ou variante), que é a verdade.

### 47. [BAIXO] Qualquer linha no stdout — inclusive lixo não-JSON — marca o canal como saudável

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:387`

`handleLine` seta `health = .healthy` e zera `reconnectAttempt` ANTES de parsear. Um adapter em estado degenerado que despeje texto de erro terminado em \n (o parse devolve `.ignored`) mantém o widget reportando canal são e reseta o backoff exponencial a cada linha de lixo — o estado `AdapterHealth` existe justamente para distinguir isso.

**Evidência:** NowPlayingController.swift:386-390 `if health != .healthy { health = .healthy; reconnectAttempt = 0 }` antes do `switch NowPlayingParser.parse(...)`; o caso `.ignored` retorna sem reverter.

**Recomendação:** Só promover a `.healthy` (e zerar o contador) quando o parse resultar em `.update` ou `.reset`.

### 48. [BAIXO] isEntitled() faz waitUntilExit com pipes anexados e nunca drenados — o antipadrão que o próprio projeto documenta

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:139`

`makeProcess` anexa Pipe a stdout e stderr (linhas 150-151). `isEntitled()` roda `test` e chama `waitUntilExit()` sem ler nenhum dos dois: se o comando escrever mais que o buffer do pipe (~64 KB — por exemplo, um erro verboso do perl/framework numa versão futura do macOS), o filho bloqueia no write e o `waitUntilExit` nunca retorna. Roda em `Task.detached` (não trava a UI), mas a saúde ficaria em `.starting` para sempre e o stream nunca abriria — sem aviso. O AppleScriptRunner.swift:36-38 documenta e evita exatamente esse deadlock ("Ler antes de esperar: um pipe cheio bloqueia o processo filho"). Os one-shot de `run()` (send/seek) têm o mesmo padrão: pipes nunca lidos e término nunca observado.

**Evidência:** MediaRemoteAdapter.swift:135-144 `try process.run(); process.waitUntilExit()` sem `readDataToEndOfFile()`; :146-152 `process.standardOutput = Pipe(); process.standardError = Pipe()`; contraste com AppleScriptRunner.swift:36-40 que lê antes de `waitUntilExit`.

**Recomendação:** Em `isEntitled()`, drenar os pipes antes do `waitUntilExit` (como o AppleScriptRunner) ou usar `FileHandle.nullDevice` para stdout/stderr nos processos cuja saída é ignorada — incluindo os de `run()`.

### 49. [BAIXO] switchTo confia em track.isPlaying de fonte com estado declaradamente não confiável

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:519`

O silenciamento da sessão anterior (`if track.isPlaying { MediaRemoteAdapter.send(.pause) }`) usa o campo `playing` cru, sem consultar `.reliablePlaybackState`. Para o Chrome esse campo mente nos dois sentidos (compatibilidade-players.md, nota ⁶: houve `playing=True` com o vídeo pausado, e o inverso é o risco aqui): com o Chrome tocando e reportando `playing=false`, a troca não pausa a sessão e os dois apps tocam juntos — exatamente o que o comentário da linha 517 diz existir para evitar. O restante do código trata esse campo com a capability (isEffectivelyPlaying, branch 3 do handleLine); este ponto ficou de fora.

**Evidência:** NowPlayingController.swift:519 `if track.isPlaying { MediaRemoteAdapter.send(.pause) }` sem guard de confiabilidade; docs/compatibilidade-players.md:51-55 (nota ⁶) documenta o `playing` mentiroso do navegador.

**Recomendação:** Quando o estado da sessão ativa não é confiável (`!isPlaybackStateReliable`), enviar `.pause` incondicionalmente na troca — pause sobre mídia já pausada é inócuo, e o custo de não pausar é áudio duplo.

### 50. [BAIXO] TrackInfo.elapsedTime/timestamp são escritos com semântica errada e nunca lidos

**Onde:** `Sources/MacMediaWidget/NowPlayingParser.swift:59`

O parser grava `t.timestamp = Date()` — o instante de RECEPÇÃO da linha —, contradizendo a declaração do campo ("momento em que elapsedTime foi medido", TrackInfo em NowPlayingController.swift:11-12). Nenhum código de produção lê `track.elapsedTime` nem `track.timestamp` (grep confirma: só a escrita no parser). Além de estado morto, o `Date()` novo a cada linha com elapsedTime torna `TrackInfo` desigual ao anterior mesmo sem mudança real, disparando publicação/redraw à toa. É também a armadilha pronta para a pendência registrada (a conta `elapsedTime + (agora − timestamp)` do Safari): quem for implementá-la e usar esse campo herdará o instante errado.

**Evidência:** NowPlayingParser.swift:57-61 `t.elapsedTime = v; t.timestamp = Date()`; NowPlayingController.swift:11-12 documenta `timestamp` como "momento em que elapsedTime foi medido"; grep em Sources sem SelfTests: únicas ocorrências são as duas escritas do parser.

**Recomendação:** Ou remover os dois campos de TrackInfo (o fluxo real usa newElapsed/newTimestamp do Outcome), ou gravar ali o timestamp do payload — nunca `Date()` — antes de implementar a reconstrução de posição pendente.

### 51. [BAIXO] Tabela-resumo "Como esta tabela virou código" está defasada em relação ao código (Safari)

**Onde:** `docs/compatibilidade-players.md:258`

A seção "Como esta tabela virou código" declara Safari "sem reliablePlaybackState", mas `SafariPlayer.capabilities` declara `.reliablePlaybackState` — corretamente, aliás, respaldado pela medição da nota ¹⁰ e pela linha "campo playing confiável | Safari: sim¹⁰" da matriz principal. Num projeto cuja regra dura é "nada entra sem evidência" e cujo documento é a fonte de conferência das capabilities, uma tabela-resumo contradizendo o código convida a uma "correção" errada na próxima auditoria de capabilities.

**Evidência:** docs/compatibilidade-players.md:258 "| Safari | `fullTransport`, `seek` — sem `streamPosition`, sem `reliablePlaybackState` |" e :260 "Todos os outros declaram reliablePlaybackState: o navegador é o único..." versus SafariPlayer.swift:43-45 `override var capabilities: PlayerCapabilities { [.fullTransport, .seek, .reliablePlaybackState] }` e a própria matriz na linha 22 ("sim¹⁰").

**Recomendação:** Atualizar a tabela-resumo (e a frase "o navegador é o único") para refletir a medição do Safari de 2026-08-21, que o código já incorporou.

---

## UI/UX e acessibilidade

*14 achados — 1 alto · 7 médio · 6 baixo*

Auditoria UI-UX do MacMediaWidget (14 achados: 1 high, 7 medium, 6 low). O produto tem base de UX excepcionalmente bem pensada — estados de erro explicados no card (canal degradado, player fechado/não instalado, fonte oculta com botão de volta), contraste calculado contra a capa, botões desabilitados com motivo em tooltip, letreiro para títulos longos, e a cobertura pt-BR de Localizable.strings está completa (todas as chaves de L10n.swift têm tradução, com índices posicionais corretos nas interpolações duplas). Os defeitos que bloqueiam o padrão comercial concentram-se em: (1) acessibilidade — VoiceOver não tem rótulo em nenhum controle do card (transporte, mute, seek, volume) e não há tratamento de reduce-motion, único high; (2) o fluxo de permissão de Automação — prompt do macOS com texto hardcoded em português para todos os idiomas e, se negado, degradação silenciosa sem caminho de recuperação; (3) primeira experiência — player padrão é Amazon Music, que empurra alerta de instalação de um app que o usuário pode nunca ter pedido; (4) estado obsoleto — slider de volume nunca relê o volume do sistema/app após o init (teclas de volume do Mac dessincronizam o widget para sempre); (5) energia — letreiros a 30 Hz rodando permanentemente, inclusive com o widget oculto. Completam a lista: play que vira no-op silencioso com auto-launch desligado (violando princípio documentado no próprio código), contraste ~2:1 em capas de luminância média (corte binário em 0.5), menu da bandeja que se auto-fecha em 2 s (fora do padrão macOS), atalho global fixo sem feedback de falha, duplo clique indescobrível, jargão 'tint' em rótulo de preferência, falha silenciosa no toggle de login e tipografia em tamanhos fixos.

### 52. [ALTO] Controles do card sem rótulos de acessibilidade — VoiceOver inutilizável no widget

**Onde:** `Sources/MacMediaWidget/ContentView.swift:394`

Os controles principais do card não têm nenhum rótulo de acessibilidade: os botões de transporte são criados por `button(_:size:action:)` só com `Image(systemName:)` (linhas 394–402), o botão de mute idem (373–381), a barra de seek é um ZStack com gesture sem `accessibilityValue`/`accessibilityAdjustableAction` (269–311) e o `VolumeSlider` (NSSlider) não recebe rótulo. O VoiceOver anuncia no máximo o nome interno do símbolo SF ('backward', 'forward') ou nada. O time sabe fazer certo — `MenuTransportView` tem `.accessibilityLabel(label)` na linha 56 — mas o card, que é o produto em si, ficou de fora. Um grep por `accessibility` em Sources/ retorna só 3 ocorrências (MenuTransportView e TrayController). Também não há tratamento de `accessibilityReduceMotion`: o letreiro `MarqueeText` rola sempre (MenuStatusView.swift:106–123) e as animações da barra não têm alternativa estática.

**Evidência:** ContentView.swift:394-402: `Button(action: action) { Image(systemName: systemName)...` sem accessibilityLabel; ContentView.swift:373-381 (mute idem); ContentView.swift:279-299 (barra de seek sem semântica de slider); grep de `accessibility` só acha MenuTransportView.swift:56 e TrayController.swift:25,30.

**Recomendação:** Adicionar `.accessibilityLabel` reutilizando as strings já existentes (L10n.previousTrack, playPause, nextTrack), expor a barra de progresso como elemento ajustável (`accessibilityValue` com tempo decorrido/duração + `accessibilityAdjustableAction` onde `isSeekable`), rotular o NSSlider (`slider.setAccessibilityLabel(volume.target.label)`) e congelar o MarqueeText quando `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` (ou `@Environment(\.accessibilityReduceMotion)`) estiver ativo, truncando com reticências.

**Veredito adversarial:** confirmado — severidade ajustada: **MÉDIO**. Evidência confirmada linha a linha: button() (ContentView.swift:394-402) e muteButton (373-381) não têm accessibilityLabel; a barra de seek (269-311) é um ZStack com DragGesture sem semântica de slider (invisível/inoperável para VoiceOver — este é o defeito mais grave); o VolumeSlider (NSSlider, 445-470) não recebe rótulo; grep por "accessibility" acha só 3 ocorrências (MenuTransportView.swift:56, TrayController.swift:25,30); não há nenhum tratamento de accessibilityReduceMotion no projeto. Porém o impacto está inflado: desde macOS 12 o SwiftUI fornece rótulos de acessibilidade automáticos para símbolos SF comuns (backward.fill, forward.fill, play.fill, speaker.*), então os botões de transporte tendem a anunciar algo utilizável, não "o nome interno do símbolo"; o NSSlider é nativamente acessível como slider ajustável (falta só o rótulo descritivo); e os .help() presentes (298, 327, 333, 355, 369) viram texto de ajuda para o VO. Além disso a janela é não-ativante em nível desktop (LSUIElement), o que já limita a alcançabilidade pelo VoiceOver por design, e a distribuição é direta com codesign ad-hoc — sem review de loja que bloqueie por isso. O quadro real é "acessibilidade incompleta com lacunas genuínas" (seek inacessível, sem reduce motion, padrão de MenuTransportView não replicado no card), não "VoiceOver inutilizável". Defeito real de impacto limitado: medium.

### 53. [MÉDIO] Permissão de Automação negada: nenhum aviso nem caminho de recuperação para o usuário

**Onde:** `Sources/MacMediaWidget/Players/AppleScriptPlayer.swift:57`

Quando o usuário nega a Automação (erro -1743), o player rebaixa capacidades silenciosamente: `isAuthorizationDenied = true` + NSLog, e nada mais. O efeito visível é o seek sumir, o volume por-app virar volume do sistema e o modo fixo degradar — tudo sem uma linha de UI explicando que a causa é a permissão e que o conserto fica em Ajustes do Sistema → Privacidade → Automação. O tooltip do volume até diz o alvo novo ('System volume'), mas não o porquê da mudança. Como a negação costuma acontecer no primeiro prompt (clique errado no diálogo do macOS), o usuário fica permanentemente com o produto degradado achando que 'o widget não tem seek'. Não existe nenhuma chave em L10n.swift para esse estado.

**Evidência:** AppleScriptPlayer.swift:57-60: `case .failure(.notAuthorized): isAuthorizationDenied = true; NSLog(...); return nil` — único tratamento. L10n.swift não tem nenhuma string mencionando Automação/permissão; ContentView/PreferencesWindow não leem `isAuthorizationDenied`.

**Recomendação:** Expor `isAuthorizationDenied` na UI: nota na seção Player das Preferências (e/ou no subtítulo do card, como já é feito para `transportUnavailableReason`) com botão que abre `x-apple.systempreferences:com.apple.preference.security?Privacy_Automation`. Rechecar a permissão ao reabrir as Preferências em vez de fixar o estado até reiniciar o app.

### 54. [MÉDIO] Contraste do conteúdo pode cair a ~2:1 com capa de luminância média

**Onde:** `Sources/MacMediaWidget/ContentView.swift:524`

`CardContrast.prefersLightContent` decide binariamente por um corte em 0.5 de luminância efetiva (linha 534) e o conteúdo vira branco puro ou quase-preto (linhas 109–111). Perto do corte — capa cuja cor média fica com luminância efetiva ~0.5, caso comum em capas coloridas — texto branco sobre fundo ~0.5 dá razão de contraste ≈1.9:1, muito abaixo dos 4.5:1 de WCAG. O secundário (opacidade 0.72) e o terciário (0.45) ficam ainda piores. Além disso a conta ignora que o Liquid Glass é translúcido: o wallpaper atrás do card participa do fundo real e não entra em `lightAppearanceBase`/`darkAppearanceBase`, que são constantes chutadas (521–522). A mitigação existente (sessão 2026-08-21) resolveu o caso extremo (capa preta), não a faixa intermediária.

**Evidência:** ContentView.swift:531-534: `let efetiva = base * (1 - opacity) + tintLuminance * opacity; return efetiva < 0.5` — decisão binária sem zona de proteção; ContentView.swift:109-111: `contentSecondary = contentPrimary.opacity(0.72)`, `contentTertiary = .opacity(0.45)` sobre fundo variável.

**Recomendação:** Nas luminâncias efetivas intermediárias (~0.35–0.65), adicionar um scrim: aumentar a opacidade do tint escurecendo/clareando a cor média na direção que favorece o contraste, ou desenhar um gradiente sutil atrás dos textos (como o Now Playing do sistema faz sobre artwork). Alternativa mais simples: saturar o tint para longe da zona 0.4–0.6 antes de aplicá-lo.

### 55. [MÉDIO] Prompt de permissão de Automação do macOS sempre em português (NSAppleEventsUsageDescription não localizada)

**Onde:** `Resources/Info.plist:34`

O app declara base inglesa (`CFBundleDevelopmentRegion` = en) e traduz a UI via pt-BR.lproj, mas a `NSAppleEventsUsageDescription` está hardcoded em português no Info.plist e não existe `InfoPlist.strings` em nenhum .lproj (find não encontra o arquivo; build-app.sh só copia os .lproj existentes). Resultado: todo usuário de sistema em inglês (ou qualquer idioma ≠ pt) vê o diálogo de permissão de Automação do macOS — o momento de maior desconfiança do fluxo — com uma justificativa em português que ele não entende, o que aumenta a chance de negação (e aí cai no achado da Automação negada, que também não tem recuperação).

**Evidência:** Info.plist:33-35: `<key>NSAppleEventsUsageDescription</key><string>O MacMediaWidget envia comandos ao app de música escolhido...</string>` com `CFBundleDevelopmentRegion` = en logo acima; `find . -name InfoPlist.strings` vazio.

**Recomendação:** Mover o texto para inglês no Info.plist (idioma-base declarado) e criar `en.lproj/InfoPlist.strings` e `pt-BR.lproj/InfoPlist.strings` com a chave `NSAppleEventsUsageDescription`; incluir no verificar-traducoes.sh.

### 56. [MÉDIO] Slider de volume mostra valor obsoleto: estado nunca é relido após a inicialização

**Onde:** `Sources/MacMediaWidget/SystemVolumeController.swift:22`

O volume do sistema é lido uma única vez, no `init` (`readCurrentState()`), e o comentário na linha 29 admite que a releitura 'pode ser rechamada quando o widget reaparece' — mas ninguém a chama: `VolumeRouter.refresh()` só executa em `retarget`, que só dispara quando o player controlado muda (ContentView.swift:92-94). O usuário ajusta o volume pelas teclas do teclado — gesto cotidiano — e o slider do widget continua mostrando o valor antigo indefinidamente; o ícone de speaker (speakerSymbol, ContentView.swift:383-390) também fica errado. O mesmo vale para volume por-app: mudou no Spotify, o widget não fica sabendo. Um controle sempre visível exibindo estado errado mina a confiança no produto inteiro.

**Evidência:** SystemVolumeController.swift:22-24: `init() { readCurrentState() }` — única chamada espontânea; VolumeRouter.swift:74-85: `refresh()` chamado só de `retarget(to:)` (linha 70); ContentView.swift:92-94: `.task(id: nowPlaying.controlledPlayer.bundleIdentifier)` — só na troca de player.

**Recomendação:** Para o volume do sistema, ouvir mudanças de verdade (CoreAudio: `AudioObjectAddPropertyListenerBlock` em `kAudioHardwareServiceDeviceProperty_VirtualMasterVolume` do device de saída — sem subprocesso e sem polling). Para volume por-app, reler junto do poll de posição de 1 Hz já existente enquanto o widget está visível, ou ao menos em `showWidget()`/`windowDidBecomeKey`.

### 57. [MÉDIO] Player preferido padrão é Amazon Music: primeira experiência ruim para quem não o tem

**Onde:** `Sources/MacMediaWidget/Settings.swift:122`

`Defaults.preferredPlayerBundleId = AmazonMusicPlayer.bundleID`. Num produto comercializado para controlar 'qualquer player', o usuário típico que instala o widget sem o Amazon Music vê no card, de saída, 'Amazon Music is not installed' (via `transportUnavailableReason`, NowPlayingController.swift:214) e, ao apertar play, recebe um alerta oferecendo instalar o Amazon Music (Player.swift:176-196) — um app que ele nunca pediu. É herança do escopo original do projeto (widget pessoal para Amazon Music), incompatível com o posicionamento comercial multiplayer. Não há onboarding que pergunte o player do usuário.

**Evidência:** Settings.swift:122: `static let preferredPlayerBundleId = AmazonMusicPlayer.bundleID`; NowPlayingController.swift:99: fallback `?? AmazonMusicPlayer()`; Player.swift:176-196: `promptInstall()` abre alerta com página de instalação do preferido ausente.

**Recomendação:** Default para Apple Music (`com.apple.Music`, presente em todo macOS) ou, melhor, detectar na primeira execução qual player conhecido está instalado/rodando e adotá-lo; um passo único de onboarding ('qual app você usa?') resolveria isso e apresentaria o produto.

### 58. [MÉDIO] Botão play vira no-op silencioso com 'abrir ao dar play' desligado

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:555`

Em `playPause()`, quando não há sessão utilizável e `autoLaunchOnPlay` está desligado, o método retorna sem fazer nada (`guard AppSettings.shared.autoLaunchOnPlay else { return }`). O botão central do card, porém, nunca é desabilitado (ContentView.swift:328-330 — prev/next têm `.disabled`, o play não) e não dá feedback nenhum. O próprio projeto formulou o princípio violado: 'Botão que não faz nada é pior que botão desligado — o usuário culpa o widget' (NowPlayingController.swift:186). O usuário que desligou a abertura automática clica no play com o player fechado e nada acontece, sem explicação.

**Evidência:** NowPlayingController.swift:553-558: `guard AppSettings.shared.autoLaunchOnPlay else { return }` sem qualquer sinal à UI; ContentView.swift:324-334: só previous/next recebem `.disabled(...)`/`.help(...)`, o botão play não tem estado desabilitado nem tooltip.

**Recomendação:** Quando `autoLaunchOnPlay == false` e o caminho cairia no launch, desabilitar o play com `.help(transportUnavailableReason)` (a string '\(name) is closed' já existe), ou tratar o clique como pedido explícito do usuário e abrir o app mesmo assim — o toggle protege contra abertura automática, não contra um clique deliberado.

### 59. [MÉDIO] Letreiros rodam a 30 Hz permanentemente, inclusive com o widget oculto

**Onde:** `Sources/MacMediaWidget/MenuStatusView.swift:80`

`MarqueeText` é dirigido por `Timer.publish(every: 1/30, in: .common).autoconnect()` que nunca para: o card tem dois letreiros (título e artista, ContentView.swift:160 e 214) e, como 'nome de faixa longo é a regra, não a exceção' (comentário em ContentView.swift:157-159), o card fica animando offset a 30 fps continuamente. Ocultar o widget (`orderOut`, WidgetWindow.swift:212) não destrói a view nem os timers — o flag `isWidgetVisible` só desliga o poll de posição (NowPlayingController.swift:86, 328), não os letreiros nem o `progressTimer` de 0.5s. Num utilitário residente que promete ficar aberto o dia inteiro, isso é consumo de energia constante que aparece no Monitor de Atividade e em review de produto.

**Evidência:** MenuStatusView.swift:74-82: `tickInterval = 1/30` + `Timer.publish(...in: .common).autoconnect()` como propriedade da view, sem pausa; MenuStatusView.swift:111-112: `tick()` só faz guard, o timer segue disparando; WidgetWindow.swift:210-219: `orderOut` sem notificar a UI SwiftUI; NowPlayingController.swift:327-331: `isWidgetVisible` gates apenas `pollRealPositionIfNeeded`.

**Recomendação:** Pausar o clock quando não há overflow (conectar/cancelar o publisher em função de `overflows`) e quando a janela está oculta (`occlusionState`/callback de `toggleVisibility` → environment). Considerar animar via `TimelineView(.animation(paused:))` ou CADisplayLink com pausa, e reduzir a 0 custo com widget invisível.

### 60. [BAIXO] Menu da bandeja se auto-fecha após 2 s sem hover — comportamento fora do padrão do macOS

**Onde:** `Sources/MacMediaWidget/AppMenuController.swift:20`

`autoCloseDelay = 2.0`: o menu da bandeja fecha sozinho após 2 segundos sem item destacado e sem o mouse sobre a janela do menu. Nenhum menu do macOS faz isso. O caso ruim é real: o usuário clica no ícone da bandeja e lê o menu com o cursor parado sobre o próprio ícone (fora do frame do painel do menu) — `mouseIsOver` dá false, `highlightedItem` é nil, e o menu some no meio da leitura. Para quem navega por teclado a partir do Controle de Teclado, qualquer pausa de 2 s sem highlight também fecha. Como recurso deliberado, merece ao menos ser bem mais tolerante ou opcional.

**Evidência:** AppMenuController.swift:20-21: `autoCloseDelay: TimeInterval = 2.0`; AppMenuController.swift:159-173: fecha via `menu.cancelTracking()` quando `highlightedItem == nil && !mouseIsOver(menu)` por 2 s acumulados.

**Recomendação:** Subir o tempo para 5–8 s ou remover o auto-fechamento (o clique fora já fecha menus no macOS); se mantiver, zerar a contagem também quando o mouse está sobre o botão do status item, não só sobre o painel do menu.

### 61. [BAIXO] Atalho global fixo em ⌃⌥⌘M, sem configuração e sem feedback quando o registro falha

**Onde:** `Sources/MacMediaWidget/GlobalHotKey.swift:59`

O atalho é hardcoded (kVK_ANSI_M + ⌃⌥⌘) e as Preferências o exibem como texto estático (PreferencesWindow.swift:182-184), sem opção de troca nem de desativação. Se `RegisterEventHotKey` falhar — colisão com atalho de outro app é o caso clássico — o app só faz NSLog e as Preferências continuam anunciando '⌃⌥⌘M' como se funcionasse. Num produto comercial, atalho global inalterável é fonte recorrente de suporte (conflita com apps de janela/screenshot que usam combos de 3 modificadores). Nota adicional: kVK_ANSI_M é posicional — em layouts não-QWERTY a tecla física pode não ser a legenda 'M'.

**Evidência:** GlobalHotKey.swift:21-23: `keyCode: Int = kVK_ANSI_M, modifiers: Int = controlKey | optionKey | cmdKey` — defaults nunca sobrescritos (App.swift:77 chama só com action); GlobalHotKey.swift:59-61: falha de registro vira apenas `NSLog`; PreferencesWindow.swift:182-184: `Text("⌃⌥⌘M").monospaced()` estático.

**Recomendação:** Tornar o atalho configurável (um recorder simples sobre a mesma API Carbon) ou ao menos desativável; propagar a falha de registro para a UI das Preferências ('atalho indisponível — em uso por outro app').

### 62. [BAIXO] Duplo clique para abrir o player é invisível: nenhuma pista na UI

**Onde:** `Sources/MacMediaWidget/WidgetWindow.swift:173`

O duplo clique em área morta do card abre o player exibido (`mouseUp` com `clickCount == 2`), mas não há tooltip, item de menu equivalente rotulado como tal, nem menção em lugar algum da UI — o usuário só descobre por acidente. O gesto convive ainda com o clique simples de arrasto da janela na mesma área, então errar o timing move o widget em vez de abrir o app. Funcionalidade útil com descoberta zero.

**Evidência:** WidgetWindow.swift:173-179: `override func mouseUp` com `event.clickCount == 2 { nowPlaying.openSourcePlayer() }` — nenhum `.help` no card cobre a área morta (ContentView só põe tooltips em controles) e nenhuma string de L10n descreve o gesto.

**Recomendação:** Adicionar `.help(L10n.openPlayer(name))` na área do artwork (alvo natural do duplo clique) e/ou citar o gesto no texto de ajuda das Preferências.

### 63. [BAIXO] Rótulo 'Tint opacity'/'Opacidade do tint' usa jargão de implementação

**Onde:** `Sources/MacMediaWidget/L10n.swift:127`

A preferência que controla o quanto a cor da capa tinge o card se chama 'Tint opacity', e a tradução pt-BR mantém o anglicismo técnico: 'Opacidade do tint' (Localizable.strings:61). Usuário leigo não sabe o que é 'tint' — o conceito para ele é 'intensidade da cor da capa no fundo do widget'. É o único rótulo do formulário que vaza vocabulário de implementação; o restante das strings tem qualidade alta.

**Evidência:** L10n.swift:127: `static var tintOpacity: String { String(localized: "Tint opacity") }`; Resources/pt-BR.lproj/Localizable.strings:61: `"Tint opacity" = "Opacidade do tint";`.

**Recomendação:** Renomear para algo descritivo — en: 'Cover color intensity' / pt-BR: 'Intensidade da cor da capa' — mantendo a chave se necessário e trocando só os valores exibidos.

### 64. [BAIXO] Falha ao alternar 'Abrir no login' é silenciosa e o toggle pode mostrar estado errado

**Onde:** `Sources/MacMediaWidget/LoginItem.swift:20`

`LoginItem.toggle()` engole o erro de `SMAppService.register/unregister` com NSLog. O caso concreto existe no próprio código: rodando fora do bundle .app o SMAppService não funciona (comentário nas linhas 4-5), e o status pode ser `.requiresApproval` (usuário precisa aprovar em Ajustes do Sistema → Geral → Itens de Início) — estado que `isEnabled` reporta como false sem explicar. O usuário liga o toggle nas Preferências (PreferencesWindow.swift:178-181) ou no menu (AppMenuController.swift:228-230), a operação falha ou fica pendente de aprovação, e a UI simplesmente volta ao estado anterior sem uma palavra.

**Evidência:** LoginItem.swift:13-24: `catch { NSLog(...) }` sem retorno de erro à UI; `isEnabled` só compara com `.enabled`, ignorando `.requiresApproval`; PreferencesWindow.swift:178-181: `Binding(get: { LoginItem.isEnabled }, set: { _ in LoginItem.toggle() })` descarta o valor e não reage a falha.

**Recomendação:** Tratar `.requiresApproval` mostrando nota com link para `SMAppService.openSystemSettingsLoginItems()`; em erro real, reverter o toggle com uma explicação curta em vez de falhar mudo.

### 65. [BAIXO] Tipografia inteira em tamanhos fixos — ignora o ajuste de tamanho de texto do sistema

**Onde:** `Sources/MacMediaWidget/ContentView.swift:161`

Todos os textos do card e dos menus usam `.system(size:)` com valores absolutos (12/16 no título, 11/13 no subtítulo, 13 no menu etc.), sem estilos semânticos nem resposta ao ajuste de tamanho de texto de acessibilidade do macOS. No formato compacto o subtítulo fica em 11 pt e o hint da fonte em tooltip — para usuário com baixa visão, o card é ilegível e não há como aumentar. Como o layout do widget é de dimensões fixas (grade de 180 pt), escalar é limitado, mas hoje não há nem o mínimo (respeitar a preferência de contraste aumentado / usar `.font(.body)` relativo onde couber).

**Evidência:** ContentView.swift:161: `.font(.system(size: isCompact ? 12 : 16, weight: .bold))`; ContentView.swift:214-216: subtítulo `size` 11/13; MenuStatusView.swift:24,29: tamanhos fixos 11/13 — nenhuma ocorrência de fontes dinâmicas ou `controlSize` no projeto.

**Recomendação:** Registrar como limitação consciente e, no mínimo, respeitar `NSWorkspace.accessibilityDisplayShouldIncreaseContrast` elevando as opacidades de secundário/terciário; avaliar um degrau de fonte maior no formato 2×1, onde há folga.

---

## Qualidade de engenharia

*11 achados — 1 alto · 6 médio · 4 baixo*

Auditoria de qualidade de engenharia do MacMediaWidget. O projeto está acima da média em disciplina: 142 asserções com racional documentado, capacidades de player só declaradas com evidência medida, scripts de verificação com falsos negativos corrigidos e documentados, tratamento de erro consciente na camada AppleScript. Os problemas reais se concentram em quatro frentes: (1) o caminho mais crítico e historicamente mais bugado — a reancoragem de posição no NowPlayingController — tem zero cobertura de teste, com um refactor já agendado exatamente ali (achado high); (2) robustez do parsing: snapshot não-vazio é mesclado como diff, deixando metadados da faixa anterior vazarem para a atual, e qualquer linha (mesmo lixo ignorado) marca o canal como saudável — um adapter incompatível vira widget vazio 'são' e sem log; (3) diagnóstico: comandos one-shot ao adapter e osascript de volume falham sem deixar rastro nenhum, o que inviabiliza suporte a bug reportado por usuário num produto comercial; (4) cadeia de build: o mediaremote-adapter é copiado do brew sem pin, checksum ou registro de versão — build irreprodutível da peça central do produto, com o CLAUDE.md descrevendo uma árvore vendorada que não existe. Completam a lista o warning conhecido do doubleValue (fix trivial: @MainActor no Coordinator), o verificador de traduções que não confere format specifiers dos valores, o loop waitForSessionThenPlay sem cancelamento (play tardio em app abandonado) e os SelfTests usando o UserDefaults real do desenvolvedor como fixture. Nenhum achado bloqueia comercialização por si, mas os de diagnóstico e pinagem precisam ser resolvidos antes de haver usuários pagantes reportando problemas.

### 66. [ALTO] Caminho mais crítico e com maior histórico de bugs — a ancoragem de posição — não tem nenhum teste

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:403`

O bloco de reancoragem do cronômetro em handleLine (linhas 403–449) e estimatedElapsed (352–357) concentram a lógica mais sutil do produto: prioridade elapsedTime vs timestamp, o caso do Amazon Music pausado há horas (âncora presa na duração), a transição play/pause sem timestamp e o clamp que não pode ser gravado de volta. É a área com mais bugs documentados do projeto (DECISOES 2026-08-05 #01, comentários nas linhas 420–443) e está 100% fora do SelfTests — a suíte testa o NowPlayingParser (entrada/saída pura) mas nunca o que o controller faz com o resultado. Agravante: PENDENCIAS.md linha 59 planeja refatorar exatamente essa conta (ancorar em elapsedTime + (agora − timestamp)), ou seja, um refactor no coração do produto vai acontecer sem rede de segurança. Também sem cobertura: ingest/split de linhas com o teto de 8 MB (366–383), reconexão com backoff (285–299) e waitForSessionThenPlay (567–577). O simulateSession já provou que dá para injetar estado em DEBUG; falta o mesmo seam para relógio e âncora.

**Evidência:** NowPlayingController.swift:403-449 (toda a cadeia if let elapsed / else if let ts / else if isPlaying mudou) é private e nenhum dos 142 expects de SelfTests.swift exercita anchorElapsed/anchorWall; PENDENCIAS.md:59-67 agenda mudança nessa mesma lógica ('Mexe no coração do NowPlayingController').

**Recomendação:** Antes do refactor pendente, extrair a decisão de reancoragem para uma função pura (entrada: outcome do parser, âncora atual, capacidades, agora; saída: nova âncora) e cobrir no SelfTests os quatro ramos com os casos históricos: elapsedTime com .streamPosition, timestamp de faixa nova, timestamp velho com sinceStart > duration (Amazon pausado), e transição play/pause sem timestamp. Injetar Date via parâmetro para o teste controlar o relógio.

**Veredito adversarial:** confirmado — severidade ajustada: **MÉDIO**. Todos os fatos conferem no código: o bloco de reancoragem (NowPlayingController.swift:403–449) e estimatedElapsed (352–357) concentram a lógica mais sutil e com mais bugs documentados (comentários 420–443, DECISOES 2026-08-05 #01), são private, e nenhum dos 142 expects de SelfTests.swift os exercita — as 7 chamadas a simulateSession (620–764) cobrem só roteamento de comando, e o parser é testado apenas como função pura. PENDENCIAS.md (~l.58–67) de fato agenda um refactor exatamente nessa conta ("Mexe no coração do NowPlayingController"). O achado é real. Rebaixo de high para medium porque não é defeito ativo com impacto presente, e sim lacuna de cobertura: o comportamento atual foi validado ao vivo, existe roteiro de teste manual institucionalizado (docs/roteiro-teste-manual.md) e a própria pendência do refactor já prevê nova rodada do roteiro. O risco é prospectivo (regressão no refactor planejado, difícil de detectar manualmente por ser lógica dependente de relógio), o que é dívida relevante para produto comercial, mas de impacto contingente — não "defeito real com impacto claro" que a régua exige para high.

### 67. [MÉDIO] Snapshot não-vazio é mesclado como diff: metadados da faixa/app anterior sobrevivem no card

**Onde:** `Sources/MacMediaWidget/NowPlayingParser.swift:44`

O parser só distingue snapshot de diff no caso vazio: `if isSnapshot, payload["bundleIdentifier"] == nil, payload["title"] == nil { return .reset }`. Um snapshot (diff:false) COM conteúdo cai no mesmo caminho de merge dos diffs (linha 49, `var t = current`), preservando todo campo ausente. Um snapshot é por definição o estado completo — campo ausente nele significa 'não existe', não 'não mudou'. Consequência concreta: snapshot de uma faixa sem album/artworkData (comum em streams de navegador e rádios) mantém no card a capa e o álbum da faixa/app anterior; um snapshot com bundleIdentifier mas sem title mantém o título antigo. É a mesma família do bug de produção que motivou o .reset (DECISOES 2026-08-05 #01), resolvida apenas para o caso 100% vazio.

**Evidência:** NowPlayingParser.swift:43-49 — `let isSnapshot = (obj["diff"] as? Bool) == false` só é usado no reset; logo abaixo, o comentário 'Fora do snapshot, o stream manda só os campos que mudaram' precede um merge que roda também PARA snapshots com conteúdo.

**Recomendação:** Quando isSnapshot for true e houver conteúdo, partir de TrackInfo() em vez de current (mantendo a política atual de timestamp). Adicionar asserção no SelfTests: snapshot com título novo e sem artist/artwork não pode herdar artist/artwork do estado anterior.

### 68. [MÉDIO] Qualquer linha do stream marca o canal como saudável — inclusive as que o parser descarta

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:387`

handleLine promove health para .healthy ANTES de parsear, para qualquer linha não-vazia. Se um update do media-control ou do macOS mudar o formato do JSON (o risco estrutural que o próprio código documenta em AdapterHealth), todas as linhas viram .ignored, o parser as descarta em silêncio (return sem log), e o widget fica eternamente vazio reportando-se são. É exatamente o cenário que o estado AdapterHealth existe para denunciar — e ele não dispara, porque a chegada de bytes é confundida com a chegada de dados válidos. Para diagnóstico de bug reportado por usuário, não há nenhum rastro: linha ignorada não gera nenhuma linha de log.

**Evidência:** NowPlayingController.swift:385-394 — `if health != .healthy { health = .healthy ... }` executa antes do switch; `case .ignored: return` não loga nada. NowPlayingParser.swift:41 devolve .ignored para qualquer JSON sem payload, também sem log.

**Recomendação:** Só promover a .healthy quando o parse devolver .update ou .reset. Contar linhas .ignored consecutivas e, acima de um limiar, logar uma amostra da linha (truncada) e degradar health — é o único sinal possível de incompatibilidade de formato do adapter.

### 69. [MÉDIO] Comandos one-shot ao adapter são fire-and-forget: falha de send/seek é invisível e indiagnosticável

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:92`

MediaRemoteAdapter.run() dispara o perl e retorna: não espera o processo, não checa terminationStatus e joga stdout/stderr em Pipes que ninguém lê. O único erro logado é a falha de spawn (process.run() lançar). Se o script perl subir e falhar — framework corrompido no bundle, entitlement recusado, argumento inválido — o comando some sem rastro. O sintoma para o usuário é 'apertei next e nada aconteceu'; para o suporte de um produto comercial não existe nenhuma linha de log para correlacionar. Nota: os Pipes criados e nunca drenados também significam que um adapter verboso pode bloquear no pipe cheio e ficar pendurado.

**Evidência:** MediaRemoteAdapter.swift:92-99 — `try process.run()` sem waitUntilExit/terminationHandler nem leitura de standardError; makeProcess (146-153) instala Pipe() em stdout e stderr que nenhum chamador de run() consome.

**Recomendação:** Instalar terminationHandler nos one-shot: se terminationStatus != 0, logar comando + status + stderr (truncado). Custa nada no caminho feliz e é a diferença entre um bug reproduzível e um 'não funciona' sem pista.

### 70. [MÉDIO] A dependência central (mediaremote-adapter/media-control) não é pinada nem vendorada — build irreprodutível

**Onde:** `scripts/build-app.sh:26`

build-app.sh copia para dentro do bundle o que quer que `brew --prefix media-control` aponte no momento do build (hoje 0.7.6), sem pin de versão, sem checksum e sem registrar a versão embarcada. O componente é literalmente o coração do produto (toda leitura e transporte passam por ele), fala com um framework privado da Apple, e um `brew upgrade` silencioso entre dois builds muda o comportamento do binário distribuído sem nenhum sinal no repositório. Não há como responder 'qual versão do adapter está no .app que o cliente X tem?'. Agravante de documentação: o CLAUDE.md do projeto descreve `Resources/mediaremote-adapter/` como versionado no repo ('framework + perl bundlados'), mas o diretório não existe — a estrutura documentada diverge da real.

**Evidência:** build-app.sh:26-32 usa `brew --prefix media-control` sem verificação de versão; `ls Resources/` confirma que mediaremote-adapter/ não existe no repositório; `brew list --versions media-control` → 0.7.6, valor que não aparece em lugar nenhum do repo.

**Recomendação:** Pinar: declarar a versão esperada no script (MMW_ADAPTER_VERSION), abortar o build se `brew list --versions` divergir, e gravar a versão embarcada no Info.plist ou num arquivo em Resources/ para diagnóstico em campo. Alternativa mais forte para comercialização: vendorar o adapter (BSD-3 permite) com checksum verificado. Corrigir a árvore descrita no CLAUDE.md.

### 71. [MÉDIO] Verificador de traduções compara chaves, mas não os format specifiers dos valores traduzidos

**Onde:** `scripts/verificar-traducoes.sh:55`

O script normaliza a interpolação para %@ na CHAVE e confere presença/ausência de chaves entre L10n.swift e cada .lproj. Ele não valida que o VALOR traduzido contém o mesmo número de %@ que a chave. Uma tradução com %@ a menos silencia o argumento (mensagem sem o nome do app — exatamente as strings de erro que orientam o usuário, como playerNotInstalled); com %@ a mais, String(format:) lê um vararg inexistente — lixo ou crash em runtime, só no idioma traduzido. É o tipo de erro que este script existe para pegar e que nenhum teste pega, porque só se manifesta com o .app montado em pt-BR. Limitação secundária: a extração só lê L10n.swift — um String(localized:) fora dele fica invisível ao verificador (hoje não há nenhum, mas nada impede).

**Evidência:** verificar-traducoes.sh:26 (`chaves_codigo = {re.sub(r'\\\([^)]*\)', '%@', lit) ...}`) e 55-58 — a comparação é `chaves_codigo - chaves_arquivo` / inverso, apenas sobre conjuntos de chaves; os valores de `json.loads(saida.stdout)` são descartados.

**Recomendação:** Para cada chave com %@, comparar value.count('%@') com key.count('%@') e falhar na divergência. Adicionar um grep que falhe se `String(localized:` aparecer fora de L10n.swift, transformando a convenção em regra verificada.

### 72. [MÉDIO] waitForSessionThenPlay não é cancelável: trocas rápidas de app deixam loops concorrentes que podem dar play tardio

**Onde:** `Sources/MacMediaWidget/NowPlayingController.swift:567`

Cada switchTo/playPause que abre um app agenda um loop de até 30 tentativas (15 s) via asyncAfter, sem token de cancelamento e sem verificar se o alvo ainda é o player controlado. Trocar de A para B e em seguida para C deixa o loop de B vivo: se a sessão de B aparecer dentro da janela (o usuário reabriu B, ou B demorou a subir), o loop obsoleto dispara player.play() num app que o usuário já abandonou — áudio inesperado, com dois apps disputando a sessão que o próprio switchTo acabou de silenciar. O caminho é assíncrono, depende de timing real e está fora do SelfTests, ou seja, só se manifesta em uso.

**Evidência:** NowPlayingController.swift:567-577 — a recursão `DispatchQueue.main.asyncAfter ... waitForSessionThenPlay(player, attempt: attempt + 1)` captura o player e não consulta controlledPlayer/preferredPlayerBundleId nem nenhum flag de geração antes de `player.play()`.

**Recomendação:** Guardar um contador de geração (incrementado a cada switchTo/playPause que inicia espera) e abortar o loop quando a geração capturada divergir da atual — uma linha no início do método. Cobrir com teste usando o PlayerDeTeste existente.

### 73. [BAIXO] Warning conhecido tolerado: Coordinator.changed lê doubleValue (MainActor) de contexto nonisolated

**Onde:** `Sources/MacMediaWidget/ContentView.swift:471`

Build limpo emite: 'main actor-isolated property doubleValue can not be referenced from a nonisolated context'. Na prática o AppKit chama o target/action na main thread, então não há race hoje — mas o warning é a única mancha num projeto que compila limpo, e warning tolerado é como o segundo aparece sem ninguém notar (o grep de 'warning' num CI deixa de ser um gate binário). Em modo estrito de Swift 6 essa referência tende a virar erro, quebrando o build num update de toolchain.

**Evidência:** Compilação após `touch ContentView.swift`: 'ContentView.swift:471:66: warning: main actor-isolated property doubleValue can not be referenced from a nonisolated context', apontando `@objc func changed(_ sender: NSSlider) { onChange(sender.doubleValue) }`.

**Recomendação:** Anotar a classe Coordinator (ou só o método changed) com @MainActor — o action de NSControl chega na main thread, então MainActor.assumeIsolated não é nem necessário se a classe inteira for isolada. Depois disso, fazer verificar.sh falhar em qualquer warning (por exemplo `swift build -Xswiftc -warnings-as-errors` na etapa de build).

### 74. [BAIXO] isEntitled() cria pipes que não drena antes de waitUntilExit — o próprio anti-padrão documentado no projeto

**Onde:** `Sources/MacMediaWidget/Players/MediaRemoteAdapter.swift:137`

isEntitled() instala Pipes em stdout/stderr (via makeProcess) e chama waitUntilExit sem ler nenhum dos dois. O AppleScriptRunner do mesmo projeto documenta a regra na direção certa: 'Ler antes de esperar: um pipe cheio bloqueia o processo filho, e aí o waitUntilExit nunca retorna'. Se uma versão futura do adapter verbalizar mais de ~64 KB no comando test (diagnóstico, deprecation notice do perl), a Task detached de start() trava para sempre, openStream nunca roda e o widget fica em .starting eternamente, sem aviso — o caso exato que AdapterHealth existe para evitar. Baixa probabilidade hoje, mas é uma bomba armada contra uma dependência que o projeto assume que vai mudar.

**Evidência:** MediaRemoteAdapter.swift:135-144 — `try process.run(); process.waitUntilExit()` sobre um Process cujo makeProcess (150-151) definiu `standardOutput = Pipe()` e `standardError = Pipe()`; contraste com AppleScriptRunner.swift:36-40, que lê os dois antes do wait.

**Recomendação:** Drenar (readDataToEndOfFile) ou trocar os Pipes por FileHandle.nullDevice em isEntitled(); aproveitar e logar stderr quando terminationStatus != 0, que hoje também se perde.

### 75. [BAIXO] runOsascript de volume não checa exit status: osascript falhando deixa o slider em 50% sem nenhum log

**Onde:** `Sources/MacMediaWidget/SystemVolumeController.swift:96`

runOsascript devolve o stdout sem olhar terminationStatus (o stderr vai para um Pipe descartado). Se osascript falhar com exit != 0 — TCC bloqueando, ambiente corporativo com AppleScript restrito —, readCurrentState recebe string vazia, o parse `parts.count == 2` falha em silêncio e o slider fica no valor default 0.5 controlando nada. O único NSLog cobre falha de spawn, não falha de execução. Usuário reporta 'volume do widget não funciona' e não há linha de log para diagnosticar.

**Evidência:** SystemVolumeController.swift:87-103 — `process.standardError = Pipe()` nunca lido; `return String(data: data, encoding: .utf8)` sem consultar terminationStatus; em readCurrentState (34-36), `guard parts.count == 2 ... else { return }` descarta a falha sem log.

**Recomendação:** Checar terminationStatus em runOsascript e logar stderr na falha; em readCurrentState, logar uma vez quando a leitura inicial falhar, para o estado 'slider decorativo' deixar rastro.

### 76. [BAIXO] SelfTests mutam o AppSettings.shared real (UserDefaults do desenvolvedor) como fixture

**Onde:** `Sources/MacMediaWidget/SelfTests.swift:517`

Vários testes usam o singleton AppSettings.shared como fixture: setHidden no preferido real (517-523), ocultar o Apple Music (535-543), trocar controlMode e preferredPlayerBundleId (660-668, 719-731), sempre restaurando via defer ou reatribuição. Funciona porque expect não lança — mas qualquer crash ou trap no meio de um teste deixa as preferências reais do desenvolvedor alteradas (app oculto, modo fixo ligado, preferido trocado), e os testes dependem da ordem/estado do domínio real de UserDefaults, o que os torna não-hermeticos. Num produto que vai escalar a suíte, isso é o tipo de acoplamento que produz teste flaky impossível de reproduzir.

**Evidência:** SelfTests.swift:517-523 (setHidden(true, for: preferido) no settings real), 535-543 (setHidden no Apple Music com restauração manual `antes`), 660-668 e 719-731 (controlMode/preferredPlayerBundleId trocados e restaurados por defer) — todos sobre AppSettings.shared, respaldado por UserDefaults de verdade (Settings.swift:49-56).

**Recomendação:** Dar ao AppSettings um init interno recebendo UserDefaults(suiteName:) e, no --run-tests, apontar o shared para uma suite descartável (removePersistentDomain no início). Elimina o risco de vazamento de estado e destrava paralelizar/embaralhar testes no futuro.
