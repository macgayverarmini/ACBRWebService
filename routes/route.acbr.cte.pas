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
procedure GetCTePDFFile(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure PostEventosCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostStatusServico(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsulta(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostInutilizacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDACTE(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);procedure PostDACTEURL(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCancelamento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCTeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCTeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostValidarRegrasCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDACTEEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure PostDebugConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDebugCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure GetModeloValidarRegrasCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDACTEEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);



procedure regRouter;

implementation



function ExtractConfig(O: TJSONObject; const Field: string): string;
var
  Data: TJSONData;
begin
  Result := '';
  if Assigned(O) then
  begin
    Data := O.Extract(Field);
    if Assigned(Data) then
    begin
      Result := Data.AsJSON;
      Data.Free;
    end;
  end;
end;
procedure GetModeloConfigCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcC: TACBRModelosJSONCTe;
begin
  AcC := TACBRModelosJSONCTe.Create('');
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
  AcC := TACBRModelosJSONCTe.Create('');
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
  AcC := TACBRModelosJSONCTe.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcC.ModelCTe.AsJSON);
  finally
    AcC.Free;
  end;
end;

procedure GetCTePDFFile(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Chave, FilePath, PdfDir: string;
begin
  Chave := Req.Params['chave'];
  Chave := StringReplace(Chave, 'CTe', '', [rfIgnoreCase]);
  PdfDir := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;

  FilePath := PdfDir + 'CTe' + Chave + '-cte.pdf';
  if not FileExists(FilePath) then
    FilePath := PdfDir + Chave + '-cte.pdf';

  if FileExists(FilePath) then
    Res.Download(FilePath, 'dacte.pdf')
  else
    Res.Status(404).Send('PDF do CT-e nao encontrado');
end;

procedure PostEventosCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
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
  O, LJson: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
    Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
    try
      LJson := Ac.DACTE(O);
      try
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
          .Send(LJson.AsJSON);
      finally
        LJson.Free;
      end;
    finally
      O.Free;
      Ac.Free;
    end;
  except
    on E: Exception do
    begin
      Res.Status(500).Send('{"error": "' + StringReplace(E.Message, '"', '\"', [rfReplaceAll]) + '"}');
    end;
  end;
end;
procedure PostDACTEURL(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.DACTE(O, True).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  ErrObj: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.CTe(O).AsJSON);
    except
      on E: Exception do
      begin
        ErrObj := TJSONObject.Create;
        ErrObj.Add('Status', 'Erro');
        ErrObj.Add('error', 'Excecao em PostCTe: ' + E.Message);
        ErrObj.Add('Message', 'Excecao em PostCTe: ' + E.Message);
        ErrObj.Add('ClassName', E.ClassName);
        Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(ErrObj.AsJSON);
        ErrObj.Free;
      end;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloDistCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONCTe;
begin
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.Cancelamento(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCTeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, ORes: TJSONObject;
  Ac: TACBRBridgeCTe;
  ConfigData: TJSONData;
  ConfigStr: string;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  ConfigStr := '';
  ConfigData := O.Extract(RSConfigField);
  if Assigned(ConfigData) then
  begin
    ConfigStr := ConfigData.AsJSON;
    ConfigData.Free;
  end;
  Ac := TACBRBridgeCTe.Create(ConfigStr);
  try
    ORes := Ac.CTeFromXML(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(ORes.AsJSON);
    finally
      ORes.Free;
    end;
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.CTeToXML(O.Extract('CTe') as TJSONObject).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDebugConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
  try
    LJson := Ac.DebugConfig;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDebugCTe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeCTe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
  try
    LJson := Ac.DebugCTe(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
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
  Ac := TACBRBridgeCTe.Create(ExtractConfig(O, RSConfigField));
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  Ac := TACBRModelosJSONCTe.Create('');
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
  THorse.Post(RSCTeDACTEURLRoute, PostDACTEURL);
  THorse.Get('/cte/pdf/:chave', GetCTePDFFile);
  THorse.Post(RSCTeCTeRoute, PostCTe);
  THorse.Post(RSCTeCancelamentoRoute, PostCancelamento);
  THorse.Post(RSCTeCTeFromXMLRoute, PostCTeFromXML);
  THorse.Post(RSCTeCTeToXMLRoute, PostCTeToXML);
  THorse.Post(RSCTeValidarRegrasRoute, PostValidarRegrasCTe);
  THorse.Post(RSCTeDACTEEventoRoute, PostDACTEEvento);

  THorse.Post('/cte/debug-config', PostDebugConfig);
  THorse.Post('/cte/debug-cte', PostDebugCTe);

  THorse.Get(RSModeloCTeValidarRegrasRoute, GetModeloValidarRegrasCTe);
  THorse.Get(RSModeloCTeDACTEEventoRoute, GetModeloDACTEEvento);

end;

end.

