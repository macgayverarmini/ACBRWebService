unit method.acbr.nfe;

{$mode Delphi}

interface

uses
  ACBrNFeDANFeLazReport,
  LCLIntf, LCLType, LMessages, Messages, Variants, Graphics,
  Controls, Forms, Dialogs, ComCtrls, StdCtrls, Spin, Buttons, ExtCtrls,
  fpjson, jsonconvert, ACBrNFeDANFeRLClass, ACBrNFeDANFEClass, ACBrDANFCeFortesFr,
  ACBrDFeReport, ACBrDFeDANFeReport, ACBrBase, ACBrDFe,
  ACBrNFe, ACBrUtil, ACBrMail, ACBrIntegrador, ACBrDANFCeFortesFrA4,
  Horse.HandleException, Base64, jsonparser, ACBrDFeSSL,
  pcnConversaoNFe, pcnConversao, pcnEnvEventoNFe, ACBrDFeConfiguracoes,
  pcnEventoNFe, ACBrNFeConfiguracoes, Classes, SysUtils, fpjsonrtti;

type


  { TACBRBridgeNFe }

  TACBRBridgeNFe = class
  private
    fcfg: string;
    facbr: TACBrNFe;
    fdanfe: TACBrNFeDANFeLazReport;
    procedure CarregaConfig;
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
begin
  if fcfg = '' then
    exit;

  TJSONTools.JsonStringToObj(fcfg, facbr.Configuracoes);
  fcfg := '';
end;

constructor TACBRBridgeNFe.Create(const Cfg: string);
begin
  facbr := TACBrNFe.Create(nil);
  fdanfe := TACBrNFeDANFeLazReport.Create(nil);
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
  CarregaConfig;
  TJSONTools.JsonToObj(jDistribuicao, facbr.WebServices.DistribuicaoDFe);
  facbr.WebServices.DistribuicaoDFe.Executar;
  Result := TJSONTools.ObjToJsonString(facbr.WebServices.DistribuicaoDFe.retDistDFeInt);
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AStream.Size);
  AStream.Position := 0;
  AStream.Read(LBytes[0], AStream.Size);
  Result := base64.EncodeStringBase64(TEncoding.UTF8.GetString(LBytes));
end;

function TACBRBridgeNFe.Danfe(const xmlData: TJSONObject): TJSONObject;
var
  xmlBase64: string;
  stringXml: string;
  streamPdf: TMemoryStream;
  id: TJSONString;
begin
  Result := TJSONObject.Create;

  try
    xmlBase64 := xmlData.Extract('xml').Value;
  except
    begin
      Result.Add('error', 'Erro na leitura do par xml no JSON.');
      Exit;
    end;
  end;

  try
    stringXml := DecodeStringBase64(xmlBase64);
  except
    begin
      Result.Add('error', 'A string XML em base64 é inválida');
      Exit;
    end;
  end;

  // esvazia o xml em base64 logo da memória
  xmlBase64 := '';
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

  streamPdf := TMemoryStream.Create;
  try
    // Realiza o processo de transformar o XML em PDF (Danfe)
    try
      fDANFe.ImprimirDANFEPDF;
    except
      begin
        Result.Add('error', 'Falha ao gerar o PDF.');
        Exit;
      end;
    end;

    if streamPdf.Size = 0 then
    begin
      Result.Add('error', 'O pdf gerado não parece ser válido.');
      Exit;
    end;
    // Converte a stream do relatório para base64
    Result.Add('pdf', StreamToBase64String(streamPdf));
    // Chave de Acesso da NF-e
    Result.Add('chave', facbr.NotasFiscais.Items[0].NFe.infNFe.ID);
    // Tamanho em Bytes
    Result.Add('tamanho', streamPdf.Size.ToString);
    // Adiciona o identificador único se ele existir
    if xmlData.Find('id', id) then
      Result.Add('id', id);
  finally
    streamPdf.Free;
  end;
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
