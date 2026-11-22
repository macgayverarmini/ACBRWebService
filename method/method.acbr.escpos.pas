unit method.acbr.escpos;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrPosPrinter,
  Variants,
  fpjson,
  jsonconvert,
  jsonparser,
  Base64,
  streamtools,
  Classes, SysUtils,
  resource.strings.global;

type
  TACBRBridgeEscPos = class
  private
    fcfg: string;
    facbr: TACBrPosPrinter;
    fForcarSpool: Boolean;
    procedure AplicarOpcoesJSON(const O: TJSONObject);
    procedure CarregaConfig;
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

function ParsePosPrinterModelo(const S: string; out AModelo: TACBrPosPrinterModelo): Boolean;
var
  LVal: string;
  LInt: Integer;
begin
  Result := True;
  LVal := LowerCase(Trim(S));
  if LVal = '' then
  begin
    Result := False;
    Exit;
  end;
  LInt := StrToIntDef(LVal, -1);
  if (LInt >= Ord(Low(TACBrPosPrinterModelo))) and (LInt <= Ord(High(TACBrPosPrinterModelo))) then
  begin
    AModelo := TACBrPosPrinterModelo(LInt);
    Exit;
  end;
  if (LVal = 'pptexto') or (LVal = 'texto') or (LVal = 'text') then
    AModelo := ppTexto
  else if (LVal = 'ppescposepson') or (LVal = 'epson') or (LVal = 'escpos') or (LVal = 'escposepson') then
    AModelo := ppEscPosEpson
  else if (LVal = 'ppescbematech') or (LVal = 'bematech') then
    AModelo := ppEscBematech
  else if (LVal = 'ppescdaruma') or (LVal = 'daruma') then
    AModelo := ppEscDaruma
  else if (LVal = 'ppescvox') or (LVal = 'vox') then
    AModelo := ppEscVox
  else if (LVal = 'ppescdiebold') or (LVal = 'diebold') then
    AModelo := ppEscDiebold
  else if (LVal = 'ppescepsonp2') or (LVal = 'epsonp2') then
    AModelo := ppEscEpsonP2
  else if (LVal = 'ppcustompos') or (LVal = 'custompos') or (LVal = 'custom') then
    AModelo := ppCustomPos
  else if (LVal = 'ppescposstar') or (LVal = 'star') then
    AModelo := ppEscPosStar
  else if (LVal = 'ppesczjiang') or (LVal = 'zjiang') or (LVal = 'elgin') then
    AModelo := ppEscZJiang
  else if (LVal = 'ppescgprinter') or (LVal = 'gprinter') or (LVal = 'gertec') then
    AModelo := ppEscGPrinter
  else if (LVal = 'ppescdatecs') or (LVal = 'datecs') then
    AModelo := ppEscDatecs
  else if (LVal = 'ppescsunmi') or (LVal = 'sunmi') then
    AModelo := ppEscSunmi
  else if (LVal = 'ppexterno') or (LVal = 'externo') then
    AModelo := ppExterno
  else
    Result := False;
end;

function ParsePosPaginaCodigo(const S: string; out APagina: TACBrPosPaginaCodigo): Boolean;
var
  LVal: string;
  LInt: Integer;
begin
  Result := True;
  LVal := LowerCase(Trim(S));
  if LVal = '' then
  begin
    Result := False;
    Exit;
  end;
  if (LVal = 'pcnone') or (LVal = 'none') or (LVal = '0') then
    APagina := pcNone
  else if (LVal = 'pc437') or (LVal = '437') or (LVal = 'cp437') or (LVal = '1') then
    APagina := pc437
  else if (LVal = 'pc850') or (LVal = '850') or (LVal = 'cp850') or (LVal = '2') then
    APagina := pc850
  else if (LVal = 'pc852') or (LVal = '852') or (LVal = 'cp852') or (LVal = '3') then
    APagina := pc852
  else if (LVal = 'pc860') or (LVal = '860') or (LVal = 'cp860') or (LVal = '4') then
    APagina := pc860
  else if (LVal = 'pcutf8') or (LVal = 'utf8') or (LVal = 'utf-8') or (LVal = '65001') or (LVal = '5') then
    APagina := pcUTF8
  else if (LVal = 'pc1252') or (LVal = '1252') or (LVal = 'cp1252') or (LVal = 'windows-1252') or (LVal = '6') then
    APagina := pc1252
  else
  begin
    LInt := StrToIntDef(LVal, -1);
    if (LInt >= Ord(Low(TACBrPosPaginaCodigo))) and (LInt <= Ord(High(TACBrPosPaginaCodigo))) then
      APagina := TACBrPosPaginaCodigo(LInt)
    else
      Result := False;
  end;
end;

{ TACBRModelosJSONEscPos }

function TACBRModelosJSONEscPos.ModelConfig: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Modelo', Integer(facbr.Modelo));
  Result.Add('Porta', facbr.Porta);
  Result.Add('ColunasFonteNormal', facbr.ColunasFonteNormal);
  Result.Add('PaginaDeCodigo', Integer(facbr.PaginaDeCodigo));
  Result.Add('EspacoEntreLinhas', facbr.EspacoEntreLinhas);
  Result.Add('LinhasEntreCupons', facbr.LinhasEntreCupons);
  Result.Add('CortaPapel', facbr.CortaPapel);
  Result.Add('TraduzirTags', facbr.TraduzirTags);
end;

{ TACBRBridgeEscPos }

