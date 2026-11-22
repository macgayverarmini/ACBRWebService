unit method.acbr.gnre;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrGNRE2,
  ACBrGNREGuias,
  ACBrDFeSSL,
  ACBrUtil.Strings,
  pcnConversao,
  pgnreGNRE,
  pgnreConversao,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  DateUtils,
  synacode,
  Classes, SysUtils,
  streamtools,
  resource.strings.global;

type
  TACBRBridgeGNRE = class
  private
    fcfg: string;
    facbr: TACBrGNRE;
    procedure CarregaConfig;
    procedure ApplyVersaoFromJSON(const jObj: TJSONObject);
    procedure PopularGuiaGNRE(const jSource: TJSONObject; const AGuia: TGNRE);
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

function ParseFlexDate(const S: string): TDateTime;
var
  Clean: string;
  DT: TDateTime;
  Y, M, D: Integer;
begin
  Result := 0;
  Clean := Trim(S);
  if Clean = '' then
    Exit;
  if Pos('T', Clean) > 0 then
    Clean := Copy(Clean, 1, Pos('T', Clean) - 1);
  if (Length(Clean) >= 10) and (Clean[5] = '-') and (Clean[8] = '-') then
  begin
    Y := StrToIntDef(Copy(Clean, 1, 4), 0);
    M := StrToIntDef(Copy(Clean, 6, 2), 0);
    D := StrToIntDef(Copy(Clean, 9, 2), 0);
    if (Y > 1900) and TryEncodeDate(Y, M, D, DT) then
    begin
      Result := DT;
      Exit;
    end;
  end;
  if (Length(Clean) >= 10) and (Clean[3] = '/') and (Clean[6] = '/') then
  begin
    D := StrToIntDef(Copy(Clean, 1, 2), 0);
    M := StrToIntDef(Copy(Clean, 4, 2), 0);
    Y := StrToIntDef(Copy(Clean, 7, 4), 0);
    if (Y > 1900) and TryEncodeDate(Y, M, D, DT) then
    begin
      Result := DT;
      Exit;
    end;
  end;
  if TryISO8601ToDate(S, DT, True) then
    Result := Trunc(DT);
end;

function ReadJsonStr(const Obj: TJSONObject; const Keys: array of string; const DefaultVal: string = ''): string;
var
  I: Integer;
  N: TJSONData;
begin
  Result := DefaultVal;
  if not Assigned(Obj) then
    Exit;
  for I := Low(Keys) to High(Keys) do
  begin
    N := Obj.Find(Keys[I]);
    if Assigned(N) and (not (N.JSONType in [jtNull, jtObject, jtArray])) then
    begin
      Result := Trim(N.AsString);
      if Result <> '' then
        Exit;
    end;
  end;
end;

function ReadJsonInt(const Obj: TJSONObject; const Keys: array of string; const DefaultVal: Integer = 0): Integer;
var
  I: Integer;
  N: TJSONData;
begin
  Result := DefaultVal;
  if not Assigned(Obj) then
    Exit;
  for I := Low(Keys) to High(Keys) do
  begin
    N := Obj.Find(Keys[I]);
    if Assigned(N) and (not (N.JSONType in [jtNull, jtObject, jtArray])) then
    begin
      if N.JSONType = jtNumber then
        Result := N.AsInteger
      else
        Result := StrToIntDef(Trim(N.AsString), DefaultVal);
      Exit;
    end;
  end;
end;

function ReadJsonCurr(const Obj: TJSONObject; const Keys: array of string; const DefaultVal: Currency = 0): Currency;
var
  I: Integer;
  N: TJSONData;
  FS: TFormatSettings;
  Flt: Double;
begin
  Result := DefaultVal;
  if not Assigned(Obj) then
    Exit;
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  for I := Low(Keys) to High(Keys) do
  begin
    N := Obj.Find(Keys[I]);
    if Assigned(N) and (not (N.JSONType in [jtNull, jtObject, jtArray])) then
    begin
      if N.JSONType = jtNumber then
        Result := N.AsFloat
      else if TryStrToFloat(StringReplace(Trim(N.AsString), ',', '.', [rfReplaceAll]), Flt, FS) then
        Result := Flt;
      Exit;
    end;
  end;
