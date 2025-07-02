{%RunFlags MESSAGES+}

unit method.acbr.mdfe;

{$mode Delphi}

interface

uses
  streamtools,
  RTTI,
  ACBrMDFe,
  ACBrMDFeManifestos,
  ACBrMDFe.Classes,
  ACBrMDFeDAMDFeRLClass,
  ACBrMDFe.EnvEvento,
  ACBrDFeSSL,
  ACBrMDFeWebServices,
  pmdfeConversaoMDFe,
  pcnConversao,
  Variants,
  Controls,
  fpjson, jsonconvert,
  Base64, jsonparser,
  ACBrDFeConfiguracoes,
  ACBrMDFeConfiguracoes,
  Classes, SysUtils;

type

  { TACBRBridgeMDFe }

  TACBRBridgeMDFe = class
  private
    fcfg: string;
    facbr: TACBrMDFe;
    fdamdfe: TACBrMDFeDAMDFERL;
    procedure CarregaConfig;
    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function Evento(const jEventos: TJSONArray): string;
    function Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
    function Damdfe(const xmlData: TJSONObject): TJSONObject;
    function MDFe(const jMDFe: TJSONObject): TJSONObject;

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
  Result.Delete('XML');
  Result.Delete('XMLOriginal');
  Result.Delete('NomeArq');
  Result.Delete('Protocolo');

  // Limpa o manifesto da memória do componente ACBr
  facbr.Manifestos.Clear;
end;

function TACBRModelosJSONMDFe.ModelDistribuicao: string;
begin
  Result := TJSONTools.ObjToJsonString(facbr.WebServices.DistribuicaoDFe);
end;

{ TACBRBridgeMDFe }

procedure TACBRBridgeMDFe.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then
    exit;

  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
  finally
    O.Free;
  end;
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
      'Parâmetro "xml" (contendo o XML em Base64) não encontrado no JSON.');

  xmlBase64 := oXML.AsString;

  if xmlBase64.IsEmpty then
    raise Exception.Create('Parâmetro "xml" está vazio.');

  try
    Result := DecodeStringBase64(xmlBase64);
  except
    on E: Exception do
      raise Exception.Create('A string XML em base64 é inválida: ' + E.Message);
  end;
end;

constructor TACBRBridgeMDFe.Create(const Cfg: string);
begin
  facbr := TACBrMDFe.Create(nil);
  fdamdfe := TACBrMDFeDAMDFERL.Create(nil);
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
    // Agrupa as chamadas de preparação e envio dentro do bloco try
    facbr.Manifestos.Assinar;
    facbr.Manifestos.Validar;
    facbr.Enviar(Lote);
  finally
    // Garante que o retorno do webservice seja sempre capturado e retornado
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.Retorno));
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

function TACBRBridgeMDFe.Damdfe(const xmlData: TJSONObject): TJSONObject;
var
  arquivofinal: string;
  stringXml: string;
  tamanho: integer;
  id: TJSONString;
  fileName: string;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  try
    stringXml := ReadXMLFromJSON(xmlData);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', E.Message);
      Exit;
    end;
  end;

  try
    facbr.Manifestos.LoadFromString(stringXml);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na leitura do XML do MDF-e: ' + E.Message);
      Exit;
    end;
  end;

  stringXml := '';

  fdamdfe.MostraPreview := False;
  fdamdfe.MostraStatus := False;
  fdamdfe.MostraSetup := False;

  fileName := GetTempFileName;

  try
    fdamdfe.PathPDF := filename;
    facbr.Manifestos.ImprimirPDF;
    filename := fdamdfe.ArquivoPDF;
  except
    begin
      Result.Add('error', 'Falha ao gerar o PDF.');
      Exit;
    end;
  end;

  // Converte o arquivo para base64
  try
    arquivofinal := FileToStringBase64(filename, True, tamanho);
  except
    on E: Exception do
    begin
      Result.Add('error', E.Message);
      Exit;
    end;
  end;

  // Converte a stream do relatório para base64
  Result.Add('pdf', arquivofinal);
  // Chave de Acesso da NF-e
  Result.Add('chave', facbr.Manifestos.Items[0].MDFe.infMDFe.ID);
  // Tamanho em Bytes
  Result.Add('tamanho', tamanho.ToString);
  // Adiciona o identificador único se ele existir
  if xmlData.Find('id', id) then
    Result.Add('id', id);

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

end.
