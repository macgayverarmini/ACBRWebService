unit method.acbr.cte;

{$mode Delphi}
{$M+}

interface

uses
  resource.strings.msg,
  RTTI,
  ACBrCTe,
  ACBrCTe.EnvEvento,
  ACBrCTe.EventoClass,
  ACBrCTeConhecimentos,
  ACBrCTeDACTeFPDF, // Para o tipo TACBrCTeDACTeFPDF
  ACBrCTeWebServices,
  // ACBrDFeDANFeReport, // Revisar se  realmente necessrio
  ACBrMail,
  ACBrDFeSSL,
  ACBrDFeConfiguracoes,
  ACBrCTeConfiguracoes,
  ACBrCTe.Classes,
  pcnConversao,      // Geral
  pcteConversaoCTe, // Especfico de CTe
  StrUtils,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  synacode,
  Classes, SysUtils,
  streamtools,
  ACBrUtil,       // Para GetTempFileName e possivelmente FileToStringBase64
  resource.strings.global;

type

  { TACBRBridgeCTe }

  TACBRBridgeCTe = class
  private
    fcfg: string;
    facbr: TACBrCTe;
    fdacte: TACBrCTeDACTeFPDF;

    procedure CarregaConfig;
    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function Evento(const jEventos: TJSONArray): string;
    function Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
    function StatusServico(const jStatus: TJSONObject): TJSONObject;
    function Consulta(const jConsulta: TJSONObject): TJSONObject;
    function Inutilizacao(const jInutilizacao: TJSONObject): TJSONObject;
    function CTe(const O: TJSONObject): TJSONObject;
    function Cancelamento(const jCancelamento: TJSONObject): TJSONObject;
    function CTeFromXML(const jXML: TJSONObject): TJSONObject;
    function CTeToXML(const jCTe: TJSONObject): TJSONObject;
    function DACTE(const xmlData: TJSONObject; const OnlyURL: Boolean = False): TJSONObject;
    function ValidarRegras(const jCTe: TJSONObject): TJSONObject;
    function DACTEEvento(const xmlEvento: TJSONObject): TJSONObject;

    function DebugConfig: TJSONObject;
    function DebugCTe(const O: TJSONObject): TJSONObject;

    function TesteConfig: boolean;
  end;

  { TACBRModelosJSONCTe - Salva os retornos de modelo de requisies CTe }

  TACBRModelosJSONCTe = class(TACBRBridgeCTe)
  private
  public
    function ModelConfig: TJSONObject;
    function ModelStatusServico: TJSONObject;
    function ModelConsulta: TJSONObject;
    function ModelInutilizacao: TJSONObject;
    function ModelEvento: TJSONObject;
    function ModelDistribuicao: string;
    function ModelCTe: TJSONObject;
    function ModelCancelamento: TJSONObject;
    function ModelCTeFromXML: TJSONObject;
    function ModelCTeToXML: TJSONObject;
    function ModelValidarRegras: TJSONObject;
    function ModelDACTEEvento: TJSONObject;
  end;

implementation

// Se precisar de pcnAuxiliar ou outras units de converso (UFtoCUF), adicione aqui.
// Exemplo: pcnAuxiliar (para UFtoCUF, se no estiver em pcnConversao ou pcteConversaoCTe)

{ TACBRModelosJSONCTe }

function TACBRModelosJSONCTe.ModelConfig: TJSONObject;
begin
  with facbr.Configuracoes.Geral do
  begin
    VersaoDF := TVersaoCTe.ve400;
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
    TimeOut := 15000;
    Visualizar := False;
  end;

  with facbr.Configuracoes.Certificados do
  begin
    ArquivoPFX := RSDefaultCertPath;
    Senha := RSDefaultCertPassword;
  end;

  with facbr.Configuracoes.Arquivos do
  begin
    Salvar := True; // Exemplo: para salvar os XMLs gerados
  end;

  with facbr.DACTE do
  begin
    Logo := 'C:\caminho\sua_logo.jpg'; // Exemplo
  end;

  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

function TACBRModelosJSONCTe.ModelStatusServico: TJSONObject;
begin
  Result := TJSONObject.Create;
end;

function TACBRModelosJSONCTe.ModelConsulta: TJSONObject;
begin
  // A classe TCTeConsulta tem a propriedade CTeChave. Vamos usar ela.
  facbr.WebServices.Consulta.CTeChave := 'Preencha com a Chave de Acesso do CTe';
  Result := TJSONObject.Create;
  Result.Add('CTeChave', facbr.WebServices.Consulta.CTeChave);
end;

