unit method.acbr.certificados;

{$mode Delphi}

interface

uses
  blcksock,
  fpjson, jsonparser, // Removed jsonconvert, fpjsonrtti as they weren't explicitly used in logic
  System.NetEncoding,
  Classes, SysUtils,
  ACBrDFeSSL, ACBrDFe; // Assuming ACBrDFe provides base types if needed

type

  { TACBRBridgeCertificados }

  TACBRBridgeCertificados = class
  private
    FCertificadosDir: string;
    FACBrDFeSSL: TDFeSSL; // Component for SSL operations and certificate reading

    // Helper to decode Base64, centralizing the call
    function DecodeBase64ToBytes(const Base64String: string; out ErrorMessage: string): TBytes;

    // Internal validation logic using ACBr
    function DoActualCertificateValidation(const TempPfxFile: string; const Senha: string): Boolean;
    function ExtractCertificateData(const TempPfxFile: string; const Senha: string;
      out CNPJ, NumSerie, RazaoSocial, Tipo: string; out Validade: TDateTime): Boolean;

    // Refined internal methods
    function InternalValidarCertificado(const CertificadoBase64: string; const Senha: string; out ErrorMsg: string): Boolean;
    function InternalLerDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;
    function InternalGerarNomeArquivoFinal(const CNPJParam: string; const NomeArquivoParam: string;
                                       const CNPJDoCert: string; const NumSerieDoCert: string): string;
  public
    function ModeloUpload: TJSONObject;
    function SalvarCertificado(const CertificadoBase64: string;
               const Senha: string; const CNPJ_Param: string; const NomeArquivo_Param: string): TJSONObject;
    function ObterDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;

    constructor Create(ACustomCertDir: string = ''); // Allow custom dir or default
    destructor Destroy; override;
  end;

implementation

uses Math; // For Max function if needed, or string utils

{ TACBRBridgeCertificados }

constructor TACBRBridgeCertificados.Create(ACustomCertDir: string = '');
begin
  inherited Create; // Call inherited constructor if TACBRBridgeCertificados descends from a class that has one

  if ACustomCertDir.Trim <> '' then
    FCertificadosDir := IncludeTrailingPathDelimiter(ACustomCertDir)
  else
    FCertificadosDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + 'certificados');

  if not DirectoryExists(FCertificadosDir) then
    ForceDirectories(FCertificadosDir);

  FACBrDFeSSL := TDFeSSL.Create; // Pass nil for owner if no visual component owns it
  // Configure FACBrDFeSSL as needed, these are common defaults
  FACBrDFeSSL.SSLType    :=  LT_TLSv1_3; // Or the appropriate SSL/TLS version
  FACBrDFeSSL.SSLCryptLib   := cryOpenSSL;
  FACBrDFeSSL.SSLHttpLib    := httpOpenSSL;
  FACBrDFeSSL.SSLXmlSignLib := xsLibXml2;
end;

destructor TACBRBridgeCertificados.Destroy;
begin
  FACBrDFeSSL.Free;
  inherited Destroy;
end;

function TACBRBridgeCertificados.DecodeBase64ToBytes(const Base64String: string; out ErrorMessage: string): TBytes;
begin
  Result := nil; // Initialize result
  ErrorMessage := '';
  if Base64String.Trim.IsEmpty then
  begin
    ErrorMessage := 'A string Base64 fornecida está vazia.';
    Exit;
  end;

  try
    Result := TNetEncoding.Base64.DecodeStringToBytes(Base64String);
    if Length(Result) = 0 then
    begin

      if Base64String <> '' then
         ErrorMessage := 'O conteúdo do certificado Base64 resultou em zero bytes após a decodificação, mas a string original não era vazia.'
      else
         ErrorMessage := 'O conteúdo do certificado Base64 resultou em zero bytes (string Base64 vazia).';
      Result := nil;
    end;
  except
    on E: Exception do
    begin
      Result := nil;
      ErrorMessage := 'Falha ao decodificar a string Base64: ' + E.Message;
    end;
  end;
