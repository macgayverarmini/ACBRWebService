unit method.acbr.sped;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrSpedFiscal,
  ACBrSpedPisCofins,
  pcnConversao,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  streamtools,
  ACBrEPCImportar,
  ACBrEFDImportar,
  ACBrEPCBlocos,
  DateUtils,
  ACBrEFDBlocos,
  ACBrEPCBloco_0,
  ACBrEPCBloco_M;

type
  TACBRBridgeSPED = class
  private
      fcfg: string;
    facbr: TACBrSpedFiscal;
    fErrosValidacao: TStringList;
    procedure CarregaConfig;
    procedure DoAcbrError(const MsnError: string);
    procedure PopularBlocosEFD(const jRoot: TJSONObject;
      out AOmit0100: Boolean);
  public
      constructor Create(const Cfg: string);
    destructor Destroy;
    override;
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
    procedure CarregaConfig;
    procedure DoAcbrError(const MsnError: string);
    procedure AjustarRegistrosImportados(const ASL: TStringList;
      const ASped: TACBrSPEDPisCofins);
    procedure NormalizarTxtRegerado(const AFileName: string);
    procedure PopularBlocosEPC(const jRoot: TJSONObject);
    procedure SomarRegistro0900(const AOrigem: ACBrEPCBloco_0.TRegistro0900;
      const ADestino: ACBrEPCBloco_0.TRegistro0900);
    procedure MesclarEstabelecimento0140(const ASrc: ACBrEPCBloco_0.TRegistro0140;
      const ADestino: TACBrSPEDPisCofins);
    procedure MesclarBlocoMConsolidado(const ALista: TList;
      const ADestino: TACBrSPEDPisCofins);
    procedure MesclarBloco1Consolidado(const ALista: TList;
      const ADestino: TACBrSPEDPisCofins);
  public
      constructor Create(const Cfg: string);
    destructor Destroy;
    override;
    function Gerar(const jSPED: TJSONObject): TJSONObject;
    function Importar(const jSPED: TJSONObject): TJSONObject;
    function Consolidar(const jConsolidar: TJSONObject): TJSONObject;
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
  else
    if CP <= $7FF then
  begin
    SetLength(Result, 2);
    Result[1] := AnsiChar($C0 or ((CP shr 6) and$1F));
    Result[2] := AnsiChar($80 or (CP and$3F));
  end
  else
  begin
    SetLength(Result, 3);
    Result[1] := AnsiChar($E0 or ((CP shr 12) and$0F));
    Result[2] := AnsiChar($80 or ((CP shr 6) and$3F));
    Result[3] := AnsiChar($80 or (CP and$3F));
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
    else
        if (B and$E0) = $C0 then
    begin
      if (B<$C2) or (I + 1 > Len) then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      if (B2 and$C0) <> $80 then
        Exit(False);
      Inc(I, 2);
    end
    else
      if (B and$F0) = $E0 then
    begin
      if I + 2 > Len then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      if ((B2 and$C0) <> $80) or ((B3 and$C0) <> $80) then
        Exit(False);
      if (B = $E0) and (B2<$A0) then
        Exit(False);
      Inc(I, 3);
    end
    else
      if (B and$F8) = $F0 then
    begin
      if I + 3 > Len then
        Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      B4 := Byte(ARaw[I + 3]);
      if ((B2 and$C0) <> $80) or ((B3 and$C0) <> $80) or ((B4 and$C0) <> $80) then
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

procedure WriteUtf8TempFile(const AFileName: string;
const AUtf8: UTF8String);
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

  while I<InLen do
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
    else
      if B = 10 then
    begin
      AppendByte(13);
      AppendByte(10);
      Inc(I);
    end
    else
      if B <= $7F then
    begin
      AppendByte(B);
      Inc(I);
    end
    else
      if ((B and$E0) = $C0) and (B >= $C2) and (I + 1 < InLen) and ((InBytes[I + 1] and$C0) = $80) then
    begin
      B2 := InBytes[I + 1];
      CP := ((Cardinal(B and$1F) shl 6) or Cardinal(B2 and$3F));
      AppendByte(UnicodeToCp1252Byte(CP));
      Inc(I, 2);
    end
    else
      if ((B and$F0) = $E0) and (I + 2 < InLen) and ((InBytes[I + 1] and$C0) = $80) and ((InBytes[I + 2] and$C0) = $80) then
    begin
      B2 := InBytes[I + 1];
      B3 := InBytes[I + 2];
      CP := (Cardinal(B and$0F) shl 12) or (Cardinal(B2 and$3F) shl 6) or Cardinal(B3 and$3F);
      AppendByte(UnicodeToCp1252Byte(CP));
      Inc(I, 3);
    end
    else
      if ((B and$F8) = $F0) and (I + 3 < InLen) and ((InBytes[I + 1] and$C0) = $80) and ((InBytes[I + 2] and$C0) = $80) and ((InBytes[I + 3] and$C0) = $80) then
    begin
      B2 := InBytes[I + 1];
      B3 := InBytes[I + 2];
      B4 := InBytes[I + 3];
      CP := (Cardinal(B and$07) shl 18) or (Cardinal(B2 and$3F) shl 12) or (Cardinal(B3 and$3F) shl 6) or Cardinal(B4 and$3F);
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

function GetJsonObj(const AParent: TJSONObject;
const AKey: string): TJSONObject;
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

function HasNonNullKey(const AParent: TJSONObject;
const AKey: string): Boolean;
var
  D: TJSONData;
begin
  Result := False;
  if not Assigned(AParent) then
    Exit;
  D := AParent.Find(AKey);
  Result := Assigned(D) and not D.IsNull;
end;

function TryParseSpedDateStr(const AStr: string;
  out ADate: TDateTime): Boolean;
var
  S: string;
  Y, M, D: Integer;
  HasTZ: Boolean;
begin
  Result := False;
  ADate := 0;
  S := Trim(AStr);
  if S = '' then
    Exit;
  if (Length(S) = 8) and TryStrToInt(Copy(S, 1, 2), D) and TryStrToInt(Copy(S, 3, 2), M) and TryStrToInt(Copy(S, 5, 4), Y) then
    Exit(TryEncodeDate(Y, M, D, ADate));
  HasTZ := (Length(S) > 10) and ((Pos('+', Copy(S, 11, MaxInt)) > 0) or (Pos('-', Copy(S, 11, MaxInt)) > 0));
  if TryISO8601ToDate(S, ADate, not HasTZ) then
    Exit(True);
  ADate := StrToDateTimeDef(S, 0);
  Result := ADate > 0;
end;

function TryExtractSpedDate(const ARoot: TJSONObject;
const AProp: string;
  out ADate: TDateTime): Boolean;
var
  D: TJSONData;
  JB0, JR0: TJSONObject;
begin
  Result := False;
  ADate := 0;
  if not Assigned(ARoot) then
    Exit;
  D := ARoot.Find(AProp);
  if Assigned(D) and not D.IsNull then
  begin
    if D is TJSONNumber then
    begin
      ADate := D.AsFloat;
      Exit(ADate > 0);
    end;
    if TryParseSpedDateStr(D.AsString, ADate) then
      Exit(True);
  end;
  JB0 := GetJsonObj(ARoot, 'Bloco_0');
  if Assigned(JB0) then
  begin
    D := JB0.Find(AProp);
    if Assigned(D) and not D.IsNull and TryParseSpedDateStr(D.AsString, ADate) then
      Exit(True);
    JR0 := GetJsonObj(JB0, 'Registro0000');
    if Assigned(JR0) then
    begin
      D := JR0.Find(AProp);
      if Assigned(D) and not D.IsNull and TryParseSpedDateStr(D.AsString, ADate) then
        Exit(True);
    end;
  end;
end;

procedure RemoveOrphanEfd0100Counter(const AFileName: string);
var
  SL: TStringList;
  I, N: Integer;
  Removed: Boolean;
  Line, Inner: string;
