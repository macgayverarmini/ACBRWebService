# Teste de Geração de XML CTe via API

Este diretório contém um script Python para testar a geração de XML do CTe utilizando a API do ACBRWebService.

## Pré-requisitos

1. O projeto deve estar compilado e rodando.
   - Executável: `bin/ACBRWebService-x86_64-win64.exe`
   - Porta: 9001
   - Certifique-se de que as DLLs do LibXml2 (x64) estejam na pasta `bin` junto com o executável.

2. Python instalado com a biblioteca `requests`.
   ```bash
   pip install requests
   ```

## Como rodar

Execute o script `generate_cte_xml.py`:

```bash
python generate_cte_xml.py
```

## O que o script faz

1. Lê o arquivo XML de exemplo: `src/resources/cteTestData.xml`.
2. Converte para Base64 e envia para o endpoint `/cte/cte-from-xml`.
3. Recebe o JSON correspondente ao CTe.
4. Adiciona um objeto de configuração dummy ao JSON.
5. Envia o JSON para o endpoint `/cte/cte-to-xml`.
6. Recebe o XML gerado (Base64) e salva em `src/tests/generated_cte.xml`.

## Resultados

O arquivo gerado `generated_cte.xml` deve ser um XML válido de CTe, similar ao original.
