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
  pmdfeConversaoMDFe,
  pcnConversao,
  Variants,
  fpjson, jsonconvert,
  Base64, jsonparser,
  ACBrDFeConfiguracoes,
  ACBrMDFeConfiguracoes,
  Classes, SysUtils,
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
    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function Evento(const jEventos: TJSONArray): string;
    function Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
    function Damdfe(const xmlData: TJSONObject; const OnlyURL: Boolean = False): TJSONObject;    function DamdfeEvento(const xmlEvento: TJSONObject): TJSONObject;
    function MDFe(const jMDFe: TJSONObject): TJSONObject;    function MDFeFromXML(const jXML: TJSONObject): TJSONObject;
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
    function ModelMDFe: TJSONObject;    function ModelMDFeFromXML: TJSONObject;
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
    UF := 'ES';
    TimeOut := 10000;
    Visualizar := False;
  end;

  with facbr.Configuracoes.Certificados do
  begin
    ArquivoPFX := 'C:\caminho\seu_certificado.pfx';
    Senha := 'sua_senha';
  end;

  with facbr.Configuracoes.Arquivos do
  begin
    // PathSalvar := 'C:\ACBr\MDFe\';
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

  // Bloco de IdentificaÃƒÂ§ÃƒÂ£o do MDF-e (ide)
  with MDFe.MDFe.Ide do
  begin
    cUF := 35;
    tpAmb := taHomologacao;
    // PadrÃƒÂ£o para modelo
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

  // Bloco Rodo (Modal RodoviÃƒÂ¡rio)
  with MDFe.MDFe.rodo do
  begin
    RNTRC := '12345678';

    // VeÃƒÂ­culo de TraÃƒÂ§ÃƒÂ£o
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
    // VeÃƒÂ­culo Reboque
    veicReboque.New;
    // Vale PedÃƒÂ¡gio
    valePed.disp.New;
    // CIOT
    infANTT.infCIOT.New;
  end;

  // Bloco de Documentos (infDoc)
  MunDescarga := MDFe.MDFe.infDoc.infMunDescarga.New;

  // InformaÃƒÂ§ÃƒÂµes do CT-e
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

  // InformaÃƒÂ§ÃƒÂµes Adicionais
  with MDFe.MDFe.infAdic do
  begin
    infCpl := 'INFORMACOES COMPLEMENTARES';
    infAdFisco := 'INFORMACOES PARA O FISCO';
  end;

  // Converte o objeto populado para JSON
  Result := TJSONTools.ObjToJson(MDFe);

  // Remove campos internos desnecessÃƒÂ¡rios para o modelo
  Result.Delete('XML');
  Result.Delete('XMLOriginal');
  Result.Delete('NomeArq');
  Result.Delete('Protocolo');

  // Limpa o manifesto da memÃƒÂ³ria do componente ACBr
  facbr.Manifestos.Clear;
end;

function TACBRModelosJSONMDFe.ModelDistribuicao: string;
begin
  Result := TJSONTools.SafeObjToJsonString(facbr.WebServices.DistribuicaoDFe);
end;
function TACBRModelosJSONMDFe.ModelMDFeFromXML: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('xml', 'BASE64_DO_XML_MDFE_AQUI');
end;

function TACBRModelosJSONMDFe.ModelMDFeToXML: TJSONObject;
begin
  Result := ModelMDFe;
end;


{ TACBRBridgeMDFe }

procedure TACBRBridgeMDFe.CarregaConfig;
var
  O, CertConfig: TJSONObject;
  tempData: TJSONData;
  b64String: string;
