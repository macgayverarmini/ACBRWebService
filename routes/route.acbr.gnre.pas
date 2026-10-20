unit route.acbr.gnre;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.gnre,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloConfigGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloGuiaGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEnviarGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

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

procedure PostEnviarGNRE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeGNRE;
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

  Ac := TACBRBridgeGNRE.Create(ExtractConfig(O, 'config'));
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
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeGNRE.Create(ExtractConfig(O, 'config'));
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
  THorse.Post(RSGNREEnviarRoute, PostEnviarGNRE);
  THorse.Post(RSGNREConsultarRoute, PostConsultarGNRE);
end;

end.