begin
  if (AFileName = '') or not FileExists(AFileName) then
    Exit;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    Removed := False;
    for I := SL.Count - 1 downto 0 do
    begin
      if SL[I] = '|9900|0100|1|' then
      begin
        SL.Delete(I);
        Removed := True;
        Break;
      end;
    end;
    if Removed then
    begin
      for I := 0 to SL.Count - 1 do
      begin
        Line := SL[I];
        if Pos('|9900|9900|', Line) = 1 then
        begin
          Inner := Copy(Line, 12, Length(Line)-12);
          if TryStrToInt(Inner, N) and (N > 1) then
            SL[I] := '|9900|9900|' + IntToStr(N - 1)+'|';
        end
        else
          if Pos('|9990|', Line) = 1 then
        begin
          Inner := Copy(Line, 7, Length(Line)-7);
          if TryStrToInt(Inner, N) and (N > 1) then
            SL[I] := '|9990|' + IntToStr(N - 1)+'|';
        end
        else
          if Pos('|9999|', Line) = 1 then
        begin
          Inner := Copy(Line, 7, Length(Line)-7);
          if TryStrToInt(Inner, N) and (N > 1) then
            SL[I] := '|9999|' + IntToStr(N - 1)+'|';
        end;
      end;
      SL.SaveToFile(AFileName);
    end;
  finally
    SL.Free;
  end;
end;
{ TACBRModelosJSONSPED }

function TACBRModelosJSONSPED.ModelConfig: TJSONObject;
begin
  // SPED nÃ£o tem as mesmas ConfiguraÃ§Ãµes DFe, entÃ£o devolvemos algo simples
  Result := TJSONObject.Create;
  Result.Add('Path', facbr.Path);
  Result.Add('Arquivo', facbr.Arquivo);
end;

{ TACBRBridgeSPED }

procedure TACBRBridgeSPED.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then
    exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr); // Popula as properties do componente em si
  finally
    O.Free;
  end;
  fcfg := '';
end;

constructor TACBRBridgeSPED.Create(const Cfg: string);
begin
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

function TACBRBridgeSPED.SPED(const jSPED: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Result.Add('status', 'sucesso');
  Result.Add('message', 'ACBr SPED Fiscal inicializado com sucesso.');
end;

function TACBRBridgeSPED.Gerar(const jSPED: TJSONObject): TJSONObject;
var
  fullFile, reqArq: string;
  tamanho, I: Integer;
  jRoot: TJSONObject;
  dtIni, dtFin: TDateTime;
  isTempFile, omit0100: Boolean;
  arrAvisos: TJSONArray;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  fullFile := '';
  isTempFile := False;
  omit0100 := False;
  try
    fErrosValidacao.Clear;
    jRoot := GetJsonObj(jSPED, 'sped');
    if not Assigned(jRoot) then
      jRoot := jSPED;

    if facbr.Path = '' then
      facbr.Path := ExtractFilePath(ParamStr(0));

    reqArq := '';
    if Assigned(jSPED) then
      reqArq := jSPED.Get('Arquivo', jSPED.Get('arquivo', ''));
    if (reqArq = '') and Assigned(jRoot) and (jRoot <> jSPED) then
      reqArq := jRoot.Get('Arquivo', jRoot.Get('arquivo', ''));

    isTempFile := (reqArq = '');
    if isTempFile then
      facbr.Arquivo := 'sped_fiscal_' + IntToStr(GetTickCount64)+'_' + IntToStr(Random(1000000))+'.txt'
    else
        facbr.Arquivo := reqArq;

    if TryExtractSpedDate(jRoot, 'DT_INI', dtIni) then
      facbr.DT_INI := dtIni;
    if TryExtractSpedDate(jRoot, 'DT_FIN', dtFin) then
      facbr.DT_FIN := dtFin;

    PopularBlocosEFD(jRoot, omit0100);
    facbr.SaveFileTXT;

    fullFile := IncludeTrailingPathDelimiter(facbr.Path)+facbr.Arquivo;
    if omit0100 then
      RemoveOrphanEfd0100Counter(fullFile);
    ConvertFileUtf8ToCp1252(fullFile);

    Result.Add('status', 'sucesso');
    Result.Add('message', 'SPED gerado com sucesso.');
    Result.Add('arquivo', fullFile);
    if FileExists(fullFile) then
    begin
      Result.Add('arquivo_base64', FileToStringBase64(fullFile, isTempFile, tamanho));
      Result.Add('tamanho', tamanho);
    end;
    arrAvisos := TJSONArray.Create;
    for I := 0 to fErrosValidacao.Count - 1 do
      arrAvisos.Add(fErrosValidacao[I]);
    Result.Add('avisos_acbr', arrAvisos);
  except
    on E: Exception do
    begin
      if isTempFile and (fullFile <> '') and FileExists(fullFile) then
        DeleteFile(fullFile);
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro ao gerar SPED: ' + E.Message);
    end;
  end;
end;

{ TACBRModelosJSONSPEDPisCofins }

function TACBRModelosJSONSPEDPisCofins.ModelConfig: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Path', facbr.Path);
  Result.Add('Arquivo', facbr.Arquivo);
  Result.Add('DT_INI', FormatDateTime('yyyy-mm-dd', Date));
  Result.Add('DT_FIN', FormatDateTime('yyyy-mm-dd', Date));
end;

function TACBRModelosJSONSPEDPisCofins.ModelImportar: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('arquivo_base64', 'CONTEUDO_TXT_SPED_PIS_COFINS_EM_BASE64');
  Result.Add('RegerarTXT', False);
end;

{ TACBRBridgeSPEDPisCofins }

procedure TACBRBridgeSPEDPisCofins.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then
    Exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr);
  finally
    O.Free;
  end;
  fcfg := '';
end;

constructor TACBRBridgeSPEDPisCofins.Create(const Cfg: string);
begin
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

function TACBRBridgeSPEDPisCofins.Gerar(const jSPED: TJSONObject): TJSONObject;
var
  fullFile, reqArq: string;
  tamanho, I: Integer;
  jRoot: TJSONObject;
  dtIni, dtFin: TDateTime;
  isTempFile: Boolean;
  arrAvisos: TJSONArray;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  fullFile := '';
  isTempFile := False;
  try
    fErrosValidacao.Clear;
    jRoot := GetJsonObj(jSPED, 'sped');
    if not Assigned(jRoot) then
      jRoot := jSPED;

    if facbr.Path = '' then
      facbr.Path := ExtractFilePath(ParamStr(0));

    reqArq := '';
    if Assigned(jSPED) then
      reqArq := jSPED.Get('Arquivo', jSPED.Get('arquivo', ''));
    if (reqArq = '') and Assigned(jRoot) and (jRoot <> jSPED) then
      reqArq := jRoot.Get('Arquivo', jRoot.Get('arquivo', ''));

    isTempFile := (reqArq = '');
    if isTempFile then
      facbr.Arquivo := 'sped_piscofins_' + IntToStr(GetTickCount64)+'_' + IntToStr(Random(1000000))+'.txt'
    else
        facbr.Arquivo := reqArq;

    if TryExtractSpedDate(jRoot, 'DT_INI', dtIni) then
      facbr.DT_INI := dtIni;
    if TryExtractSpedDate(jRoot, 'DT_FIN', dtFin) then
      facbr.DT_FIN := dtFin;

    PopularBlocosEPC(jRoot);
    facbr.SaveFileTXT;

    fullFile := IncludeTrailingPathDelimiter(facbr.Path)+facbr.Arquivo;
    NormalizarTxtRegerado(fullFile);
    ConvertFileUtf8ToCp1252(fullFile);

    Result.Add('status', 'sucesso');
    Result.Add('message', 'SPED Contribuicoes (PIS/COFINS) gerado com sucesso.');
    Result.Add('arquivo', fullFile);
    if FileExists(fullFile) then
    begin
      Result.Add('arquivo_base64', FileToStringBase64(fullFile, isTempFile, tamanho));
      Result.Add('tamanho', tamanho);
    end;
    arrAvisos := TJSONArray.Create;
    for I := 0 to fErrosValidacao.Count - 1 do
      arrAvisos.Add(fErrosValidacao[I]);
    Result.Add('avisos_acbr', arrAvisos);
  except
    on E: Exception do
    begin
      if isTempFile and (fullFile <> '') and FileExists(fullFile) then
        DeleteFile(fullFile);
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro ao gerar SPED Contribuicoes: ' + E.Message);
    end;
  end;
