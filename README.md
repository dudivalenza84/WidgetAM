# MacMediaWidget

Um widget de desktop interativo e com design premium para macOS que permite controlar a reprodução do Amazon Music rodando no Google Chrome (instalado como PWA).

## Tecnologias
- **Electron**: Criação de janelas nativas, transparente e sem bordas.
- **Node.js**: Backend para comunicação com eventos do sistema e execução de AppleScript.
- **HTML5/Vanilla CSS/JavaScript**: Interface com visual jateado (glassmorphism), animações de hover e sliders integrados.

## Requisitos
- macOS Sonoma ou superior.
- Google Chrome instalado.
- Node.js instalado.

## Instalação e Execução

1. Instale as dependências:
   ```bash
   npm install
   ```

2. Execute o widget:
   ```bash
   npm start
   ```

## Como Funciona
O processo principal do Electron executa periodicamente um script em AppleScript que localiza a aba do Amazon Music no Google Chrome. Ele injeta um pequeno código em JavaScript para ler as informações de metadados (`navigator.mediaSession.metadata`) e o estado de áudio (volume, progresso e reprodução) e os envia ao widget. Os cliques e ajustes nos sliders enviam comandos de volta para o navegador.
