(atenção, esse texto foi gerado usando Chat GPT da OpenAI, assim com várias partes do código.)

# ACBRWebService

O projeto ACBRWebService é uma tentativa de usar a ACBR por meio de uma API REST. Devido ao tamanho da ACBR os benefícios são ilimitados, qualquer tipo de microservice pode se tornar poderoso havendo um endpoint para a ACBR. Por exemplo a classe ACBR Validador aceleraria qualquer projeto em que um backend precisaria validar documentos nacionais, Gerar uma DANFE por XML com muita simplicidade e obter o PDF em base64, transformar uma estação qualquer, ou mesmo um Raspberry em uma central de impressão, enviando comandos para uma impressora ESCPOS ou mesmo lendo um peso de Balança, a lista seria enorme.

É importante notar que o projeto inicialmente não vai se preocupar com autenticação da API, haja visto que inicialmente a idéia é utilizar junto a outro backend de outra linguágem de progração, ou serviços de automação como o N8N, você facilmente poderia inserir em uma imagem DOCKER do N8N e tornar uma ferramenta que já é poderosa, ainda mais.

Esse projeto não tem intenção de funcionar no Delphi, apenas no Lazarus, isso é devido não apenas por ser uma ferramenta gratuita, mas porque o RTTI do lazarus ao transformar um JSON em TObject ser mais eficiente, e somente por isso que o código desse repositório se tornou viável.

