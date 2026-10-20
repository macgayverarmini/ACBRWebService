unit method.acbr.boleto;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrBoleto,
  ACBrBoletoFPDF,
  ACBrBoletoConversao,
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

  { TACBRBridgeBoleto }

  TACBRBridgeBoleto = class
  private
    fcfg: string;
    facbr: TACBrBoleto;
    fpdf: TACBrBoletoFPDF;
    procedure CarregaConfig;
    procedure PopularTitulos(const jPayload: TJSONObject);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function GerarPDF(const jBoleto: TJSONObject): TJSONObject;
    function GerarRemessa(const jRemessa: TJSONObject): TJSONObject;
    function LerRetorno(const jRetorno: TJSONObject): TJSONObject;
  end;

  { TACBRModelosJSONBoleto }

  TACBRModelosJSONBoleto = class(TACBRBridgeBoleto)
  public
    function ModelConfig: TJSONObject;
    function ModelTitulo: TJSONObject;
  end;

implementation

{ TACBRModelosJSONBoleto }

function TACBRModelosJSONBoleto.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr, 'Erro ao gerar modelo de configuracao do Boleto');
  if Assigned(Result) then
  begin
    Result.Delete('ListadeBoletos');
    Result.Delete('ACBrBoletoFC');
  end;
end;

function TACBRModelosJSONBoleto.ModelTitulo: TJSONObject;
var
  Titulo: TACBrTitulo;
begin
  facbr.ListadeBoletos.Clear;
  Titulo := facbr.CriarTituloNaLista;
  Result := TJSONTools.SafeObjToJson(Titulo, 'Erro ao gerar modelo de Titulo do Boleto');
  facbr.ListadeBoletos.Clear;
end;

{ TACBRBridgeBoleto }

procedure TACBRBridgeBoleto.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then
    Exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    TJSONTools.JsonToObj(O, facbr);
  finally
    O.Free;
  end;
  fcfg := '';
end;

procedure TACBRBridgeBoleto.PopularTitulos(const jPayload: TJSONObject);
var
  arrTitulos: TJSONData;
  objTitulo: TJSONData;
  arr: TJSONArray;
  I: Integer;
  Titulo: TACBrTitulo;
begin
  facbr.ListadeBoletos.Clear;

  arrTitulos := jPayload.Find('titulos');
  if not Assigned(arrTitulos) then
    arrTitulos := jPayload.Find('Titulos');

  if Assigned(arrTitulos) and (arrTitulos.JSONType = jtArray) then
  begin
    arr := TJSONArray(arrTitulos);
    for I := 0 to arr.Count - 1 do
    begin
      if arr.Items[I].JSONType = jtObject then
      begin
        Titulo := facbr.CriarTituloNaLista;
        TJSONTools.JsonToObj(TJSONObject(arr.Items[I]), Titulo);
      end;
    end;
    Exit;
  end;

  objTitulo := jPayload.Find('titulo');
  if not Assigned(objTitulo) then
    objTitulo := jPayload.Find('Titulo');

  if Assigned(objTitulo) and (objTitulo.JSONType = jtObject) then
  begin
    Titulo := facbr.CriarTituloNaLista;
    TJSONTools.JsonToObj(TJSONObject(objTitulo), Titulo);
  end
  else
  begin
    Titulo := facbr.CriarTituloNaLista;
    TJSONTools.JsonToObj(jPayload, Titulo);
  end;
end;

constructor TACBRBridgeBoleto.Create(const Cfg: string);
begin
  inherited Create;
  facbr := TACBrBoleto.Create(nil);
  fpdf := TACBrBoletoFPDF.Create(nil);
  facbr.ACBrBoletoFC := fpdf;
  fcfg := Cfg;
end;

destructor TACBRBridgeBoleto.Destroy;
begin
  FreeAndNil(facbr);
  FreeAndNil(fpdf);
  inherited Destroy;
end;

