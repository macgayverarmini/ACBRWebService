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
    function CTe(const jCTe: TJSONObject): TJSONObject;
    function Cancelamento(const jCancelamento: TJSONObject): TJSONObject;
    function CTeFromXML(const jXML: TJSONObject): TJSONObject;
    function CTeToXML(const jCTe: TJSONObject): TJSONObject;
    function DACTE(const xmlData: TJSONObject): TJSONObject;
    function ValidarRegras(const jCTe: TJSONObject): TJSONObject;
    function DACTEEvento(const xmlEvento: TJSONObject): TJSONObject;

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
    UF := 'ES'; // Exemplo
    TimeOut := 15000;
    Visualizar := False;
  end;

  with facbr.Configuracoes.Certificados do
  begin
    ArquivoPFX := 'C:\caminho\seu_certificado.pfx'; // Exemplo
    Senha := 'sua_senha'; // Exemplo
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
  Result.Add('xml', 'XML do CTe em Base64 Ã¢â‚¬â€ retorna o CTe como JSON');
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

  Result.Delete('XML');
  Result.Delete('XMLOriginal');
  Result.Delete('NomeArq');
  Result.Delete('Protocolo');
  Result.Delete('DigVal');
  Result.Delete('infCTeSupl');

  facbr.Conhecimentos.Clear;
end;

function TACBRModelosJSONCTe.ModelDistribuicao: string;
begin
  //  Evento := facbr.WebServices.DistribuicaoDFe.new;
  Result := TJSONTools.SafeObjToJsonString(facbr.WebServices.DistribuicaoDFe);
  //  facbr.EventoNFe.Evento.Clear;
end;

function TACBRModelosJSONCTe.ModelValidarRegras: TJSONObject;
begin
  Result := ModelCTe;
  // O modelo ÃƒÂ© o mesmo do CTe Ã¢â‚¬â€ envie o JSON do CTe para validaÃƒÂ§ÃƒÂ£o offline
end;

function TACBRModelosJSONCTe.ModelDACTEEvento: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('xml', 'XML do ProcEventoCTe em Base64 Ã¢â‚¬â€ retorna o PDF do evento');
end;


// function TACBRModelosJSONCTe.ModelConsultaSituacaoServico removida

{ TACBRBridgeCTe }

procedure TACBRBridgeCTe.CarregaConfig;
var
  O: TJSONObject;
begin

  if fcfg = '' then
    Exit;

  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
  finally
    O.Free;
  end;

  fcfg := '';

end;

function TACBRBridgeCTe.ReadXMLFromJSON(const jsonData: TJSONObject): string;
var
  xmlBase64JSON: TJSONString;
  xmlBase64: string;
begin
  if not jsonData.Find('xml', xmlBase64JSON) then
    raise Exception.Create('Parmetro "xml" (string Base64) no encontrado no JSON.');

  xmlBase64 := xmlBase64JSON.AsString;
  if xmlBase64 = '' then
    raise Exception.Create('Parmetro "xml" est vazio no JSON.');

  try
    Result := DecodeStringBase64(xmlBase64); // Funo de Classes ou Base64 unit
  except
    on E: Exception do
      raise Exception.Create(RSInvalidBase64XML + E.Message);
  end;
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

function TACBRBridgeCTe.CTe(const jCTe: TJSONObject): TJSONObject;
var
  ConhecimentoCTe: TCTe;
  Lote: integer;
begin
  CarregaConfig;

  try
    ConhecimentoCTe := facbr.Conhecimentos.Add.CTe;
    Lote := 1;

    TJSONTools.JsonToObj(jCTe, ConhecimentoCTe);
  except
    on E: Exception do
    begin
      Result := TJSONTools.SafeObjToJson(nil, 'Erro na leitura do objeto JSON para CTe: ' + E.Message);
      if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
      Exit;
    end;
  end;

  try
    facbr.WebServices.Envia(Lote, True); // True para Assinar
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao enviar CTe');
  finally
    if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
  end;
end;

function TACBRBridgeCTe.Evento(const jEventos: TJSONArray): string;
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
      facbr.Conhecimentos.LoadFromString(Base64.DecodeStringBase64(XmlBase64.AsString));

    objEvento := facbr.EventoCTe.Evento.New;
    TJSONTools.JsonToObj(oEvento, objEvento);
  end;

  facbr.EnviarEvento(1);
  Result := TJSONTools.ObjToJsonString(
    facbr.WebServices.EnvEvento.EventoRetorno.retEvento);
end;

function TACBRBridgeCTe.Distribuicao(const jDistribuicao: TJSONObject): TJSONObject;
var
  objDistribuicao: TDistribuicaoDFe;
  UF: TJSONString;
  CNPJCPF, ultNSU, NSU, chCTe: TJSONString;
