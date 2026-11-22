# Gemini CLI - Configurações do Projeto ACBRWebService

## Caminhos de Build
- **Lazbuild:** `C:\fpcupdeluxe\lazarus\lazbuild.exe`
- **Projeto Principal:** `C:\BuildWebService\src\ACBRWebService.lpi`
- **Projeto de Testes:** `C:\BuildWebService\src\tests\unit\TestRunner.lpi`

## Binários
- **Serviço:** `C:\BuildWebService\src\bin\ACBRWebService-x86_64-win64.exe` (Porta: 9002)
- **Runner de Testes:** `C:\BuildWebService\src\tests\unit\TestRunner.exe`

## Comandos Úteis (PowerShell)
- **Build Completo:** `& "C:\fpcupdeluxe\lazarus\lazbuild.exe" -B ACBRWebService.lpi`
- **Build Testes:** `& "C:\fpcupdeluxe\lazarus\lazbuild.exe" -B TestRunner.lpi`
- **Rodar Testes:** `./TestRunner.exe --all --format=plain`

## Observações
- O serviço deve estar rodando para que os testes unitários (que são testes de integração de API) passem.
- Caso o comando `lazbuild` falhe diretamente, use o operador de chamada `&` com o caminho completo entre aspas.