function TACBRModelosJSONCTe.ModelInutilizacao: TJSONObject;
begin
  facbr.WebServices.Inutilizacao.CNPJ := '00000000000000';
  facbr.WebServices.Inutilizacao.Justificativa := 'Justificativa da Inutilizacao';
  facbr.WebServices.Inutilizacao.Ano := 2023;
  facbr.WebServices.Inutilizacao.Serie := 1;
  facbr.WebServices.Inutilizacao.NumeroInicial := 100;
  facbr.WebServices.Inutilizacao.NumeroFinal := 100;
  facbr.WebServices.Inutilizacao.Modelo := 57;
  
  Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.Inutilizacao));
end;

function TACBRModelosJSONCTe.ModelEvento: TJSONObject;
begin
  facbr.EventoCTe.Evento.New;
  // Preencher campos mnimos de exemplo se desejado
  Result := TJSONTools.ObjToJson(facbr.EventoCTe);
  facbr.EventoCTe.Evento.Clear;
end;

function TACBRModelosJSONCTe.ModelCancelamento: TJSONObject;
begin
  facbr.EventoCTe.Evento.Clear;
  with facbr.EventoCTe.Evento.New.InfEvento do
  begin
     tpEvento := teCancelamento;
     chCTe := 'Preencha com a Chave de Acesso';
     detEvento.nProt := 'Preencha com o Protocolo';
     detEvento.xJust := 'Justificativa do Cancelamento (min 15 caracteres)';
  end;
  Result := TJSONObject(TJSONTools.ObjToJson(facbr.EventoCTe.Evento.Items[0]));
  facbr.EventoCTe.Evento.Clear;
end;

function TACBRModelosJSONCTe.ModelCTeFromXML: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add(RSXmlKey, 'XML do CTe em Base64 Ã¢â‚¬â€ retorna o CTe como JSON');
end;

function TACBRModelosJSONCTe.ModelCTeToXML: TJSONObject;
begin
  Result := ModelCTe;
  // O modelo ÃƒÂ© o mesmo do CTe Ã¢â‚¬â€ envie o JSON do CTe e receba o XML gerado
end;

function TACBRModelosJSONCTe.ModelCTe: TJSONObject;
var
  vConhecimento: Conhecimento;
begin
  vConhecimento := facbr.Conhecimentos.Add;
  with vConhecimento.CTe do
  begin
    infCTe.versao := 4.0;
    Ide.cUF := UFtoCUF('ES'); // Certifique-se que UFtoCUF est acessvel
    Ide.CFOP := 5353;
    Ide.natOp := 'PRESTACAO SERVICO';
    ide.forPag := fpAPagar;
    Ide.modelo := 57;
    Ide.serie := 1;
    Ide.nCT := 1;
    Ide.cCT := 1; // Ateno: deve ser aleatrio
    Ide.dhEmi := Now;
    Ide.tpImp := tiRetrato;
    Ide.tpEmis := teNormal;
    Ide.tpAmb := taHomologacao;
    Ide.tpCTe := tcNormal;
    Ide.procEmi := peAplicativoContribuinte;
    Ide.verProc := '4.0'; // Ou sua verso
    Ide.cMunEnv := StrToInt('3203205'); // Exemplo Linhares/ES
    Ide.xMunEnv := 'LINHARES';
    Ide.UFEnv := 'ES';
    Ide.modal := mdRodoviario;
    Ide.tpServ := tsNormal;
    ide.indIEToma := TpcnindIEDest.inContribuinte; // Corrigido: indIEToma usa enum ii*
    Ide.cMunIni := 3119401; // Exemplo Coronel Fabriciano/MG
    Ide.xMunIni := 'CORONEL FABRICIANO';
    Ide.UFIni := 'MG';
    Ide.cMunFim := 2900207; // Exemplo Abar/BA
    Ide.xMunFim := 'ABARE';
    Ide.UFFim := 'BA';
    Ide.retira := rtSim;
    ide.indGlobalizado := TIndicador.tiSim; // boolean

    // Adicione mais campos conforme o modelo extenso que voc tinha
    // ...

    Emit.CRT := crtRegimeNormal;
    Emit.CNPJ := '11222333000144'; // CNPJ fictcio
    Emit.IE := '001000000000';    // IE fictcia
    Emit.xNome := 'Empresa Ficticia de Transportes Ltda';
    Emit.enderEmit.xLgr := 'Avenida das Flores';
    Emit.enderEmit.nro := '1234';
    Emit.enderEmit.xBairro := 'Centro';
    Emit.enderEmit.cMun := 3205002; // Serra/ES como exemplo
    Emit.enderEmit.xMun := 'SERRA';
    Emit.enderEmit.CEP := 29160000;
    Emit.enderEmit.UF := 'ES';

    // ... (Restante do seu preenchimento detalhado do CTe)

    autXML.New.CNPJCPF := '01234567809'; // Exemplo
  end;

  Result := TJSONTools.ObjToJson(vConhecimento.Cte);

  Result.Delete(RSXMLField);
  Result.Delete(RSXMLOriginalField);
  Result.Delete(RSNomeArqField);
  Result.Delete(RSProtocoloField);
  Result.Delete('DigVal');
  Result.Delete('infCTeSupl');

  facbr.Conhecimentos.Clear;
