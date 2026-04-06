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

procedure GetModeloStatusServico(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsulta(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloInutilizacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCancelamento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCTeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCTeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure PostEventosCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostStatusServico(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsulta(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostInutilizacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDACTE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCancelamento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCTeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCTeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostValidarRegrasCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDACTEEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure GetModeloValidarRegrasCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDACTEEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);



procedure regRouter;

implementation


procedure GetModeloConfigCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcC.ModelConfig.AsJSON);
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcC.ModelEvento.AsJSON);
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcC.ModelCTe.AsJSON);
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
      .Send(Ac.DACTE(O).AsJSON);
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.CTe(O).AsJSON);
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
      .Send(Ac.Distribuicao(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloStatusServico(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelStatusServico.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsulta(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelConsulta.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloInutilizacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelInutilizacao.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure PostStatusServico(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.StatusServico(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsulta(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.Consulta(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostInutilizacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.Inutilizacao(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;


procedure GetModeloCancelamento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelCancelamento.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloCTeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelCTeFromXML.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloCTeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelCTeToXML.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure PostCancelamento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.Cancelamento(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCTeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.CTeFromXML(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCTeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.CTeToXML(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostValidarRegrasCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ValidarRegras(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDACTEEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(O.Extract(RSConfigField).AsJSON);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.DACTEEvento(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloValidarRegrasCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelValidarRegras.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloDACTEEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create(RSEmptyString);
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelDACTEEvento.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get(RSModeloCTeConfigRoute, GetModeloConfigCTe);
  THorse.Get(RSModeloCTeEventoRoute, GetModeloEventoCTe);
  THorse.Get(RSModeloCTeDistribuicaoRoute, GetModeloDistCTe);
  THorse.Get(RSModeloCTeStatusRoute, GetModeloStatusServico);
  THorse.Get(RSModeloCTeConsultaRoute, GetModeloConsulta);
  THorse.Get(RSModeloCTeInutilizacaoRoute, GetModeloInutilizacao);
  THorse.Get(RSModeloCTeCTeRoute, GetModeloCTe);
  THorse.Get(RSModeloCTeCancelamentoRoute, GetModeloCancelamento);
  THorse.Get(RSModeloCTeCTeFromXMLRoute, GetModeloCTeFromXML);
  THorse.Get(RSModeloCTeCTeToXMLRoute, GetModeloCTeToXML);

  THorse.Post(RSCTeEventosRoute, PostEventosCTe);
  THorse.Post(RSCTeStatusRoute, PostStatusServico);
  THorse.Post(RSCTeConsultaRoute, PostConsulta);
  THorse.Post(RSCTeInutilizacaoRoute, PostInutilizacao);
  THorse.Post(RSCTeDistribuicaoRoute, PostDistCTe);
  THorse.Post(RSCTeDACTERoute, PostDACTE);
  THorse.Post(RSCTeCTeRoute, PostCTe);
  THorse.Post(RSCTeCancelamentoRoute, PostCancelamento);
  THorse.Post(RSCTeCTeFromXMLRoute, PostCTeFromXML);
  THorse.Post(RSCTeCTeToXMLRoute, PostCTeToXML);
  THorse.Post(RSCTeValidarRegrasRoute, PostValidarRegrasCTe);
  THorse.Post(RSCTeDACTEEventoRoute, PostDACTEEvento);

  THorse.Get(RSModeloCTeValidarRegrasRoute, GetModeloValidarRegrasCTe);
  THorse.Get(RSModeloCTeDACTEEventoRoute, GetModeloDACTEEvento);

end;

end.

