unit method.acbr.boleto;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrBoleto,
  ACBrBoletoFPDF,
  ACBrBoletoConversao,
  ACBrUtil.Strings,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
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
    fBancoNumeroJson: Integer;
    procedure CarregaConfig;
    procedure ConfigurarPixTitulo(Titulo: TACBrTitulo; const jTitulo: TJSONObject);
    procedure PopularTitulos(const jPayload: TJSONObject);
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    function GerarPDF(const jBoleto: TJSONObject): TJSONObject;
    function GerarRemessa(const jRemessa: TJSONObject): TJSONObject;
    function LerRetorno(const jRetorno: TJSONObject): TJSONObject;
    function GerarPixBrCode(const jPix: TJSONObject): TJSONObject;
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
  O, jBancoObj: TJSONObject;
  jBancoNode, jNumNode: TJSONData;
  hasTipoCobranca: Boolean;
  vNumBanco: Integer;
  vCarteira: string;
begin
  if Trim(fcfg) = '' then
    Exit;
  O := GetJSON(fcfg) as TJSONObject;
  try
    hasTipoCobranca := False;
    vNumBanco := 0;
    jBancoObj := nil;
    jBancoNode := O.Find('Banco');
    if not Assigned(jBancoNode) then
      jBancoNode := O.Find('banco');
    if Assigned(jBancoNode) and (jBancoNode.JSONType = jtObject) then
    begin
      jBancoObj := TJSONObject(jBancoNode);
      hasTipoCobranca := Assigned(jBancoObj.Find('TipoCobranca')) or Assigned(jBancoObj.Find('tipoCobranca'));
      jNumNode := jBancoObj.Find('Numero');
      if not Assigned(jNumNode) then
        jNumNode := jBancoObj.Find('numero');
      if Assigned(jNumNode) then
      begin
        if jNumNode.JSONType = jtNumber then
          vNumBanco := jNumNode.AsInteger
        else
          vNumBanco := StrToIntDef(Trim(jNumNode.AsString), 0);
      end;
    end;
    if vNumBanco = 0 then
      vNumBanco := O.Get('BancoNumero', O.Get('bancoNumero', 0));
    if vNumBanco > 0 then
      fBancoNumeroJson := vNumBanco;

    TJSONTools.JsonToObj(O, facbr);

    if (not hasTipoCobranca) and (facbr.Banco.TipoCobranca = cobNenhum) and (fBancoNumeroJson > 0) then
    begin
      vCarteira := O.Get('Carteira', O.Get('carteira', ''));
      facbr.Banco.TipoCobranca := facbr.GetTipoCobranca(fBancoNumeroJson, vCarteira);
      if Assigned(jBancoObj) then
        TJSONTools.JsonToObj(jBancoObj, facbr.Banco);
    end;
  finally
    O.Free;
  end;
  fcfg := '';
end;

procedure SanitizarStringsCNAB(const facbr: TACBrBoleto);
var
  I, J: Integer;
  T: TACBrTitulo;