end;

function TACBRModelosJSONCTe.ModelDistribuicao: string;
begin
  Result := TJSONTools.SafeObjToJsonString(facbr.WebServices.DistribuicaoDFe);
end;

function TACBRModelosJSONCTe.ModelValidarRegras: TJSONObject;
begin
  Result := ModelCTe;
  // O modelo ÃƒÂ© o mesmo do CTe Ã¢â‚¬â€ envie o JSON do CTe para validaÃƒÂ§ÃƒÂ£o offline
end;

function TACBRModelosJSONCTe.ModelDACTEEvento: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add(RSXmlKey, 'XML do ProcEventoCTe em Base64 Ã¢â‚¬â€ retorna o PDF do evento');
end;


{ TACBRBridgeCTe }

procedure TACBRBridgeCTe.CarregaConfig;
var
  O: TJSONObject;
  LPfx: AnsiString;
begin
  if Trim(fcfg) = '' then
    raise Exception.Create(RSConfigEmptyError);

  try
    O := GetJSON(fcfg) as TJSONObject;
    try
      TJSONTools.JsonToObj(O, facbr.Configuracoes);

      LPfx := TJSONTools.ExtractCertificadoPFX(O);
      if LPfx <> '' then
        facbr.Configuracoes.Certificados.DadosPFX := LPfx;

      // Força configurações de SSL para OpenSSL e ModeloDF para moCTe
      with facbr.Configuracoes.Geral do
      begin
        ModeloDF := moCTe;
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

  if facbr.Configuracoes.WebServices.UF = '' then
    facbr.Configuracoes.WebServices.UF := RSDefaultUF;

  // Garante PathSchemas padrão para CTe se não foi informado
  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + RSSchemasDir + PathDelim + 'CTe';

  fcfg := '';
end;

function TACBRBridgeCTe.ReadXMLFromJSON(const jsonData: TJSONObject): string;
begin
  Result := TJSONTools.ReadXMLFromJSON(jsonData, ['xml_cte', 'CTeXML']);
end;

constructor TACBRBridgeCTe.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrCTe.Create(nil);
  fdacte := TACBrCTeDACTeFPDF.Create(nil);
  fcfg := Cfg;
  facbr.DACTE := fdacte;
end;

destructor TACBRBridgeCTe.Destroy;
begin
  FreeAndNil(facbr);
  FreeAndNil(fdacte);
  inherited Destroy;
end;

function TACBRBridgeCTe.CTe(const O: TJSONObject): TJSONObject;
var
  Item: Conhecimento;
  Lote: integer;
  jTarget, jEmit: TJSONData;
begin
  CarregaConfig;
  facbr.Conhecimentos.Clear;

  try
    Item := facbr.Conhecimentos.Add;
    Lote := 1;

    jTarget := nil;
    if Assigned(O) then
    begin
      jTarget := O.Find('CTe');
      if not Assigned(jTarget) then
        jTarget := O.Find('cte');
    end;
    if Assigned(jTarget) and (jTarget.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jTarget), Item.CTe)
    else
    begin
      jTarget := O;
      TJSONTools.JsonToObj(O, Item.CTe);
    end;

    if (Item.CTe.Emit.CNPJ = '') and Assigned(jTarget) and (jTarget.JSONType = jtObject) then
    begin
      jEmit := TJSONObject(jTarget).Find('emit');
      if not Assigned(jEmit) then
        jEmit := TJSONObject(jTarget).Find('Emit');
      if Assigned(jEmit) and (jEmit.JSONType = jtObject) then
        Item.CTe.Emit.CNPJ := TJSONObject(jEmit).Get('CNPJCPF', TJSONObject(jEmit).Get('CNPJ', ''));
    end;
  except
    on E: Exception do
    begin
      Result := TJSONTools.SafeObjToJson(nil, 'Erro na leitura do objeto JSON para CTe: ' + E.Message);
      if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
      Exit;
    end;
  end;

  try
    facbr.Conhecimentos.GerarCTe;
    facbr.SSL.CarregarCertificado;
    facbr.SSL.ValidarCNPJCertificado(Item.CTe.Emit.CNPJ);
    Item.Assinar;
    facbr.Conhecimentos.Validar;
    facbr.WebServices.Envia(Lote, True);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao enviar CTe');
    if facbr.Conhecimentos.Count > 0 then
      Result.Add('xml_autorizado', EncodeStringBase64(facbr.Conhecimentos.Items[0].XML));
  finally
    if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
  end;
end;

