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
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelConfig;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelEmitir;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelConsultarSituacao;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelConsultarLote;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelConsultarNFSePorRps;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelConsultarNFSe;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelCancelar;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create(RSEmptyString);
  try
    LJson := AC.ModelSubstituir;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.Emitir(O);
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

procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.Gerar(O);
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

procedure PostConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.ConsultarSituacao(O);
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

procedure PostConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.ConsultarLote(O);
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

procedure PostConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.ConsultarNFSePorRps(O);
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

procedure PostConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.ConsultarNFSe(O);
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

procedure PostCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.Cancelar(O);
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

procedure PostSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.Substituir(O);
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

procedure PostDANFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
  try
    LJson := Ac.Danfse(O);
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

procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFSe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFSe.Create(O.Extract(RSConfigField).AsJSON);
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
