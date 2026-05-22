unit route.acbr.nfe;

{$mode Delphi}{$H+}


interface

uses
  method.acbr.nfe, fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.routes;

//Get
procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDist(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
//Post
procedure PostEventos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDANFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostStatusServicoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultaNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultaReciboNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostInutilizacaoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCancelamentoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNFeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNFeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostValidarRegrasNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDanfeEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
//Get - Modelos
procedure GetModeloStatusServicoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloInutilizacaoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCancelamentoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloValidarRegrasNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDanfeEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;
procedure PostDebugConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNFeLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

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
procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    LJson := AC.ModelConfig;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    LJson := Ac.ModelNFe;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    LJson := AC.ModelEvento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
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
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.Evento(O.Extract(RSEventosField) as TJSONArray));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    LJson := Ac.Distribuicao(O);
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

procedure PostNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, ErrObj: TJSONObject;
  Ac: TACBRBridgeNFe;
  LJson: TJSONObject;
  Step: String;

begin
  try
    Step := 'ParseJSONBody';
    O := GetJSON(Req.Body) as TJSONObject;

    Step := 'CreateTACBRBridgeNFe';
    Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
    try
      Step := 'CallAcNFe';
      LJson := Ac.NFe(O);

      try
        Step := 'SendResponse';
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
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
      ErrObj := TJSONObject.Create;
      ErrObj.Add('Status', 'Erro');
      ErrObj.Add('error', 'Excecao em PostNFe (' + Step + '): ' + E.Message); // 'error' em lowercase para bater com a checagem no python
      ErrObj.Add('Message', 'Excecao em PostNFe (' + Step + '): ' + E.Message);
      ErrObj.Add('ClassName', E.ClassName);
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(ErrObj.AsJSON);
      ErrObj.Free;
    end;
  end;
end;

procedure PostDANFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    LJson := Ac.Danfe(O);
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

