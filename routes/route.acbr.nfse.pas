unit route.acbr.nfse;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.nfse, jsonconvert, fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

// Get - Modelos
procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFSeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloNFSeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// Post
procedure PostEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDANFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNFSeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostNFSeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEventoNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEventoNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultarEventosNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultarEventosNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

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

procedure GetModeloConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
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

procedure GetModeloEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelEmitir;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelConsultarSituacao;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelConsultarLote;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelConsultarNFSePorRps;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelConsultarNFSe;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelCancelar;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelSubstituir;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostEmitir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Emitir(O);
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

procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Gerar(O);
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

procedure PostConsultarSituacao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ConsultarSituacao(O);
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

procedure PostConsultarLote(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ConsultarLote(O);
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

procedure PostConsultarNFSePorRps(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ConsultarNFSePorRps(O);
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

procedure PostConsultarNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ConsultarNFSe(O);
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

procedure PostCancelar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Cancelar(O);
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

procedure PostSubstituir(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Substituir(O);
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

procedure PostDANFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Danfse(O);
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

procedure PostDistribuicao(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
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

procedure GetModeloNFSeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelNFSeFromXML;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure GetModeloNFSeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelNFSeToXML;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostNFSeFromXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.NFSeFromXML(O);
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

procedure PostNFSeToXML(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.NFSeToXML(O);
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

procedure GetModeloEventoNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
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

procedure PostEventoNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.EnviarEvento(O);
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

procedure GetModeloConsultarEventosNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRModelosJSONNFSe;
  LJson: TJSONObject;
begin
  Ac := TACBRModelosJSONNFSe.Create('');
  try
    LJson := Ac.ModelConsultarEventos;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    Ac.Free;
  end;
end;

procedure PostConsultarEventosNFSe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeNFSe;
begin
  if not TryParseJSONObject(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeNFSe.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.ConsultarEventos(O);
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
  THorse.Get(RSModeloNFSeConfigRoute, GetModeloConfig);
  THorse.Get(RSModeloNFSeEmitirRoute, GetModeloEmitir);
  THorse.Get(RSModeloNFSeConsultarSituacaoRoute, GetModeloConsultarSituacao);
  THorse.Get(RSModeloNFSeConsultarLoteRoute, GetModeloConsultarLote);
  THorse.Get(RSModeloNFSeConsultarNFSePorRpsRoute, GetModeloConsultarNFSePorRps);
  THorse.Get(RSModeloNFSeConsultarNFSeRoute, GetModeloConsultarNFSe);
  THorse.Get(RSModeloNFSeCancelarRoute, GetModeloCancelar);
  THorse.Get(RSModeloNFSeSubstituirRoute, GetModeloSubstituir);
  THorse.Get(RSModeloNFSeNFSeFromXMLRoute, GetModeloNFSeFromXML);
  THorse.Get(RSModeloNFSeNFSeToXMLRoute, GetModeloNFSeToXML);
  THorse.Get(RSModeloNFSeEventoRoute, GetModeloEventoNFSe);
  THorse.Get(RSModeloNFSeEventosRoute, GetModeloEventoNFSe);
  THorse.Get(RSModeloNFSeConsultarEventosRoute, GetModeloConsultarEventosNFSe);

  THorse.Post(RSNFSeEmitirRoute, PostEmitir);
  THorse.Post(RSNFSeGerarRoute, PostGerar);
  THorse.Post(RSNFSeConsultarSituacaoRoute, PostConsultarSituacao);
  THorse.Post(RSNFSeConsultarLoteRoute, PostConsultarLote);
  THorse.Post(RSNFSeConsultarNFSePorRpsRoute, PostConsultarNFSePorRps);
  THorse.Post(RSNFSeConsultarNFSeRoute, PostConsultarNFSe);
  THorse.Post(RSNFSeCancelarRoute, PostCancelar);
  THorse.Post(RSNFSeSubstituirRoute, PostSubstituir);
  THorse.Post(RSNFSeDANFSeRoute, PostDANFSe);
  THorse.Post(RSNFSeDistribuicaoRoute, PostDistribuicao);
  THorse.Post(RSNFSeConsultarEventosRoute, PostConsultarEventosNFSe);
  THorse.Post(RSNFSeNFSeFromXMLRoute, PostNFSeFromXML);
  THorse.Post(RSNFSeNFSeToXMLRoute, PostNFSeToXML);
  THorse.Post(RSNFSeEventoRoute, PostEventoNFSe);
  THorse.Post(RSNFSeEventosRoute, PostEventoNFSe);
end;

end.