function TACBRBridgeCTe.Evento(const jEventos: TJSONArray): string;
var
  objEvento: TInfEventoCollectionItem;
  oEvento, InfEvento, DetJson: TJSONObject;
  I, J: integer;
  InfEventoData, XmlBase64, DetData, ArrData: TJSONData;
  ArrJson: TJSONArray;
  xmlStr, LTpEventoStr: string;
  LOk: Boolean;
begin
  CarregaConfig;
  Result := '';
  facbr.EventoCTe.Evento.Clear;

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
        facbr.Conhecimentos.LoadFromString(xmlStr)
      else
        facbr.Conhecimentos.LoadFromString(Base64.DecodeStringBase64(xmlStr));
      InfEvento.Delete('LoadXML');
      oEvento.Delete('LoadXML');
    end;

    objEvento := facbr.EventoCTe.Evento.New;
    if InfEvento = oEvento then
      TJSONTools.JsonToObj(oEvento, objEvento.InfEvento)
    else
      TJSONTools.JsonToObj(oEvento, objEvento);

    if objEvento.InfEvento.tpEvento = teNaoMapeado then
    begin
      LTpEventoStr := Trim(InfEvento.Get('tpEvento', oEvento.Get('tpEvento', '')));
      if LTpEventoStr <> '' then
        objEvento.InfEvento.tpEvento := StrToTpEventoCTe(LOk, LTpEventoStr);
    end;

    DetData := InfEvento.Find('detEvento');
    if not Assigned(DetData) then
      DetData := InfEvento.Find('DetEvento');

    if Assigned(DetData) and (DetData.JSONType = jtObject) then
    begin
      DetJson := TJSONObject(DetData);
      TJSONTools.JsonToObj(DetJson, objEvento.InfEvento.detEvento);

      ArrData := DetJson.Find('infCorrecao');
      if not Assigned(ArrData) then
        ArrData := DetJson.Find('InfCorrecao');
      if Assigned(ArrData) and (ArrData.JSONType = jtArray) then
      begin
        ArrJson := TJSONArray(ArrData);
        objEvento.InfEvento.detEvento.infCorrecao.Clear;
        for J := 0 to ArrJson.Count - 1 do
          if ArrJson.Items[J].JSONType = jtObject then
            TJSONTools.JsonToObj(TJSONObject(ArrJson.Items[J]), objEvento.InfEvento.detEvento.infCorrecao.New);
      end;

      ArrData := DetJson.Find('infEntrega');
      if not Assigned(ArrData) then
        ArrData := DetJson.Find('InfEntrega');
      if Assigned(ArrData) and (ArrData.JSONType = jtArray) then
      begin
        ArrJson := TJSONArray(ArrData);
        objEvento.InfEvento.detEvento.infEntrega.Clear;
        for J := 0 to ArrJson.Count - 1 do
          if ArrJson.Items[J].JSONType = jtObject then
            TJSONTools.JsonToObj(TJSONObject(ArrJson.Items[J]), objEvento.InfEvento.detEvento.infEntrega.New);
      end;

      ArrData := DetJson.Find('infGTV');
      if not Assigned(ArrData) then
        ArrData := DetJson.Find('InfGTV');
      if Assigned(ArrData) and (ArrData.JSONType = jtArray) then
      begin
        ArrJson := TJSONArray(ArrData);
        objEvento.InfEvento.detEvento.infGTV.Clear;
        for J := 0 to ArrJson.Count - 1 do
          if ArrJson.Items[J].JSONType = jtObject then
            TJSONTools.JsonToObj(TJSONObject(ArrJson.Items[J]), objEvento.InfEvento.detEvento.infGTV.New);
      end;
    end;

    with objEvento.InfEvento do
    begin
      if dhEvento = 0 then dhEvento := Now;
      if (CNPJ = '') and (Length(chCTe) >= 20) then CNPJ := Copy(chCTe, 7, 14);
      if (cOrgao = 0) and (Length(chCTe) >= 2) then cOrgao := StrToIntDef(Copy(chCTe, 1, 2), 0);
      if nSeqEvento <= 0 then nSeqEvento := 1;
    end;
  end;

  facbr.SSL.CarregarCertificado;
  facbr.EnviarEvento(1);
  Result := TJSONTools.SafeObjToJsonString(
    facbr.WebServices.EnvEvento, 'Erro ao enviar evento de CT-e');
end;

function TACBRBridgeCTe.Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
var
  objDistribuicao: TDistribuicaoDFe;
  UF: TJSONString;
  CNPJCPF, ultNSU, NSU, chCTe: TJSONString;
