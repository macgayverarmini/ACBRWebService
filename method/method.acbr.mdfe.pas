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
    procedure CarregaConfig;
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
    function ModelStatusServico: TJSONObject;
    function ModelConsulta: TJSONObject;
    function ModelCancelamento: TJSONObject;
    function ModelEncerramento: TJSONObject;
    function ModelNaoEncerrados: TJSONObject;
  end;

implementation

{ TACBRModelosJSONMDFe }

function TACBRModelosJSONMDFe.ModelConfig: TJSONObject;
begin
  with facbr.Configuracoes.Geral do
  begin
    VersaoDF := TVersaoMDFe.ve300;
    RetirarAcentos := True;
    SSLLib := TSSLLib.libOpenSSL;
    SSLCryptLib := TSSLCryptLib.cryOpenSSL;
    SSLHttpLib := TSSLHttpLib.httpOpenSSL;
    SSLXmlSignLib := TSSLXmlSignLib.xsLibXml2;
  end;

  with facbr.Configuracoes.WebServices do
  begin
    Ambiente := TpcnTipoAmbiente.taHomologacao;
    UF := RSDefaultUF;
    TimeOut := 10000;
    Visualizar := False;
  end;

  with facbr.Configuracoes.Certificados do
  begin
    ArquivoPFX := RSDefaultCertPath;
    Senha := RSDefaultCertPassword;
  end;

  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

function TACBRModelosJSONMDFe.ModelEvento: TJSONObject;
begin
  facbr.EventoMDFe.Evento.New;
  Result := TJSONTools.ObjToJson(facbr.EventoMDFe);
  facbr.EventoMDFe.Evento.Clear;
end;

function TACBRModelosJSONMDFe.ModelMDFe: TJSONObject;
var
  MDFe: TManifesto;
  MunDescarga: TinfMunDescargaCollectionItem;
  infCTe: TinfCTeCollectionItem;
  infUnidTranspCTe: TinfUnidTranspCollectionItem;
  infUnidCargaCTe: TinfUnidCargaCollectionItem;
begin
  // Cria um manifesto MDF-e vazio para gerar o modelo JSON
  MDFe := facbr.Manifestos.Add;

  // Bloco de Identificação do MDF-e (ide)
  with MDFe.MDFe.Ide do
  begin
    cUF := 35;
    tpAmb := taHomologacao;
    // Padrão para modelo
    tpEmit := teTransportadora;
    modelo := '58';
    serie := 1;
    nMDF := 1;
    cMDF := 1;
    modal := moRodoviario;
    dhEmi := Now;
    tpEmis := teNormal;
    procEmi := peAplicativoContribuinte;
    verProc := '1.0';
    UFIni := 'SP';
    UFFim := 'SP';
  end;

  MDFe.MDFe.Ide.infMunCarrega.New;

  // Bloco do Emitente (emit)
  with MDFe.MDFe.Emit do
  begin
    CNPJCPF := '00000000000191';
    IE := '123456789012';
    xNome := 'RAZAO SOCIAL DO EMITENTE';
    xFant := 'NOME FANTASIA DO EMITENTE';
    with EnderEmit do
    begin
      xLgr := 'AVENIDA PRINCIPAL';
      nro := '1234';
      xBairro := 'CENTRO';
      cMun := 3550308;
      xMun := 'SAO PAULO';
      CEP := 12345000;
      UF := 'SP';
    end;
  end;

  // Bloco Rodo (Modal Rodoviário)
  with MDFe.MDFe.rodo do
  begin
    RNTRC := '12345678';

    // Veículo de Tração
    with veicTracao do
    begin
      placa := 'ABC1234';
      RENAVAM := '123456789';
      tara := 5000;
      capKG := 4500;
      tpRod := trTruck;
      tpCar := tcFechada;
      UF := 'SP';
    end;

    // Condutor
    veicTracao.condutor.New;
    // Veículo Reboque
    veicReboque.New;
    // Vale Pedágio
    valePed.disp.New;
    // CIOT
    infANTT.infCIOT.New;
  end;

  // Bloco de Documentos (infDoc)
  MunDescarga := MDFe.MDFe.infDoc.infMunDescarga.New;

  // Informações do CT-e
  infCTe := MunDescarga.infCTe.New;
  infCTe.chCTe := '35110803911545000148570010000001011000001018';

  // Unidade de Transporte
  infUnidTranspCTe := infCTe.infUnidTransp.New;

  infUnidTranspCTe.tpUnidTransp := utRodoTracao;
  infUnidTranspCTe.idUnidTransp := 'ABC1234';
  infUnidTranspCTe.lacUnidTransp.New;

  // Unidade de Carga
  infUnidCargaCte := infUnidTranspCTe.infUnidCarga.New;
  infUnidCargaCte.tpUnidCarga := ucOutros;
  infUnidCargaCte.idUnidCarga := 'AB45';
  infUnidCargaCte.lacUnidCarga.New;

  // Bloco de Totais (tot)
  with MDFe.MDFe.Tot do
  begin
    qCTe := 1;
    vCarga := 3500.00;
    cUnid := uTon;
    qCarga := 2.8000;
  end;

  // Lacres
  MDFe.MDFe.lacres.New;

  // Informações Adicionais
  with MDFe.MDFe.infAdic do
  begin
    infCpl := 'INFORMACOES COMPLEMENTARES';
    infAdFisco := 'INFORMACOES PARA O FISCO';
  end;

  // Converte o objeto populado para JSON
  Result := TJSONTools.ObjToJson(MDFe);

  // Remove campos internos desnecessários para o modelo
  Result.Delete(RSXMLField);
  Result.Delete(RSXMLOriginalField);
  Result.Delete(RSNomeArqField);
  Result.Delete(RSProtocoloField);

  // Limpa o manifesto da memória do componente ACBr
  facbr.Manifestos.Clear;
