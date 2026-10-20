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
  ACBrEPCBlocos;

type
  TACBRBridgeSPED = class
  private
    fcfg: string;
    facbr: TACBrSpedFiscal;
    procedure CarregaConfig;
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
  end;

  TACBRBridgeSPEDPisCofins = class
  private
    fcfg: string;
    facbr: TACBrSPEDPisCofins;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Gerar(const jSPED: TJSONObject): TJSONObject;
    function Importar(const jSPED: TJSONObject): TJSONObject;
    function Consolidar(const jConsolidar: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONSPEDPisCofins = class(TACBRBridgeSPEDPisCofins)
  public
    function ModelConfig: TJSONObject;
    function ModelImportar: TJSONObject;
  end;

implementation

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
  fcfg := Cfg;
end;

destructor TACBRBridgeSPED.Destroy;
begin
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
  fullFile: string;
  tamanho: integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    try
      if facbr.Path = '' then
        facbr.Path := ExtractFilePath(ParamStr(0));
      if facbr.Arquivo = '' then
        facbr.Arquivo := 'sped_fiscal.txt';

      // Mapeamento Generico das Propriedades
      TJSONTools.JsonToObj(jSPED, facbr);

      // Gera o TXT do SPED Fiscal baseado nos blocos
      facbr.SaveFileTXT;

      fullFile := IncludeTrailingPathDelimiter(facbr.Path) + facbr.Arquivo;
      Result.Add('status', 'sucesso');
      Result.Add('message', 'SPED gerado com sucesso.');
      Result.Add('arquivo', fullFile);
      if FileExists(fullFile) then
        Result.Add('arquivo_base64', FileToStringBase64(fullFile, False, tamanho));
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao gerar SPED: ' + E.Message);
      end;
    end;
  finally
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
  fcfg := Cfg;
end;

destructor TACBRBridgeSPEDPisCofins.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeSPEDPisCofins.Gerar(const jSPED: TJSONObject): TJSONObject;
var
  fullFile: string;
  tamanho: integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    if facbr.Path = '' then
      facbr.Path := ExtractFilePath(ParamStr(0));
    if facbr.Arquivo = '' then
      facbr.Arquivo := 'sped_piscofins.txt';

    TJSONTools.JsonToObj(jSPED, facbr);
    facbr.SaveFileTXT;

    fullFile := IncludeTrailingPathDelimiter(facbr.Path) + facbr.Arquivo;
    Result.Add('status', 'sucesso');
    Result.Add('message', 'SPED Contribuicoes (PIS/COFINS) gerado com sucesso.');
    Result.Add('arquivo', fullFile);
    if FileExists(fullFile) then
      Result.Add('arquivo_base64', FileToStringBase64(fullFile, False, tamanho));
  except
    on E: Exception do
    begin
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
      b64 := jSPED.Get('arquivo_base64', '');
      tmpFile := jSPED.Get('Arquivo', '');
      if b64 <> '' then
      begin
        tmpFile := ExtractFilePath(ParamStr(0)) + 'sped_efdimp_' + IntToStr(GetTickCount64) + '.txt';
        SL.Text := DecodeStringBase64(b64);
        SL.SaveToFile(tmpFile);
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
  b64, tmpFile: string;
  SL: TStringList;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Imp := TACBrSpedPCImportar.Create(nil);
  SL := TStringList.Create;
  try
    try
      b64 := jSPED.Get('arquivo_base64', '');
      tmpFile := jSPED.Get('Arquivo', '');
      if b64 <> '' then
      begin
        tmpFile := ExtractFilePath(ParamStr(0)) + 'sped_epcimp_' + IntToStr(GetTickCount64) + '.txt';
        SL.Text := DecodeStringBase64(b64);
        SL.SaveToFile(tmpFile);
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

      if (b64 <> '') and FileExists(tmpFile) then
        DeleteFile(tmpFile);

      Result.Add('status', 'sucesso');
      Result.Add('message', 'SPED Contribuicoes importado com sucesso.');
      Result.Add('sped', TJSONTools.SafeObjToJson(facbr, 'Erro ao serializar SPED Contribuicoes importado'));
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
  I, Y, tamanho: Integer;
  b64, tmpFile, outFile: string;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  arrData := jConsolidar.Find('arquivos');
  if not Assigned(arrData) then
    arrData := jConsolidar.Find('Arquivos');

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
        if arr.Items[I].JSONType = jtObject then
        begin
          itemObj := TJSONObject(arr.Items[I]);
          b64 := itemObj.Get('arquivo_base64', itemObj.Get('ArquivoData', ''));
          if b64 <> '' then
          begin
            tmpFile := ExtractFilePath(ParamStr(0)) + 'sped_cons_' + IntToStr(GetTickCount64) + '_' + IntToStr(I) + '.txt';
            SL.Text := DecodeStringBase64(b64);
            SL.SaveToFile(tmpFile);
            try
              ItemSped := TACBrSPEDPisCofins.Create(nil);
              Lista.Add(ItemSped);
              Imp.ACBrSpedPisCofins := ItemSped;
              Imp.Arquivo := tmpFile;
              Imp.Importar;
              if itemObj.Get('principal', itemObj.Get('Principal', False)) or not Assigned(Principal) then
                Principal := ItemSped;
            finally
              if FileExists(tmpFile) then
                DeleteFile(tmpFile);
            end;
          end;
        end;
      end;

      if not Assigned(Principal) or (Lista.Count = 0) then
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Nenhum arquivo SPED Contribuicoes valido foi importado para consolidacao.');
        Exit;
      end;

      // Bloco 0 do Principal (0000, 0001, 0100, 0110)
      CopySpedObjProperties(Principal.Bloco_0.Registro0000, Destino.Bloco_0.Registro0000New);
      Destino.Bloco_0.Registro0001.IND_MOV := Principal.Bloco_0.Registro0001.IND_MOV;
      for Y := 0 to Principal.Bloco_0.Registro0001.Registro0100.Count - 1 do
        CopySpedObjProperties(
          Principal.Bloco_0.Registro0001.Registro0100.Items[Y],
          Destino.Bloco_0.Registro0001.Registro0100.New
        );
      CopySpedObjProperties(Principal.Bloco_0.Registro0001.Registro0110, Destino.Bloco_0.Registro0001.Registro0110);

      // Mescla 0140, Bloco A e Bloco C de todas as filiais
      for I := 0 to Lista.Count - 1 do
      begin
        ItemSped := TACBrSPEDPisCofins(Lista[I]);
        for Y := 0 to ItemSped.Bloco_0.Registro0001.Registro0140.Count - 1 do
          CopySpedObjProperties(
            ItemSped.Bloco_0.Registro0001.Registro0140.Items[Y],
            Destino.Bloco_0.Registro0001.Registro0140.New
          );

        if ItemSped.Bloco_A.RegistroA001.IND_MOV = imComDados then
        begin
          Destino.Bloco_A.RegistroA001.IND_MOV := imComDados;
          for Y := 0 to ItemSped.Bloco_A.RegistroA001.RegistroA010.Count - 1 do
            CopySpedObjProperties(
              ItemSped.Bloco_A.RegistroA001.RegistroA010.Items[Y],
              Destino.Bloco_A.RegistroA001.RegistroA010.New
            );
        end;

        if ItemSped.Bloco_C.RegistroC001.IND_MOV = imComDados then
        begin
          Destino.Bloco_C.RegistroC001.IND_MOV := imComDados;
          for Y := 0 to ItemSped.Bloco_C.RegistroC001.RegistroC010.Count - 1 do
            CopySpedObjProperties(
              ItemSped.Bloco_C.RegistroC001.RegistroC010.Items[Y],
              Destino.Bloco_C.RegistroC001.RegistroC010.New
            );
        end;
      end;

      Destino.DT_INI := Destino.Bloco_0.Registro0000.DT_INI;
      Destino.DT_FIN := Destino.Bloco_0.Registro0000.DT_FIN;
      Destino.Path := ExtractFilePath(ParamStr(0));
      Destino.Arquivo := 'sped_piscofins_consolidado_' + IntToStr(GetTickCount64) + '.txt';
      Destino.SaveFileTXT;

      outFile := IncludeTrailingPathDelimiter(Destino.Path) + Destino.Arquivo;
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

end.
