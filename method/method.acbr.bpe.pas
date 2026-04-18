unit method.acbr.bpe;

{$mode Delphi}

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
  streamtools;

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
  if fcfg = '' then Exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
  finally
    O.Free;
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
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro ao consultar status: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeBPe.BPe(const jBPe: TJSONObject): TJSONObject;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Result.Add('status', 'sucesso');
  Result.Add('message', 'ACBr BPe inicializado com sucesso (Não implementado).');
end;

function TACBRBridgeBPe.Enviar(const jBPe: TJSONObject): TJSONObject;
var
  Lote: Int64;
  Imprimir: Boolean;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  try
    try
      Lote := jBPe.Get('Lote', 1);
      Imprimir := jBPe.Get('Imprimir', False);
      if facbr.Enviar(Lote, Imprimir) then
      begin
        Result.Add('status', 'sucesso');
        Result.Add('message', 'BPe enviado com sucesso.');
      end
      else
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Falha no envio BPe.');
      end;
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Erro ao enviar BPe: ' + E.Message);
      end;
    end;
  finally
  end;
end;

end.