begin
  if not Assigned(facbr) then
    Exit;
  facbr.Cedente.Nome := TiraAcentos(facbr.Cedente.Nome);
  facbr.Cedente.FantasiaCedente := TiraAcentos(facbr.Cedente.FantasiaCedente);
  facbr.Cedente.Logradouro := TiraAcentos(facbr.Cedente.Logradouro);
  facbr.Cedente.NumeroRes := TiraAcentos(facbr.Cedente.NumeroRes);
  facbr.Cedente.Complemento := TiraAcentos(facbr.Cedente.Complemento);
  facbr.Cedente.Bairro := TiraAcentos(facbr.Cedente.Bairro);
  facbr.Cedente.Cidade := TiraAcentos(facbr.Cedente.Cidade);
  facbr.Banco.LocalPagamento := TiraAcentos(facbr.Banco.LocalPagamento);
  for J := 0 to facbr.Banco.OrientacoesBanco.Count - 1 do
    facbr.Banco.OrientacoesBanco[J] := TiraAcentos(facbr.Banco.OrientacoesBanco[J]);

  for I := 0 to facbr.ListadeBoletos.Count - 1 do
  begin
    T := facbr.ListadeBoletos[I];
    T.LocalPagamento := TiraAcentos(T.LocalPagamento);
    T.SeuNumero := TiraAcentos(T.SeuNumero);
    T.NumeroDocumento := TiraAcentos(T.NumeroDocumento);
    T.EspecieDoc := TiraAcentos(T.EspecieDoc);
    T.Instrucao1 := TiraAcentos(T.Instrucao1);
    T.Instrucao2 := TiraAcentos(T.Instrucao2);
    T.Instrucao3 := TiraAcentos(T.Instrucao3);
    T.Sacado.NomeSacado := TiraAcentos(T.Sacado.NomeSacado);
    T.Sacado.Logradouro := TiraAcentos(T.Sacado.Logradouro);
    T.Sacado.Numero := TiraAcentos(T.Sacado.Numero);
    T.Sacado.Complemento := TiraAcentos(T.Sacado.Complemento);
    T.Sacado.Bairro := TiraAcentos(T.Sacado.Bairro);
    T.Sacado.Cidade := TiraAcentos(T.Sacado.Cidade);
    T.Sacado.SacadoAvalista.NomeAvalista := TiraAcentos(T.Sacado.SacadoAvalista.NomeAvalista);
    for J := 0 to T.Mensagem.Count - 1 do
      T.Mensagem[J] := TiraAcentos(T.Mensagem[J]);
  end;
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
        ConfigurarPixTitulo(Titulo, TJSONObject(arr.Items[I]));
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
    ConfigurarPixTitulo(Titulo, TJSONObject(objTitulo));
  end
  else
  begin
    Titulo := facbr.CriarTituloNaLista;
    TJSONTools.JsonToObj(jPayload, Titulo);
    ConfigurarPixTitulo(Titulo, jPayload);
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
  numRemessa, layoutInt, I, vNumBanco: Integer;
  nomeArq, codBarras, linhaDig, nossoNum, vCart: string;
  arrOut: TJSONArray;
  itemOut: TJSONObject;
  T: TACBrTitulo;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Stream := TMemoryStream.Create;
  try
    try
      PopularTitulos(jRemessa);

      if (facbr.Banco.TipoCobranca = cobNenhum) and (fBancoNumeroJson > 0) then
      begin
        vCart := '';
        if facbr.ListadeBoletos.Count > 0 then
          vCart := facbr.ListadeBoletos[0].Carteira;
        facbr.Banco.TipoCobranca := facbr.GetTipoCobranca(fBancoNumeroJson, vCart);
      end;

      if jRemessa.Get('RetirarAcentos', True) then
        SanitizarStringsCNAB(facbr);

      layoutInt := jRemessa.Get('LayoutRemessa', -1);
      if layoutInt = 240 then
        facbr.LayoutRemessa := c240
      else if layoutInt = 400 then
        facbr.LayoutRemessa := c400;

      numRemessa := jRemessa.Get('NumeroRemessa', 1);
      nomeArq := facbr.GerarRemessaStream(numRemessa, Stream);

      Result.Add('status', 'sucesso');
      Result.Add('sucesso', True);
      Result.Add('banco_numero', facbr.Banco.Numero);
      Result.Add('tipo_cobranca', Integer(facbr.Banco.TipoCobranca));
      Result.Add('nome_arquivo', ExtractFileName(nomeArq));
      Result.Add('remessa_base64', StreamToBase64String(Stream));
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
        Result.Add('status', 'erro');
        Result.Add('sucesso', False);
        Result.Add(RSErrorField, 'Erro ao gerar remessa CNAB: ' + E.Message);
      end;
    end;
  finally
    Stream.Free;
  end;
end;

