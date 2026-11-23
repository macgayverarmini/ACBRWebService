unit route.acbr.reinf;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.reinf,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloConfigReinf(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEnviarReinf(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarReinf(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

function TryParseJSONObject(Req: THorseRequest; Res: THorseResponse; out O: TJSONObject): Boolean;
var
  LData: TJSONData;
begin
  Result := False;
  O := nil;
  try
    LData := GetJSON(Req.Body);
    if not (LData is TJSONObject) then
    begin
      LData.Free;
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSStatusField, RSStatusErro, RSMessageField, RSNotJSONObjectError])));
      Exit;
    end;
    O := TJSONObject(LData);
    Result := True;
  except
    on E: Exception do
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSStatusField, RSStatusErro, RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
  end;
end;

procedure GetModeloConfigReinf(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONReinf;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONReinf.Create('');
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

procedure PostEnviarReinf(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeReinf;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeReinf.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Enviar(O);
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

procedure PostConsultarReinf(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeReinf;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeReinf.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Consultar(O);
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
  THorse.Get(RSModeloReinfConfigRoute, GetModeloConfigReinf);
  THorse.Post(RSReinfEnviarRoute, PostEnviarReinf);
  THorse.Post(RSReinfConsultarRoute, PostConsultarReinf);
end;

end.
