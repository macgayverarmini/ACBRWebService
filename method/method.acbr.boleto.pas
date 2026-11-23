unit method.acbr.boleto;

{$mode Delphi}
{$M+}

interface

uses
  TypInfo,
  ACBrBoleto,
  ACBrBoletoFPDF,
  ACBrBoletoConversao,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes,
  SysUtils,
  streamtools,
  resource.strings.global,
  resource.strings.msg,
  ACBrPIXBRCode;

type

  { TACBRBridgeBoleto }

  TACBRBridgeBoleto = class
  private
    fcfg: string;
    facbr: TACBrBoleto;
    fpdf: TACBrBoletoFPDF;
    procedure CarregaConfig(const AllowEmpty: Boolean = False);
    procedure PopularTitulos(const jPayload: TJSONObject);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function GerarPDF(const jBoleto: TJSONObject): TJSONObject;
    function GerarRemessa(const jRemessa: TJSONObject): TJSONObject;
    function LerRetorno(const jRetorno: TJSONObject): TJSONObject;
    function GerarPixQRCode(const jPix: TJSONObject): TJSONObject;
    function EnviarWebService(const jPayload: TJSONObject): TJSONObject;
  end;

  { TACBRModelosJSONBoleto }

  TACBRModelosJSONBoleto = class(TACBRBridgeBoleto)
  public
    function ModelConfig: TJSONObject;
    function ModelTitulo: TJSONObject;
    function ModelPixQRCode: TJSONObject;
  end;

implementation

{ TACBRModelosJSONBoleto }

function TACBRModelosJSONBoleto.ModelConfig: TJSONObject;
begin
  Result := TJSONTools.SafeObjToJson(facbr, 'Erro ao gerar modelo de configuracao do Boleto');
  if Assigned(Result) then
    Result.Delete('ListadeBoletos');
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

function TACBRModelosJSONBoleto.ModelPixQRCode: TJSONObject;
var
  LEMV: TACBrPIXQRCodeDinamico;
begin
  LEMV := TACBrPIXQRCodeDinamico.Create;
  try
    Result := TJSONTools.SafeObjToJson(LEMV, 'Erro ao gerar modelo PIX QRCode');
  finally
    LEMV.Free;
  end;
end;

{ TACBRBridgeBoleto }

procedure TACBRBridgeBoleto.CarregaConfig(const AllowEmpty: Boolean);
var
  LData: TJSONData;
begin
  if (Trim(fcfg) = '') and (not AllowEmpty) then
    raise Exception.Create(RSConfigEmptyError);

  if Trim(fcfg) <> '' then
  begin
    LData := GetJSON(fcfg);
    try
      if LData is TJSONObject then
        TJSONTools.JsonToObj(TJSONObject(LData), facbr)
      else
        raise Exception.Create(RSNotJSONObjectError);
    finally
      LData.Free;
    end;
    fcfg := '';
  end;
end;

procedure TACBRBridgeBoleto.PopularTitulos(const jPayload: TJSONObject);
var
  arrTitulos, objTitulo: TJSONData;
  arr: TJSONArray;
  I: Integer;
  Titulo: TACBrTitulo;
begin
  facbr.ListadeBoletos.Clear;
  if not Assigned(jPayload) then
    Exit;

  arrTitulos := jPayload.Find('Titulos');
  if not Assigned(arrTitulos) then
    arrTitulos := jPayload.Find('titulos');
  if not Assigned(arrTitulos) then
    arrTitulos := jPayload.Find('ListadeBoletos');

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

  objTitulo := jPayload.Find('Titulo');
  if not Assigned(objTitulo) then
    objTitulo := jPayload.Find('titulo');

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
  Result := TJSONObject.Create;
  try
    CarregaConfig;
    if Assigned(jBoleto) then
      TJSONTools.JsonToObj(jBoleto, facbr);
    PopularTitulos(jBoleto);

    if facbr.ListadeBoletos.Count = 0 then
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, 'Nenhum titulo informado para geracao de boleto.');
      Exit;
    end;

    pdfDir := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
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
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, 'Arquivo PDF do boleto nao foi gerado.');
      Exit;
    end;

    b64Pdf := FileToStringBase64(fileName, True, tamanho);
    Result.Add(RSStatusField, RSStatusSucesso);
    Result.Add(RSPDFField, b64Pdf);
    Result.Add(RSTamanhoField, tamanho);

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
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, 'Erro ao gerar PDF do boleto: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeBoleto.GerarRemessa(const jRemessa: TJSONObject): TJSONObject;
var
  Stream: TMemoryStream;
  numRemessa, I: Integer;
  nomeArq, codBarras, linhaDig, nossoNum: string;
  arrOut: TJSONArray;
  itemOut: TJSONObject;
  T: TACBrTitulo;
