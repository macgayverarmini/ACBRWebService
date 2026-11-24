unit method.acbr.sped;

{$mode Delphi}
{$M+}

interface

uses
  ACBrSpedFiscal,
  ACBrSpedPisCofins,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes,
  SysUtils,
  streamtools,
  ACBrEPCImportar,
  ACBrEPCBlocos,
  ACBrEFDImportar,
  ACBrEFDBlocos,
  resource.strings.global,
  resource.strings.msg;

type
  TACBRBridgeSPED = class
  private
    fcfg: string;
    facbr: TACBrSpedFiscal;
    fErrosValidacao: TStringList;
    procedure CarregaConfig(const AllowEmpty: Boolean = True);
    procedure DoAcbrError(const MsnError: string);
    procedure PopularBlocosEFD(const jRoot: TJSONObject; out AOmit0100: Boolean);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function SPED(const jSPED: TJSONObject): TJSONObject;
    function Gerar(const jSPED: TJSONObject): TJSONObject;
    function Importar(const jSPED: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONSPED = class(TACBRBridgeSPED)
  public
    function ModelConfig: TJSONObject;
    function ModelGerar: TJSONObject;
  end;

  TACBRBridgeSPEDPisCofins = class
  private
    fcfg: string;
    facbr: TACBrSPEDPisCofins;
    fErrosValidacao: TStringList;
    procedure CarregaConfig(const AllowEmpty: Boolean = True);
    procedure DoAcbrError(const MsnError: string);
    procedure PopularBlocosEPC(const jRoot: TJSONObject; out AOmitBlocoP: Boolean);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Gerar(const jSPED: TJSONObject): TJSONObject;
    function Importar(const jSPED: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONSPEDPisCofins = class(TACBRBridgeSPEDPisCofins)
  public
    function ModelConfig: TJSONObject;
    function ModelGerar: TJSONObject;
    function ModelImportar: TJSONObject;
  end;

implementation

function UnicodeToCp1252Byte(const ACodePoint: Cardinal): Byte;
begin
  case ACodePoint of
    0..$7F, $A0..$FF: Result := Byte(ACodePoint);
    $20AC: Result := $80;
    $201A: Result := $82;
    $0192: Result := $83;
    $201E: Result := $84;
    $2026: Result := $85;
    $2020: Result := $86;
    $2021: Result := $87;
    $02C6: Result := $88;
    $2030: Result := $89;
    $0160: Result := $8A;
    $2039: Result := $8B;
    $0152: Result := $8C;
    $017D: Result := $8E;
    $2018: Result := $91;
    $2019: Result := $92;
    $201C: Result := $93;
    $201D: Result := $94;
    $2022: Result := $95;
    $2013: Result := $96;
    $2014: Result := $97;
    $02DC: Result := $98;
    $2122: Result := $99;
    $0161: Result := $9A;
    $203A: Result := $9B;
    $0153: Result := $9C;
    $017E: Result := $9E;
    $0178: Result := $9F;
    $80..$9F: Result := Byte(ACodePoint);
  else
    Result := Ord('?');
  end;
end;

function Cp1252ByteToCodePoint(const B: Byte): Cardinal;
begin
  case B of
    $80: Result := $20AC;
    $82: Result := $201A;
    $83: Result := $0192;
    $84: Result := $201E;
    $85: Result := $2026;
    $86: Result := $2020;
    $87: Result := $2021;
    $88: Result := $02C6;
    $89: Result := $2030;
    $8A: Result := $0160;
    $8B: Result := $2039;
    $8C: Result := $0152;
    $8E: Result := $017D;
    $91: Result := $2018;
    $92: Result := $2019;
    $93: Result := $201C;
    $94: Result := $201D;
    $95: Result := $2022;
    $96: Result := $2013;
    $97: Result := $2014;
    $98: Result := $02DC;
    $99: Result := $2122;
    $9A: Result := $0161;
    $9B: Result := $203A;
    $9C: Result := $0153;
    $9E: Result := $017E;
    $9F: Result := $0178;
  else
    Result := B;
  end;
end;

function CodePointToUtf8Seq(const CP: Cardinal): RawByteString;
begin
  if CP <= $7F then
  begin
    SetLength(Result, 1);
    Result[1] := AnsiChar(CP);
  end
  else if CP <= $7FF then
  begin
    SetLength(Result, 2);
    Result[1] := AnsiChar($C0 or ((CP shr 6) and $1F));
    Result[2] := AnsiChar($80 or (CP and $3F));
  end
  else
  begin
    SetLength(Result, 3);
    Result[1] := AnsiChar($E0 or ((CP shr 12) and $0F));
    Result[2] := AnsiChar($80 or ((CP shr 6) and $3F));
    Result[3] := AnsiChar($80 or (CP and $3F));
  end;
end;

function IsValidUtf8Raw(const ARaw: RawByteString): Boolean;
var
  I, Len: Integer;
  B, B2, B3, B4: Byte;
begin
  Result := True;
  Len := Length(ARaw);
  I := 1;
  while I <= Len do
  begin
    B := Byte(ARaw[I]);
    if B <= $7F then
      Inc(I)
    else if (B and $E0) = $C0 then
    begin
      if (B < $C2) or (I + 1 > Len) then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      if (B2 and $C0) <> $80 then
        Exit(False);
      Inc(I, 2);
    end
    else if (B and $F0) = $E0 then
    begin
      if I + 2 > Len then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      if ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) then
        Exit(False);
      if (B = $E0) and (B2 < $A0) then
        Exit(False);
      Inc(I, 3);
    end
    else if (B and $F8) = $F0 then
    begin
      if I + 3 > Len then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      B4 := Byte(ARaw[I + 3]);
      if ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) or ((B4 and $C0) <> $80) then
        Exit(False);
      Inc(I, 4);
    end
    else
      Exit(False);
  end;
