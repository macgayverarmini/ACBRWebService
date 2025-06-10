unit route.acbr.cte;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.cte,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.routes;

procedure GetModeloConfigCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEventoCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDistCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure PostEventosCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDACTE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation


procedure GetModeloConfigCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(AcC.ModelConfig);
  finally
    AcC.Free;
  end;
end;

procedure GetModeloEventoCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(AcC.ModelEvento);
  finally
    AcC.Free;
  end;
end;

procedure GetModeloCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(AcC.ModelCTe);
  finally
    AcC.Free;
  end;
end;

procedure PostEventosCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.Evento(O.Extract(RSEventosField) as TJSONArray));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDACTE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.DACTE(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.CTe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloDistCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AC.ModelDistribuicao);
  finally
    Ac.Free;
  end;
end;

procedure PostDistCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.Distribuicao(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;


procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get(RSModeloCTeConfigRoute, GetModeloConfigCTe);
  THorse.Get(RSModeloCTeEventoRoute, GetModeloEventoCTe);
  THorse.Get(RSModeloCTeDistribuicaoRoute, GetModeloDistCTe);
  THorse.Get(RSModeloCTeCTeRoute, GetModeloCTe);

  THorse.Post(RSCTeEventosRoute, PostEventosCTe);
  THorse.Post(RSCTeDistribuicaoRoute, PostDistCTe);
  THorse.Post(RSCTeDANFeRoute, PostDACTE);
  THorse.Post(RSCTeNFeRoute, PostCTe);

end;

end.
