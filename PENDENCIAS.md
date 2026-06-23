# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

> **Virada de arquitetura (2026-06-23 · #01):** o projeto deixa de ser um app Electron que
> controla o PWA e passa a ser um **app Swift nativo** que controla o **app oficial
> `Amazon Music.app`** via Now Playing do macOS. As pendências da era Electron estão na
> seção "Obsoletas" e foram substituídas pelas de implementação Swift abaixo.

## Alta

- [ ] **Limpar a base Electron** na própria pasta: remover `main.js`, `preload.js`,
  `renderer.js`, `index.html`, `style.css`, `package.json`, `package-lock.json` e
  `node_modules/`; ajustar `.gitignore` (tirar refs de pnpm/Electron, adicionar `.build/`).
  Git preserva o histórico — sem perda. (#01 2026-06-23)
- [ ] **Atualizar `CLAUDE.md`**: seção "Stack" (Electron → Swift/AppKit + SwiftUI) e
  "Estrutura de arquivos esperada". (#01 2026-06-23)
- [ ] **Setup do projeto Swift**: alvo executável via SPM + bundle `.app` montado à mão
  (`Info.plist` com `LSUIElement`) + codesign ad-hoc. (#01 2026-06-23)
- [ ] **Integrar mediaremote-adapter** (fork Swift do `ejbills`): bundlar
  `MediaRemoteAdapter.framework` + perl; rodar `stream`, parsear JSON, atualizar UI; enviar
  comandos de transporte pelo mesmo canal. (#01 2026-06-23)

## Média

- [ ] **Janela widget de mesa**: `NSWindow` em nível de desktop, presente em todos os Spaces,
  não-ativante, snap à grade com posição persistida. (#01 2026-06-23)
- [ ] **UI Liquid Glass nativo** (macOS 26): capa, título, artista, barra de progresso e
  botões play/pause/anterior/próxima/seek. (#01 2026-06-23)
- [ ] **Tray na barra de menu** (`NSStatusItem`): mostrar/ocultar widget, preferências, sair. (#01 2026-06-23)
- [ ] **Tela de configurações + autostart no login** via `SMAppService`. (#01 2026-06-23)
- [ ] **Botão "abrir Amazon Music"** (`NSWorkspace`, bundle `com.amazon.music`). (#01 2026-06-23)

## Baixa

- [ ] **Persistência** (posição da janela, preferências) em `UserDefaults`. (#01 2026-06-23)
- [ ] **Empacotamento/distribuição** do `.app` (`.dmg` opcional; sem Apple Developer ID →
  contorno de Gatekeeper para uso pessoal). (#01 2026-06-23)

## Obsoletas — arquitetura Electron descartada (2026-06-23 · #01)

Marcadas `[x]` por encerramento (descartadas, não concluídas).

- [x] ~~Etapa 1 — Integração com o PWA via AppleScript~~ → descartada: o Amazon Music web
  bloqueia navegador desconhecido; abordagem trocada por controle do app oficial. (#02)
- [x] ~~Etapa 2 — Comportamento de widget de mesa (em Electron)~~ → substituída pela versão Swift. (#02)
- [x] ~~Etapa 3 — Liquid Glass via `vibrancy` do BrowserWindow~~ → substituída por Liquid Glass nativo (Swift). (#02)
- [x] ~~Etapa 4 — Persistência (Electron)~~ → substituída pela versão Swift. (#02)
- [x] ~~Etapa 6 — Empacotamento `.dmg` do app Electron~~ → substituída por empacotamento `.app` Swift. (#02)