end;

function EnsureUtf8FromBytes(const ARaw: RawByteString): UTF8String;
var
  I, StartIdx: Integer;
  OutS: RawByteString;
begin
  if ARaw = '' then
    Exit('');
  StartIdx := 1;
  if (Length(ARaw) >= 3) and (Byte(ARaw[1]) = $EF) and (Byte(ARaw[2]) = $BB) and (Byte(ARaw[3]) = $BF) then
    StartIdx := 4;
  if IsValidUtf8Raw(Copy(ARaw, StartIdx, MaxInt)) then
  begin
    OutS := Copy(ARaw, StartIdx, MaxInt);
    SetCodePage(OutS, CP_UTF8, False);
    Result := OutS;
    Exit;
  end;
  OutS := '';
  for I := StartIdx to Length(ARaw) do
    OutS := OutS + CodePointToUtf8Seq(Cp1252ByteToCodePoint(Byte(ARaw[I])));
  SetCodePage(OutS, CP_UTF8, False);
  Result := OutS;
end;

procedure WriteUtf8TempFile(const AFileName: string; const AUtf8: UTF8String);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(AUtf8) > 0 then
      FS.WriteBuffer(Pointer(AUtf8)^, Length(AUtf8));
  finally
    FS.Free;
  end;
end;

procedure ConvertFileUtf8ToCp1252(const AFileName: string);
var
  FS: TFileStream;
  InBytes, OutBytes: TBytes;
  InLen, OutLen, I: Integer;
  B, B2, B3, B4: Byte;
  CP: Cardinal;

  procedure AppendByte(const AB: Byte);
  begin
    if OutLen >= Length(OutBytes) then
      SetLength(OutBytes, OutLen * 2 + 1024);
    OutBytes[OutLen] := AB;
    Inc(OutLen);
  end;

