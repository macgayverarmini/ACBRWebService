unit TestDiversos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser,
  Base64, TestBase;

type
  { TTestDiversos }
  TTestDiversos = class(TTestBase)
  published
    procedure TestGetModeloExtenso;
    procedure TestGetModelosDiversosEBoleto;
    procedure TestPostTraduzValor;
    procedure TestGetModeloValidador;
    procedure TestPostValidar;
    procedure TestPostCargaBalancaToledoMGV6;
    procedure TestPostEscPosSpoolBuffer;
    procedure TestPostGNREToXML;
    procedure TestPostSintegra126Colunas;
    procedure TestPostBoletoRemessaCNAB240;
    procedure TestPostSpedPisCofinsOmitBlocoPSemDados;
    procedure TestPostCargaBalancaFilizolaSetorIndex;
  end;

implementation

{ TTestDiversos }

procedure TTestDiversos.TestGetModeloExtenso;
begin
  ExecuteGetTest('/modelo/diversos/extenso');
end;

procedure TTestDiversos.TestGetModelosDiversosEBoleto;
begin
  ExecuteGetTest('/modelo/diversos/cmc7');
  ExecuteGetTest('/modelo/diversos/balanca/instore');
  ExecuteGetTest('/modelo/diversos/balanca/carga');
  ExecuteGetTest('/modelo/diversos/ibpt/config');
  ExecuteGetTest('/modelo/diversos/ead');
  ExecuteGetTest('/modelo/diversos/calc-digito');
  ExecuteGetTest('/modelo/diversos/mail');
  ExecuteGetTest('/modelo/boleto/pix-qrcode');
  ExecuteGetTest('/modelo/certificados/upload');
end;

procedure TTestDiversos.TestPostTraduzValor;
var
  Client: TFPHTTPClient;
  Response: String;
  Json, RespJson: TJSONObject;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('Valor', 123.45);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/diversos/extenso');
      finally
        Client.RequestBody.Free;
      end;
      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertTrue('Texto por extenso nao deve ser vazio', RespJson.Get('Texto', '') <> '');
      finally
        RespJson.Free;
      end;
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestGetModeloValidador;
begin
  ExecuteGetTest('/modelo/diversos/validador');
end;

procedure TTestDiversos.TestPostValidar;
var
  Client: TFPHTTPClient;
  Response: String;
  Json: TJSONObject;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('TipoDocto', 'docCPF');
      Json.Add('Documento', '12345678909');
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/diversos/validador');
      finally
        Client.RequestBody.Free;
      end;
      AssertEquals('Status code mismatch', 200, Client.ResponseStatusCode);
      AssertTrue('Expected boolean JSON response',
        (LowerCase(Trim(Response)) = 'true') or (LowerCase(Trim(Response)) = 'false'));
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostCargaBalancaToledoMGV6;
var
  Client: TFPHTTPClient;
  Response: String;
  Payload, ProdItem, RespJson: TJSONObject;
  ArrProd: TJSONArray;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('Modelo', 'modToledoMGV6');
      ArrProd := TJSONArray.Create;
      ProdItem := TJSONObject.Create;
      ProdItem.Add('Codigo', 101);
      ProdItem.Add('Descricao', 'PRODUTO EXEMPLO KG');
      ProdItem.Add('ValorVenda', 19.90);
      ProdItem.Add('Validade', 5);
      ProdItem.Add('Tipo', 'tpvPeso');
      ProdItem.Add('TipoValidade', 'tpvDias');
      ArrProd.Add(ProdItem);
      Payload.Add('Produtos', ArrProd);

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/diversos/balanca/carga');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('Carga balanca deve retornar status sucesso', 'sucesso', RespJson.Get('status', ''));
        AssertNotNull('Deve retornar lista de arquivos gerados', RespJson.Find('arquivos'));
      finally
        RespJson.Free;
      end;
    finally
      Payload.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostEscPosSpoolBuffer;
var
  Client: TFPHTTPClient;
  Response: String;
  Payload, RespJson: TJSONObject;
  BufferArr: TJSONArray;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('Modelo', 'ppEscPosEpson');
      Payload.Add('PaginaDeCodigo', 'pc850');
      Payload.Add('Porta', '');
      BufferArr := TJSONArray.Create;
      BufferArr.Add('</zera><ce>EMPRESA EXEMPLO LTDA</ce>');
      BufferArr.Add('</corte_parcial>');
      Payload.Add('Buffer', BufferArr);

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/escpos/escpos');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('EscPos spool deve retornar status sucesso', 'sucesso', RespJson.Get('status', ''));
        AssertEquals('Modelo RTTI deve ser ppEscPosEpson', 'ppEscPosEpson', RespJson.Get('modelo', ''));
        AssertTrue('spool_base64 nao deve ser vazio', RespJson.Get('spool_base64', '') <> '');
      finally
        RespJson.Free;
      end;
    finally
      Payload.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostGNREToXML;
