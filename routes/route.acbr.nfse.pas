unit route.acbr.nfse;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.nfse, fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.routes;

// Get - Modelos
procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// Post
procedure PostEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDANFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelConfig);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelEmitir);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelConsultarSituacao);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelConsultarLote);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelConsultarNFSePorRps);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelConsultarNFSe);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelCancelar);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    Res.Send<TJSONObject>(AC.ModelSubstituir);
  finally
    Ac.Free;
  end;
end;

procedure PostEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Emitir(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Gerar(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.ConsultarSituacao(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.ConsultarLote(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.ConsultarNFSePorRps(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.ConsultarNFSe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Cancelar(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Substituir(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDANFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Danfse(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Distribuicao(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloNFSeConfigRoute, GetModeloConfig);
  THorse.Get(RSModeloNFSeEmitirRoute, GetModeloEmitir);
  THorse.Get(RSModeloNFSeConsultarSituacaoRoute, GetModeloConsultarSituacao);
  THorse.Get(RSModeloNFSeConsultarLoteRoute, GetModeloConsultarLote);
  THorse.Get(RSModeloNFSeConsultarNFSePorRpsRoute, GetModeloConsultarNFSePorRps);
  THorse.Get(RSModeloNFSeConsultarNFSeRoute, GetModeloConsultarNFSe);
  THorse.Get(RSModeloNFSeCancelarRoute, GetModeloCancelar);
  THorse.Get(RSModeloNFSeSubstituirRoute, GetModeloSubstituir);

  THorse.Post(RSNFSeEmitirRoute, PostEmitir);
  THorse.Post(RSNFSeGerarRoute, PostGerar);
  THorse.Post(RSNFSeConsultarSituacaoRoute, PostConsultarSituacao);
  THorse.Post(RSNFSeConsultarLoteRoute, PostConsultarLote);
  THorse.Post(RSNFSeConsultarNFSePorRpsRoute, PostConsultarNFSePorRps);
  THorse.Post(RSNFSeConsultarNFSeRoute, PostConsultarNFSe);
  THorse.Post(RSNFSeCancelarRoute, PostCancelar);
  THorse.Post(RSNFSeSubstituirRoute, PostSubstituir);
  THorse.Post(RSNFSeDANFSeRoute, PostDANFSe);
  THorse.Post(RSNFSeDistribuicaoRoute, PostDistribuicao);
end;

end.
