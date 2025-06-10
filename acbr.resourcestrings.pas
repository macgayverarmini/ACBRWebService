unit acbr.resourcestrings;

{$mode Delphi}{$H+}

interface

resourcestring
  // Strings básicas
  RSEmptyString = '';
  
  // Separadores e formatação
  RSSeparatorLine = '-------------------------------------------------------';
  RSDateTimeFormat = 'yyyymmddhhnnsszzz';
  RSDateFormat = 'yyyy-mm-dd';
  
  // Aplicação principal - Mensagens de log
  RSStartingApplication = 'Starting ACBRWebService application...';
  RSInitializingMiddleware = 'Initializing middleware...';
  RSJsonMiddlewareInitialized = ' Json middleware initialized.';
  RSHandleExceptionMiddlewareInitialized = ' HandleException middleware initialized.';
  RSInitializingRoutes = 'Initializing routes...';
  RSACBRNFeRoutesMapped = '  ACBR NFe routes mapped.';
  RSACBRCTeRoutesMapped = '  ACBR CTe routes mapped.';
  RSACBRMDFeRoutesMapped = '  ACBR MDFe routes mapped.';
  RSACBRDiversosExtensoRoutesMapped = '  ACBR Diversos Extenso routes mapped.';
  RSACBRDiversosValidadorRoutesMapped = '  ACBR Diversos Validador routes mapped.';
  RSACBRCertificadosRoutesMapped = '  ACBR Certificados routes mapped.';
  RSHorseApplicationStarted = 'Horse application successfully started.';
  RSListeningOnPort = 'Listening on port %d';
  RSApplicationStopped = 'ACBRWebService application stopped.';
  
  // Configurações padrão
  RSDefaultUF = 'ES';
  RSDefaultCertPath = 'C:\NFMonitor\src\exemplo.pfx';
  RSDefaultCertPassword = '123';
  RSCertificadosDir = 'certificados';
  RSCertificadoDefault = 'certificado';
  
  // Campos JSON comuns
  RSConfigField = 'config';
  RSEventosField = 'eventos';
  RSXMLField = 'XML';
  RSXMLOriginalField = 'XMLOriginal';
  RSNomeArqField = 'NomeArq';
  RSErroValidacaoCompletoField = 'ErroValidacaoCompleto';
  RSErroValidacaoField = 'ErroValidacao';
  RSErroRegrasdeNegociosField = 'ErroRegrasdeNegocios';
  RSAlertasField = 'Alertas';
  RSStatusField = 'status';
  RSMessageField = 'message';
  RSErrorField = 'error';
  RSPDFField = 'pdf';
  RSChaveField = 'chave';
  RSTamanhoField = 'tamanho';
  RSIDField = 'id';
  RSInfEventoField = 'InfEvento';
  RSLoadXMLField = 'LoadXML';
  RSUFField = 'UF';
  RSCNPJCPFField = 'CNPJCPF';
  RSUltNSUField = 'ultNSU';
  RSNSUField = 'NSU';
  RSChNFeField = 'chNFe';
  RSChCTeField = 'chCTe';
  RSChMDFeField = 'chMDFe';
  
  // Status e valores
  RSStatusErro = 'erro';
  RSCertificadoA1 = 'A1';
  RSCertificadoA3 = 'A3';
  
  // Campos específicos de certificados
  RSCertificadoBase64Field = 'certificado_base64';
  RSSenhaField = 'senha';
  RSCNPJField = 'cnpj';
  RSNomeArquivoField = 'nome_arquivo';
  RSObservacaoField = 'observacao';
  RSSucessoField = 'sucesso';
  RSMensagemField = 'mensagem';
  RSNumeroSerieField = 'numero_serie';
  RSRazaoSocialField = 'razao_social';
  RSValidadeField = 'validade';
  RSTipoField = 'tipo';
  RSCaminhoCompletoField = 'caminho_completo';
  RSNomeArquivoSalvoField = 'nome_arquivo_salvo';
  RSCNPJCertificadoField = 'cnpj_certificado';
  RSNumeroSerieCertificadoField = 'numero_serie_certificado';
  RSRazaoSocialCertificadoField = 'razao_social_certificado';
  RSValidadeCertificadoField = 'validade_certificado';
  RSTipoCertificadoField = 'tipo_certificado';
  RSAvisoLeituraDadosField = 'aviso_leitura_dados';
  
  // Prefixos de arquivos temporários
  RSTempValidaPrefix = 'temp_valida_';
  RSTempLerDadosPrefix = 'temp_lerdados_';
  RSPfxExtension = '.pfx';
  
  // Rotas - NFe
  RSModeloNFeConfigRoute = '/modelo/nfe/config';
  RSModeloNFeEventoRoute = '/modelo/nfe/evento';
  RSModeloNFeDistribuicaoRoute = '/modelo/nfe/distribuicao';
  RSModeloNFeNFeRoute = '/modelo/nfe/nfe';
  RSNFeEventosRoute = '/nfe/eventos';
  RSNFeDistribuicaoRoute = '/nfe/distribuicao';
  RSNFeDANFeRoute = '/nfe/danfe';
  RSNFeNFeRoute = '/nfe/nfe';
  
  // Rotas - CTe
  RSModeloCTeConfigRoute = '/modelo/cte/config';
  RSModeloCTeEventoRoute = '/modelo/cte/evento';
  RSModeloCTeDistribuicaoRoute = '/modelo/cte/distribuicao';
  RSModeloCTeCTeRoute = '/modelo/cte/cte';
  RSCTeEventosRoute = '/cte/eventos';
  RSCTeDistribuicaoRoute = '/cte/distribuicao';
  RSCTeDANFeRoute = '/cte/danfe';
  RSCTeNFeRoute = '/cte/nfe';
  
  // Rotas - MDFe
  RSModeloMDFeConfigRoute = '/modelo/mdfe/config';
  RSModeloMDFeEventoRoute = '/modelo/mdfe/evento';
  RSModeloMDFeMDFeRoute = '/modelo/mdfe/mdfe';
  RSModeloMDFeDistribuicaoRoute = '/modelo/mdfe/distribuicao';
  RSMDFeEnviarRoute = '/mdfe/enviar';
  RSMDFeEventosRoute = '/mdfe/eventos';
  RSMDFeDAMDFeRoute = '/mdfe/damdfe';
  RSMDFeDistribuicaoRoute = '/mdfe/distribuicao';
  
  // Rotas - Certificados
  RSCertificadosUploadRoute = '/certificados/upload';
  RSCertificadosLerDadosRoute = '/certificados/ler-dados';
  
  // Rotas - Diversos
  RSModeloDiversosValidadorRoute = '/modelo/diversos/validador';
  RSDiversosValidadorRoute = '/diversos/validador';
  RSModeloDiversosExtensoRoute = '/modelo/diversos/extenso';
  RSDiversosExtensoRoute = '/diversos/extenso';
  
  // Mensagens de erro - JSON
  RSErrorReadingJSON = 'Erro na leitura do objeto JSON: ';
  RSErrorReadingXMLParam = 'Erro na leitura do parâmetro "xml" do JSON: ';
  RSJSONParseError = 'Erro ao parsear o corpo da requisição JSON: ';
  RSInvalidJSONBodyError = 'Corpo da requisição JSON inválido ou vazio.';
  RSNotJSONObjectError = 'O corpo da requisição não é um objeto JSON.';
  RSInvalidJSONBodyMDFe = 'Corpo da requisição JSON inválido: ';
  
  // Mensagens de erro - XML
  RSInvalidBase64XML = 'A string XML em base64 é inválida: ';
  RSXMLReadError = 'Erro na leitura do XML: ';
  RSXMLReadErrorMDFe = 'Erro na leitura do XML do MDF-e: ';
  RSXMLReadErrorCTe = 'Erro na leitura do XML: ';
  RSXMLParamNotFound = 'Parâmetro "xml" (contendo o XML em Base64) não encontrado no JSON.';
  RSXMLParamEmpty = 'Parâmetro "xml" está vazio.';
  
  // Mensagens de erro - Validação
  RSInvalidUFCode = 'Código de UF inválido';
  RSPDFGenerationError = 'Falha ao gerar o PDF.';
  RSErrorReadingJSONMDFe = 'Erro na leitura do objeto JSON do MDF-e: ';
  RSErrorReadingJSONCTe = 'Erro na leitura do objeto JSON para CTe: ';
  
  // Mensagens de erro - Certificados
  RSEmptyBase64Error = 'A string Base64 fornecida está vazia.';
  RSZeroBytesAfterDecodeError = 'O conteúdo do certificado Base64 resultou em zero bytes após a decodificação, mas a string original não era vazia.';
  RSZeroBytesEmptyStringError = 'O conteúdo do certificado Base64 resultou em zero bytes (string Base64 vazia).';
  RSBase64DecodeError = 'Falha ao decodificar a string Base64: ';
  RSEmptyDataError = 'Certificado Base64 resultou em dados vazios.';
  RSValidationFailedError = 'Falha na validação do certificado PFX com a senha fornecida (verifique senha ou integridade do arquivo).';
  RSCertificadoBase64EmptyError = 'Campo "certificado_base64" não pode ser vazio.';
  RSCertificadoBase64NotFoundError = 'Campo "certificado_base64" não encontrado ou não é do tipo string no corpo da requisição JSON.';
  RSSenhaEmptyError = 'Campo "senha" não pode ser vazio.';
  RSSenhaNotFoundError = 'Campo "senha" não encontrado ou não é do tipo string no corpo da requisição JSON.';
  RSUniqueFileError = 'Não foi possível gerar um nome de arquivo único para o certificado.';
  RSCertificateReadError = 'Não foi possível ler os dados do certificado (verifique senha ou formato do arquivo).';
  RSCertificateDecodeError = 'Falha ao decodificar certificado Base64 ou dados vazios.';
  RSCertificateDecodeErrorEmpty = 'Falha ao decodificar certificado Base64 ou dados resultantes vazios.';
  RSCertificateInvalidError = 'Certificado inválido ou senha incorreta.';
  RSCertificateSavedSuccess = 'Certificado salvo com sucesso.';
  RSCertificateMetadataReadError = 'Não foi possível ler todos os metadados do certificado.';
  
  // Mensagens de sucesso
  RSOperationSuccess = 'Operação realizada com sucesso.';
  
  // Valores de exemplo para modelos
  RSExampleBase64String = 'string_base64_do_arquivo_pfx_aqui';
  RSExamplePassword = 'senha_do_certificado_aqui';
  RSExampleCNPJ = '00000000000000';
  RSExampleFileName = 'nome_sugerido_para_o_arquivo_pfx_sem_extensao';
  RSExampleObservation = 'O CNPJ e nome_arquivo são opcionais. Se o CNPJ não for fornecido, será usado o CNPJ lido do certificado para nomear o arquivo. Se nome_arquivo não for fornecido, o CNPJ (ou "certificado") será usado como base.';
  
  // Códigos IBGE para UF
  RSCodigoIBGE_AC = '12';
  RSCodigoIBGE_AL = '17';
  RSCodigoIBGE_AP = '16';
  RSCodigoIBGE_AM = '13';
  RSCodigoIBGE_BA = '29';
  RSCodigoIBGE_CE = '23';
  RSCodigoIBGE_DF = '53';
  RSCodigoIBGE_ES = '32';
  RSCodigoIBGE_GO = '52';
  RSCodigoIBGE_MA = '21';
  RSCodigoIBGE_MT = '51';
  RSCodigoIBGE_MS = '50';
  RSCodigoIBGE_MG = '31';
  RSCodigoIBGE_PA = '15';
  RSCodigoIBGE_PB = '25';
  RSCodigoIBGE_PR = '41';
  RSCodigoIBGE_PE = '26';
  RSCodigoIBGE_PI = '22';
  RSCodigoIBGE_RJ = '33';
  RSCodigoIBGE_RN = '24';
  RSCodigoIBGE_RS = '43';
  RSCodigoIBGE_RO = '11';
  RSCodigoIBGE_RR = '14';
  RSCodigoIBGE_SC = '42';
  RSCodigoIBGE_SP = '35';
  RSCodigoIBGE_SE = '28';
  RSCodigoIBGE_TO = '27';

implementation

end.