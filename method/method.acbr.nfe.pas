{%RunFlags MESSAGES+}
unit method.acbr.nfe;

{$mode Delphi}

interface

uses streamtools,
  ACBrNFeDANFeRLClass,

  LCLIntf, LCLType,   Variants, Graphics,
  Controls, Forms, Dialogs, ComCtrls,   Buttons, ExtCtrls,
  fpjson, jsonconvert,
   ACBrDFeDANFeReport,
  ACBrNFe,  ACBrMail,
  Horse.HandleException, Base64, jsonparser, ACBrDFeSSL,
  pcnConversaoNFe, pcnConversao, pcnEnvEventoNFe, ACBrDFeConfiguracoes,
   ACBrNFeConfiguracoes, Classes, SysUtils;

type


  { TACBRBridgeNFe }

  TACBRBridgeNFe = class
  private
    fcfg: string;
    facbr: TACBrNFe;
    fdanfe: TACBrNFeDANFeRL;
    procedure CarregaConfig;

    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    // Envia um evento
    function Evento(const jEventos: TJSONArray): string;
    // Distribuição
    function Distribuicao(const jDistribuicao: TJSONObject): string;
    // DANFE
    function Danfe(const xmlData: TJSONObject): TJSONObject;

    // Teste a configuração passada em JSON
    function TesteConfig: boolean;
  end;

  { TACBRModelosJSON - Salva os retornos de modelo de requisições, para facilitar
  documentação ou consulta por parte do programador.}

  TACBRModelosJSON = class(TACBRBridgeNFe)
  private
  public
    // Retorna as configurações atuais do componente da ACBR.
    function ModelConfig: TJSONObject;
    function ModelEvento: TJSONObject;
    function ModelDistribuicao: string;
  end;

implementation

{ TACBRModelosJSON }

function TACBRModelosJSON.ModelConfig: TJSONObject;
begin

  with facbr.Configuracoes.Geral do
  begin
    FormaEmissao := TpcnTipoEmissao.teNormal;
    ModeloDF := TpcnModeloDF.moNFe;
    VersaoDF := TpcnVersaoDF.ve400;
    RetirarAcentos := True;
    IdCSC := '';
    //cIdToken := '';

    SSLLib := TSSLLib.libOpenSSL;
    SSLCryptLib := TSSLCryptLib.cryOpenSSL;
    SSLHttpLib := TSSLHttpLib.httpOpenSSL;
    SSLXmlSignLib := TSSLXmlSignLib.xsLibXml2;
  end;

  with facbr.Configuracoes.WebServices do
  begin
    Ambiente := TpcnTipoAmbiente.taHomologacao;
    UF := 'ES';
    TimeOut := 5000;
  end;

  with facbr.Configuracoes.Certificados do
  begin
    ArquivoPFX := 'C:\NFMonitor\src\jb3.pfx';
    Senha := '33711388';
  end;


  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

function TACBRModelosJSON.ModelEvento: TJSONObject;
begin
  facbr.EventoNFe.Evento.New;
  Result := TJSONTools.ObjToJson(facbr.EventoNFe);
  facbr.EventoNFe.Evento.Clear;
end;

function TACBRModelosJSON.ModelDistribuicao: string;
begin
  //  Evento := facbr.WebServices.DistribuicaoDFe.new;
  Result := TJSONTools.ObjToJsonString(facbr.WebServices.DistribuicaoDFe);
  //  facbr.EventoNFe.Evento.Clear;
end;

{ TACBRBridgeNFe }

procedure TACBRBridgeNFe.CarregaConfig;
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

function TACBRBridgeNFe.ReadXMLFromJSON(const jsonData: TJSONObject): string;
var
  xmlBase64: string;
begin
  try
    xmlBase64 := jsonData.Extract('xml').Value;
  except
    on E: Exception do
    begin
      raise Exception.Create('Erro na leitura do parâmetro "xml" do JSON: ' +
        E.Message);
    end;
  end;

  try
    Result := DecodeStringBase64(xmlBase64);
    xmlBase64 := '';
  except
    on E: Exception do
    begin
      raise Exception.Create('A string XML em base64 é inválida: ' + E.Message);
    end;
  end;
end;

constructor TACBRBridgeNFe.Create(const Cfg: string);
begin
  facbr := TACBrNFe.Create(nil);
  fdanfe := TACBrNFeDANFeRL.Create(nil);
  fcfg := Cfg;
  facbr.DANFE := fdanfe;
end;

destructor TACBRBridgeNFe.Destroy;
begin
  facbr.Free;
  FreeAndNil(fdanfe);
  inherited Destroy;
end;

function TACBRBridgeNFe.Evento(const jEventos: TJSONArray): string;
var
  objEvento: TInfEventoCollectionItem;
  oEvento: TJSONObject;
  I: integer;
  InfEvento: TJSONObject;
  XmlBase64: TJSONString;
begin
  CarregaConfig;

  for I := 0 to jEventos.Count - 1 do
  begin
    oEvento := jEventos.Items[i] as TJSONObject;
    InfEvento := oEvento.Extract('InfEvento') as TJSONObject;
    if InfEvento.Find('LoadXML', XmlBase64) then
      facbr.NotasFiscais.LoadFromString(Base64.DecodeStringBase64(XmlBase64.AsString));

    objEvento := facbr.EventoNFe.Evento.New;
    TJSONTools.JsonToObj(oEvento, objEvento);
  end;

  facbr.EnviarEvento(1);
  Result := TJSONTools.ObjToJsonString(
    facbr.WebServices.EnvEvento.EventoRetorno.retEvento);
end;

function TACBRBridgeNFe.Distribuicao(const jDistribuicao: TJSONObject): string;
begin

end;

function TACBRBridgeNFe.Danfe(const xmlData: TJSONObject): TJSONObject;
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
    facbr.NotasFiscais.LoadFromString(stringXml);
  except
    on E: Exception do
    begin
      Result.Add('error', 'Erro na leitura do XML: ' + E.Message);
      Exit;
    end;
  end;

  // Esvazia a string para liberar da memória logo o xml
  stringXml := '';
  // O acesso a propriedade TipoDanfe se faz somente diretamente pelo objeto.
  if facbr.NotasFiscais.Items[0].NFe.Ide.tpImp <> TpcnTipoImpressao.tiPaisagem then
    fdanfe.TipoDANFE := tiRetrato
  else
    fdanfe.TipoDANFE := tiPaisagem;

  // Como é um aplicativo console, jamais a propriedade MostraStatus deve ser true.
  fdanfe.MostraPreview := False;
  fdanfe.MostraStatus := False;
  fdanfe.MostraSetup := False;

  //Gerando arquivo temporário
  fileName := GetTempFileName;
  // Realiza o processo de transformar o XML em PDF (Danfe)
  try
    fDAnFe.PathPDF := filename;
    facbr.NotasFiscais.ImprimirPDF;
    filename := fdanfe.ArquivoPDF;
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
  Result.Add('chave', facbr.NotasFiscais.Items[0].NFe.infNFe.ID);
  // Tamanho em Bytes
  Result.Add('tamanho', tamanho.ToString);
  // Adiciona o identificador único se ele existir
  if xmlData.Find('id', id) then
    Result.Add('id', id);

end;

function TACBRBridgeNFe.TesteConfig: boolean;
begin
  try
    CarregaConfig;
    Result := True;
  except
    Result := False;
  end;
end;


end.