begin
  if (AFileName = '') or not FileExists(AFileName) then
    Exit;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    InLen := FS.Size;
    SetLength(InBytes, InLen);
    if InLen > 0 then
      FS.ReadBuffer(InBytes[0], InLen);
  finally
    FS.Free;
  end;

  SetLength(OutBytes, InLen + 64);
  OutLen := 0;
  I := 0;
  if (InLen >= 3) and (InBytes[0] = $EF) and (InBytes[1] = $BB) and (InBytes[2] = $BF) then
    I := 3;

  while I < InLen do
  begin
    B := InBytes[I];
    if B = 13 then
    begin
      AppendByte(13);
      AppendByte(10);
      if (I + 1 < InLen) and (InBytes[I + 1] = 10) then
        Inc(I, 2)
      else
        Inc(I);
    end
    else if B = 10 then
    begin
      AppendByte(13);
      AppendByte(10);
      Inc(I);
    end
    else if B <= $7F then
    begin
      AppendByte(B);
      Inc(I);
    end
    else if ((B and $E0) = $C0) and (B >= $C2) and (I + 1 < InLen) and ((InBytes[I + 1] and $C0) = $80) then
    begin
      B2 := InBytes[I + 1];
      CP := ((Cardinal(B and $1F) shl 6) or Cardinal(B2 and $3F));
      AppendByte(UnicodeToCp1252Byte(CP));
      Inc(I, 2);
    end
    else if ((B and $F0) = $E0) and (I + 2 < InLen) and ((InBytes[I + 1] and $C0) = $80) and ((InBytes[I + 2] and $C0) = $80) then
    begin
      B2 := InBytes[I + 1];
      B3 := InBytes[I + 2];
      CP := (Cardinal(B and $0F) shl 12) or (Cardinal(B2 and $3F) shl 6) or Cardinal(B3 and $3F);
      AppendByte(UnicodeToCp1252Byte(CP));
      Inc(I, 3);
    end
    else if ((B and $F8) = $F0) and (I + 3 < InLen) and ((InBytes[I + 1] and $C0) = $80) and ((InBytes[I + 2] and $C0) = $80) and ((InBytes[I + 3] and $C0) = $80) then
    begin
      B2 := InBytes[I + 1];
      B3 := InBytes[I + 2];
      B4 := InBytes[I + 3];
      CP := (Cardinal(B and $07) shl 18) or (Cardinal(B2 and $3F) shl 12) or (Cardinal(B3 and $3F) shl 6) or Cardinal(B4 and $3F);
      AppendByte(UnicodeToCp1252Byte(CP));
      Inc(I, 4);
    end
    else
    begin
      AppendByte(B);
      Inc(I);
    end;
  end;

  if (OutLen > 0) and not ((OutLen >= 2) and (OutBytes[OutLen - 2] = 13) and (OutBytes[OutLen - 1] = 10)) then
  begin
    AppendByte(13);
    AppendByte(10);
  end;

  FS := TFileStream.Create(AFileName, fmCreate);
  try
    if OutLen > 0 then
      FS.WriteBuffer(OutBytes[0], OutLen);
  finally
    FS.Free;
  end;
end;

function GetJsonObj(const AParent: TJSONObject; const AKey: string): TJSONObject;
var
  D: TJSONData;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;
  D := AParent.Find(AKey);
  if Assigned(D) and (D is TJSONObject) then
    Result := TJSONObject(D);
end;

function HasNonNullKey(const AParent: TJSONObject; const AKey: string): Boolean;
var
  D: TJSONData;
begin
  Result := False;
  if not Assigned(AParent) then
    Exit;
  D := AParent.Find(AKey);
  Result := Assigned(D) and not D.IsNull;
end;

{ TACBRModelosJSONSPED }

function TACBRModelosJSONSPED.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr);
end;

function TACBRModelosJSONSPED.ModelGerar: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr);
end;

{ TACBRBridgeSPED }

procedure TACBRBridgeSPED.CarregaConfig(const AllowEmpty: Boolean);
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

