unit route.acbr.escpos;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.escpos,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeEscPos.Create(TJSONTools.ExtractConfig(O));
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
