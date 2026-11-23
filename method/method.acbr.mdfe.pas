{%RunFlags MESSAGES+}

unit method.acbr.mdfe;

{$mode Delphi}
{$M+}

interface

uses
  streamtools,
  RTTI,
  ACBrMDFe,
  ACBrMDFeManifestos,
  ACBrMDFe.Classes,
  ACBrMDFeDAMDFeFPDF,
  ACBrMDFe.EnvEvento,
  ACBrDFeSSL,
  ACBrMDFeWebServices,
  ACBrMDFe.Conversao,
  pcnConversao,
  Variants,
  fpjson, jsonconvert,
  Base64, jsonparser,
  ACBrDFeConfiguracoes,
  ACBrMDFeConfiguracoes,
  ACBrMail,
  ACBrDFe.Conversao,
  Classes, SysUtils, DateUtils,
  resource.strings.global,
  synacode,
  resource.strings.msg;

type

  { TACBRBridgeMDFe }

  TACBRBridgeMDFe = class
  private
    fcfg: string;
    facbr: TACBrMDFe;
    fdamdfe: TACBrMDFeDAMDFeFPDF;
    procedure CarregaConfig(const AllowEmpty: Boolean = False);
    function HasUsableCertificate: Boolean;
    function DecodeXMLValue(const rawValue: string): string;
    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
    procedure ApplyLogoFromJSON(const jsonData: TJSONObject; const pdfDir: string; out tempLogoFile: string);
    procedure CleanupTempLogo(var tempLogoFile: string);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function Evento(const jEventos: TJSONArray): string;
    function Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
    function Damdfe(const xmlData: TJSONObject; const OnlyURL: Boolean = False): TJSONObject;
    function DamdfeEvento(const xmlEvento: TJSONObject): TJSONObject;
    function MDFe(const jMDFe: TJSONObject): TJSONObject;
    function MDFeFromXML(const jXML: TJSONObject): TJSONObject;
    function MDFeToXML(const jMDFe: TJSONObject): TJSONObject;
    function StatusServico(const jStatus: TJSONObject): TJSONObject;
    function Consulta(const jConsulta: TJSONObject): TJSONObject;
    function Cancelamento(const jCancelamento: TJSONObject): TJSONObject;
    function Encerramento(const jEncerramento: TJSONObject): TJSONObject;
    function ConsultarMDFeNaoEnc(const jConsulta: TJSONObject): TJSONObject;
    function ValidarRegras(const jMDFe: TJSONObject): TJSONObject;
    function EventoToXML(const jEvento: TJSONObject): TJSONObject;
    function EnviarEmail(const jEmail: TJSONObject): TJSONObject;

    function TesteConfig: boolean;
  end;

  { TACBRModelosJSONMDFe }

  TACBRModelosJSONMDFe = class(TACBRBridgeMDFe)
  private
  public
    function ModelConfig: TJSONObject;
    function ModelEvento: TJSONObject;
    function ModelDistribuicao: string;
    function ModelMDFe: TJSONObject;
    function ModelMDFeFromXML: TJSONObject;
    function ModelMDFeToXML: TJSONObject;
    function ModelValidarRegras: TJSONObject;
    function ModelStatusServico: TJSONObject;
    function ModelConsulta: TJSONObject;
    function ModelCancelamento: TJSONObject;
    function ModelEncerramento: TJSONObject;
    function ModelNaoEncerrados: TJSONObject;
    function ModelEmail: TJSONObject;
  end;

implementation

{ TACBRModelosJSONMDFe }

function TACBRModelosJSONMDFe.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.Configuracoes, 'Erro ao gerar modelo de configuracao do MDF-e');
end;

function TACBRModelosJSONMDFe.ModelEvento: TJSONObject;
begin
  facbr.EventoMDFe.Evento.Clear;
  facbr.EventoMDFe.Evento.New;
  try
    Result := TJSONTools.SafeObjToJson(facbr.EventoMDFe, 'Erro ao gerar modelo de evento do MDF-e');
  finally
    facbr.EventoMDFe.Evento.Clear;
  end;
end;

function TACBRModelosJSONMDFe.ModelMDFe: TJSONObject;
var
  Manifesto: TManifesto;
begin
  facbr.Manifestos.Clear;
  Manifesto := facbr.Manifestos.Add;
  try
    Result := TJSONTools.SafeObjToJson(Manifesto.MDFe, 'Erro ao gerar modelo do MDF-e');
  finally
    facbr.Manifestos.Clear;
  end;
end;

function TACBRModelosJSONMDFe.ModelDistribuicao: string;
begin
  Result := TJSONTools.SafeObjToJsonString(facbr.WebServices.DistribuicaoDFe, 'Erro ao gerar modelo de distribuicao do MDF-e');
end;

function TACBRModelosJSONMDFe.ModelMDFeFromXML: TJSONObject;
begin
  Result := ModelMDFe;
end;

function TACBRModelosJSONMDFe.ModelMDFeToXML: TJSONObject;
begin
  Result := ModelMDFe;
end;


{ TACBRBridgeMDFe }

procedure SetJSONFieldStr(const Obj: TJSONObject; const Key, Value: string);
begin
  if not Assigned(Obj) then
    Exit;
  Obj.Delete(Key);
  Obj.Add(Key, Value);
end;

procedure SetJSONFieldInt(const Obj: TJSONObject; const Key: string; const Value: Integer);
begin
  if not Assigned(Obj) then
    Exit;
  Obj.Delete(Key);
  Obj.Add(Key, Value);
end;

procedure SetJSONFieldBool(const Obj: TJSONObject; const Key: string; const Value: Boolean);
begin
  if not Assigned(Obj) then
    Exit;
  Obj.Delete(Key);
  Obj.Add(Key, Value);
end;

procedure TACBRBridgeMDFe.CarregaConfig(const AllowEmpty: Boolean = False);
var
  O: TJSONObject;
  LPfx: AnsiString;
  tempData: TJSONData;
  logoCfg, LDefaultRootSchemas, LCurSchemas: string;
begin
  if (Trim(fcfg) = '') and (not AllowEmpty) then
    raise Exception.Create(RSConfigEmptyError);

  LDefaultRootSchemas := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + RSSchemasDir);

  if Trim(fcfg) <> '' then
  begin
    try
      O := GetJSON(fcfg) as TJSONObject;
      try
        TJSONTools.JsonToObj(O, facbr.Configuracoes);

        tempData := O.Find('DAMDFE');
        if not Assigned(tempData) then
          tempData := O.Find('DAMDFe');
        if Assigned(tempData) and (tempData.JSONType = jtObject) then
          TJSONTools.JsonToObj(TJSONObject(tempData), fdamdfe);

        tempData := O.Find('Logo');
        if not Assigned(tempData) then
          tempData := O.Find('logo');
        if Assigned(tempData) and (tempData.JSONType = jtString) then
        begin
          logoCfg := Trim(tempData.AsString);
          if logoCfg <> '' then
            fdamdfe.Logo := logoCfg;
        end;

        LPfx := TJSONTools.ExtractCertificadoPFX(O);
        if LPfx <> '' then
          facbr.Configuracoes.Certificados.DadosPFX := LPfx;
      finally
        O.Free;
      end;
    except
      on E: Exception do
        raise Exception.Create(RSConfigReadError + E.Message);
    end;
    fcfg := '';
  end;

  with facbr.Configuracoes.Geral do
  begin
    SSLLib := libOpenSSL;
    SSLCryptLib := cryOpenSSL;
    SSLHttpLib := httpOpenSSL;
    SSLXmlSignLib := xsLibXml2;
  end;

  LCurSchemas := ExcludeTrailingPathDelimiter(Trim(facbr.Configuracoes.Arquivos.PathSchemas));
  if (LCurSchemas = '') or SameText(LCurSchemas, LDefaultRootSchemas) then
    facbr.Configuracoes.Arquivos.PathSchemas := LDefaultRootSchemas + PathDelim + 'MDFe' + PathDelim;
