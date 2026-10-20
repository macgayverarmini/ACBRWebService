unit method.acbr.gnre;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrGNRE2,
  ACBrGNREGuias,
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
  TACBRBridgeGNRE = class
  private
    fcfg: string;
    facbr: TACBrGNRE;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Enviar(const jGNRE: TJSONObject): TJSONObject;
    function Consultar(const jConsulta: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONGNRE = class(TACBRBridgeGNRE)
  public
    function ModelConfig: TJSONObject;
    function ModelGuia: TJSONObject;
  end;

implementation

{ TACBRModelosJSONGNRE }

function TACBRModelosJSONGNRE.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.Configuracoes, 'Erro ao gerar modelo de configuracao da GNRE');
end;

function TACBRModelosJSONGNRE.ModelGuia: TJSONObject;
var
  ItemGuia: Guia;
begin
  facbr.Guias.Clear;
  ItemGuia := facbr.Guias.Add;
  Result := TJSONTools.SafeObjToJson(ItemGuia.GNRE, 'Erro ao gerar modelo de Guia GNRE');
  facbr.Guias.Clear;
end;

{ TACBRBridgeGNRE }

procedure TACBRBridgeGNRE.CarregaConfig;
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
      raise Exception.Create('Erro na leitura da configuracao da GNRE: ' + E.Message);
  end;

  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + 'Schemas' + PathDelim + 'GNRE';

  fcfg := '';
end;

constructor TACBRBridgeGNRE.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrGNRE.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeGNRE.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeGNRE.Enviar(const jGNRE: TJSONObject): TJSONObject;
var
  ItemGuia: Guia;
begin
  CarregaConfig;
  facbr.Guias.Clear;
  try
    try
      ItemGuia := facbr.Guias.Add;
      TJSONTools.JsonToObj(jGNRE, ItemGuia.GNRE);
      facbr.Enviar(False);
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Retorno Envio GNRE');
    except
      on E: Exception do
        Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao enviar GNRE: ' + E.Message);
    end;
  finally
    facbr.Guias.Clear;
  end;
end;

function TACBRBridgeGNRE.Consultar(const jConsulta: TJSONObject): TJSONObject;
var
  recibo: string;
begin
  CarregaConfig;
  recibo := jConsulta.Get('recibo', '');
  if recibo = '' then
    recibo := jConsulta.Get('nRec', '');

  if recibo = '' then
  begin
    Result := TJSONTools.SafeObjToJson(nil, 'Recibo (nRec) nao informado para consulta GNRE.');
    Exit;
  end;

  try
    facbr.ConsultarResultadoLote(recibo);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Retorno Consulta GNRE');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao consultar GNRE: ' + E.Message);
  end;
end;

end.
