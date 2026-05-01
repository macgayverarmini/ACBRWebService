unit method.acbr.sped;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrSpedFiscal,
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
  if fcfg = '' then Exit;
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
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    try
      // Mapeamento Generico das Propriedades
      TJSONTools.JsonToObj(jSPED, facbr);

      // Gera o TXT do SPED Fiscal baseado nos blocos
      facbr.SaveFileTXT;
      
      Result.Add('status', 'sucesso');
      Result.Add('message', 'SPED gerado com sucesso.');
      Result.Add('arquivo', facbr.Arquivo);
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

end.
