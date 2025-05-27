unit method.acbr.diversos.extenso;

{$mode Delphi}

interface

uses
  fpjson, jsonconvert, ACBrExtenso,
  Horse.HandleException, jsonparser,
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
  Result := TJSONTools.ObjToJson(facbr);
end;

function TACBRBridgeExtenso.TraduzValor(const jExtenso: TJSONObject): TJSONObject;
begin
  TJSONTools.JsonToObj(jExtenso, facbr);

  Result := TJSONTools.ObjToJson(facbr);
end;

constructor TACBRBridgeExtenso.Create;
begin
  facbr := TACBrExtenso.Create(nil);
end;

destructor TACBRBridgeExtenso.Destroy;
begin
  facbr.Free;
  inherited Destroy;
end;

end.
