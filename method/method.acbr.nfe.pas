unit method.acbr.nfe;

{$mode Delphi}

interface

uses
  fpjson,
  Horse.HandleException, Base64, jsonparser, ACBrDFeSSL,
  ACBrNFe, pcnConversaoNFe, pcnConversao, pcnEnvEventoNFe, ACBrDFeConfiguracoes,
  pcnEventoNFe, ACBrNFeConfiguracoes, Classes, SysUtils, fpjsonrtti;

type

  { TJSONTools }

  TJSONTools = class
  public
    class function ObjToJsonString(const Obj: TObject): string;
    class function ObjToJson(const Obj: TObject): TJSONObject;

    class procedure JsonStringToObj(const JsonString: string; const Obj: TObject);
    class procedure JsonToObj(const Json: TJSONObject; const Obj: TObject);
  end;


  { TACBRBridgeNFe }

  TACBRBridgeNFe = class
  private
    fcfg: string;
    facbr: TACBrNFe;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    // Envia um evento
    function Evento(const jEventos: TJSONArray): string;
    // Distribuição
    function Distribuicao(const jDistribuicao: TJSONObject): string;

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

{ TJSONTools }

class function TJSONTools.ObjToJsonString(const Obj: TObject): string;
var
  Streamer: TJSONStreamer;
begin
  Streamer := TJSONStreamer.Create(nil);
  try
    Streamer.Options := Streamer.Options + [jsoDateTimeAsString, jsoTStringsAsArray];
    Result := Streamer.ObjectToJSONString(Obj);
  finally
    Streamer.Destroy;
  end;
end;

class function TJSONTools.ObjToJson(const Obj: TObject): TJSONObject;
var
  Streamer: TJSONStreamer;
begin
  Streamer := TJSONStreamer.Create(nil);
  try
    Streamer.Options := Streamer.Options + [jsoDateTimeAsString, jsoTStringsAsArray];
    Result := Streamer.ObjectToJSON(Obj);
  finally
    Streamer.Destroy;
  end;
end;

class procedure TJSONTools.JsonStringToObj(const JsonString: string; const Obj: TObject);
var
  Streamer: TJSONDeStreamer;
begin
  Streamer := TJSONDeStreamer.Create(nil);
  try
    Streamer.Options := [jdoIgnorePropertyErrors];
    Streamer.JSONToObject(JsonString, Obj);
  finally
    Streamer.Destroy;
  end;
end;

class procedure TJSONTools.JsonToObj(const Json: TJSONObject; const Obj: TObject);
var
  Streamer: TJSONDeStreamer;
begin
  Streamer := TJSONDeStreamer.Create(nil);
  try
    Streamer.Options := [jdoIgnorePropertyErrors];
    Streamer.JSONToObject(Json, Obj);
  finally
    Streamer.Destroy;
  end;
end;

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
  fcfg := Cfg;
end;

destructor TACBRBridgeNFe.Destroy;
begin
  facbr.Free;
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
  Result := TJSONTools.ObjToJsonString(facbr.WebServices.EnvEvento.EventoRetorno.retEvento);
end;

function TACBRBridgeNFe.Distribuicao(const jDistribuicao: TJSONObject): string;
begin
  CarregaConfig;
  TJSONTools.JsonToObj(jDistribuicao, facbr.WebServices.DistribuicaoDFe);
  facbr.WebServices.DistribuicaoDFe.Executar;
  Result := TJSONTools.ObjToJsonString(facbr.WebServices.DistribuicaoDFe.retDistDFeInt);
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