begin
  Result := TJSONObject.Create;
  Stream := TMemoryStream.Create;
  try
    try
      CarregaConfig;
      if Assigned(jRemessa) then
        TJSONTools.JsonToObj(jRemessa, facbr);
      PopularTitulos(jRemessa);

      numRemessa := jRemessa.Get('NumeroRemessa', 1);
      nomeArq := facbr.GerarRemessaStream(numRemessa, Stream);

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('banco_numero', facbr.Banco.Numero);
      Result.Add('tipo_cobranca', GetEnumName(TypeInfo(TACBrTipoCobranca), Ord(facbr.Banco.TipoCobranca)));
      Result.Add('nome_arquivo', ExtractFileName(nomeArq));
      Result.Add('remessa_base64', StreamToBase64String(Stream));
      Result.Add(RSTamanhoField, Stream.Size);
      Result.Add('total_titulos', facbr.ListadeBoletos.Count);

      arrOut := TJSONArray.Create;
      for I := 0 to facbr.ListadeBoletos.Count - 1 do
      begin
        T := facbr.ListadeBoletos[I];
        codBarras := facbr.Banco.MontarCodigoBarras(T);
        linhaDig := facbr.Banco.MontarLinhaDigitavel(codBarras, T);
        nossoNum := facbr.Banco.MontarCampoNossoNumero(T);
        itemOut := TJSONObject.Create;
        itemOut.Add('nosso_numero', nossoNum);
        itemOut.Add('nosso_numero_puro', T.NossoNumero);
        itemOut.Add('codigo_barras', codBarras);
        itemOut.Add('linha_digitavel', linhaDig);
        itemOut.Add('numero_documento', T.NumeroDocumento);
        arrOut.Add(itemOut);
      end;
      Result.Add('titulos', arrOut);
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
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
  Result := TJSONObject.Create;
  try
    CarregaConfig;
    if Assigned(jRetorno) then
      TJSONTools.JsonToObj(jRetorno, facbr);

    b64Retorno := jRetorno.Get('arquivo_base64', '');
    if b64Retorno = '' then
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, 'Parametro "arquivo_base64" nao informado para leitura de retorno CNAB.');
      Exit;
    end;

    rawRetorno := DecodeStringBase64(b64Retorno);
    Stream := TStringStream.Create(rawRetorno);
    try
      facbr.LerRetorno(Stream);

      arrTitulos := TJSONArray.Create;
      for I := 0 to facbr.ListadeBoletos.Count - 1 do
        arrTitulos.Add(TJSONTools.SafeObjToJson(facbr.ListadeBoletos[I], 'Erro ao serializar titulo do retorno'));

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('banco_numero', facbr.Banco.Numero);
      Result.Add('total_titulos', facbr.ListadeBoletos.Count);
      Result.Add('cedente', TJSONTools.SafeObjToJson(facbr.Cedente, 'Erro ao serializar cedente'));
      Result.Add('titulos', arrTitulos);
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, 'Erro ao ler retorno CNAB: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeBoleto.GerarPixQRCode(const jPix: TJSONObject): TJSONObject;
var
  LEMV: TACBrPIXQRCodeDinamico;
  emvStr: string;
