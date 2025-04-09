unit route.acbr.certificados;

{$mode Delphi}{$H+}

interface

uses
  // Unit com a lógica de negócio dos certificados
  method.acbr.certificados,
  // Units do Horse e JSON
  fpjson, Horse, Horse.Commons, Classes, SysUtils;

// --- Handlers para Endpoints de Modelos (GET) ---
procedure GetModeloUploadCertificado(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// --- Handlers para Endpoints de Operações (POST) ---
procedure PostUploadCertificado(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostLerDadosCertificado(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// Procedure para registrar todas as rotas no Horse
procedure regRouter;

implementation

// --- Implementação dos Handlers de Modelos (GET) ---

procedure GetModeloUploadCertificado(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeCertificados;
begin
  Ac := TACBRBridgeCertificados.Create;
  try
    // Envia o JSON do modelo de upload de certificado
    Res.Send<TJSONObject>(Ac.ModeloUpload);
  finally
    Ac.Free;
  end;
end;

// --- Implementação dos Handlers de Operações (POST) ---

procedure PostUploadCertificado(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCertificados;
  CertificadoBase64, Senha, CNPJ, NomeArquivo: string;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  
  try
    // Extrai os dados do corpo da requisição
    if not O.Find('certificado_base64', CertificadoBase64) then
      raise Exception.Create('Campo "certificado_base64" não encontrado no corpo da requisição JSON.');
      
    if not O.Find('senha', Senha) then
      raise Exception.Create('Campo "senha" não encontrado no corpo da requisição JSON.');
      
    // CNPJ é opcional, será lido do certificado se não informado
    if not O.Find('cnpj', CNPJ) then
      CNPJ := '';
      
    // Nome do arquivo é opcional
    if not O.Find('nome_arquivo', NomeArquivo) then
      NomeArquivo := '';
    
    // Cria a instância da Bridge
    Ac := TACBRBridgeCertificados.Create;
    try
      // Chama o método para salvar o certificado
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send<TJSONObject>(Ac.SalvarCertificado(CertificadoBase64, Senha, CNPJ, NomeArquivo));
    finally
      Ac.Free;
    end;
  finally
    O.Free; // Libera o JSON principal da requisição
  end;
end;

procedure PostLerDadosCertificado(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCertificados;
  CertificadoBase64, Senha: string;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  
  try
    // Extrai os dados do corpo da requisição
    if not O.Find('certificado_base64', CertificadoBase64) then
      raise Exception.Create('Campo "certificado_base64" não encontrado no corpo da requisição JSON.');
      
    if not O.Find('senha', Senha) then
      raise Exception.Create('Campo "senha" não encontrado no corpo da requisição JSON.');
    
    // Cria a instância da Bridge
    Ac := TACBRBridgeCertificados.Create;
    try
      // Chama o método para ler os dados do certificado
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send<TJSONObject>(Ac.ObterDadosCertificado(CertificadoBase64, Senha));
    finally
      Ac.Free;
    end;
  finally
    O.Free; // Libera o JSON principal da requisição
  end;
end;

// --- Registro das Rotas ---

procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get('/certificados/upload', GetModeloUploadCertificado);

  // Endpoints de Operações (POST)
  THorse.Post('/certificados/upload', PostUploadCertificado);
  THorse.Post('/certificados/ler-dados', PostLerDadosCertificado);
end;

end.