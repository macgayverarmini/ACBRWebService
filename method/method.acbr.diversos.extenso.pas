unit method.acbr.diversos.extenso;

{$mode Delphi}
{$M+}

interface

uses
  fpjson, jsonconvert, ACBrExtenso,
  Classes, SysUtils;

type

  { TACBRBridgeExtenso }

  TACBRBridgeExtenso = class
  private
    facbr: TACBrExtenso;
  public
    function Modelo: TJSONObject;
    function TraduzValor(const jExtenso: TJSONObject): TJSONObject;

    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TACBRBridgeExtenso }

function TACBRBridgeExtenso.Modelo: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr, 'Erro ao gerar modelo Extenso');
end;

function TACBRBridgeExtenso.TraduzValor(const jExtenso: TJSONObject): TJSONObject;
begin
  TJSONTools.JsonToObj(jExtenso, facbr);
  Result := TJSONTools.SafeObjToJson(facbr, 'Erro ao traduzir valor por extenso');
end;

constructor TACBRBridgeExtenso.Create;
begin
  inherited Create;
  facbr := TACBrExtenso.Create(nil);
end;

destructor TACBRBridgeExtenso.Destroy;
begin
  facbr.Free;
  inherited Destroy;
end;

end.
