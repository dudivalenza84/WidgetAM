# Pendências — MacMediaWidget

Backlog vivo. Pendências resolvidas são marcadas com `[x]` (a linha permanece aqui).
Migração para `PENDENCIAS_CONCLUIDAS.md` só por pedido explícito.

## Alta

- [ ] **Etapa 1 — Integração com o PWA (causa raiz).** Ajustar o AppleScript em `main.js` para
  enxergar a janela do PWA `Amazon Music.app` (busca por aba via `tell application "Google Chrome"`
  pode não pegar janela app-mode). Validar leitura de `mediaSession`/estado de áudio e o controle
  de volume (setar `audio.volume` pode não refletir no player). Sem isto, o widget abre mas não controla. (#02)

## Média

- [ ] **Etapa 2 — Comportamento de widget de mesa.** Tray na barra de menu (mostrar/ocultar, sair,
  preferências); resolver nível de janela `setAlwaysOnTop('desktop')` que pode engolir cliques;
  snap à grade de widgets com posição persistida. (#02)
- [ ] **Etapa 3 — Liquid Glass nativo.** Usar `vibrancy` do `BrowserWindow` (macOS 26 Tahoe) e
  ajustar CSS; avaliar se materiais novos exigem upgrade do Electron 31. (#02)
- [ ] **Etapa 6 — Empacotamento `.dmg`.** `electron-builder`, target dmg, ícone `.icns`. Definir
  assinatura/notarização (sem Apple Developer ID → contorno de Gatekeeper para uso pessoal). (#02)

## Baixa

- [ ] **Etapa 4 — Persistência.** Salvar posição da janela e volume entre execuções. (#02)
