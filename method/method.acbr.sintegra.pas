unit method.acbr.sintegra;

{$mode Delphi}
{$M+}

interface

uses
  ACBrSintegra,
  fpjson,
  jsonconvert,
  jsonparser,
  streamtools,
  SysUtils,
  resource.strings.global,
  resource.strings.msg;

type
  TACBRBridgeSintegra = class
  private
    fcfg: string;
    facbr: TACBrSintegra;
    procedure CarregaConfig(const AllowEmpty: Boolean = True);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;
    function Sintegra(const jSintegra: TJSONObject): TJSONObject;
    function Gerar(const jSintegra: TJSONObject): TJSONObject;
  end;

  TACBRModelosJSONSintegra = class(TACBRBridgeSintegra)
  public
    function ModelConfig: TJSONObject;
    function ModelGerar: TJSONObject;
  end;

implementation

{ TACBRModelosJSONSintegra }

function TACBRModelosJSONSintegra.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr);
end;

function TACBRModelosJSONSintegra.ModelGerar: TJSONObject;
begin
  facbr.LimparRegistros;
  Result := TJSONTools.SafeObjToJson(facbr);
end;

{ TACBRBridgeSintegra }

procedure TACBRBridgeSintegra.CarregaConfig(const AllowEmpty: Boolean);
var
  O: TJSONObject;
begin
  if (Trim(fcfg) = '') and (not AllowEmpty) then
    raise Exception.Create(RSConfigEmptyError);

  if Trim(fcfg) <> '' then
  begin
    O := GetJSON(fcfg) as TJSONObject;
    try
      TJSONTools.JsonToObj(O, facbr);
    finally
      O.Free;
    end;
    fcfg := '';
  end;
end;

constructor TACBRBridgeSintegra.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrSintegra.Create(nil);
  fcfg := Cfg;
end;

destructor TACBRBridgeSintegra.Destroy;
begin
  FreeAndNil(facbr);
  inherited Destroy;
end;

function TACBRBridgeSintegra.Sintegra(const jSintegra: TJSONObject): TJSONObject;
begin
  CarregaConfig(True);
  Result := TJSONObject.Create;
  Result.Add(RSStatusField, RSStatusSucesso);
  Result.Add(RSMessageField, 'ACBr Sintegra inicializado com sucesso.');
end;

function TACBRBridgeSintegra.Gerar(const jSintegra: TJSONObject): TJSONObject;
var
  tamanho: Integer;
  isTempFile: Boolean;
  jData: TJSONObject;
  jNode: TJSONData;
  tmpDir: string;
begin
  Result := TJSONObject.Create;
  isTempFile := False;
  try
    try
      CarregaConfig(True);

      if Trim(facbr.FileName) = '' then
      begin
        isTempFile := True;
        tmpDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim;
        facbr.FileName := BuildUniqueTempFilePath(tmpDir, 'sintegra_', '.txt');
      end;

      jData := jSintegra;
      if Assigned(jSintegra) then
      begin
        jNode := jSintegra.Find('sintegra');
        if Assigned(jNode) and (jNode is TJSONObject) then
          jData := TJSONObject(jNode);
      end;

      facbr.LimparRegistros;
      TJSONTools.JsonToObj(jData, facbr);
      facbr.GeraArquivo;

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add(RSMessageField, 'Sintegra gerado com sucesso.');
      Result.Add('arquivo', facbr.FileName);
      if FileExists(facbr.FileName) then
      begin
        Result.Add('arquivo_base64', FileToStringBase64(facbr.FileName, isTempFile, tamanho));
        Result.Add(RSTamanhoField, tamanho);
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao gerar Sintegra: ' + E.Message);
      end;
    end;
  finally
    if isTempFile and (facbr.FileName <> '') and FileExists(facbr.FileName) then
      SysUtils.DeleteFile(facbr.FileName);
    facbr.LimparRegistros;
  end;
end;

end.