function TACBRBridgeBoleto.LerRetorno(const jRetorno: TJSONObject): TJSONObject;
var
  b64Retorno, rawRetorno, firstLine: string;
  Stream: TStringStream;
  SL: TStringList;
  arrTitulos: TJSONArray;
  I, layoutInt, codBancoHeader: Integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  b64Retorno := jRetorno.Get('arquivo_base64', '');
  if b64Retorno = '' then
    b64Retorno := jRetorno.Get('retorno_base64', '');

  if b64Retorno = '' then
  begin
    Result.Add('status', 'erro');
    Result.Add('sucesso', False);
    Result.Add(RSErrorField, 'Parametro "arquivo_base64" nao informado para leitura de retorno CNAB.');
    Exit;
  end;

  rawRetorno := DecodeStringBase64(b64Retorno);

  layoutInt := jRetorno.Get('LayoutRemessa', -1);
  if layoutInt = 240 then
    facbr.LayoutRemessa := c240
  else if layoutInt = 400 then
    facbr.LayoutRemessa := c400
  else
  begin
    SL := TStringList.Create;
    try
      SL.Text := rawRetorno;
      firstLine := '';
      for I := 0 to SL.Count - 1 do
        if Trim(SL[I]) <> '' then
        begin
          firstLine := SL[I];
          Break;
        end;
      if Length(firstLine) >= 380 then
        facbr.LayoutRemessa := c400
      else if Length(firstLine) >= 200 then
        facbr.LayoutRemessa := c240;

      if (facbr.Banco.TipoCobranca = cobNenhum) and (firstLine <> '') then
      begin
        if facbr.LayoutRemessa = c240 then
          codBancoHeader := StrToIntDef(Copy(firstLine, 1, 3), 0)
        else
          codBancoHeader := StrToIntDef(Copy(firstLine, 77, 3), 0);
        if codBancoHeader > 0 then
          facbr.Banco.TipoCobranca := facbr.GetTipoCobranca(codBancoHeader);
      end;
    finally
      SL.Free;
    end;
  end;

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
      Result.Add('sucesso', True);
      Result.Add('banco_numero', facbr.Banco.Numero);
      Result.Add('total_titulos', facbr.ListadeBoletos.Count);
      Result.Add('cedente', TJSONTools.SafeObjToJson(facbr.Cedente, 'Erro ao serializar cedente'));
      Result.Add('titulos', arrTitulos);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('sucesso', False);
        Result.Add(RSErrorField, 'Erro ao ler retorno CNAB: ' + E.Message);
      end;
    end;
  finally
    Stream.Free;
  end;
end;



function TACBRModelosJSONBoleto.ModelPixQRCode: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('urlQRCode', 'pix.exemplo.com/qr/v2/123456');
  Result.Add('txId', 'TXID123456789');
  Result.Add('MerchantName', 'EMPRESA RECEBEDORA LTDA');
  Result.Add('MerchantCity', 'VITORIA');
  Result.Add('ValorDocumento', 150.00);
  Result.Add('RemoverTag01', True);
end;

procedure TACBRBridgeBoleto.ConfigurarPixTitulo(Titulo: TACBrTitulo; const jTitulo: TJSONObject);
var
  jPixData: TJSONData;
  jPixObj: TJSONObject;
  urlQr, txIdStr, recNome, recCidade: string;
  removerTag01: Boolean;
  LEMV: TACBrPIXQRCodeDinamico;
  LIdx: Integer;
begin
  if not Assigned(Titulo) or not Assigned(jTitulo) then
    Exit;

  urlQr := Titulo.QrCode.url;
  txIdStr := Titulo.QrCode.txId;
  recNome := facbr.Cedente.Nome;
  recCidade := facbr.Cedente.Cidade;
  removerTag01 := True;

  jPixData := jTitulo.Find('pix');
  if not Assigned(jPixData) then
    jPixData := jTitulo.Find('Pix');

  if Assigned(jPixData) and (jPixData.JSONType = jtObject) then
  begin
    jPixObj := TJSONObject(jPixData);
    if urlQr = '' then
      urlQr := jPixObj.Get('urlQRCode', jPixObj.Get('url', ''));
    if txIdStr = '' then
      txIdStr := jPixObj.Get('txid', jPixObj.Get('txId', ''));
    recNome := jPixObj.Get('MerchantName', jPixObj.Get('banestes_recebedor_nome', recNome));
    recCidade := jPixObj.Get('MerchantCity', jPixObj.Get('banestes_recebedor_cidade', recCidade));
    removerTag01 := jPixObj.Get('RemoverTag01', True);
  end;

  if (Titulo.QrCode.emv <> '') or (urlQr = '') then
    Exit;

  if Copy(urlQr, 1, 4) = '0002' then
  begin
    Titulo.QrCode.emv := urlQr;
    Titulo.QrCode.url := '';
    Titulo.QrCode.txId := txIdStr;
    Exit;
  end;

  LEMV := TACBrPIXQRCodeDinamico.Create;
  try
    LEMV.IgnoreErrors := True;
    LEMV.MerchantName := recNome;
    LEMV.MerchantCity := recCidade;
    LEMV.URL := urlQr;
    LEMV.TransactionAmount := Titulo.ValorDocumento;
    if removerTag01 then
    begin
      LIdx := LEMV.IndexOfName('01');
      if LIdx >= 0 then
        LEMV.Delete(LIdx);
    end;
    Titulo.QrCode.emv := LEMV.AsString;
    Titulo.QrCode.url := urlQr;
    Titulo.QrCode.txId := txIdStr;
  finally
    LEMV.Free;
  end;