end;

{ TACBRModelosJSONGNRE }

function TACBRModelosJSONGNRE.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr.Configuracoes, 'Erro ao gerar modelo de configuracao da GNRE');
end;

function TACBRModelosJSONGNRE.ModelGuia: TJSONObject;
var
  jRef, jEmit, jExtra: TJSONObject;
  arrExtras: TJSONArray;
begin
  Result := TJSONObject.Create;
  Result.Add('VersaoDF', 've200');
  Result.Add('c01_UfFavorecida', 'SP');
  Result.Add('c02_receita', 100099);
  Result.Add('c25_detalhamentoReceita', 0);
  Result.Add('c26_produto', 0);
  Result.Add('c27_tipoIdentificacaoEmitente', 1);
  jEmit := TJSONObject.Create;
  jEmit.Add('CNPJ', '12345678000195');
  jEmit.Add('IE', '');
  Result.Add('c03_idContribuinteEmitente', jEmit);
  Result.Add('c28_tipoDocOrigem', 10);
  Result.Add('c04_docOrigem', '1');
  Result.Add('c06_valorPrincipal', 100.00);
  Result.Add('c10_valorTotal', 100.00);
  Result.Add('c14_dataVencimento', FormatDateTime('yyyy-mm-dd', Date));
  Result.Add('c15_convenio', '');
  Result.Add('c16_razaoSocialEmitente', 'EMPRESA EXEMPLO LTDA');
  Result.Add('c17_inscricaoEstadualEmitente', '');
  Result.Add('c18_enderecoEmitente', 'AVENIDA EXEMPLO, 1000');
  Result.Add('c19_municipioEmitente', '50308');
  Result.Add('c20_ufEnderecoEmitente', 'SP');
  Result.Add('c21_cepEmitente', '01001000');
  Result.Add('c22_telefoneEmitente', '1130000000');
  Result.Add('c33_dataPagamento', FormatDateTime('yyyy-mm-dd', Date));
  Result.Add('c34_tipoIdentificacaoDestinatario', 0);
  Result.Add('c35_idContribuinteDestinatario', '');
  Result.Add('c36_inscricaoEstadualDestinatario', '');
  Result.Add('c37_razaoSocialDestinatario', '');
  Result.Add('c38_municipioDestinatario', '');
  Result.Add('c42_identificadorGuia', '1');
  Result.Add('tipoGNRE', 'tgSimples');
  Result.Add('ValorFECP', 0.00);
  Result.Add('TotalFECP', 0.00);
  Result.Add('MultaICMS', 0.00);
  Result.Add('JurosICMS', 0.00);
  Result.Add('AtualMonetICMS', 0.00);
  jRef := TJSONObject.Create;
  jRef.Add('periodo', 0);
  jRef.Add('mes', FormatDateTime('mm', Date));
  jRef.Add('ano', YearOf(Date));
  jRef.Add('parcela', 1);
  Result.Add('c05_referencia', jRef);
  arrExtras := TJSONArray.Create;
  jExtra := TJSONObject.Create;
  jExtra.Add('codigo', 86);
  jExtra.Add('tipo', 'T');
  jExtra.Add('valor', '35260112345678000195550010000000011000000019');
  arrExtras.Add(jExtra);
  Result.Add('camposExtras', arrExtras);
end;

{ TACBRBridgeGNRE }

procedure TACBRBridgeGNRE.ApplyVersaoFromJSON(const jObj: TJSONObject);
var
  jGeral: TJSONData;
  vStr: string;
