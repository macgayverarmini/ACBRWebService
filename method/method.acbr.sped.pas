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
  streamtools;

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
  end;

  TACBRModelosJSONSPEDPisCofins = class(TACBRBridgeSPEDPisCofins)
  public
    function ModelConfig: TJSONObject;
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

end.