end;

function TACBRBridgeBoleto.GerarPixBrCode(const jPix: TJSONObject): TJSONObject;
var
  LEMV: TACBrPIXQRCodeDinamico;
  urlQr, txIdStr, recNome, recCidade, cepStr: string;
  valorDoc: Double;
  removerTag01: Boolean;
  LIdx: Integer;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  LEMV := TACBrPIXQRCodeDinamico.Create;
  try
    try
      urlQr := jPix.Get('urlQRCode', jPix.Get('url', ''));
      txIdStr := jPix.Get('txId', jPix.Get('txid', ''));
      recNome := jPix.Get('MerchantName', jPix.Get('banestes_recebedor_nome', facbr.Cedente.Nome));
      recCidade := jPix.Get('MerchantCity', jPix.Get('banestes_recebedor_cidade', facbr.Cedente.Cidade));
      cepStr := jPix.Get('PostalCode', '');
      valorDoc := jPix.Get('ValorDocumento', jPix.Get('TransactionAmount', 0.0));
      removerTag01 := jPix.Get('RemoverTag01', True);

      if Copy(urlQr, 1, 4) = '0002' then
      begin
        Result.Add('status', 'sucesso');
        Result.Add('emv', urlQr);
        Result.Add('url', '');
        Result.Add('txId', txIdStr);
        Exit;
      end;

      LEMV.IgnoreErrors := True;
      LEMV.MerchantName := recNome;
      LEMV.MerchantCity := recCidade;
      if cepStr <> '' then
        LEMV.PostalCode := cepStr;
      LEMV.URL := urlQr;
      LEMV.TransactionAmount := valorDoc;

      if removerTag01 then
      begin
        LIdx := LEMV.IndexOfName('01');
        if LIdx >= 0 then
          LEMV.Delete(LIdx);
      end;

      Result.Add('status', 'sucesso');
      Result.Add('emv', LEMV.AsString);
      Result.Add('url', urlQr);
      Result.Add('txId', txIdStr);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add(RSErrorField, 'Erro ao gerar PIX BRCode: ' + E.Message);
      end;
    end;
  finally
    LEMV.Free;
  end;
end;

function TACBRBridgeBoleto.EnviarWebService(const jPayload: TJSONObject): TJSONObject;
var
  operacaoStr, codBarras, linhaDig, nossoNum: string;
  enviado: Boolean;
  I: Integer;
  arrTitulos, arrRetornos: TJSONArray;
  itemOut, retOut: TJSONObject;
  T: TACBrTitulo;
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  try
    PopularTitulos(jPayload);

    operacaoStr := LowerCase(Trim(jPayload.Get('Operacao', jPayload.Get('operacao', ''))));
    if (operacaoStr = 'tpinclui') or (operacaoStr = 'inclui') or (operacaoStr = 'incluir') or (operacaoStr = '0') then
      facbr.Configuracoes.WebService.Operacao := tpInclui
    else if (operacaoStr = 'tpbaixa') or (operacaoStr = 'baixa') or (operacaoStr = 'baixar') or (operacaoStr = '2') then
      facbr.Configuracoes.WebService.Operacao := tpBaixa
    else if (operacaoStr = 'tpconsultadetalhe') or (operacaoStr = 'consultadetalhe') or (operacaoStr = 'consulta') or (operacaoStr = '4') then
      facbr.Configuracoes.WebService.Operacao := tpConsultaDetalhe
    else if (operacaoStr = 'tptera') or (operacaoStr = 'altera') or (operacaoStr = 'alterar') or (operacaoStr = '1') then
      facbr.Configuracoes.WebService.Operacao := tpAltera;

    enviado := facbr.Enviar;

    if enviado then
      Result.Add('status', 'sucesso')
    else
      Result.Add('status', 'erro');
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
      Result.Add('status', 'erro');
      Result.Add(RSErrorField, 'Erro ao enviar boleto via WebService: ' + E.Message);
    end;
  end;
end;

end.