begin
  if not Assigned(jObj) then
    Exit;
  vStr := ReadJsonStr(jObj, ['VersaoDF', 'versaoDF', 'versao', 'Versao'], '');
  if vStr = '' then
  begin
    jGeral := jObj.Find('Geral');
    if not Assigned(jGeral) then
      jGeral := jObj.Find('geral');
    if Assigned(jGeral) and (jGeral.JSONType = jtObject) then
      vStr := ReadJsonStr(TJSONObject(jGeral), ['VersaoDF', 'versaoDF', 'versao'], '');
  end;
  vStr := LowerCase(Trim(vStr));
  if (vStr = '0') or (vStr = 've100') or (vStr = '1.00') or (vStr = '1.0') then
    facbr.Configuracoes.Geral.VersaoDF := ve100
  else if (vStr = '1') or (vStr = 've200') or (vStr = '2.00') or (vStr = '2.0') or (vStr = '2') then
    facbr.Configuracoes.Geral.VersaoDF := ve200;
end;

procedure TACBRBridgeGNRE.CarregaConfig;
var
  O: TJSONObject;
  LPfx: AnsiString;
  LDefaultRootSchemas, LCurSchemas: string;
begin
  LDefaultRootSchemas := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + RSSchemasDir);

  if Trim(fcfg) <> '' then
  begin
    try
      O := GetJSON(fcfg) as TJSONObject;
      try
        TJSONTools.JsonToObj(O, facbr.Configuracoes);
        ApplyVersaoFromJSON(O);

        LPfx := TJSONTools.ExtractCertificadoPFX(O);
        if LPfx <> '' then
          facbr.Configuracoes.Certificados.DadosPFX := LPfx;

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
    fcfg := '';
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

procedure TACBRBridgeGNRE.PopularGuiaGNRE(const jSource: TJSONObject; const AGuia: TGNRE);
var
  jNode, jSub: TJSONData;
  jEmitObj, jDestObj, jRefObj, jExtraObj: TJSONObject;
  jArr: TJSONArray;
  I, mesInt: Integer;
  docStr, ieStr, dtStr, tpGnreStr, mesStr: string;
  extraItem: TCampoExtraCollectionItem;