begin
  CarregaConfig;
  Result := nil;

  objDistribuicao := facbr.WebServices.DistribuicaoDFe;

  if jDistribuicao.Find(RSUFField, UF) then
  begin
    if not MatchStr(UF.ToString, CodigosIBGE) then
    begin
      Result := TJSONObject.Create;
      Result.Add(RSErrorField, RSInvalidUFCode);
      Exit;
    end;
    objDistribuicao.cUFAutor := StrToInt(UF.ToString);
  end;

  if jDistribuicao.Find(RSCNPJCPFField, CNPJCPF) then
    objDistribuicao.CNPJCPF := CNPJCPF.ToString;

  if jDistribuicao.Find(RSUltNSUField, ultNSU) then
    objDistribuicao.ultNSU := ultNSU.ToString;

  if jDistribuicao.Find(RSNSUField, NSU) then
    objDistribuicao.NSU := NSU.ToString;

  if jDistribuicao.Find(RSChCTeField, chCTe) then
    objDistribuicao.chCTe := chCTe.ToString;

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



function TACBRBridgeCTe.StatusServico(const jStatus: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  try
    facbr.WebServices.StatusServico.Executar;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.StatusServico, 'Erro ao consultar status');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao consultar status: ' + E.Message);
  end;
end;

function TACBRBridgeCTe.Consulta(const jConsulta: TJSONObject): TJSONObject;
var
  Chave: TJSONData;
begin
  CarregaConfig;

  Chave := jConsulta.Find('CTeChave');
  if not Assigned(Chave) then Chave := jConsulta.Find('chCTe');
  if not Assigned(Chave) then Chave := jConsulta.Find('chave');
  if not Assigned(Chave) then Chave := jConsulta.Find('Chave');

  if Assigned(Chave) and (Trim(Chave.AsString) <> '') then
  begin
    try
      facbr.WebServices.Consulta.CTeChave := Trim(Chave.AsString);
      facbr.WebServices.Consulta.Executar;
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consulta, 'Erro na consulta');
    except
      on E: Exception do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro na consulta: ' + E.Message);
    end;
  end
  else
    Result := TJSONTools.SafeObjToJson(nil, 'Chave nao informada para consulta.');
end;

function TACBRBridgeCTe.Inutilizacao(const jInutilizacao: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  
  try
    TJSONTools.JsonToObj(jInutilizacao, facbr.WebServices.Inutilizacao);
    facbr.WebServices.Inutilizacao.Executar;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Inutilizacao, 'Erro na inutilizacao');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro na inutilizacao: ' + E.Message);
  end;
end;


function TACBRBridgeCTe.Cancelamento(const jCancelamento: TJSONObject): TJSONObject;
var
  chCTe, nProt, xJust, xmlPath: string;
  CancObj: TJSONObject;
begin
  CarregaConfig;
  Result := nil;

  CancObj := jCancelamento.Extract('cancelamento') as TJSONObject;
  if not Assigned(CancObj) then CancObj := jCancelamento;

  try
    try
      chCTe := CancObj.Get('chCTe', '');
      nProt := CancObj.Get('nProt', '');
      xJust := CancObj.Get('xJust', '');

      if chCTe = '' then chCTe := CancObj.Get(RSChaveField, '');
      if nProt = '' then nProt := CancObj.Get('protocolo', '');
      if xJust = '' then xJust := CancObj.Get('justificativa', '');

      facbr.Conhecimentos.Clear;
      xmlPath := ExtractFilePath(ParamStr(0)) + RSDocsDir + PathDelim + chCTe + '-cte.xml';
      if (not FileExists(xmlPath)) and (facbr.Configuracoes.Arquivos.PathSalvar <> '') then
        xmlPath := IncludeTrailingPathDelimiter(facbr.Configuracoes.Arquivos.PathSalvar) + chCTe + '-cte.xml';

      if FileExists(xmlPath) then
        facbr.Conhecimentos.LoadFromFile(xmlPath);

      facbr.SSL.CarregarCertificado;

      if (facbr.Conhecimentos.Count > 0) and (nProt = '') then
      begin
        facbr.Cancelamento(xJust, 1);
      end
      else
      begin
        facbr.EventoCTe.Evento.Clear;
        with facbr.EventoCTe.Evento.New do
        begin
          InfEvento.chCTe := chCTe;
          InfEvento.CNPJ := CancObj.Get('CNPJ', CancObj.Get('cnpj', Copy(chCTe, 7, 14)));
          InfEvento.cOrgao := StrToIntDef(Copy(chCTe, 1, 2), 0);
          InfEvento.dhEvento := Now;
          InfEvento.tpEvento := teCancelamento;
          InfEvento.nSeqEvento := 1;
          InfEvento.detEvento.nProt := nProt;
          InfEvento.detEvento.xJust := xJust;
        end;
        facbr.EnviarEvento(1);
      end;

      Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento, 'Cancelamento CT-e processado');
    except
      on E: Exception do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro no cancelamento: ' + E.Message);
    end;
  finally
    if (CancObj <> jCancelamento) and Assigned(CancObj) then CancObj.Free;
    facbr.Conhecimentos.Clear;
  end;
end;