end;


procedure CopySpedObjProperties(const Origem, Destino: TObject);
var
  J: TJSONObject;
begin
  if not Assigned(Origem) or not Assigned(Destino) then
    Exit;
  J := TJSONTools.SafeObjToJson(Origem);
  try
    if Assigned(J) then
      TJSONTools.JsonToObj(J, Destino);
  finally
    J.Free;
  end;
end;

function TACBRBridgeSPED.Importar(const jSPED: TJSONObject): TJSONObject;
var
  Imp: TACBrSpedFiscalImportar;
  b64, tmpFile: string;
  SL: TStringList;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Imp := TACBrSpedFiscalImportar.Create(nil);
  SL := TStringList.Create;
  try
    try
      b64 := jSPED.Get('arquivo_base64', jSPED.Get('ArquivoData', ''));
      tmpFile := jSPED.Get('Arquivo', jSPED.Get('arquivo', ''));
      if b64 <> '' then
      begin
        tmpFile := ExtractFilePath(ParamStr(0))+'sped_efdimp_' + IntToStr(GetTickCount64)+'.txt';
        WriteUtf8TempFile(tmpFile, EnsureUtf8FromBytes(DecodeStringBase64(b64)));
        SL.LoadFromFile(tmpFile);
      end;

      if (tmpFile = '') or not FileExists(tmpFile) then
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Arquivo SPED Fiscal nao informado ou inexistente para importacao.');
        Exit;
      end;

      Imp.ACBrSpedFiscal := facbr;
      Imp.Arquivo := tmpFile;
      Imp.Importar;

      if (b64 <> '') and FileExists(tmpFile) then
        DeleteFile(tmpFile);

      Result.Add('status', 'sucesso');
      Result.Add('message', 'SPED Fiscal importado com sucesso.');
      Result.Add('sped', TJSONTools.SafeObjToJson(facbr, 'Erro ao serializar SPED Fiscal importado'));
    except
      on E: Exception do
      begin
        if (b64 <> '') and (tmpFile <> '') and FileExists(tmpFile) then
          DeleteFile(tmpFile);
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao importar SPED Fiscal: ' + E.Message);
      end;
    end;
  finally
    SL.Free;
    Imp.Free;
  end;
end;

function TACBRBridgeSPEDPisCofins.Importar(const jSPED: TJSONObject): TJSONObject;
var
  Imp: TACBrSpedPCImportar;
  b64, tmpFile, outFile: string;
  SL: TStringList;
  regerar: Boolean;
  tamanho, I: Integer;
  arrAvisos: TJSONArray;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Imp := TACBrSpedPCImportar.Create(nil);
  SL := TStringList.Create;
  try
    try
      fErrosValidacao.Clear;
      b64 := jSPED.Get('arquivo_base64', jSPED.Get('ArquivoData', ''));
      tmpFile := jSPED.Get('Arquivo', jSPED.Get('arquivo', ''));
      regerar := jSPED.Get('RegerarTXT', jSPED.Get('regerar_txt', False));
      if b64 <> '' then
      begin
        tmpFile := ExtractFilePath(ParamStr(0))+'sped_epcimp_' + IntToStr(GetTickCount64)+'.txt';
        WriteUtf8TempFile(tmpFile, EnsureUtf8FromBytes(DecodeStringBase64(b64)));
        SL.LoadFromFile(tmpFile);
      end;

      if (tmpFile = '') or not FileExists(tmpFile) then
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Arquivo SPED Contribuicoes nao informado ou inexistente para importacao.');
        Exit;
      end;

      Imp.ACBrSpedPisCofins := facbr;
      Imp.Arquivo := tmpFile;
      Imp.Importar;
      AjustarRegistrosImportados(SL, facbr);

      if (b64 <> '') and FileExists(tmpFile) then
        DeleteFile(tmpFile);

      Result.Add('status', 'sucesso');
      Result.Add('message', 'SPED Contribuicoes importado com sucesso.');
      Result.Add('sped', TJSONTools.SafeObjToJson(facbr, 'Erro ao serializar SPED Contribuicoes importado'));

      if regerar then
      begin
        if facbr.Bloco_0.Registro0000.DT_INI > 0 then
          facbr.DT_INI := facbr.Bloco_0.Registro0000.DT_INI
        else
            if facbr.DT_INI = 0 then
            facbr.DT_INI := EncodeDate(2026, 8, 1);

        if facbr.Bloco_0.Registro0000.DT_FIN > 0 then
          facbr.DT_FIN := facbr.Bloco_0.Registro0000.DT_FIN
        else
            if facbr.DT_FIN = 0 then
            facbr.DT_FIN := EncodeDate(2026, 8, 31);

        facbr.Path := ExtractFilePath(ParamStr(0));
        facbr.Arquivo := 'sped_epcreg_' + IntToStr(GetTickCount64)+'.txt';
        facbr.SaveFileTXT;

        outFile := IncludeTrailingPathDelimiter(facbr.Path)+facbr.Arquivo;
        NormalizarTxtRegerado(outFile);
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
        if (b64 <> '') and (tmpFile <> '') and FileExists(tmpFile) then
          DeleteFile(tmpFile);
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao importar SPED Contribuicoes: ' + E.Message);
      end;
    end;
  finally
    SL.Free;
    Imp.Free;
  end;
end;

