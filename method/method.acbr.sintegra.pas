unit method.acbr.sintegra;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrSintegra,
  Variants,
  fpjson,
  jsonconvert,
  jsonparser,
  streamtools,
  Classes,
  SysUtils,
  resource.strings.global,
  resource.strings.msg;

type
  TACBRBridgeSintegra = class
  private
    fcfg: string;
    facbr: TACBrSintegra;
    procedure CarregaConfig(const AllowEmpty: Boolean = True);
    procedure StabilizeSameDaySortOrder;
    procedure EnsureMultiLineRegistro90(const AFileName: string);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Sintegra(const jSintegra: TJSONObject): TJSONObject;
    function Gerar(const jSintegra: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONSintegra = class(TACBRBridgeSintegra)
  public
    function ModelConfig: TJSONObject;
    function ModelGerar: TJSONObject;
  end;

implementation

{ TACBRModelosJSONSintegra }

function TACBRModelosJSONSintegra.ModelConfig: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('FileName', facbr.FileName);
  Result.Add('VersaoValidador', 'vv524');
  Result.Add('Informa88C', facbr.Informa88C);
  Result.Add('Informa88EAN', facbr.Informa88EAN);
  Result.Add('Informa88SME', facbr.Informa88SME);
  Result.Add('Informa88SMS', facbr.Informa88SMS);
  Result.Add('InformaSapiMG', facbr.InformaSapiMG);
end;

function TACBRModelosJSONSintegra.ModelGerar: TJSONObject;
begin
  facbr.LimparRegistros;
  TJSONTools.PopulateModelDefaults(facbr, 4);
  Result := TJSONObject.Create;
  Result.Add('sintegra', TJSONTools.ObjToJson(facbr));
  facbr.LimparRegistros;
end;

{ TACBRBridgeSintegra }

procedure TACBRBridgeSintegra.CarregaConfig(const AllowEmpty: Boolean);
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

constructor TACBRBridgeSintegra.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrSintegra.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeSintegra.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

{ Estabiliza Sort51/Sort70 do ACBrSintegra sob TList.Sort (QuickSort instavel do FPC) em registros do mesmo dia }
procedure TACBRBridgeSintegra.StabilizeSameDaySortOrder;
var
  I: Integer;
begin
  for I := 0 to facbr.Registros51.Count - 1 do
    facbr.Registros51[I].DataDocumento := Trunc(facbr.Registros51[I].DataDocumento) + (I * 1.0E-8);
  for I := 0 to facbr.Registros70.Count - 1 do
    facbr.Registros70[I].DataDocumento := Trunc(facbr.Registros70[I].DataDocumento) + (I * 1.0E-8);
end;

{ Contorna limite de 1 linha em TACBrSintegra.GerarRegistros90 (Conv. ICMS 57/95 exige ate 9 pares por linha 90) }
procedure TACBRBridgeSintegra.EnsureMultiLineRegistro90(const AFileName: string);
const
  ORDEM_90: array[0..16] of string = (
    '50', '51', '53', '54', '55', '56', '60', '61',
    '70', '71', '74', '75', '76', '77', '85', '86', '88'
  );
var
  SL: TStringList;
  K, M, CountInChunk, Total90Lines, TotalFileLines, CntTipo, ActiveLen: Integer;
  Tipo2, Prefix90, Suffix90, ChunkBody, Cnpj10, Ie10: string;
  ActiveTipos: array[0..16] of string;
  ActiveCounts: array[0..16] of Integer;
begin
  if (AFileName = '') or (not FileExists(AFileName)) then
    Exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    while (SL.Count > 0) and (Copy(SL[SL.Count - 1], 1, 2) = '90') do
      SL.Delete(SL.Count - 1);

    Cnpj10 := '';
    Ie10 := '';
    if (SL.Count > 0) and (Copy(SL[0], 1, 2) = '10') and (Length(SL[0]) >= 30) then
    begin
      Cnpj10 := Copy(SL[0], 3, 14);
      Ie10 := Copy(SL[0], 17, 14);
    end;

    if (Cnpj10 = '') or (Ie10 = '') then
      Exit;

    ActiveLen := 0;
    for K := Low(ORDEM_90) to High(ORDEM_90) do
    begin
      Tipo2 := ORDEM_90[K];
      CntTipo := 0;
      for M := 0 to SL.Count - 1 do
        if Copy(SL[M], 1, 2) = Tipo2 then
          Inc(CntTipo);
      if CntTipo > 0 then
      begin
        ActiveTipos[ActiveLen] := Tipo2;
        ActiveCounts[ActiveLen] := CntTipo;
        Inc(ActiveLen);
      end;
    end;

    if ActiveLen > 0 then
      Total90Lines := ((ActiveLen - 1) div 9) + 2
    else
      Total90Lines := 1;

    if Total90Lines > 9 then
      Suffix90 := '9'
    else
      Suffix90 := IntToStr(Total90Lines);

    Prefix90 := '90' + Cnpj10 + Ie10;
    K := 0;
    while K < ActiveLen do
    begin
      ChunkBody := '';
      CountInChunk := 0;
      while (K < ActiveLen) and (CountInChunk < 9) do
      begin
        ChunkBody := ChunkBody + Copy(ActiveTipos[K] + '  ', 1, 2) + Format('%.8d', [ActiveCounts[K]]);
        Inc(K);
        Inc(CountInChunk);
      end;
      SL.Add(Prefix90 + ChunkBody + StringOfChar(' ', 95 - Length(ChunkBody)) + Suffix90);
    end;

    TotalFileLines := SL.Count + 1;
    ChunkBody := '99' + Format('%.8d', [TotalFileLines]);
    SL.Add(Prefix90 + ChunkBody + StringOfChar(' ', 95 - Length(ChunkBody)) + Suffix90);

    SL.LineBreak := #13#10;
    SL.SaveToFile(AFileName);
  finally
    SL.Free;
  end;
end;

function TACBRBridgeSintegra.Sintegra(const jSintegra: TJSONObject): TJSONObject;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;
  Result.Add(RSStatusField, RSStatusSucesso);
  Result.Add(RSMessageField, 'ACBr Sintegra inicializado com sucesso.');
end;

function TACBRBridgeSintegra.Gerar(const jSintegra: TJSONObject): TJSONObject;
var
  tamanho: Integer;
  isTempFile: Boolean;
  jData: TJSONObject;
  jNode: TJSONData;
  tmpDir: string;
begin
  Result := TJSONObject.Create;
  isTempFile := False;
  try
    try
      CarregaConfig(True);

      if Trim(facbr.FileName) = '' then
      begin
        isTempFile := True;
        tmpDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim;
        ForceDirectories(tmpDir);
        facbr.FileName := tmpDir + Format('sintegra_%d_%d.txt', [GetTickCount64, Random(1000000)]);
      end;

      jData := jSintegra;
      if Assigned(jSintegra) then
      begin
        jNode := jSintegra.Find('sintegra');
        if Assigned(jNode) and (jNode is TJSONObject) then
          jData := TJSONObject(jNode);
      end;

      facbr.LimparRegistros;
      TJSONTools.JsonToObj(jData, facbr);
      StabilizeSameDaySortOrder;

      try
        facbr.GeraArquivo;
      except
        on E: Exception do
          if (Pos('Registro: 90', E.Message) = 0) or (not FileExists(facbr.FileName)) then
            raise;
      end;

      EnsureMultiLineRegistro90(facbr.FileName);

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSMessageField, 'Sintegra gerado com sucesso.');
      Result.Add('arquivo', facbr.FileName);
      if FileExists(facbr.FileName) then
      begin
        Result.Add('arquivo_base64', FileToStringBase64(facbr.FileName, isTempFile, tamanho));
        Result.Add(RSTamanhoField, tamanho);
      end;
    except
      on E: Exception do
      begin
        if isTempFile and (facbr.FileName <> '') and FileExists(facbr.FileName) then
          SysUtils.DeleteFile(facbr.FileName);
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao gerar Sintegra: ' + E.Message);
      end;
    end;
  finally
    facbr.LimparRegistros;
  end;
end;

end.
