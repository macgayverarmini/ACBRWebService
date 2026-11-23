# 🌐 ACBRWebService

**Microserviço HTTP REST/JSON open-source em Object Pascal (Lazarus + Free Pascal + Horse) com arquitetura 100% RTTI-First sobre a suíte oficial [Projeto ACBr](https://www.projetoacbr.com.br/).**

> Exponha emissões fiscais (DF-e), geração determinística de XML, validação de XSD e regras de negócio, pré-visualização de PDF (FPDF nativo sem dependências gráficas), obrigações acessórias (SPED e Sintegra), boletos bancários híbridos (CNAB 240/400 + PIX EMV), carga de balanças e impressão térmica EscPos para qualquer stack (Node.js, Python, Go, Java, C#, PHP, Rust) via payloads JSON refletidos diretamente das classes Object Pascal do ACBr na porta **`9002`**.

---

## 📚 Documentação Rápida

| Documento | Conteúdo |
| :--- | :--- |
| **[API_ROUTES.md](API_ROUTES.md)** | Catálogo completo de endpoints HTTP (`GET /modelo/...` e `POST /...`), tabela de Enums RTTI e exemplos práticos de payloads JSON e `curl`. |
| **[BUILD_GUIDE.md](BUILD_GUIDE.md)** | Guia passo a passo de compilação nativa em **Windows (`win64`)** e **Linux (`x86_64`)** com Free Pascal `3.3.1` (`Extended RTTI`) + `lazbuild` e execução da suíte de testes (`TestRunner`). |

---

## ✨ Principais Capacidades

- **Documentos Fiscais Eletrônicos (DF-e):**
  - **NF-e (Modelo 55) e NFC-e (Modelo 65):** emissão unitária (`/nfe/nfe`) e em lote (`/nfe/nfe-lote`), consulta de protocolo e recibo, cancelamento, Carta de Correção (`CC-e`), Manifestação do Destinatário, eventos da Reforma Tributária (`IBS/CBS/IS`), inutilização, Distribuição DF-e, DANFE A4 / NFC-e 80mm em PDF (FPDF) e bobina EscPos, consulta de cadastro e envio por e-mail.
  - **CT-e (Modelo 57 — 4.00 e Simplificado):** emissão, consulta, cancelamento, eventos (CC-e, desacordo, insucesso de entrega), inutilização, Distribuição DF-e, DACTE e DACTE de Evento em PDF.
  - **MDF-e (Modelo 58):** emissão (incluindo modo síncrono SVRS), consulta, cancelamento, encerramento, consulta de não encerrados, inclusão de condutor/DF-e, Distribuição DF-e, DAMDFE / DAMDFE de Evento e envio por e-mail SMTP (`POST /mdfe/email`).
  - **NFS-e (`TACBrNFSeX`):** suporte unificado ao **Padrão Nacional (`<DPS>` / ADN)** (emissão, eventos, consulta de eventos por chave via `POST /nfse/consultar-eventos` e Distribuição DF-e Nacional) e aos **provedores municipais** suportados nativamente pelo `ACBrNFSeXServicos.ini`, além de DANFSe em PDF.
  - **GNRE (1.00 e 2.00):** geração determinística de XML (`POST /gnre/gnre-to-xml`), transmissão de lote e consulta de resultado (`TACBrGNRE`).
  - **EFD-Reinf, BP-e, CIOT e eSocial:** transmissão, consulta e geração de payloads via pontes dedicadas.
- **Geração Determinística de XML, Validação Offline e PDF sem Transmissão SOAP:**
  - NF-e/NFC-e: `POST /nfe/nfe-to-xml`, `POST /nfe/nfe-from-xml`, `POST /nfe/validar-regras`, `POST /nfe/danfe`
  - CT-e: `POST /cte/cte-to-xml`, `POST /cte/cte-from-xml`, `POST /cte/validar-regras`, `POST /cte/dacte`
  - MDF-e: `POST /mdfe/mdfe-to-xml`, `POST /mdfe/evento-to-xml`, `POST /mdfe/mdfe-from-xml`, `POST /mdfe/validar-regras`, `POST /mdfe/damdfe`
  - GNRE: `POST /gnre/gnre-to-xml`
  - NFS-e: `POST /nfse/nfse-to-xml`, `POST /nfse/nfse-from-xml`, `POST /nfse/danfse`
- **Obrigações Acessórias (SPED e Sintegra):**
  - **SPED Fiscal (`EFD ICMS/IPI`) e EFD Contribuições (`PIS/COFINS`):** geração completa via `TACBrSPEDFiscal` (`/sped/gerar`) e `TACBrSPEDPisCofins` (`/sped/piscofins/gerar`) com cálculo oficial do Bloco 9 e importação estruturada via `TACBrSpedPCImportar` (`/sped/piscofins/importar`).
  - **Sintegra (`POST /sintegra/gerar`):** geração magnética via `TACBrSintegra` com paginação automática de múltiplos Registros `90` (até 9 totalizadores por linha + `99` conforme Convênio ICMS 57/95) e **exatamente `126` colunas (`CRLF`)**.
- **Cobrança Bancária, CNAB 240/400 e PIX Híbrido (`TACBrBoleto`):**
  - Impressão de boletos em PDF (FPDF) com QR Code PIX nativo (`Titulo.QrCode`), geração de **Remessa CNAB 240 e 400** (`LayoutRemessa`: `c240` | `c400`), **Leitura de Retorno CNAB 240/400**, integração com APIs bancárias (`/boleto/enviar`) e geração de payload **PIX EMV (`TACBrPIXQRCodeDinamico`)** (`POST /boleto/pix-qrcode`).
- **Automação Comercial e Utilitários (`Hardware & Diversos`):**
  - **Carga de Balanças (`TACBrCargaBal`):** geração de arquivos de carga (`POST /diversos/balanca/carga`) para **Toledo (`modToledo`, `modToledoMGV5`, `modToledoMGV6`, `modToledoMGV7`)**, **Filizola (`modFilizola`)**, **Urano**, **Ramuza** e **Triunfo**, além de decodificação de etiquetas EAN-13 (`TACBrInStore` em `POST /diversos/balanca/instore`).
  - **Impressão Térmica EscPos (`TACBrPosPrinter`):** configuração 100% RTTI (`Modelo`, `PaginaDeCodigo`, `ColunasFonteNormal`, `CortaPapel`, `Buffer`), com envio direto para portas físicas/TCP ou geração segura de **spool temporário em `Base64`** quando `Porta: ""` (`POST /escpos/escpos` e `GET /escpos/portas`).
  - **Utilitários Fiscais:** certificados digitais A1 (`POST /certificados/upload`, `POST /certificados/ler-dados`), validação de CPF/CNPJ/IE/GTIN/CEP (`POST /diversos/validador`), cheque CMC7 (`POST /diversos/cmc7`), assinatura EAD/MD5 (`POST /diversos/ead`), dígito verificador (`POST /diversos/calc-digito`), valor por extenso (`POST /diversos/extenso`), tabela IBPTax (`POST /diversos/ibpt/ler-tabela`) e envio SMTP (`POST /diversos/mail`).

---

## 🏗️ Arquitetura: Horse + Pure Extended RTTI (`TJSONTools`)

Diferente de wrappers manuais que exigem manutenção de centenas de DTOs intermediários a cada Nota Técnica da SEFAZ, o **ACBRWebService** combina o microframework HTTP **[Horse](https://github.com/HashLoad/horse)** (porta **`9002`**) com o **Extended RTTI (`TRttiContext`)** do **Free Pascal `3.3.1` (`-dENABLE_DELPHI_RTTI`)**.

```mermaid
flowchart LR
    Client["Cliente HTTP (REST/JSON)"] -->|POST /modulo/operacao| Horse["Servidor Horse (:9002)"]
    Horse --> Bridge["Bridge Object Pascal (method.acbr.*.pas)"]
    Bridge <-->|TJSONTools JsonToObj / ObjToJson| RTTI["Extended RTTI (FPC 3.3.1)"]
    RTTI <--> ACBr["Componentes Nativos ACBr + FPDF + OpenSSL/LibXml2"]
    ACBr -->|Opcional| Ext["SEFAZ / ADN / Bancos / Impressoras"]
```

### 1. Descoberta Dinâmica Pura (`GET /modelo/<modulo>/<operacao>`)
Toda rota de modelo instancia a classe real do componente ACBr em memória (sem mutações ou dados fictícios) e executa `TJSONTools.SafeObjToJson` via RTTI, devolvendo o contrato exato das propriedades `public` e `published` compiladas:

```bash
curl -s http://localhost:9002/modelo/nfe/config
curl -s http://localhost:9002/modelo/nfe/nfe
curl -s http://localhost:9002/modelo/cte/cte
curl -s http://localhost:9002/modelo/mdfe/mdfe
curl -s http://localhost:9002/modelo/gnre/guia
curl -s http://localhost:9002/modelo/boleto/titulo
curl -s http://localhost:9002/modelo/escpos/config
```

### 2. Estabilidade Criptográfica Cross-Platform (Win64 & Linux x86_64)
Todas as pontes DF-e padronizam `SSLLib = libOpenSSL`, `SSLCryptLib = cryOpenSSL`, `SSLHttpLib = httpOpenSSL` e `SSLXmlSignLib = xsLibXml2`, suportando tanto caminho de certificado no host (`Certificados.ArquivoPFX`) quanto carregamento direto em memória via `Certificados.DadosPFX` (`Base64`), sem gravar chaves privadas temporárias em disco.

---

## 🚀 Exemplos Rápidos de Uso (`curl`)

### 1. Gerar XML Determinístico de GNRE 2.00 (Sem Transmissão SOAP)
```bash
curl -X POST http://localhost:9002/gnre/gnre-to-xml \
  -H "Content-Type: application/json" \
  -d '{
    "config": {
      "Geral": { "VersaoDF": "ve200" },
      "WebServices": { "Ambiente": "taHomologacao", "UF": "SP" }
    },
    "c01_UfFavorecida": "SP",
    "c02_receita": 100099,
    "c27_tipoIdentificacaoEmitente": 1,
    "c03_idContribuinteEmitente": "12345678000195",
    "c28_tipoDocOrigem": 10,
    "c04_docOrigem": "1001",
    "c06_valorPrincipal": 150.00,
    "c10_valorTotal": 150.00,
    "c14_dataVencimento": "2026-12-31",
    "c33_dataPagamento": "2026-12-31",
    "c16_razaoSocialEmitente": "EMPRESA EXEMPLO LTDA",
    "c18_enderecoEmitente": "AVENIDA EXEMPLO, 1000",
    "c19_municipioEmitente": "50308",
    "c20_ufEnderecoEmitente": "SP",
    "c21_cepEmitente": "01001000",
    "camposExtras": [
      { "CampoExtra": { "codigo": 86, "tipo": "T", "valor": "35260112345678000195550010000010011000010015" } }
    ]
  }'
```

### 2. Gerar Arquivo Sintegra (`126` Colunas Posicionais)
```bash
curl -X POST http://localhost:9002/sintegra/gerar \
  -H "Content-Type: application/json" \
  -d '{
    "VersaoValidador": "vv524",
    "Registro10": {
      "CNPJ": "12345678000195",
      "Inscricao": "110042490114",
      "RazaoSocial": "EMPRESA EXEMPLO COMERCIO E INDUSTRIA LTDA",
      "Cidade": "SAO PAULO",
      "Estado": "SP",
      "Telefone": "1130000000",
      "DataInicial": "2026-01-01",
      "DataFinal": "2026-01-31",
      "CodigoConvenio": "3",
      "NaturezaInformacoes": "3",
      "FinalidadeArquivo": "1"
    },
    "Registro11": {
      "Endereco": "AVENIDA EXEMPLO",
      "Numero": "1000",
      "Bairro": "CENTRO",
      "Cep": "01001000",
      "Responsavel": "CONTADOR EXEMPLO",
      "Telefone": "1130000000"
    }
  }'
```

### 3. Gerar Spool EscPos (`Base64`) sem Impressora Física Conectada
```bash
curl -X POST http://localhost:9002/escpos/escpos \
  -H "Content-Type: application/json" \
  -d '{
    "Modelo": "ppEscPosEpson",
    "PaginaDeCodigo": "pc850",
    "ColunasFonteNormal": 48,
    "Porta": "",
    "CortaPapel": true,
    "Buffer": [
      "</zera><ce><n>EMPRESA EXEMPLO LTDA</n></ce>",
      "<ce>CNPJ: 12.345.678/0001-95</ce>",
      "</linha_simples>",
      "<ae>ITEM 001 - PRODUTO EXEMPLO          R$ 25,00</ae>",
      "</linha_simples>",
      "<ad><e>TOTAL: R$ 25,00</e></ad>",
      "</corte_parcial>"
    ]
  }'
```

### 4. Gerar Arquivos de Carga para Balança (`Toledo MGV6` / `Filizola`)
```bash
curl -X POST http://localhost:9002/diversos/balanca/carga \
  -H "Content-Type: application/json" \
  -d '{
    "Modelo": "modToledoMGV6",
    "Produtos": [
      {
        "Codigo": 101,
        "Descricao": "PAO FRANCES KG",
        "ValorVenda": 16.90,
        "Validade": 2,
        "Tipo": "tpvPeso",
        "TipoValidade": "tpvDias"
      }
    ]
  }'
```

---

## 🛠️ Compilação Rápida (Windows & Linux)

### Requisitos Essenciais
| Componente | Versão Obrigatória | Detalhe |
| :--- | :--- | :--- |
| **Free Pascal (FPC)** | **`3.3.1` (`trunk`)** | Compilado com **`-dENABLE_DELPHI_RTTI`** (`EnableRTTI=1` no `fpcupdeluxe`). |
| **Lazarus (`lazbuild`)** | **`4.x` (`fixes_4` / `4.99`)** | Com `{$EXTENDEDRTTI ON}` na linha 3 de `acbr/Fontes/ACBrComum/ACBr.inc`. |

### Windows (`win64` / `x86_64`)
```powershell
cd C:\BuildWebService\src
& "C:\fpcupdeluxe\lazarus\lazbuild.exe" --max-process-count=1 --os=win64 --cpu=x86_64 ACBRWebService.lpi
& "C:\fpcupdeluxe\lazarus\lazbuild.exe" --max-process-count=1 --os=win64 --cpu=x86_64 tests\unit\TestRunner.lpi
```

### Linux (`linux` / `x86_64` — Nativo sem Docker)
```bash
cd ~/Documentos/ACBRWebService/src
~/development/lazarus/lazbuild \
  --lazarusdir=~/development/lazarus \
  --compiler=~/development/fpc/bin/x86_64-linux/fpc \
  -B --os=linux --cpu=x86_64 ACBRWebService.lpi

~/development/lazarus/lazbuild \
  --lazarusdir=~/development/lazarus \
  --compiler=~/development/fpc/bin/x86_64-linux/fpc \
  -B --os=linux --cpu=x86_64 tests/unit/TestRunner.lpi
```

---

## 🔒 Segurança e Boas Práticas em Produção

1. **Isolamento de Rede:** O `ACBRWebService` opera como um microserviço interno sem camada própria de autenticação de usuários. **Nunca exponha a porta `9002` diretamente na internet pública** — restrinja o bind/firewall à rede interna do backend consumidor ou utilize proxy reverso autenticado (mTLS / API Gateway).
2. **Proteção de Certificados e Artefatos Sensíveis:** Nunca versione arquivos `.pfx`, `.p12`, `.pem`, `.key`, arquivos `.ini` de produção, PDFs ou XMLs de documentos reais. O `.gitignore` bloqueia automaticamente `bin/`, `**/certificados/**`, `**/pdf/**`, `**/tmp/**`, `**/logs/**` e chaves criptográficas.

---

## 📝 Licença e Aviso Legal

Este projeto é distribuído como software livre sob licença compatível com o ecossistema [Projeto ACBr](https://www.projetoacbr.com.br/) (LGPL). O nome "ACBr" e os componentes subjacentes pertencem aos respectivos mantenedores do [Projeto ACBr](https://www.projetoacbr.com.br/); este repositório é uma ponte HTTP independente mantida pela comunidade.
