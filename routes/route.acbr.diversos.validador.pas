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
begin
  Ac := TACBRBridgeValidador.Create;
  try
    Res.Send<TJSONObject>(AC.Modelo);
  finally
    Ac.Free;
  end;
end;

procedure GetValidar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeValidador;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeValidador.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONBoolean>(AC.Validar(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get('/modelo/diversos/validador', GetModeloValidador);
  THorse.Get('/diversos/validador', GetValidar);
end;


end.