function TACBRBridgeSPEDPisCofins.Consolidar(const jConsolidar: TJSONObject): TJSONObject;
var
  arrData: TJSONData;
  arr: TJSONArray;
  itemObj: TJSONObject;
  Imp: TACBrSpedPCImportar;
  Lista: TList;
  ItemSped, Principal, Destino: TACBrSPEDPisCofins;
  SL: TStringList;
  I, Y, Z, tamanho: Integer;
  b64, tmpFile, outFile: string;
  Found0500: Boolean;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  arrData := jConsolidar.Find('arquivos');
  if not Assigned(arrData) then
    arrData := jConsolidar.Find('Arquivos');
  if not Assigned(arrData) then
    arrData := jConsolidar.Find('arquivos_base64');

  if not Assigned(arrData) or (arrData.JSONType <> jtArray) or (TJSONArray(arrData).Count = 0) then
  begin
    Result.Add('status', 'erro');
    Result.Add('message', 'Informe o array "arquivos" com os SPEDs das filiais para consolidar.');
    Exit;
  end;

  arr := TJSONArray(arrData);
  Imp := TACBrSpedPCImportar.Create(nil);
  Lista := TList.Create;
  SL := TStringList.Create;
  Destino := TACBrSPEDPisCofins.Create(nil);
  Principal := nil;
  try
    try
      for I := 0 to arr.Count - 1 do
      begin
        b64 := '';
        if arr.Items[I].JSONType = jtObject then
        begin
          itemObj := TJSONObject(arr.Items[I]);
          b64 := itemObj.Get('arquivo_base64', itemObj.Get('ArquivoData', ''));
        end
        else
          if arr.Items[I].JSONType = jtString then
        begin
          itemObj := nil;
          b64 := arr.Items[I].AsString;
        end;

        if b64 <> '' then
        begin
          tmpFile := ExtractFilePath(ParamStr(0))+'sped_cons_' + IntToStr(GetTickCount64)+'_' + IntToStr(I)+'.txt';
          WriteUtf8TempFile(tmpFile, EnsureUtf8FromBytes(DecodeStringBase64(b64)));
          SL.LoadFromFile(tmpFile);
          try
            ItemSped := TACBrSPEDPisCofins.Create(nil);
            Lista.Add(ItemSped);
            Imp.ACBrSpedPisCofins := ItemSped;
            Imp.Arquivo := tmpFile;
            Imp.Importar;
            AjustarRegistrosImportados(SL, ItemSped);
            if (Assigned(itemObj) and itemObj.Get('principal', itemObj.Get('Principal', False))) or not Assigned(Principal) then
              Principal := ItemSped;
          finally
            if FileExists(tmpFile) then
              DeleteFile(tmpFile);
          end;
        end;
      end;

      if not Assigned(Principal) or (Lista.Count = 0) then
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Nenhum arquivo SPED Contribuicoes valido foi importado para consolidacao.');
        Exit;
      end;

      // Bloco 0 do Principal (0000, 0001, 0100, 0110, 0120)
      CopySpedObjProperties(Principal.Bloco_0.Registro0000, Destino.Bloco_0.Registro0000New);
      Destino.Bloco_0.Registro0001.IND_MOV := Principal.Bloco_0.Registro0001.IND_MOV;
      for Y := 0 to Principal.Bloco_0.Registro0001.Registro0100.Count - 1 do
        CopySpedObjProperties(
          Principal.Bloco_0.Registro0001.Registro0100.Items[Y],
          Destino.Bloco_0.Registro0001.Registro0100.New
          );
      CopySpedObjProperties(Principal.Bloco_0.Registro0001.Registro0110, Destino.Bloco_0.Registro0001.Registro0110);
      for Y := 0 to Principal.Bloco_0.Registro0001.Registro0120.Count - 1 do
        CopySpedObjProperties(
          Principal.Bloco_0.Registro0001.Registro0120.Items[Y],
          Destino.Bloco_0.Registro0001.Registro0120.New
          );

      // Mescla 0140, 0500, 0900 e Blocos A, C, D, F, P de todas as filiais
      for I := 0 to Lista.Count - 1 do
      begin
        ItemSped := TACBrSPEDPisCofins(Lista[I]);
        for Y := 0 to ItemSped.Bloco_0.Registro0001.Registro0140.Count - 1 do
          MesclarEstabelecimento0140(ItemSped.Bloco_0.Registro0001.Registro0140.Items[Y], Destino);

        for Y := 0 to ItemSped.Bloco_0.Registro0001.Registro0500.Count - 1 do
        begin
          Found0500 := False;
          for Z := 0 to Destino.Bloco_0.Registro0001.Registro0500.Count - 1 do
            if SameText(Destino.Bloco_0.Registro0001.Registro0500.Items[Z].COD_CTA,
              ItemSped.Bloco_0.Registro0001.Registro0500.Items[Y].COD_CTA) then
          begin
            Found0500 := True;
            Break;
          end;
          if not Found0500 then
            CopySpedObjProperties(
              ItemSped.Bloco_0.Registro0001.Registro0500.Items[Y],
              Destino.Bloco_0.Registro0001.Registro0500.New
              );
        end;

        if Assigned(ItemSped.Bloco_0.Registro0001.Registro0900) then
        begin
          if not Assigned(Destino.Bloco_0.Registro0001.Registro0900) then
            Destino.Bloco_0.Registro0900New;
          SomarRegistro0900(ItemSped.Bloco_0.Registro0001.Registro0900, Destino.Bloco_0.Registro0001.Registro0900);
        end;

        if ItemSped.Bloco_A.RegistroA001.IND_MOV = ACBrEPCBlocos.imComDados then
        begin
          Destino.Bloco_A.RegistroA001.IND_MOV := ACBrEPCBlocos.imComDados;
          for Y := 0 to ItemSped.Bloco_A.RegistroA001.RegistroA010.Count - 1 do
            CopySpedObjProperties(
              ItemSped.Bloco_A.RegistroA001.RegistroA010.Items[Y],
              Destino.Bloco_A.RegistroA001.RegistroA010.New
              );
        end;

        if ItemSped.Bloco_C.RegistroC001.IND_MOV = ACBrEPCBlocos.imComDados then
        begin
          Destino.Bloco_C.RegistroC001.IND_MOV := ACBrEPCBlocos.imComDados;
          for Y := 0 to ItemSped.Bloco_C.RegistroC001.RegistroC010.Count - 1 do
            CopySpedObjProperties(
              ItemSped.Bloco_C.RegistroC001.RegistroC010.Items[Y],
              Destino.Bloco_C.RegistroC001.RegistroC010.New
              );
        end;

        if ItemSped.Bloco_D.RegistroD001.IND_MOV = ACBrEPCBlocos.imComDados then
        begin
          Destino.Bloco_D.RegistroD001.IND_MOV := ACBrEPCBlocos.imComDados;
          for Y := 0 to ItemSped.Bloco_D.RegistroD001.RegistroD010.Count - 1 do
            CopySpedObjProperties(
              ItemSped.Bloco_D.RegistroD001.RegistroD010.Items[Y],
              Destino.Bloco_D.RegistroD001.RegistroD010.New
              );
        end;

        if ItemSped.Bloco_F.RegistroF001.IND_MOV = ACBrEPCBlocos.imComDados then
        begin
          Destino.Bloco_F.RegistroF001.IND_MOV := ACBrEPCBlocos.imComDados;
          for Y := 0 to ItemSped.Bloco_F.RegistroF001.RegistroF010.Count - 1 do
            CopySpedObjProperties(
              ItemSped.Bloco_F.RegistroF001.RegistroF010.Items[Y],
              Destino.Bloco_F.RegistroF001.RegistroF010.New
              );
        end;

        if ItemSped.Bloco_P.RegistroP001.IND_MOV = ACBrEPCBlocos.imComDados then
        begin
          Destino.Bloco_P.RegistroP001.IND_MOV := ACBrEPCBlocos.imComDados;
          for Y := 0 to ItemSped.Bloco_P.RegistroP001.RegistroP010.Count - 1 do
            CopySpedObjProperties(
              ItemSped.Bloco_P.RegistroP001.RegistroP010.Items[Y],
              Destino.Bloco_P.RegistroP001.RegistroP010.New
              );
        end;
      end;

      MesclarBlocoMConsolidado(Lista, Destino);
      MesclarBloco1Consolidado(Lista, Destino);

      Destino.DT_INI := Destino.Bloco_0.Registro0000.DT_INI;
      Destino.DT_FIN := Destino.Bloco_0.Registro0000.DT_FIN;
      Destino.Path := ExtractFilePath(ParamStr(0));
      Destino.Arquivo := 'sped_piscofins_consolidado_' + IntToStr(GetTickCount64)+'.txt';
      Destino.SaveFileTXT;

      outFile := IncludeTrailingPathDelimiter(Destino.Path)+Destino.Arquivo;
      NormalizarTxtRegerado(outFile);
      ConvertFileUtf8ToCp1252(outFile);
      Result.Add('status', 'sucesso');
      Result.Add('message', 'SPED Contribuicoes consolidado com sucesso.');
      Result.Add('total_arquivos', Lista.Count);
      if FileExists(outFile) then
        Result.Add('arquivo_base64', FileToStringBase64(outFile, True, tamanho));
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao consolidar SPED Contribuicoes: ' + E.Message);
      end;
    end;
  finally
    for I := 0 to Lista.Count - 1 do
      TObject(Lista[I]).Free;
    Lista.Free;
    Destino.Free;
    SL.Free;
    Imp.Free;
  end;
end;

procedure TACBRBridgeSPEDPisCofins.AjustarRegistrosImportados(const ASL: TStringList;
const ASped: TACBrSPEDPisCofins);
var
  Fields: TStringList;
  I: Integer;
  HasM200, HasM600: Boolean;
  R0900: ACBrEPCBloco_0.TRegistro0900;

