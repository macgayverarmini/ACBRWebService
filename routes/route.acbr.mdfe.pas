unit route.acbr.mdfe;

{$mode Delphi}{$H+}

interface

uses
  // Unit com a lógica de negócio do MDF-e
  method.acbr.mdfe,
  // Units do Horse e JSON
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

// --- Handlers para Endpoints de Modelos (GET) ---
procedure GetModeloConfigMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);procedure GetModeloMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);procedure GetMDFePDFFile(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// --- Handlers para Endpoints de Operações (POST) ---
procedure PostEnviarMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEventosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDamdfeMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);procedure PostDamdfeURLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);procedure PostMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);procedure PostDamdfeEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// Procedure para registrar todas as rotas no Horse
procedure regRouter;

implementation


function ExtractConfig(O: TJSONObject; const Field: string): string;
var
  Data: TJSONData;
begin
  Result := '';
  if Assigned(O) then
  begin
    Data := O.Extract(Field);
    if Assigned(Data) then
    begin
      Result := Data.AsJSON;
      Data.Free;
    end;
  end;
end;
// --- Implementação dos Handlers de Modelos (GET) ---

procedure GetModeloConfigMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelConfig;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelEvento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelMDFe;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelDistribuicao);
  finally
    AcM.Free;
  end;
end;
procedure GetModeloMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelMDFeFromXML;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelMDFeToXML;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;
procedure GetMDFePDFFile(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Chave, FilePath, PdfDir: string;
begin
  Chave := Req.Params['chave'];
  Chave := StringReplace(Chave, 'MDFe', '', [rfIgnoreCase]);

  PdfDir := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;
  FilePath := PdfDir + 'MDFe' + Chave + '-mdfe.pdf';
  if not FileExists(FilePath) then
    FilePath := PdfDir + Chave + '-mdfe.pdf';

  if FileExists(FilePath) then
    Res.Download(FilePath, 'damdfe.pdf')
  else
    Res.Status(404).Send('PDF do MDF-e nao encontrado');
end;

// --- Implementação dos Handlers de Operações (POST) ---

procedure PostEnviarMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.MDFe(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostEventosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.Evento(O.Extract('eventos') as TJSONArray));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDamdfeMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe;
  LJson: TJSONObject;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.Damdfe(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;
procedure PostDamdfeURLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.Damdfe(O, True);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;
procedure PostDamdfeEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.DamdfeEvento(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe;
  LJson: TJSONObject;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.Distribuicao(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;
procedure PostMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.MDFeFromXML(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo da requisição JSON inválido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.MDFeToXML(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

// --- Registro das Rotas ---

procedure GetModeloStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelStatusServico;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelConsulta;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelCancelamento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelEncerramento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelNaoEncerrados;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;
  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.StatusServico(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;
  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.Consulta(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;
  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.Cancelamento(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;
  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.Encerramento(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;
  Ac := TACBRBridgeMDFe.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.ConsultarMDFeNaoEnc(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get(RSModeloMDFeConfigRoute, GetModeloConfigMDFe);
  THorse.Get(RSModeloMDFeEventoRoute, GetModeloEventoMDFe);
  THorse.Get(RSModeloMDFeMDFeRoute, GetModeloMDFe);
  THorse.Get(RSModeloMDFeDistribuicaoRoute, GetModeloDistribuicaoMDFe);  THorse.Get(RSModeloMDFeMDFeFromXMLRoute, GetModeloMDFeFromXMLMDFe);
  THorse.Get(RSModeloMDFeMDFeToXMLRoute, GetModeloMDFeToXMLMDFe);  THorse.Get(RSMDFePDFRoute, GetMDFePDFFile);
  THorse.Get(RSModeloMDFeStatusRoute, GetModeloStatusMDFe);
  THorse.Get(RSModeloMDFeConsultaRoute, GetModeloConsultaMDFe);
  THorse.Get(RSModeloMDFeCancelamentoRoute, GetModeloCancelamentoMDFe);
  THorse.Get(RSModeloMDFeEncerramentoRoute, GetModeloEncerramentoMDFe);
  THorse.Get(RSModeloMDFeNaoEncerradosRoute, GetModeloNaoEncerradosMDFe);

  // Endpoints de Operações (POST)
  THorse.Post(RSMDFeMDFeRoute, PostEnviarMDFe);
  THorse.Post(RSMDFeEventosRoute, PostEventosMDFe);
  THorse.Post(RSMDFeDAMDFeRoute, PostDamdfeMDFe);  THorse.Post(RSMDFeDAMDFeURLRoute, PostDamdfeURLMDFe);
  THorse.Post(RSMDFeDistribuicaoRoute, PostDistribuicaoMDFe);  THorse.Post(RSMDFeMDFeFromXMLRoute, PostMDFeFromXMLMDFe);
  THorse.Post(RSMDFeMDFeToXMLRoute, PostMDFeToXMLMDFe);  THorse.Post(RSMDFeDAMDFeEventoRoute, PostDamdfeEventoMDFe);
  THorse.Post(RSMDFeStatusRoute, PostStatusMDFe);
  THorse.Post(RSMDFeConsultaRoute, PostConsultaMDFe);
  THorse.Post(RSMDFeCancelamentoRoute, PostCancelamentoMDFe);
  THorse.Post(RSMDFeEncerramentoRoute, PostEncerramentoMDFe);
  THorse.Post(RSMDFeNaoEncerradosRoute, PostNaoEncerradosMDFe);
end;

end.
