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
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

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
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

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
