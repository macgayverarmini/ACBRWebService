unit method.acbr.boleto;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  TypInfo,
  Contnrs,
  ACBrBoleto,
  ACBrBoletoFPDF,
  ACBrBoletoConversao,
  ACBrUtil.Strings,
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

{ Normaliza genericamente strings via RTTI antes de PadRight em FPC UTF-8 quando RemoveAcentosArqRemessa = True }
procedure NormalizeAsciiObjectTree(const Root: TObject);
var
  Visited: TList;

  procedure Walk(const Cur: TObject);
  var
    Ctx: TRttiContext;
    RttiType: TRttiType;
    Props: TRttiPropertyArray;
    Prop: TRttiProperty;
    I: Integer;
    ChildObj: TObject;
    SVal, SClean: string;
  begin
    if (Cur = nil) or (Visited.IndexOf(Cur) >= 0) then
      Exit;
    Visited.Add(Cur);

    if Cur is TStrings then
    begin
      for I := 0 to TStrings(Cur).Count - 1 do
        TStrings(Cur)[I] := TiraAcentos(TStrings(Cur)[I]);
      Exit;
    end;

    if Cur is TCollection then
    begin
      for I := 0 to TCollection(Cur).Count - 1 do
        Walk(TCollection(Cur).Items[I]);
      Exit;
    end;

    if Cur is TObjectList then
    begin
      for I := 0 to TObjectList(Cur).Count - 1 do
        Walk(TObjectList(Cur).Items[I]);
      Exit;
    end;

    Ctx := TRttiContext.Create(False);
    try
      RttiType := Ctx.GetType(Cur.ClassType);
      if not Assigned(RttiType) then
        Exit;
      Props := RttiType.GetProperties;
      for I := 0 to Length(Props) - 1 do
      begin
        Prop := Props[I];
        if not Prop.IsReadable or not (Prop.Visibility in [mvPublic, mvPublished]) then
          Continue;
        try
          if Prop.PropertyType.TypeKind = tkClass then
          begin
            ChildObj := Prop.GetValue(Cur).AsObject;
            if Assigned(ChildObj) and not (ChildObj is TComponent) then
              Walk(ChildObj);
          end
          else if Prop.IsWritable and
                  (Prop.PropertyType.TypeKind in [tkString, tkUString, tkAString, tkWString]) then
          begin
            SVal := Prop.GetValue(Cur).AsString;
            if SVal <> '' then
            begin
              SClean := TiraAcentos(SVal);
              if SClean <> SVal then
                Prop.SetValue(Cur, TValue.From<string>(SClean));
            end;
          end;
        except
        end;
      end;
    finally
      Ctx.Free;
    end;
  end;

begin
  if Root = nil then
    Exit;
  Visited := TList.Create;
  try
    Walk(Root);
  finally
    Visited.Free;
  end;
end;

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

function TACBRModelosJSONBoleto.ModelPixQRCode: TJSONObject;
var
  LEMV: TACBrPIXQRCodeDinamico;
begin
  LEMV := TACBrPIXQRCodeDinamico.Create;
  try
    LEMV.IgnoreErrors := True;
    LEMV.MerchantName := 'EMPRESA RECEBEDORA LTDA';
    LEMV.MerchantCity := 'VITORIA';
    LEMV.PostalCode := '29010000';
    LEMV.URL := 'pix.exemplo.com/qr/v2/123456';
    LEMV.TxId := 'TXID123456789';
    LEMV.TransactionAmount := 150.00;
    Result := TJSONTools.SafeObjToJson(LEMV, 'Erro ao gerar modelo PIX QRCode');
  finally
    LEMV.Free;
  end;
end;

{ TACBRBridgeBoleto }

procedure TACBRBridgeBoleto.CarregaConfig(const AllowEmpty: Boolean);
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

procedure TACBRBridgeBoleto.PopularTitulos(const jPayload: TJSONObject);
var
  arrTitulos, objTitulo: TJSONData;
  arr: TJSONArray;
  I: Integer;
  Titulo: TACBrTitulo;