end;

function TACBRBridgeMDFe.HasUsableCertificate: Boolean;
var
  LPfxPath: string;
begin
  LPfxPath := Trim(facbr.Configuracoes.Certificados.ArquivoPFX);
  Result := (Length(facbr.Configuracoes.Certificados.DadosPFX) > 0) or
            ((LPfxPath <> '') and FileExists(LPfxPath));
end;

function TACBRBridgeMDFe.DecodeXMLValue(const rawValue: string): string;
var
  trimmed: string;
begin
  Result := '';
  trimmed := Trim(rawValue);
  if trimmed = '' then
    Exit;

  if trimmed[1] = '<' then
  begin
    Result := trimmed;
    Exit;
  end;

  try
    Result := DecodeStringBase64(trimmed);
  except
    on E: Exception do
      raise Exception.Create('A string XML em base64 e invalida: ' + E.Message);
  end;
end;

function TACBRBridgeMDFe.ReadXMLFromJSON(const jsonData: TJSONObject): string;
begin
  Result := TJSONTools.ReadXMLFromJSON(jsonData, ['xml_mdfe', 'MDFeXML', 'XMLMDFe', 'xmlMdfe', 'XMLEvento', 'xml_evento', 'xmlEvento']);
end;

procedure TACBRBridgeMDFe.ApplyLogoFromJSON(
  const jsonData: TJSONObject;
  const pdfDir: string;
  out tempLogoFile: string
);
var
  logoNode, damdfeNode: TJSONData;
  logoStr, b64Payload, ext, guidStr: string;
  decodedBytes: AnsiString;
  semiPos: Integer;
  hasDataUri, isImageMagic: Boolean;
  LGuid: TGUID;
  fs: TFileStream;
