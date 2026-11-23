unit route.acbr.nfe;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.nfe, jsonconvert, fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

// Get
procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDist(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// Post
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

// Get - Modelos adicionais
procedure GetModeloStatusServicoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloInutilizacaoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCancelamentoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloValidarRegrasNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDanfeEvento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;
procedure PostNFeLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDanfeEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDanfeEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultaCadastroNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaCadastroNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEmailNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEmailNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetNFePDF(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

implementation

function TryParseJSONObject(Req: THorseRequest; Res: THorseResponse; out O: TJSONObject): Boolean;
var
  LData: TJSONData;
begin
  Result := False;
  O := nil;
  try
    LData := GetJSON(Req.Body);
    if not (LData is TJSONObject) then
    begin
      LData.Free;
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSStatusField, RSStatusErro, RSMessageField, RSNotJSONObjectError])));
      Exit;
    end;
    O := TJSONObject(LData);
    Result := True;
  except
    on E: Exception do
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSStatusField, RSStatusErro, RSMessageField, RSJSONParseError + E.Message])));
  end;
end;

procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    LJson := Ac.ModelConfig;
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
    LJson := Ac.ModelEvento;
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(Ac.ModelDistribuicao);
  finally
    Ac.Free;
  end;
end;

procedure PostEventos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  LEventos: TJSONArray;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    LEventos := O.Extract(RSEventosField) as TJSONArray;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send(Ac.Evento(LEventos));
    finally
      LEventos.Free;
    end;
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
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
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
  O, ErrObj, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
  Step: string;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  try
    Step := 'CreateTACBRBridgeNFe';
    Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
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
      ErrObj.Add(RSStatusField, RSStatusErro);
      ErrObj.Add(RSErrorField, 'Excecao em PostNFe (' + Step + '): ' + E.Message);
      ErrObj.Add(RSMessageField, 'Excecao em PostNFe (' + Step + '): ' + E.Message);
      ErrObj.Add('ClassName', E.ClassName);
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(ErrObj));
    end;
  end;
end;

procedure PostDANFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  try
    Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
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
  except
    on E: Exception do
      Res.Status(500).ContentType(TMimeTypes.ApplicationJSON.ToString)
        .Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSStatusField, RSStatusErro, RSErrorField, E.Message])));
  end;
end;

procedure PostStatusServicoNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.StatusServico(O)));
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
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Consulta(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultaReciboNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
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
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Inutilizacao(O)));
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
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Cancelamento(O)));
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
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.NFeFromXML(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostNFeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, ErrObj: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  try
    Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.NFeToXML(O)));
    finally
      O.Free;
      Ac.Free;
    end;
  except
    on E: Exception do
    begin
      ErrObj := TJSONObject.Create;
      ErrObj.Add(RSStatusField, RSStatusErro);
      ErrObj.Add(RSMessageField, 'Excecao em PostNFeToXML: ' + E.Message);
      ErrObj.Add('ClassName', E.ClassName);
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(ErrObj));
    end;
  end;
end;

procedure PostValidarRegrasNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ValidarRegras(O)));
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
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.DanfeEvento(O)));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelStatusServico));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelConsulta));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelInutilizacao));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelCancelamento));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelNFeFromXML));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelNFeToXML));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelNFe));
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
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelDanfeEvento));
  finally
    Ac.Free;
  end;
end;

procedure PostNFeLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, ErrObj, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
  LNFes: TJSONArray;
  Step: string;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  try
    Step := 'CreateTACBRBridgeNFe';
    Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
    try
      Step := 'ExtractNFesArray';
      LNFes := O.Find('NFes', jtArray) as TJSONArray;
      if LNFes = nil then
      begin
        ErrObj := TJSONObject.Create;
        ErrObj.Add(RSStatusField, RSStatusErro);
        ErrObj.Add(RSErrorField, 'Campo NFes (array) nao encontrado no payload');
        ErrObj.Add(RSMessageField, 'Campo NFes (array) nao encontrado no payload');
        Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(ErrObj));
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
      ErrObj.Add(RSStatusField, RSStatusErro);
      ErrObj.Add(RSErrorField, 'Excecao em PostNFeLote (' + Step + '): ' + E.Message);
      ErrObj.Add(RSMessageField, 'Excecao em PostNFeLote (' + Step + '): ' + E.Message);
      ErrObj.Add('ClassName', E.ClassName);
      Res.Status(400).ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(ErrObj));
    end;
  end;
end;

procedure PostDanfeEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.DanfeEscPos(O);
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

procedure GetModeloDanfeEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelDanfeEscPos));
  finally
    Ac.Free;
  end;
end;

procedure PostConsultaCadastroNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ConsultaCadastro(O);
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

procedure GetModeloConsultaCadastroNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelConsultaCadastro));
  finally
    Ac.Free;
  end;
end;

procedure PostEmailNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.EnviarEmail(O);
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

procedure GetModeloEmailNFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSON;
begin
  Ac := TACBRModelosJSON.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.ModelEmail));
  finally
    Ac.Free;
  end;
end;

procedure GetNFePDF(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  chave, pdfDir, filePath: string;
begin
  chave := Req.Params[RSChaveField];
  pdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
  filePath := pdfDir + chave + '-nfe.pdf';
  if not FileExists(filePath) then
    filePath := pdfDir + 'NFe' + chave + '-nfe.pdf';
  if not FileExists(filePath) then
    filePath := pdfDir + chave + '.pdf';

  if FileExists(filePath) then
    Res.Download(filePath, chave + '-danfe.pdf')
  else
    Res.Status(404).ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send('{"error":"Arquivo PDF nao encontrado para a chave informada."}');
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
  THorse.Get(RSModeloNFeDanfeEscPosRoute, GetModeloDanfeEscPos);
  THorse.Get(RSModeloNFeConsultaCadastroRoute, GetModeloConsultaCadastroNFe);
  THorse.Get(RSModeloNFeEmailRoute, GetModeloEmailNFe);
  THorse.Get(RSNFePDFRoute, GetNFePDF);

  THorse.Post(RSNFeEventosRoute, PostEventos);
  THorse.Post(RSNFeDistribuicaoRoute, PostDistribuicao);
  THorse.Post(RSNFeDANFeRoute, PostDANFe);
  THorse.Post(RSNFeDanfeEscPosRoute, PostDanfeEscPos);
  THorse.Post(RSNFeNFeRoute, PostNFe);
  THorse.Post(RSNFeStatusRoute, PostStatusServicoNFe);
  THorse.Post(RSNFeConsultaRoute, PostConsultaNFe);
  THorse.Post(RSNFeConsultaCadastroRoute, PostConsultaCadastroNFe);
  THorse.Post(RSNFeEmailRoute, PostEmailNFe);
  THorse.Post(RSNFeConsultaReciboRoute, PostConsultaReciboNFe);
  THorse.Post(RSNFeInutilizacaoRoute, PostInutilizacaoNFe);
  THorse.Post(RSNFeCancelamentoRoute, PostCancelamentoNFe);
  THorse.Post(RSNFeNFeFromXMLRoute, PostNFeFromXML);
  THorse.Post(RSNFeNFeToXMLRoute, PostNFeToXML);
  THorse.Post(RSNFeValidarRegrasRoute, PostValidarRegrasNFe);
  THorse.Post(RSNFeDanfeEventoRoute, PostDanfeEvento);
  THorse.Post(RSNFeLoteRoute, PostNFeLote);
end;

end.
