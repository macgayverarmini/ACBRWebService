unit route.acbr.certificados;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.certificados,
  fpjson, Horse, Horse.Commons, Classes, SysUtils;


procedure GetModeloUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);


procedure PostUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
procedure PostLerDadosCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);


procedure regRouter;

implementation

procedure GetModeloUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  Ac: TACBRBridgeCertificados;
begin
  Ac := TACBRBridgeCertificados.Create;
  try
    Res.Send<TJSONObject>(Ac.ModeloUpload);
  finally
    Ac.Free;
  end;
end;


procedure PostUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  LJsonBody: TJSONData;
  O: TJSONObject;
  Ac: TACBRBridgeCertificados;
  CertificadoBase64, Senha, CNPJ, NomeArquivo: string;
  JsonStr: TJSONString;
begin

  try
    LJsonBody := GetJSON(Req.Body);
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(
        ['message', 'Erro ao parsear o corpo da requisição JSON: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  if not Assigned(LJsonBody) then
  begin
    Res.Status(400).Send(TJSONObject.Create(
      ['message', 'Corpo da requisição JSON inválido ou vazio.']).AsJSON);
    Exit;
  end;

  if not (LJsonBody is TJSONObject) then
  begin
    LJsonBody.Free;
    Res.Status(400).Send(TJSONObject.Create(
      ['message', 'O corpo da requisição não é um objeto JSON.']).AsJSON);
    Exit;
  end;
  O := LJsonBody as TJSONObject;
  try
    try
      if O.Find('certificado_base64', JsonStr) then
      begin
        CertificadoBase64 := JsonStr.Value;
        if CertificadoBase64 = '' then
          raise Exception.Create('Campo "certificado_base64" não pode ser vazio.');
      end
      else
      begin
        raise Exception.Create(
          'Campo "certificado_base64" não encontrado ou não é do tipo string no corpo da requisição JSON.');
      end;

      // Campo: senha (obrigatório)
      if O.Find('senha', JsonStr) then
      begin
        Senha := JsonStr.Value;
        if Senha = '' then
          raise Exception.Create('Campo "senha" não pode ser vazio.');
      end
      else
      begin
        raise Exception.Create(
          'Campo "senha" não encontrado ou não é do tipo string no corpo da requisição JSON.');
      end;

      // Campo: cnpj (opcional)
      if O.Find('cnpj', JsonStr) then
        CNPJ := JsonStr.Value
      else
        CNPJ := ''; // Valor padrão se não encontrado ou tipo incorreto

      // Campo: nome_arquivo (opcional)
      if O.Find('nome_arquivo', JsonStr) then
        NomeArquivo := JsonStr.Value
      else
        NomeArquivo := ''; // Valor padrão

      // Cria a instância da Bridge
      Ac := TACBRBridgeCertificados.Create;
      try
        // Chama o método para salvar o certificado
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
          .Send<TJSONObject>(Ac.SalvarCertificado(CertificadoBase64,
          Senha, CNPJ, NomeArquivo));
      finally
        Ac.Free;
      end;
    except
      on E: Exception do
      begin
        Res.Status(400).Send(TJSONObject.Create(['message', E.Message]).AsJSON);
      end;
    end;
  finally
    O.Free; // Libera o JSON principal da requisição
  end;
end;

procedure PostLerDadosCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  LJsonBody: TJSONData;
  O: TJSONObject;
  Ac: TACBRBridgeCertificados;
  CertificadoBase64, Senha: string;

  // Variável para receber o out-parameter do método Find
  JsonStr: TJSONString;
begin
  // 1. Obtenção mais robusta do TJSONObject
  try
    LJsonBody := GetJSON(Req.Body);
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(
        ['message', 'Erro ao parsear o corpo da requisição JSON: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  if not Assigned(LJsonBody) then
  begin
    Res.Status(400).Send(TJSONObject.Create(
      ['message', 'Corpo da requisição JSON inválido ou vazio.']).AsJSON);
    Exit;
  end;

  if not (LJsonBody is TJSONObject) then
  begin
    LJsonBody.Free;
    Res.Status(400).Send(TJSONObject.Create(
      ['message', 'O corpo da requisição não é um objeto JSON.']).AsJSON);
    Exit;
  end;
  O := LJsonBody as TJSONObject;

  try

    try
      // Campo: certificado_base64 (obrigatório)
      if O.Find('certificado_base64', JsonStr) then
      begin
        CertificadoBase64 := JsonStr.Value;
        if CertificadoBase64 = '' then
          raise Exception.Create('Campo "certificado_base64" não pode ser vazio.');
      end
      else
      begin
        raise Exception.Create(
          'Campo "certificado_base64" não encontrado ou não é do tipo string no corpo da requisição JSON.');
      end;

      // Campo: senha (obrigatório)
      if O.Find('senha', JsonStr) then
      begin
        Senha := JsonStr.Value;
        if Senha = '' then
          raise Exception.Create('Campo "senha" não pode ser vazio.');
      end
      else
      begin
        raise Exception.Create(
          'Campo "senha" não encontrado ou não é do tipo string no corpo da requisição JSON.');
      end;

      // Cria a instância da Bridge
      Ac := TACBRBridgeCertificados.Create;
      try
        // Chama o método para ler os dados do certificado
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
          .Send<TJSONObject>(Ac.ObterDadosCertificado(CertificadoBase64, Senha));
      finally
        Ac.Free;
      end;
    except
      on E: Exception do
      begin
        Res.Status(400).Send(TJSONObject.Create(['message', E.Message]).AsJSON);
      end;
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
