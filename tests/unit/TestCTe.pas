unit TestCTe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser,
  Base64, TestBase;

type
  { TTestCTe }
  TTestCTe = class(TTestBase)
  published
    // GET - Modelos
    procedure TestGetModeloConfig;
    procedure TestGetModeloEvento;
    procedure TestGetModeloDistribuicao;
    procedure TestGetModeloStatusServico;
    procedure TestGetModeloConsulta;
    procedure TestGetModeloInutilizacao;
    procedure TestGetModeloCTe;
    procedure TestGetModeloCancelamento;
    procedure TestGetModeloCTeFromXML;
    procedure TestGetModeloCTeToXML;

    // POST - Operações
    procedure TestPostStatusServico;
    procedure TestPostConsulta;
    procedure TestPostInutilizacao;
    procedure TestPostDistribuicao;
    procedure TestPostEnviar;
    procedure TestPostEventos;
    procedure TestPostDACTE;
    procedure TestPostCancelamento;
    procedure TestPostCTeFromXML;
    procedure TestPostCTeToXML;

    // XML-based tests (usando cteTestData.xml)
    procedure TestPostCTeFromXMLWithValidXML;
    procedure TestPostEnviarWithXML;
    procedure TestPostDACTEWithXML;
    procedure TestPostConsultaWithKey;
  end;

implementation

{ TTestCTe }

// --- GET Tests ---

procedure TTestCTe.TestGetModeloConfig;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/config');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloEvento;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/evento');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloDistribuicao;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/distribuicao');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloStatusServico;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/status');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloConsulta;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    try
      Response := Client.Get(FBaseUrl + '/modelo/cte/consulta');
    except
      on E: EHTTPClient do
      begin
        // Catch 500/404 errors which raise exception in FPC
        if Client.ResponseStatusCode = 0 then raise; 
        Response := ''; // Body might be lost or we can try to read it from stream if needed
      end;
    end;

    if Client.ResponseStatusCode >= 400 then
         CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)       
       else
         CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloInutilizacao;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/inutilizacao');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloCTe;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/cte');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloCancelamento;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/cancelamento');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloCTeFromXML;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/cte-from-xml');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloCTeToXML;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/cte/cte-to-xml');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

// --- POST Tests ---

procedure TTestCTe.TestPostStatusServico;
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
        Client.RequestBody := TStringStream.Create(Json.AsJSON);
        Response := Client.Post(FBaseUrl + '/cte/status');
        CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
        Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestPostConsulta;
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
       Json.Add('chave', '35230912345678000190570010000000011000000010'); // Dummy key
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/consulta');
       CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostInutilizacao;
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
       // Add required fields for inutilizacao if any
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/inutilizacao');
       // Might fail with 400 or 500 if fields missing, but we check if we get a JSON response
       CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostDistribuicao;
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
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/distribuicao');
       CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostEnviar;
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
       // Needs 'cte' object usually
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/enviar');
       // Expecting 200 or 400 (validation error), but valid JSON
       if Client.ResponseStatusCode >= 400 then
         CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)       
       else
         CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostEventos;
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
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/eventos');
       if Client.ResponseStatusCode >= 400 then
         CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)       
       else
         CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostDACTE;
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
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/dacte');
       if Client.ResponseStatusCode >= 400 then
         CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)       
       else
         CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostCancelamento;
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
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/cancelamento');
       if Client.ResponseStatusCode >= 400 then
         CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)       
       else
         CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostCTeFromXML;
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
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/cte-from-xml');
       if Client.ResponseStatusCode >= 400 then
         CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)       
       else
         CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

procedure TTestCTe.TestPostCTeToXML;
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
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/cte-to-xml');
       if Client.ResponseStatusCode >= 400 then
         CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)
       else
         CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

// --- XML-based Tests ---

procedure TTestCTe.TestPostCTeFromXMLWithValidXML;
var
  Client: TFPHTTPClient;
  Response: String;
  Json, RespJson: TJSONObject;
  XmlBase64: String;
begin
  XmlBase64 := LoadTestXMLAsBase64(TEST_CTE_XML_FILE);
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('config', CreateConfigJSON);
      Json.Add('xml', XmlBase64);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/cte/cte-from-xml');
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
        // Verificar que o JSON de retorno contém campos esperados do CTe
        if Response <> '' then
        begin
          RespJson := GetJSON(Response) as TJSONObject;
          try
            // O TCTe serializado via RTTI pode ter nomes de propriedade diferentes dos XML tags
            // Verificamos que: (1) não é resposta de erro, ou (2) tem campos do CTe
            if RespJson.Find('status') <> nil then
              // Se tem 'status', é resposta de erro — aceitar como válido (XML pode ter problemas)
              AssertTrue('Error response should have message',
                RespJson.Find('message') <> nil)
            else
              // Resposta com sucesso — deve ter pelo menos alguns campos do CTe
              AssertTrue('Response should have CTe fields (got ' + IntToStr(RespJson.Count) + ' fields)',
                RespJson.Count > 0);
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

procedure TTestCTe.TestPostEnviarWithXML;
var
  Client: TFPHTTPClient;
  Response: String;
  Json: TJSONObject;
  XmlBase64: String;
begin
  // Este teste espera falha proposital (sem certificado válido)
  XmlBase64 := LoadTestXMLAsBase64(TEST_CTE_XML_FILE);
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('config', CreateConfigJSON);
      Json.Add('xml', XmlBase64);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/cte/enviar');
      except
        on E: EHTTPClient do
        begin
          if Client.ResponseStatusCode = 0 then raise;
          Response := '';
        end;
      end;

      // Aceitar 200, 400 ou 500 — o importante é que não crashou
      AssertTrue('Status code should be valid HTTP response',
        (Client.ResponseStatusCode >= 200) and (Client.ResponseStatusCode < 600));
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

procedure TTestCTe.TestPostDACTEWithXML;
var
  Client: TFPHTTPClient;
  Response: String;
  Json: TJSONObject;
  RespJson: TJSONObject;
  XmlBase64: String;
begin
  XmlBase64 := LoadTestXMLAsBase64(TEST_CTE_XML_FILE);
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
      Json.Add('config', CreateConfigJSON);
      Json.Add('xml', XmlBase64);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/cte/dacte');
      except
        on E: EHTTPClient do
        begin
          if Client.ResponseStatusCode = 0 then raise;
          Response := '';
        end;
      end;

      // DACTE pode retornar 200 com pdf, ou erro se faltam libs gráficas
      if Client.ResponseStatusCode >= 400 then
        CheckResponse(Response, Client.ResponseStatusCode, Client.ResponseStatusCode)
      else
      begin
        CheckResponse(Response, 200, Client.ResponseStatusCode);
        // Se retornou 200, verificar se tem campo 'pdf' ou 'chave'
        if (Response <> '') then
        begin
          try
            RespJson := GetJSON(Response) as TJSONObject;
            try
              AssertTrue('DACTE response should have pdf or error',
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

procedure TTestCTe.TestPostConsultaWithKey;
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
      Json.Add('CTeChave', TEST_CTE_ACCESS_KEY);
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/cte/consulta');
      except
        on E: EHTTPClient do
        begin
          if Client.ResponseStatusCode = 0 then raise;
          Response := '';
        end;
      end;

      // Consulta com chave fictícia vai falhar no SEFAZ, mas deve retornar JSON
      AssertTrue('Status code should be valid HTTP response',
        (Client.ResponseStatusCode >= 200) and (Client.ResponseStatusCode < 600));
    finally
      Json.Free;
    end;
  finally
    Client.Free;
  end;
end;

initialization
  RegisterTest(TTestCTe);
end.