end;

function TACBRBridgeCertificados.DoActualCertificateValidation(const TempPfxFile: string; const Senha: string): Boolean;
begin
  Result := False;
  if not FileExists(TempPfxFile) then Exit;
  if TFileStream.Create(TempPfxFile, fmOpenRead).Size = 0 then Exit;


  FACBrDFeSSL.ArquivoPFX := TempPfxFile;
  FACBrDFeSSL.Senha := Senha;
  try
     FACBrDFeSSL.CarregarCertificado;

    Result := FACBrDFeSSL.CertNumeroSerie <> '';
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

function TACBRBridgeCertificados.InternalValidarCertificado(const CertificadoBase64: string; const Senha: string; out ErrorMsg: string): Boolean;
var
  TempFileName: string;
  DecodedBytes: TBytes;
  DecodedStream: TBytesStream;
  fs: TFileStream;
begin
  Result := False;
  ErrorMsg := '';
  TempFileName := '';
  DecodedStream := nil;

  DecodedBytes := DecodeBase64ToBytes(CertificadoBase64, ErrorMsg);
  if Length(DecodedBytes) = 0 then
  begin
    if ErrorMsg = '' then ErrorMsg := 'Certificado Base64 resultou em dados vazios.';
    Exit;
  end;

  try
    DecodedStream := TBytesStream.Create(DecodedBytes);
    TempFileName := FCertificadosDir + 'temp_valida_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.pfx';
    DecodedStream.SaveToFile(TempFileName);


    Result := DoActualCertificateValidation(TempFileName, Senha);
    if not Result then
      ErrorMsg := 'Falha na validação do certificado PFX com a senha fornecida (verifique senha ou integridade do arquivo).';


  finally
    if Assigned(DecodedStream) then
      DecodedStream.Free;
    if (TempFileName <> '') and FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
end;

function TACBRBridgeCertificados.ExtractCertificateData(const TempPfxFile: string; const Senha: string;
  out CNPJ, NumSerie, RazaoSocial, Tipo: string; out Validade: TDateTime): Boolean;
var
  CertEhA1: Boolean;
begin
  Result := False;
  CNPJ := ''; NumSerie := ''; RazaoSocial := ''; Tipo := ''; Validade := 0;

  FACBrDFeSSL.ArquivoPFX := TempPfxFile;
  FACBrDFeSSL.Senha := Senha;

  try
    NumSerie    := FACBrDFeSSL.CertNumeroSerie;
    CNPJ        := FACBrDFeSSL.CertCNPJ;
    RazaoSocial := FACBrDFeSSL.CertRazaoSocial;
    Validade    := FACBrDFeSSL.CertDataVenc;
    CertEhA1    := FACBrDFeSSL.CertTipo = tpcA1; // Assuming tpcA1 is defined in ACBrDFeSSL or related units

    if CertEhA1 then
      Tipo := 'A1'
    else
      Tipo := 'A3'; // Or other types if distinguishable

    Result := True; // Data extraction successful
  except
    on E: Exception do
    begin
      Result := False;
      // Optionally, log E.Message or pass it out
    end;
  end;
end;

function TACBRBridgeCertificados.InternalLerDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;
var
  TempFileName: string;
  DecodedBytes: TBytes;
  DecodedStream: TBytesStream;
  sNumSerie, sCNPJ, sRazaoSocial, sTipo: string;
  dtValidade: TDateTime;
  ErrorMsg: string;
