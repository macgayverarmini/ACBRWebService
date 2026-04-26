
unit method.acbr.certificados;

{$mode Delphi}
{$M+}

interface

uses 
  blcksock,
  fpjson,
  jsonparser,
  System.NetEncoding,
  Classes, SysUtils,
  ACBrDFeSSL, ACBrDFe,
  resource.strings.global,
  resource.strings.msg;

type 

  { TACBRBridgeCertificados }

  TACBRBridgeCertificados = class
  private 
    FCertificadosDir: string;
    FACBrDFeSSL: TDFeSSL;
    function DecodeBase64ToBytes(const Base64String: String; out ErrorMessage:
      String): TBytes;

    function DoActualCertificateValidation(const TempPfxFile: String; const
      Senha: String): Boolean;
    function ExtractCertificateData(const TempPfxFile: String; const Senha:
      String;
      out CNPJ, NumSerie, RazaoSocial, Tipo:
      String; out Validade: TDateTime): Boolean;
    function InternalValidarCertificado(const CertificadoBase64: String; const
      Senha: String; out ErrorMsg: String):Boolean;
    function InternalLerDadosCertificado(const CertificadoBase64: String;
      const Senha: String): TJSONObject;
    function InternalGerarNomeArquivoFinal(const CNPJParam: String; const
      NomeArquivoParam: String;
      const CNPJDoCert: String; const
      NumSerieDoCert: String): string;
  public 
    function ModeloUpload: TJSONObject;
    function SalvarCertificado(const CertificadoBase64: String;
      const Senha: String; const CNPJ_Param: String;
      const NomeArquivo_Param: String): TJSONObject;
    function ObterDadosCertificado(const CertificadoBase64: String; const
      Senha: String): TJSONObject;

    constructor Create(ACustomCertDir: String = '');
    destructor Destroy;
      override;
  end;

implementation

uses Math;

{ TACBRBridgeCertificados }

constructor TACBRBridgeCertificados.Create(ACustomCertDir: String = '');
begin
  inherited Create;

  if ACustomCertDir.Trim <> RSEmptyString then
    FCertificadosDir := IncludeTrailingPathDelimiter(ACustomCertDir)
  else
    FCertificadosDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)
      ) + RSCertificadosDir);

  if not DirectoryExists(FCertificadosDir) then
    ForceDirectories(FCertificadosDir);

  FACBrDFeSSL := TDFeSSL.Create;
  FACBrDFeSSL.SSLType    :=  LT_TLSv1_3;
  FACBrDFeSSL.SSLCryptLib   := cryOpenSSL;
  FACBrDFeSSL.SSLHttpLib    := httpOpenSSL;
  FACBrDFeSSL.SSLXmlSignLib := xsLibXml2;
end;

destructor TACBRBridgeCertificados.Destroy;
begin
  FACBrDFeSSL.Free;
  inherited Destroy;
end;

function TACBRBridgeCertificados.DecodeBase64ToBytes(const Base64String: String;
  out ErrorMessage: String):


TBytes
;
begin
  Result := Nil;
  // Initialize result
  ErrorMessage := RSEmptyString;
  if Base64String.Trim.IsEmpty then
  begin
    ErrorMessage := RSEmptyBase64Error;
    Exit;
  end;

  try
    Result := TNetEncoding.Base64.DecodeStringToBytes(Base64String);
    if Length(Result) = 0 then
    begin

      if Base64String <> RSEmptyString then
        ErrorMessage := RSZeroBytesAfterDecodeError
      else
        ErrorMessage := RSZeroBytesEmptyStringError;
      Result := Nil;
    end;
  except
    on E: Exception do
    begin
      Result := Nil;
      ErrorMessage := RSBase64DecodeError + E.Message;
    end;
  end;
end;

function TACBRBridgeCertificados.DoActualCertificateValidation(const TempPfxFile
  : String; const
  Senha: String):


Boolean
;
begin
  Result := False;
  if not FileExists(TempPfxFile) then Exit;
  if TFileStream.Create(TempPfxFile, fmOpenRead).Size = 0 then Exit;


  FACBrDFeSSL.ArquivoPFX := TempPfxFile;
  FACBrDFeSSL.Senha := Senha;
  try
    FACBrDFeSSL.CarregarCertificado;

    Result := FACBrDFeSSL.CertNumeroSerie <> RSEmptyString;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

function TACBRBridgeCertificados.InternalValidarCertificado(const
  CertificadoBase64:
  String; const Senha:
  String; out ErrorMsg
  : String): Boolean;

var 
  TempFileName: string;
  DecodedBytes: TBytes;
  DecodedStream: TBytesStream;
  fs: TFileStream;
