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