begin
  tempLogoFile := '';
  logoStr := '';

  if Assigned(jsonData) then
  begin
    logoNode := jsonData.Find('Logo');
    if not Assigned(logoNode) then logoNode := jsonData.Find('logo');
    if not Assigned(logoNode) then logoNode := jsonData.Find('LogoBase64');
    if not Assigned(logoNode) then logoNode := jsonData.Find('logoBase64');
    if not Assigned(logoNode) then logoNode := jsonData.Find('logo_base64');
    if not Assigned(logoNode) then logoNode := jsonData.Find('logomarca');

    if not Assigned(logoNode) then
    begin
      damdfeNode := jsonData.Find('DAMDFE');
      if not Assigned(damdfeNode) then damdfeNode := jsonData.Find('DAMDFe');
      if Assigned(damdfeNode) and (damdfeNode.JSONType = jtObject) then
      begin
        logoNode := TJSONObject(damdfeNode).Find('Logo');
        if not Assigned(logoNode) then logoNode := TJSONObject(damdfeNode).Find('logo');
      end;
    end;

    if Assigned(logoNode) and (logoNode.JSONType = jtString) then
      logoStr := Trim(logoNode.AsString);
  end;

  if logoStr = '' then
    logoStr := Trim(fdamdfe.Logo);

  if logoStr = '' then
    Exit;

  hasDataUri := False;
  b64Payload := logoStr;
  semiPos := Pos('base64,', LowerCase(b64Payload));
  if semiPos > 0 then
  begin
    hasDataUri := True;
    b64Payload := Trim(Copy(b64Payload, semiPos + 7, Length(b64Payload)));
  end;

  if (not hasDataUri) and FileExists(logoStr) then
  begin
    fdamdfe.Logo := logoStr;
    Exit;
  end;

  if hasDataUri or (Length(b64Payload) > 32) then
  begin
    try
      b64Payload := StringReplace(b64Payload, #13, '', [rfReplaceAll]);
      b64Payload := StringReplace(b64Payload, #10, '', [rfReplaceAll]);
      b64Payload := StringReplace(b64Payload, ' ', '', [rfReplaceAll]);
      decodedBytes := synacode.DecodeBase64(AnsiString(b64Payload));

      ext := '';
      isImageMagic := False;
      if (Length(decodedBytes) >= 8) and
         (Byte(decodedBytes[1]) = $89) and (Byte(decodedBytes[2]) = $50) and
         (Byte(decodedBytes[3]) = $4E) and (Byte(decodedBytes[4]) = $47) then
      begin
        ext := '.png';
        isImageMagic := True;
      end
      else if (Length(decodedBytes) >= 3) and
              (Byte(decodedBytes[1]) = $FF) and (Byte(decodedBytes[2]) = $D8) and
              (Byte(decodedBytes[3]) = $FF) then
      begin
        ext := '.jpg';
        isImageMagic := True;
      end
      else if (Length(decodedBytes) >= 14) and
              (Byte(decodedBytes[1]) = $42) and (Byte(decodedBytes[2]) = $4D) then
      begin
        ext := '.bmp';
        isImageMagic := True;
      end
      else if (Length(decodedBytes) >= 6) and
              (Byte(decodedBytes[1]) = $47) and (Byte(decodedBytes[2]) = $49) and
              (Byte(decodedBytes[3]) = $46) and (Byte(decodedBytes[4]) = $38) then
      begin
        ext := '.gif';
        isImageMagic := True;
      end
      else if hasDataUri and (Length(decodedBytes) > 0) then
      begin
        ext := '.png';
        isImageMagic := True;
      end;

      if isImageMagic then
      begin
        if not DirectoryExists(pdfDir) then
          CreateDir(pdfDir);
        CreateGUID(LGuid);
        guidStr := StringReplace(GUIDToString(LGuid), '{', '', [rfReplaceAll]);
        guidStr := StringReplace(guidStr, '}', '', [rfReplaceAll]);
        tempLogoFile := IncludeTrailingPathDelimiter(pdfDir) + 'logo_' + guidStr + ext;

        fs := TFileStream.Create(tempLogoFile, fmCreate);
        try
          fs.WriteBuffer(PAnsiChar(decodedBytes)^, Length(decodedBytes));
        finally
          fs.Free;
        end;

        fdamdfe.Logo := tempLogoFile;
        Exit;
      end;
    except
      tempLogoFile := '';
    end;
  end;

  if not hasDataUri then
    fdamdfe.Logo := logoStr;
end;

procedure TACBRBridgeMDFe.CleanupTempLogo(var tempLogoFile: string);
begin
  if tempLogoFile <> '' then
  begin
    if fdamdfe.Logo = tempLogoFile then
      fdamdfe.Logo := '';
    if FileExists(tempLogoFile) then
      SysUtils.DeleteFile(tempLogoFile);
    tempLogoFile := '';
  end;
end;

constructor TACBRBridgeMDFe.Create(const Cfg: string);
begin
  facbr := TACBrMDFe.Create(nil);
  fdamdfe := TACBrMDFeDAMDFeFPDF.Create(nil);
  fcfg := Cfg;
  facbr.DAMDFE := fdamdfe;
end;

destructor TACBRBridgeMDFe.Destroy;
begin
  FreeAndNil(facbr);
  FreeAndNil(fdamdfe);
  inherited Destroy;
end;

function TACBRBridgeMDFe.MDFe(const jMDFe: TJSONObject): TJSONObject;
var
  Manifesto: TManifesto;
  Lote, sendExceptionMsg, erroVal, xmlFinal, chClean: string;
  wsXMotivo, wsProtocolo, wsRecibo: string;
  wsCStat: Integer;
  Sincrono: Boolean;
  jOpt: TJSONData;
begin
  CarregaConfig;

  Result := nil;
  Sincrono := True;
  jOpt := jMDFe.Find('sincrono');
  if not Assigned(jOpt) then
    jOpt := jMDFe.Find('Sincrono');
  if Assigned(jOpt) then
  begin
    if jOpt.JSONType = jtBoolean then
      Sincrono := jOpt.AsBoolean
    else if jOpt.JSONType = jtNumber then
      Sincrono := (jOpt.AsInteger <> 0)
    else if jOpt.JSONType = jtString then
      Sincrono := not (SameText(Trim(jOpt.AsString), 'false') or (Trim(jOpt.AsString) = '0'));
  end;

  Lote := '';
  jOpt := jMDFe.Find('Lote');
  if not Assigned(jOpt) then jOpt := jMDFe.Find('lote');
  if not Assigned(jOpt) then jOpt := jMDFe.Find('idLote');
  if Assigned(jOpt) then
  begin
    if jOpt.JSONType = jtString then
      Lote := Trim(jOpt.AsString)
    else if jOpt.JSONType = jtNumber then
      Lote := IntToStr(jOpt.AsInt64);
  end;
  if Lote = '' then
    Lote := '1';

  facbr.Manifestos.Clear;
  Manifesto := facbr.Manifestos.Add;

  try
    if Assigned(jMDFe.Find('MDFe')) then
      TJSONTools.JsonToObj(jMDFe, Manifesto)
    else
      TJSONTools.JsonToObj(jMDFe, Manifesto.MDFe);
  except
    on E: Exception do
    begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro na leitura do objeto JSON do MDF-e: ' +
        E.Message);
      facbr.Manifestos.Clear;
      Exit;
    end;
  end;

  sendExceptionMsg := '';
  try
    try
      facbr.Manifestos.GerarMDFe;
      facbr.Manifestos.Assinar;
      facbr.Manifestos.Validar;
      // SVRS (NT 2024.001 / MDF-e 3.00): MDFeRecepcaoSinc obrigatorio (Sincrono = True por padrao; Imprimir = False)
      facbr.Enviar(Lote, False, Sincrono);
    except
      on E: Exception do
        sendExceptionMsg := E.Message;
    end;

    wsXMotivo := '';
    wsProtocolo := '';
    wsRecibo := '';
    if Sincrono then
    begin
      wsCStat := facbr.WebServices.Enviar.cStat;
      wsXMotivo := Trim(facbr.WebServices.Enviar.xMotivo);
      wsProtocolo := Trim(facbr.WebServices.Enviar.Protocolo);
      wsRecibo := Trim(facbr.WebServices.Enviar.Recibo);
    end
    else
    begin
      wsCStat := facbr.WebServices.Retorno.cStat;
      if wsCStat = 0 then
      begin
        wsCStat := facbr.WebServices.Enviar.cStat;
        wsXMotivo := Trim(facbr.WebServices.Enviar.xMotivo);
      end;
      wsRecibo := Trim(facbr.WebServices.Retorno.Recibo);
      if wsRecibo = '' then
        wsRecibo := Trim(facbr.WebServices.Enviar.Recibo);
    end;

    erroVal := '';
    xmlFinal := '';
    chClean := '';
    if facbr.Manifestos.Count > 0 then
    begin
      erroVal := Trim(facbr.Manifestos.Items[0].ErroValidacao);

      if facbr.Manifestos.Items[0].MDFe.procMDFe.cStat <> 0 then
      begin
        wsCStat := facbr.Manifestos.Items[0].MDFe.procMDFe.cStat;
        if Trim(facbr.Manifestos.Items[0].MDFe.procMDFe.xMotivo) <> '' then
          wsXMotivo := Trim(facbr.Manifestos.Items[0].MDFe.procMDFe.xMotivo);
        if Trim(facbr.Manifestos.Items[0].MDFe.procMDFe.nProt) <> '' then
          wsProtocolo := Trim(facbr.Manifestos.Items[0].MDFe.procMDFe.nProt);
      end;

      xmlFinal := Trim(facbr.Manifestos.Items[0].XML);
      if xmlFinal = '' then
        xmlFinal := Trim(facbr.Manifestos.Items[0].XMLAssinado);
      if xmlFinal = '' then
        xmlFinal := Trim(facbr.Manifestos.Items[0].XMLOriginal);

      chClean := StringReplace(
        Trim(facbr.Manifestos.Items[0].MDFe.infMDFe.ID),
        'MDFe',
        '',
        [rfIgnoreCase]
      );
    end;

    if (sendExceptionMsg <> '') and (wsCStat = 0) and (erroVal = '') then
      raise Exception.Create(sendExceptionMsg);

    if Sincrono then
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Enviar, 'Erro ao enviar MDF-e')
    else
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao enviar MDF-e');

    SetJSONFieldBool(Result, 'sincrono', Sincrono);
    if wsCStat <> 0 then
      SetJSONFieldInt(Result, 'cStat', wsCStat);
    if wsXMotivo <> '' then
      SetJSONFieldStr(Result, 'xMotivo', wsXMotivo);
    if wsProtocolo <> '' then
    begin
      SetJSONFieldStr(Result, 'Protocolo', wsProtocolo);
      SetJSONFieldStr(Result, 'nProt', wsProtocolo);
    end;
    if wsRecibo <> '' then
      SetJSONFieldStr(Result, 'Recibo', wsRecibo);
    if chClean <> '' then
    begin
      SetJSONFieldStr(Result, 'chave', chClean);
      SetJSONFieldStr(Result, 'chMDFe', chClean);
      SetJSONFieldStr(Result, 'ChaveMDFe', chClean);
    end;
    if xmlFinal <> '' then
    begin
      SetJSONFieldStr(Result, 'xml_autorizado', EncodeStringBase64(xmlFinal));
      SetJSONFieldStr(Result, 'XML', xmlFinal);
    end;
    if (sendExceptionMsg <> '') and (wsCStat = 0) then
    begin
      SetJSONFieldStr(Result, RSStatusField, RSStatusErro);
      SetJSONFieldStr(Result, RSMessageField, sendExceptionMsg);
      if erroVal <> '' then
        SetJSONFieldStr(Result, RSErroValidacaoField, erroVal);
    end;
  finally
    facbr.Manifestos.Clear;
  end;
end;

