# Testes de Integração - NFMonitor

Este diretório contém testes de integração para a API do NFMonitor.
Recomendamos o uso da extensão **REST Client** para VS Code para executar estes testes diretamente do editor.

## 🚀 Como Executar

1.  **Instale a Extensão**: Procure por "REST Client" (humao.rest-client) no VS Code e instale.
2.  **Selecione o Ambiente**:
    *   Abra um arquivo `.http` (ex: `api/cte/status.http`).
    *   No canto inferior direito do VS Code (ou via comando `Ctrl+Alt+E`), selecione o ambiente (ex: `localhost`).
3.  **Execute o Teste**:
    *   Clique no link `Send Request` que aparece acima da URL de cada teste.

## 📂 Estrutura

*   `api/`: Contém os arquivos de teste `.http` organizados por módulo (CTe, NFe, etc).
*   `api/shared/env.json`: Define as variáveis de ambiente (URL base, content-type).
*   `unit/`: Reservado para testes unitários (DUnitX).

## 💡 Dicas

*   Você pode ver a resposta completa no painel lateral.
*   Use variáveis como `{{baseUrl}}` para alternar facilmente entre ambientes.