begin
  Result := False;
  ErrorMsg := RSEmptyString;
  TempFileName := RSEmptyString;
  DecodedStream := Nil;

  DecodedBytes := DecodeBase64ToBytes(CertificadoBase64, ErrorMsg);
  if Length(DecodedBytes) = 0 then
  begin
    if ErrorMsg = RSEmptyString then ErrorMsg := RSEmptyDataError;
    Exit;
  end;

  try
    DecodedStream := TBytesStream.Create(DecodedBytes);
    TempFileName := FCertificadosDir + RSTempValidaPrefix + FormatDateTime(
      RSDateTimeFormat, Now) + RSPfxExtension;
    DecodedStream.SaveToFile(TempFileName);


    Result := DoActualCertificateValidation(TempFileName, Senha);
    if not Result then
      ErrorMsg := RSValidationFailedError;


  finally
    if Assigned(DecodedStream) then
      DecodedStream.Free;
    if (TempFileName <> RSEmptyString) and FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
end;

function TACBRBridgeCertificados.ExtractCertificateData(const TempPfxFile:
  String; const Senha:
  String;
  out CNPJ, NumSerie,
  RazaoSocial, Tipo:
  String; out Validade:
  TDateTime): Boolean;

var 
  CertEhA1: Boolean;
begin
  Result := False;
  CNPJ := RSEmptyString;
  NumSerie := RSEmptyString;
  RazaoSocial := RSEmptyString;
  Tipo := RSEmptyString;
  Validade := 0;

  FACBrDFeSSL.ArquivoPFX := TempPfxFile;
  FACBrDFeSSL.Senha := Senha;

  try
    NumSerie    := FACBrDFeSSL.CertNumeroSerie;
    CNPJ        := FACBrDFeSSL.CertCNPJ;
    RazaoSocial := FACBrDFeSSL.CertRazaoSocial;
    Validade    := FACBrDFeSSL.CertDataVenc;
    CertEhA1    := FACBrDFeSSL.CertTipo = tpcA1;
    // Assuming tpcA1 is defined in ACBrDFeSSL or related units

    if CertEhA1 then
      Tipo := RSCertificadoA1
    else
      Tipo := RSCertificadoA3;
    // Or other types if distinguishable

    Result := True;
    // Data extraction successful
  except
    on E: Exception do
    begin
      Result := False;
      // Optionally, log E.Message or pass it out
    end;
  end;
end;

function TACBRBridgeCertificados.InternalLerDadosCertificado(const
  CertificadoBase64:
  String; const Senha
  : String):


TJSONObject
;

var 
  TempFileName: string;
  DecodedBytes: TBytes;
  DecodedStream: TBytesStream;
  sNumSerie, sCNPJ, sRazaoSocial, sTipo: string;
  dtValidade: TDateTime;
  ErrorMsg: string;
begin
  Result := TJSONObject.Create;
  DecodedStream := Nil;
  TempFileName := '';
  ErrorMsg := '';

  DecodedBytes := DecodeBase64ToBytes(CertificadoBase64, ErrorMsg);
  if Length(DecodedBytes) = 0 then
  begin
    Result.Add(RSSucessoField, False);

    if ErrorMsg <> RSEmptyString then
      Result.Add(RSMensagemField, ErrorMsg)
    else
      Result.Add(RSMensagemField, RSCertificateDecodeError);
    Exit;
  end;

  try
    DecodedStream := TBytesStream.Create(DecodedBytes);
    TempFileName := FCertificadosDir + RSTempLerDadosPrefix + FormatDateTime(
      RSDateTimeFormat, Now) + RSPfxExtension;
    DecodedStream.SaveToFile(TempFileName);

    if ExtractCertificateData(TempFileName, Senha, sCNPJ, sNumSerie,
      sRazaoSocial, sTipo, dtValidade) then
    begin
      Result.Add(RSSucessoField, True);
      Result.Add(RSNumeroSerieField, sNumSerie);
      Result.Add(RSCNPJField, sCNPJ);
      Result.Add(RSRazaoSocialField, sRazaoSocial);
      Result.Add(RSValidadeField, FormatDateTime(RSDateFormat, dtValidade));
      Result.Add(RSTipoField, sTipo);
    end
    else
    begin
      Result.Add(RSSucessoField, False);
      Result.Add(RSMensagemField, RSCertificateReadError);
    end;

  finally
    if Assigned(DecodedStream) then
      DecodedStream.Free;
    if (TempFileName <> '') and FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
end;


function TACBRBridgeCertificados.InternalGerarNomeArquivoFinal(const CNPJParam:
  String; const
  NomeArquivoParam:
  String;
  const CNPJDoCert:
  String; const
  NumSerieDoCert:
  String): string;

