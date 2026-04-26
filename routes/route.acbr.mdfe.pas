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
procedure GetModeloDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// --- Handlers para Endpoints de Operações (POST) ---
procedure PostEnviarMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEventosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDamdfeMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// Procedure para registrar todas as rotas no Horse
procedure regRouter;

implementation

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

  Ac := TACBRBridgeMDFe.Create(O.Extract('config').AsJSON);
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

  Ac := TACBRBridgeMDFe.Create(O.Extract('config').AsJSON);
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

  Ac := TACBRBridgeMDFe.Create(O.Extract('config').AsJSON);
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

  Ac := TACBRBridgeMDFe.Create(O.Extract('config').AsJSON);
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

// --- Registro das Rotas ---

procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get(RSModeloMDFeConfigRoute, GetModeloConfigMDFe);
  THorse.Get(RSModeloMDFeEventoRoute, GetModeloEventoMDFe);
  THorse.Get(RSModeloMDFeMDFeRoute, GetModeloMDFe);
  THorse.Get(RSModeloMDFeDistribuicaoRoute, GetModeloDistribuicaoMDFe);

  // Endpoints de Operações (POST)
  THorse.Post(RSMDFeMDFeRoute, PostEnviarMDFe);
  THorse.Post(RSMDFeEventosRoute, PostEventosMDFe);
  THorse.Post(RSMDFeDAMDFeRoute, PostDamdfeMDFe);
  THorse.Post(RSMDFeDistribuicaoRoute, PostDistribuicaoMDFe);
end;

end.
