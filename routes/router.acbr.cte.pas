unit router.acbr.cte;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.cte,
  fpjson, Horse, Horse.Commons, Classes, SysUtils;

procedure GetModeloConfigCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEventoCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaSituacaoServicoCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEnviarCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEventosCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarSituacaoServicoCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDACTE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);



procedure regRouter;

implementation


procedure GetModeloConfigCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create('');
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
  AcC := TACBRModelosJSONCTe.Create('');
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
  AcC := TACBRModelosJSONCTe.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(AcC.ModelCTe);
  finally
    AcC.Free;
  end;
end;

procedure GetModeloConsultaCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(AcC.ModelConsultaCTe);
  finally
    AcC.Free;
  end;
end;

procedure GetModeloConsultaSituacaoServicoCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(AcC.ModelConsultaSituacaoServico);
  finally
    AcC.Free;
  end;
end;

procedure PostEnviarCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;

  if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" n\u00E3o encontrado no corpo da requisi\u00E7\u00E3o JSON.');

  Ac := TACBRBridgeCTe.Create(cfgJson.AsString);
  try
    O.Remove(O.FindValue('config'));

    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.EnviarCTe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostEventosCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  jEventos: TJSONArray;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" n\u00E3o encontrado no corpo da requisi\u00E7\u00E3o JSON.');

  Ac := TACBRBridgeCTe.Create(cfgJson.AsString);
  try
    jEventos := O.Extract('eventos') as TJSONArray;
    if not Assigned(jEventos) then
       raise Exception.Create('Array de eventos n\u00E3o encontrado no corpo da requisi\u00E7\u00E3o JSON sob a chave "eventos".');
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.EnviarEvento(jEventos));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultarCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
   if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" n\u00E3o encontrado no corpo da requisi\u00E7\u00E3o JSON.');

  Ac := TACBRBridgeCTe.Create(cfgJson.AsString);
  try
    O.Remove(O.FindValue('config'));

    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.ConsultarCTe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultarSituacaoServicoCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
   if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" n\u00E3o encontrado no corpo da requisi\u00E7\u00E3o JSON.');

  Ac := TACBRBridgeCTe.Create(cfgJson.AsString);
  try
    O.Remove(O.FindValue('config'));


    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.ConsultarSituacaoServico(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDACTE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
   if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" n\u00E3o encontrado no corpo da requisi\u00E7\u00E3o JSON.');

  Ac := TACBRBridgeCTe.Create(cfgJson.AsString);
  try
     O.Remove(O.FindValue('config'));
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.GerarDACTE(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;


procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get('/modelo/cte/config', GetModeloConfigCTe);
  THorse.Get('/modelo/cte/evento', GetModeloEventoCTe);
  THorse.Get('/modelo/cte/cte', GetModeloCTe);
  THorse.Get('/modelo/cte/consulta', GetModeloConsultaCTe);
  THorse.Get('/modelo/cte/consulta-situacao-servico', GetModeloConsultaSituacaoServicoCTe);


  // Endpoints de Opera\u00E7\u00F5es (POST)
  THorse.Post('/cte/enviar', PostEnviarCTe);
  THorse.Post('/cte/eventos', PostEventosCTe);
  THorse.Post('/cte/consulta', PostConsultarCTe);
  THorse.Post('/cte/consulta-situacao-servico', PostConsultarSituacaoServicoCTe);
  THorse.Post('/cte/dacte', PostDACTE);

end;

end.