begin
  if (fcfg = '') or (fcfg = '') then
    raise Exception.Create('Configuracao vazia ou nao informada.');

  try
    O := GetJSON(fcfg) as TJSONObject;
      try
        TJSONTools.JsonToObj(O, facbr.Configuracoes);

        tempData := O.Find('Certificados');
        if Assigned(tempData) and (tempData.JSONType = jtObject) then
        begin
          CertConfig := TJSONObject(tempData);
          b64String := CertConfig.Get('DadosPFXBase64', '');
          if b64String <> '' then
          begin
            facbr.Configuracoes.Certificados.DadosPFX := synacode.DecodeBase64(AnsiString(b64String));
          end;
        end;
      finally
        O.Free;
      end;
  except
    on E: Exception do
      raise Exception.Create('Erro na leitura da configuracao: ' + E.Message);
  end;

  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + 'Schemas' + PathDelim + 'MDFe';

  fcfg := '';
end;

function TACBRBridgeMDFe.ReadXMLFromJSON(const jsonData: TJSONObject): string;
var
  xmlBase64: string;
  oXML: TJSONString;
begin
  Result := '';
  if not jsonData.Find('xml', oXML) then
    raise Exception.Create(
      'ParÃƒÂ¢metro "xml" (contendo o XML em Base64) nÃƒÂ£o encontrado no JSON.');

  xmlBase64 := oXML.AsString;

  if xmlBase64.IsEmpty then
    raise Exception.Create('ParÃƒÂ¢metro "xml" estÃƒÂ¡ vazio.');

  try
    Result := DecodeStringBase64(xmlBase64);
  except
    on E: Exception do
      raise Exception.Create('A string XML em base64 ÃƒÂ© invÃƒÂ¡lida: ' + E.Message);
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
  Lote: string;
begin
  CarregaConfig;

  Result := TJSONObject.Create;
  Manifesto := facbr.Manifestos.Add;
  Lote := '1';

  try
    TJSONTools.JsonToObj(jMDFe, Manifesto);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na leitura do objeto JSON do MDF-e: ' +
        E.Message);
      facbr.Manifestos.Clear;
      Exit;
    end;
  end;

  try
    // Agrupa as chamadas de preparaÃƒÂ§ÃƒÂ£o e envio dentro do bloco try
    facbr.Manifestos.Assinar;
    facbr.Manifestos.Validar;
    facbr.Enviar(Lote);
  finally
    // Garante que o retorno do webservice seja sempre capturado e retornado
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.Retorno));
    if facbr.Manifestos.Count > 0 then
      Result.Add('xml_autorizado', EncodeStringBase64(facbr.Manifestos.Items[0].XML));
  end;

  facbr.Manifestos.Clear;
end;

function TACBRBridgeMDFe.Evento(const jEventos: TJSONArray): string;
var
  objEvento: TInfEventoCollectionItem;
  oEvento: TJSONObject;
  I: integer;
  InfEvento: TJSONObject;
  XmlBase64: TJSONString;
begin
  CarregaConfig;
  Result := '';



  for I := 0 to jEventos.Count - 1 do
  begin
    oEvento := jEventos.Items[i] as TJSONObject;
    InfEvento := oEvento.Extract('InfEvento') as TJSONObject;
    if InfEvento.Find('LoadXML', XmlBase64) then
      facbr.Manifestos.LoadFromString(Base64.DecodeStringBase64(
        XmlBase64.AsString));

    objEvento := facbr.EventoMDFe.Evento.New;
    TJSONTools.JsonToObj(oEvento, objEvento);
  end;

  facbr.EnviarEvento(1);
  Result := TJSONTools.ObjToJsonString(
    facbr.WebServices.EnvEvento.EventoRetorno.retEvento);
end;

function TACBRBridgeMDFe.Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
var
  objDistribuicao: TDistribuicaoDFe;
  CNPJCPF, ultNSU, NSU, chMDFe: TJSONString;
