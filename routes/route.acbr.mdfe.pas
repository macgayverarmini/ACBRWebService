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
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    Res.Send<TJSONObject>(AcM.ModelConfig);
  finally
    AcM.Free;
  end;
end;

procedure GetModeloEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    Res.Send<TJSONObject>(AcM.ModelEvento);
  finally
    AcM.Free;
  end;
end;

procedure GetModeloMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    Res.Send<TJSONObject>(AcM.ModelMDFe);
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.MDFe(O));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Damdfe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Distribuicao(O));
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