begin
  if (not Assigned(jSource)) or (not Assigned(AGuia)) then
    Exit;

  ApplyVersaoFromJSON(jSource);

  // Evita emitir <referencia><periodo>0</periodo></referencia> vazio quando nao informado
  AGuia.referencia.periodo := -1;
  AGuia.referencia.mes := '';
  AGuia.referencia.ano := 0;
  AGuia.referencia.parcela := 0;

  AGuia.c01_UfFavorecida := UpperCase(ReadJsonStr(jSource, ['c01_UfFavorecida', 'ufFavorecida', 'UF'], AGuia.c01_UfFavorecida));
  AGuia.c02_receita := ReadJsonInt(jSource, ['c02_receita', 'codigoReceita', 'receita'], AGuia.c02_receita);
  AGuia.c25_detalhamentoReceita := ReadJsonInt(jSource, ['c25_detalhamentoReceita', 'detalhamentoReceita'], AGuia.c25_detalhamentoReceita);
  AGuia.c26_produto := ReadJsonInt(jSource, ['c26_produto', 'produto'], AGuia.c26_produto);
  AGuia.c27_tipoIdentificacaoEmitente := ReadJsonInt(jSource, ['c27_tipoIdentificacaoEmitente', 'tipoIdentificacaoEmitente'], 0);

  // c03_idContribuinteEmitente: aceita string direta ou objeto { CNPJ, CPF, IE }
  jNode := jSource.Find('c03_idContribuinteEmitente');
  if not Assigned(jNode) then
    jNode := jSource.Find('contribuinteEmitente');
  if Assigned(jNode) then
  begin
    if jNode.JSONType = jtObject then
    begin
      jEmitObj := TJSONObject(jNode);
      docStr := OnlyNumber(ReadJsonStr(jEmitObj, ['CNPJ', 'cnpj'], ''));
      if docStr <> '' then
      begin
        AGuia.c03_idContribuinteEmitente := docStr;
        if AGuia.c27_tipoIdentificacaoEmitente = 0 then
          AGuia.c27_tipoIdentificacaoEmitente := 1;
      end
      else
      begin
        docStr := OnlyNumber(ReadJsonStr(jEmitObj, ['CPF', 'cpf'], ''));
        if docStr <> '' then
        begin
          AGuia.c03_idContribuinteEmitente := docStr;
          if AGuia.c27_tipoIdentificacaoEmitente = 0 then
            AGuia.c27_tipoIdentificacaoEmitente := 2;
        end;
      end;
      ieStr := OnlyNumber(ReadJsonStr(jEmitObj, ['IE', 'ie', 'inscricaoEstadual'], ''));
      if ieStr <> '' then
        AGuia.c17_inscricaoEstadualEmitente := ieStr;
    end
    else if not (jNode.JSONType in [jtNull, jtArray]) then
      AGuia.c03_idContribuinteEmitente := OnlyNumber(jNode.AsString);
  end
  else
  begin
    docStr := OnlyNumber(ReadJsonStr(jSource, ['CNPJ', 'cnpj', 'gnreCnpj', 'numeroDocumento'], ''));
    if docStr <> '' then
      AGuia.c03_idContribuinteEmitente := docStr;
  end;

  if (AGuia.c27_tipoIdentificacaoEmitente = 0) and (AGuia.c03_idContribuinteEmitente <> '') then
  begin
    if Length(AGuia.c03_idContribuinteEmitente) = 11 then
      AGuia.c27_tipoIdentificacaoEmitente := 2
    else
      AGuia.c27_tipoIdentificacaoEmitente := 1;
  end;

  AGuia.c28_tipoDocOrigem := ReadJsonInt(jSource, ['c28_tipoDocOrigem', 'tipoDocOrigem'], AGuia.c28_tipoDocOrigem);
  AGuia.c04_docOrigem := ReadJsonStr(jSource, ['c04_docOrigem', 'docOrigem', 'documentoOrigem'], AGuia.c04_docOrigem);
  AGuia.c06_valorPrincipal := ReadJsonCurr(jSource, ['c06_valorPrincipal', 'valorPrincipal'], AGuia.c06_valorPrincipal);
  AGuia.c10_valorTotal := ReadJsonCurr(jSource, ['c10_valorTotal', 'valorTotal'], AGuia.c10_valorTotal);

  dtStr := ReadJsonStr(jSource, ['c14_dataVencimento', 'dataVencimento'], '');
  if dtStr <> '' then
    AGuia.c14_dataVencimento := ParseFlexDate(dtStr);

  AGuia.c15_convenio := ReadJsonStr(jSource, ['c15_convenio', 'convenio'], AGuia.c15_convenio);
  AGuia.c16_razaoSocialEmitente := TiraAcentos(ReadJsonStr(jSource, ['c16_razaoSocialEmitente', 'razaoSocialEmitente', 'razaoSocial'], AGuia.c16_razaoSocialEmitente));
  ieStr := OnlyNumber(ReadJsonStr(jSource, ['c17_inscricaoEstadualEmitente', 'inscricaoEstadualEmitente', 'gnreIe'], ''));
  if ieStr <> '' then
    AGuia.c17_inscricaoEstadualEmitente := ieStr;
  AGuia.c18_enderecoEmitente := TiraAcentos(ReadJsonStr(jSource, ['c18_enderecoEmitente', 'enderecoEmitente', 'endereco'], AGuia.c18_enderecoEmitente));
  AGuia.c19_municipioEmitente := ReadJsonStr(jSource, ['c19_municipioEmitente', 'municipioEmitente'], AGuia.c19_municipioEmitente);
  AGuia.c20_ufEnderecoEmitente := UpperCase(ReadJsonStr(jSource, ['c20_ufEnderecoEmitente', 'ufEnderecoEmitente', 'ufEmitente'], AGuia.c20_ufEnderecoEmitente));
  AGuia.c21_cepEmitente := OnlyNumber(ReadJsonStr(jSource, ['c21_cepEmitente', 'cepEmitente'], AGuia.c21_cepEmitente));
  AGuia.c22_telefoneEmitente := OnlyNumber(ReadJsonStr(jSource, ['c22_telefoneEmitente', 'telefoneEmitente'], AGuia.c22_telefoneEmitente));

  dtStr := ReadJsonStr(jSource, ['c33_dataPagamento', 'dataPagamento'], '');
  if dtStr <> '' then
    AGuia.c33_dataPagamento := ParseFlexDate(dtStr)
  else if AGuia.c14_dataVencimento > 0 then
    AGuia.c33_dataPagamento := AGuia.c14_dataVencimento;

  AGuia.c34_tipoIdentificacaoDestinatario := ReadJsonInt(jSource, ['c34_tipoIdentificacaoDestinatario', 'tipoIdentificacaoDestinatario'], 0);
  jNode := jSource.Find('c35_idContribuinteDestinatario');
  if not Assigned(jNode) then
    jNode := jSource.Find('contribuinteDestinatario');
  if Assigned(jNode) then
  begin
    if jNode.JSONType = jtObject then
    begin
      jDestObj := TJSONObject(jNode);
      docStr := OnlyNumber(ReadJsonStr(jDestObj, ['CNPJ', 'cnpj'], ''));
      if docStr <> '' then
      begin
        AGuia.c35_idContribuinteDestinatario := docStr;
        if AGuia.c34_tipoIdentificacaoDestinatario = 0 then
          AGuia.c34_tipoIdentificacaoDestinatario := 1;
      end
      else
      begin
        docStr := OnlyNumber(ReadJsonStr(jDestObj, ['CPF', 'cpf'], ''));
        if docStr <> '' then
        begin
          AGuia.c35_idContribuinteDestinatario := docStr;
          if AGuia.c34_tipoIdentificacaoDestinatario = 0 then
            AGuia.c34_tipoIdentificacaoDestinatario := 2;
        end;
      end;
      ieStr := OnlyNumber(ReadJsonStr(jDestObj, ['IE', 'ie'], ''));
      if ieStr <> '' then
        AGuia.c36_inscricaoEstadualDestinatario := ieStr;
    end
    else if not (jNode.JSONType in [jtNull, jtArray]) then
      AGuia.c35_idContribuinteDestinatario := OnlyNumber(jNode.AsString);
  end;
  if (AGuia.c34_tipoIdentificacaoDestinatario = 0) and (AGuia.c35_idContribuinteDestinatario <> '') then
  begin
    if Length(AGuia.c35_idContribuinteDestinatario) = 11 then
      AGuia.c34_tipoIdentificacaoDestinatario := 2
    else
      AGuia.c34_tipoIdentificacaoDestinatario := 1;
  end;

  ieStr := OnlyNumber(ReadJsonStr(jSource, ['c36_inscricaoEstadualDestinatario', 'inscricaoEstadualDestinatario'], ''));
  if ieStr <> '' then
    AGuia.c36_inscricaoEstadualDestinatario := ieStr;
  AGuia.c37_razaoSocialDestinatario := TiraAcentos(ReadJsonStr(jSource, ['c37_razaoSocialDestinatario', 'razaoSocialDestinatario'], AGuia.c37_razaoSocialDestinatario));
  AGuia.c38_municipioDestinatario := ReadJsonStr(jSource, ['c38_municipioDestinatario', 'municipioDestinatario'], AGuia.c38_municipioDestinatario);
  AGuia.c42_identificadorGuia := ReadJsonStr(jSource, ['c42_identificadorGuia', 'identificadorGuia'], AGuia.c42_identificadorGuia);
  if AGuia.c42_identificadorGuia = '' then
  begin
    AGuia.c42_identificadorGuia := Copy(OnlyNumber(AGuia.c04_docOrigem), 1, 10);
    if AGuia.c42_identificadorGuia = '' then
      AGuia.c42_identificadorGuia := '1';
  end;

  // Campos GNRE 2.00 e aliases alternativos (c16_atualizacaoMonetaria, c17_juros, c18_multa)
  tpGnreStr := LowerCase(ReadJsonStr(jSource, ['tipoGNRE', 'tipoGnre'], ''));
  if (tpGnreStr = '1') or (tpGnreStr = 'tgmultiplosdoc') or (tpGnreStr = 'tgmultiplosdocorigem') then
    AGuia.tipoGNRE := tgMultiplosDoc
  else if (tpGnreStr = '2') or (tpGnreStr = 'tgmultiplasreceitas') then
    AGuia.tipoGNRE := tgMultiplasReceitas
  else
    AGuia.tipoGNRE := tgSimples;

  AGuia.ValorFECP := ReadJsonCurr(jSource, ['ValorFECP', 'valorFECP'], AGuia.ValorFECP);
  AGuia.TotalFECP := ReadJsonCurr(jSource, ['TotalFECP', 'totalFECP'], AGuia.TotalFECP);
  AGuia.MultaICMS := ReadJsonCurr(jSource, ['MultaICMS', 'multaICMS', 'c18_multa', 'valorMulta'], AGuia.MultaICMS);
  AGuia.MultaFECP := ReadJsonCurr(jSource, ['MultaFECP', 'multaFECP'], AGuia.MultaFECP);
  AGuia.JurosICMS := ReadJsonCurr(jSource, ['JurosICMS', 'jurosICMS', 'c17_juros', 'valorJuros'], AGuia.JurosICMS);
  AGuia.JurosFECP := ReadJsonCurr(jSource, ['JurosFECP', 'jurosFECP'], AGuia.JurosFECP);
  AGuia.AtualMonetICMS := ReadJsonCurr(jSource, ['AtualMonetICMS', 'atualMonetICMS', 'c16_atualizacaoMonetaria', 'valorAtualizacao'], AGuia.AtualMonetICMS);
  AGuia.AtualMonetFECP := ReadJsonCurr(jSource, ['AtualMonetFECP', 'atualMonetFECP'], AGuia.AtualMonetFECP);
  AGuia.numeroControle := ReadJsonStr(jSource, ['numeroControle', 'NumeroControle'], AGuia.numeroControle);

  // Referencia (c05_referencia ou referencia)
  jNode := jSource.Find('c05_referencia');
  if not Assigned(jNode) then
    jNode := jSource.Find('referencia');
  if Assigned(jNode) and (jNode.JSONType = jtObject) then
  begin
    jRefObj := TJSONObject(jNode);
    AGuia.referencia.periodo := ReadJsonInt(jRefObj, ['periodo', 'Periodo'], 0);
    mesStr := ReadJsonStr(jRefObj, ['mes', 'Mes'], '');
    mesInt := StrToIntDef(mesStr, -1);
    if (mesInt >= 1) and (mesInt <= 12) then
      AGuia.referencia.mes := FormatFloat('00', mesInt)
    else
      AGuia.referencia.mes := mesStr;
    AGuia.referencia.ano := ReadJsonInt(jRefObj, ['ano', 'Ano'], 0);
    AGuia.referencia.parcela := ReadJsonInt(jRefObj, ['parcela', 'Parcela'], 0);
  end;

  // Campos Extras (camposExtras ou c39_camposExtras)
  jNode := jSource.Find('camposExtras');
  if not Assigned(jNode) then
    jNode := jSource.Find('c39_camposExtras');
  if Assigned(jNode) and (jNode.JSONType = jtArray) then
  begin
    AGuia.camposExtras.Clear;
    jArr := TJSONArray(jNode);
    for I := 0 to jArr.Count - 1 do
    begin
      if jArr.Items[I].JSONType = jtObject then
      begin
        jExtraObj := TJSONObject(jArr.Items[I]);
        jSub := jExtraObj.Find('CampoExtra');
        if not Assigned(jSub) then
          jSub := jExtraObj.Find('campoExtra');
        if Assigned(jSub) and (jSub.JSONType = jtObject) then
          jExtraObj := TJSONObject(jSub);

        extraItem := AGuia.camposExtras.New;
        extraItem.CampoExtra.codigo := ReadJsonInt(jExtraObj, ['codigo', 'Codigo'], 0);
        extraItem.CampoExtra.tipo := ReadJsonStr(jExtraObj, ['tipo', 'Tipo'], 'T');
        extraItem.CampoExtra.valor := TiraAcentos(ReadJsonStr(jExtraObj, ['valor', 'Valor'], ''));
      end;
    end;
  end;
