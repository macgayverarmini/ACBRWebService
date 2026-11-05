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
  streamtools,
  resource.strings.global,
  resource.strings.msg;

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
  if Trim(fcfg) = '' then
    raise Exception.Create(RSConfigEmptyError);
  try
    O := GetJSON(fcfg) as TJSONObject;
    try
      TJSONTools.JsonToObj(O, facbr.Configuracoes);
    finally
      O.Free;
    end;
  except
    on E: Exception do
      raise Exception.Create(RSConfigReadError + E.Message);
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
  Result.Add(RSStatusField, RSStatusSucesso);
  Result.Add(RSMessageField, 'ACBr eSocial inicializado com sucesso.');
end;

end.
