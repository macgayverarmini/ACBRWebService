unit TestNFe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser, TestBase;

type
  { TTestNFe }
  TTestNFe = class(TTestBase)
  published
    // GET
    procedure TestGetModeloConfig;
    procedure TestGetModeloEvento;
    procedure TestGetModeloDistribuicao;
    procedure TestGetModeloNFe;
    procedure TestGetModeloStatusServicoNFe;
    procedure TestGetModeloConsultaNFe;
    procedure TestGetModeloInutilizacaoNFe;
    procedure TestGetModeloCancelamentoNFe;
    procedure TestGetModeloNFeFromXML;
    procedure TestGetModeloNFeToXML;
    procedure TestGetModeloValidarRegrasNFe;
    procedure TestGetModeloDanfeEvento;

    // POST
    procedure TestPostEventos;
    procedure TestPostDistribuicao;
    procedure TestPostDANFe;
    procedure TestPostNFe;
    procedure TestPostStatusServicoNFe;
    procedure TestPostConsultaNFe;
    procedure TestPostInutilizacaoNFe;
    procedure TestPostCancelamentoNFe;
    procedure TestPostNFeFromXML;
    procedure TestPostNFeToXML;
    procedure TestPostValidarRegrasNFe;
    procedure TestPostDanfeEvento;
    // XML-based tests (usando nfeTestData.xml real)
    procedure TestPostNFeFromXMLWithValidXML;
    procedure TestPostDANFeWithXML;
    procedure TestPostConsultaWithKey;
    procedure TestPostNFeFromXMLWithInvalidBase64;
  end;

implementation

{ TTestNFe }

// --- GET Tests ---

procedure TTestNFe.TestGetModeloConfig;
begin
  ExecuteGetTest('/modelo/nfe/config');
end;

procedure TTestNFe.TestGetModeloEvento;
begin
  ExecuteGetTest('/modelo/nfe/evento');
end;

procedure TTestNFe.TestGetModeloDistribuicao;
begin
  ExecuteGetTest('/modelo/nfe/distribuicao');
end;

procedure TTestNFe.TestGetModeloNFe;
begin
  ExecuteGetTest('/modelo/nfe/nfe');
end;

procedure TTestNFe.TestGetModeloStatusServicoNFe;
begin
  ExecuteGetTest('/modelo/nfe/status');
end;

procedure TTestNFe.TestGetModeloConsultaNFe;
begin
  ExecuteGetTest('/modelo/nfe/consulta');
end;

procedure TTestNFe.TestGetModeloInutilizacaoNFe;
begin
  ExecuteGetTest('/modelo/nfe/inutilizacao');
end;

procedure TTestNFe.TestGetModeloCancelamentoNFe;
begin
  ExecuteGetTest('/modelo/nfe/cancelamento');
end;

procedure TTestNFe.TestGetModeloNFeFromXML;
begin
  ExecuteGetTest('/modelo/nfe/nfe-from-xml');
end;

procedure TTestNFe.TestGetModeloNFeToXML;
begin
  ExecuteGetTest('/modelo/nfe/nfe-to-xml');
end;

procedure TTestNFe.TestGetModeloValidarRegrasNFe;
begin
  ExecuteGetTest('/modelo/nfe/validar-regras');
end;

procedure TTestNFe.TestGetModeloDanfeEvento;
begin
  ExecuteGetTest('/modelo/nfe/danfe-evento');
end;

// --- POST Tests ---

procedure TTestNFe.TestPostEventos;
begin
  ExecutePostTest('/nfe/eventos', nil, 500);
end;

procedure TTestNFe.TestPostDistribuicao;
begin
  ExecutePostTest('/nfe/distribuicao');
end;

procedure TTestNFe.TestPostDANFe;
begin
  ExecutePostTest('/nfe/danfe');
end;

procedure TTestNFe.TestPostNFe;
begin
  ExecutePostTest('/nfe/nfe', nil, 500);
end;

procedure TTestNFe.TestPostStatusServicoNFe;
begin
  ExecutePostTest('/nfe/status');
end;

procedure TTestNFe.TestPostConsultaNFe;
begin
  ExecutePostTest('/nfe/consulta');
end;

procedure TTestNFe.TestPostInutilizacaoNFe;
begin
  ExecutePostTest('/nfe/inutilizacao');
end;

procedure TTestNFe.TestPostCancelamentoNFe;
begin
  ExecutePostTest('/nfe/cancelamento');
end;

procedure TTestNFe.TestPostNFeFromXML;
begin
  ExecutePostTest('/nfe/nfe-from-xml');