begin
  facbr.ListadeBoletos.Clear;

  arrTitulos := jPayload.Find('Titulos');
  if not Assigned(arrTitulos) then
    arrTitulos := jPayload.Find('titulos');

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

  objTitulo := jPayload.Find('Titulo');
  if not Assigned(objTitulo) then
    objTitulo := jPayload.Find('titulo');

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
  CarregaConfig;
  Result := TJSONObject.Create;
  Stream := TMemoryStream.Create;
  try
    try
      PopularTitulos(jRemessa);

      if facbr.RemoveAcentosArqRemessa then
      begin
        NormalizeAsciiObjectTree(facbr.Banco);
        NormalizeAsciiObjectTree(facbr.Cedente);
        NormalizeAsciiObjectTree(facbr.ListadeBoletos);
      end;

      numRemessa := jRemessa.Get('NumeroRemessa', 1);
      nomeArq := facbr.GerarRemessaStream(numRemessa, Stream);

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('banco_numero', facbr.Banco.Numero);
      Result.Add('tipo_cobranca', GetEnumName(TypeInfo(TACBrTipoCobranca), Ord(facbr.Banco.TipoCobranca)));
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
      facbr.LeCedenteRetorno := jRetorno.Get('LeCedenteRetorno', facbr.LeCedenteRetorno);
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

procedure TACBRBridgeBoleto.ConfigurarPixTitulo(Titulo: TACBrTitulo; const jTitulo: TJSONObject);
var
  jPixData: TJSONData;
  LEMV: TACBrPIXQRCodeDinamico;
  LIdx: Integer;
begin
  if not Assigned(Titulo) or not Assigned(jTitulo) then
    Exit;

  jPixData := jTitulo.Find('BRCode');
  if not Assigned(jPixData) then
    jPixData := jTitulo.Find('Pix');

  if (Titulo.QrCode.emv <> '') then
    Exit;

  if Copy(Titulo.QrCode.url, 1, 4) = '0002' then
  begin
    Titulo.QrCode.emv := Titulo.QrCode.url;
    Titulo.QrCode.url := '';
    Exit;
  end;

  LEMV := TACBrPIXQRCodeDinamico.Create;
  try
    LEMV.IgnoreErrors := True;
    LEMV.MerchantName := facbr.Cedente.Nome;
    LEMV.MerchantCity := facbr.Cedente.Cidade;
    LEMV.PostalCode := facbr.Cedente.CEP;
    LEMV.URL := Titulo.QrCode.url;
    LEMV.TxId := Titulo.QrCode.txId;
    LEMV.TransactionAmount := Titulo.ValorDocumento;

    if Assigned(jPixData) and (jPixData.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jPixData), LEMV);

    if Copy(LEMV.URL, 1, 4) = '0002' then
    begin
      Titulo.QrCode.emv := LEMV.URL;
      Titulo.QrCode.url := '';
      Titulo.QrCode.txId := LEMV.TxId;
      Exit;
    end;

    if LEMV.URL = '' then
      Exit;

    if Assigned(jPixData) and (jPixData.JSONType = jtObject) and
       TJSONObject(jPixData).Get('RemoverTag01', True) then
    begin
      LIdx := LEMV.IndexOfName('01');
      if LIdx >= 0 then
        LEMV.Delete(LIdx);
    end;

    Titulo.QrCode.emv := LEMV.AsString;
    Titulo.QrCode.url := LEMV.URL;
    Titulo.QrCode.txId := LEMV.TxId;
  finally
    LEMV.Free;
  end;
end;

function TACBRBridgeBoleto.GerarPixBrCode(const jPix: TJSONObject): TJSONObject;
var
  LEMV: TACBrPIXQRCodeDinamico;
  LIdx: Integer;
begin
  CarregaConfig(True);
  LEMV := TACBrPIXQRCodeDinamico.Create;
  try
    try
      LEMV.IgnoreErrors := True;
      LEMV.MerchantName := facbr.Cedente.Nome;
      LEMV.MerchantCity := facbr.Cedente.Cidade;
      LEMV.PostalCode := facbr.Cedente.CEP;
      TJSONTools.JsonToObj(jPix, LEMV);

      if Copy(LEMV.URL, 1, 4) = '0002' then
      begin
        LEMV.AsString := LEMV.URL;
      end
      else if jPix.Get('RemoverTag01', True) then
      begin
        LIdx := LEMV.IndexOfName('01');
        if LIdx >= 0 then
          LEMV.Delete(LIdx);
      end;

      Result := TJSONTools.SafeObjToJson(LEMV, 'Erro ao serializar PIX BRCode');
      if Assigned(Result) and (Result.Find(RSStatusField) = nil) then
      begin
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add('emv', LEMV.AsString);
      end;
    except
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Erro ao gerar PIX BRCode: ' + E.Message);
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
  CarregaConfig;
  Result := TJSONObject.Create;

  try
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
