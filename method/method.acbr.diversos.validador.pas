unit method.acbr.diversos.validador;

{$mode Delphi}

interface

uses
  fpjson,jsonconvert, ACBrValidador,
  Horse.HandleException, Base64, jsonparser,
  Classes, SysUtils, fpjsonrtti;

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
   Result := TJSONTools.ObjToJson(facbr);
end;

function TACBRBridgeValidador.Validar(const jValidador: TJSONObject
  ): TJSONBoolean;
begin
  TJSONTools.JsonToObj(jValidador, facbr);
  Result := TJSONBoolean.Create(facbr.Validar);
end;

constructor TACBRBridgeValidador.Create;
begin
 facbr := TACBrValidador.Create(nil);
end;

destructor TACBRBridgeValidador.Destroy;
begin
  facbr.Free;
  inherited Destroy;
end;

end.