constructor TACBRBridgeSPED.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrSpedFiscal.Create(nil);
  fErrosValidacao := TStringList.Create;
  facbr.OnError := DoAcbrError;
  fcfg := Cfg;
end;

destructor TACBRBridgeSPED.Destroy;
begin
  FreeAndNil(fErrosValidacao);
  FreeAndNil(facbr);
  inherited Destroy;
end;

procedure TACBRBridgeSPED.DoAcbrError(const MsnError: string);
begin
  if Assigned(fErrosValidacao) and (Trim(MsnError) <> '') then
    fErrosValidacao.Add(Trim(MsnError));
end;

function TACBRBridgeSPED.SPED(const jSPED: TJSONObject): TJSONObject;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;
  Result.Add(RSStatusField, RSStatusSucesso);
  Result.Add(RSMessageField, 'ACBr SPED Fiscal inicializado com sucesso.');
end;

procedure TACBRBridgeSPED.PopularBlocosEFD(const jRoot: TJSONObject; out AOmit0100: Boolean);
var
  jB0, jR0001, jBK, jRK001: TJSONObject;
begin
  AOmit0100 := False;
  if not Assigned(jRoot) then
    Exit;

  jB0 := GetJsonObj(jRoot, 'Bloco_0');
  if Assigned(jB0) then
  begin
    jR0001 := GetJsonObj(jB0, 'Registro0001');
    if Assigned(jR0001) then
    begin
      if not HasNonNullKey(jR0001, 'Registro0005') and Assigned(facbr.Bloco_0.Registro0001.Registro0005) then
      begin
        facbr.Bloco_0.Registro0001.Registro0005.Free;
        facbr.Bloco_0.Registro0001.Registro0005 := nil;
      end;
      if not HasNonNullKey(jR0001, 'Registro0100') then
      begin
        AOmit0100 := True;
        if Assigned(facbr.Bloco_0.Registro0001.Registro0100) then
        begin
          facbr.Bloco_0.Registro0001.Registro0100.Free;
          facbr.Bloco_0.Registro0001.Registro0100 := nil;
        end;
      end;
    end;
  end;

  TJSONTools.JsonToObj(jRoot, facbr);

  if (facbr.DT_INI = 0) and (facbr.Bloco_0.Registro0000.DT_INI > 0) then
    facbr.DT_INI := facbr.Bloco_0.Registro0000.DT_INI;
  if (facbr.DT_FIN = 0) and (facbr.Bloco_0.Registro0000.DT_FIN > 0) then
    facbr.DT_FIN := facbr.Bloco_0.Registro0000.DT_FIN;

  if facbr.Bloco_0.Registro0001.IND_MOV <> ACBrEFDBlocos.imComDados then
    AOmit0100 := False;

  jBK := GetJsonObj(jRoot, 'Bloco_K');
  jRK001 := GetJsonObj(jBK, 'RegistroK001');
  if Assigned(jRK001) and
     (facbr.Bloco_K.RegistroK001.IND_MOV = ACBrEFDBlocos.imComDados) and
     (facbr.Bloco_0.Registro0000.COD_VER > ACBrEFDBlocos.vlVersao116) and
     not HasNonNullKey(jRK001, 'RegistroK010') and
     Assigned(facbr.Bloco_K.RegistroK001.RegistroK010) then
    facbr.Bloco_K.RegistroK001.RegistroK010.IND_TIPO_LEIAUTE := ACBrEFDBlocos.itlCompleto;
end;

function TACBRBridgeSPED.Gerar(const jSPED: TJSONObject): TJSONObject;
var
  fullFile, reqArq, tmpDir: string;
  tamanho, I: Integer;
  jRoot: TJSONObject;
  isTempFile, omit0100: Boolean;
  arrAvisos: TJSONArray;
