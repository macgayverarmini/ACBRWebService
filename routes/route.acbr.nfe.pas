unit route.acbr.nfe;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.nfe, fpjson, Horse, Horse.Commons, Classes, SysUtils;

//Get
procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDist(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
//Post
procedure PostEventos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);


procedure regRouter;

implementation

procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.Send<TJSONObject>(AC.ModelConfig);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.Send<TJSONObject>(AC.ModelEvento);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloDist(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AC.ModelDistribuicao);
  finally
    Ac.Free;
  end;
end;

procedure PostEventos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRModelosJSON.Create(O.Extract('config').AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.Evento(O.Extract('eventos') as TJSONArray));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRModelosJSON.Create(O.Extract('config').AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.Distribuicao(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get('/modelo/nfe/config', GetModeloConfig);
  THorse.Get('/modelo/nfe/evento', GetModeloEvento);
  THorse.Get('/modelo/nfe/distribuicao', GetModeloDist);
  THorse.Post('/nfe/eventos', PostEventos);
  THorse.Post('/nfe/distribuicao', PostDistribuicao);
end;

end.
