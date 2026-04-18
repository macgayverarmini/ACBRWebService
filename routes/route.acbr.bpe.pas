unit route.acbr.bpe;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.bpe,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloConfigBPe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostBPe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEnviar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloConfigBPe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONBPe;
begin
  AcM := TACBRModelosJSONBPe.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelConfig.AsJSON);
  finally
    AcM.Free;
  end;
end;

procedure PostBPe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeBPe;
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

  Ac := TACBRBridgeBPe.Create(O.Extract('config').AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.BPe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostEnviar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeBPe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeBPe.Create(O.Extract('config').AsJSON);
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
  THorse.Get(RSModeloBPeConfigRoute, GetModeloConfigBPe);
  THorse.Post(RSBPeRoute, PostBPe);
  THorse.Post(RSBPeEnviarRoute, PostEnviar);
end;

end.
