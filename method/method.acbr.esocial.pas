unit method.acbr.esocial;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBreSocial,
  pcnConversao,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  streamtools;

type
  TACBRBridgeeSocial = class
  private
    fcfg: string;
    facbr: TACBreSocial;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function eSocial(const jeSocial: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONeSocial = class(TACBRBridgeeSocial)
  public
    function ModelConfig: TJSONObject;
  end;

implementation

{ TACBRModelosJSONeSocial }

function TACBRModelosJSONeSocial.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

{ TACBRBridgeeSocial }

procedure TACBRBridgeeSocial.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then Exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
  finally
    O.Free;
  end;
  fcfg := '';
end;

constructor TACBRBridgeeSocial.Create(const Cfg: string);
begin
  facbr := TACBreSocial.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeeSocial.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeeSocial.eSocial(const jeSocial: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Result.Add('status', 'sucesso');
  Result.Add('message', 'ACBr eSocial inicializado com sucesso.');
end;

end.
