unit method.acbr.sintegra;

{$mode Delphi}

interface

uses
  RTTI,
  ACBrSintegra,
  pcnConversao,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  streamtools;

type
  TACBRBridgeSintegra = class
  private
    fcfg: string;
    facbr: TACBrSintegra;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Sintegra(const jSintegra: TJSONObject): TJSONObject;
    function Gerar(const jSintegra: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONSintegra = class(TACBRBridgeSintegra)
  public
    function ModelConfig: TJSONObject;
  end;

implementation

{ TACBRModelosJSONSintegra }

function TACBRModelosJSONSintegra.ModelConfig: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('FileName', facbr.FileName);
end;

{ TACBRBridgeSintegra }

procedure TACBRBridgeSintegra.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then Exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr);
  finally
    O.Free;
  end;
  fcfg := '';
end;

constructor TACBRBridgeSintegra.Create(const Cfg: string);
begin
  facbr := TACBrSintegra.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeSintegra.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeSintegra.Sintegra(const jSintegra: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Result.Add('status', 'sucesso');
  Result.Add('message', 'ACBr Sintegra inicializado com sucesso.');
end;

function TACBRBridgeSintegra.Gerar(const jSintegra: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    try
      // Mapeamento Generico das Propriedades
      TJSONTools.JsonToObj(jSintegra, facbr);

      // Gera o arquivo do Sintegra
      facbr.GeraArquivo;
      
      Result.Add('status', 'sucesso');
      Result.Add('message', 'Sintegra gerado com sucesso.');
      Result.Add('arquivo', facbr.FileName);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao gerar Sintegra: ' + E.Message);
      end;
    end;
  finally
  end;
end;

end.