begin
  Result := TJSONObject.Create;
  fullFile := '';
  isTempFile := False;
  omit0100 := False;
  try
    CarregaConfig(True);
    fErrosValidacao.Clear;

    jRoot := GetJsonObj(jSPED, 'sped');
    if not Assigned(jRoot) then
      jRoot := jSPED;

    reqArq := Trim(facbr.Arquivo);
    if (reqArq = '') and Assigned(jSPED) then
      reqArq := Trim(jSPED.Get('Arquivo', ''));
    if (reqArq = '') and Assigned(jRoot) and (jRoot <> jSPED) then
      reqArq := Trim(jRoot.Get('Arquivo', ''));

    isTempFile := (reqArq = '');
    if isTempFile then
    begin
      tmpDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim;
      ForceDirectories(tmpDir);
      facbr.Path := tmpDir;
      facbr.Arquivo := 'sped_fiscal_' + IntToStr(GetTickCount64) + '_' + IntToStr(Random(1000000)) + '.txt';
    end
    else
    begin
      if Trim(facbr.Path) = '' then
        facbr.Path := ExtractFilePath(ParamStr(0));
      facbr.Arquivo := reqArq;
    end;

    PopularBlocosEFD(jRoot, omit0100);
    if omit0100 then
    begin
      { TACBrSPEDFiscal.WriteRegistro0001 appends REG_BLC='0100' unconditionally to
        Bloco_9.Registro9900 even when Registro0100=nil. Remove it in-memory before
        SaveFileTXT writes Bloco_9 (IniciaGeracao/WriteBloco_0 guard against re-running). }
      facbr.IniciaGeracao;
      facbr.WriteBloco_0;
      for I := facbr.Bloco_9.Registro9900.Count - 1 downto 0 do
        if facbr.Bloco_9.Registro9900.Items[I].REG_BLC = '0100' then
          facbr.Bloco_9.Registro9900.Delete(I);
    end;
    facbr.SaveFileTXT;

    fullFile := IncludeTrailingPathDelimiter(facbr.Path) + facbr.Arquivo;
    ConvertFileUtf8ToCp1252(fullFile);

    Result.Add(RSStatusField, RSStatusSucesso);
    Result.Add(RSMessageField, 'SPED gerado com sucesso.');
    Result.Add('arquivo', fullFile);
    if FileExists(fullFile) then
    begin
      Result.Add('arquivo_base64', FileToStringBase64(fullFile, isTempFile, tamanho));
      Result.Add(RSTamanhoField, tamanho);
    end;
    arrAvisos := TJSONArray.Create;
    for I := 0 to fErrosValidacao.Count - 1 do
      arrAvisos.Add(fErrosValidacao[I]);
    Result.Add('avisos_acbr', arrAvisos);
  except
    on E: Exception do
    begin
      if isTempFile and (fullFile <> '') and FileExists(fullFile) then
        SysUtils.DeleteFile(fullFile);
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao gerar SPED: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeSPED.Importar(const jSPED: TJSONObject): TJSONObject;
var
  Imp: TACBrSpedFiscalImportar;
  b64, tmpFile, tmpDir: string;
begin
  Result := TJSONObject.Create;
  Imp := TACBrSpedFiscalImportar.Create(nil);
  b64 := '';
  tmpFile := '';
  try
    try
      CarregaConfig(True);
      TJSONTools.JsonToObj(jSPED, Imp);
      b64 := jSPED.Get('arquivo_base64', '');
      if b64 <> '' then
      begin
        tmpDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim;
        ForceDirectories(tmpDir);
        tmpFile := tmpDir + 'sped_efdimp_' + IntToStr(GetTickCount64) + '_' + IntToStr(Random(1000000)) + '.txt';
        WriteUtf8TempFile(tmpFile, EnsureUtf8FromBytes(DecodeStringBase64(b64)));
        Imp.Arquivo := tmpFile;
      end;

      if (Imp.Arquivo = '') or not FileExists(Imp.Arquivo) then
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Arquivo SPED Fiscal nao informado ou inexistente para importacao.');
        Exit;
      end;

      Imp.ACBrSpedFiscal := facbr;
      Imp.Importar;

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSMessageField, 'SPED Fiscal importado com sucesso.');
      Result.Add('sped', TJSONTools.SafeObjToJson(facbr, 'Erro ao serializar SPED Fiscal importado'));
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao importar SPED Fiscal: ' + E.Message);
      end;
    end;
  finally
    if (b64 <> '') and (tmpFile <> '') and FileExists(tmpFile) then
      SysUtils.DeleteFile(tmpFile);
    Imp.Free;
  end;