begin
  CarregaConfig(True);
  LEMV := TACBrPIXQRCodeDinamico.Create;
  try
    try
      if facbr.Cedente.Nome <> '' then
        LEMV.MerchantName := facbr.Cedente.Nome;
      if facbr.Cedente.Cidade <> '' then
        LEMV.MerchantCity := facbr.Cedente.Cidade;
      if facbr.Cedente.CEP <> '' then
        LEMV.PostalCode := facbr.Cedente.CEP;
      TJSONTools.JsonToObj(jPix, LEMV);

      emvStr := LEMV.AsString;
      Result := TJSONTools.SafeObjToJson(LEMV, 'Erro ao serializar PIX QRCode');
      if Assigned(Result) then
      begin
        if Result.Find(RSStatusField) = nil then
          Result.Add(RSStatusField, RSStatusSucesso);
        if Result.Find('emv') = nil then
          Result.Add('emv', emvStr);
      end;
    except
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Erro ao gerar PIX QRCode: ' + E.Message);
      end;
    end;
  finally
    LEMV.Free;
  end;
end;

function TACBRBridgeBoleto.EnviarWebService(const jPayload: TJSONObject): TJSONObject;
var
  codBarras, linhaDig, nossoNum: string;
  enviado: Boolean;
  I: Integer;
  arrTitulos, arrRetornos: TJSONArray;
  itemOut, retOut: TJSONObject;
  T: TACBrTitulo;
begin
  Result := TJSONObject.Create;
  try
    CarregaConfig;
    TJSONTools.JsonToObj(jPayload, facbr.Configuracoes.WebService);
    PopularTitulos(jPayload);

    enviado := facbr.Enviar;

    if enviado then
      Result.Add(RSStatusField, RSStatusSucesso)
    else
      Result.Add(RSStatusField, RSStatusErro);
    Result.Add('enviado', enviado);
    Result.Add('total_retornos', facbr.TotalListaRetornoWeb);

    arrRetornos := TJSONArray.Create;
    for I := 0 to facbr.TotalListaRetornoWeb - 1 do
    begin
      retOut := TJSONTools.SafeObjToJson(facbr.ListaRetornoWeb[I], 'Erro ao serializar retorno web do boleto');
      arrRetornos.Add(retOut);
    end;
    Result.Add('retornos', arrRetornos);

    arrTitulos := TJSONArray.Create;
    for I := 0 to facbr.ListadeBoletos.Count - 1 do
    begin
      T := facbr.ListadeBoletos[I];
      codBarras := facbr.Banco.MontarCodigoBarras(T);
      linhaDig := facbr.Banco.MontarLinhaDigitavel(codBarras, T);
      nossoNum := facbr.Banco.MontarCampoNossoNumero(T);

      itemOut := TJSONObject.Create;
      itemOut.Add('nosso_numero', nossoNum);
      itemOut.Add('nosso_numero_correspondente', T.NossoNumeroCorrespondente);
      itemOut.Add('codigo_barras', codBarras);
      itemOut.Add('linha_digitavel', linhaDig);
      itemOut.Add('numero_documento', T.NumeroDocumento);
      if I < facbr.TotalListaRetornoWeb then
        itemOut.Add('estado_titulo_cobranca', facbr.ListaRetornoWeb[I].DadosRet.TituloRet.EstadoTituloCobranca)
      else
        itemOut.Add('estado_titulo_cobranca', '');
      itemOut.Add('qrcode_txid', T.QrCode.txId);
      itemOut.Add('qrcode_emv', T.QrCode.emv);
      itemOut.Add('qrcode_url', T.QrCode.url);
      arrTitulos.Add(itemOut);

      if I = 0 then
      begin
        Result.Add('nosso_numero', nossoNum);
        Result.Add('codigo_barras', codBarras);
        Result.Add('linha_digitavel', linhaDig);
        if facbr.TotalListaRetornoWeb > 0 then
          Result.Add('estado_titulo_cobranca', facbr.ListaRetornoWeb[0].DadosRet.TituloRet.EstadoTituloCobranca)
        else
          Result.Add('estado_titulo_cobranca', '');
        Result.Add('qrcode_txid', T.QrCode.txId);
        Result.Add('qrcode_emv', T.QrCode.emv);
        Result.Add('qrcode_url', T.QrCode.url);
      end;
    end;
    Result.Add('titulos', arrTitulos);
  except
    on E: Exception do
    begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, 'Erro ao enviar boleto via WebService: ' + E.Message);
    end;
  end;
end;

end.