procedure TACBRBridgeEscPos.AplicarOpcoesJSON(const O: TJSONObject);
var
  N: TJSONData;
  LMod: TACBrPosPrinterModelo;
  LPag: TACBrPosPaginaCodigo;
begin
  if not Assigned(O) then
    Exit;

  TJSONTools.JsonToObj(O, facbr);

  N := O.Find('Modelo');
  if not Assigned(N) then N := O.Find('modelo');
  if Assigned(N) and (not (N.JSONType in [jtNull, jtObject, jtArray])) then
  begin
    if ParsePosPrinterModelo(N.AsString, LMod) then
      facbr.Modelo := LMod;
  end;

  N := O.Find('PaginaDeCodigo');
  if not Assigned(N) then N := O.Find('paginaDeCodigo');
  if not Assigned(N) then N := O.Find('paginaCodigo');
  if not Assigned(N) then N := O.Find('PaginaCodigo');
  if Assigned(N) and (not (N.JSONType in [jtNull, jtObject, jtArray])) then
  begin
    if ParsePosPaginaCodigo(N.AsString, LPag) then
      facbr.PaginaDeCodigo := LPag;
  end;

  N := O.Find('Porta');
  if not Assigned(N) then N := O.Find('porta');
  if Assigned(N) and (N.JSONType = jtString) then
    facbr.Porta := Trim(N.AsString);

  N := O.Find('ColunasFonteNormal');
  if not Assigned(N) then N := O.Find('colunasFonteNormal');
  if not Assigned(N) then N := O.Find('colunas');
  if not Assigned(N) then N := O.Find('Colunas');
  if Assigned(N) and (N.JSONType = jtNumber) and (N.AsInteger > 0) then
    facbr.ColunasFonteNormal := N.AsInteger;

  N := O.Find('GerarSpool');
  if not Assigned(N) then N := O.Find('gerarSpool');
  if Assigned(N) and (N.JSONType = jtBoolean) and N.AsBoolean then
    fForcarSpool := True;
end;

procedure TACBRBridgeEscPos.CarregaConfig;
var
  O: TJSONObject;
begin
  if Trim(fcfg) = '' then
    Exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    AplicarOpcoesJSON(O);
  finally
    O.Free;
  end;
  fcfg := '';
end;

constructor TACBRBridgeEscPos.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrPosPrinter.Create(nil);
  fForcarSpool := False;
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
  textoImprimir, portaUpper, spoolFile, b64Spool: string;
  isTempSpool: Boolean;
begin
  CarregaConfig;
  AplicarOpcoesJSON(jEscPos);
  Result := TJSONObject.Create;

  textoImprimir := '';
  if Assigned(jEscPos) then
  begin
    jLinhas := jEscPos.Find('Linhas');
    if not Assigned(jLinhas) then jLinhas := jEscPos.Find('linhas');
    if not Assigned(jLinhas) then jLinhas := jEscPos.Find('Texto');
    if not Assigned(jLinhas) then jLinhas := jEscPos.Find('texto');
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

  portaUpper := UpperCase(Trim(facbr.Porta));
  isTempSpool := fForcarSpool or (portaUpper = '') or (portaUpper = 'BUFFER') or
                 (portaUpper = 'SPOOL') or (portaUpper = 'MEMORIA') or
                 (portaUpper = 'TEMP') or (portaUpper = 'NUL');
  spoolFile := '';
  if isTempSpool then
  begin
    spoolFile := ExtractFilePath(ParamStr(0)) +
      Format('escpos_spool_%d_%d.bin', [GetTickCount64, Random(1000000)]);
    facbr.Porta := spoolFile;
  end;

  try
    facbr.Ativar;
    if textoImprimir <> '' then
      facbr.Imprimir(textoImprimir);
    facbr.Desativar;

    Result.Add(RSStatusField, RSStatusSucesso);
    Result.Add('sucesso', True);
    Result.Add(RSMessageField, 'Impressao executada com sucesso.');
    Result.Add('mensagem', 'Impressao executada com sucesso.');
    Result.Add('modelo', Integer(facbr.Modelo));

    if isTempSpool and FileExists(spoolFile) then
    begin
      b64Spool := FileToStringBase64(spoolFile, True, tamanho);
      Result.Add('spool_base64', b64Spool);
      Result.Add('buffer_base64', b64Spool);
      Result.Add('tamanho', tamanho);
    end
    else if (not isTempSpool) and FileExists(facbr.Porta) then
    begin
      b64Spool := FileToStringBase64(facbr.Porta, False, tamanho);
      Result.Add('spool_base64', b64Spool);
      Result.Add('buffer_base64', b64Spool);
      Result.Add('tamanho', tamanho);
    end;
  except
    on E: Exception do
    begin
      if facbr.Ativo then
        facbr.Desativar;
      if isTempSpool and (spoolFile <> '') and FileExists(spoolFile) then
        SysUtils.DeleteFile(spoolFile);
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add('sucesso', False);
      Result.Add(RSMessageField, 'Erro na impressao: ' + E.Message);
      Result.Add('mensagem', 'Erro na impressao: ' + E.Message);
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
  CarregaConfig;
  Result := TJSONObject.Create;
  SL := TStringList.Create;
  Arr := TJSONArray.Create;
  try
    try
      facbr.Device.AcharPortas(SL);
      for I := 0 to SL.Count - 1 do
        Arr.Add(SL[I]);
      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('sucesso', True);
      Result.Add('portas', Arr);
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add('sucesso', False);
        Result.Add(RSMessageField, 'Erro ao listar portas: ' + E.Message);
        Arr.Free;
      end;
    end;
  finally
    SL.Free;
  end;
end;

end.