end;

{ TACBRModelosJSONSPEDPisCofins }

function TACBRModelosJSONSPEDPisCofins.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr);
end;

function TACBRModelosJSONSPEDPisCofins.ModelGerar: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr);
end;

function TACBRModelosJSONSPEDPisCofins.ModelImportar: TJSONObject;
var
  Imp: TACBrSpedPCImportar;
begin
  Imp := TACBrSpedPCImportar.Create(nil);
  try
    Result := TJSONTools.SafeObjToJson(Imp);
  finally
    Imp.Free;
  end;
end;

{ TACBRBridgeSPEDPisCofins }

procedure TACBRBridgeSPEDPisCofins.CarregaConfig(const AllowEmpty: Boolean);
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

constructor TACBRBridgeSPEDPisCofins.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrSPEDPisCofins.Create(nil);
  fErrosValidacao := TStringList.Create;
  facbr.OnError := DoAcbrError;
  fcfg := Cfg;
end;

procedure TACBRBridgeSPEDPisCofins.DoAcbrError(const MsnError: string);
begin
  if Assigned(fErrosValidacao) and (Trim(MsnError) <> '') then
    fErrosValidacao.Add(Trim(MsnError));
end;

destructor TACBRBridgeSPEDPisCofins.Destroy;
begin
  FreeAndNil(fErrosValidacao);
  FreeAndNil(facbr);
  inherited Destroy;
end;

procedure TACBRBridgeSPEDPisCofins.PopularBlocosEPC(const jRoot: TJSONObject; out AOmitBlocoP: Boolean);
var
  jB0, jR0001, jBM, jRM001, jBP, jRP001: TJSONObject;
begin
  AOmitBlocoP := True;
  if not Assigned(jRoot) then
    Exit;

  jB0 := GetJsonObj(jRoot, 'Bloco_0');
  jR0001 := GetJsonObj(jB0, 'Registro0001');
  if Assigned(jR0001) then
  begin
    if not HasNonNullKey(jR0001, 'Registro0110') and Assigned(facbr.Bloco_0.Registro0001.Registro0110) then
    begin
      facbr.Bloco_0.Registro0001.Registro0110.Free;
      facbr.Bloco_0.Registro0001.Registro0110 := nil;
    end;
    if HasNonNullKey(jR0001, 'Registro0900') and not Assigned(facbr.Bloco_0.Registro0001.Registro0900) then
      facbr.Bloco_0.Registro0900New;
  end;

  jBM := GetJsonObj(jRoot, 'Bloco_M');
  jRM001 := GetJsonObj(jBM, 'RegistroM001');
  if Assigned(jRM001) then
  begin
    if not HasNonNullKey(jRM001, 'RegistroM200') and Assigned(facbr.Bloco_M.RegistroM001.RegistroM200) then
    begin
      facbr.Bloco_M.RegistroM001.RegistroM200.Free;
      facbr.Bloco_M.RegistroM001.RegistroM200 := nil;
    end;
    if not HasNonNullKey(jRM001, 'RegistroM600') and Assigned(facbr.Bloco_M.RegistroM001.RegistroM600) then
    begin
      facbr.Bloco_M.RegistroM001.RegistroM600.Free;
      facbr.Bloco_M.RegistroM001.RegistroM600 := nil;
    end;
  end;

  jBP := GetJsonObj(jRoot, 'Bloco_P');
  jRP001 := GetJsonObj(jBP, 'RegistroP001');
  if Assigned(jRP001) then
    AOmitBlocoP := False;

  TJSONTools.JsonToObj(jRoot, facbr);

  if (facbr.DT_INI = 0) and (facbr.Bloco_0.Registro0000.DT_INI > 0) then
    facbr.DT_INI := facbr.Bloco_0.Registro0000.DT_INI;
  if (facbr.DT_FIN = 0) and (facbr.Bloco_0.Registro0000.DT_FIN > 0) then
    facbr.DT_FIN := facbr.Bloco_0.Registro0000.DT_FIN;
