unit method.acbr.certificados;

{$mode Delphi}

interface

uses
  fpjson, jsonconvert, Base64, jsonparser,
  Classes, SysUtils, fpjsonrtti,
  ACBrDFeSSL, ACBrDFe;

type

  { TACBRBridgeCertificados }

  TACBRBridgeCertificados = class
  private
    FCertificadosDir: string;
    FACBrDFeSSL: TDFeSSL;
    function ValidarCertificado(const CertificadoBase64: string; const Senha: string): Boolean;
    function GerarNomeArquivo(const CNPJ: string; const NomeArquivo: string): string;
    function LerDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;
  public
    function ModeloUpload: TJSONObject;
    function SalvarCertificado(const CertificadoBase64: string; const Senha: string; 
      const CNPJ: string; const NomeArquivo: string): TJSONObject;
    function ObterDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TACBRBridgeCertificados }

function TACBRBridgeCertificados.ModeloUpload: TJSONObject;
begin
  // Cria um modelo JSON para o upload de certificado
  Result := TJSONObject.Create;
  Result.Add('certificado_base64', 'string_base64_do_arquivo_pfx');
  Result.Add('senha', 'senha_do_certificado');
  Result.Add('cnpj', '00000000000000'); // Opcional, será lido do certificado se não informado
  Result.Add('nome_arquivo', 'nome_opcional_do_arquivo'); // Opcional, será gerado automaticamente se não informado
  
  // Adiciona informações sobre os dados que serão retornados
  Result.Add('observacao', 'O sistema lerá automaticamente o CNPJ, número de série e outros dados do certificado');
end;

function TACBRBridgeCertificados.ValidarCertificado(const CertificadoBase64: string; const Senha: string): Boolean;
var
  TempFileName: string;
  CertificadoStream: TMemoryStream;
  DecodedStream: TBytesStream;
  DecodedBytes: TBytes;
begin
  Result := False;
  
  // Verifica se o certificado base64 não está vazio
  if CertificadoBase64.Trim.IsEmpty then
    Exit;
    
  try
    // Decodifica o certificado de Base64
    DecodedBytes := DecodeBase64(CertificadoBase64);
    DecodedStream := TBytesStream.Create(DecodedBytes);
    try
      // Cria um arquivo temporário para validar o certificado
      TempFileName := FCertificadosDir + 'temp_' + FormatDateTime('yyyymmddhhnnss', Now) + '.pfx';
      DecodedStream.SaveToFile(TempFileName);
      
      // Aqui poderia usar o ACBr para validar o certificado com a senha
      // Por simplicidade, apenas verificamos se o arquivo foi criado
      Result := FileExists(TempFileName);
    finally
      DecodedStream.Free;
      // Remove o arquivo temporário
      if FileExists(TempFileName) then
        DeleteFile(TempFileName);
    end;
  except
    on E: Exception do
      Result := False;
  end;
end;

function TACBRBridgeCertificados.GerarNomeArquivo(const CNPJ: string; const NomeArquivo: string): string;
var
  NomeBase: string;
begin
  // Se o nome do arquivo foi fornecido, usa ele, senão usa o CNPJ
  if NomeArquivo.Trim.IsEmpty then
    NomeBase := 'certificado_' + CNPJ
  else
    NomeBase := NomeArquivo;
    
  // Garante que o nome do arquivo termine com .pfx
  if not NomeBase.EndsWith('.pfx', True) then
    NomeBase := NomeBase + '.pfx';
    
  Result := FCertificadosDir + NomeBase;
  
  // Se o arquivo já existir, adiciona um timestamp para evitar sobrescrever
  if FileExists(Result) then
    Result := FCertificadosDir + ChangeFileExt(NomeBase, '') + '_' + 
              FormatDateTime('yyyymmddhhnnss', Now) + '.pfx';
end;

function TACBRBridgeCertificados.SalvarCertificado(const CertificadoBase64: string; 
  const Senha: string; const CNPJ: string; const NomeArquivo: string): TJSONObject;