const
  CodigosIBGE: array [0..26] of string = (
    '11', '12', '13', '14', '15', '16', '17', '21', '22', '23', '24',
    '25', '26', '27', '28', '29', '31',
    '32', '33', '35', '41', '42', '43', '50', '51', '52', '53');
begin
  CarregaConfig;

  Result := TJSONObject.Create;

  objDistribuicao := facbr.WebServices.DistribuicaoDFe;

  if jDistribuicao.Find('UF', UF) then
  begin
    if not MatchStr(UF.ToString, CodigosIBGE) then
    begin
      Result.Add('error', 'Cdigo de UF invlido');
      Exit;
    end;
    objDistribuicao.cUFAutor := StrToInt(UF.ToString);
  end;

  if jDistribuicao.Find('CNPJCPF', CNPJCPF) then
    objDistribuicao.CNPJCPF := CNPJCPF.ToString;

  if jDistribuicao.Find('ultNSU', ultNSU) then
    objDistribuicao.ultNSU := ultNSU.ToString;

  if jDistribuicao.Find('NSU', NSU) then
    objDistribuicao.NSU := NSU.ToString;

  if jDistribuicao.Find('chCTe', chCTe) then
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
        Result.Add('error', E.message);
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

  if jConsulta.Find('CTeChave', Chave) then
  begin
    try
      facbr.WebServices.Consulta.CTeChave := Chave.AsString;
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
  idLote: Integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  idLote := 1;
  facbr.EventoCTe.Evento.Clear;
  facbr.EventoCTe.idLote := idLote;

  try
    // Popula o objeto evento diretamente do JSON
    TJSONTools.JsonToObj(jCancelamento, facbr.EventoCTe.Evento.New);
  except
     on E: Exception do
     begin
       Result.Add('status', 'erro');
       Result.Add('message', 'Erro ao converter JSON para Evento: ' + E.Message);
       Exit;
     end;
  end;

  // Garante tipo de evento cancelamento e data se falhar
  with facbr.EventoCTe.Evento.Items[0].InfEvento do
  begin
     if tpEvento <> teCancelamento then tpEvento := teCancelamento;
     if dhEvento = 0 then dhEvento := Now;
     if CNPJ = '' then CNPJ := Copy(chCTe, 7, 14);
  end;

  try
    facbr.EnviarEvento(idLote);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento.EventoRetorno.retEvento, 'Erro ao enviar evento de cancelamento');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao enviar evento de cancelamento: ' + E.Message);
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
        Result.Delete('XML');
        Result.Delete('XMLOriginal');
        Result.Delete('NomeArq');
        Result.Delete('Protocolo');
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
begin
  CarregaConfig;

  try
    ConhecimentoCTe := facbr.Conhecimentos.Add.CTe;
    TJSONTools.JsonToObj(jCTe, ConhecimentoCTe);
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
    Result.Add('xml', EncodeStringBase64(xmlString));
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao gerar XML do CTe: ' + E.Message);
  end;

  if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
end;

function TACBRBridgeCTe.DACTE(const xmlData: TJSONObject): TJSONObject;
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
      Result.Add('error', E.Message);
      Exit;
    end;
  end;

  try
    facbr.Conhecimentos.LoadFromString(stringXml);
  except
    on E: Exception do
    begin
      Result.Add('error', 'Erro na leitura do XML: ' + E.Message);
      Exit;
    end;
  end;

  // Esvazia a string para liberar da memria logo o xml
  stringXml := '';

  if facbr.Conhecimentos.Count = 0 then
  begin
    Result.Add('error', 'Nenhum CT-e foi carregado a partir do XML.');
    Exit;
  end;

  // O acesso a propriedade TipoDanfe se faz somente diretamente pelo objeto.
  if facbr.Conhecimentos.Items[0].CTe.Ide.tpImp <> TpcnTipoImpressao.tiPaisagem then
    fdacte.TipoDACTE := tiRetrato
  else
    fdacte.TipoDACTE := tiPaisagem;

  // Como  um aplicativo console, jamais a propriedade MostraStatus deve ser true.
  fdacte.MostraPreview := False;
  fdacte.MostraStatus := False;
  fdacte.MostraSetup := False;

  //Gerando arquivo temporrio
  fileName := GetTempFileName;
  // Realiza o processo de transformar o XML em PDF (Danfe)
  try
    fdacte.PathPDF := filename;
    facbr.Conhecimentos.ImprimirPDF;
    filename := fdacte.ArquivoPDF;
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

  // Converte a stream do relatrio para base64
  Result.Add('pdf', arquivofinal);
  // Chave de Acesso da NF-e
  Result.Add('chave', facbr.Conhecimentos.Items[0].CTe.infCTe.ID);
  // Tamanho em Bytes
  Result.Add('tamanho', tamanho.ToString);
  // Adiciona o identificador nico se ele existir
  if xmlData.Find('id', id) then
    Result.Add('id', id);

end;

// function TACBRBridgeCTe.ConsultaSituacaoServico removida

