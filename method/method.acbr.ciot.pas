unit method.acbr.ciot;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrCIOT,
  ACBrDFeSSL,
  ACBrDFeConfiguracoes,
  ACBrCIOTConfiguracoes,
  pcnConversao,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  streamtools,
  resource.strings.global;

type
  TACBRBridgeCIOT = class
  private
    fcfg: string;
    facbr: TACBrCIOT;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function CIOT(const jCIOT: TJSONObject): TJSONObject;
    function Enviar(const jCIOT: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONCIOT = class(TACBRBridgeCIOT)
  public
    function ModelConfig: TJSONObject;
  end;

implementation

{ TACBRModelosJSONCIOT }

function TACBRModelosJSONCIOT.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

{ TACBRBridgeCIOT }

procedure TACBRBridgeCIOT.CarregaConfig;
var
  O: TJSONObject;
begin
  if (fcfg = '') or (fcfg = '') then
    raise Exception.Create('Configuracao vazia ou nao informada.');
  try
    O := GetJSON(fcfg) as TJSONObject;
      try
        TJSONTools.JsonToObj(O, facbr.Configuracoes);
      finally
        O.Free;
      end;
  except
    on E: Exception do
      raise Exception.Create('Erro na leitura da configuracao: ' + E.Message);
  end;
  fcfg := '';
end;

constructor TACBRBridgeCIOT.Create(const Cfg: string);
begin
  facbr := TACBrCIOT.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeCIOT.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeCIOT.CIOT(const jCIOT: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Result.Add('status', 'sucesso');
  Result.Add('message', 'ACBr CIOT inicializado com sucesso.');
end;

function TACBRBridgeCIOT.Enviar(const jCIOT: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    try
      if facbr.Enviar('') then
      begin
        Result.Add('status', 'sucesso');
        Result.Add('message', 'CIOT enviado com sucesso.');
      end
      else
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Falha no envio do CIOT.');
      end;
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao enviar CIOT: ' + E.Message);
      end;
    end;
  finally
  end;
end;

end.
