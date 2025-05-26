unit method.acbr.cte;

{$mode Delphi}

interface

uses
  RTTI,
  ACBrCTe,
  ACBrCTe.EnvEvento,
  ACBrCTe.EventoClass,
  ACBrCTeConhecimentos,
  ACBrCTeDACTeRLClass, // Para o tipo TACBrCTeDACTeRL
  ACBrCTeWebServices,
  // ACBrDFeDANFeReport, // Revisar se � realmente necess�rio
  ACBrMail,
  ACBrDFeSSL,
  ACBrDFeConfiguracoes,
  ACBrCTeConfiguracoes,
  ACBrCTe.Classes,
  pcnConversao,      // Geral
  pcteConversaoCTe, // Espec�fico de CTe
  StrUtils,
  Variants,
  Controls, // Provavelmente necess�rio por ACBrCTeDACTeRL
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  streamtools,
  ACBrCTeDACTeRL, // Para a inst�ncia fdacte
  ACBrUtil;       // Para GetTempFileName e possivelmente FileToStringBase64

type

  { TACBRBridgeCTe }

  TACBRBridgeCTe = class
  private
    fcfg: string;
    facbr: TACBrCTe;
    fdacte: TACBrCTeDACTeRL;

    procedure CarregaConfig;
    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function Evento(const jEventos: TJSONArray): string;
    function CTe(const jCTe: TJSONObject): TJSONObject;
    function ConsultarCTe(const jConsulta: TJSONObject): TJSONObject;
    function DACTE(const xmlData: TJSONObject): TJSONObject;
    // function ConsultaSituacaoServico removida

    function TesteConfig: boolean;
  end;

  { TACBRModelosJSONCTe - Salva os retornos de modelo de requisi��es CTe }

  TACBRModelosJSONCTe = class(TACBRBridgeCTe)
  private
  public
    function ModelConfig: TJSONObject;
    function ModelEvento: TJSONObject;
    function ModelCTe: TJSONObject;
    function ModelConsultaCTe: TJSONObject;
    // function ModelConsultaSituacaoServico removida
  end;

implementation

// Se precisar de pcnAuxiliar ou outras units de convers�o (UFtoCUF), adicione aqui.
// Exemplo: pcnAuxiliar (para UFtoCUF, se n�o estiver em pcnConversao ou pcteConversaoCTe)

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

function TACBRModelosJSONCTe.ModelEvento: TJSONObject;
begin
  facbr.EventoCTe.Evento.New;
  // Preencher campos m�nimos de exemplo se desejado
  Result := TJSONTools.ObjToJson(facbr.EventoCTe);
  facbr.EventoCTe.Evento.Clear;
end;

function TACBRModelosJSONCTe.ModelCTe: TJSONObject;
var
  vConhecimento: Conhecimento;
begin
  vConhecimento := facbr.Conhecimentos.Add;
  with vConhecimento.CTe do
  begin
    infCTe.versao := 4.0;
    Ide.cUF := UFtoCUF('ES'); // Certifique-se que UFtoCUF est� acess�vel
    Ide.CFOP := 5353;
    Ide.natOp := 'PRESTACAO SERVICO';
    ide.forPag := fpAPagar;
    Ide.modelo := 57;
    Ide.serie := 1;
    Ide.nCT := 1;
    Ide.cCT := 1; // Aten��o: deve ser aleat�rio
    Ide.dhEmi := Now;
    Ide.tpImp := tiRetrato;
    Ide.tpEmis := teNormal;
    Ide.tpAmb := taHomologacao;
    Ide.tpCTe := tcNormal;
    Ide.procEmi := peAplicativoContribuinte;
    Ide.verProc := '4.0'; // Ou sua vers�o
    Ide.cMunEnv := StrToInt('3203205'); // Exemplo Linhares/ES
    Ide.xMunEnv := 'LINHARES';
    Ide.UFEnv := 'ES';
    Ide.modal := mdRodoviario;
    Ide.tpServ := tsNormal;
    ide.indIEToma := TpcnindIEDest.inContribuinte; // Corrigido: indIEToma usa enum ii*
    Ide.cMunIni := 3119401; // Exemplo Coronel Fabriciano/MG
    Ide.xMunIni := 'CORONEL FABRICIANO';
    Ide.UFIni := 'MG';
    Ide.cMunFim := 2900207; // Exemplo Abar�/BA
    Ide.xMunFim := 'ABARE';
    Ide.UFFim := 'BA';
    Ide.retira := rtSim;
    ide.indGlobalizado := TIndicador.tiSim; // boolean

    // Adicione mais campos conforme o modelo extenso que voc� tinha
    // ...

    Emit.CRT := crtRegimeNormal;
    Emit.CNPJ := '11222333000144'; // CNPJ fict�cio
    Emit.IE := '001000000000';    // IE fict�cia
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

function TACBRModelosJSONCTe.ModelConsultaCTe: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('tpAmb', Ord(TpcnTipoAmbiente.taHomologacao));
  Result.Add('chCTe', '35000000000000000000000000000000000000000000'); // Chave exemplo
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
    raise Exception.Create('Par�metro "xml" (string Base64) n�o encontrado no JSON.');

  xmlBase64 := xmlBase64JSON.AsString;
  if xmlBase64 = '' then
    raise Exception.Create('Par�metro "xml" est� vazio no JSON.');

  try
    Result := DecodeStringBase64(xmlBase64); // Fun��o de Classes ou Base64 unit
  except
    on E: Exception do
      raise Exception.Create('A string XML em base64 � inv�lida: ' + E.Message);
  end;
