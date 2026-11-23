unit route.acbr.gnre;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.gnre,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloConfigGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloGuiaGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEnviarGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGNREToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

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

procedure GetModeloConfigGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONGNRE;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONGNRE.Create('');
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

procedure GetModeloGuiaGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONGNRE;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONGNRE.Create('');
  try
    LJson := AcM.ModelGuia;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostGNREToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeGNRE;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeGNRE.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.GNREToXML(O);
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

procedure PostEnviarGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeGNRE;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeGNRE.Create(TJSONTools.ExtractConfig(O));
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

procedure PostConsultarGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeGNRE;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeGNRE.Create(TJSONTools.ExtractConfig(O));
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
  THorse.Get(RSModeloGNREConfigRoute, GetModeloConfigGNRE);
  THorse.Get(RSModeloGNREGuiaRoute, GetModeloGuiaGNRE);
  THorse.Get(RSModeloGNREToXMLRoute, GetModeloGuiaGNRE);
  THorse.Post(RSGNREEnviarRoute, PostEnviarGNRE);
  THorse.Post(RSGNREConsultarRoute, PostConsultarGNRE);
  THorse.Post(RSGNREToXMLRoute, PostGNREToXML);
end;

end.