end;

procedure TACBRBridgeGNRE.PopularGuiasPayload(const jPayload: TJSONObject);
var
  jNode: TJSONData;
  jArr: TJSONArray;
  I: Integer;
  ItemGuia: Guia;
begin
  facbr.Guias.Clear;
  if not Assigned(jPayload) then
    Exit;

  ApplyVersaoFromJSON(jPayload);

  jNode := jPayload.Find('guias');
  if not Assigned(jNode) then
    jNode := jPayload.Find('Guias');
  if Assigned(jNode) and (jNode.JSONType = jtArray) then
  begin
    jArr := TJSONArray(jNode);
    for I := 0 to jArr.Count - 1 do
    begin
      if jArr.Items[I].JSONType = jtObject then
      begin
        ItemGuia := facbr.Guias.Add;
        PopularGuiaGNRE(TJSONObject(jArr.Items[I]), ItemGuia.GNRE);
      end;
    end;
    Exit;
  end;

  jNode := jPayload.Find('gnre');
  if not Assigned(jNode) then jNode := jPayload.Find('GNRE');
  if not Assigned(jNode) then jNode := jPayload.Find('guia');
  if not Assigned(jNode) then jNode := jPayload.Find('Guia');

  ItemGuia := facbr.Guias.Add;
  if Assigned(jNode) and (jNode.JSONType = jtObject) then
    PopularGuiaGNRE(TJSONObject(jNode), ItemGuia.GNRE)
  else
    PopularGuiaGNRE(jPayload, ItemGuia.GNRE);