begin
  Result := TJSONObject.Create;
  DecodedStream := nil;
  TempFileName := '';
  ErrorMsg := '';

  DecodedBytes := DecodeBase64ToBytes(CertificadoBase64, ErrorMsg);
  if Length(DecodedBytes) = 0 then
  begin
    Result.Add('sucesso', False);

    if ErrorMsg <> '' then
        Result.Add('mensagem', ErrorMsg)
    else
      Result.Add('mensagem',  'Falha ao decodificar certificado Base64 ou dados vazios.');
    Exit;
  end;

  try
    DecodedStream := TBytesStream.Create(DecodedBytes);
    TempFileName := FCertificadosDir + 'temp_lerdados_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.pfx';
    DecodedStream.SaveToFile(TempFileName);

    if ExtractCertificateData(TempFileName, Senha, sCNPJ, sNumSerie, sRazaoSocial, sTipo, dtValidade) then
    begin
      Result.Add('sucesso', True);
      Result.Add('numero_serie', sNumSerie);
      Result.Add('cnpj', sCNPJ);
      Result.Add('razao_social', sRazaoSocial);
      Result.Add('validade', FormatDateTime('yyyy-mm-dd', dtValidade));
      Result.Add('tipo', sTipo);
    end
    else
    begin
      Result.Add('sucesso', False);
      Result.Add('mensagem', 'Não foi possível ler os dados do certificado (verifique senha ou formato do arquivo).');
    end;

  finally
    if Assigned(DecodedStream) then
      DecodedStream.Free;
    if (TempFileName <> '') and FileExists(TempFileName) then
      DeleteFile(TempFileName);
  end;
end;


function TACBRBridgeCertificados.InternalGerarNomeArquivoFinal(const CNPJParam: string; const NomeArquivoParam: string;
                                                       const CNPJDoCert: string; const NumSerieDoCert: string): string;
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

  // 2. Determinar o nome base (sem extensão)
  if not NomeArquivoParam.Trim.IsEmpty then
  begin
    NomeBaseSemExt := ChangeFileExt(NomeArquivoParam.Trim, '');
    // Se o nome do arquivo fornecido já contiver o CNPJ e ele for diferente, pode gerar nomes longos.
    // Esta lógica assume que NomeArquivoParam é um nome desejado, ou o IdentificadorPrincipal é usado.
    // Se IdentificadorPrincipal não estiver vazio e NomeArquivoParam não o contiver, pode-se prefixar.
    // Por simplicidade, vamos usar NomeArquivoParam se fornecido, senão o Identificador.
    if IdentificadorPrincipal = '' then IdentificadorPrincipal := 'certificado';
  end
  else
  begin
     if IdentificadorPrincipal = '' then IdentificadorPrincipal := 'certificado';
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
  NomeFinalComExt := NomeFinalComExt + '.pfx';

  // 5. Adicionar caminho do diretório
  Result := FCertificadosDir + ExtractFileName(NomeFinalComExt); // ExtractFileName para sanitizar e pegar só o nome

  // 6. Garantir unicidade adicionando timestamp se necessário

    Result := FCertificadosDir + ChangeFileExt(ExtractFileName(NomeFinalComExt), '') + '_' +
              TGuid.NewGuid.ToString + '.pfx';

  if FileExists(Result) then // Se ainda existir após 100 tentativas
     raise Exception.Create('Não foi possível gerar um nome de arquivo único para o certificado.');

end;


function TACBRBridgeCertificados.ModeloUpload: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('certificado_base64', 'string_base64_do_arquivo_pfx_aqui');
  Result.Add('senha', 'senha_do_certificado_aqui');
  Result.Add('cnpj', '00000000000000');
  Result.Add('nome_arquivo', 'nome_sugerido_para_o_arquivo_pfx_sem_extensao');
  Result.Add('observacao', 'O CNPJ e nome_arquivo são opcionais. Se o CNPJ não for fornecido, será usado o CNPJ lido do certificado para nomear o arquivo. Se nome_arquivo não for fornecido, o CNPJ (ou "certificado") será usado como base.');
end;