function Parse0900Var(const idx: Integer): Variant;
var
  S: string;
  FVal: Double;
  VCode: Integer;
begin
  if idx >= Fields.Count then
    Exit(Null);
  S := Trim(Fields[idx]);
  if S = '' then
    Exit(Null);
  System.Val(StringReplace(S, ',', '.', [rfReplaceAll]), FVal, VCode);
  if VCode = 0 then
    Result := FVal
  else
      Result := Null;
end;
begin
  if not Assigned(ASL) or not Assigned(ASped) or (ASL.Count = 0) then
    Exit;
  Fields := TStringList.Create;
  try
    Fields.StrictDelimiter := True;
    Fields.Delimiter := '|';
    Fields.DelimitedText := ASL[0];
    if (Fields.Count > 4) and (Fields[1] = '0000') then
    begin
      if Trim(Fields[4]) = '' then
        ASped.Bloco_0.Registro0000.IND_SIT_ESP := ACBrEPCBlocos.indNenhum;
      if (Fields.Count > 13) and (Trim(Fields[13]) = '') then
        ASped.Bloco_0.Registro0000.IND_NAT_PJ := ACBrEPCBlocos.indNatPJNenhum;
    end;

    HasM200 := False;
    HasM600 := False;
    for I := 0 to ASL.Count - 1 do
    begin
      if Pos('|0900|', ASL[I]) = 1 then
      begin
        Fields.DelimitedText := ASL[I];
        R0900 := ASped.Bloco_0.Registro0900New;
        R0900.REC_TOTAL_BLOCO_A := Parse0900Var(2);
        R0900.REC_NRB_BLOCO_A := Parse0900Var(3);
        R0900.REC_TOTAL_BLOCO_C := Parse0900Var(4);
        R0900.REC_NRB_BLOCO_C := Parse0900Var(5);
        R0900.REC_TOTAL_BLOCO_D := Parse0900Var(6);
        R0900.REC_NRB_BLOCO_D := Parse0900Var(7);
        R0900.REC_TOTAL_BLOCO_F := Parse0900Var(8);
        R0900.REC_NRB_BLOCO_F := Parse0900Var(9);
        R0900.REC_TOTAL_BLOCO_I := Parse0900Var(10);
        R0900.REC_NRB_BLOCO_I := Parse0900Var(11);
        R0900.REC_TOTAL_BLOCO_1 := Parse0900Var(12);
        R0900.REC_NRB_BLOCO_1 := Parse0900Var(13);
        R0900.REC_TOTAL_PERIODO := Parse0900Var(14);
        R0900.REC_TOTAL_NRB_PERIODO := Parse0900Var(15);
      end
      else
        if Pos('|M200|', ASL[I]) = 1 then
          HasM200 := True
      else
          if Pos('|M600|', ASL[I]) = 1 then
          HasM600 := True;
    end;

    if ASped.Bloco_M.RegistroM001.IND_MOV = ACBrEPCBlocos.imComDados then
    begin
      if not HasM200 and Assigned(ASped.Bloco_M.RegistroM001.RegistroM200) then
      begin
        ASped.Bloco_M.RegistroM001.RegistroM200.Free;
        ASped.Bloco_M.RegistroM001.RegistroM200 := nil;
      end;
      if not HasM600 and Assigned(ASped.Bloco_M.RegistroM001.RegistroM600) then
      begin
        ASped.Bloco_M.RegistroM001.RegistroM600.Free;
        ASped.Bloco_M.RegistroM001.RegistroM600 := nil;
      end;
    end;
  finally
    Fields.Free;
  end;
end;

procedure TACBRBridgeSPEDPisCofins.NormalizarTxtRegerado(const AFileName: string);
var
  Lines, Fields: TStringList;
  I, CommaPos: Integer;
  Modified, LineModified: Boolean;
begin
  if (AFileName = '') or not FileExists(AFileName) then
    Exit;
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);
    Fields.StrictDelimiter := True;
    Fields.Delimiter := '|';
    Modified := False;
    for I := 0 to Lines.Count - 1 do
    begin
      if Pos('|C175|', Lines[I]) = 1 then
      begin
        LineModified := False;
        Fields.DelimitedText := Lines[I];
        if Fields.Count > 13 then
        begin
          CommaPos := Pos(',', Fields[7]);
          if (CommaPos > 0) and (Length(Fields[7])-CommaPos = 2) then
          begin
            Fields[7] := Fields[7]+'00';
            LineModified := True;
          end;
          CommaPos := Pos(',', Fields[13]);
          if (CommaPos > 0) and (Length(Fields[13])-CommaPos = 2) then
          begin
            Fields[13] := Fields[13]+'00';
            LineModified := True;
          end;
          if LineModified then
          begin
            Lines[I] := Fields.DelimitedText;
            Modified := True;
          end;
        end;
      end;
    end;
    if Modified then
      Lines.SaveToFile(AFileName);
  finally
    Fields.Free;
    Lines.Free;
  end;
end;

procedure TACBRBridgeSPED.DoAcbrError(const MsnError: string);
begin
  if Assigned(fErrosValidacao) and (Trim(MsnError) <> '') then
    fErrosValidacao.Add(Trim(MsnError));
end;


procedure TACBRBridgeSPED.PopularBlocosEFD(const jRoot: TJSONObject;
  out AOmit0100: Boolean);
var
  jB, jR: TJSONObject;
begin
  AOmit0100 := False;
  if not Assigned(jRoot) then
    Exit;

  jB := GetJsonObj(jRoot, 'Bloco_0');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'Registro0000');
    if Assigned(jR) then
    begin
      TJSONTools.JsonToObj(jR, facbr.Bloco_0.Registro0000);
      if (facbr.DT_INI = 0) and (facbr.Bloco_0.Registro0000.DT_INI > 0) then
        facbr.DT_INI := facbr.Bloco_0.Registro0000.DT_INI;
      if (facbr.DT_FIN = 0) and (facbr.Bloco_0.Registro0000.DT_FIN > 0) then
        facbr.DT_FIN := facbr.Bloco_0.Registro0000.DT_FIN;
    end;

    jR := GetJsonObj(jB, 'Registro0002');
    if Assigned(jR) and Assigned(facbr.Bloco_0.Registro0002) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_0.Registro0002);

    jR := GetJsonObj(jB, 'Registro0001');
    if Assigned(jR) then
    begin
      if not HasNonNullKey(jR, 'Registro0005') and Assigned(facbr.Bloco_0.Registro0001.Registro0005) then
      begin
        facbr.Bloco_0.Registro0001.Registro0005.Free;
        facbr.Bloco_0.Registro0001.Registro0005 := nil;
      end;
      if not HasNonNullKey(jR, 'Registro0100') then
      begin
        AOmit0100 := True;
        if Assigned(facbr.Bloco_0.Registro0001.Registro0100) then
        begin
          facbr.Bloco_0.Registro0001.Registro0100.Free;
          facbr.Bloco_0.Registro0001.Registro0100 := nil;
        end;
      end;
      TJSONTools.JsonToObj(jR, facbr.Bloco_0.Registro0001);
      if facbr.Bloco_0.Registro0001.IND_MOV <> ACBrEFDBlocos.imComDados then
        AOmit0100 := False;
    end;
  end;

  jB := GetJsonObj(jRoot, 'Bloco_B');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroB001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_B.RegistroB001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_C');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroC001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_C.RegistroC001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_D');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroD001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_D.RegistroD001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_E');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroE001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_E.RegistroE001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_G');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroG001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_G.RegistroG001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_H');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroH001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_H.RegistroH001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_K');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroK001');
    if Assigned(jR) then
    begin
      TJSONTools.JsonToObj(jR, facbr.Bloco_K.RegistroK001);
      if (facbr.Bloco_K.RegistroK001.IND_MOV = ACBrEFDBlocos.imComDados) and
        (facbr.Bloco_0.Registro0000.COD_VER > ACBrEFDBlocos.vlVersao116) and
        not HasNonNullKey(jR, 'RegistroK010') and
        Assigned(facbr.Bloco_K.RegistroK001.RegistroK010) then
        facbr.Bloco_K.RegistroK001.RegistroK010.IND_TIPO_LEIAUTE := ACBrEFDBlocos.itlCompleto;
    end;
  end;

  jB := GetJsonObj(jRoot, 'Bloco_1');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'Registro1001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_1.Registro1001);
  end;