function TACBRBridgeMDFe.Evento(const jEventos: TJSONArray): string;
var
  objEvento: TInfEventoCollectionItem;
  oEvento: TJSONObject;
  I: integer;
  InfEventoData: TJSONData;
  InfEvento: TJSONObject;
  XmlBase64: TJSONData;
  xmlStr: string;
begin
  CarregaConfig;
  Result := '';
  facbr.EventoMDFe.Evento.Clear;

  for I := 0 to jEventos.Count - 1 do
  begin
    oEvento := jEventos.Items[i] as TJSONObject;
    InfEventoData := oEvento.Find('InfEvento');
    if not Assigned(InfEventoData) then
      InfEventoData := oEvento.Find('infEvento');
    if Assigned(InfEventoData) and (InfEventoData.JSONType = jtObject) then
      InfEvento := TJSONObject(InfEventoData)
    else
      InfEvento := oEvento;

    XmlBase64 := InfEvento.Find('LoadXML');
    if not Assigned(XmlBase64) then
      XmlBase64 := oEvento.Find('LoadXML');
    if Assigned(XmlBase64) and (Trim(XmlBase64.AsString) <> '') then
    begin
      xmlStr := Trim(XmlBase64.AsString);
      if xmlStr[1] = '<' then
        facbr.Manifestos.LoadFromString(xmlStr)
      else
        facbr.Manifestos.LoadFromString(Base64.DecodeStringBase64(xmlStr));
      InfEvento.Delete('LoadXML');
      oEvento.Delete('LoadXML');
    end;

    objEvento := facbr.EventoMDFe.Evento.New;
    if InfEvento = oEvento then
      TJSONTools.JsonToObj(oEvento, objEvento.InfEvento)
    else
      TJSONTools.JsonToObj(oEvento, objEvento);

    with objEvento.InfEvento do
    begin
      if dhEvento = 0 then dhEvento := Now;
      if (CNPJCPF = '') and (Length(chMDFe) >= 20) then CNPJCPF := Copy(chMDFe, 7, 14);
      if (cOrgao = 0) and (Length(chMDFe) >= 2) then cOrgao := StrToIntDef(Copy(chMDFe, 1, 2), 0);
      if nSeqEvento <= 0 then nSeqEvento := 1;
    end;
  end;

  facbr.EnviarEvento(1);
  Result := TJSONTools.SafeObjToJsonString(
    facbr.WebServices.EnvEvento, 'Erro ao enviar evento de MDF-e');
end;

function TACBRBridgeMDFe.Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
var
  objDistribuicao: TDistribuicaoDFe;
begin
  CarregaConfig;

  Result := nil;
  objDistribuicao := facbr.WebServices.DistribuicaoDFe;

  if Assigned(jDistribuicao) then
    TJSONTools.JsonToObj(jDistribuicao, objDistribuicao);

  objDistribuicao.CNPJCPF := Trim(objDistribuicao.CNPJCPF);
  objDistribuicao.ultNSU := Trim(objDistribuicao.ultNSU);
  objDistribuicao.NSU := Trim(objDistribuicao.NSU);
  objDistribuicao.chMDFe := Trim(objDistribuicao.chMDFe);

  try
    objDistribuicao.Executar;
  except
    on E: Exception do
    begin
      if objDistribuicao.RetDistDFeInt.cStat <> 0 then
        Result := TJSONObject(TJSONTools.ObjToJson(
          objDistribuicao.RetDistDFeInt))
      else
      begin
        Result := TJSONObject.Create;
        Result.Add(RSErrorField, E.Message);
      end;
      Exit;
    end;
  end;

  Result := TJSONObject(TJSONTools.ObjToJson(objDistribuicao.RetDistDFeInt));
end;

function TACBRBridgeMDFe.Damdfe(const xmlData: TJSONObject; const OnlyURL: Boolean = False): TJSONObject;
var
  arquivofinal: string;
  stringXml: string;
  tamanho: integer;
  id: TJSONString;
  fileName: string;
  pdfDir: string;
  chClean: string;
  tempLogoFile: string;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;
  tempLogoFile := '';

  try
    stringXml := ReadXMLFromJSON(xmlData);
  except
    on E: Exception do
    begin
      Result.Add(RSErrorField, E.Message);
      Exit;
    end;
  end;

  facbr.Manifestos.Clear;
  try
    try
      facbr.Manifestos.LoadFromString(stringXml);
    except
      on E: Exception do
      begin
        Result.Add(RSErrorField, RSXMLReadError + E.Message);
        Exit;
      end;
    end;

    stringXml := '';

    if facbr.Manifestos.Count = 0 then
    begin
      Result.Add(RSErrorField, 'Nenhum MDF-e foi carregado a partir do XML.');
      Exit;
    end;

    fdamdfe.Cancelada := (facbr.Manifestos.Items[0].MDFe.procMDFe.cStat in [101, 151, 155]);

    fdamdfe.MostraPreview := False;
    fdamdfe.MostraStatus := False;
    fdamdfe.MostraSetup := False;

    pdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
    if not DirectoryExists(pdfDir) then
      CreateDir(pdfDir);

    ApplyLogoFromJSON(xmlData, pdfDir, tempLogoFile);

    chClean := StringReplace(facbr.Manifestos.Items[0].MDFe.infMDFe.ID, 'MDFe', '', [rfIgnoreCase]);
    fileName := pdfDir + chClean + '-mdfe.pdf';
    if FileExists(fileName) then
      SysUtils.DeleteFile(fileName);

    try
      fdamdfe.PathPDF := pdfDir;
      facbr.DAMDFE := fdamdfe;
      facbr.Manifestos.ImprimirPDF;

      if not FileExists(fileName) then
        fileName := fdamdfe.ArquivoPDF;
      if (fileName = '') or (not FileExists(fileName)) then
      begin
        fileName := pdfDir + facbr.Manifestos.Items[0].MDFe.infMDFe.ID + '-mdfe.pdf';
        if not FileExists(fileName) then
          fileName := pdfDir + chClean + '-mdfe.pdf';
      end;

      if not FileExists(fileName) then
      begin
        Result.Add(RSErrorField, RSPDFGenerationError + ': Arquivo PDF nao foi gerado pelo ACBr.');
        Exit;
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSErrorField, RSPDFGenerationError + ': ' + E.Message);
        Exit;
      end;
    end;

    if not OnlyURL then
    begin
      try
        arquivofinal := FileToStringBase64(fileName, False, tamanho);
        Result.Add(RSPDFField, arquivofinal);
        Result.Add(RSTamanhoField, tamanho.ToString);
      except
        on E: Exception do
        begin
          Result.Add(RSErrorField, E.Message);
          Exit;
        end;
      end;
    end;

    Result.Add(RSChaveField, chClean);
    Result.Add(RSURLField, '/mdfe/pdf/' + chClean);

    if xmlData.Find(RSIDField, id) then
      Result.Add(RSIDField, id.AsString);
  finally
    CleanupTempLogo(tempLogoFile);
    facbr.Manifestos.Clear;
  end;
end;