procedure PostStatusServicoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.StatusServico(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultaNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.Consulta(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultaReciboNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    LJson := Ac.ConsultaRecibo(O);
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

procedure PostInutilizacaoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.Inutilizacao(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostCancelamentoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.Cancelamento(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostNFeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.NFeFromXML(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostNFeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, ErrObj: TJSONObject;
  Ac: TACBRBridgeNFe;
  CfgData: TJSONData;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
    CfgData := O.Extract(RSConfigField);
    if Assigned(CfgData) then
    begin
      Ac := TACBRBridgeNFe.Create(CfgData.AsJSON);
      CfgData.Free;
    end
    else
      Ac := TACBRBridgeNFe.Create('');

    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.NFeToXML(O).AsJSON);
    finally
      O.Free;
      Ac.Free;
    end;
  except
    on E: Exception do
    begin
      ErrObj := TJSONObject.Create;
      ErrObj.Add('Status', 'Erro');
      ErrObj.Add('Message', 'Excecao em PostNFeToXML: ' + E.Message);
      ErrObj.Add('ClassName', E.ClassName);
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(ErrObj.AsJSON);
      ErrObj.Free;
    end;
  end;
end;

procedure PostValidarRegrasNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ValidarRegras(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDanfeEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.DanfeEvento(O).AsJSON);
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloStatusServicoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelStatusServico.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultaNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelConsulta.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloInutilizacaoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelInutilizacao.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloCancelamentoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelCancelamento.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloNFeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelNFeFromXML.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloNFeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelNFeToXML.AsJSON);
  finally
    Ac.Free;
  end;
end;

procedure GetModeloValidarRegrasNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelConfig.AsJSON);
    // ValidarRegras usa o mesmo modelo do NF-e
  finally
    Ac.Free;
  end;
end;

procedure GetModeloDanfeEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelNFeFromXML.AsJSON);
    // DanfeEvento usa o mesmo formato: xml em Base64
  finally
    Ac.Free;
  end;
end;

procedure PostNFeLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, ErrObj: TJSONObject;
  Ac: TACBRBridgeNFe;
  LJson: TJSONObject;
  LNFes: TJSONArray;
  Step: String;
begin
  try
    Step := 'ParseJSONBody';
    O := GetJSON(Req.Body) as TJSONObject;

    Step := 'CreateTACBRBridgeNFe';
    Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
    try
      Step := 'ExtractNFesArray';
      LNFes := O.Find('NFes', jtArray) as TJSONArray;
      if LNFes = nil then
      begin
        ErrObj := TJSONObject.Create;
        ErrObj.Add('Status', 'Erro');
        ErrObj.Add('error', 'Campo NFes (array) nao encontrado no payload');
        Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(ErrObj.AsJSON);
        ErrObj.Free;
        Exit;
      end;

      Step := 'CallAcNFeLote';
      LJson := Ac.NFeLote(LNFes);
      try
        Step := 'SendResponse';
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
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
      ErrObj := TJSONObject.Create;
      ErrObj.Add('Status', 'Erro');
      ErrObj.Add('error', 'Excecao em PostNFeLote (' + Step + '): ' + E.Message);
      ErrObj.Add('Message', 'Excecao em PostNFeLote (' + Step + '): ' + E.Message);
      ErrObj.Add('ClassName', E.ClassName);
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(ErrObj.AsJSON);
      ErrObj.Free;
    end;
  end;
end;

procedure PostDebugConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
  LJson: TJSONObject;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeNFe.Create(ExtractConfig(O, RSConfigField));
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

procedure regRouter;
begin
  THorse.Get(RSModeloNFeConfigRoute, GetModeloConfig);
  THorse.Get(RSModeloNFeEventoRoute, GetModeloEvento);
  THorse.Get(RSModeloNFeDistribuicaoRoute, GetModeloDist);
  THorse.Get(RSModeloNFeNFeRoute, GetModeloNFe);
  THorse.Get(RSModeloNFeStatusRoute, GetModeloStatusServicoNFe);
  THorse.Get(RSModeloNFeConsultaRoute, GetModeloConsultaNFe);
  THorse.Get(RSModeloNFeInutilizacaoRoute, GetModeloInutilizacaoNFe);
  THorse.Get(RSModeloNFeCancelamentoRoute, GetModeloCancelamentoNFe);
  THorse.Get(RSModeloNFeNFeFromXMLRoute, GetModeloNFeFromXML);
  THorse.Get(RSModeloNFeNFeToXMLRoute, GetModeloNFeToXML);
  THorse.Get(RSModeloNFeValidarRegrasRoute, GetModeloValidarRegrasNFe);
  THorse.Get(RSModeloNFeDanfeEventoRoute, GetModeloDanfeEvento);

  THorse.Post(RSNFeEventosRoute, PostEventos);
  THorse.Post(RSNFeDistribuicaoRoute, PostDistribuicao);
  THorse.Post(RSNFeDANFeRoute, PostDANFe);
  THorse.Post(RSNFeNFeRoute, PostNFe);
  THorse.Post(RSNFeStatusRoute, PostStatusServicoNFe);
  THorse.Post(RSNFeConsultaRoute, PostConsultaNFe);
  THorse.Post('/nfe/consulta-recibo', PostConsultaReciboNFe);
  THorse.Post(RSNFeInutilizacaoRoute, PostInutilizacaoNFe);
  THorse.Post(RSNFeCancelamentoRoute, PostCancelamentoNFe);
  THorse.Post(RSNFeNFeFromXMLRoute, PostNFeFromXML);
  THorse.Post(RSNFeNFeToXMLRoute, PostNFeToXML);
  THorse.Post(RSNFeValidarRegrasRoute, PostValidarRegrasNFe);
  THorse.Post(RSNFeDanfeEventoRoute, PostDanfeEvento);

  // Debug temporário
  THorse.Post('/nfe/debug-config', PostDebugConfig);
  THorse.Post('/nfe/nfe-lote', PostNFeLote);
end;

end.