end;

constructor TACBRBridgeCTe.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrCTe.Create(nil);
  fdacte := TACBrCTeDACTeRL.Create(nil);
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
  Result := TJSONObject.Create;

  try
    ConhecimentoCTe := facbr.Conhecimentos.Add.CTe;
    Lote := 1;

    TJSONTools.JsonToObj(jCTe, ConhecimentoCTe);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na leitura do objeto JSON para CTe: ' + E.Message);
      if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
      Exit;
    end;
  end;

  try
    facbr.WebServices.Envia(Lote, True); // True para Assinar
  finally
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.Retorno));
  end;

  if Assigned(facbr.Conhecimentos) then facbr.Conhecimentos.Clear;
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

function TACBRBridgeCTe.ConsultarCTe(const jConsulta: TJSONObject): TJSONObject;
var
  ChaveCTe_JSON: TJSONString;
  NumRecibo_JSON: TJSONString;
  Ambiente_JSON: TJSONNumber;
  ChaveOuRecibo: string;
  TipoAmbiente: TpcnTipoAmbiente;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  ChaveOuRecibo := '';

  try
    if jConsulta.Find('tpAmb', Ambiente_JSON) then
    begin
      TipoAmbiente := TpcnTipoAmbiente(Ambiente_JSON.AsInteger);
      facbr.Configuracoes.WebServices.Ambiente := TipoAmbiente;
    end;

    if jConsulta.Find('chCTe', ChaveCTe_JSON) then
      ChaveOuRecibo := ChaveCTe_JSON.AsString
    else if jConsulta.Find('nRec', NumRecibo_JSON) then
      ChaveOuRecibo := NumRecibo_JSON.AsString;

    if ChaveOuRecibo = '' then
    begin
      Result.Add('error',
        'Chave do CTe (chCTe) ou n�mero do recibo (nRec) n�o informado para consulta.');
      Exit;
    end;

    facbr.Consultar(ChaveOuRecibo);
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.Retorno));
    // Retorno � TCTeRetConsSit

  except
    on E: Exception do
    begin
      Result.Clear;
      Result.Add('error', 'Erro ao consultar CTe: ' + E.Message);
    end;
  end;
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

  // Esvazia a string para liberar da mem�ria logo o xml
  stringXml := '';
  // O acesso a propriedade TipoDanfe se faz somente diretamente pelo objeto.
  if facbr.Conhecimentos.Items[0].CTe.Ide.tpImp <> TpcnTipoImpressao.tiPaisagem then
    fdacte.TipoDACTE := tiRetrato
  else
    fdacte.TipoDACTE := tiPaisagem;

  // Como � um aplicativo console, jamais a propriedade MostraStatus deve ser true.
  fdacte.MostraPreview := False;
  fdacte.MostraStatus := False;
  fdacte.MostraSetup := False;

  //Gerando arquivo tempor�rio
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

  // Converte a stream do relat�rio para base64
  Result.Add('pdf', arquivofinal);
  // Chave de Acesso da NF-e
  Result.Add('chave', facbr.Conhecimentos.Items[0].CTe.infCTe.ID);
  // Tamanho em Bytes
  Result.Add('tamanho', tamanho.ToString);
  // Adiciona o identificador �nico se ele existir
  if xmlData.Find('id', id) then
    Result.Add('id', id);

end;

// function TACBRBridgeCTe.ConsultaSituacaoServico removida

function TACBRBridgeCTe.TesteConfig: boolean;
begin
  try
    CarregaConfig;
    Result := True;
  except
    Result := False;
  end;
end;

// Implementa��o de FileToStringBase64 (se n�o estiver em streamtools ou ACBrUtil de forma acess�vel)
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
//         EnBase64(MemStream, Base64Stream); // Fun��o da unit Base64 do FPC
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

// Certifique-se que UFtoCUF esteja implementada ou em units acess�veis.
// Geralmente est� em pcnAuxiliar do ACBr. Se n�o, uma implementa��o simples:
// function UFtoCUF(const AUF: string): Integer;
// begin
//   // Implementa��o de convers�o de Sigla UF para C�digo IBGE
//   // Exemplo: if AUF = 'SP' then Result := 35 else ...
//   // O ACBr geralmente tem essa fun��o em ACBrUtil ou pcnAuxiliar.
//   // Se voc� usa o componente ACBr, ele mesmo pode fazer essa convers�o
//   // ao atribuir facbr.Configuracoes.WebServices.UF := 'SP'; e depois usar
//   // facbr.Configuracoes.WebServices.UF ????????? StrToInteger(pcnCodUFIBGE[UF]);
//   // Para o CTe.Ide.cUF, voc� precisar� do c�digo IBGE num�rico.
//   Result := TACBrDFe.StrUFToCodIBGE(AUF); // Use a fun��o do ACBr se dispon�vel
// end;

end.