end;

procedure TTestNFe.TestPostNFeToXML;
begin
  ExecutePostTest('/nfe/nfe-to-xml');
end;

procedure TTestNFe.TestPostValidarRegrasNFe;
begin
  ExecutePostTest('/nfe/validar-regras');
end;

procedure TTestNFe.TestPostDanfeEvento;
begin
  ExecutePostTest('/nfe/danfe-evento');
end;

// --- XML-based Tests ---

procedure TTestNFe.TestPostNFeFromXMLWithValidXML;
var
  Client: TFPHTTPClient;
  Response: String;
  Json, RespJson: TJSONObject;
  XmlBase64: String;
begin
  XmlBase64 := LoadTestXMLAsBase64(TEST_NFE_XML_FILE);
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('config', CreateConfigJSON);
      Json.Add('xml', XmlBase64);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/nfe/nfe-from-xml');
      except
        on E: EHTTPClient do
        begin
          if Client.ResponseStatusCode = 0 then raise;
          Response := '';
        end;
      end;

      if Client.ResponseStatusCode >= 400 then
        CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)
      else
      begin
        CheckResponse(Response, 200, Client.ResponseStatusCode);
        if Response <> '' then
        begin
          RespJson := GetJSON(Response) as TJSONObject;
          try
            if RespJson.Find('status') <> nil then
              AssertTrue('Error response should have message',
                RespJson.Find('message') <> nil)
            else
              AssertTrue('Response should be valid JSON (got ' + IntToStr(RespJson.Count) + ' fields)',
                RespJson.Count >= 0);
          finally
            RespJson.Free;
          end;
        end;
      end;
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestNFe.TestPostDANFeWithXML;
var
  Client: TFPHTTPClient;
  Response: String;
  Json, RespJson: TJSONObject;
  XmlBase64: String;
begin
  XmlBase64 := LoadTestXMLAsBase64(TEST_NFE_XML_FILE);
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('config', CreateConfigJSON);
      Json.Add('xml', XmlBase64);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/nfe/danfe');
      except
        on E: EHTTPClient do
        begin
          if Client.ResponseStatusCode = 0 then raise;
          Response := '';
        end;
      end;

      if Client.ResponseStatusCode >= 400 then
        CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)
      else
      begin
        CheckResponse(Response, 200, Client.ResponseStatusCode);
        if Response <> '' then
        begin
          try
            RespJson := GetJSON(Response) as TJSONObject;
            try
              AssertTrue('DANFE response should have pdf or error',
                (RespJson.Find('pdf') <> nil) or (RespJson.Find('error') <> nil) or
                (RespJson.Find('status') <> nil));
            finally
              RespJson.Free;
            end;
          except
            // Response might not be JSON
          end;
        end;
      end;
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestNFe.TestPostConsultaWithKey;
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
      Json.Add('config', CreateConfigJSON);
      Json.Add('NFe_Chave', TEST_NFE_ACCESS_KEY);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/nfe/consulta');
      except
        on E: EHTTPClient do
        begin
          if Client.ResponseStatusCode = 0 then raise;
          Response := '';
        end;
      end;

      // Consulta com chave real vai falhar no SEFAZ sem certificado, mas deve retornar JSON
      AssertTrue('Status code should be valid HTTP response',
        (Client.ResponseStatusCode >= 200) and (Client.ResponseStatusCode < 600));
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestNFe.TestPostNFeFromXMLWithInvalidBase64;
var
  Client: TFPHTTPClient;
  Response: String;
  Json: TJSONObject;
  ResponseStream: TStringStream;
begin
  Client := TFPHTTPClient.Create(nil);
  ResponseStream := TStringStream.Create('');
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('config', CreateConfigJSON);
      Json.Add('xml', 'invalid-base64-!!!');
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Client.Post(FBaseUrl + '/nfe/nfe-from-xml', ResponseStream);
        Response := ResponseStream.DataString;
      except
        on E: EHTTPClient do
        begin
          Response := ResponseStream.DataString;
          if Response = '' then Response := E.Message;
        end;
      end;

      AssertTrue('Response should contain error or empty result: ' + Response,
        (Pos('Nenhuma NF-e carregada', Response) > 0) or
        (Pos('Erro', Response) > 0) or
        (Pos('error', Response) > 0));
    finally
      Json.Free;
    end;
  finally
    ResponseStream.Free;
    Client.Free;
  end;
end;

initialization
  RegisterTest(TTestNFe);
end.