var 
  NomeBaseSemExt: string;
  NomeFinalComExt: string;
  IdentificadorPrincipal: string;
  NumSerieSanitizado: string;
  Attempt: Integer;

begin
  // 1. Determinar o identificador principal para o nome base
  if not CNPJParam.Trim.IsEmpty then
    IdentificadorPrincipal := CNPJParam.Trim
  else if not CNPJDoCert.Trim.IsEmpty then
    IdentificadorPrincipal := CNPJDoCert.Trim
  else
    IdentificadorPrincipal := '';

  // 2. Determinar o nome base (sem extensÃ£o)
  if not NomeArquivoParam.Trim.IsEmpty then
  begin
    NomeBaseSemExt := ChangeFileExt(NomeArquivoParam.Trim, '');


    // Se o nome do arquivo fornecido jÃ¡ contiver o CNPJ e ele for diferente, pode gerar nomes longos.


    // Esta lÃ³gica assume que NomeArquivoParam Ã© um nome desejado, ou o IdentificadorPrincipal Ã© usado.


    // Se IdentificadorPrincipal nÃ£o estiver vazio e NomeArquivoParam nÃ£o o contiver, pode-se prefixar.


    // Por simplicidade, vamos usar NomeArquivoParam se fornecido, senÃ£o o Identificador.
    if IdentificadorPrincipal = '' then IdentificadorPrincipal := 


        'certificado'
    ;
  end
  else
  begin
    if IdentificadorPrincipal = '' then IdentificadorPrincipal := 


        'certificado'
    ;
    NomeBaseSemExt := IdentificadorPrincipal;
  end;


  // 3. Adicionar nÃºmero de sÃ©rie sanitizado, se disponÃ­vel
  NomeFinalComExt := NomeBaseSemExt;
  if not NumSerieDoCert.Trim.IsEmpty then
  begin
    NumSerieSanitizado := StringReplace(NumSerieDoCert, ' ', '', [rfReplaceAll
      ]);
    NumSerieSanitizado := StringReplace(NumSerieSanitizado, ':', '', [
      rfReplaceAll]);


    // Adiciona apenas se o nÃºmero de sÃ©rie jÃ¡ nÃ£o estiver no nome base (evita duplicar)
    if Pos(UpperCase(NumSerieSanitizado), UpperCase(NomeFinalComExt)) = 0 then
      NomeFinalComExt := NomeFinalComExt + '_' + NumSerieSanitizado;
  end;

  // 4. Adicionar extensÃ£o
  NomeFinalComExt := NomeFinalComExt + '.pfx';

  // 5. Adicionar caminho do diretÃ³rio
  Result := FCertificadosDir + ExtractFileName(NomeFinalComExt);
  // ExtractFileName para sanitizar e pegar sÃ³ o nome

  // 6. Garantir unicidade adicionando timestamp se necessÃ¡rio

  Result := FCertificadosDir + ChangeFileExt(ExtractFileName(NomeFinalComExt),
    '') + '_' +
    TGuid.NewGuid.ToString + '.pfx';

  if FileExists(Result) then // Se ainda existir apÃ³s 100 tentativas
    raise Exception.Create(


      'NÃ£o foi possÃ­vel gerar um nome de arquivo Ãºnico para o certificado.'
      );

end;


function TACBRBridgeCertificados.ModeloUpload: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add(RSCertificadoBase64Field, RSExampleBase64String);
  Result.Add(RSSenhaField, RSExamplePassword);
  Result.Add(RSCNPJField, RSExampleCNPJ);
  Result.Add(RSNomeArquivoField, RSExampleFileName);
  Result.Add(RSObservacaoField, RSExampleObservation);
end;

function TACBRBridgeCertificados.SalvarCertificado(const CertificadoBase64:
  String;
  const Senha: String; const
  CNPJ_Param: String; const
  NomeArquivo_Param: String):


TJSONObject
;

var 
  DecodedBytes: TBytes;
  CertificadoStream: TBytesStream;
  DadosCertLidos: TJSONObject;
  sCNPJdoCert, sNumSerieDoCert, sRazaoSocialDoCert,
  sValidadeDoCert, sTipoDoCert: string;
  tempJsonString: TJSONString;
  NomeArquivoFinal: string;
  ValidationErrorMessage: string;
  DecodeErrorMessage: string;
