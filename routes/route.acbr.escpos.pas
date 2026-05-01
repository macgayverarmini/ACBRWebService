unit route.acbr.escpos;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.escpos,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloConfigEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetPortasDisponiveis(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure regRouter;

implementation

procedure GetModeloConfigEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONEscPos;
begin
  AcM := TACBRModelosJSONEscPos.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelConfig.AsJSON);
  finally
    AcM.Free;
  end;
end;

procedure PostEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeEscPos;
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

  Ac := TACBRBridgeEscPos.Create(O.Extract('config').AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.EscPos(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetPortasDisponiveis(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeEscPos;
begin
  Ac := TACBRBridgeEscPos.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.PortasDisponiveis);
  finally
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloEscPosConfigRoute, GetModeloConfigEscPos);
  THorse.Get(RSEscPosPortasRoute, GetPortasDisponiveis);
  THorse.Post(RSEscPosRoute, PostEscPos);
end;

end.