end;

function TACBRBridgeGNRE.GNREToXML(const jGNRE: TJSONObject): TJSONObject;
var
  I: Integer;
  xmlStr: string;
  arrXmls: TJSONArray;
  itemObj: TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  facbr.Guias.Clear;
  try
    try
      PopularGuiasPayload(jGNRE);
      if facbr.Guias.Count = 0 then
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add('sucesso', False);
        Result.Add(RSMessageField, 'Nenhuma guia GNRE informada para geracao de XML.');
        Exit;
      end;

      facbr.Guias.GerarGNRE;
      if jGNRE.Get('validar_xsd', jGNRE.Get('ValidarXSD', False)) then
        facbr.Guias.Validar;

      xmlStr := Trim(facbr.Guias.Items[0].XMLOriginal);
      if xmlStr = '' then
        xmlStr := Trim(facbr.Guias.Items[0].GerarXML);

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('sucesso', True);
      if facbr.Configuracoes.Geral.VersaoDF = ve100 then
        Result.Add('versao', '1.00')
      else
        Result.Add('versao', '2.00');
      Result.Add(RSXmlKey, EncodeStringBase64(xmlStr));
      Result.Add('xml_raw', xmlStr);
      Result.Add(RSXMLField, xmlStr);

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
          itemObj.Add('xml_raw', xmlStr);
          arrXmls.Add(itemObj);
        end;
        Result.Add('guias_xml', arrXmls);
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add('sucesso', False);
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
  CarregaConfig;
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
      begin
        Result.Add(RSXmlKey, EncodeStringBase64(xmlStr));
        Result.Add('xml_raw', xmlStr);
      end;
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