begin
  Result := TJSONObject.Create;
  DadosCertLidos := Nil;
  CertificadoStream := Nil;

  if not DirectoryExists(FCertificadosDir) then
    ForceDirectories(FCertificadosDir);

  if not InternalValidarCertificado(CertificadoBase64, Senha,
    ValidationErrorMessage) then
  begin
    Result.Add('sucesso', False);

    if ValidationErrorMessage <> '' then
      Result.Add('mensagem', ValidationErrorMessage)
    else
      Result.Add('mensagem', 'Certificado invÃ¡lido ou senha incorreta.');

    Exit;
  end;

  try
    DadosCertLidos := InternalLerDadosCertificado(CertificadoBase64, Senha);

    sCNPJdoCert := '';
    sNumSerieDoCert := '';
    sRazaoSocialDoCert := '';
    sValidadeDoCert := '';
    sTipoDoCert := '';

    if DadosCertLidos.Get('sucesso', False) then
    begin
      if DadosCertLidos.Find('cnpj', tempJsonString) then sCNPJdoCert := 


          tempJsonString
          .


          AsString
      ;
      if DadosCertLidos.Find('numero_serie', tempJsonString) then
        sNumSerieDoCert := tempJsonString.AsString;
      if DadosCertLidos.Find('razao_social', tempJsonString) then
        sRazaoSocialDoCert := tempJsonString.AsString;
      if DadosCertLidos.Find('validade', tempJsonString) then sValidadeDoCert 
        := tempJsonString.AsString;
      // JÃ¡ estÃ¡ formatado por InternalLerDadosCertificado
      if DadosCertLidos.Find('tipo', tempJsonString) then sTipoDoCert := 


          tempJsonString
          .


          AsString
      ;
    end
    else
      // Mesmo que a leitura detalhada falhe, a validaÃ§Ã£o bÃ¡sica passou.
      // Podemos prosseguir com o salvamento, mas o nome do arquivo pode ser menos especÃ­fico.
      // A mensagem de erro da leitura jÃ¡ estarÃ¡ em DadosCertLidos.Get('mensagem', '')
      // NÃ£o Ã© crÃ­tico para o salvamento em si, mas para a informaÃ§Ã£o retornada.
    ;

    NomeArquivoFinal := InternalGerarNomeArquivoFinal(CNPJ_Param,
      NomeArquivo_Param, sCNPJdoCert, sNumSerieDoCert);

    DecodedBytes := DecodeBase64ToBytes(CertificadoBase64, DecodeErrorMessage);
    if Length(DecodedBytes) = 0 then
    begin
      Result.Add('sucesso', False);

      if (DecodeErrorMessage <> '') then
        Result.Add('mensagem', DecodeErrorMessage)
      else
        Result.Add('mensagem',


          'Falha ao decodificar certificado Base64 ou dados resultantes vazios.'
          );

      Exit;
    end;

    CertificadoStream := TBytesStream.Create(DecodedBytes);
    try
      CertificadoStream.SaveToFile(NomeArquivoFinal);

      Result.Add('sucesso', True);
      Result.Add('mensagem', 'Certificado salvo com sucesso.');
      Result.Add('caminho_completo', NomeArquivoFinal);
      Result.Add('nome_arquivo_salvo', ExtractFileName(NomeArquivoFinal));


      // Adiciona os dados lidos do certificado ao resultado JSON, se a leitura foi bem sucedida
      if DadosCertLidos.Get('sucesso', False) then
      begin
        if sCNPJdoCert <> '' then Result.Add('cnpj_certificado', sCNPJdoCert);
        if sNumSerieDoCert <> '' then Result.Add('numero_serie_certificado',
            sNumSerieDoCert);
        if sRazaoSocialDoCert <> '' then Result.Add('razao_social_certificado'
            , sRazaoSocialDoCert);
        if sValidadeDoCert <> '' then Result.Add('validade_certificado',
            sValidadeDoCert);
        if sTipoDoCert <> '' then Result.Add('tipo_certificado', sTipoDoCert);
      end
      else
      if DadosCertLidos.Find('mensagem', tempJsonString) then
        Result.Add('aviso_leitura_dados', tempJsonString.AsString)
      else
        Result.Add('aviso_leitura_dados',


          'NÃ£o foi possÃ­vel ler todos os metadados do certificado.'
          )// Adiciona a mensagem de erro da leitura de dados se houver
      ;

    finally
      CertificadoStream.Free;
    end;

  finally
    if Assigned(DadosCertLidos) then
      DadosCertLidos.Free;
  end;
end;

function TACBRBridgeCertificados.ObterDadosCertificado(const CertificadoBase64:
  String; const Senha:
  String): TJSONObject;
begin

  // A validaÃ§Ã£o bÃ¡sica do Base64 (se Ã© decodificÃ¡vel e nÃ£o zero bytes)


  // jÃ¡ Ã© feita dentro de InternalLerDadosCertificado atravÃ©s de DecodeBase64ToBytes.
  Result := InternalLerDadosCertificado(CertificadoBase64, Senha);
end;

end.