end;


procedure TACBRBridgeSPEDPisCofins.PopularBlocosEPC(const jRoot: TJSONObject);
var
  jB, jR: TJSONObject;
begin
  if not Assigned(jRoot) then
    Exit;

  jB := GetJsonObj(jRoot, 'Bloco_0');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'Registro0000');
    if Assigned(jR) then
    begin
      TJSONTools.JsonToObj(jR, facbr.Bloco_0.Registro0000);
      if (facbr.DT_INI = 0) and (facbr.Bloco_0.Registro0000.DT_INI > 0) then
        facbr.DT_INI := facbr.Bloco_0.Registro0000.DT_INI;
      if (facbr.DT_FIN = 0) and (facbr.Bloco_0.Registro0000.DT_FIN > 0) then
        facbr.DT_FIN := facbr.Bloco_0.Registro0000.DT_FIN;
    end;

    jR := GetJsonObj(jB, 'Registro0001');
    if Assigned(jR) then
    begin
      if not HasNonNullKey(jR, 'Registro0110') and Assigned(facbr.Bloco_0.Registro0001.Registro0110) then
      begin
        facbr.Bloco_0.Registro0001.Registro0110.Free;
        facbr.Bloco_0.Registro0001.Registro0110 := nil;
      end;
      if HasNonNullKey(jR, 'Registro0900') and not Assigned(facbr.Bloco_0.Registro0001.Registro0900) then
        facbr.Bloco_0.Registro0900New;
      TJSONTools.JsonToObj(jR, facbr.Bloco_0.Registro0001);
    end;
  end;

  jB := GetJsonObj(jRoot, 'Bloco_A');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroA001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_A.RegistroA001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_C');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroC001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_C.RegistroC001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_D');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroD001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_D.RegistroD001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_F');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroF001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_F.RegistroF001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_I');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroI001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_I.RegistroI001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_M');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroM001');
    if Assigned(jR) then
    begin
      if not HasNonNullKey(jR, 'RegistroM200') and Assigned(facbr.Bloco_M.RegistroM001.RegistroM200) then
      begin
        facbr.Bloco_M.RegistroM001.RegistroM200.Free;
        facbr.Bloco_M.RegistroM001.RegistroM200 := nil;
      end;
      if not HasNonNullKey(jR, 'RegistroM600') and Assigned(facbr.Bloco_M.RegistroM001.RegistroM600) then
      begin
        facbr.Bloco_M.RegistroM001.RegistroM600.Free;
        facbr.Bloco_M.RegistroM001.RegistroM600 := nil;
      end;
      TJSONTools.JsonToObj(jR, facbr.Bloco_M.RegistroM001);
    end;
  end;

  jB := GetJsonObj(jRoot, 'Bloco_P');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'RegistroP001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_P.RegistroP001);
  end;

  jB := GetJsonObj(jRoot, 'Bloco_1');
  if Assigned(jB) then
  begin
    jR := GetJsonObj(jB, 'Registro1001');
    if Assigned(jR) then
      TJSONTools.JsonToObj(jR, facbr.Bloco_1.Registro1001);
  end;
end;


procedure TACBRBridgeSPEDPisCofins.SomarRegistro0900(const AOrigem: ACBrEPCBloco_0.TRegistro0900;
const ADestino: ACBrEPCBloco_0.TRegistro0900);

function AddVarField(const VDest, VOrig: Variant;
const ForceZeroWhenEmpty: Boolean): Variant;
var
  HasD, HasO: Boolean;
  SumVal: Double;
begin
  HasD := not (VarIsNull(VDest) or VarIsEmpty(VDest));
  HasO := not (VarIsNull(VOrig) or VarIsEmpty(VOrig));
  if not HasD and not HasO then
  begin
    if ForceZeroWhenEmpty then
      Result := Double(0)
    else
        Result := Null;
    Exit;
  end;
  SumVal := 0;
  if HasD and VarIsNumeric(VDest) then
    SumVal := SumVal + Double(VDest);
  if HasO and VarIsNumeric(VOrig) then
    SumVal := SumVal + Double(VOrig);
  if (not ForceZeroWhenEmpty) and (SumVal = 0) then
    Result := Null
  else
      Result := SumVal;
end;
begin
  if not Assigned(AOrigem) or not Assigned(ADestino) then
    Exit;
  ADestino.REC_TOTAL_BLOCO_A := AddVarField(ADestino.REC_TOTAL_BLOCO_A, AOrigem.REC_TOTAL_BLOCO_A, True);
  ADestino.REC_NRB_BLOCO_A := AddVarField(ADestino.REC_NRB_BLOCO_A, AOrigem.REC_NRB_BLOCO_A, False);
  ADestino.REC_TOTAL_BLOCO_C := AddVarField(ADestino.REC_TOTAL_BLOCO_C, AOrigem.REC_TOTAL_BLOCO_C, True);
  ADestino.REC_NRB_BLOCO_C := AddVarField(ADestino.REC_NRB_BLOCO_C, AOrigem.REC_NRB_BLOCO_C, False);
  ADestino.REC_TOTAL_BLOCO_D := AddVarField(ADestino.REC_TOTAL_BLOCO_D, AOrigem.REC_TOTAL_BLOCO_D, True);
  ADestino.REC_NRB_BLOCO_D := AddVarField(ADestino.REC_NRB_BLOCO_D, AOrigem.REC_NRB_BLOCO_D, False);
  ADestino.REC_TOTAL_BLOCO_F := AddVarField(ADestino.REC_TOTAL_BLOCO_F, AOrigem.REC_TOTAL_BLOCO_F, True);
  ADestino.REC_NRB_BLOCO_F := AddVarField(ADestino.REC_NRB_BLOCO_F, AOrigem.REC_NRB_BLOCO_F, False);
  ADestino.REC_TOTAL_BLOCO_I := AddVarField(ADestino.REC_TOTAL_BLOCO_I, AOrigem.REC_TOTAL_BLOCO_I, True);
  ADestino.REC_NRB_BLOCO_I := AddVarField(ADestino.REC_NRB_BLOCO_I, AOrigem.REC_NRB_BLOCO_I, False);
  ADestino.REC_TOTAL_BLOCO_1 := AddVarField(ADestino.REC_TOTAL_BLOCO_1, AOrigem.REC_TOTAL_BLOCO_1, True);
  ADestino.REC_NRB_BLOCO_1 := AddVarField(ADestino.REC_NRB_BLOCO_1, AOrigem.REC_NRB_BLOCO_1, False);
  ADestino.REC_TOTAL_PERIODO := AddVarField(ADestino.REC_TOTAL_PERIODO, AOrigem.REC_TOTAL_PERIODO, True);
  ADestino.REC_TOTAL_NRB_PERIODO := AddVarField(ADestino.REC_TOTAL_NRB_PERIODO, AOrigem.REC_TOTAL_NRB_PERIODO, False);
end;


procedure TACBRBridgeSPEDPisCofins.MesclarBlocoMConsolidado(const ALista: TList;
const ADestino: TACBrSPEDPisCofins);
var
  I, Y, ActiveCount: Integer;
  ItemSped, SingleActive: TACBrSPEDPisCofins;
  SrcM, DstM: ACBrEPCBloco_M.TRegistroM001;
  HasM200, HasM600: Boolean;
