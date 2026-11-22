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
    procedure TestGetTraduzValor;
    procedure TestPostTraduzValor;
    procedure TestGetModeloValidador;
    procedure TestPostValidar;
    procedure TestPostCargaBalancaToledoMGV6;
    procedure TestPostEscPosSpoolBuffer;
    procedure TestPostGNREToXML;
    procedure TestPostSintegra126Colunas;
    procedure TestPostBoletoRemessaCNAB240;
  end;

implementation

{ TTestDiversos }

procedure TTestDiversos.TestGetModeloExtenso;
begin
  ExecuteGetTest('/modelo/diversos/extenso');
end;

procedure TTestDiversos.TestGetTraduzValor;
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
      Json.Add('valor', 123.45);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Get(FBaseUrl + '/diversos/extenso');
      finally
        Client.RequestBody.Free;
      end;
      CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestDiversos.TestPostTraduzValor;
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
      Json.Add('valor', 123.45);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/diversos/extenso');
      finally
        Client.RequestBody.Free;
      end;
      CheckResponse(Response, 200, Client.ResponseStatusCode);
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
      Payload.Add('RetirarAcentos', True);
      ArrProd := TJSONArray.Create;
      ProdItem := TJSONObject.Create;
      ProdItem.Add('Codigo', 101);
      ProdItem.Add('Descricao', 'PRODUTO EXEMPLO KG');
      ProdItem.Add('ValorVenda', 19.90);
      ProdItem.Add('Validade', 5);
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
        AssertTrue('Carga balanca deve retornar sucesso', RespJson.Get('sucesso', False));
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
  LinhasArr: TJSONArray;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('Modelo', 'ppEscPosEpson');
      Payload.Add('PaginaDeCodigo', 'pc850');
      Payload.Add('Porta', 'BUFFER');
      Payload.Add('GerarSpool', True);
      LinhasArr := TJSONArray.Create;
      LinhasArr.Add('</zera><ce>EMPRESA EXEMPLO LTDA</ce>');
      LinhasArr.Add('</corte_parcial>');
      Payload.Add('Linhas', LinhasArr);

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/escpos/escpos');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertTrue('EscPos spool deve retornar sucesso', RespJson.Get('sucesso', False));
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
  Response: String;
  Payload, EmitObj, RespJson: TJSONObject;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('config', CreateConfigJSON);
      Payload.Add('VersaoDF', 've200');
      Payload.Add('c01_UfFavorecida', 'SP');
      Payload.Add('c02_receita', 100099);
      EmitObj := TJSONObject.Create;
      EmitObj.Add('CNPJ', '12345678000195');
      Payload.Add('c03_idContribuinteEmitente', EmitObj);
      Payload.Add('c28_tipoDocOrigem', 10);
      Payload.Add('c04_docOrigem', '1001');
      Payload.Add('c06_valorPrincipal', 100.00);
      Payload.Add('c10_valorTotal', 100.00);
      Payload.Add('c14_dataVencimento', '2026-12-31');
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
        AssertTrue('GNREToXML deve retornar sucesso', RespJson.Get('sucesso', False));
        AssertTrue('XML GNRE deve conter TDadosGNRE', Pos('TDadosGNRE', RespJson.Get('xml_raw', '')) > 0);
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
      Payload.Add('RetirarAcentos', True);
      Reg10 := TJSONObject.Create;
      Reg10.Add('CNPJ', '12345678000195');
      Reg10.Add('Inscricao', '110042490114');
      Reg10.Add('RazaoSocial', 'EMPRESA EXEMPLO COMÉRCIO E INDÚSTRIA LTDA');
      Reg10.Add('Cidade', 'SÃO PAULO');
      Reg10.Add('Estado', 'SP');
      Reg10.Add('Telefone', '1130000000');
      Reg10.Add('DataInicial', '2026-01-01');
      Reg10.Add('DataFinal', '2026-01-31');
      Reg10.Add('CodigoConvenio', '3');
      Reg10.Add('NaturezaInformacoes', '3');
      Reg10.Add('FinalidadeArquivo', '1');
      Payload.Add('Registro10', Reg10);

      Reg11 := TJSONObject.Create;
      Reg11.Add('Endereco', 'AVENIDA EXEMPLO CONCEIÇÃO');
      Reg11.Add('Numero', '1000');
      Reg11.Add('Bairro', 'CENTRO');
      Reg11.Add('Cep', '01001000');
      Reg11.Add('Responsavel', 'RESPONSÁVEL TÉCNICO');
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
      BancoObj := TJSONObject.Create;
      BancoObj.Add('Numero', 1);
      CfgObj.Add('Banco', BancoObj);

      CedenteObj := TJSONObject.Create;
      CedenteObj.Add('Nome', 'EMPRESA EXEMPLO LTDA');
      CedenteObj.Add('CNPJCPF', '12345678000195');
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

      Payload.Add('LayoutRemessa', 240);
      Payload.Add('NumeroRemessa', 1);
      Payload.Add('RetirarAcentos', True);

      ArrTit := TJSONArray.Create;
      TitObj := TJSONObject.Create;
      TitObj.Add('Carteira', '17');
      TitObj.Add('NossoNumero', '0000000001');
      TitObj.Add('NumeroDocumento', 'NF-1001');
      TitObj.Add('Vencimento', '2026-12-31');
      TitObj.Add('DataDocumento', '2026-11-20');
      TitObj.Add('ValorDocumento', 250.00);
      TitObj.Add('EspecieDoc', 'DM');

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
        AssertTrue('Remessa CNAB 240 deve retornar sucesso', RespJson.Get('sucesso', False));
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

initialization
  RegisterTest(TTestDiversos);
end.
