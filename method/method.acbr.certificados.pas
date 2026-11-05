
unit method.acbr.certificados;

{$mode Delphi}
{$M+}

interface

uses 
  blcksock,
  synacode,
  fpjson,
  jsonparser,
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

    function ExtractCertificateData(const CertificadoBase64: String; const Senha:
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

{ TACBRBridgeCertificados }

constructor TACBRBridgeCertificados.Create(ACustomCertDir: String = '');
begin
  inherited Create;

  if ACustomCertDir.Trim <> '' then
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
TBytes;
var
  DecodedStr: AnsiString;
begin
  Result := Nil;
  ErrorMessage := '';
  if Base64String.Trim.IsEmpty then
  begin
    ErrorMessage := RSEmptyBase64Error;
    Exit;
  end;

  try
    DecodedStr := synacode.DecodeBase64(AnsiString(Base64String));
    if Length(DecodedStr) = 0 then
    begin
      if Base64String <> '' then
        ErrorMessage := RSZeroBytesAfterDecodeError
      else
        ErrorMessage := RSZeroBytesEmptyStringError;
      Result := Nil;
    end
    else
    begin
      SetLength(Result, Length(DecodedStr));
      Move(DecodedStr[1], Result[0], Length(DecodedStr));
    end;
  except
    on E: Exception do
    begin
      Result := Nil;
      ErrorMessage := RSBase64DecodeError + E.Message;
    end;
  end;
end;

function TACBRBridgeCertificados.InternalValidarCertificado(const
  CertificadoBase64:
  String; const Senha:
  String; out ErrorMsg
  : String): Boolean;

begin
  Result := False;
  ErrorMsg := '';

  if CertificadoBase64 = '' then
  begin
    ErrorMsg := RSEmptyDataError;
    Exit;
  end;

  try
    // Bypassing file disk read to avoid FPC 64-bit Access Violation with OpenSSL
    FACBrDFeSSL.DadosPFX := synacode.DecodeBase64(AnsiString(CertificadoBase64));
    FACBrDFeSSL.Senha := Senha;
    FACBrDFeSSL.CarregarCertificado;
    Result := FACBrDFeSSL.CertNumeroSerie <> '';
    if not Result then
      ErrorMsg := RSValidationFailedError;
  except
    on E: Exception do
    begin
      Result := False;
      ErrorMsg := E.Message;
    end;
  end;
end;

function TACBRBridgeCertificados.ExtractCertificateData(const CertificadoBase64: String; const Senha: String;
  out CNPJ, NumSerie, RazaoSocial, Tipo: String; out Validade: TDateTime): Boolean;
var 
  CertEhA1: Boolean;
begin
  Result := False;
  CNPJ := '';
  NumSerie := '';
  RazaoSocial := '';
  Tipo := '';
  Validade := 0;

  FACBrDFeSSL.DadosPFX := synacode.DecodeBase64(AnsiString(CertificadoBase64));
  FACBrDFeSSL.Senha := Senha;

  try
    FACBrDFeSSL.CarregarCertificado;
    NumSerie    := FACBrDFeSSL.CertNumeroSerie;
    CNPJ        := FACBrDFeSSL.CertCNPJ;
    RazaoSocial := FACBrDFeSSL.CertRazaoSocial;
    Validade    := FACBrDFeSSL.CertDataVenc;
    CertEhA1    := FACBrDFeSSL.CertTipo = tpcA1;

    if CertEhA1 then
      Tipo := RSCertificadoA1
    else
      Tipo := RSCertificadoA3;

    Result := True;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

function TACBRBridgeCertificados.InternalLerDadosCertificado(const CertificadoBase64: String; const Senha: String): TJSONObject;
var 
  sNumSerie, sCNPJ, sRazaoSocial, sTipo: string;
  dtValidade: TDateTime;
begin
  Result := TJSONObject.Create;
  
  if CertificadoBase64 = '' then
  begin
    Result.Add(RSSucessoField, False);
    Result.Add(RSMensagemField, RSEmptyDataError);
    Exit;
  end;

  if ExtractCertificateData(CertificadoBase64, Senha, sCNPJ, sNumSerie, sRazaoSocial, sTipo, dtValidade) then
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

begin
  // 1. Determinar o identificador principal para o nome base
  if not CNPJParam.Trim.IsEmpty then
    IdentificadorPrincipal := CNPJParam.Trim
  else if not CNPJDoCert.Trim.IsEmpty then
    IdentificadorPrincipal := CNPJDoCert.Trim
  else
    IdentificadorPrincipal := '';

  // 2. Determinar o nome base (sem extensão)
  if not NomeArquivoParam.Trim.IsEmpty then
  begin
    NomeBaseSemExt := ChangeFileExt(NomeArquivoParam.Trim, '');
    if IdentificadorPrincipal = '' then
      IdentificadorPrincipal := RSCertificadoDefault;
  end
  else
  begin
    if IdentificadorPrincipal = '' then
      IdentificadorPrincipal := RSCertificadoDefault;
    NomeBaseSemExt := IdentificadorPrincipal;
  end;

  // 3. Adicionar número de série sanitizado, se disponível
  NomeFinalComExt := NomeBaseSemExt;
  if not NumSerieDoCert.Trim.IsEmpty then
  begin
    NumSerieSanitizado := StringReplace(NumSerieDoCert, ' ', '', [rfReplaceAll]);
    NumSerieSanitizado := StringReplace(NumSerieSanitizado, ':', '', [rfReplaceAll]);

    // Adiciona apenas se o número de série já não estiver no nome base (evita duplicar)
    if Pos(UpperCase(NumSerieSanitizado), UpperCase(NomeFinalComExt)) = 0 then
      NomeFinalComExt := NomeFinalComExt + '_' + NumSerieSanitizado;
  end;

  // 4. Adicionar extensão
  NomeFinalComExt := NomeFinalComExt + RSPFXExtension;

  // 5. Garantir unicidade adicionando GUID
  Result := FCertificadosDir + ChangeFileExt(ExtractFileName(NomeFinalComExt),
    '') + '_' +
    TGuid.NewGuid.ToString + RSPFXExtension;

  if FileExists(Result) then
    raise Exception.Create(RSUniqueFileError);
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
  NomeArquivo_Param: String): TJSONObject;

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
    Result.Add(RSSucessoField, False);

    if ValidationErrorMessage <> '' then
      Result.Add(RSMensagemField, ValidationErrorMessage)
    else
      Result.Add(RSMensagemField, RSCertificateInvalidError);

    Exit;
  end;

  try
    DadosCertLidos := InternalLerDadosCertificado(CertificadoBase64, Senha);

    sCNPJdoCert := '';
    sNumSerieDoCert := '';
    sRazaoSocialDoCert := '';
    sValidadeDoCert := '';
    sTipoDoCert := '';

    if DadosCertLidos.Get(RSSucessoField, False) then
    begin
      if DadosCertLidos.Find(RSCNPJField, tempJsonString) then
        sCNPJdoCert := tempJsonString.AsString;
      if DadosCertLidos.Find(RSNumeroSerieField, tempJsonString) then
        sNumSerieDoCert := tempJsonString.AsString;
      if DadosCertLidos.Find(RSRazaoSocialField, tempJsonString) then
        sRazaoSocialDoCert := tempJsonString.AsString;
      if DadosCertLidos.Find(RSValidadeField, tempJsonString) then
        sValidadeDoCert := tempJsonString.AsString;
      if DadosCertLidos.Find(RSTipoField, tempJsonString) then
        sTipoDoCert := tempJsonString.AsString;
    end;

    NomeArquivoFinal := InternalGerarNomeArquivoFinal(CNPJ_Param,
      NomeArquivo_Param, sCNPJdoCert, sNumSerieDoCert);

    DecodedBytes := DecodeBase64ToBytes(CertificadoBase64, DecodeErrorMessage);
    if Length(DecodedBytes) = 0 then
    begin
      Result.Add(RSSucessoField, False);

      if (DecodeErrorMessage <> '') then
        Result.Add(RSMensagemField, DecodeErrorMessage)
      else
        Result.Add(RSMensagemField, RSCertificateDecodeErrorEmpty);

      Exit;
    end;

    CertificadoStream := TBytesStream.Create(DecodedBytes);
    try
      CertificadoStream.SaveToFile(NomeArquivoFinal);

      Result.Add(RSSucessoField, True);
      Result.Add(RSMensagemField, RSCertificateSavedSuccess);
      Result.Add(RSCaminhoCompletoField, NomeArquivoFinal);
      Result.Add(RSNomeArquivoSalvoField, ExtractFileName(NomeArquivoFinal));

      // Adiciona os dados lidos do certificado ao resultado JSON, se a leitura foi bem sucedida
      if DadosCertLidos.Get(RSSucessoField, False) then
      begin
        if sCNPJdoCert <> '' then Result.Add(RSCNPJCertificadoField, sCNPJdoCert);
        if sNumSerieDoCert <> '' then Result.Add(RSNumeroSerieCertificadoField, sNumSerieDoCert);
        if sRazaoSocialDoCert <> '' then Result.Add(RSRazaoSocialCertificadoField, sRazaoSocialDoCert);
        if sValidadeDoCert <> '' then Result.Add(RSValidadeCertificadoField, sValidadeDoCert);
        if sTipoDoCert <> '' then Result.Add(RSTipoCertificadoField, sTipoDoCert);
      end
      else if DadosCertLidos.Find(RSMensagemField, tempJsonString) then
        Result.Add(RSAvisoLeituraDadosField, tempJsonString.AsString)
      else
        Result.Add(RSAvisoLeituraDadosField, RSCertificateMetadataReadError);

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
  Result := InternalLerDadosCertificado(CertificadoBase64, Senha);
end;

end.
