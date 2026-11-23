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
  pgnreGNRE,
  pgnreConversao,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg;

type
  TACBRBridgeGNRE = class
  private
    fcfg: string;
    facbr: TACBrGNRE;
    procedure CarregaConfig(const AllowEmpty: Boolean = False);
    procedure PopularGuiasPayload(const jPayload: TJSONObject);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Enviar(const jGNRE: TJSONObject): TJSONObject;
    function Consultar(const jConsulta: TJSONObject): TJSONObject;
    function GNREToXML(const jGNRE: TJSONObject): TJSONObject;
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
  try
    Result := TJSONTools.SafeObjToJson(ItemGuia.GNRE, 'Erro ao gerar modelo de Guia GNRE');
  finally
    facbr.Guias.Clear;
  end;
end;

{ TACBRBridgeGNRE }

procedure TACBRBridgeGNRE.CarregaConfig(const AllowEmpty: Boolean);
var
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
      O := GetJSON(fcfg) as TJSONObject;
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
        raise Exception.Create('Erro na leitura da configuracao da GNRE: ' + E.Message);
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
    facbr.Configuracoes.Arquivos.PathSchemas := LDefaultRootSchemas + PathDelim + 'GNRe' + PathDelim;
end;

constructor TACBRBridgeGNRE.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrGNRE.Create(nil);
  facbr.Configuracoes.Geral.VersaoDF := ve200;
  facbr.Configuracoes.Geral.RetirarAcentos := True;
  facbr.Configuracoes.Geral.Salvar := False;
  facbr.Configuracoes.Arquivos.Salvar := False;
  facbr.Configuracoes.Geral.SSLLib := libOpenSSL;
  facbr.Configuracoes.Geral.SSLCryptLib := cryOpenSSL;
  facbr.Configuracoes.Geral.SSLHttpLib := httpOpenSSL;
  facbr.Configuracoes.Geral.SSLXmlSignLib := xsLibXml2;
  fcfg := Cfg;
end;

destructor TACBRBridgeGNRE.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

procedure TACBRBridgeGNRE.PopularGuiasPayload(const jPayload: TJSONObject);
var
  jNode: TJSONData;
  jArr: TJSONArray;
  I: Integer;
  ItemGuia: Guia;

  procedure PopularItem(const jSource: TJSONObject);
  begin
    ItemGuia := facbr.Guias.Add;
    // Default -1 evita que TGNREW emita <referencia><periodo>0</periodo></referencia> quando nao informada
    ItemGuia.GNRE.referencia.periodo := -1;
    ItemGuia.GNRE.referencia.mes := '';
    ItemGuia.GNRE.referencia.ano := 0;
    ItemGuia.GNRE.referencia.parcela := 0;
    TJSONTools.JsonToObj(jSource, ItemGuia.GNRE);
  end;

begin
  facbr.Guias.Clear;
  if not Assigned(jPayload) then
    Exit;

  jNode := jPayload.Find('Guias');
  if not Assigned(jNode) then
    jNode := jPayload.Find('guias');
  if Assigned(jNode) and (jNode.JSONType = jtArray) then
  begin
    jArr := TJSONArray(jNode);
    for I := 0 to jArr.Count - 1 do
      if jArr.Items[I].JSONType = jtObject then
        PopularItem(TJSONObject(jArr.Items[I]));
    Exit;
  end;

  jNode := jPayload.Find('GNRE');
  if not Assigned(jNode) then
    jNode := jPayload.Find('gnre');
  if not Assigned(jNode) then
    jNode := jPayload.Find('Guia');
  if not Assigned(jNode) then
    jNode := jPayload.Find('guia');

  if Assigned(jNode) and (jNode.JSONType = jtObject) then
    PopularItem(TJSONObject(jNode))
  else
    PopularItem(jPayload);
end;

function TACBRBridgeGNRE.GNREToXML(const jGNRE: TJSONObject): TJSONObject;
var
  I: Integer;
  xmlStr: string;
  arrXmls: TJSONArray;
  itemObj: TJSONObject;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;
  facbr.Guias.Clear;
  try
    try
      PopularGuiasPayload(jGNRE);
      if facbr.Guias.Count = 0 then
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Nenhuma guia GNRE informada para geracao de XML.');
        Exit;
      end;

      facbr.Guias.GerarGNRE;
      if Assigned(jGNRE) and jGNRE.Get('ValidarXSD', False) then
        facbr.Guias.Validar;

      xmlStr := Trim(facbr.Guias.Items[0].XMLOriginal);
      if xmlStr = '' then
        xmlStr := Trim(facbr.Guias.Items[0].GerarXML);

      Result.Add(RSStatusField, RSStatusSucesso);
      if facbr.Configuracoes.Geral.VersaoDF = ve100 then
        Result.Add('versao', '1.00')
      else
        Result.Add('versao', '2.00');
      Result.Add(RSXmlKey, EncodeStringBase64(xmlStr));

      if facbr.Guias.Count > 1 then
      begin
        arrXmls := TJSONArray.Create;
        for I := 0 to facbr.Guias.Count - 1 do
        begin
          xmlStr := Trim(facbr.Guias.Items[I].XMLOriginal);
          if xmlStr = '' then
            xmlStr := Trim(facbr.Guias.Items[I].GerarXML);
          itemObj := TJSONObject.Create;
          itemObj.Add(RSXmlKey, EncodeStringBase64(xmlStr));
          arrXmls.Add(itemObj);
        end;
        Result.Add('guias_xml', arrXmls);
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao gerar XML da GNRE: ' + E.Message);
      end;
    end;
  finally
    facbr.Guias.Clear;
  end;
end;

function TACBRBridgeGNRE.Enviar(const jGNRE: TJSONObject): TJSONObject;
var
  xmlStr: string;
begin
  CarregaConfig(False);
  facbr.Guias.Clear;
  try
    try
      PopularGuiasPayload(jGNRE);
      facbr.Guias.GerarGNRE;
      xmlStr := '';
      if facbr.Guias.Count > 0 then
        xmlStr := Trim(facbr.Guias.Items[0].XMLOriginal);
      facbr.Enviar(False);
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Retorno Envio GNRE');
      if xmlStr <> '' then
        Result.Add(RSXmlKey, EncodeStringBase64(xmlStr));
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
  CarregaConfig(False);
  facbr.WebServices.Retorno.Clear;
  if Assigned(jConsulta) then
    TJSONTools.JsonToObj(jConsulta, facbr.WebServices.Retorno);

  recibo := Trim(facbr.WebServices.Retorno.numeroRecibo);
  if (recibo = '') and Assigned(jConsulta) then
  begin
    recibo := Trim(jConsulta.Get('recibo', ''));
    if recibo = '' then
      recibo := Trim(jConsulta.Get('nRec', ''));
    facbr.WebServices.Retorno.numeroRecibo := recibo;
  end;

  if recibo = '' then
  begin
    Result := TJSONTools.SafeObjToJson(nil, 'Recibo (numeroRecibo) nao informado para consulta GNRE.');
    Exit;
  end;

  try
    facbr.WebServices.Retorno.Executar;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Retorno Consulta GNRE');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao consultar GNRE: ' + E.Message);
  end;
end;

end.