end;

function TACBRBridgeSPEDPisCofins.Gerar(const jSPED: TJSONObject): TJSONObject;
var
  fullFile, reqArq, tmpDir: string;
  tamanho, I: Integer;
  jRoot: TJSONObject;
  isTempFile, omitBlocoP: Boolean;
  arrAvisos: TJSONArray;
begin
  Result := TJSONObject.Create;
  fullFile := '';
  isTempFile := False;
  try
    CarregaConfig(True);
    fErrosValidacao.Clear;

    jRoot := GetJsonObj(jSPED, 'sped');
    if not Assigned(jRoot) then
      jRoot := jSPED;

    reqArq := Trim(facbr.Arquivo);
    if (reqArq = '') and Assigned(jSPED) then
      reqArq := Trim(jSPED.Get('Arquivo', ''));
    if (reqArq = '') and Assigned(jRoot) and (jRoot <> jSPED) then
      reqArq := Trim(jRoot.Get('Arquivo', ''));

    isTempFile := (reqArq = '');
    if isTempFile then
    begin
      tmpDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim;
      ForceDirectories(tmpDir);
      facbr.Path := tmpDir;
      facbr.Arquivo := 'sped_piscofins_' + IntToStr(GetTickCount64) + '_' + IntToStr(Random(1000000)) + '.txt';
    end
    else
    begin
      if Trim(facbr.Path) = '' then
        facbr.Path := ExtractFilePath(ParamStr(0));
      facbr.Arquivo := reqArq;
    end;

    PopularBlocosEPC(jRoot, omitBlocoP);
    if Assigned(jSPED) and jSPED.Get('omitirBlocoP', False) then
      omitBlocoP := True;
    if Assigned(jRoot) and jRoot.Get('omitirBlocoP', False) then
      omitBlocoP := True;

    if omitBlocoP then
    begin
      { IniciaGeracao resets Bloco_*.Gravado := False and sets FInicializado := True;
        SaveFileTXT's internal IniciaGeracao exits immediately when FInicializado = True.
        Execute native WriteBloco_0 / WriteBloco_I (when imComDados) / WriteBloco_M first
        so WriteBloco_M cascades Bloco_A..F (including imSemDados) before Bloco_P.Gravado := True. }
      facbr.IniciaGeracao;
      facbr.WriteBloco_0;
      if facbr.Bloco_I.RegistroI001.IND_MOV = ACBrEPCBlocos.imComDados then
        facbr.WriteBloco_I;
      facbr.WriteBloco_M;
      facbr.Bloco_P.Gravado := True;
    end;
    facbr.SaveFileTXT;

    fullFile := IncludeTrailingPathDelimiter(facbr.Path) + facbr.Arquivo;
    ConvertFileUtf8ToCp1252(fullFile);

    Result.Add(RSStatusField, RSStatusSucesso);
    Result.Add(RSMessageField, 'SPED Contribuicoes (PIS/COFINS) gerado com sucesso.');
    Result.Add('arquivo', fullFile);
    if FileExists(fullFile) then
    begin
      Result.Add('arquivo_base64', FileToStringBase64(fullFile, isTempFile, tamanho));
      Result.Add(RSTamanhoField, tamanho);
    end;
    arrAvisos := TJSONArray.Create;
    for I := 0 to fErrosValidacao.Count - 1 do
      arrAvisos.Add(fErrosValidacao[I]);
    Result.Add('avisos_acbr', arrAvisos);
  except
    on E: Exception do
    begin
      if isTempFile and (fullFile <> '') and FileExists(fullFile) then
        SysUtils.DeleteFile(fullFile);
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao gerar SPED Contribuicoes: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeSPEDPisCofins.Importar(const jSPED: TJSONObject): TJSONObject;
var
  Imp: TACBrSpedPCImportar;
  b64, tmpFile, outFile, tmpDir: string;
  regerar: Boolean;
  tamanho, I: Integer;
  arrAvisos: TJSONArray;
