unit resource.strings.msg;

{$mode Delphi}{$H+}

interface

resourcestring
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

implementation

end.