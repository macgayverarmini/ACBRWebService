unit method.acbr.escpos;

{$mode Delphi}
{$M+}

interface

uses
  TypInfo,
  IniFiles,
  ACBrPosPrinter,
  fpjson,
  jsonconvert,
  jsonparser,
  streamtools,
  Classes,
  SysUtils,
  resource.strings.global,
  resource.strings.msg;

type
  TACBRBridgeEscPos = class
  private
    fcfg: string;
    facbr: TACBrPosPrinter;
    procedure AplicarConfigIni(const AIniText: string);
    procedure CarregaConfig(const AllowEmpty: Boolean = True);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function EscPos(const jEscPos: TJSONObject): TJSONObject;
    function PortasDisponiveis: TJSONObject;
  end;

  TACBRModelosJSONEscPos = class(TACBRBridgeEscPos)
  public
    function ModelConfig: TJSONObject;
  end;

implementation

{ TACBRModelosJSONEscPos }

function TACBRModelosJSONEscPos.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr, 'Erro ao gerar modelo de configuracao do EscPos');
end;

{ TACBRBridgeEscPos }

procedure TACBRBridgeEscPos.AplicarConfigIni(const AIniText: string);
var
  SL, Sections, Keys: TStringList;
  Ini: TMemIniFile;
  RootJson, TargetJson: TJSONObject;
  S, K, V, SecUpper, SubProp: string;
  I, J: Integer;
  IntVal: Int64;
begin
  if Trim(AIniText) = '' then
    Exit;

  SL := TStringList.Create;
  Sections := TStringList.Create;
  Keys := TStringList.Create;
  Ini := TMemIniFile.Create('');
  RootJson := TJSONObject.Create;
  try
    SL.Text := AIniText;
    Ini.SetStrings(SL);
    Ini.ReadSections(Sections);

    for I := 0 to Sections.Count - 1 do
    begin
      S := Sections[I];
      SecUpper := UpperCase(Trim(S));
      SubProp := '';
      if (SecUpper = '') or (SecUpper = 'POSPRINTER') then
        TargetJson := RootJson
      else
      begin
        if (SecUpper = 'BARRAS') or (SecUpper = 'CONFIGBARRAS') then
          SubProp := 'ConfigBarras'
        else if (SecUpper = 'QRCODE') or (SecUpper = 'CONFIGQRCODE') then
          SubProp := 'ConfigQRCode'
        else if (SecUpper = 'LOGO') or (SecUpper = 'CONFIGLOGO') then
          SubProp := 'ConfigLogo'
        else if (SecUpper = 'GAVETA') or (SecUpper = 'CONFIGGAVETA') then
          SubProp := 'ConfigGaveta'
        else if (SecUpper = 'MODOPAGINA') or (SecUpper = 'CONFIGMODOPAGINA') then
          SubProp := 'ConfigModoPagina'
        else
          SubProp := S;

        TargetJson := RootJson.Find(SubProp) as TJSONObject;
        if not Assigned(TargetJson) then
        begin
          TargetJson := TJSONObject.Create;
          RootJson.Add(SubProp, TargetJson);
        end;
      end;

      Keys.Clear;
      Ini.ReadSection(S, Keys);
      for J := 0 to Keys.Count - 1 do
      begin
        K := Keys[J];
        V := Trim(Ini.ReadString(S, K, ''));
        if (V <> '') and TryStrToInt64(V, IntVal) then
          TargetJson.Add(K, IntVal)
        else
          TargetJson.Add(K, V);
      end;
    end;

    TJSONTools.JsonToObj(RootJson, facbr);
  finally
    RootJson.Free;
    Ini.Free;
    Keys.Free;
    Sections.Free;
    SL.Free;
  end;
end;

procedure TACBRBridgeEscPos.CarregaConfig(const AllowEmpty: Boolean);
var
  LTrimmed: string;
  LData: TJSONData;
