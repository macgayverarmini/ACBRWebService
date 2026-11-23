unit method.acbr.diversos.validador;

{$mode Delphi}
{$M+}

interface

uses
  fpjson, jsonconvert, ACBrValidador,
  Classes, SysUtils;

type

  { TACBRBridgeValidador }

  TACBRBridgeValidador = class
  private
    facbr: TACBrValidador;
  public
    function Modelo: TJSONObject;
    function Validar(const jValidador: TJSONObject): TJSONBoolean;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TACBRBridgeValidador }

function TACBRBridgeValidador.Modelo: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr, 'Erro ao gerar modelo Validador');
end;

function TACBRBridgeValidador.Validar(const jValidador: TJSONObject): TJSONBoolean;
begin
  TJSONTools.JsonToObj(jValidador, facbr);
  Result := TJSONBoolean.Create(facbr.Validar);
end;

constructor TACBRBridgeValidador.Create;
begin
  inherited Create;
  facbr := TACBrValidador.Create(nil);
end;

destructor TACBRBridgeValidador.Destroy;
begin
  facbr.Free;
  inherited Destroy;
end;

end.