function TACBRBridgeCertificados.SalvarCertificado(const CertificadoBase64: string;
  const Senha: string; const CNPJ_Param: string; const NomeArquivo_Param: string): TJSONObject;
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
  DadosCertLidos := nil;
  CertificadoStream := nil;

  if not DirectoryExists(FCertificadosDir) then
    ForceDirectories(FCertificadosDir);

  if not InternalValidarCertificado(CertificadoBase64, Senha, ValidationErrorMessage) then
  begin
    Result.Add('sucesso', False);

    if ValidationErrorMessage <> '' then
       Result.Add('mensagem', ValidationErrorMessage)
    else
       Result.Add('mensagem', 'Certificado inválido ou senha incorreta.');

    Exit;
  end;

  try
    DadosCertLidos := InternalLerDadosCertificado(CertificadoBase64, Senha);

    sCNPJdoCert := ''; sNumSerieDoCert := ''; sRazaoSocialDoCert := '';
    sValidadeDoCert := ''; sTipoDoCert := '';

    if DadosCertLidos.Get('sucesso', False) then
    begin
      if DadosCertLidos.Find('cnpj', tempJsonString) then sCNPJdoCert := tempJsonString.AsString;
      if DadosCertLidos.Find('numero_serie', tempJsonString) then sNumSerieDoCert := tempJsonString.AsString;
      if DadosCertLidos.Find('razao_social', tempJsonString) then sRazaoSocialDoCert := tempJsonString.AsString;
      if DadosCertLidos.Find('validade', tempJsonString) then sValidadeDoCert := tempJsonString.AsString; // Já está formatado por InternalLerDadosCertificado
      if DadosCertLidos.Find('tipo', tempJsonString) then sTipoDoCert := tempJsonString.AsString;
    end
    else
    begin
      // Mesmo que a leitura detalhada falhe, a validação básica passou.
      // Podemos prosseguir com o salvamento, mas o nome do arquivo pode ser menos específico.
      // A mensagem de erro da leitura já estará em DadosCertLidos.Get('mensagem', '')
      // Não é crítico para o salvamento em si, mas para a informação retornada.
    end;

    NomeArquivoFinal := InternalGerarNomeArquivoFinal(CNPJ_Param, NomeArquivo_Param, sCNPJdoCert, sNumSerieDoCert);

    DecodedBytes := DecodeBase64ToBytes(CertificadoBase64, DecodeErrorMessage);
    if Length(DecodedBytes) = 0 then
    begin
      Result.Add('sucesso', False);

      if (DecodeErrorMessage <> '') then
          Result.Add('mensagem', DecodeErrorMessage)
      else
          Result.Add('mensagem', 'Falha ao decodificar certificado Base64 ou dados resultantes vazios.');

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
        if sNumSerieDoCert <> '' then Result.Add('numero_serie_certificado', sNumSerieDoCert);
        if sRazaoSocialDoCert <> '' then Result.Add('razao_social_certificado', sRazaoSocialDoCert);
        if sValidadeDoCert <> '' then Result.Add('validade_certificado', sValidadeDoCert);
        if sTipoDoCert <> '' then Result.Add('tipo_certificado', sTipoDoCert);
      end
      else
      begin
         // Adiciona a mensagem de erro da leitura de dados se houver
         if DadosCertLidos.Find('mensagem', tempJsonString) then
            Result.Add('aviso_leitura_dados', tempJsonString.AsString)
         else
            Result.Add('aviso_leitura_dados', 'Não foi possível ler todos os metadados do certificado.');
      end;

    finally
      CertificadoStream.Free;
    end;

  finally
    if Assigned(DadosCertLidos) then
      DadosCertLidos.Free;
  end;
end;

function TACBRBridgeCertificados.ObterDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;
begin
  // A validação básica do Base64 (se é decodificável e não zero bytes)
  // já é feita dentro de InternalLerDadosCertificado através de DecodeBase64ToBytes.
  Result := InternalLerDadosCertificado(CertificadoBase64, Senha);
end;

end.

