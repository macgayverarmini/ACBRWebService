unit route.acbr.sintegra;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.sintegra,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloConfigSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloConfigSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSintegra;
begin
  AcM := TACBRModelosJSONSintegra.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelConfig.AsJSON);
  finally
    AcM.Free;
  end;
end;

procedure PostSintegra(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSintegra;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON inválido.']).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeSintegra.Create(O.Extract('config').AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Sintegra(O));
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
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeSintegra.Create(O.Extract('config').AsJSON);
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Gerar(O));
    except
      on E: Exception do
        Res.Status(500).Send(E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloSintegraConfigRoute, GetModeloConfigSintegra);
  THorse.Post(RSSintegraRoute, PostSintegra);
  THorse.Post(RSSintegraGerarRoute, PostGerar);
end;

end.
