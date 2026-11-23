# 📡 Referência Completa de Rotas e Payloads — ACBRWebService (`API_ROUTES.md`)

Este documento cataloga todos os endpoints HTTP expostos pelo **ACBRWebService** (porta padrão **`9002`**), a convenção de serialização/desserialização **100% RTTI-First** (`TJSONTools.ObjToJson` / `TJSONTools.JsonToObj`) sobre as classes nativas do Projeto ACBr, os identificadores de enums Object Pascal e exemplos práticos 100% sintéticos prontos para teste.

---

## 🧭 Sumário

1. [Convenções Gerais e Objeto `config` (`TACBrDFeConfiguracoes`)](#1-convenções-gerais-e-objeto-config-tacbrdfeconfiguracoes)
2. [Tabela de Identificadores de Enums Object Pascal (RTTI)](#2-tabela-de-identificadores-de-enums-object-pascal-rtti)
3. [Certificados Digitais A1 (`/certificados`)](#3-certificados-digitais-a1-certificados)
4. [NF-e Modelo 55 e NFC-e Modelo 65 (`/nfe`)](#4-nf-e-modelo-55-e-nfc-e-modelo-65-nfe)
5. [CT-e Modelo 57 — 4.00 e Simplificado (`/cte`)](#5-ct-e-modelo-57--400-e-simplificado-cte)
6. [MDF-e Modelo 58 (`/mdfe`)](#6-mdf-e-modelo-58-mdfe)
7. [NFS-e — Padrão Nacional (`<DPS>` / ADN) e Provedores Municipais (`/nfse`)](#7-nfs-e--padrão-nacional-dps--adn-e-provedores-municipais-nfse)
8. [GNRE 1.00 & 2.00 (`/gnre`)](#8-gnre-100--200-gnre)
9. [EFD-Reinf, BP-e, CIOT e eSocial (`/reinf`, `/bpe`, `/ciot`, `/esocial`)](#9-efd-reinf-bp-e-ciot-e-esocial-reinf-bpe-ciot-esocial)
10. [SPED Fiscal (`EFD ICMS/IPI`) e EFD Contribuições (`PIS/COFINS`) (`/sped`)](#10-sped-fiscal-efd-icmsipi-e-efd-contribuições-piscofins-sped)
11. [Sintegra — `126` Colunas Posicionais (`/sintegra`)](#11-sintegra--126-colunas-posicionais-sintegra)
12. [Boleto Bancário FPDF, CNAB 240/400 e PIX EMV (`/boleto`)](#12-boleto-bancário-fpdf-cnab-240400-e-pix-emv-boleto)
13. [Impressão Térmica e Spool Temporário (`/escpos`)](#13-impressão-térmica-e-spool-temporário-escpos)
14. [Balanças (`CargaBal` / `InStore`), IBPTax e Utilitários (`/diversos`)](#14-balanças-cargabal--instore-ibptax-e-utilitários-diversos)

---

## 1. Convenções Gerais e Objeto `config` (`TACBrDFeConfiguracoes`)

- **Content-Type:** `application/json; charset=utf-8` em todas as requisições `POST`.
- **Descoberta Dinâmica Pura de Esquema (`GET /modelo/<modulo>/<operacao>`):** Instancia a classe real do componente ACBr sem valores fictícios ou chaves extras e retorna `TJSONTools.SafeObjToJson(...)` diretamente via Extended RTTI do Free Pascal `3.3.1`.
- **Chave `"config"`:** Nos endpoints DF-e (`nfe`, `cte`, `mdfe`, `nfse`, `gnre`, `reinf`, `bpe`, `ciot`, `esocial`) e componentes (`boleto`, `escpos`, `sintegra`, `sped`), o servidor extrai `"config"` da raiz do JSON (`TJSONTools.ExtractConfig`) e popula a configuração do componente via RTTI antes de executar a operação. Operações online exigem `config` não vazio (`RSConfigEmptyError`).
- **Resolução Automática de `PathSchemas`:** Quando `config.Arquivos.PathSchemas` está vazio (`""`) ou aponta para a pasta raiz `Schemas/` do servidor, a ponte anexa automaticamente a subpasta do documento (`NFe`, `CTe`, `MDFe`, `NFSe` ou `GNRe`) relativa ao executável (`ExtractFilePath(ParamStr(0))`).

### Exemplo Padrão de `config` (`TCertificadosConf` RTTI)
```json
{
  "Certificados": {
    "ArquivoPFX": "c:\\caminho\\para\\certificado.pfx",
    "DadosPFX": "",
    "Senha": "senha_do_certificado"
  },
  "Geral": {
    "ModeloDF": "moNFe",
    "VersaoDF": "ve400",
    "SSLLib": "libOpenSSL",
    "SSLCryptLib": "cryOpenSSL",
    "SSLHttpLib": "httpOpenSSL",
    "SSLXmlSignLib": "xsLibXml2",
    "FormaEmissao": "teNormal",
    "RetirarAcentos": true,
    "Salvar": false,
    "ExibirErroSchema": true
  },
  "WebServices": {
    "Ambiente": "taHomologacao",
    "UF": "SP",
    "TimeOut": 30000,
    "Visualizar": false
  },
  "Arquivos": {
    "Salvar": false,
    "PathSchemas": ""
  },
  "RespTec": {
    "IdCSRT": 0,
    "CSRT": ""
  }
}
```

> **Nota (`CNPJCPF`):** Nos atores das classes PCN/ACBr (`Emit`, `Dest`, `Rem`, `Exped`, `Receb`, `autXML`, `Cedente`, `Sacado`), informe o documento sem máscara (11 ou 14 dígitos) exatamente na propriedade RTTI **`CNPJCPF`**.

---

## 2. Tabela de Identificadores de Enums Object Pascal (RTTI)

O motor `TJSONTools.JsonToObj` aceita o **identificador textual exato do enum Pascal** (recomendado) ou seu valor ordinal inteiro dentro da faixa do tipo:

| Propriedade | Valores Aceitos (Identificadores Pascal) |
| :--- | :--- |
| **Ambiente (`WebServices.Ambiente`)** | `taProducao`, `taHomologacao` |
| **Modelo DF (`Geral.ModeloDF`)** | `moNFe` (55), `moNFCe` (65) |
| **Forma de Emissão (`FormaEmissao` / `tpEmis`)** | `teNormal`, `teContingencia`, `teSCAN`, `teDPEC`, `teFSDA`, `teSVCAN`, `teSVCRS`, `teSVCSP`, `teOffLine` |
| **Tipo de Evento DF-e (`tpEvento`)** | `teCancelamento`, `teCCe`, `teEncerramento`, `teInclusaoCondutor`, `teInclusaoDFe`, `tePagamentoOperacao`, `teManifDestConfirmacao`, `teManifDestCiencia`, `teManifDestDesconhecimento`, `teManifDestOperNaoRealizada` |
| **Regime Tributário (`CRT`)** | `crtSimplesNacional`, `crtSimplesNacionalExcesso`, `crtRegimeNormal`, `crtMEI` |
| **Finalidade NF-e (`finNFe`)** | `fnNormal`, `fnComplementar`, `fnAjuste`, `fnDevolucao`, `fnCredito`, `fnDebito` |
| **Indicador IE (`indIEDest`)** | `inContribuinte`, `inIsento`, `inNaoContribuinte` |
| **Modalidade de Frete (`modFrete`)** | `mfContaEmitente`, `mfContaDestinatario`, `mfContaTerceiros`, `mfProprioRemetente`, `mfProprioDestinatario`, `mfSemFrete` |
| **Meio de Pagamento (`tPag`)** | `fpDinheiro`, `fpCheque`, `fpCartaoCredito`, `fpCartaoDebito`, `fpCreditoLoja`, `fpBoletoBancario`, `fpDepositoBancario`, `fpPagamentoInstantaneo` (PIX), `fpTransfBancario`, `fpSemPagamento`, `fpOutro` |
| **CST ICMS (`CST`)** | `cst00`, `cst10`, `cst20`, `cst30`, `cst40`, `cst41`, `cst50`, `cst51`, `cst60`, `cst61`, `cst70`, `cst90`, `cstSimples` |
| **CSOSN Simples Nacional (`CSOSN`)** | `csosn101`, `csosn102`, `csosn103`, `csosn201`, `csosn202`, `csosn203`, `csosn300`, `csosn400`, `csosn500`, `csosn900` |
| **Modal CT-e (`modal`)** | `mdRodoviario`, `mdAereo`, `mdAquaviario`, `mdFerroviario`, `mdDutoviario`, `mdMultimodal` |
| **Modal MDF-e (`modal`)** | `moRodoviario`, `moAereo`, `moAquaviario`, `moFerroviario` |
| **Layout CNAB (`LayoutRemessa`)** | `c240`, `c400` |
| **Tipo Cobrança (`Banco.TipoCobranca`)** | `cobBancoDoBrasil`, `cobSantander`, `cobCaixaEconomica`, `cobBradesco`, `cobItau`, `cobBanestes`, `cobBancoob`, `cobBancoInter`, `cobSicred`, ... |
| **Impressora EscPos (`Modelo`)** | `ppTexto`, `ppEscPosEpson`, `ppEscBematech`, `ppEscDaruma`, `ppEscVox`, `ppEscDiebold`, `ppEscPosStar`, `ppEscZJiang`, `ppEscGPrinter`, `ppEscDatecs`, `ppEscSunmi` |
| **Balança (`TACBrCargaBal.Modelo`)** | `modFilizola`, `modToledo`, `modUrano`, `modUranoS`, `modToledoMGV5`, `modToledoMGV6`, `modToledoMGV7`, `modUranoURF32`, `modRamuza`, `modToledoMGV5Ver1`, `modTriunfoRdc429` |

---

## 3. Certificados Digitais A1 (`/certificados`)

| Método | Rota | Descrição |
| :---: | :--- | :--- |
| `GET` | `/modelo/certificados/upload` (ou `/certificados/upload`) | Retorna o esquema RTTI puro de `TCertificadosConf` (`URLPFX`, `ArquivoPFX`, `DadosPFX`, `NumeroSerie`, `Senha`, `VerificarValidade`). |
| `POST` | `/certificados/upload` | Valida a senha via OpenSSL, extrai metadados ICP-Brasil (série, CNPJ, razão social, validade) e persiste no diretório local `certificados/` do servidor. Aceita `DadosPFX` (ou `certificado_base64`) e `Senha` (ou `senha`). |
| `POST` | `/certificados/ler-dados` | Lê e valida os metadados de um certificado em Base64 sem gravar arquivo permanente em disco. |

```bash
curl -X POST http://localhost:9002/certificados/ler-dados \
  -H "Content-Type: application/json" \
  -d '{
    "DadosPFX": "<CONTEUDO_PKCS12_EM_BASE64>",
    "Senha": "senha_do_certificado"
  }'
```

---

## 4. NF-e Modelo 55 e NFC-e Modelo 65 (`/nfe`)

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/nfe/nfe` | `/modelo/nfe/nfe` | Gera, assina, valida e transmite NF-e (55) ou NFC-e (65). |
| `POST` | `/nfe/nfe-lote` | `/modelo/nfe/nfe` | Emissão de lote de múltiplas notas fiscais. |
| `POST` | `/nfe/nfe-to-xml` | `/modelo/nfe/nfe-to-xml` | Gera e assina o XML a partir do JSON RTTI **sem transmitir à SEFAZ**. |
| `POST` | `/nfe/nfe-from-xml` | `/modelo/nfe/nfe-from-xml` | Converte um XML de NF-e/NFC-e (puro ou Base64) em objeto JSON RTTI. |
| `POST` | `/nfe/validar-regras` | `/modelo/nfe/validar-regras` | Valida XSD e `ValidarRegrasdeNegocios` (aceita JSON RTTI ou XML puro/Base64). |
| `POST` | `/nfe/status` | `/modelo/nfe/status` | Consulta disponibilidade dos webservices SEFAZ (`TNFeStatusServico`). |
| `POST` | `/nfe/consulta` | `/modelo/nfe/consulta` | Consulta situação atual e protocolo de autorização pela chave de 44 dígitos (`TNFeConsulta`). |
| `POST` | `/nfe/consulta-recibo` | — | Consulta resultado de processamento de recibo de lote. |
| `POST` | `/nfe/cancelamento` | `/modelo/nfe/cancelamento` | Envia evento de Cancelamento (`teCancelamento`) ou Cancelamento por Substituição. |
| `POST` | `/nfe/eventos` | `/modelo/nfe/evento` | Envia eventos gerais (`TInfEventoCollectionItem`: Carta de Correção, Manifestação, eventos RTC). |
| `POST` | `/nfe/inutilizacao` | `/modelo/nfe/inutilizacao` | Inutiliza faixa de numeração na SEFAZ (`TNFeInutilizacao`). |
| `POST` | `/nfe/distribuicao` | `/modelo/nfe/distribuicao` | Distribuição DF-e por último NSU, NSU específico ou chave. |
| `POST` | `/nfe/danfe` | — | Renderiza DANFE A4 (modelo 55) ou DANFE NFC-e 80mm (modelo 65) em PDF Base64 (`FPDF`). |
| `GET` | `/nfe/pdf/:chave` | — | Download direto do PDF gerado pela chave de 44 dígitos. |
| `POST` | `/nfe/danfe-evento` | `/modelo/nfe/danfe-evento` | Renderiza PDF de evento (Cancelamento / CC-e) a partir do XML do evento e da nota. |
| `POST` | `/nfe/danfe-escpos` | `/modelo/nfe/danfe-escpos` | Gera comandos/bobina térmica EscPos para NFC-e (`TACBrNFeDANFeESCPOS`). |
| `POST` | `/nfe/consulta-cadastro` | `/modelo/nfe/consulta-cadastro` | Consulta Cadastro de Contribuintes na SEFAZ (`TNFeConsultaCadastro`). |
| `POST` | `/nfe/email` | `/modelo/nfe/email` | Envia XML + DANFE PDF anexados via SMTP (`TACBrMail`). |

---

## 5. CT-e Modelo 57 — 4.00 e Simplificado (`/cte`)

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/cte/cte` | `/modelo/cte/cte` | Emite CT-e 4.00 ou CT-e Simplificado (`tcSimplificado`). |
| `POST` | `/cte/cte-to-xml` | `/modelo/cte/cte-to-xml` | Gera (e assina se certificado presente) o XML do CT-e sem transmitir, retornando `xml` (Base64) e `chave`. |
| `POST` | `/cte/cte-from-xml` | `/modelo/cte/cte-from-xml` | Converte XML de CT-e em JSON RTTI completo. |
| `POST` | `/cte/validar-regras` | `/modelo/cte/validar-regras` | Valida Schema XSD e regras de negócio do CT-e sem transmitir à SEFAZ. |
| `POST` | `/cte/status` | `/modelo/cte/status` | Consulta status do serviço SEFAZ CT-e (`TCTeStatusServico`). |
| `POST` | `/cte/consulta` | `/modelo/cte/consulta` | Consulta protocolo do CT-e pela chave de 44 dígitos (`TCTeConsulta`). |
| `POST` | `/cte/cancelamento` | `/modelo/cte/cancelamento` | Evento de cancelamento de CT-e. |
| `POST` | `/cte/eventos` | `/modelo/cte/evento` | Eventos de CT-e (CC-e, Prestação em Desacordo, Insucesso de Entrega). |
| `POST` | `/cte/inutilizacao` | `/modelo/cte/inutilizacao` | Inutilização de numeração de CT-e (`TCTeInutilizacao`). |
| `POST` | `/cte/distribuicao` | `/modelo/cte/distribuicao` | Distribuição DF-e do ambiente nacional CT-e. |
| `POST` | `/cte/dacte` | — | Gera PDF do DACTE em Base64 (`ACBr_CTe_DACTeFPDF`). |
| `POST` | `/cte/dacte-url` | — | Gera o PDF no servidor e retorna a URL `/cte/pdf/:chave`. |
| `GET` | `/cte/pdf/:chave` | — | Download direto do PDF do DACTE pela chave. |
| `POST` | `/cte/dacte-evento` | `/modelo/cte/dacte-evento` | Gera PDF de evento do CT-e em Base64. |

---

## 6. MDF-e Modelo 58 (`/mdfe`)

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/mdfe/mdfe` | `/modelo/mdfe/mdfe` | Emite MDF-e 3.00 (com suporte a envio síncrono SVRS). |
| `POST` | `/mdfe/mdfe-to-xml` | `/modelo/mdfe/mdfe-to-xml` | Gera (e assina se certificado presente) o XML do MDF-e localmente, retornando `xml` (Base64) e `chave`. |
| `POST` | `/mdfe/mdfe-from-xml` | `/modelo/mdfe/mdfe-from-xml` | Converte XML do MDF-e em JSON RTTI. |
| `POST` | `/mdfe/validar-regras` | `/modelo/mdfe/validar-regras` | Valida Schema XSD e `ValidarRegrasdeNegocios` do MDF-e sem transmitir à SEFAZ. |
| `POST` | `/mdfe/evento-to-xml` | `/modelo/mdfe/evento-to-xml` | Gera (e assina se certificado presente) o XML determinístico de evento MDF-e (`TInfEvento` RTTI) sem transmitir, retornando `{ status, chave, id, assinado, xml }`. |
| `POST` | `/mdfe/status` | `/modelo/mdfe/status` | Consulta status do serviço MDF-e (`TMDFeStatusServico`). |
| `POST` | `/mdfe/consulta` | `/modelo/mdfe/consulta` | Consulta protocolo do MDF-e pela chave (`TMDFeConsulta`). |
| `POST` | `/mdfe/cancelamento` | `/modelo/mdfe/cancelamento` | Evento de cancelamento de MDF-e (`teCancelamento`). |
| `POST` | `/mdfe/encerramento` | `/modelo/mdfe/encerramento` | Evento de encerramento de MDF-e (`teEncerramento`). |
| `POST` | `/mdfe/nao-encerrados` | `/modelo/mdfe/nao-encerrados` | Consulta MDF-es não encerrados (`TMDFeConsultaMDFeNaoEnc`). |
| `POST` | `/mdfe/eventos` | `/modelo/mdfe/evento` | Envio de eventos (`teInclusaoCondutor`, `teInclusaoDFe`, `tePagamentoOperacao`). |
| `POST` | `/mdfe/distribuicao` | `/modelo/mdfe/distribuicao` | Distribuição DF-e MDF-e. |
| `POST` | `/mdfe/damdfe` | — | Gera PDF do DAMDFE em Base64. |
| `POST` | `/mdfe/damdfe-url` | — | Gera o DAMDFE e retorna a URL `/mdfe/pdf/:chave`. |
| `GET` | `/mdfe/pdf/:chave` | — | Download direto do PDF do DAMDFE. |
| `POST` | `/mdfe/damdfe-evento` | — | Gera PDF de evento do MDF-e (aceita XML base do MDF-e + XML do evento). |
| `POST` | `/mdfe/email` | `/modelo/mdfe/email` | Envia o XML e o DAMDFE PDF por e-mail via SMTP (`TACBrMail`). |

### Exemplo: Geração Offline de XML de Evento de Encerramento MDF-e (`POST /mdfe/evento-to-xml`)
```bash
curl -X POST http://localhost:9002/mdfe/evento-to-xml \
  -H "Content-Type: application/json" \
  -d '{
    "config": {
      "WebServices": { "Ambiente": "taHomologacao", "UF": "SP" }
    },
    "chMDFe": "35260112345678000195580010000000011000000018",
    "CNPJCPF": "12345678000195",
    "tpEvento": "teEncerramento",
    "nSeqEvento": 1,
    "detEvento": {
      "nProt": "935260000000001",
      "dtEnc": "2026-01-31",
      "cUF": 35,
      "cMun": 3550308
    }
  }'
```

---

## 7. NFS-e — Padrão Nacional (`<DPS>` / ADN) e Provedores Municipais (`/nfse`)

O módulo `/nfse` encapsula o `TACBrNFSeX`, atendendo tanto o **Ambiente de Dados Nacional (ADN / `<DPS>`)** quanto os provedores municipais configurados no `ACBrNFSeXServicos.ini` (com seleção pelo código IBGE `Geral.CodigoMunicipio` ou explícita via `ForcarNacional: true` / `PadraoNacional: true`).

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/nfse/emitir` | `/modelo/nfse/emitir` | Emite RPS / DPS (lote ou unitário conforme o provedor). |
| `POST` | `/nfse/gerar` | `/modelo/nfse/emitir` | Emissão síncrona unitária de RPS / DPS. |
| `POST` | `/nfse/nfse-to-xml` | `/modelo/nfse/nfse-to-xml` | Gera o XML do RPS ou `<DPS>` a partir do JSON RTTI sem transmitir. |
| `POST` | `/nfse/nfse-from-xml` | `/modelo/nfse/nfse-from-xml` | Converte XML de NFS-e / DPS em estrutura JSON RTTI. |
| `POST` | `/nfse/consultarsituacao` | `/modelo/nfse/consultarsituacao` | Consulta situação de lote RPS. |
| `POST` | `/nfse/consultarlote` | `/modelo/nfse/consultarlote` | Consulta lote de RPS processado. |
| `POST` | `/nfse/consultarnfseporrps` | `/modelo/nfse/consultarnfseporrps` | Consulta NFS-e a partir da identificação do RPS/DPS. |
| `POST` | `/nfse/consultarnfse` | `/modelo/nfse/consultarnfse` | Consulta NFS-e por número, período ou chave de 50 dígitos (`TInfConsultaNFSe`). |
| `POST` | `/nfse/cancelar` | `/modelo/nfse/cancelar` | Solicita cancelamento de NFS-e. |
| `POST` | `/nfse/substituir` | `/modelo/nfse/substituir` | Substituição de NFS-e. |
| `POST` | `/nfse/evento` (ou `/nfse/eventos`) | `/modelo/nfse/evento` | Envia pedido de registro de evento no Padrão Nacional (`TInfEvento`). |
| `POST` | `/nfse/consultar-eventos` | `/modelo/nfse/consultar-eventos` | Consulta eventos vinculados a uma chave de NFS-e no Ambiente Nacional. |
| `POST` | `/nfse/distribuicao` | — | Distribuição DF-e do Ambiente Nacional ADN por NSU ou chave. |
| `POST` | `/nfse/danfse` | — | Renderiza o DANFSe em PDF Base64 (`ACBr_NFSeXDanfseFPDF`). |

---

## 8. GNRE 1.00 & 2.00 (`/gnre`)

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/gnre/gnre-to-xml` | `/modelo/gnre/gnre-to-xml` | Gera o XML determinístico da(s) guia(s) `TGNRE` (`ve100` ou `ve200` em `config.Geral.VersaoDF`) **sem transmitir ao portal GNRE**, com validação XSD opcional (`ValidarXSD: true`), retornando `{ status, versao, xml }` (Base64). |
| `POST` | `/gnre/enviar` | `/modelo/gnre/guia` | Gera e transmite o lote de guias ao Portal Nacional GNRE / SEFAZ estadual. |
| `POST` | `/gnre/consultar` | `/modelo/gnre/config` | Consulta o resultado do lote GNRE pelo número de recibo (`TGNREConsulta`). |

---

## 9. EFD-Reinf, BP-e, CIOT e eSocial (`/reinf`, `/bpe`, `/ciot`, `/esocial`)

| Módulo | Rotas `GET` (Modelos) | Rotas `POST` (Operações) |
| :--- | :--- | :--- |
| **EFD-Reinf** | `/modelo/reinf/config` | `/reinf/enviar`, `/reinf/consultar` |
| **BP-e (Modelo 63)** | `/modelo/bpe/config` | `/bpe/bpe`, `/bpe/enviar` |
| **CIOT** | `/modelo/ciot/config` | `/ciot/ciot`, `/ciot/enviar` |
| **eSocial** | `/modelo/esocial/config` | `/esocial/esocial` |

---

## 10. SPED Fiscal (`EFD ICMS/IPI`) e EFD Contribuições (`PIS/COFINS`) (`/sped`)

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/sped/gerar` (ou `/sped/sped`) | `/modelo/sped/gerar` | Gera o arquivo TXT oficial da **EFD ICMS/IPI** (`TACBrSPEDFiscal` — Blocos `0`, `B`, `C`, `D`, `E`, `G`, `H`, `K`, `1` e cálculo automático do **Bloco 9**), retornando `arquivo_base64`. |
| `POST` | `/sped/importar` | — | Importa um arquivo TXT da EFD ICMS/IPI. |
| `POST` | `/sped/piscofins/gerar` | `/modelo/sped/piscofins/gerar` | Gera o arquivo TXT oficial da **EFD Contribuições** (`TACBrSPEDPisCofins` — Blocos `0`, `A`, `C`, `D`, `F`, `I`, `M`, `P`, `1` e `9`), retornando `arquivo_base64`. |
| `POST` | `/sped/piscofins/importar` | `/modelo/sped/piscofins/importar` | Importa um arquivo TXT da EFD Contribuições via `TACBrSpedPCImportar` em JSON RTTI estruturado. |

---

## 11. Sintegra — `126` Colunas Posicionais (`/sintegra`)

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/sintegra/gerar` (ou `/sintegra/sintegra`) | `/modelo/sintegra/gerar` | Gera o arquivo magnético do Sintegra via `TACBrSintegra` (`Registros 10, 11, 50, 51, 53, 54, 55, 60M/A/D/I/R, 61/61R, 70, 71, 74, 75, 76, 77, 85, 86, 88*` e `90`) com paginação nativa de até 9 pares por linha no Registro `90` + totalizador `99` (Convênio ICMS 57/95), retornando `arquivo_base64` e `tamanho`. |

> **Nota sobre Codificação Posicional (`126` colunas):** Para garantir correspondência estrita `1 caractere = 1 byte` em Free Pascal (`UTF-8`), envie os textos dos registros já normalizados em ASCII sem diacríticos e informe `VersaoValidador` como `"vv523"` ou `"vv524"`.

---

## 12. Boleto Bancário FPDF, CNAB 240/400 e PIX EMV (`/boleto`)

| Método | Rota | Modelo (`GET`) | Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/boleto/pdf` | `/modelo/boleto/titulo` | Gera o PDF do(s) boleto(s) em Base64 (`ACBr_BoletoFC_FPDF`), retornando `pdf`, `tamanho` (inteiro), linha digitável, código de barras e nosso número formatado (suporta boleto híbrido via `Titulo.QrCode: { emv, txId, url }` e `ACBrBoletoFC: { LayOut: "lPadraoPIX" }`). |
| `POST` | `/boleto/remessa` | `/modelo/boleto/titulo` | Gera arquivo de **Remessa CNAB 240 ou 400** (`LayoutRemessa`: `"c240"` ou `"c400"`, `Banco.TipoCobranca` explícito), devolvendo `remessa_base64` + metadados de cada título. |
| `POST` | `/boleto/retorno` | `/modelo/boleto/config` | Lê arquivo de **Retorno CNAB 240 ou 400** (`arquivo_base64`) conforme `config` (`Banco.TipoCobranca`, `LayoutRemessa`, `LeCedenteRetorno`) e retorna os títulos desserializados via RTTI (`TACBrTitulo`). |
| `POST` | `/boleto/pix-qrcode` (ou `/boleto/pix-emv`) | `/modelo/boleto/pix-qrcode` | Popula `TACBrPIXQRCodeDinamico` via RTTI (`URL`, `MerchantName`, `MerchantCity`, `PostalCode`, `TxId`, `TransactionAmount`) e retorna a string EMV `AsString` / `emv`. |
| `POST` | `/boleto/enviar` | `/modelo/boleto/config` | Registra, altera ou consulta boletos via WebService/API bancária (`TACBrBoleto.Enviar`). |

### Exemplo: Geração de Remessa CNAB 240 (`POST /boleto/remessa`)
```bash
curl -X POST http://localhost:9002/boleto/remessa \
  -H "Content-Type: application/json" \
  -d '{
    "config": {
      "LayoutRemessa": "c240",
      "RemoveAcentosArqRemessa": true,
      "Banco": {
        "Numero": 1,
        "TipoCobranca": "cobBancoDoBrasil"
      },
      "Cedente": {
        "Nome": "EMPRESA EXEMPLO LTDA",
        "CNPJCPF": "12345678000195",
        "TipoInscricao": "pJuridica",
        "Agencia": "1234",
        "AgenciaDigito": "5",
        "Conta": "00012345",
        "ContaDigito": "6",
        "Convenio": "1234567",
        "CodigoCedente": "1234567",
        "Modalidade": "19",
        "Logradouro": "AVENIDA EXEMPLO",
        "NumeroRes": "1000",
        "Bairro": "CENTRO",
        "Cidade": "SAO PAULO",
        "UF": "SP",
        "CEP": "01001000"
      }
    },
    "NumeroRemessa": 1,
    "Titulos": [
      {
        "Carteira": "17",
        "NossoNumero": "0000000001",
        "NumeroDocumento": "NF-1001/01",
        "Vencimento": "2026-12-31",
        "DataDocumento": "2026-11-20",
        "ValorDocumento": 350.00,
        "EspecieDoc": "DM",
        "Aceite": "atNao",
        "Sacado": {
          "NomeSacado": "CLIENTE EXEMPLO LTDA",
          "CNPJCPF": "00000000000191",
          "Logradouro": "RUA CLIENTE",
          "Numero": "200",
          "Bairro": "CENTRO",
          "Cidade": "SAO PAULO",
          "UF": "SP",
          "CEP": "01002000"
        }
      }
    ]
  }'
```

---

## 13. Impressão Térmica e Spool Temporário (`/escpos`)

| Método | Rota | Descrição |
| :---: | :--- | :--- |
| `GET` | `/modelo/escpos/config` | Retorna o modelo RTTI puro de `TACBrPosPrinter` (`Modelo`, `Porta`, `ColunasFonteNormal`, `PaginaDeCodigo`, `CortaPapel`, `TraduzirTags`, `Buffer`, `ConfigBarras`, `ConfigQRCode`, etc.). |
| `GET` | `/escpos/portas` | Lista portas seriais/impressoras disponíveis no host (`portas`). |
| `POST` | `/escpos/escpos` | Configura `TACBrPosPrinter` via RTTI (em `"config"` JSON/INI e/ou na raiz do JSON), traduz tags ACBr EscPos (`Buffer` ou `Linhas`/`Texto`) e envia para a `Porta` configurada. Quando `Porta` é vazia (`""`), gera spool temporário isolado em `tmp/escpos_<tick>_<rnd>.bin`, retorna `spool_base64` e remove o arquivo imediatamente. |

**Modelos aceitos (`Modelo` — `TACBrPosPrinterModelo`):** `ppTexto`, `ppEscPosEpson`, `ppEscBematech`, `ppEscDaruma`, `ppEscVox`, `ppEscDiebold`, `ppEscEpsonP2`, `ppCustomPos`, `ppEscPosStar`, `ppEscZJiang`, `ppEscGPrinter`, `ppEscDatecs`, `ppEscSunmi`, `ppExterno`.

**Páginas de código aceitas (`PaginaDeCodigo` — `TACBrPosPaginaCodigo`):** `pcNone`, `pc437`, `pc850`, `pc852`, `pc860`, `pcUTF8`, `pc1252`.

---

## 14. Balanças (`CargaBal` / `InStore`), IBPTax e Utilitários (`/diversos`)

| Método | Rota | Modelo (`GET`) | Componente ACBr / Descrição |
| :---: | :--- | :--- | :--- |
| `POST` | `/diversos/balanca/carga` | `/modelo/diversos/balanca/carga` | `TACBrCargaBal` — Gera arquivos de carga (`ITENSMGV.TXT`, `TXITENS.TXT`, `CADTXT.TXT`, etc. em Base64) via RTTI (`Modelo`, `Produtos`, `Operadores`). |
| `POST` | `/diversos/balanca/instore` | `/modelo/diversos/balanca/instore` | `TACBrInStore` — Decodifica etiquetas EAN-13 conforme `Codificacao` configurada via RTTI e `CodigoEtiqueta`. |
| `POST` | `/diversos/ibpt/ler-tabela` | `/modelo/diversos/ibpt/config` | `TACBrIBPTax` — Processa tabela CSV IBPT (`arquivo_base64` ou `Arquivo`) e consulta alíquotas aproximadas federal/estadual/municipal por `NCM`. |
| `POST` | `/diversos/validador` | `/modelo/diversos/validador` | `TACBrValidador` — Valida CPF, CNPJ, Inscrição Estadual, GTIN/EAN, CEP, Cartão, PIS e Renavam via RTTI (`TipoDocto`, `Documento`, `Complemento`), retornando booleano JSON. |
| `POST` | `/diversos/extenso` | `/modelo/diversos/extenso` | `TACBrExtenso` — Converte `Valor` monetário para escrita por extenso (`Texto`). |
| `POST` | `/diversos/cmc7` | `/modelo/diversos/cmc7` | `TACBrCMC7` — Valida ou monta banda magnética CMC7 de cheques, serializando todas as propriedades RTTI de `TACBrCMC7`. |
| `POST` | `/diversos/calc-digito` | `/modelo/diversos/calc-digito` | `TACBrCalcDigito` — Calcula dígito verificador Módulo 10 / Módulo 11 parametrizável (`FormulaDigito`, `Documento`, `MultiplicadorInicial`, `MultiplicadorFinal`). |
| `POST` | `/diversos/ead` | `/modelo/diversos/ead` | `TACBrEAD` — Assinatura RSA EAD, geração de par de chaves e hashes MD5/SHA. |
| `POST` | `/diversos/mail` | `/modelo/diversos/mail` | `TACBrMail` — Disparo SMTP genérico via RTTI (`Host`, `Port`, `Username`, `Password`, `SetSSL`, `SetTLS`, `IsHTML`, `From`, `Subject`, `Body`, destinatários `To`/`Para`/`CC` e `Anexos` Base64) ou geração de stream `.eml` MIME (`ApenasGerarMime: true`). |