var
  Client: TFPHTTPClient;
  Response, DecodedXml: String;
  Payload, CfgObj, GeralObj, RespJson: TJSONObject;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      CfgObj := CreateConfigJSON;
      GeralObj := CfgObj.Find('Geral') as TJSONObject;
      if Assigned(GeralObj) then
        GeralObj.Strings['VersaoDF'] := 've200';
      Payload.Add('config', CfgObj);

      Payload.Add('c01_UfFavorecida', 'SP');
      Payload.Add('c02_receita', 100099);
      Payload.Add('c27_tipoIdentificacaoEmitente', 1);
      Payload.Add('c03_idContribuinteEmitente', '12345678000195');
      Payload.Add('c28_tipoDocOrigem', 10);
      Payload.Add('c04_docOrigem', '1001');
      Payload.Add('c06_valorPrincipal', 100.00);
      Payload.Add('c10_valorTotal', 100.00);
      Payload.Add('c14_dataVencimento', '2026-12-31');
      Payload.Add('c33_dataPagamento', '2026-12-31');
      Payload.Add('c16_razaoSocialEmitente', 'EMPRESA EXEMPLO LTDA');
      Payload.Add('c18_enderecoEmitente', 'AVENIDA EXEMPLO, 1000');
      Payload.Add('c19_municipioEmitente', '50308');
      Payload.Add('c20_ufEnderecoEmitente', 'SP');
      Payload.Add('c21_cepEmitente', '01001000');

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/gnre/gnre-to-xml');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('GNREToXML deve retornar status sucesso', 'sucesso', RespJson.Get('status', ''));
        DecodedXml := DecodeStringBase64(RespJson.Get('xml', ''));
        AssertTrue('XML GNRE deve conter TDadosGNRE', Pos('TDadosGNRE', DecodedXml) > 0);
      finally
        RespJson.Free;
      end;
    finally
      Payload.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostSintegra126Colunas;
var
  Client: TFPHTTPClient;
  Response, RawTxt: String;
  Payload, Reg10, Reg11, RespJson: TJSONObject;
  SL: TStringList;
  I: Integer;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('VersaoValidador', 'vv524');
      Reg10 := TJSONObject.Create;
      Reg10.Add('CNPJ', '12345678000195');
      Reg10.Add('Inscricao', '110042490114');
      Reg10.Add('RazaoSocial', 'EMPRESA EXEMPLO COMERCIO E INDUSTRIA LTDA');
      Reg10.Add('Cidade', 'SAO PAULO');
      Reg10.Add('Estado', 'SP');
      Reg10.Add('Telefone', '1130000000');
      Reg10.Add('DataInicial', '2026-01-01');
      Reg10.Add('DataFinal', '2026-01-31');
      Reg10.Add('CodigoConvenio', '3');
      Reg10.Add('NaturezaInformacoes', '3');
      Reg10.Add('FinalidadeArquivo', '1');
      Payload.Add('Registro10', Reg10);

      Reg11 := TJSONObject.Create;
      Reg11.Add('Endereco', 'AVENIDA EXEMPLO CONCEICAO');
      Reg11.Add('Numero', '1000');
      Reg11.Add('Bairro', 'CENTRO');
      Reg11.Add('Cep', '01001000');
      Reg11.Add('Responsavel', 'RESPONSAVEL TECNICO');
      Reg11.Add('Telefone', '1130000000');
      Payload.Add('Registro11', Reg11);

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/sintegra/gerar');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('Sintegra status deve ser sucesso', 'sucesso', RespJson.Get('status', ''));
        RawTxt := DecodeStringBase64(RespJson.Get('arquivo_base64', ''));
        AssertTrue('Sintegra TXT nao deve ser vazio', RawTxt <> '');
        SL := TStringList.Create;
        try
          SL.Text := RawTxt;
          AssertTrue('Sintegra deve ter ao menos 3 linhas (10, 11, 90)', SL.Count >= 3);
          for I := 0 to SL.Count - 1 do
            if SL[I] <> '' then
              AssertEquals('Linha ' + IntToStr(I) + ' deve ter exatamente 126 colunas', 126, Length(SL[I]));
        finally
          SL.Free;
        end;
      finally
        RespJson.Free;
      end;
    finally
      Payload.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostBoletoRemessaCNAB240;
var
  Client: TFPHTTPClient;
  Response: String;
  Payload, CfgObj, BancoObj, CedenteObj, TitObj, SacadoObj, RespJson: TJSONObject;
  ArrTit: TJSONArray;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      CfgObj := TJSONObject.Create;
      CfgObj.Add('LayoutRemessa', 'c240');
      CfgObj.Add('RemoveAcentosArqRemessa', True);

      BancoObj := TJSONObject.Create;
      BancoObj.Add('Numero', 1);
      BancoObj.Add('TipoCobranca', 'cobBancoDoBrasil');
      CfgObj.Add('Banco', BancoObj);

      CedenteObj := TJSONObject.Create;
      CedenteObj.Add('Nome', 'EMPRESA EXEMPLO LTDA');
      CedenteObj.Add('CNPJCPF', '12345678000195');
      CedenteObj.Add('TipoInscricao', 'pJuridica');
      CedenteObj.Add('Agencia', '1234');
      CedenteObj.Add('AgenciaDigito', '5');
      CedenteObj.Add('Conta', '00012345');
      CedenteObj.Add('ContaDigito', '6');
      CedenteObj.Add('Convenio', '1234567');
      CedenteObj.Add('CodigoCedente', '1234567');
      CedenteObj.Add('Modalidade', '19');
      CedenteObj.Add('Logradouro', 'AVENIDA EXEMPLO');
      CedenteObj.Add('NumeroRes', '1000');
      CedenteObj.Add('Bairro', 'CENTRO');
      CedenteObj.Add('Cidade', 'SAO PAULO');
      CedenteObj.Add('UF', 'SP');
      CedenteObj.Add('CEP', '01001000');
      CfgObj.Add('Cedente', CedenteObj);
      Payload.Add('config', CfgObj);

      Payload.Add('LayoutRemessa', 'c240');
      Payload.Add('NumeroRemessa', 1);

      ArrTit := TJSONArray.Create;
      TitObj := TJSONObject.Create;
      TitObj.Add('Carteira', '17');
      TitObj.Add('NossoNumero', '0000000001');
      TitObj.Add('NumeroDocumento', 'NF-1001');
      TitObj.Add('Vencimento', '2026-12-31');
      TitObj.Add('DataDocumento', '2026-11-20');
      TitObj.Add('ValorDocumento', 250.00);
      TitObj.Add('EspecieDoc', 'DM');
      TitObj.Add('Aceite', 'atNao');

      SacadoObj := TJSONObject.Create;
      SacadoObj.Add('NomeSacado', 'CLIENTE EXEMPLO LTDA');
      SacadoObj.Add('CNPJCPF', '00000000000191');
      SacadoObj.Add('Logradouro', 'RUA EXEMPLO');
      SacadoObj.Add('Numero', '100');
      SacadoObj.Add('Bairro', 'CENTRO');
      SacadoObj.Add('Cidade', 'SAO PAULO');
      SacadoObj.Add('UF', 'SP');
      SacadoObj.Add('CEP', '01002000');
      TitObj.Add('Sacado', SacadoObj);
      ArrTit.Add(TitObj);
      Payload.Add('Titulos', ArrTit);

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/boleto/remessa');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('Remessa CNAB 240 deve retornar status sucesso', 'sucesso', RespJson.Get('status', ''));
        AssertTrue('remessa_base64 nao deve ser vazio', RespJson.Get('remessa_base64', '') <> '');
      finally
        RespJson.Free;
      end;
    finally
      Payload.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostSpedPisCofinsOmitBlocoPSemDados;
var
  Client: TFPHTTPClient;
  Response, RawTxt: String;
  Payload, RespJson: TJSONObject;

  function MakeBlocoSemDados(const ARegKey: String): TJSONObject;
  var
    RegObj: TJSONObject;
  begin
    Result := TJSONObject.Create;
    RegObj := TJSONObject.Create;
    RegObj.Add('IND_MOV', 'imSemDados');
    Result.Add(ARegKey, RegObj);
  end;