end;

function TACBRModelosJSONMDFe.ModelDistribuicao: string;
begin
  Result := TJSONTools.SafeObjToJsonString(facbr.WebServices.DistribuicaoDFe);
end;

function TACBRModelosJSONMDFe.ModelMDFeFromXML: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add(RSXmlKey, 'BASE64_DO_XML_MDFE_AQUI');
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

procedure TACBRBridgeMDFe.CarregaConfig;
var
  O: TJSONObject;
  LPfx: AnsiString;
  tempData: TJSONData;
  logoCfg: string;
begin
  if Trim(fcfg) = '' then
    raise Exception.Create(RSConfigEmptyError);

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

      with facbr.Configuracoes.Geral do
      begin
        SSLLib := libOpenSSL;
        SSLCryptLib := cryOpenSSL;
        SSLHttpLib := httpOpenSSL;
        SSLXmlSignLib := xsLibXml2;
      end;
    finally
      O.Free;
    end;
  except
    on E: Exception do
      raise Exception.Create(RSConfigReadError + E.Message);
  end;

  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + RSSchemasDir + PathDelim + 'MDFe';

  fcfg := '';
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
  jOpt, jTarget, jInf, jEmit, jModal, jRodo: TJSONData;
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
    jTarget := nil;
    if Assigned(jMDFe) then
    begin
      jTarget := jMDFe.Find('MDFe');
      if not Assigned(jTarget) then
        jTarget := jMDFe.Find('mdfe');
    end;
    if not (Assigned(jTarget) and (jTarget.JSONType = jtObject)) then
      jTarget := jMDFe;

    if Assigned(jTarget) and (jTarget.JSONType = jtObject) then
    begin
      jInf := TJSONObject(jTarget).Find('infMDFe');
      if Assigned(TJSONObject(jTarget).Find('Ide')) or Assigned(TJSONObject(jTarget).Find('ide')) then
        TJSONTools.JsonToObj(TJSONObject(jTarget), Manifesto.MDFe)
      else if Assigned(jInf) and (jInf.JSONType = jtObject) then
        TJSONTools.JsonToObj(TJSONObject(jInf), Manifesto.MDFe)
      else
        TJSONTools.JsonToObj(TJSONObject(jTarget), Manifesto.MDFe);

      if Assigned(jInf) and (jInf.JSONType = jtObject) and
         not Assigned(TJSONObject(jTarget).Find('rodo')) then
      begin
        jModal := TJSONObject(jInf).Find('infModal');
        if Assigned(jModal) and (jModal.JSONType = jtObject) then
        begin
          jRodo := TJSONObject(jModal).Find('rodo');
          if Assigned(jRodo) and (jRodo.JSONType = jtObject) then
            TJSONTools.JsonToObj(TJSONObject(jRodo), Manifesto.MDFe.rodo);
        end;
      end;

      if Manifesto.MDFe.Emit.CNPJCPF = '' then
      begin
        jEmit := TJSONObject(jTarget).Find('Emit');
        if not Assigned(jEmit) then jEmit := TJSONObject(jTarget).Find('emit');
        if not Assigned(jEmit) and Assigned(jInf) and (jInf.JSONType = jtObject) then
        begin
          jEmit := TJSONObject(jInf).Find('Emit');
          if not Assigned(jEmit) then jEmit := TJSONObject(jInf).Find('emit');
        end;
        if Assigned(jEmit) and (jEmit.JSONType = jtObject) then
          Manifesto.MDFe.Emit.CNPJCPF := TJSONObject(jEmit).Get(
            'CNPJCPF',
            TJSONObject(jEmit).Get('CNPJ', TJSONObject(jEmit).Get('CPF', ''))
          );
      end;
    end;
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
  LOk: Boolean;
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

    if objEvento.InfEvento.tpEvento = teNaoMapeado then
    begin
      xmlStr := Trim(InfEvento.Get('tpEvento', oEvento.Get('tpEvento', '')));
      if xmlStr <> '' then
        objEvento.InfEvento.tpEvento := StrToTpEventoMDFe(LOk, xmlStr);
    end;

    if Assigned(InfEvento.Find('detEvento')) and (InfEvento.Find('detEvento').JSONType = jtObject) then
    begin
      TJSONTools.JsonToObj(TJSONObject(InfEvento.Find('detEvento')), objEvento.InfEvento.detEvento);
      if Assigned(TJSONObject(InfEvento.Find('detEvento')).Find('condutor')) and
         (TJSONObject(InfEvento.Find('detEvento')).Find('condutor').JSONType = jtObject) then
      begin
        TJSONTools.JsonToObj(
          TJSONObject(TJSONObject(InfEvento.Find('detEvento')).Find('condutor')),
          objEvento.InfEvento.detEvento
        );
      end;
    end
    else if Assigned(InfEvento.Find('DetEvento')) and (InfEvento.Find('DetEvento').JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(InfEvento.Find('DetEvento')), objEvento.InfEvento.detEvento);

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
  CNPJCPF, ultNSU, NSU, chMDFe: TJSONString;