function TACBRBridgeCTe.CTeFromXML(const jXML: TJSONObject): TJSONObject;
var
  xmlBase64: string;
begin
  CarregaConfig;
  try
    xmlBase64 := ReadXMLFromJSON(jXML);
    try
      facbr.Conhecimentos.LoadFromString(xmlBase64);
    except
      on E: Exception do
        raise Exception.Create('Falha no LoadFromString: ' + E.Message);
    end;
    
    if facbr.Conhecimentos.Count > 0 then
    begin
      try
        Result := TJSONTools.SafeObjToJson(facbr.Conhecimentos.Items[0].CTe, 'Erro no SafeObjToJson');
      except
        on E: Exception do
          raise Exception.Create('Falha no SafeObjToJson interno: ' + E.Message);
      end;
      
      if Result.Find(RSStatusField) = nil then
      begin
        // Limpeza opcional de campos internos
        Result.Delete(RSXMLField);
        Result.Delete(RSXMLOriginalField);
        Result.Delete(RSNomeArqField);
        Result.Delete(RSProtocoloField);
        Result.Delete('DigVal');
        Result.Delete('infCTeSupl');
      end;
    end
    else
       Result := TJSONTools.SafeObjToJson(nil, 'Nenhum CTe carregado do XML.');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'GLOBAL ERROR: ' + E.Message);
  end;
  facbr.Conhecimentos.Clear;
end;

function TACBRBridgeCTe.CTeToXML(const jCTe: TJSONObject): TJSONObject;
var
  ConhecimentoCTe: TCTe;
  xmlString: string;
  jTarget, jEmit: TJSONData;
begin
  CarregaConfig;

  try
    ConhecimentoCTe := facbr.Conhecimentos.Add.CTe;
    jTarget := nil;
    if Assigned(jCTe) then
    begin
      jTarget := jCTe.Find('CTe');
      if not Assigned(jTarget) then
        jTarget := jCTe.Find('cte');
    end;
    if Assigned(jTarget) and (jTarget.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jTarget), ConhecimentoCTe)
    else
    begin
      jTarget := jCTe;
      TJSONTools.JsonToObj(jCTe, ConhecimentoCTe);
    end;

    if (ConhecimentoCTe.Emit.CNPJ = '') and Assigned(jTarget) and (jTarget.JSONType = jtObject) then
    begin
      jEmit := TJSONObject(jTarget).Find('emit');
      if not Assigned(jEmit) then
        jEmit := TJSONObject(jTarget).Find('Emit');
      if Assigned(jEmit) and (jEmit.JSONType = jtObject) then
        ConhecimentoCTe.Emit.CNPJ := TJSONObject(jEmit).Get('CNPJCPF', TJSONObject(jEmit).Get('CNPJ', ''));
    end;
  except
    on E: Exception do
    begin
      Result := TJSONTools.SafeObjToJson(nil, 'Erro na leitura do objeto JSON para CTe: ' + E.Message);
      if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
      Exit;
    end;
  end;

  try
    facbr.Conhecimentos.GerarCTe;
    xmlString := facbr.Conhecimentos.Items[0].XMLOriginal;
    if xmlString = '' then
      xmlString := facbr.Conhecimentos.Items[0].XML;

    Result := TJSONObject.Create;
    Result.Add(RSXmlKey, EncodeStringBase64(xmlString));
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao gerar XML do CTe: ' + E.Message);
  end;

  if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
end;

function TACBRBridgeCTe.DACTE(const xmlData: TJSONObject; const OnlyURL: Boolean = False): TJSONObject;
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
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, E.Message);
      Exit;
    end;
  end;

  facbr.Conhecimentos.Clear;
  try
    try
      facbr.Conhecimentos.LoadFromString(stringXml);
    except
      on E: Exception do
      begin
        Result.Add(RSErrorField, RSXMLReadError + E.Message);
        Exit;
      end;
    end;

    stringXml := '';

    if facbr.Conhecimentos.Count = 0 then
    begin
      Result.Add(RSErrorField, 'Nenhum CT-e foi carregado a partir do XML.');
      Exit;
    end;

    chClean := StringReplace(facbr.Conhecimentos.Items[0].CTe.infCTe.ID, 'CTe', '', [rfIgnoreCase]);

    if facbr.Conhecimentos.Items[0].CTe.Ide.tpImp <> TpcnTipoImpressao.tiPaisagem then
      fdacte.TipoDACTE := tiRetrato
    else
      fdacte.TipoDACTE := tiPaisagem;

    fdacte.Cancelada := (facbr.Conhecimentos.Items[0].CTe.procCTe.cStat in [101, 151, 155]);
    fdacte.MostraPreview := False;
    fdacte.MostraStatus := False;
    fdacte.MostraSetup := False;

    pdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
    if not DirectoryExists(pdfDir) then
      CreateDir(pdfDir);

    fileName := pdfDir + chClean + '-cte.pdf';
    if FileExists(fileName) then
      SysUtils.DeleteFile(fileName);

    try
      fdacte.PathPDF := pdfDir;
      facbr.DACTE := fdacte;
      facbr.Conhecimentos.ImprimirPDF;

      if not FileExists(fileName) then
        fileName := fdacte.ArquivoPDF;

      if not FileExists(fileName) then
        fileName := pdfDir + facbr.Conhecimentos.Items[0].CTe.infCTe.ID + '-cte.pdf';

      if not FileExists(fileName) then
      begin
        Result.Add(RSErrorField, 'Arquivo PDF nao foi gerado em disco pelo ACBr.');
        Exit;
      end;

      if not OnlyURL then
      begin
        arquivofinal := FileToStringBase64(fileName, False, tamanho);
        Result.Add(RSPDFField, arquivofinal);
        Result.Add(RSTamanhoField, tamanho.ToString);
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSErrorField, 'Falha ao gerar o PDF no ACBr: ' + E.Message);
        Exit;
      end;
    end;

    Result.Add(RSChaveField, chClean);
    Result.Add(RSURLField, '/cte/pdf/' + chClean);

    if xmlData.Find(RSIDField, id) then
      Result.Add(RSIDField, id);
  finally
    facbr.Conhecimentos.Clear;
  end;
