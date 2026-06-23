# Changelog — MacMediaWidget

Formato semver: MINOR por release cronológica, PATCH para hotfix.
Entradas novas vão no topo.

## [1.0.1] — 2026-06-22 · #02

- Recuperado o ambiente Electron quebrado pelo pnpm: removidos artefatos do pnpm, reinstalação
  via npm e extração manual do binário do Electron 31 (postinstall não completava sob Node v26).
  `npm start` volta a abrir o widget.
- `.gitignore` passa a ignorar `pnpm-*.yaml`.
- Aberta a reconstrução de features (integração PWA, widget de mesa, Liquid Glass nativo,
  empacotamento `.dmg`); etapas registradas em `PENDENCIAS.md`.

## [1.0.0] — 2026-06-22 · #01

- Projeto migrado para git e publicado no GitHub (`dudivalenza84/WidgetAM`).
- Protocolo de governança de sessões configurado (`CLAUDE.md`, `SESSIONS.md`, `PENDENCIAS.md`, `docs/sessions/`).
