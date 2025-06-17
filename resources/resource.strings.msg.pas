unit resource.strings.msg;


interface

resourcestring
  // Aplicação principal - Mensagens de log
  RSStartingApplication = 'Iniciando a aplicação ACBRWebService...';
  RSInitializingMiddleware = 'Inicializando o middleware...';
  RSJsonMiddlewareInitialized = ' Middleware Json inicializado.';
  RSHandleExceptionMiddlewareInitialized = ' Middleware de tratamento de exceções (HandleException) inicializado.';
  RSInitializingRoutes = 'Inicializando as rotas...';
  RSACBRNFeRoutesMapped = '  Rotas ACBR NFe mapeadas.';
  RSACBRCTeRoutesMapped = '  Rotas ACBR CTe mapeadas.';
  RSACBRMDFeRoutesMapped = '  Rotas ACBR MDFe mapeadas.';
  RSACBRDiversosExtensoRoutesMapped = '  Rotas ACBR Diversos Extenso mapeadas.';
  RSACBRDiversosValidadorRoutesMapped = '  Rotas ACBR Diversos Validador mapeadas.';
  RSACBRCertificadosRoutesMapped = '  Rotas ACBR Certificados mapeadas.';
  RSHorseApplicationStarted = 'Aplicação Horse iniciada com sucesso.';
  RSListeningOnPort = 'Escutando na porta %d';
  RSApplicationStopped = 'Aplicação ACBRWebService finalizada.';

  // Mensagens de erro - JSON
  RSErrorReadingJSON = 'Erro na leitura do objeto JSON: ';
  RSErrorReadingXMLParam = 'Erro na leitura do parâmetro "xml" do JSON: ';
  RSJSONParseError = 'Erro ao analisar o corpo da requisição JSON: ';
  RSInvalidJSONBodyError = 'Corpo da requisição JSON inválido ou vazio.';
  RSNotJSONObjectError = 'O corpo da requisição não é um objeto JSON.';
  RSInvalidJSONBodyMDFe = 'Corpo da requisição JSON inválido: ';

  // Mensagens de erro - XML
  RSInvalidBase64XML = 'A string XML em base64 é inválida: ';
  RSXMLReadError = 'Erro na leitura do XML: ';
  RSXMLReadErrorMDFe = 'Erro na leitura do XML do MDF-e: ';
  RSXMLReadErrorCTe = 'Erro na leitura do XML do CT-e: ';
  RSXMLParamNotFound = 'Parâmetro "xml" (contendo o XML em Base64) não encontrado no JSON.';
  RSXMLParamEmpty = 'O parâmetro "xml" está vazio.';

  // Mensagens de erro - Validação
  RSInvalidUFCode = 'Código de UF inválido.';
  RSPDFGenerationError = 'Falha ao gerar o PDF.';
  RSErrorReadingJSONMDFe = 'Erro na leitura do objeto JSON do MDF-e: ';
  RSErrorReadingJSONCTe = 'Erro na leitura do objeto JSON para CT-e: ';

  // Mensagens de erro - Certificados
  RSEmptyBase64Error = 'A string Base64 fornecida está vazia.';
  RSZeroBytesAfterDecodeError = 'O conteúdo do certificado Base64 resultou em zero bytes após a decodificação, mas a string original não estava vazia.';
  RSZeroBytesEmptyStringError = 'O conteúdo do certificado Base64 resultou em zero bytes (string Base64 vazia).';
  RSBase64DecodeError = 'Falha ao decodificar a string Base64: ';
  RSEmptyDataError = 'O certificado Base64 resultou em dados vazios.';
  RSValidationFailedError = 'Falha na validação do certificado PFX com a senha fornecida (verifique a senha ou a integridade do arquivo).';
  RSCertificadoBase64EmptyError = 'O campo "certificado_base64" não pode ser vazio.';
  RSCertificadoBase64NotFoundError = 'Campo "certificado_base64" não encontrado ou não é do tipo string no corpo da requisição JSON.';
  RSSenhaEmptyError = 'O campo "senha" não pode ser vazio.';
  RSSenhaNotFoundError = 'O campo "senha" não encontrado ou não é do tipo string no corpo da requisição JSON.';
  RSUniqueFileError = 'Não foi possível gerar um nome de arquivo único para o certificado.';
  RSCertificateReadError = 'Não foi possível ler os dados do certificado (verifique a senha ou o formato do arquivo).';
  RSCertificateDecodeError = 'Falha ao decodificar o certificado Base64 ou dados vazios.';
  RSCertificateDecodeErrorEmpty = 'Falha ao decodificar o certificado Base64 ou os dados resultantes estão vazios.';
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
  RSExampleObservation = 'O CNPJ e o nome_arquivo são opcionais. Se o CNPJ não for fornecido, será usado o CNPJ lido do certificado para nomear o arquivo. Se o nome_arquivo não for fornecido, o CNPJ (ou "certificado") será usado como base.';

implementation

end.