{ Valida o XML contra o Schema sem enviar para a SEFAZ }
function TACBRBridgeCTe.ValidarRegras(const jCTe: TJSONObject): TJSONObject;
var
  ConhecimentoCTe: TCTe;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  try
    // Limpa conhecimentos anteriores
    facbr.Conhecimentos.Clear;
    ConhecimentoCTe := facbr.Conhecimentos.Add.CTe;

    // Converte JSON para CTe
    try
      TJSONTools.JsonToObj(jCTe, ConhecimentoCTe);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro_parse');
        Result.Add('message', 'Erro na conversao JSON para Objeto: ' + E.Message);
        Exit;
      end;
    end;

    // Tenta Validar (Assina automaticamente se necessÃƒÂ¡rio para validar digest value)
    try
      facbr.Conhecimentos.Items[0].Assinar;
      facbr.Conhecimentos.Items[0].Validar;

      Result := TJSONObject.Create;
      Result.Add(RSStatusField, 'sucesso');
      Result.Add(RSMessageField, 'XML Valido e Assinado');
      // Retorna o XML assinado caso o cliente queira salvar
      Result.Add('xml_assinado', EncodeStringBase64(facbr.Conhecimentos.Items[0].XML));
    except
      on E: Exception do
      begin
        Result := TJSONTools.SafeObjToJson(nil, E.Message);
        Result.Delete(RSStatusField);
        Result.Add(RSStatusField, 'erro_validacao');
        // O ACBr costuma popular a lista de erros de validaÃƒÂ§ÃƒÂ£o
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
  stringXml, fileName: string;
  tamanho: integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  // 1. Carregar o XML do Evento (ProcEventoCTe)
  try
    stringXml := ReadXMLFromJSON(xmlEvento);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', E.Message);
      Exit;
    end;
  end;

  try
    // Carrega o XML do evento no componente
    facbr.EventoCTe.Evento.Clear;
    facbr.EventoCTe.LerXMLFromString(stringXml);

    // ConfiguraÃƒÂ§ÃƒÂµes visuais bÃƒÂ¡sicas
    fdacte.MostraPreview := False;
    fdacte.MostraStatus := False;

    fileName := GetTempFileName;
    fdacte.PathPDF := fileName;

    // Chama a impressÃƒÂ£o do evento
    facbr.ImprimirEventoPDF;
    fileName := fdacte.ArquivoPDF;

    // Converte para Base64
    arquivofinal := FileToStringBase64(fileName, True, tamanho);

    Result.Add('pdf', arquivofinal);
    Result.Add('tamanho', tamanho.ToString);
    Result.Add('status', 'sucesso');

  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro ao gerar PDF do Evento: ' + E.Message);
    end;
  end;
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

// Implementao de FileToStringBase64 (se no estiver em streamtools ou ACBrUtil de forma acessvel)
// Exemplo:
// function FileToStringBase64(const AFileName: string; DeleteFileAfter: Boolean; out ASize: Integer): string;
// var
//   LStream: TFileStream;
//   MemStream: TMemoryStream;
//   Base64Stream: TStringStream; // Para receber o Base64
// begin
//   Result := '';
//   ASize := 0;
//   if not FileExists(AFileName) then Exit;

//   LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
//   try
//     ASize := LStream.Size;
//     MemStream := TMemoryStream.Create;
//     try
//       MemStream.LoadFromStream(LStream);
//       MemStream.Position := 0;
//       Base64Stream := TStringStream.Create('');
//       try
//         EnBase64(MemStream, Base64Stream); // Funo da unit Base64 do FPC
//         Result := Base64Stream.DataString;
//       finally
//         Base64Stream.Free;
//       end;
//     finally
//       MemStream.Free;
//     end;
//   finally
//     LStream.Free;
//   end;

//   if DeleteFileAfter then
//     System.DeleteFile(AFileName); // ou SysUtils.DeleteFile
// end;

// Certifique-se que UFtoCUF esteja implementada ou em units acessveis.
// Geralmente est em pcnAuxiliar do ACBr. Se no, uma implementao simples:
// function UFtoCUF(const AUF: string): Integer;
// begin
//   // Implementao de converso de Sigla UF para Cdigo IBGE
//   // Exemplo: if AUF = 'SP' then Result := 35 else ...
//   // O ACBr geralmente tem essa funo em ACBrUtil ou pcnAuxiliar.
//   // Se voc usa o componente ACBr, ele mesmo pode fazer essa converso
//   // ao atribuir facbr.Configuracoes.WebServices.UF := 'SP'; e depois usar
//   // facbr.Configuracoes.WebServices.UF ????????? StrToInteger(pcnCodUFIBGE[UF]);
//   // Para o CTe.Ide.cUF, voc precisar do cdigo IBGE numrico.
//   Result := TACBrDFe.StrUFToCodIBGE(AUF); // Use a funo do ACBr se disponvel
// end;

end.