var
  Bloco0, Reg0000, Reg0001: TJSONObject;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('DT_INI', '2026-01-01');
      Payload.Add('DT_FIN', '2026-01-31');

      Bloco0 := TJSONObject.Create;
      Reg0000 := TJSONObject.Create;
      Reg0000.Add('COD_VER', 'vlVersao320');
      Reg0000.Add('TIPO_ESCRIT', 'tpEscrOriginal');
      Reg0000.Add('IND_SIT_ESP', 'indNenhum');
      Reg0000.Add('DT_INI', '2026-01-01');
      Reg0000.Add('DT_FIN', '2026-01-31');
      Reg0000.Add('NOME', 'EMPRESA EXEMPLO LTDA');
      Reg0000.Add('CNPJ', '12345678000195');
      Reg0000.Add('UF', 'ES');
      Reg0000.Add('COD_MUN', 3203205);
      Reg0000.Add('IND_NAT_PJ', 'indNatPJSocEmpresariaGeral');
      Reg0000.Add('IND_ATIV', 'indAtivOutros');
      Bloco0.Add('Registro0000', Reg0000);

      Reg0001 := TJSONObject.Create;
      Reg0001.Add('IND_MOV', 'imSemDados');
      Bloco0.Add('Registro0001', Reg0001);
      Payload.Add('Bloco_0', Bloco0);

      Payload.Add('Bloco_A', MakeBlocoSemDados('RegistroA001'));
      Payload.Add('Bloco_C', MakeBlocoSemDados('RegistroC001'));
      Payload.Add('Bloco_D', MakeBlocoSemDados('RegistroD001'));
      Payload.Add('Bloco_F', MakeBlocoSemDados('RegistroF001'));
      Payload.Add('Bloco_I', MakeBlocoSemDados('RegistroI001'));
      Payload.Add('Bloco_M', MakeBlocoSemDados('RegistroM001'));
      Payload.Add('Bloco_1', MakeBlocoSemDados('Registro1001'));

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/sped/piscofins/gerar');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('SPED PisCofins status deve ser sucesso', 'sucesso', RespJson.Get('status', ''));
        RawTxt := DecodeStringBase64(RespJson.Get('arquivo_base64', ''));
        AssertTrue('Deve conter |A001|1|', Pos('|A001|1|', RawTxt) > 0);
        AssertTrue('Deve conter |A990|2|', Pos('|A990|2|', RawTxt) > 0);
        AssertTrue('Deve conter |C001|1|', Pos('|C001|1|', RawTxt) > 0);
        AssertTrue('Deve conter |C990|2|', Pos('|C990|2|', RawTxt) > 0);
        AssertTrue('Deve conter |D001|1|', Pos('|D001|1|', RawTxt) > 0);
        AssertTrue('Deve conter |D990|2|', Pos('|D990|2|', RawTxt) > 0);
        AssertTrue('Deve conter |F001|1|', Pos('|F001|1|', RawTxt) > 0);
        AssertTrue('Deve conter |F990|2|', Pos('|F990|2|', RawTxt) > 0);
        AssertTrue('Deve conter |M001|1|', Pos('|M001|1|', RawTxt) > 0);
        AssertTrue('Deve conter |M990|2|', Pos('|M990|2|', RawTxt) > 0);
        AssertTrue('Deve conter |1001|1|', Pos('|1001|1|', RawTxt) > 0);
        AssertTrue('Deve conter |1990|2|', Pos('|1990|2|', RawTxt) > 0);
        AssertEquals('Nao deve conter |P001| quando Bloco_P omitido', 0, Pos('|P001|', RawTxt));
        AssertEquals('Nao deve conter |P990| quando Bloco_P omitido', 0, Pos('|P990|', RawTxt));
      finally
        RespJson.Free;
      end;
    finally
      Payload.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostCargaBalancaFilizolaSetorIndex;
var
  Client: TFPHTTPClient;
  Response, SetorTxt: String;
  Payload, ProdItem, SetorObj, TecladoObj, RespJson, FileObj: TJSONObject;
  ArrProd, ArrFiles: TJSONArray;
  I: Integer;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('Modelo', 'modFilizola');
      ArrProd := TJSONArray.Create;
      ProdItem := TJSONObject.Create;
      ProdItem.Add('Codigo', 101);
      ProdItem.Add('Descricao', 'ALCATRA KG');
      ProdItem.Add('ValorVenda', 49.90);
      ProdItem.Add('Validade', 3);
      ProdItem.Add('Tipo', 'tpvPeso');
      SetorObj := TJSONObject.Create;
      SetorObj.Add('Codigo', 1);
      SetorObj.Add('Descricao', 'ACOUGUE');
      ProdItem.Add('Setor', SetorObj);
      TecladoObj := TJSONObject.Create;
      TecladoObj.Add('Tecla', 1);
      ProdItem.Add('Teclado', TecladoObj);
      ArrProd.Add(ProdItem);
      Payload.Add('Produtos', ArrProd);

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/diversos/balanca/carga');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('Carga Filizola deve retornar status sucesso', 'sucesso', RespJson.Get('status', ''));
        ArrFiles := RespJson.Arrays['arquivos'];
        SetorTxt := '';
        for I := 0 to ArrFiles.Count - 1 do
        begin
          FileObj := ArrFiles.Objects[I];
          if UpperCase(FileObj.Get('nome', '')) = 'SETORTXT.TXT' then
            SetorTxt := DecodeStringBase64(FileObj.Get('conteudo_base64', ''));
        end;
        AssertTrue('SETORTXT.TXT deve ser gerado para modFilizola', SetorTxt <> '');
        AssertTrue('SETORTXT.TXT deve formatar indice 1 como 0001 (nao 0100)', Pos('ACOUGUE     0001010001001', SetorTxt) > 0);
      finally
        RespJson.Free;
      end;
    finally
      Payload.Free;
    end;
  finally
    Client.Free;
  end;
end;

initialization
  RegisterTest(TTestDiversos);
end.
