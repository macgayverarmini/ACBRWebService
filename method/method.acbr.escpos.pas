unit method.acbr.escpos;

{$mode Delphi}

interface

uses
  RTTI,
  ACBrPosPrinter,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  streamtools;

type
  TACBRBridgeEscPos = class
  private
    fcfg: string;
    facbr: TACBrPosPrinter;
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

{ TACBRModelosJSONEscPos }

function TACBRModelosJSONEscPos.ModelConfig: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Modelo', Integer(facbr.Modelo));
  Result.Add('Porta', facbr.Porta);
  Result.Add('ColunasFonteNormal', facbr.ColunasFonteNormal);
end;

{ TACBRBridgeEscPos }

procedure TACBRBridgeEscPos.CarregaConfig;
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

constructor TACBRBridgeEscPos.Create(const Cfg: string);
begin
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
  LinhasStr: TJSONString;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  
  try
    facbr.Ativar;
    if jEscPos.Find('Linhas', LinhasStr) then
    begin
      facbr.Imprimir(LinhasStr.AsString);
    end;
    facbr.Desativar;
    
    Result.Add('status', 'sucesso');
    Result.Add('message', 'Impressão executada com sucesso.');
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na impressão: ' + E.Message);
      if facbr.Ativo then facbr.Desativar;
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
      Result.Add('status', 'sucesso');
      Result.Add('portas', Arr);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao listar portas: ' + E.Message);
        Arr.Free;
      end;
    end;
  finally
    SL.Free;
  end;
end;

end.
