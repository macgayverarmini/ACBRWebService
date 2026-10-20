unit method.acbr.reinf;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrReinf,
  ACBrDFeSSL,
  pcnConversao,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  synacode,
  Classes, SysUtils,
  streamtools;

type
  TACBRBridgeReinf = class
  private
    fcfg: string;
    facbr: TACBrReinf;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Enviar(const jReinf: TJSONObject): TJSONObject;
    function Consultar(const jConsulta: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONReinf = class(TACBRBridgeReinf)
  public
    function ModelConfig: TJSONObject;
  end;

implementation

{ TACBRModelosJSONReinf }

function TACBRModelosJSONReinf.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.Configuracoes, 'Erro ao gerar modelo de configuracao do EFD-Reinf');
end;

{ TACBRBridgeReinf }

procedure TACBRBridgeReinf.CarregaConfig;
var
  O, CertConfig: TJSONObject;
  tempData: TJSONData;
  b64String: string;
begin
  if fcfg = '' then
    Exit;
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
          facbr.Configuracoes.Certificados.DadosPFX := synacode.DecodeBase64(AnsiString(b64String));
      end;

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
      raise Exception.Create('Erro na leitura da configuracao do Reinf: ' + E.Message);
  end;

  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + 'Schemas' + PathDelim + 'Reinf';

  fcfg := '';
end;

constructor TACBRBridgeReinf.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrReinf.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeReinf.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeReinf.Enviar(const jReinf: TJSONObject): TJSONObject;
var
  xmlBase64: string;
begin
  CarregaConfig;
  try
    xmlBase64 := jReinf.Get('xml', '');
    if xmlBase64 <> '' then
      facbr.Eventos.LoadFromString(DecodeStringBase64(xmlBase64))
    else
      TJSONTools.JsonToObj(jReinf, facbr.Eventos);

    facbr.Enviar;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvioLote, 'Retorno EnvioLote EFD-Reinf');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao enviar EFD-Reinf: ' + E.Message);
  end;
end;

function TACBRBridgeReinf.Consultar(const jConsulta: TJSONObject): TJSONObject;
var
  protocolo: string;
begin
  CarregaConfig;
  protocolo := jConsulta.Get('protocolo', '');
  if protocolo = '' then
    protocolo := jConsulta.Get('nProt', '');

  if protocolo = '' then
  begin
    Result := TJSONTools.SafeObjToJson(nil, 'Protocolo nao informado para consulta EFD-Reinf.');
    Exit;
  end;

  try
    facbr.Consultar(protocolo);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consultar, 'Retorno Consulta EFD-Reinf');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao consultar EFD-Reinf: ' + E.Message);
  end;
end;

end.
