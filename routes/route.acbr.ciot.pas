unit route.acbr.ciot;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.ciot,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloConfigCIOT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCIOT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEnviar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloConfigCIOT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONCIOT;
begin
  AcM := TACBRModelosJSONCIOT.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelConfig.AsJSON);
  finally
    AcM.Free;
  end;
end;

procedure PostCIOT(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCIOT;
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

  Ac := TACBRBridgeCIOT.Create(O.Extract('config').AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.CIOT(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostEnviar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCIOT;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCIOT.Create(O.Extract('config').AsJSON);
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Enviar(O));
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
  THorse.Get(RSModeloCIOTConfigRoute, GetModeloConfigCIOT);
  THorse.Post(RSCIOTRoute, PostCIOT);
  THorse.Post(RSCIOTEnviarRoute, PostEnviar);
end;

end.
