unit route.acbr.sintegra;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.sintegra,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeSintegra.Create(TJSONTools.ExtractConfig(O));
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
  Ac := TACBRBridgeSintegra.Create(TJSONTools.ExtractConfig(O));
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