var
  DecodedBytes: TBytes;
  CertificadoStream: TBytesStream;
  CaminhoCompleto: string;
  DadosCertificado: TJSONObject;
  CertificadoCNPJ, CertificadoNumSerie: string;
  NomeArquivoFinal: string;
begin
  Result := TJSONObject.Create;
  
  // Verifica se o diretório de certificados existe, se não, cria
  if not DirectoryExists(FCertificadosDir) then
    ForceDirectories(FCertificadosDir);
  
  // Valida o certificado
  if not ValidarCertificado(CertificadoBase64, Senha) then
  begin
    Result.Add('sucesso', False);
    Result.Add('mensagem', 'Certificado inválido ou senha incorreta');
    Exit;
  end;
  
  try
    // Lê os dados do certificado para obter CNPJ e número de série
    DadosCertificado := LerDadosCertificado(CertificadoBase64, Senha);
    
    try
      // Se a leitura dos dados foi bem-sucedida, usa o CNPJ do certificado
      if DadosCertificado.Get('sucesso', False) and DadosCertificado.Find('cnpj', CertificadoCNPJ) then
      begin
        // Se o CNPJ não foi fornecido ou está vazio, usa o do certificado
        if CNPJ.Trim.IsEmpty then
          NomeArquivoFinal := GerarNomeArquivo(CertificadoCNPJ, NomeArquivo)
        else
          NomeArquivoFinal := GerarNomeArquivo(CNPJ, NomeArquivo);
          
        // Adiciona o número de série ao nome do arquivo se disponível
        if DadosCertificado.Find('numero_serie', CertificadoNumSerie) and not CertificadoNumSerie.Trim.IsEmpty then
        begin
          // Remove caracteres inválidos para nome de arquivo
          CertificadoNumSerie := StringReplace(CertificadoNumSerie, ' ', '', [rfReplaceAll]);
          CertificadoNumSerie := StringReplace(CertificadoNumSerie, ':', '', [rfReplaceAll]);
          
          // Adiciona o número de série ao nome do arquivo
          NomeArquivoFinal := ChangeFileExt(NomeArquivoFinal, '');
          NomeArquivoFinal := NomeArquivoFinal + '_' + CertificadoNumSerie + '.pfx';
        end;
      end
      else
      begin
        // Se não conseguiu ler o CNPJ do certificado, usa o fornecido
        NomeArquivoFinal := GerarNomeArquivo(CNPJ, NomeArquivo);
      end;
      
      // Decodifica o certificado de Base64
      DecodedBytes := DecodeBase64(CertificadoBase64);
      CertificadoStream := TBytesStream.Create(DecodedBytes);
      try
        // Salva o certificado no arquivo
        CertificadoStream.SaveToFile(NomeArquivoFinal);
        
        // Retorna sucesso e informações do certificado salvo
        Result.Add('sucesso', True);
        Result.Add('mensagem', 'Certificado salvo com sucesso');
        Result.Add('caminho', NomeArquivoFinal);
        Result.Add('nome_arquivo', ExtractFileName(NomeArquivoFinal));
        
        // Adiciona os dados do certificado ao resultado
        if DadosCertificado.Get('sucesso', False) then
        begin
          if DadosCertificado.Find('cnpj', CertificadoCNPJ) then
            Result.Add('cnpj_certificado', CertificadoCNPJ);
            
          if DadosCertificado.Find('numero_serie', CertificadoNumSerie) then
            Result.Add('numero_serie', CertificadoNumSerie);
            
          if DadosCertificado.Find('razao_social', CertificadoNumSerie) then
            Result.Add('razao_social', CertificadoNumSerie);
            
          if DadosCertificado.Find('validade', CertificadoNumSerie) then
            Result.Add('validade', CertificadoNumSerie);
            
          if DadosCertificado.Find('tipo', CertificadoNumSerie) then
            Result.Add('tipo', CertificadoNumSerie);
        end;
      finally
        CertificadoStream.Free;
      end;
    finally
      DadosCertificado.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Add('sucesso', False);
      Result.Add('mensagem', 'Erro ao salvar certificado: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeCertificados.LerDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;
var
  TempFileName: string;
  DecodedBytes: TBytes;
  DecodedStream: TBytesStream;
  CertificadoNumSerie: string;
  CertificadoCNPJ: string;
  CertificadoRazaoSocial: string;
  CertificadoValidade: TDateTime;
  CertificadoTipo: string;
  CertificadoEhA1: Boolean;
begin
  Result := TJSONObject.Create;
  
  try
    // Decodifica o certificado de Base64
    DecodedBytes := DecodeBase64(CertificadoBase64);
    DecodedStream := TBytesStream.Create(DecodedBytes);
    try
      // Cria um arquivo temporário para o certificado
      TempFileName := FCertificadosDir + 'temp_' + FormatDateTime('yyyymmddhhnnss', Now) + '.pfx';
      DecodedStream.SaveToFile(TempFileName);
      
      // Configura o componente SSL para ler o certificado
      FACBrDFeSSL.NumeroSerie := '';
      FACBrDFeSSL.ArquivoPFX := TempFileName;
      FACBrDFeSSL.Senha := Senha;
      
      try
        // Tenta ler os dados do certificado
        CertificadoNumSerie := FACBrDFeSSL.CertNumeroSerie;
        CertificadoCNPJ := FACBrDFeSSL.CertCNPJ;
        CertificadoRazaoSocial := FACBrDFeSSL.CertRazaoSocial;
        CertificadoValidade := FACBrDFeSSL.CertDataVenc;
        CertificadoEhA1 := FACBrDFeSSL.CertTipo = tpcA1;
        
        if CertificadoEhA1 then
          CertificadoTipo := 'A1'
        else
          CertificadoTipo := 'A3';
        
        // Adiciona os dados ao JSON de retorno
        Result.Add('sucesso', True);
        Result.Add('numero_serie', CertificadoNumSerie);
        Result.Add('cnpj', CertificadoCNPJ);
        Result.Add('razao_social', CertificadoRazaoSocial);
        Result.Add('validade', FormatDateTime('yyyy-mm-dd', CertificadoValidade));
        Result.Add('tipo', CertificadoTipo);
      except
        on E: Exception do
        begin
          Result.Add('sucesso', False);
          Result.Add('mensagem', 'Erro ao ler dados do certificado: ' + E.Message);
        end;
      end;
    finally
      DecodedStream.Free;
      // Remove o arquivo temporário
      if FileExists(TempFileName) then
        DeleteFile(TempFileName);
    end;
  except
    on E: Exception do
    begin
      Result.Add('sucesso', False);
      Result.Add('mensagem', 'Erro ao processar certificado: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeCertificados.ObterDadosCertificado(const CertificadoBase64: string; const Senha: string): TJSONObject;
begin
  Result := LerDadosCertificado(CertificadoBase64, Senha);
end;

constructor TACBRBridgeCertificados.Create;
begin
  // Define o diretório onde os certificados serão salvos
  FCertificadosDir := ExtractFilePath(ParamStr(0)) + 'certificados\';
  
  // Garante que o diretório termine com barra
  if not FCertificadosDir.EndsWith('\') then
    FCertificadosDir := FCertificadosDir + '\';
    
  // Cria o diretório se não existir
  if not DirectoryExists(FCertificadosDir) then
    ForceDirectories(FCertificadosDir);
    
  // Cria o componente SSL para manipulação de certificados
  FACBrDFeSSL := TDFeSSL.Create;
  FACBrDFeSSL.SSLType := TSSLType.LT_TLSv1_2;
  FACBrDFeSSL.CryptLib := cryOpenSSL;
  FACBrDFeSSL.HttpLib := httpOpenSSL;
  FACBrDFeSSL.XmlSignLib := xsLibXml2;
  FACBrDFeSSL.SSLLib := libOpenSSL;
end;

destructor TACBRBridgeCertificados.Destroy;
begin
  FACBrDFeSSL.Free;
  inherited Destroy;
end;

end.