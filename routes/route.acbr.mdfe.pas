unit route.acbr.mdfe;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.mdfe,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

// --- Handlers para Endpoints de Modelos (GET) ---
procedure GetModeloConfigMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetMDFePDFFile(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// --- Handlers para Endpoints de Operacoes (POST) ---
procedure PostEnviarMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEventosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDamdfeMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDamdfeURLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDamdfeEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloValidarRegrasMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostValidarRegrasMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEventoToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEventoToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEmailMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEmailMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

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

procedure GetModeloConfigMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelConfig;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelEvento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelMDFe;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelDistribuicao);
  finally
    AcM.Free;
  end;
end;

procedure GetModeloMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelMDFeFromXML;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelMDFeToXML;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetMDFePDFFile(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Chave, FilePath, PdfDir: string;
begin
  Chave := Req.Params[RSChaveField];
  Chave := StringReplace(Chave, 'MDFe', '', [rfIgnoreCase]);

  PdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
  FilePath := PdfDir + 'MDFe' + Chave + '-mdfe.pdf';
  if not FileExists(FilePath) then
    FilePath := PdfDir + Chave + '-mdfe.pdf';

  if FileExists(FilePath) then
    Res.Download(FilePath, 'damdfe.pdf')
  else
    Res.Status(404).Send('PDF do MDF-e nao encontrado');
end;

procedure PostEnviarMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.MDFe(O);
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

procedure PostEventosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  LEventos: TJSONArray;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
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

procedure PostDamdfeMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Damdfe(O);
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

procedure PostDamdfeURLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Damdfe(O, True);
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

procedure PostDamdfeEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.DamdfeEvento(O);
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

procedure PostDistribuicaoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
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

procedure PostMDFeFromXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.MDFeFromXML(O);
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

procedure PostMDFeToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.MDFeToXML(O);
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

procedure GetModeloStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelStatusServico;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelConsulta;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelCancelamento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelEncerramento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelNaoEncerrados;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostStatusMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.StatusServico(O);
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

procedure PostConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Consulta(O);
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

procedure PostCancelamentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Cancelamento(O);
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

procedure PostEncerramentoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Encerramento(O);
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

procedure PostNaoEncerradosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ConsultarMDFeNaoEnc(O);
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

procedure GetModeloValidarRegrasMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelValidarRegras;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostValidarRegrasMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ValidarRegras(O);
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

procedure GetModeloEventoToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelEvento;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostEventoToXMLMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.EventoToXML(O);
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

procedure GetModeloEmailMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    LJson := AcM.ModelEmail;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostEmailMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeMDFe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeMDFe.Create(TJSONTools.ExtractConfig(O));
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

procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get(RSModeloMDFeConfigRoute, GetModeloConfigMDFe);
  THorse.Get(RSModeloMDFeEventoRoute, GetModeloEventoMDFe);
  THorse.Get(RSModeloMDFeMDFeRoute, GetModeloMDFe);
  THorse.Get(RSModeloMDFeDistribuicaoRoute, GetModeloDistribuicaoMDFe);
  THorse.Get(RSModeloMDFeMDFeFromXMLRoute, GetModeloMDFeFromXMLMDFe);
  THorse.Get(RSModeloMDFeMDFeToXMLRoute, GetModeloMDFeToXMLMDFe);
  THorse.Get(RSMDFePDFRoute, GetMDFePDFFile);
  THorse.Get(RSModeloMDFeStatusRoute, GetModeloStatusMDFe);
  THorse.Get(RSModeloMDFeConsultaRoute, GetModeloConsultaMDFe);
  THorse.Get(RSModeloMDFeCancelamentoRoute, GetModeloCancelamentoMDFe);
  THorse.Get(RSModeloMDFeEncerramentoRoute, GetModeloEncerramentoMDFe);
  THorse.Get(RSModeloMDFeNaoEncerradosRoute, GetModeloNaoEncerradosMDFe);
  THorse.Get(RSModeloMDFeValidarRegrasRoute, GetModeloValidarRegrasMDFe);
  THorse.Get(RSModeloMDFeEventoToXMLRoute, GetModeloEventoToXMLMDFe);
  THorse.Get(RSModeloMDFeEmailRoute, GetModeloEmailMDFe);

  // Endpoints de Operacoes (POST)
  THorse.Post(RSMDFeMDFeRoute, PostEnviarMDFe);
  THorse.Post(RSMDFeEventosRoute, PostEventosMDFe);
  THorse.Post(RSMDFeDAMDFeRoute, PostDamdfeMDFe);
  THorse.Post(RSMDFeDAMDFeURLRoute, PostDamdfeURLMDFe);
  THorse.Post(RSMDFeDistribuicaoRoute, PostDistribuicaoMDFe);
  THorse.Post(RSMDFeMDFeFromXMLRoute, PostMDFeFromXMLMDFe);
  THorse.Post(RSMDFeMDFeToXMLRoute, PostMDFeToXMLMDFe);
  THorse.Post(RSMDFeDAMDFeEventoRoute, PostDamdfeEventoMDFe);
  THorse.Post(RSMDFeStatusRoute, PostStatusMDFe);
  THorse.Post(RSMDFeConsultaRoute, PostConsultaMDFe);
  THorse.Post(RSMDFeCancelamentoRoute, PostCancelamentoMDFe);
  THorse.Post(RSMDFeEncerramentoRoute, PostEncerramentoMDFe);
  THorse.Post(RSMDFeNaoEncerradosRoute, PostNaoEncerradosMDFe);
  THorse.Post(RSMDFeValidarRegrasRoute, PostValidarRegrasMDFe);
  THorse.Post(RSMDFeEventoToXMLRoute, PostEventoToXMLMDFe);
  THorse.Post(RSMDFeEmailRoute, PostEmailMDFe);
end;

end.
