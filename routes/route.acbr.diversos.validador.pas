unit route.acbr.diversos.validador;

{$mode Delphi}

interface

uses
   method.acbr.diversos.validador, fpjson, Horse, Horse.Commons, Classes, SysUtils;

procedure GetModeloValidador(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetValidar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

 procedure regRouter;

implementation

procedure GetModeloValidador(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  Ac: TACBRBridgeValidador;
  LJson: TJSONObject;
begin
  Ac := TACBRBridgeValidador.Create;
  try
    LJson := AC.Modelo;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetValidar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeValidador;
  LBool: TJSONBoolean;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeValidador.Create;
  try
    LBool := AC.Validar(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LBool.AsJSON);
    finally
      LBool.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get('/modelo/diversos/validador', GetModeloValidador);
  THorse.Post('/diversos/validador', GetValidar);
end;


end.