function TACBRBridgeMDFe.DamdfeEvento(const xmlEvento: TJSONObject): TJSONObject;
var
  arquivofinal: string;
  stringXml, mdfeXmlStr: string;
  evtXmlNode, mdfeXmlNode: TJSONData;
  tamanho: integer;
  id: TJSONString;
  fileName: string;
  pdfDir: string;
  tempLogoFile: string;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;
  tempLogoFile := '';

  try
    evtXmlNode := xmlEvento.Find('XMLEvento');
    if (not Assigned(evtXmlNode)) or (Trim(evtXmlNode.AsString) = '') then
      evtXmlNode := xmlEvento.Find('xml_evento');
    if (not Assigned(evtXmlNode)) or (Trim(evtXmlNode.AsString) = '') then
      evtXmlNode := xmlEvento.Find('xmlEvento');

    if Assigned(evtXmlNode) and (Trim(evtXmlNode.AsString) <> '') then
      stringXml := DecodeXMLValue(evtXmlNode.AsString)
    else
      stringXml := ReadXMLFromJSON(xmlEvento);
  except
    on E: Exception do
    begin
      Result.Add(RSErrorField, E.Message);
      Exit;
    end;
  end;

  facbr.Manifestos.Clear;
  facbr.EventoMDFe.Evento.Clear;
  try
    mdfeXmlNode := xmlEvento.Find('XMLMDFe');
    if (not Assigned(mdfeXmlNode)) or (Trim(mdfeXmlNode.AsString) = '') then
      mdfeXmlNode := xmlEvento.Find('xmlMdfe');
    if (not Assigned(mdfeXmlNode)) or (Trim(mdfeXmlNode.AsString) = '') then
      mdfeXmlNode := xmlEvento.Find('xml_mdfe');
    if (not Assigned(mdfeXmlNode)) or (Trim(mdfeXmlNode.AsString) = '') then
      mdfeXmlNode := xmlEvento.Find('MDFeXML');
    if (not Assigned(mdfeXmlNode)) or (Trim(mdfeXmlNode.AsString) = '') then
      mdfeXmlNode := xmlEvento.Find(RSXMLField);
    if (not Assigned(mdfeXmlNode)) or (Trim(mdfeXmlNode.AsString) = '') then
      mdfeXmlNode := xmlEvento.Find(RSXmlKey);

    if Assigned(mdfeXmlNode) and (Trim(mdfeXmlNode.AsString) <> '') then
    begin
      try
        mdfeXmlStr := DecodeXMLValue(mdfeXmlNode.AsString);
        if (mdfeXmlStr <> '') and (mdfeXmlStr <> stringXml) then
          facbr.Manifestos.LoadFromString(mdfeXmlStr);
      except
        on E: Exception do
        begin
          Result.Add(RSErrorField, 'Erro ao carregar XML base do MDF-e para o evento: ' + E.Message);
          Exit;
        end;
      end;
    end;

    try
      facbr.EventoMDFe.LerXMLFromString(stringXml);
    except
      on E: Exception do
      begin
        Result.Add(RSErrorField, 'Erro ao carregar XML de evento MDF-e: ' + E.Message);
        Exit;
      end;
    end;

    stringXml := '';

    if facbr.EventoMDFe.Evento.Count = 0 then
    begin
      Result.Add(RSErrorField, 'Nenhum evento MDF-e foi carregado a partir do XML.');
      Exit;
    end;

    if facbr.Manifestos.Count = 0 then
      facbr.Manifestos.Add.MDFe.infMDFe.ID := 'MDFe' + facbr.EventoMDFe.Evento.Items[0].InfEvento.chMDFe;

    fdamdfe.MostraPreview := False;
    fdamdfe.MostraStatus := False;
    fdamdfe.MostraSetup := False;

    pdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
    if not DirectoryExists(pdfDir) then
      CreateDir(pdfDir);

    ApplyLogoFromJSON(xmlEvento, pdfDir, tempLogoFile);

    try
      fdamdfe.PathPDF := pdfDir;
      facbr.DAMDFE := fdamdfe;
      facbr.ImprimirEventoPDF;

      fileName := fdamdfe.ArquivoPDF;
      if (fileName = '') or (not FileExists(fileName)) then
      begin
        fileName := pdfDir + facbr.EventoMDFe.Evento.Items[0].InfEvento.chMDFe + '-procEventoMDFe.pdf';
      end;

      if not FileExists(fileName) then
      begin
        Result.Add(RSErrorField, RSPDFGenerationError + ': Arquivo PDF de evento nao foi gerado.');
        Exit;
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSErrorField, RSPDFGenerationError + ': ' + E.Message);
        Exit;
      end;
    end;

    try
      arquivofinal := FileToStringBase64(fileName, False, tamanho);
    except
      on E: Exception do
      begin
        Result.Add(RSErrorField, E.Message);
        Exit;
      end;
    end;

    Result.Add(RSPDFField, arquivofinal);
    Result.Add(RSChaveField, facbr.EventoMDFe.Evento.Items[0].InfEvento.chMDFe);
    Result.Add(RSTamanhoField, tamanho.ToString);

    if xmlEvento.Find(RSIDField, id) then
      Result.Add(RSIDField, id.AsString);
  finally
    CleanupTempLogo(tempLogoFile);
    facbr.EventoMDFe.Evento.Clear;
    facbr.Manifestos.Clear;
  end;
end;


function TACBRBridgeMDFe.MDFeFromXML(const jXML: TJSONObject): TJSONObject;
var
  xmlBase64: string;
begin
  CarregaConfig(True);
  try
    xmlBase64 := ReadXMLFromJSON(jXML);
    try
      facbr.Manifestos.LoadFromString(xmlBase64);
    except
      on E: Exception do
        raise Exception.Create('Falha no LoadFromString: ' + E.Message);
    end;

    if facbr.Manifestos.Count > 0 then
    begin
      try
        Result := TJSONTools.SafeObjToJson(facbr.Manifestos.Items[0].MDFe, 'Erro no SafeObjToJson');
      except
        on E: Exception do
          raise Exception.Create('Falha no SafeObjToJson interno: ' + E.Message);
      end;

      if Result.Find(RSStatusField) = nil then
      begin
        Result.Delete(RSXMLField);
        Result.Delete(RSXMLOriginalField);
        Result.Delete(RSNomeArqField);
        Result.Delete(RSProtocoloField);
      end;
    end
    else
      Result := TJSONTools.SafeObjToJson(nil, 'Nenhum MDFe carregado do XML.');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'GLOBAL ERROR: ' + E.Message);
  end;
  facbr.Manifestos.Clear;
end;

function TACBRBridgeMDFe.MDFeToXML(const jMDFe: TJSONObject): TJSONObject;
var
  ManifestoMDFe: TManifesto;
  xmlString: string;
  LAssinado: Boolean;
