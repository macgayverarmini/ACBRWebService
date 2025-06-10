unit resource.strings.global;

{$mode Delphi}{$H+}

interface

resourcestring
  // Strings básicas
  RSEmptyString = '';
  
  // Separadores e formatação
  RSSeparatorLine = '-------------------------------------------------------';
  RSDateTimeFormat = 'yyyymmddhhnnsszzz';
  RSDateFormat = 'yyyy-mm-dd';
  
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