end;

{ Valida o XML contra o Schema sem enviar para a SEFAZ }
function TACBRBridgeCTe.ValidarRegras(const jCTe: TJSONObject): TJSONObject;
var
  ConhecimentoCTe: TCTe;
  jTarget, jEmit: TJSONData;
begin
  CarregaConfig;
  Result := nil;

  try
    // Limpa conhecimentos anteriores
    facbr.Conhecimentos.Clear;
    ConhecimentoCTe := facbr.Conhecimentos.Add.CTe;

    // Converte JSON para CTe
    try
      jTarget := nil;
      if Assigned(jCTe) then
      begin
        jTarget := jCTe.Find('CTe');
        if not Assigned(jTarget) then
          jTarget := jCTe.Find('cte');
      end;
      if Assigned(jTarget) and (jTarget.JSONType = jtObject) then
        TJSONTools.JsonToObj(TJSONObject(jTarget), ConhecimentoCTe)
      else
      begin
        jTarget := jCTe;
        TJSONTools.JsonToObj(jCTe, ConhecimentoCTe);
      end;

      if (ConhecimentoCTe.Emit.CNPJ = '') and Assigned(jTarget) and (jTarget.JSONType = jtObject) then
      begin
        jEmit := TJSONObject(jTarget).Find('emit');
        if not Assigned(jEmit) then
          jEmit := TJSONObject(jTarget).Find('Emit');
        if Assigned(jEmit) and (jEmit.JSONType = jtObject) then
          ConhecimentoCTe.Emit.CNPJ := TJSONObject(jEmit).Get('CNPJCPF', TJSONObject(jEmit).Get('CNPJ', ''));
      end;
    except
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, 'erro_parse');
        Result.Add(RSMessageField, 'Erro na conversao JSON para Objeto: ' + E.Message);
        Exit;
      end;
    end;

    // Tenta Validar (Assina automaticamente se necessário para validar digest value)
    try
      facbr.Conhecimentos.Items[0].Assinar;
      facbr.Conhecimentos.Items[0].Validar;

      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSMessageField, 'XML Valido e Assinado');
      // Retorna o XML assinado caso o cliente queira salvar
      Result.Add('xml_assinado', EncodeStringBase64(facbr.Conhecimentos.Items[0].XML));
    except
      on E: Exception do
      begin
        Result := TJSONTools.SafeObjToJson(nil, E.Message);
        Result.Delete(RSStatusField);
        Result.Add(RSStatusField, 'erro_validacao');
        // O ACBr costuma popular a lista de erros de validação
        if facbr.Conhecimentos.Items[0].ErroValidacao <> '' then
           Result.Add('detalhes', facbr.Conhecimentos.Items[0].ErroValidacao);
      end;
    end;

  finally
    facbr.Conhecimentos.Clear;
  end;
end;