begin
  CarregaConfig(True);

  try
    ManifestoMDFe := facbr.Manifestos.Add;
    if Assigned(jMDFe.Find('MDFe')) then
      TJSONTools.JsonToObj(jMDFe, ManifestoMDFe)
    else
      TJSONTools.JsonToObj(jMDFe, ManifestoMDFe.MDFe);
  except
    on E: Exception do
    begin
      Result := TJSONTools.SafeObjToJson(nil, 'Erro na leitura do objeto JSON para MDFe: ' + E.Message);
      if Assigned(facbr.Manifestos) then facbr.Manifestos.Clear;
      Exit;
    end;
  end;

  try
    facbr.Manifestos.GerarMDFe;
    LAssinado := False;
    if HasUsableCertificate then
    begin
      facbr.Manifestos.Items[0].Assinar;
      LAssinado := True;
    end;
    xmlString := facbr.Manifestos.Items[0].XML;
    if xmlString = '' then
      xmlString := facbr.Manifestos.Items[0].XMLOriginal;

    Result := TJSONObject.Create;
    Result.Add(RSStatusField, RSStatusSucesso);
    Result.Add(RSChaveField, StringReplace(facbr.Manifestos.Items[0].MDFe.infMDFe.ID, 'MDFe', '', [rfIgnoreCase]));
    Result.Add('assinado', LAssinado);
    Result.Add(RSXmlKey, EncodeStringBase64(xmlString));
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao gerar XML do MDFe: ' + E.Message);
  end;

  if Assigned(facbr.Manifestos) then facbr.Manifestos.Clear;
end;

function TACBRBridgeMDFe.TesteConfig: boolean;
begin
  try
    CarregaConfig;
    Result := True;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;


function TACBRBridgeMDFe.StatusServico(const jStatus: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  try
    facbr.WebServices.StatusServico.Executar;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.StatusServico, 'Erro ao consultar status do servico MDF-e');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao consultar status do servico MDF-e: ' + E.Message);
  end;
end;



function TACBRBridgeMDFe.Consulta(const jConsulta: TJSONObject): TJSONObject;
var
  Chave: string;
begin
  CarregaConfig;
  if Assigned(jConsulta) then
    TJSONTools.JsonToObj(jConsulta, facbr.WebServices.Consulta);

  Chave := Trim(facbr.WebServices.Consulta.MDFeChave);
  if (Chave = '') and Assigned(jConsulta) then
  begin
    Chave := Trim(jConsulta.Get('chMDFe', ''));
    if Chave = '' then
      Chave := Trim(jConsulta.Get(RSChaveField, ''));
    facbr.WebServices.Consulta.MDFeChave := Chave;
  end;

  if Chave <> '' then
  begin
    try
      facbr.WebServices.Consulta.Executar;
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consulta, 'Erro na consulta de MDF-e');
    except
      on E: Exception do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro na consulta de MDF-e: ' + E.Message);
    end;
  end
  else
    Result := TJSONTools.SafeObjToJson(nil, 'Chave (MDFeChave) nao informada para consulta de MDF-e.');
end;



function TACBRBridgeMDFe.Cancelamento(const jCancelamento: TJSONObject): TJSONObject;
var
  chMDFe, nProt, xJust, cnpjCpf, xmlBase64: string;
  CancObj: TJSONObject;
begin
  CarregaConfig;
  CancObj := jCancelamento.Extract('cancelamento') as TJSONObject;
  if not Assigned(CancObj) then
    CancObj := jCancelamento;

  try
    try
      chMDFe := CancObj.Get('chMDFe', '');
      if chMDFe = '' then chMDFe := CancObj.Get(RSChaveField, '');
      nProt := CancObj.Get('nProt', '');
      if nProt = '' then nProt := CancObj.Get('protocolo', '');
      xJust := CancObj.Get('xJust', '');
      if xJust = '' then xJust := CancObj.Get('justificativa', '');
      cnpjCpf := CancObj.Get('CNPJCPF', '');
      xmlBase64 := CancObj.Get(RSXmlKey, '');

      facbr.Manifestos.Clear;
      if xmlBase64 <> '' then
        facbr.Manifestos.LoadFromString(DecodeStringBase64(xmlBase64));

      if (facbr.Manifestos.Count > 0) and (nProt = '') then
      begin
        facbr.Cancelamento(xJust, 1);
      end
      else
      begin
        facbr.EventoMDFe.Evento.Clear;
        with facbr.EventoMDFe.Evento.New do
        begin
          infEvento.chMDFe := chMDFe;
          infEvento.CNPJCPF := cnpjCpf;
          infEvento.cOrgao := StrToIntDef(Copy(chMDFe, 1, 2), 0);
          infEvento.dhEvento := Now;
          infEvento.tpEvento := teCancelamento;
          infEvento.nSeqEvento := 1;
          infEvento.detEvento.nProt := nProt;
          infEvento.detEvento.xJust := xJust;
        end;
        facbr.EnviarEvento(1);
      end;

      Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento, 'Cancelamento MDF-e processado');
    except
      on E: Exception do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro no cancelamento de MDF-e: ' + E.Message);
    end;
  finally
    if (CancObj <> jCancelamento) and Assigned(CancObj) then
      CancObj.Free;
    facbr.Manifestos.Clear;
  end;
end;



function TACBRBridgeMDFe.Encerramento(const jEncerramento: TJSONObject): TJSONObject;
var
  chMDFe, nProt, cnpjCpf, dtEncStr: string;
  cUF, cMun: Integer;
  dtEncTmp: TDateTime;
  EncObj: TJSONObject;
begin
  CarregaConfig;
  EncObj := jEncerramento.Extract('encerramento') as TJSONObject;
  if not Assigned(EncObj) then
    EncObj := jEncerramento;

  try
    try
      chMDFe := EncObj.Get('chMDFe', '');
      if chMDFe = '' then chMDFe := EncObj.Get(RSChaveField, '');
      nProt := EncObj.Get('nProt', '');
      if nProt = '' then nProt := EncObj.Get('protocolo', '');
      cnpjCpf := EncObj.Get('CNPJCPF', '');
      if (cnpjCpf = '') and (Length(chMDFe) >= 20) then
        cnpjCpf := Copy(chMDFe, 7, 14);
      cMun := EncObj.Get('cMun', 0);
      cUF := EncObj.Get('cUF', 0);
      if (cUF = 0) and (cMun > 0) then
        cUF := StrToIntDef(Copy(IntToStr(cMun), 1, 2), 0);
      dtEncStr := EncObj.Get('dtEnc', '');
      if dtEncStr = '' then dtEncStr := EncObj.Get('dtEncStr', '');
      if dtEncStr = '' then dtEncStr := EncObj.Get('dhEnc', '');

      facbr.EventoMDFe.Evento.Clear;
      with facbr.EventoMDFe.Evento.New do
      begin
        infEvento.chMDFe := chMDFe;
        infEvento.CNPJCPF := cnpjCpf;
        infEvento.cOrgao := StrToIntDef(Copy(chMDFe, 1, 2), cUF);
        infEvento.dhEvento := Now;
        infEvento.tpEvento := teEncerramento;
        infEvento.nSeqEvento := 1;
        infEvento.detEvento.nProt := nProt;
        if dtEncStr <> '' then
        begin
          if TryISO8601ToDate(dtEncStr, dtEncTmp, True) then
            infEvento.detEvento.dtEnc := Trunc(dtEncTmp)
          else
            infEvento.detEvento.dtEnc := StrToDateDef(dtEncStr, Date);
        end
        else
          infEvento.detEvento.dtEnc := Date;
        infEvento.detEvento.cUF := cUF;
        infEvento.detEvento.cMun := cMun;
      end;

      facbr.EnviarEvento(1);
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento, 'Encerramento MDF-e processado');
    except
      on E: Exception do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro no encerramento de MDF-e: ' + E.Message);
    end;
  finally
    if (EncObj <> jEncerramento) and Assigned(EncObj) then
      EncObj.Free;
  end;
