unit route.acbr.sintegra;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.sintegra,
  jsonconvert,
  fpjson,
  jsonparser,
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloConfigSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloGerarSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure SendJsonError(Res: THorseResponse; const AStatus: Integer; const AMsg: string);
var
  LErr: TJSONObject;
begin
  LErr := TJSONObject.Create;
  LErr.Add(RSStatusField, RSStatusErro);
  LErr.Add(RSMessageField, AMsg);
  Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
     .Status(AStatus)
     .Send(TJSONTools.JsonAndFree(LErr));
end;

function TryParseJsonObjectBody(Req: THorseRequest; Res: THorseResponse; out AObj: TJSONObject): Boolean;
var
  LData: TJSONData;
begin
  Result := False;
  AObj := nil;
  if Trim(Req.Body) = '' then
  begin
    SendJsonError(Res, 400, RSInvalidJSONBodyError);
    Exit;
  end;
  try
    LData := GetJSON(Req.Body);
  except
    on E: Exception do
    begin
      SendJsonError(Res, 400, RSInvalidJSONBodyError);
      Exit;
    end;
  end;
  if not Assigned(LData) then
  begin
    SendJsonError(Res, 400, RSInvalidJSONBodyError);
    Exit;
  end;
  if not (LData is TJSONObject) then
  begin
    LData.Free;
    SendJsonError(Res, 400, RSNotJSONObjectError);
    Exit;
  end;
  AObj := TJSONObject(LData);
  Result := True;
end;

procedure GetModeloConfigSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSintegra;
begin
  AcM := TACBRModelosJSONSintegra.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
  finally
    AcM.Free;
  end;
end;

procedure GetModeloGerarSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSintegra;
begin
  AcM := TACBRModelosJSONSintegra.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelGerar));
  finally
    AcM.Free;
  end;
end;

procedure PostSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSintegra;
begin
  if not TryParseJsonObjectBody(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeSintegra.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Sintegra(O)));
    except
      on E: Exception do
        SendJsonError(Res, 500, E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSintegra;
begin
  if not TryParseJsonObjectBody(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeSintegra.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Gerar(O)));
    except
      on E: Exception do
        SendJsonError(Res, 500, E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloSintegraConfigRoute, GetModeloConfigSintegra);
  THorse.Get(RSModeloSintegraGerarRoute, GetModeloGerarSintegra);
  THorse.Post(RSSintegraRoute, PostSintegra);
  THorse.Post(RSSintegraGerarRoute, PostGerar);
end;

end.