## Requisitos
- Versão 3.2.0 do Free Pascal Compiler (FPC).
- Versão 2.2.0 do Lazarus.
- fpcupdeluxe instalado para compilar o código fonte. (https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases/tag/v2.2.0n)
- Componente ACBR (informações disponíveis em http://acbr.sourceforge.net/).
- FortesReport-CE4 (informações disponíveis em http://www.fortesinformatica.com.br/produtos/report-ce/).
- Horse (informações disponíveis em https://github.com/HashLoad/horse).
- Python 3 (Para permitir converter a propriedade dos arquivos da ACBRDFe (inteira) em publish

## Instalação
1. Faça o download do fpcupdeluxe em https://github.com/LongDirtyAnimAlf/fpcupdeluxe.
2. Instale o fpcupdeluxe seguindo as versões informada em requisitos.
3. Baixe e instale os componentes ACBR, FortesReport-CE4 e Horse no Lazarus.
4. Baixe e instale o Python3.
5. Clone o repositório ACBRWebService em sua máquina.
6. Execute o compando na sua pasta clonada "python script_altera_acbr.py"

## Licença
O projeto ACBRWebService é licenciado sob a mesma licença do projeto ACBR.

## Nota
O nome "ACBR" no nome do projeto não é de autoria do desenvolvedor e pertence ao projeto ACBR. O uso do nome é apenas para chamar a atenção do projeto ACBR e para que no futuro ele possa ser incluído no repositório oficial.

## Clonando o Repositório
Abra o terminal ou prompt de comando e navegue até a pasta onde deseja clonar o repositório. Em seguida, execute o seguinte comando:

git clone https://github.com/macgayverarmini/ACBRWebService.git

# Project: ACBRWebAPI Public
API Rest para integração com ACBR por HTTP
# 📁 Collection: NFe 


## End-point: nfeEventos
#### LoadXML *("LoadXML": XmlBase64)*

Qualquer requisição de qualquer tipo de eventos, uma chave personalizada chamada **LoadXML** pode ser usada, nela deve ir o XML em **base64,**

Quando informada, o componente da ACBR carrega o XML antes de carregar os demais parâmetros, permitindo realizar um cancelamento por XML.
### Method: POST
>```
>{{baseurl}}/{{nfe}}/eventos
>```
### Body (**raw**)

```json
{
    "config": {},
    "eventos": [
        {
            "InfEvento": {
                "CNPJ": "",
                "cOrgao": 0,
                "chNFe": "",
                "detEvento": {
                    "IE": "",
                    "autXML": [],
                    "cOrgaoAutor": 0,
                    "chNFeRef": "",
                    "descEvento": "",
                    "dest": {
                        "CNPJCPF": "",
                        "IE": "",
                        "UF": "",
                        "idEstrangeiro": ""
                    },
                    "dhEmi": "1899-12-30T00:00:00",
                    "dhEntrega": "1899-12-30T00:00:00",
                    "dhHashComprovante": "1899-12-30T00:00:00",
                    "hashComprovante": "",
                    "idPedidoCancelado": "",
                    "itemPedido": [],
                    "latGPS": 0.0000000000000000E+000,
                    "longGPS": 0.0000000000000000E+000,
                    "nDoc": "",
                    "nProt": "",
                    "nProtEvento": "",
                    "tpAutor": "taEmpresaEmitente",
                    "tpAutorizacao": "taNaoPermite",
                    "tpNF": "tnEntrada",
                    "vICMS": 0.0000000000000000E+000,
                    "vNF": 0.0000000000000000E+000,
                    "vST": 0.0000000000000000E+000,
                    "verAplic": "",
                    "versao": "",
                    "xCondUso": "",
                    "xCorrecao": "",
                    "xJust": "",
                    "xNome": ""
                },
                "dhEvento": "1899-12-30T00:00:00",
                "id": "",
                "nSeqEvento": 0,
                "tpAmb": "taProducao",
                "tpEvento": "teNaoMapeado",
                "versaoEvento": ""
            }
        }
    ]
}
```


⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: nfeDanfe
#### LoadXML *("LoadXML": XmlBase64)*

Qualquer requisição de qualquer tipo de eventos, uma chave personalizada chamada **LoadXML** pode ser usada, nela deve ir o XML em **base64,**

Quando informada, o componente da ACBR carrega o XML antes de carregar os demais parâmetros, permitindo realizar um cancelamento por XML.
### Method: POST
>```
>{{baseurl}}/{{nfe}}/danfe
>```
### Body (**raw**)

```json
{
    "config": {},
    "xml": ""
}
```


⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: nfeManifDestConfirmacao
### Method: POST
>```
>{{baseurl}}/{{nfe}}/eventos
>```
### Body (**raw**)

```json
{
    "config": {},
    "eventos": [
        {
            "InfEvento": {
                "CNPJ": "00000000000000",
                "cOrgao": 91,
                "chNFe": "32220400000000000000550010000000681967374995",
                "dhEvento": "2022-04-10T18:21:00",
                "id": "",
                "nSeqEvento": 0,
                "tpAmb": "taHomologacao",
                "tpEvento": "teManifDestConfirmacao"
            }
        }
    ]
}
```


⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: nfeCancelarComXML
#### LoadXML *("LoadXML": XmlBase64)*

Qualquer requisição de qualquer tipo de eventos, uma chave personalizada chamada **LoadXML** pode ser usada, nela deve ir o XML em **base64,**

Quando informada, o componente da ACBR carrega o XML antes de carregar os demais parâmetros, permitindo realizar um cancelamento por XML.
### Method: POST
>```
>{{baseurl}}/{{nfe}}/eventos
>```
### Body (**raw**)

```json
{
    "config": {},
    "eventos": [
        {
            "InfEvento": {
                "LoadXML": "",
                "CNPJ": "00000000000000",
                "cOrgao": 91,
                "chNFe": "32220400000000000000550010000000681967374995",
                "dhEvento": "2022-04-10T18:21:00",
                "id": "",
                "nSeqEvento": 0,
                "tpAmb": "taHomologacao",
                "tpEvento": "teManifDestConfirmacao"
            }
        }
    ]
}
```


⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: nfeDistribuicao
### Method: POST
>```
>{{baseurl}}/{{nfe}}/distribuicao
>```
### Body (**raw**)

```json
{
    "config":  {},   
    "CNPJCPF": "00000000000000",
    "ListaArqs": [],
    "NSU": "400",    
    "cUFAutor": 32,
    "chNFe": "",
    "ultNSU": "" 
}
```


⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃
# 📁 Collection: Modelos 


## End-point: nfeModeloConfig
### Method: GET
>```
>{{baseurl}}/modelo/{{nfe}}/config
>```

⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: extensoModelo
### Method: GET
>```
>{{baseurl}}/modelo/{{diversos}}/extenso
>```

⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: validadorModelo
### Method: GET
>```
>{{baseurl}}/modelo/{{diversos}}/validador
>```

⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: nfeModeloEvento
### Method: GET
>```
>{{baseurl}}/modelo/{{nfe}}/evento
>```

⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: nfeModeloEvento Copy
### Method: GET
>```
>{{baseurl}}/modelo/{{nfe}}/evento
>```

⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: nfeModeloDistribuicao
### Method: GET
>```
>{{baseurl}}/modelo/{{nfe}}/distribuicao
>```

⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃
# 📁 Collection: Diversos 


## End-point: extenso
### Method: GET
>```
>{{baseurl}}/{{diversos}}/extenso
>```
### Body (**raw**)

```json
{
    "AboutACBr": "ACBrAbout",
    "Formato": "extPadrao",
    "Name": "",
    "StrCentavo": "Centavo",
    "StrCentavos": "Centavos",
    "StrMoeda": "Real",
    "StrMoedas": "Reais",
    "Tag": 0,
    "Texto": "",
    "Valor": 150,
    "ZeroAEsquerda": true
}
```


⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃

## End-point: validador
### Method: GET
>```
>{{baseurl}}/{{diversos}}/validador
>```
### Body (**raw**)

```json
{
    "AboutACBr": "ACBrAbout",
    "AjustarTamanho": false,
    "Complemento": "",
    "Documento": "12215052708",
    "ExibeDigitoCorreto": false,
    "IgnorarChar": "./-",
    "Name": "",
    "PermiteVazio": false,
    "RaiseExcept": false,
    "Tag": 0,
    "TipoDocto": "docCPF"
}
```


⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃ ⁃
_________________________________________________
Powered By: [postman-to-markdown](https://github.com/bautistaj/postman-to-markdown/)