begin
  CarregaConfig;

  Result := nil;
  objDistribuicao := facbr.WebServices.DistribuicaoDFe;

  if jDistribuicao.Find('CNPJCPF', CNPJCPF) then
    objDistribuicao.CNPJCPF := CNPJCPF.ToString;

  if jDistribuicao.Find('ultNSU', ultNSU) then
    objDistribuicao.ultNSU := ultNSU.ToString;

  if jDistribuicao.Find('NSU', NSU) then
    objDistribuicao.NSU := NSU.ToString;

  if jDistribuicao.Find('chMDFe', chMDFe) then
    objDistribuicao.chMDFe := chMDFe.ToString;

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
  CarregaConfig;
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
  CarregaConfig;
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
  CarregaConfig;
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
  jTarget, jInf, jEmit, jModal, jRodo: TJSONData;
begin
  CarregaConfig;

  try
    ManifestoMDFe := facbr.Manifestos.Add;
    jTarget := nil;
    if Assigned(jMDFe) then
    begin
      jTarget := jMDFe.Find('MDFe');
      if not Assigned(jTarget) then
        jTarget := jMDFe.Find('mdfe');
    end;
    if not (Assigned(jTarget) and (jTarget.JSONType = jtObject)) then
      jTarget := jMDFe;

    if Assigned(jTarget) and (jTarget.JSONType = jtObject) then
    begin
      jInf := TJSONObject(jTarget).Find('infMDFe');
      if Assigned(TJSONObject(jTarget).Find('Ide')) or Assigned(TJSONObject(jTarget).Find('ide')) then
        TJSONTools.JsonToObj(TJSONObject(jTarget), ManifestoMDFe.MDFe)
      else if Assigned(jInf) and (jInf.JSONType = jtObject) then
        TJSONTools.JsonToObj(TJSONObject(jInf), ManifestoMDFe.MDFe)
      else
        TJSONTools.JsonToObj(TJSONObject(jTarget), ManifestoMDFe.MDFe);

      if Assigned(jInf) and (jInf.JSONType = jtObject) and
         not Assigned(TJSONObject(jTarget).Find('rodo')) then
      begin
        jModal := TJSONObject(jInf).Find('infModal');
        if Assigned(jModal) and (jModal.JSONType = jtObject) then
        begin
          jRodo := TJSONObject(jModal).Find('rodo');
          if Assigned(jRodo) and (jRodo.JSONType = jtObject) then
            TJSONTools.JsonToObj(TJSONObject(jRodo), ManifestoMDFe.MDFe.rodo);
        end;
      end;

      if ManifestoMDFe.MDFe.Emit.CNPJCPF = '' then
      begin
        jEmit := TJSONObject(jTarget).Find('Emit');
        if not Assigned(jEmit) then jEmit := TJSONObject(jTarget).Find('emit');
        if not Assigned(jEmit) and Assigned(jInf) and (jInf.JSONType = jtObject) then
        begin
          jEmit := TJSONObject(jInf).Find('Emit');
          if not Assigned(jEmit) then jEmit := TJSONObject(jInf).Find('emit');
        end;
        if Assigned(jEmit) and (jEmit.JSONType = jtObject) then
          ManifestoMDFe.MDFe.Emit.CNPJCPF := TJSONObject(jEmit).Get(
            'CNPJCPF',
            TJSONObject(jEmit).Get('CNPJ', TJSONObject(jEmit).Get('CPF', ''))
          );
      end;
    end;
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
    xmlString := facbr.Manifestos.Items[0].XMLOriginal;
    if xmlString = '' then
      xmlString := facbr.Manifestos.Items[0].XML;

    Result := TJSONObject.Create;
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
  Chave := jConsulta.Get('MDFeChave', '');
  if Chave = '' then
    Chave := jConsulta.Get('chMDFe', '');
  if Chave = '' then
    Chave := jConsulta.Get(RSChaveField, '');

  if Chave <> '' then
  begin
    try
      facbr.WebServices.Consulta.MDFeChave := Chave;
      facbr.WebServices.Consulta.ExtrairEventos := jConsulta.Get('ExtrairEventos', False);
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
          if not TryISO8601ToDate(dtEncStr, infEvento.detEvento.dtEnc, False) then
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
  cnpjCpf := jConsulta.Get('CNPJCPF', '');
  if cnpjCpf = '' then
    cnpjCpf := jConsulta.Get('cnpj', '');

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
  Result := TJSONObject.Create;
end;



function TACBRModelosJSONMDFe.ModelConsulta: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('MDFeChave', 'Preencha com a Chave de Acesso de 44 digitos do MDF-e');
  Result.Add('ExtrairEventos', True);
end;



function TACBRModelosJSONMDFe.ModelCancelamento: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('chMDFe', 'Preencha com a Chave de Acesso do MDF-e');
  Result.Add('nProt', 'Preencha com o Protocolo de Autorizacao');
  Result.Add('CNPJCPF', '00000000000191');
  Result.Add('xJust', 'Justificativa do Cancelamento (min 15 caracteres)');
end;



function TACBRModelosJSONMDFe.ModelEncerramento: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('chMDFe', 'Preencha com a Chave de Acesso do MDF-e');
  Result.Add('nProt', 'Preencha com o Protocolo de Autorizacao');
  Result.Add('CNPJCPF', '00000000000191');
  Result.Add('cUF', 32);
  Result.Add('cMun', 3205002);
  Result.Add('dtEnc', FormatDateTime('yyyy-mm-dd', Date));
end;



function TACBRModelosJSONMDFe.ModelNaoEncerrados: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('CNPJCPF', '00000000000191');
end;


end.