{ Gera PDF de Evento (Cancelamento ou CCe) }
function TACBRBridgeCTe.DACTEEvento(const xmlEvento: TJSONObject): TJSONObject;
var
  arquivofinal: string;
  stringXml, cteXmlStr, fileName, pdfDir: string;
  evtXmlNode, cteXmlNode: TJSONData;
  tamanho: integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  try
    evtXmlNode := xmlEvento.Find('XMLEvento');
    if not Assigned(evtXmlNode) then evtXmlNode := xmlEvento.Find('xml_evento');
    if Assigned(evtXmlNode) and (Trim(evtXmlNode.AsString) <> '') then
    begin
      stringXml := Trim(evtXmlNode.AsString);
      if stringXml[1] <> '<' then
        stringXml := DecodeStringBase64(stringXml);
    end
    else
      stringXml := ReadXMLFromJSON(xmlEvento);
  except
    on E: Exception do
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, E.Message);
      Result.Add(RSMessageField, E.Message);
      Exit;
    end;
  end;

  facbr.Conhecimentos.Clear;
  facbr.EventoCTe.Evento.Clear;
  try
    try
      cteXmlNode := xmlEvento.Find('XMLCTe');
      if not Assigned(cteXmlNode) then cteXmlNode := xmlEvento.Find('xml_cte');
      if not Assigned(cteXmlNode) then cteXmlNode := xmlEvento.Find('CTeXML');
      if not Assigned(cteXmlNode) then cteXmlNode := xmlEvento.Find(RSXMLField);
      if not Assigned(cteXmlNode) then cteXmlNode := xmlEvento.Find(RSXmlKey);
      if Assigned(cteXmlNode) and (Trim(cteXmlNode.AsString) <> '') then
      begin
        cteXmlStr := Trim(cteXmlNode.AsString);
        if cteXmlStr[1] <> '<' then
          cteXmlStr := DecodeStringBase64(cteXmlStr);
        if cteXmlStr <> stringXml then
          facbr.Conhecimentos.LoadFromString(cteXmlStr);
      end;

      facbr.EventoCTe.LerXMLFromString(stringXml);

      if facbr.EventoCTe.Evento.Count = 0 then
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Nenhum evento CT-e foi carregado a partir do XML.');
        Result.Add(RSMessageField, 'Nenhum evento CT-e foi carregado a partir do XML.');
        Exit;
      end;

      if facbr.Conhecimentos.Count = 0 then
        facbr.Conhecimentos.Add.CTe.infCTe.ID := 'CTe' + facbr.EventoCTe.Evento.Items[0].InfEvento.chCTe;

      fdacte.MostraPreview := False;
      fdacte.MostraStatus := False;
      fdacte.MostraSetup := False;

      pdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
      if not DirectoryExists(pdfDir) then
        CreateDir(pdfDir);

      fdacte.PathPDF := pdfDir;
      facbr.DACTE := fdacte;
      facbr.ImprimirEventoPDF;
      fileName := fdacte.ArquivoPDF;

      arquivofinal := FileToStringBase64(fileName, False, tamanho);

      Result.Add(RSPDFField, arquivofinal);
      Result.Add(RSTamanhoField, tamanho.ToString);
      Result.Add(RSChaveField, facbr.EventoCTe.Evento.Items[0].InfEvento.chCTe);
      Result.Add(RSStatusField, RSStatusSucesso);
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Erro ao gerar PDF do Evento: ' + E.Message);
        Result.Add(RSMessageField, 'Erro ao gerar PDF do Evento: ' + E.Message);
      end;
    end;
  finally
    facbr.EventoCTe.Evento.Clear;
    facbr.Conhecimentos.Clear;
  end;
end;

function TACBRBridgeCTe.DebugConfig: TJSONObject;
begin
  CarregaConfig;
  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

function TACBRBridgeCTe.DebugCTe(const O: TJSONObject): TJSONObject;
var
  Item: Conhecimento;
  jTarget, jEmit: TJSONData;
begin
  CarregaConfig;
  try
    Item := facbr.Conhecimentos.Add;
    jTarget := nil;
    if Assigned(O) then
    begin
      jTarget := O.Find('CTe');
      if not Assigned(jTarget) then
        jTarget := O.Find('cte');
    end;
    if Assigned(jTarget) and (jTarget.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jTarget), Item.CTe)
    else
    begin
      jTarget := O;
      TJSONTools.JsonToObj(O, Item.CTe);
    end;

    if (Item.CTe.Emit.CNPJ = '') and Assigned(jTarget) and (jTarget.JSONType = jtObject) then
    begin
      jEmit := TJSONObject(jTarget).Find('emit');
      if not Assigned(jEmit) then
        jEmit := TJSONObject(jTarget).Find('Emit');
      if Assigned(jEmit) and (jEmit.JSONType = jtObject) then
        Item.CTe.Emit.CNPJ := TJSONObject(jEmit).Get('CNPJCPF', TJSONObject(jEmit).Get('CNPJ', ''));
    end;
    
    Result := TJSONTools.ObjToJson(Item.CTe);
  except
    on E: Exception do
    begin
      Result := TJSONTools.SafeObjToJson(nil, 'Erro no DebugCTe: ' + E.Message);
      Exit;
    end;
  end;
  facbr.Conhecimentos.Clear;
end;

function TACBRBridgeCTe.TesteConfig: boolean;
begin
  try
    CarregaConfig;
    Result := True;
  except
    Result := False;
  end;
end;

end.