end;



function TACBRBridgeMDFe.ConsultarMDFeNaoEnc(const jConsulta: TJSONObject): TJSONObject;
var
  cnpjCpf: string;
begin
  CarregaConfig;
  if Assigned(jConsulta) then
    TJSONTools.JsonToObj(jConsulta, facbr.WebServices.ConsMDFeNaoEnc);

  cnpjCpf := Trim(facbr.WebServices.ConsMDFeNaoEnc.CNPJCPF);
  if (cnpjCpf = '') and Assigned(jConsulta) then
    cnpjCpf := Trim(jConsulta.Get('cnpj', ''));

  if cnpjCpf = '' then
  begin
    Result := TJSONTools.SafeObjToJson(nil, 'CNPJCPF nao informado para consulta de MDF-e nao encerrados.');
    Exit;
  end;

  try
    facbr.ConsultarMDFeNaoEnc(cnpjCpf);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.ConsMDFeNaoEnc, 'Erro ao consultar MDF-e nao encerrados');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.ConsMDFeNaoEnc, 'Erro ao consultar MDF-e nao encerrados: ' + E.Message);
  end;
end;

function TACBRModelosJSONMDFe.ModelStatusServico: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.WebServices.StatusServico, 'Erro ao gerar modelo de status do MDF-e');
end;

function TACBRModelosJSONMDFe.ModelConsulta: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consulta, 'Erro ao gerar modelo de consulta do MDF-e');
end;

function TACBRModelosJSONMDFe.ModelCancelamento: TJSONObject;
var
  LEvt: TInfEventoCollectionItem;
begin
  facbr.EventoMDFe.Evento.Clear;
  LEvt := facbr.EventoMDFe.Evento.New;
  try
    Result := TJSONTools.SafeObjToJson(LEvt, 'Erro ao gerar modelo de cancelamento do MDF-e');
  finally
    facbr.EventoMDFe.Evento.Clear;
  end;
end;

function TACBRModelosJSONMDFe.ModelEncerramento: TJSONObject;
var
  LEvt: TInfEventoCollectionItem;
begin
  facbr.EventoMDFe.Evento.Clear;
  LEvt := facbr.EventoMDFe.Evento.New;
  try
    Result := TJSONTools.SafeObjToJson(LEvt, 'Erro ao gerar modelo de encerramento do MDF-e');
  finally
    facbr.EventoMDFe.Evento.Clear;
  end;
end;

function TACBRModelosJSONMDFe.ModelNaoEncerrados: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.WebServices.ConsMDFeNaoEnc, 'Erro ao gerar modelo de MDF-e nao encerrados');
end;

function TACBRModelosJSONMDFe.ModelEmail: TJSONObject;
var
  LMail: TACBrMail;
begin
  LMail := TACBrMail.Create(nil);
  try
    Result := TJSONTools.SafeObjToJson(LMail, 'Erro ao gerar modelo de e-mail do MDF-e');
  finally
    LMail.Free;
  end;
end;

function TACBRModelosJSONMDFe.ModelValidarRegras: TJSONObject;
begin
  Result := ModelMDFe;
end;

function TACBRBridgeMDFe.ValidarRegras(const jMDFe: TJSONObject): TJSONObject;
var
  ManifestoMDFe: TManifesto;
  xmlInput, xmlOut, errosRegras: string;
  hasCert, LAssinado: Boolean;
begin
  CarregaConfig(True);
  Result := nil;

  try
    facbr.Manifestos.Clear;
    xmlInput := '';
    try
      xmlInput := ReadXMLFromJSON(jMDFe);
    except
      xmlInput := '';
    end;

    try
      if xmlInput <> '' then
      begin
        facbr.Manifestos.LoadFromString(xmlInput);
      end
      else
      begin
        ManifestoMDFe := facbr.Manifestos.Add;
        if Assigned(jMDFe.Find('MDFe')) then
          TJSONTools.JsonToObj(jMDFe, ManifestoMDFe)
        else
          TJSONTools.JsonToObj(jMDFe, ManifestoMDFe.MDFe);
      end;
    except
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, 'erro_parse');
        Result.Add(RSMessageField, 'Erro na conversao JSON/XML para MDF-e: ' + E.Message);
        Exit;
      end;
    end;

    try
      hasCert := HasUsableCertificate;
      LAssinado := Pos('<Signature', facbr.Manifestos.Items[0].XMLOriginal) > 0;
      if hasCert and (not LAssinado) then
      begin
        facbr.Manifestos.Items[0].Assinar;
        LAssinado := True;
      end
      else if facbr.Manifestos.Items[0].XMLOriginal = '' then
        facbr.Manifestos.GerarMDFe;

      if LAssinado or (Pos('<Signature', facbr.Manifestos.Items[0].XML) > 0) then
      begin
        LAssinado := True;
        facbr.Manifestos.Items[0].Validar;
      end;

      errosRegras := '';
      facbr.Manifestos.ValidarRegrasdeNegocios(errosRegras);
      xmlOut := facbr.Manifestos.Items[0].XML;
      if xmlOut = '' then
        xmlOut := facbr.Manifestos.Items[0].XMLOriginal;

      Result := TJSONObject.Create;
      if Trim(errosRegras) <> '' then
      begin
        Result.Add(RSStatusField, 'erro_validacao');
        Result.Add(RSMessageField, Trim(errosRegras));
        Result.Add('erros_regras_negocio', Trim(errosRegras));
      end
      else
      begin
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add(RSMessageField, 'XML Valido');
      end;
      Result.Add(RSChaveField, StringReplace(facbr.Manifestos.Items[0].MDFe.infMDFe.ID, 'MDFe', '', [rfIgnoreCase]));
      Result.Add('assinado', LAssinado);
      Result.Add(RSXmlKey, EncodeStringBase64(xmlOut));
    except
      on E: Exception do
      begin
        Result := TJSONTools.SafeObjToJson(nil, E.Message);
        Result.Delete(RSStatusField);
        Result.Add(RSStatusField, 'erro_validacao');
        if (facbr.Manifestos.Count > 0) and (facbr.Manifestos.Items[0].ErroValidacao <> '') then
          Result.Add('detalhes', facbr.Manifestos.Items[0].ErroValidacao);
      end;
    end;
  finally
    facbr.Manifestos.Clear;
  end;
end;