begin
  ActiveCount := 0;
  SingleActive := nil;
  for I := 0 to ALista.Count - 1 do
  begin
    ItemSped := TACBrSPEDPisCofins(ALista[I]);
    if ItemSped.Bloco_M.RegistroM001.IND_MOV = ACBrEPCBlocos.imComDados then
    begin
      Inc(ActiveCount);
      SingleActive := ItemSped;
    end;
  end;

  if ActiveCount = 0 then
  begin
    ADestino.Bloco_M.RegistroM001.IND_MOV := ACBrEPCBlocos.imSemDados;
    Exit;
  end;

  DstM := ADestino.Bloco_M.RegistroM001;
  if ActiveCount = 1 then
  begin
    if not Assigned(SingleActive.Bloco_M.RegistroM001.RegistroM200) and Assigned(DstM.RegistroM200) then
    begin
      DstM.RegistroM200.Free;
      DstM.RegistroM200 := nil;
    end;
    if not Assigned(SingleActive.Bloco_M.RegistroM001.RegistroM600) and Assigned(DstM.RegistroM600) then
    begin
      DstM.RegistroM600.Free;
      DstM.RegistroM600 := nil;
    end;
    CopySpedObjProperties(SingleActive.Bloco_M.RegistroM001, DstM);
    Exit;
  end;

  DstM.IND_MOV := ACBrEPCBlocos.imComDados;
  HasM200 := False;
  HasM600 := False;
  for I := 0 to ALista.Count - 1 do
  begin
    ItemSped := TACBrSPEDPisCofins(ALista[I]);
    SrcM := ItemSped.Bloco_M.RegistroM001;
    if SrcM.IND_MOV <> ACBrEPCBlocos.imComDados then
      Continue;

    for Y := 0 to SrcM.RegistroM100.Count - 1 do
      CopySpedObjProperties(SrcM.RegistroM100.Items[Y], DstM.RegistroM100.New);

    if Assigned(SrcM.RegistroM200) and Assigned(DstM.RegistroM200) then
    begin
      HasM200 := True;
      DstM.RegistroM200.VL_TOT_CONT_NC_PER := DstM.RegistroM200.VL_TOT_CONT_NC_PER + SrcM.RegistroM200.VL_TOT_CONT_NC_PER;
      DstM.RegistroM200.VL_TOT_CRED_DESC := DstM.RegistroM200.VL_TOT_CRED_DESC + SrcM.RegistroM200.VL_TOT_CRED_DESC;
      DstM.RegistroM200.VL_TOT_CRED_DESC_ANT := DstM.RegistroM200.VL_TOT_CRED_DESC_ANT + SrcM.RegistroM200.VL_TOT_CRED_DESC_ANT;
      DstM.RegistroM200.VL_TOT_CONT_NC_DEV := DstM.RegistroM200.VL_TOT_CONT_NC_DEV + SrcM.RegistroM200.VL_TOT_CONT_NC_DEV;
      DstM.RegistroM200.VL_RET_NC := DstM.RegistroM200.VL_RET_NC + SrcM.RegistroM200.VL_RET_NC;
      DstM.RegistroM200.VL_OUT_DED_NC := DstM.RegistroM200.VL_OUT_DED_NC + SrcM.RegistroM200.VL_OUT_DED_NC;
      DstM.RegistroM200.VL_CONT_NC_REC := DstM.RegistroM200.VL_CONT_NC_REC + SrcM.RegistroM200.VL_CONT_NC_REC;
      DstM.RegistroM200.VL_TOT_CONT_CUM_PER := DstM.RegistroM200.VL_TOT_CONT_CUM_PER + SrcM.RegistroM200.VL_TOT_CONT_CUM_PER;
      DstM.RegistroM200.VL_RET_CUM := DstM.RegistroM200.VL_RET_CUM + SrcM.RegistroM200.VL_RET_CUM;
      DstM.RegistroM200.VL_OUT_DED_CUM := DstM.RegistroM200.VL_OUT_DED_CUM + SrcM.RegistroM200.VL_OUT_DED_CUM;
      DstM.RegistroM200.VL_CONT_CUM_REC := DstM.RegistroM200.VL_CONT_CUM_REC + SrcM.RegistroM200.VL_CONT_CUM_REC;
      DstM.RegistroM200.VL_TOT_CONT_REC := DstM.RegistroM200.VL_TOT_CONT_REC + SrcM.RegistroM200.VL_TOT_CONT_REC;
      for Y := 0 to SrcM.RegistroM200.RegistroM205.Count - 1 do
        CopySpedObjProperties(SrcM.RegistroM200.RegistroM205.Items[Y], DstM.RegistroM200.RegistroM205.New);
      for Y := 0 to SrcM.RegistroM200.RegistroM210.Count - 1 do
        CopySpedObjProperties(SrcM.RegistroM200.RegistroM210.Items[Y], DstM.RegistroM200.RegistroM210.New);
    end;

    for Y := 0 to SrcM.RegistroM400.Count - 1 do
      CopySpedObjProperties(SrcM.RegistroM400.Items[Y], DstM.RegistroM400.New);
    for Y := 0 to SrcM.RegistroM500.Count - 1 do
      CopySpedObjProperties(SrcM.RegistroM500.Items[Y], DstM.RegistroM500.New);

    if Assigned(SrcM.RegistroM600) and Assigned(DstM.RegistroM600) then
    begin
      HasM600 := True;
      DstM.RegistroM600.VL_TOT_CONT_NC_PER := DstM.RegistroM600.VL_TOT_CONT_NC_PER + SrcM.RegistroM600.VL_TOT_CONT_NC_PER;
      DstM.RegistroM600.VL_TOT_CRED_DESC := DstM.RegistroM600.VL_TOT_CRED_DESC + SrcM.RegistroM600.VL_TOT_CRED_DESC;
      DstM.RegistroM600.VL_TOT_CRED_DESC_ANT := DstM.RegistroM600.VL_TOT_CRED_DESC_ANT + SrcM.RegistroM600.VL_TOT_CRED_DESC_ANT;
      DstM.RegistroM600.VL_TOT_CONT_NC_DEV := DstM.RegistroM600.VL_TOT_CONT_NC_DEV + SrcM.RegistroM600.VL_TOT_CONT_NC_DEV;
      DstM.RegistroM600.VL_RET_NC := DstM.RegistroM600.VL_RET_NC + SrcM.RegistroM600.VL_RET_NC;
      DstM.RegistroM600.VL_OUT_DED_NC := DstM.RegistroM600.VL_OUT_DED_NC + SrcM.RegistroM600.VL_OUT_DED_NC;
      DstM.RegistroM600.VL_CONT_NC_REC := DstM.RegistroM600.VL_CONT_NC_REC + SrcM.RegistroM600.VL_CONT_NC_REC;
      DstM.RegistroM600.VL_TOT_CONT_CUM_PER := DstM.RegistroM600.VL_TOT_CONT_CUM_PER + SrcM.RegistroM600.VL_TOT_CONT_CUM_PER;
      DstM.RegistroM600.VL_RET_CUM := DstM.RegistroM600.VL_RET_CUM + SrcM.RegistroM600.VL_RET_CUM;
      DstM.RegistroM600.VL_OUT_DED_CUM := DstM.RegistroM600.VL_OUT_DED_CUM + SrcM.RegistroM600.VL_OUT_DED_CUM;
      DstM.RegistroM600.VL_CONT_CUM_REC := DstM.RegistroM600.VL_CONT_CUM_REC + SrcM.RegistroM600.VL_CONT_CUM_REC;
      DstM.RegistroM600.VL_TOT_CONT_REC := DstM.RegistroM600.VL_TOT_CONT_REC + SrcM.RegistroM600.VL_TOT_CONT_REC;
      for Y := 0 to SrcM.RegistroM600.RegistroM605.Count - 1 do
        CopySpedObjProperties(SrcM.RegistroM600.RegistroM605.Items[Y], DstM.RegistroM600.RegistroM605.New);
      for Y := 0 to SrcM.RegistroM600.RegistroM610.Count - 1 do
        CopySpedObjProperties(SrcM.RegistroM600.RegistroM610.Items[Y], DstM.RegistroM600.RegistroM610.New);
    end;

    for Y := 0 to SrcM.RegistroM800.Count - 1 do
      CopySpedObjProperties(SrcM.RegistroM800.Items[Y], DstM.RegistroM800.New);
  end;

  if not HasM200 and Assigned(DstM.RegistroM200) then
  begin
    DstM.RegistroM200.Free;
    DstM.RegistroM200 := nil;
  end;
  if not HasM600 and Assigned(DstM.RegistroM600) then
  begin
    DstM.RegistroM600.Free;
    DstM.RegistroM600 := nil;
  end;
