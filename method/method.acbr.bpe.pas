unit method.acbr.bpe;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrBPe,
  ACBrBPeWebServices,
  ACBrDFeSSL,
  ACBrDFeConfiguracoes,
  ACBrBPeConfiguracoes,
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
  TACBRBridgeBPe = class
  private
    fcfg: string;
    facbr: TACBrBPe;
    procedure CarregaConfig;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function BPe(const jBPe: TJSONObject): TJSONObject;
    function StatusServico: TJSONObject;
    function Enviar(const jBPe: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONBPe = class(TACBRBridgeBPe)
  public
    function ModelConfig: TJSONObject;
  end;

implementation

{ TACBRModelosJSONBPe }

function TACBRModelosJSONBPe.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

{ TACBRBridgeBPe }

procedure TACBRBridgeBPe.CarregaConfig;
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

constructor TACBRBridgeBPe.Create(const Cfg: string);
begin
  facbr := TACBrBPe.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeBPe.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeBPe.StatusServico: TJSONObject;
begin
  CarregaConfig;
  try
    facbr.WebServices.StatusServico.Executar;
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.StatusServico));
  except
    on E: Exception do
    begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao consultar status: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeBPe.BPe(const jBPe: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Result.Add(RSStatusField, RSStatusSucesso);
  Result.Add(RSMessageField, 'ACBr BPe inicializado com sucesso (Não implementado).');
end;

function TACBRBridgeBPe.Enviar(const jBPe: TJSONObject): TJSONObject;
var
  Lote: Int64;
  Imprimir: Boolean;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    Lote := jBPe.Get('Lote', 1);
    Imprimir := jBPe.Get('Imprimir', False);
    if facbr.Enviar(Lote, Imprimir) then
    begin
      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSMessageField, 'BPe enviado com sucesso.');
    end
    else
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Falha no envio BPe.');
    end;
  except
    on E: Exception do
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao enviar BPe: ' + E.Message);
    end;
  end;
end;

end.
