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

procedure regRouter;

implementation

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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

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
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

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
  THorse.Post(RSGNREEnviarRoute, PostEnviarGNRE);
  THorse.Post(RSGNREConsultarRoute, PostConsultarGNRE);
end;

end.
