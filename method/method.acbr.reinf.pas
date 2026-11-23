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
  streamtools,
  resource.strings.global,
  resource.strings.msg;

type
  TACBRBridgeReinf = class
  private
    fcfg: string;
    facbr: TACBrReinf;
    procedure CarregaConfig(const AllowEmpty: Boolean = False);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Enviar(const jReinf: TJSONObject): TJSONObject;
    function Consultar(const jConsulta: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONReinf = class(TACBRBridgeReinf)
  public
    function ModelConfig: TJSONObject;
    function ModelEnviar: TJSONObject;
    function ModelConsultar: TJSONObject;
  end;

implementation

{ TACBRModelosJSONReinf }

function TACBRModelosJSONReinf.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.Configuracoes, 'Erro ao gerar modelo de configuracao do EFD-Reinf');
end;

function TACBRModelosJSONReinf.ModelEnviar: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.Eventos, 'Erro ao gerar modelo de envio do EFD-Reinf');
end;

function TACBRModelosJSONReinf.ModelConsultar: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consultar, 'Erro ao gerar modelo de consulta do EFD-Reinf');
end;

{ TACBRBridgeReinf }

procedure TACBRBridgeReinf.CarregaConfig(const AllowEmpty: Boolean);
var
  LData: TJSONData;
  O: TJSONObject;
  LPfx: AnsiString;
  LDefaultRootSchemas, LCurSchemas: string;
begin
  if (Trim(fcfg) = '') and (not AllowEmpty) then
    raise Exception.Create(RSConfigEmptyError);

  LDefaultRootSchemas := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + RSSchemasDir);

  if Trim(fcfg) <> '' then
  begin
    try
      LData := GetJSON(fcfg);
      if not (LData is TJSONObject) then
      begin
        LData.Free;
        raise Exception.Create(RSNotJSONObjectError);
      end;
      O := TJSONObject(LData);
      try
        TJSONTools.JsonToObj(O, facbr.Configuracoes);

        LPfx := TJSONTools.ExtractCertificadoPFX(O);
        if LPfx <> '' then
          facbr.Configuracoes.Certificados.DadosPFX := LPfx;
      finally
        O.Free;
      end;
    except
      on E: Exception do
        raise Exception.Create('Erro na leitura da configuracao do Reinf: ' + E.Message);
    end;
    fcfg := '';
  end;

  with facbr.Configuracoes.Geral do
  begin
    SSLLib := libOpenSSL;
    SSLCryptLib := cryOpenSSL;
    SSLHttpLib := httpOpenSSL;
    SSLXmlSignLib := xsLibXml2;
  end;

  LCurSchemas := ExcludeTrailingPathDelimiter(Trim(facbr.Configuracoes.Arquivos.PathSchemas));
  if (LCurSchemas = '') or SameText(LCurSchemas, LDefaultRootSchemas) then
    facbr.Configuracoes.Arquivos.PathSchemas := LDefaultRootSchemas + PathDelim + 'Reinf' + PathDelim;
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
  CarregaConfig(False);
  try
    xmlBase64 := jReinf.Get(RSXmlKey, '');
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
  CarregaConfig(False);
  facbr.WebServices.Consultar.Clear;
  if Assigned(jConsulta) then
    TJSONTools.JsonToObj(jConsulta, facbr.WebServices.Consultar);

  protocolo := Trim(facbr.WebServices.Consultar.Protocolo);
  if (protocolo = '') and Assigned(jConsulta) then
  begin
    protocolo := Trim(jConsulta.Get('protocolo', ''));
    if protocolo = '' then
      protocolo := Trim(jConsulta.Get('nProt', ''));
  end;

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