begin
  CarregaConfig;

  Result := TJSONObject.Create;
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
        Result.Add('error', E.message);
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
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  try
    stringXml := ReadXMLFromJSON(xmlData);
  except
    on E: Exception do
    begin
      Result.Add(RSErrorField, E.Message);
      Exit;
    end;
  end;

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

  fdamdfe.Cancelada := (facbr.Manifestos.Items[0].MDFe.procMDFe.cStat = 101);

  fdamdfe.MostraPreview := False;
  fdamdfe.MostraStatus := False;
  fdamdfe.MostraSetup := False;

  pdfDir := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;
  if not DirectoryExists(pdfDir) then
    CreateDir(pdfDir);

  try
    fdamdfe.PathPDF := pdfDir;
    facbr.DAMDFE := fdamdfe;
    facbr.Manifestos.ImprimirPDF;

    fileName := fdamdfe.ArquivoPDF;
    if (fileName = '') or (not FileExists(fileName)) then
    begin
      fileName := pdfDir + facbr.Manifestos.Items[0].MDFe.infMDFe.ID + '-mdfe.pdf';
      if not FileExists(fileName) then
        fileName := pdfDir + StringReplace(facbr.Manifestos.Items[0].MDFe.infMDFe.ID, 'MDFe', '', [rfIgnoreCase]) + '-mdfe.pdf';
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

  chClean := StringReplace(facbr.Manifestos.Items[0].MDFe.infMDFe.ID, 'MDFe', '', [rfIgnoreCase]);

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
  Result.Add('url', '/mdfe/pdf/' + chClean);

  if xmlData.Find(RSIDField, id) then
    Result.Add(RSIDField, id);
end;

function TACBRBridgeMDFe.DamdfeEvento(const xmlEvento: TJSONObject): TJSONObject;
var
  arquivofinal: string;
  stringXml: string;
  tamanho: integer;
  id: TJSONString;
  fileName: string;
  pdfDir: string;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  try
    stringXml := ReadXMLFromJSON(xmlEvento);
  except
    on E: Exception do
    begin
      Result.Add(RSErrorField, E.Message);
      Exit;
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

  fdamdfe.MostraPreview := False;
  fdamdfe.MostraStatus := False;
  fdamdfe.MostraSetup := False;

  pdfDir := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;
  if not DirectoryExists(pdfDir) then
    CreateDir(pdfDir);

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
    Result.Add(RSIDField, id);
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
        Result.Delete('XML');
        Result.Delete('XMLOriginal');
        Result.Delete('NomeArq');
        Result.Delete('Protocolo');
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
begin
  CarregaConfig;

  try
    ManifestoMDFe := facbr.Manifestos.Add;
    TJSONTools.JsonToObj(jMDFe, ManifestoMDFe);
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
    Result.Add('xml', EncodeStringBase64(xmlString));
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
    Chave := jConsulta.Get('chave', '');

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
      if chMDFe = '' then chMDFe := CancObj.Get('chave', '');
      nProt := CancObj.Get('nProt', '');
      if nProt = '' then nProt := CancObj.Get('protocolo', '');
      xJust := CancObj.Get('xJust', '');
      if xJust = '' then xJust := CancObj.Get('justificativa', '');
      cnpjCpf := CancObj.Get('CNPJCPF', '');
      xmlBase64 := CancObj.Get('xml', '');

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
          infEvento.detEvento.nProt := nProt;
          infEvento.detEvento.xJust := xJust;
        end;
        facbr.EnviarEvento(1);
      end;

      Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento.EventoRetorno.retEvento, 'Cancelamento MDF-e processado');
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
      if chMDFe = '' then chMDFe := EncObj.Get('chave', '');
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

      facbr.EventoMDFe.Evento.Clear;
      with facbr.EventoMDFe.Evento.New do
      begin
        infEvento.chMDFe := chMDFe;
        infEvento.CNPJCPF := cnpjCpf;
        infEvento.cOrgao := StrToIntDef(Copy(chMDFe, 1, 2), cUF);
        infEvento.dhEvento := Now;
        infEvento.tpEvento := teEncerramento;
        infEvento.detEvento.nProt := nProt;
        infEvento.detEvento.dtEnc := Date;
        infEvento.detEvento.cUF := cUF;
        infEvento.detEvento.cMun := cMun;
      end;

      facbr.EnviarEvento(1);
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento.EventoRetorno.retEvento, 'Encerramento MDF-e processado');
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