begin
  Result := TJSONObject.Create;
  Imp := TACBrSpedPCImportar.Create(nil);
  b64 := '';
  tmpFile := '';
  outFile := '';
  try
    try
      CarregaConfig(True);
      fErrosValidacao.Clear;

      TJSONTools.JsonToObj(jSPED, Imp);
      b64 := jSPED.Get('arquivo_base64', '');
      regerar := jSPED.Get('RegerarTXT', False);

      tmpDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim;
      ForceDirectories(tmpDir);

      if b64 <> '' then
      begin
        tmpFile := tmpDir + 'sped_epcimp_' + IntToStr(GetTickCount64) + '_' + IntToStr(Random(1000000)) + '.txt';
        WriteUtf8TempFile(tmpFile, EnsureUtf8FromBytes(DecodeStringBase64(b64)));
        Imp.Arquivo := tmpFile;
      end;

      if (Imp.Arquivo = '') or not FileExists(Imp.Arquivo) then
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Arquivo SPED Contribuicoes nao informado ou inexistente para importacao.');
        Exit;
      end;

      Imp.ACBrSpedPisCofins := facbr;
      Imp.Importar;

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSMessageField, 'SPED Contribuicoes importado com sucesso.');
      Result.Add('sped', TJSONTools.SafeObjToJson(facbr, 'Erro ao serializar SPED Contribuicoes importado'));

      if regerar then
      begin
        if facbr.Bloco_0.Registro0000.DT_INI > 0 then
          facbr.DT_INI := facbr.Bloco_0.Registro0000.DT_INI;
        if facbr.Bloco_0.Registro0000.DT_FIN > 0 then
          facbr.DT_FIN := facbr.Bloco_0.Registro0000.DT_FIN;

        if (facbr.DT_INI <= 0) or (facbr.DT_FIN <= 0) then
          raise Exception.Create('DT_INI e DT_FIN devem constar no Registro 0000 ou em config para regerar o TXT.');

        facbr.Path := tmpDir;
        facbr.Arquivo := 'sped_epcreg_' + IntToStr(GetTickCount64) + '_' + IntToStr(Random(1000000)) + '.txt';
        facbr.SaveFileTXT;

        outFile := IncludeTrailingPathDelimiter(facbr.Path) + facbr.Arquivo;
        ConvertFileUtf8ToCp1252(outFile);
        if FileExists(outFile) then
          Result.Add('arquivo_base64', FileToStringBase64(outFile, True, tamanho));
      end;

      arrAvisos := TJSONArray.Create;
      for I := 0 to fErrosValidacao.Count - 1 do
        arrAvisos.Add(fErrosValidacao[I]);
      Result.Add('avisos_acbr', arrAvisos);
    except
      on E: Exception do
      begin
        if (outFile <> '') and FileExists(outFile) then
          SysUtils.DeleteFile(outFile);
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao importar SPED Contribuicoes: ' + E.Message);
      end;
    end;
  finally
    if (b64 <> '') and (tmpFile <> '') and FileExists(tmpFile) then
      SysUtils.DeleteFile(tmpFile);
    Imp.Free;
  end;
end;

end.