function TACBRBridgeBoleto.GerarPDF(const jBoleto: TJSONObject): TJSONObject;
var
  pdfDir, fileName, b64Pdf, codBarras, linhaDig, nossoNum: string;
  tamanho, I: Integer;
  arrOut: TJSONArray;
  itemOut: TJSONObject;
  T: TACBrTitulo;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  try
    PopularTitulos(jBoleto);

    if facbr.ListadeBoletos.Count = 0 then
    begin
      Result.Add(RSErrorField, 'Nenhum titulo informado para geracao de boleto.');
      Exit;
    end;

    pdfDir := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;
    if not DirectoryExists(pdfDir) then
      CreateDir(pdfDir);

    fileName := pdfDir + 'boleto_' + IntToStr(GetTickCount64) + '.pdf';
    fpdf.MostrarPreview := False;
    fpdf.MostrarSetup := False;
    fpdf.MostrarProgresso := False;
    fpdf.NomeArquivo := fileName;

    facbr.GerarPDF;

    if not FileExists(fileName) then
    begin
      Result.Add(RSErrorField, 'Arquivo PDF do boleto nao foi gerado.');
      Exit;
    end;

    b64Pdf := FileToStringBase64(fileName, True, tamanho);
    Result.Add('status', 'sucesso');
    Result.Add(RSPDFField, b64Pdf);
    Result.Add(RSTamanhoField, IntToStr(tamanho));

    arrOut := TJSONArray.Create;
    for I := 0 to facbr.ListadeBoletos.Count - 1 do
    begin
      T := facbr.ListadeBoletos[I];
      codBarras := facbr.Banco.MontarCodigoBarras(T);
      linhaDig := facbr.Banco.MontarLinhaDigitavel(codBarras, T);
      nossoNum := facbr.Banco.MontarCampoNossoNumero(T);

      itemOut := TJSONObject.Create;
      itemOut.Add('nosso_numero', nossoNum);
      itemOut.Add('codigo_barras', codBarras);
      itemOut.Add('linha_digitavel', linhaDig);
      itemOut.Add('numero_documento', T.NumeroDocumento);
      arrOut.Add(itemOut);

      if I = 0 then
      begin
        Result.Add('nosso_numero', nossoNum);
        Result.Add('codigo_barras', codBarras);
        Result.Add('linha_digitavel', linhaDig);
      end;
    end;
    Result.Add('titulos', arrOut);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add(RSErrorField, 'Erro ao gerar PDF do boleto: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeBoleto.GerarRemessa(const jRemessa: TJSONObject): TJSONObject;
var
  Stream: TMemoryStream;
  numRemessa, layoutInt: Integer;
  nomeArq: string;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Stream := TMemoryStream.Create;
  try
    try
      PopularTitulos(jRemessa);

      layoutInt := jRemessa.Get('LayoutRemessa', -1);
      if layoutInt = 240 then
        facbr.LayoutRemessa := c240
      else if layoutInt = 400 then
        facbr.LayoutRemessa := c400;

      numRemessa := jRemessa.Get('NumeroRemessa', 1);
      nomeArq := facbr.GerarRemessaStream(numRemessa, Stream);

      Result.Add('status', 'sucesso');
      Result.Add('nome_arquivo', ExtractFileName(nomeArq));
      Result.Add('remessa_base64', StreamToBase64String(Stream));
      Result.Add('total_titulos', facbr.ListadeBoletos.Count);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add(RSErrorField, 'Erro ao gerar remessa CNAB: ' + E.Message);
      end;
    end;
  finally
    Stream.Free;
  end;
end;

function TACBRBridgeBoleto.LerRetorno(const jRetorno: TJSONObject): TJSONObject;
var
  b64Retorno, rawRetorno: string;
  Stream: TStringStream;
  arrTitulos: TJSONArray;
  I: Integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  b64Retorno := jRetorno.Get('arquivo_base64', '');
  if b64Retorno = '' then
    b64Retorno := jRetorno.Get('retorno_base64', '');

  if b64Retorno = '' then
  begin
    Result.Add('status', 'erro');
    Result.Add(RSErrorField, 'Parametro "arquivo_base64" nao informado para leitura de retorno CNAB.');
    Exit;
  end;

  rawRetorno := DecodeStringBase64(b64Retorno);
  Stream := TStringStream.Create(rawRetorno);
  try
    try
      facbr.LeCedenteRetorno := jRetorno.Get('LeCedenteRetorno', True);
      facbr.LerRetorno(Stream);

      arrTitulos := TJSONArray.Create;
      for I := 0 to facbr.ListadeBoletos.Count - 1 do
      begin
        arrTitulos.Add(TJSONTools.SafeObjToJson(facbr.ListadeBoletos[I], 'Erro ao serializar titulo do retorno'));
      end;

      Result.Add('status', 'sucesso');
      Result.Add('total_titulos', facbr.ListadeBoletos.Count);
      Result.Add('cedente', TJSONTools.SafeObjToJson(facbr.Cedente, 'Erro ao serializar cedente'));
      Result.Add('titulos', arrTitulos);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add(RSErrorField, 'Erro ao ler retorno CNAB: ' + E.Message);
      end;
    end;
  finally
    Stream.Free;
  end;
end;

end.
