unit method.acbr.escpos;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  TypInfo,
  ACBrPosPrinter,
  Variants,
  fpjson,
  jsonconvert,
  jsonparser,
  Base64,
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

procedure TACBRBridgeEscPos.CarregaConfig(const AllowEmpty: Boolean);
var
  O: TJSONObject;
begin
  if (Trim(fcfg) = '') and (not AllowEmpty) then
    raise Exception.Create(RSConfigEmptyError);

  if Trim(fcfg) <> '' then
  begin
    O := GetJSON(fcfg) as TJSONObject;
    try
      TJSONTools.JsonToObj(O, facbr);
    finally
      O.Free;
    end;
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
  jLinhas: TJSONData;
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
      spoolFile := tmpDir + Format('escpos_spool_%d_%d.bin', [GetTickCount64, Random(1000000)]);
      facbr.Porta := spoolFile;
    end;

    try
      facbr.Ativar;
      if textoImprimir <> '' then
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
      end
      else if (not isTempSpool) and FileExists(facbr.Porta) then
      begin
        b64Spool := FileToStringBase64(facbr.Porta, False, tamanho);
        Result.Add('spool_base64', b64Spool);
        Result.Add(RSTamanhoField, tamanho);
      end;
    finally
      if facbr.Ativo then
        facbr.Desativar;
      if isTempSpool and (spoolFile <> '') and FileExists(spoolFile) then
        SysUtils.DeleteFile(spoolFile);
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
