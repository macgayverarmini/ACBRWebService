unit route.acbr.diversos.legado;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.diversos.legado,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloIBPT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostIBPTLerTabela(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversosLegado;
  LJson: TJSONObject;
begin
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.ModelCMC7;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeDiversosLegado;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.ProcessarCMC7(O);
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

procedure GetModeloInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversosLegado;
  LJson: TJSONObject;
begin
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.ModelInStore;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeDiversosLegado;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.DesmembrarInStore(O);
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

procedure GetModeloCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversosLegado;
  LJson: TJSONObject;
begin
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.ModelCargaBal;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeDiversosLegado;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.GerarCargaBalanca(O);
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

procedure GetModeloIBPT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversosLegado;
  LJson: TJSONObject;
begin
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.ModelIBPT;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostIBPTLerTabela(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeDiversosLegado;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeDiversosLegado.Create;
  try
    LJson := Ac.LerTabelaIBPT(O);
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
  THorse.Get(RSModeloDiversosCMC7Route, GetModeloCMC7);
  THorse.Post(RSDiversosCMC7Route, PostCMC7);
  THorse.Get(RSModeloDiversosInStoreRoute, GetModeloInStore);
  THorse.Post(RSDiversosInStoreRoute, PostInStore);
  THorse.Get(RSModeloDiversosCargaBalRoute, GetModeloCargaBal);
  THorse.Post(RSDiversosCargaBalRoute, PostCargaBal);
  THorse.Get(RSModeloDiversosIBPTRoute, GetModeloIBPT);
  THorse.Post(RSDiversosIBPTLerTabelaRoute, PostIBPTLerTabela);
end;

end.
