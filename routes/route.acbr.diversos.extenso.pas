unit route.acbr.diversos.extenso;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.diversos.extenso, fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;


  procedure GetModeloExtenso(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
  procedure GetTraduzValor(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

  procedure regRouter;
implementation

procedure GetModeloExtenso(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  Ac: TACBRBridgeExtenso;
begin
  Ac := TACBRBridgeExtenso.Create;
  try
    Res.Send<TJSONObject>(AC.Modelo);
  finally
    Ac.Free;
  end;
end;

procedure GetTraduzValor(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeExtenso;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeExtenso.Create;
  try
    Res.Send<TJSONObject>(AC.TraduzValor(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloDiversosExtensoRoute, GetModeloExtenso);
  THorse.Get(RSDiversosExtensoRoute, GetTraduzValor);
end;



end.