begin
  LTrimmed := Trim(fcfg);
  if (LTrimmed = '') and (not AllowEmpty) then
    raise Exception.Create(RSConfigEmptyError);

  if LTrimmed <> '' then
  begin
    LData := nil;
    if (LTrimmed[1] = '{') or (LTrimmed[1] = '"') then
    begin
      try
        LData := GetJSON(LTrimmed);
      except
        LData := nil;
      end;
    end;

    if Assigned(LData) then
    begin
      try
        if LData is TJSONObject then
          TJSONTools.JsonToObj(TJSONObject(LData), facbr)
        else if LData is TJSONString then
          AplicarConfigIni(TJSONString(LData).AsString);
      finally
        LData.Free;
      end;
    end
    else
      AplicarConfigIni(LTrimmed);

    fcfg := '';
  end;
end;

constructor TACBRBridgeEscPos.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrPosPrinter.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeEscPos.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeEscPos.EscPos(const jEscPos: TJSONObject): TJSONObject;
var
  jLinhas, jBuffer: TJSONData;
  jArr: TJSONArray;
  SL: TStringList;
  I, tamanho: Integer;
  textoImprimir, tmpDir, spoolFile, b64Spool: string;
  isTempSpool: Boolean;
begin
  Result := TJSONObject.Create;
  spoolFile := '';
  isTempSpool := False;
  try
    CarregaConfig(True);

    textoImprimir := '';
    if Assigned(jEscPos) then
    begin
      TJSONTools.JsonToObj(jEscPos, facbr);

      jBuffer := jEscPos.Find('Buffer');
      if Assigned(jBuffer) and (jBuffer.JSONType = jtString) then
        facbr.Buffer.Text := jBuffer.AsString;

      jLinhas := jEscPos.Find('Linhas');
      if not Assigned(jLinhas) then
        jLinhas := jEscPos.Find('Texto');
      if Assigned(jLinhas) then
      begin
        if jLinhas.JSONType = jtArray then
        begin
          SL := TStringList.Create;
          try
            jArr := TJSONArray(jLinhas);
            for I := 0 to jArr.Count - 1 do
              SL.Add(jArr.Items[I].AsString);
            textoImprimir := SL.Text;
          finally
            SL.Free;
          end;
        end
        else if not (jLinhas.JSONType in [jtNull, jtObject]) then
          textoImprimir := jLinhas.AsString;
      end;
    end;

    isTempSpool := Trim(facbr.Porta) = '';
    if isTempSpool then
    begin
      tmpDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim;
      ForceDirectories(tmpDir);
      spoolFile := tmpDir + Format('escpos_%d_%d.bin', [GetTickCount64, Random(1000000)]);
      facbr.Porta := spoolFile;
    end;

    try
      facbr.Ativar;
      if (textoImprimir <> '') or (facbr.Buffer.Count > 0) then
        facbr.Imprimir(textoImprimir);
      facbr.Desativar;

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSMessageField, 'Impressao executada com sucesso.');
      Result.Add('modelo', GetEnumName(TypeInfo(TACBrPosPrinterModelo), Ord(facbr.Modelo)));

      if isTempSpool and FileExists(spoolFile) then
      begin
        b64Spool := FileToStringBase64(spoolFile, True, tamanho);
        Result.Add('spool_base64', b64Spool);
        Result.Add(RSTamanhoField, tamanho);
      end;
    finally
      if facbr.Ativo then
        facbr.Desativar;
      if isTempSpool then
      begin
        facbr.Porta := '';
        if (spoolFile <> '') and FileExists(spoolFile) then
          SysUtils.DeleteFile(spoolFile);
      end;
    end;
  except
    on E: Exception do
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro na impressao: ' + E.Message);
      Result.Add(RSErrorField, 'Erro na impressao: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeEscPos.PortasDisponiveis: TJSONObject;
var
  SL: TStringList;
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  SL := TStringList.Create;
  Arr := TJSONArray.Create;
  try
    try
      CarregaConfig(True);
      facbr.Device.AcharPortas(SL);
      for I := 0 to SL.Count - 1 do
        Arr.Add(SL[I]);
      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('portas', Arr);
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao listar portas: ' + E.Message);
        Arr.Free;
      end;
    end;
  finally
    SL.Free;
  end;
end;

end.