end;


procedure TACBRBridgeSPEDPisCofins.MesclarBloco1Consolidado(const ALista: TList;
const ADestino: TACBrSPEDPisCofins);
var
  I, Y: Integer;
  ItemSped: TACBrSPEDPisCofins;
begin
  ADestino.Bloco_1.Registro1001.IND_MOV := ACBrEPCBlocos.imSemDados;
  for I := 0 to ALista.Count - 1 do
  begin
    ItemSped := TACBrSPEDPisCofins(ALista[I]);
    if ItemSped.Bloco_1.Registro1001.IND_MOV <> ACBrEPCBlocos.imComDados then
      Continue;
    ADestino.Bloco_1.Registro1001.IND_MOV := ACBrEPCBlocos.imComDados;
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1010.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1010.Items[Y], ADestino.Bloco_1.Registro1001.Registro1010.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1020.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1020.Items[Y], ADestino.Bloco_1.Registro1001.Registro1020.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1050.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1050.Items[Y], ADestino.Bloco_1.Registro1001.Registro1050.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1100.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1100.Items[Y], ADestino.Bloco_1.Registro1001.Registro1100.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1200.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1200.Items[Y], ADestino.Bloco_1.Registro1001.Registro1200.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1300.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1300.Items[Y], ADestino.Bloco_1.Registro1001.Registro1300.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1500.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1500.Items[Y], ADestino.Bloco_1.Registro1001.Registro1500.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1600.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1600.Items[Y], ADestino.Bloco_1.Registro1001.Registro1600.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1700.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1700.Items[Y], ADestino.Bloco_1.Registro1001.Registro1700.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1800.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1800.Items[Y], ADestino.Bloco_1.Registro1001.Registro1800.New);
    for Y := 0 to ItemSped.Bloco_1.Registro1001.Registro1900.Count - 1 do
      CopySpedObjProperties(ItemSped.Bloco_1.Registro1001.Registro1900.Items[Y], ADestino.Bloco_1.Registro1001.Registro1900.New);
  end;
end;


procedure TACBRBridgeSPEDPisCofins.MesclarEstabelecimento0140(const ASrc: ACBrEPCBloco_0.TRegistro0140;
const ADestino: TACBrSPEDPisCofins);
var
  I, J: Integer;
  Target0140: ACBrEPCBloco_0.TRegistro0140;
  Found: Boolean;
begin
  if not Assigned(ASrc) or not Assigned(ADestino) then
    Exit;

  Target0140 := nil;
  for I := 0 to ADestino.Bloco_0.Registro0001.Registro0140.Count - 1 do
  begin
    if ((ASrc.CNPJ <> '') and SameText(ADestino.Bloco_0.Registro0001.Registro0140.Items[I].CNPJ, ASrc.CNPJ)) or
      ((ASrc.CNPJ = '') and SameText(ADestino.Bloco_0.Registro0001.Registro0140.Items[I].COD_EST, ASrc.COD_EST)) then
    begin
      Target0140 := ADestino.Bloco_0.Registro0001.Registro0140.Items[I];
      Break;
    end;
  end;

  if not Assigned(Target0140) then
  begin
    CopySpedObjProperties(ASrc, ADestino.Bloco_0.Registro0001.Registro0140.New);
    Exit;
  end;

  if Assigned(ASrc.Registro0145) and (ASrc.Registro0145.COD_INC_TRIB <> '') and
    Assigned(Target0140.Registro0145) and (Target0140.Registro0145.COD_INC_TRIB = '') then
    CopySpedObjProperties(ASrc.Registro0145, Target0140.Registro0145);

  for I := 0 to ASrc.Registro0150.Count - 1 do
  begin
    Found := False;
    for J := 0 to Target0140.Registro0150.Count - 1 do
      if SameText(Target0140.Registro0150.Items[J].COD_PART, ASrc.Registro0150.Items[I].COD_PART) then
    begin
      Found := True;
      Break;
    end;
    if not Found then
      CopySpedObjProperties(ASrc.Registro0150.Items[I], Target0140.Registro0150.New);
  end;

  for I := 0 to ASrc.Registro0190.Count - 1 do
  begin
    Found := False;
    for J := 0 to Target0140.Registro0190.Count - 1 do
      if SameText(Target0140.Registro0190.Items[J].UNID, ASrc.Registro0190.Items[I].UNID) then
    begin
      Found := True;
      Break;
    end;
    if not Found then
      CopySpedObjProperties(ASrc.Registro0190.Items[I], Target0140.Registro0190.New);
  end;

  for I := 0 to ASrc.Registro0200.Count - 1 do
  begin
    Found := False;
    for J := 0 to Target0140.Registro0200.Count - 1 do
      if SameText(Target0140.Registro0200.Items[J].COD_ITEM, ASrc.Registro0200.Items[I].COD_ITEM) then
    begin
      Found := True;
      Break;
    end;
    if not Found then
      CopySpedObjProperties(ASrc.Registro0200.Items[I], Target0140.Registro0200.New);
  end;

  for I := 0 to ASrc.Registro0400.Count - 1 do
  begin
    Found := False;
    for J := 0 to Target0140.Registro0400.Count - 1 do
      if SameText(Target0140.Registro0400.Items[J].COD_NAT, ASrc.Registro0400.Items[I].COD_NAT) then
    begin
      Found := True;
      Break;
    end;
    if not Found then
      CopySpedObjProperties(ASrc.Registro0400.Items[I], Target0140.Registro0400.New);
  end;

  for I := 0 to ASrc.Registro0450.Count - 1 do
  begin
    Found := False;
    for J := 0 to Target0140.Registro0450.Count - 1 do
      if SameText(Target0140.Registro0450.Items[J].COD_INF, ASrc.Registro0450.Items[I].COD_INF) then
    begin
      Found := True;
      Break;
    end;
    if not Found then
      CopySpedObjProperties(ASrc.Registro0450.Items[I], Target0140.Registro0450.New);
  end;
end;

function TACBRModelosJSONSPED.ModelGerar: TJSONObject;
var
  jSped: TJSONObject;
begin
  facbr.DT_INI := Date;
  facbr.DT_FIN := Date;
  TJSONTools.PopulateModelDefaults(facbr.Bloco_0, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_B, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_C, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_D, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_E, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_G, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_H, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_K, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_1, 5);
  jSped := TJSONTools.ObjToJson(facbr);
  if Assigned(jSped) then
    jSped.Delete('Bloco_9');
  Result := TJSONObject.Create;
  Result.Add('sped', jSped);
end;



function TACBRModelosJSONSPEDPisCofins.ModelGerar: TJSONObject;
var
  jSped: TJSONObject;
begin
  facbr.DT_INI := Date;
  facbr.DT_FIN := Date;
  facbr.Bloco_0.Registro0900New;
  TJSONTools.PopulateModelDefaults(facbr.Bloco_0, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_A, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_C, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_D, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_F, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_I, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_M, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_P, 5);
  TJSONTools.PopulateModelDefaults(facbr.Bloco_1, 5);
  jSped := TJSONTools.ObjToJson(facbr);
  if Assigned(jSped) then
    jSped.Delete('Bloco_9');
  Result := TJSONObject.Create;
  Result.Add('sped', jSped);
end;


end.
