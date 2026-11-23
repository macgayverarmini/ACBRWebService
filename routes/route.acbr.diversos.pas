unit route.acbr.diversos;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.diversos,
  jsonconvert,
  fpjson,
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloIBPT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostIBPTLerTabela(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEAD(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEAD(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCalcDigito(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCalcDigito(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloMail(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostMail(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

function TryParseJsonObject(const ABody: string; Res: THorseResponse; out AObj: TJSONObject): Boolean;
var
  LData: TJSONData;
begin
  Result := False;
  AObj := nil;
  LData := nil;
  try
    LData := GetJSON(ABody);
  except
    on E: Exception do
    begin
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
         .Status(400)
         .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
           RSStatusField, RSStatusErro,
           RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message
         ])));
      Exit;
    end;
  end;

  if not Assigned(LData) then
  begin
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
         RSStatusField, RSStatusErro,
         RSMessageField, RSInvalidJSONBodyError
       ])));
    Exit;
  end;

  if not (LData is TJSONObject) then
  begin
    LData.Free;
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
         RSStatusField, RSStatusErro,
         RSMessageField, RSNotJSONObjectError
       ])));
    Exit;
  end;

  AObj := TJSONObject(LData);
  Result := True;
end;

procedure GetModeloCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversos;
begin
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModelCMC7));
  finally
    Ac.Free;
  end;
end;

procedure PostCMC7(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeDiversos;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ProcessarCMC7(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversos;
begin
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModelInStore));
  finally
    Ac.Free;
  end;
end;

procedure PostInStore(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeDiversos;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.DesmembrarInStore(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversos;
begin
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModelCargaBal));
  finally
    Ac.Free;
  end;
end;

procedure PostCargaBal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeDiversos;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.GerarCargaBalanca(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloIBPT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversos;
begin
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModelIBPT));
  finally
    Ac.Free;
  end;
end;

procedure PostIBPTLerTabela(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeDiversos;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.LerTabelaIBPT(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloEAD(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversos;
begin
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModelEAD));
  finally
    Ac.Free;
  end;
end;

procedure PostEAD(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeDiversos;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ProcessarEAD(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloCalcDigito(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversos;
begin
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModelCalcDigito));
  finally
    Ac.Free;
  end;
end;

procedure PostCalcDigito(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeDiversos;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.CalcularDigito(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloMail(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeDiversos;
begin
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModelMail));
  finally
    Ac.Free;
  end;
end;

procedure PostMail(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeDiversos;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;
  Ac := TACBRBridgeDiversos.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.EnviarEmail(O)));
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
  THorse.Get(RSModeloDiversosEADRoute, GetModeloEAD);
  THorse.Post(RSDiversosEADRoute, PostEAD);
  THorse.Get(RSModeloDiversosCalcDigitoRoute, GetModeloCalcDigito);
  THorse.Post(RSDiversosCalcDigitoRoute, PostCalcDigito);
  THorse.Get(RSModeloDiversosMailRoute, GetModeloMail);
  THorse.Post(RSDiversosMailRoute, PostMail);
end;

end.
