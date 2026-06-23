# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

> **Virada de arquitetura (2026-06-23 · #01):** o projeto deixa de ser um app Electron que
> controla o PWA e passa a ser um **app Swift nativo** que controla o **app oficial
> `Amazon Music.app`** via Now Playing do macOS. As pendências da era Electron estão na
> seção "Obsoletas" e foram substituídas pelas de implementação Swift abaixo.

## Alta

- [x] **Limpar a base Electron** na própria pasta: remover `main.js`, `preload.js`,
  `renderer.js`, `index.html`, `style.css`, `package.json`, `package-lock.json` e
  `node_modules/`; ajustar `.gitignore` (tirar refs de pnpm/Electron, adicionar `.build/`).
  Git preserva o histórico — sem perda. (#01 2026-06-23 · feito #02)
- [x] **Atualizar `CLAUDE.md`**: seção "Stack" (Electron → Swift/AppKit + SwiftUI) e
  "Estrutura de arquivos esperada". (#01 2026-06-23 · feito #02)
- [x] **Setup do projeto Swift**: alvo executável via SPM + bundle `.app` montado à mão
  (`Info.plist` com `LSUIElement`) + codesign ad-hoc. (#01 2026-06-23 · feito #02)
- [x] **Integrar mediaremote-adapter** (fork Swift do `ejbills`): bundlar
  `MediaRemoteAdapter.framework` + perl; rodar `stream`, parsear JSON, atualizar UI; enviar
  comandos de transporte pelo mesmo canal. (#01 2026-06-23 · feito #02)

## Média

- [x] **Janela widget de mesa**: `NSWindow` em nível de desktop, presente em todos os Spaces,
  não-ativante, snap à grade com posição persistida. (#01 2026-06-23 · feito #02 — snap por
  ancoragem à borda, não grade do sistema; ver decisão na sessão)
- [~] **UI Liquid Glass nativo** (macOS 26): capa, título, artista, barra de progresso e
  botões play/pause/anterior/próxima/seek. (#01 2026-06-23 — base entregue no #02: card
  tonalizado pela capa + progresso animado; falta o `glassEffect` nativo do macOS 26)
- [x] **Tray na barra de menu** (`NSStatusItem`): mostrar/ocultar widget, preferências, sair. (#01 2026-06-23 · feito #02)
- [x] **Autostart no login** via `SMAppService`. (#01 2026-06-23 · feito #02 — toggle no menu da bandeja)
- [ ] **Tela de configurações dedicada**: janela de preferências (margem/grade, etc.). Hoje as
  ações vivem no menu da bandeja. (#02 2026-06-23)
- [x] **Botão "abrir Amazon Music"** (`NSWorkspace`, bundle `com.amazon.music`). (#01 2026-06-23 · feito #02)

## Baixa

- [~] **Persistência** (posição da janela, preferências) em `UserDefaults`. (#01 2026-06-23 —
  posição da janela feita no #02; preferências futuras quando houver tela de configurações)
- [ ] **Empacotamento/distribuição** do `.app` (`.dmg` opcional; sem Apple Developer ID →
  contorno de Gatekeeper para uso pessoal). (#01 2026-06-23)
- [ ] **Controle de volume — opção 1 (volume do sistema)**: ajustar o volume do macOS via
  AppleScript (`set volume`). Decidido no #02: é global, não por-app; volume por-app real exige
  driver de áudio virtual (fora de escopo) e o MediaRemote não tem comando de volume. (#02 2026-06-23)
- [ ] **Calibrar `edgeMargin`** do snap horizontal para casar exatamente com a coluna dos widgets
  nativos (hoje 16pt, ajuste empírico na tela). (#02 2026-06-23)

## Obsoletas — arquitetura Electron descartada (2026-06-23 · #01)

Marcadas `[x]` por encerramento (descartadas, não concluídas).

- [x] ~~Etapa 1 — Integração com o PWA via AppleScript~~ → descartada: o Amazon Music web
  bloqueia navegador desconhecido; abordagem trocada por controle do app oficial. (#02)
- [x] ~~Etapa 2 — Comportamento de widget de mesa (em Electron)~~ → substituída pela versão Swift. (#02)
- [x] ~~Etapa 3 — Liquid Glass via `vibrancy` do BrowserWindow~~ → substituída por Liquid Glass nativo (Swift). (#02)
- [x] ~~Etapa 4 — Persistência (Electron)~~ → substituída pela versão Swift. (#02)
- [x] ~~Etapa 6 — Empacotamento `.dmg` do app Electron~~ → substituída por empacotamento `.app` Swift. (#02)