function TACBRBridgeMDFe.EventoToXML(const jEvento: TJSONObject): TJSONObject;
var
  objEvento: TInfEventoCollectionItem;
  LEvtArrData: TJSONData;
  LEvtItemObj: TJSONObject;
  xmlOut: string;
  LAssinado: Boolean;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;
  facbr.EventoMDFe.Evento.Clear;
  try
    try
      if Assigned(jEvento) then
      begin
        if Assigned(jEvento.Find('Evento')) and (jEvento.Find('Evento').JSONType = jtArray) then
          TJSONTools.JsonToObj(jEvento, facbr.EventoMDFe)
        else
        begin
          LEvtArrData := jEvento.Find(RSEventosField);
          if Assigned(LEvtArrData) and (LEvtArrData.JSONType = jtArray) and (TJSONArray(LEvtArrData).Count > 0) then
          begin
            LEvtItemObj := TJSONArray(LEvtArrData).Objects[0];
            objEvento := facbr.EventoMDFe.Evento.New;
            if Assigned(LEvtItemObj.Find('InfEvento')) then
              TJSONTools.JsonToObj(LEvtItemObj, objEvento)
            else
              TJSONTools.JsonToObj(LEvtItemObj, objEvento.InfEvento);
          end
          else
          begin
            objEvento := facbr.EventoMDFe.Evento.New;
            if Assigned(jEvento.Find('InfEvento')) then
              TJSONTools.JsonToObj(jEvento, objEvento)
            else
              TJSONTools.JsonToObj(jEvento, objEvento.InfEvento);
          end;
        end;
      end;

      if facbr.EventoMDFe.Evento.Count = 0 then
        raise Exception.Create('Nenhum evento MDF-e informado no payload JSON.');

      objEvento := facbr.EventoMDFe.Evento.Items[0];
      if Trim(objEvento.InfEvento.chMDFe) = '' then
        raise Exception.Create('Campo "chMDFe" nao informado para geracao do evento MDF-e.');
      if objEvento.InfEvento.tpEvento = teNaoMapeado then
        raise Exception.Create('Campo "tpEvento" invalido ou nao informado para geracao do evento MDF-e.');

      with objEvento.InfEvento do
      begin
        if (CNPJCPF = '') and (Length(chMDFe) >= 20) then
          CNPJCPF := Copy(chMDFe, 7, 14);
        if (cOrgao = 0) and (Length(chMDFe) >= 2) then
          cOrgao := StrToIntDef(Copy(chMDFe, 1, 2), 0);
        if dhEvento = 0 then
          dhEvento := Now;
        if nSeqEvento <= 0 then
          nSeqEvento := 1;
        if tpEvento = teEncerramento then
        begin
          if detEvento.dtEnc = 0 then
            detEvento.dtEnc := Date;
          if (detEvento.cUF = 0) and (detEvento.cMun > 0) then
            detEvento.cUF := StrToIntDef(Copy(IntToStr(detEvento.cMun), 1, 2), 0);
        end;
      end;

      if facbr.EventoMDFe.Versao = '' then
        facbr.EventoMDFe.Versao := '3.00';
      if facbr.EventoMDFe.idLote <= 0 then
        facbr.EventoMDFe.idLote := 1;
      facbr.EventoMDFe.GerarXML;
      xmlOut := facbr.EventoMDFe.XmlEnvio;

      LAssinado := False;
      if HasUsableCertificate and (xmlOut <> '') then
      begin
        facbr.SSL.CarregarCertificado;
        xmlOut := facbr.SSL.Assinar(xmlOut, 'eventoMDFe', 'infEvento');
        LAssinado := True;
      end;

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSChaveField, objEvento.InfEvento.chMDFe);
      Result.Add(RSIDField, objEvento.InfEvento.Id);
      Result.Add('assinado', LAssinado);
      Result.Add(RSXmlKey, EncodeStringBase64(xmlOut));
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao gerar XML do evento MDF-e: ' + E.Message);
      end;
    end;
  finally
    facbr.EventoMDFe.Evento.Clear;
  end;
end;

function TACBRBridgeMDFe.EnviarEmail(const jEmail: TJSONObject): TJSONObject;
var
  stringXml, para, assunto, msgTxt, pdfDir: string;
  enviaPdf: Boolean;
  mailComponent: TACBrMail;
  jMailCfg, jCc: TJSONData;
  msgLines, ccLines: TStringList;
  I: Integer;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;

  try
    stringXml := ReadXMLFromJSON(jEmail);
  except
    on E: Exception do
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, E.Message);
      Exit;
    end;
  end;

  para := Trim(jEmail.Get('para', jEmail.Get('Para', jEmail.Get('destinatario', jEmail.Get('email', '')))));
  if para = '' then
  begin
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSErrorField, 'Destinatario ("para" / "email") nao informado para envio de e-mail.');
    Exit;
  end;

  assunto := jEmail.Get('assunto', jEmail.Get('Assunto', 'Manifesto Eletronico de Documentos Fiscais'));
  msgTxt := jEmail.Get('mensagem', jEmail.Get('Mensagem', 'Segue em anexo o MDF-e.'));
  enviaPdf := jEmail.Get('enviaPDF', jEmail.Get('EnviaPDF', True));

  mailComponent := TACBrMail.Create(nil);
  msgLines := TStringList.Create;
  ccLines := TStringList.Create;
  try
    try
      jMailCfg := jEmail.Find('mail');
      if not Assigned(jMailCfg) then jMailCfg := jEmail.Find('Mail');
      if not Assigned(jMailCfg) then jMailCfg := jEmail.Find('smtp');
      if Assigned(jMailCfg) and (jMailCfg.JSONType = jtObject) then
        TJSONTools.JsonToObj(TJSONObject(jMailCfg), mailComponent)
      else
      begin
        mailComponent.Host := jEmail.Get('Host', jEmail.Get('host', ''));
        mailComponent.Port := IntToStr(jEmail.Get('Port', jEmail.Get('port', 587)));
        mailComponent.Username := jEmail.Get('Username', jEmail.Get('username', ''));
        mailComponent.Password := jEmail.Get('Password', jEmail.Get('password', ''));
        mailComponent.From := jEmail.Get('From', jEmail.Get('from', mailComponent.Username));
        mailComponent.FromName := jEmail.Get('FromName', jEmail.Get('fromName', ''));
        mailComponent.SetSSL := jEmail.Get('SetSSL', jEmail.Get('setSSL', False));
        mailComponent.SetTLS := jEmail.Get('SetTLS', jEmail.Get('setTLS', True));
      end;

      msgLines.Text := msgTxt;

      jCc := jEmail.Find('cc');
      if not Assigned(jCc) then jCc := jEmail.Find('CC');
      if Assigned(jCc) then
      begin
        if jCc.JSONType = jtArray then
        begin
          for I := 0 to TJSONArray(jCc).Count - 1 do
            ccLines.Add(TJSONArray(jCc).Items[I].AsString);
        end
        else if Trim(jCc.AsString) <> '' then
          ccLines.Text := StringReplace(jCc.AsString, ';', LineEnding, [rfReplaceAll]);
      end;

      facbr.Manifestos.Clear;
      facbr.Manifestos.LoadFromString(stringXml);
      if facbr.Manifestos.Count = 0 then
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Nenhum MDF-e foi carregado a partir do XML para envio de e-mail.');
        Exit;
      end;

      pdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
      if not DirectoryExists(pdfDir) then
        CreateDir(pdfDir);
      fdamdfe.PathPDF := pdfDir;
      fdamdfe.MostraPreview := False;
      fdamdfe.MostraStatus := False;
      fdamdfe.MostraSetup := False;

      facbr.DAMDFE := fdamdfe;
      facbr.MAIL := mailComponent;

      facbr.Manifestos.Items[0].EnviarEmail(para, assunto, msgLines, enviaPdf, ccLines, nil, nil);

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('para', para);
      Result.Add('assunto', assunto);
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Erro ao enviar e-mail do MDF-e: ' + E.Message);
      end;
    end;
  finally
    facbr.MAIL := nil;
    facbr.Manifestos.Clear;
    ccLines.Free;
    msgLines.Free;
    mailComponent.Free;
  end;
end;


end.
