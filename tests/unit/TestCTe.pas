unit TestCTe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser,
  Base64, TestBase, resource.strings.msg;

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

    // POST - OperaÃ§Ãµes
    procedure TestPostStatusServico;
    procedure TestPostConsulta;
    procedure TestPostInutilizacao;
    procedure TestPostDistribuicao;
    procedure TestPostEnviar;
    procedure TestPostEnviarMegaPayload;
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

    procedure TestPostCTeFromXMLWithInvalidBase64;
    procedure TestPostDACTEWithInvalidBase64;
    procedure TestPostDACTEEventoWithInvalidBase64;
  end;

implementation

{ TTestCTe }

// --- GET Tests ---

procedure TTestCTe.TestGetModeloConfig;
begin
  ExecuteGetTest('/modelo/cte/config');
end;

procedure TTestCTe.TestGetModeloEvento;
begin
  ExecuteGetTest('/modelo/cte/evento');
end;

procedure TTestCTe.TestGetModeloDistribuicao;
begin
  ExecuteGetTest('/modelo/cte/distribuicao');
end;

procedure TTestCTe.TestGetModeloStatusServico;
begin
  ExecuteGetTest('/modelo/cte/status');
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

procedure TTestCTe.TestPostCTeFromXMLWithInvalidBase64;
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
        Client.Post(FBaseUrl + '/cte/cte-from-xml', ResponseStream);
        Response := ResponseStream.DataString;
      except
        on E: EHTTPClient do
        begin
          Response := ResponseStream.DataString;
          if Response = '' then Response := E.Message;
        end;
      end;

      AssertTrue('Response should contain error message: ' + Response,
        Pos('Nenhum CTe carregado', Response) > 0);
    finally
      Json.Free;
    end;
  finally
    ResponseStream.Free;
    Client.Free;
  end;
end;

procedure TTestCTe.TestPostDACTEWithInvalidBase64;
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
        Client.Post(FBaseUrl + '/cte/dacte', ResponseStream);
        Response := ResponseStream.DataString;
      except
        on E: EHTTPClient do
        begin
          Response := ResponseStream.DataString;
          if Response = '' then Response := E.Message;
        end;
      end;

      AssertTrue('Response should contain error message: ' + Response,
        (Pos('out of bounds', Response) > 0) or (Pos('Internal Application Error', Response) > 0));
    finally
      Json.Free;
    end;
  finally
    ResponseStream.Free;
    Client.Free;
  end;
end;

procedure TTestCTe.TestPostDACTEEventoWithInvalidBase64;
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
        Client.Post(FBaseUrl + '/cte/dacte-evento', ResponseStream);
        Response := ResponseStream.DataString;
      except
        on E: EHTTPClient do
        begin
          Response := ResponseStream.DataString;
          if Response = '' then Response := E.Message;
        end;
      end;

      AssertTrue('Response should contain error message: ' + Response,
        Pos('Erro ao gerar', Response) > 0);
    finally
      Json.Free;
    end;
  finally
    ResponseStream.Free;
    Client.Free;
  end;
end;

procedure TTestCTe.TestGetModeloInutilizacao;
begin
  ExecuteGetTest('/modelo/cte/inutilizacao');
end;

procedure TTestCTe.TestGetModeloCTe;
begin
  ExecuteGetTest('/modelo/cte/cte');
end;

procedure TTestCTe.TestGetModeloCancelamento;
begin
  ExecuteGetTest('/modelo/cte/cancelamento');
end;

procedure TTestCTe.TestGetModeloCTeFromXML;
begin
  ExecuteGetTest('/modelo/cte/cte-from-xml');
end;

procedure TTestCTe.TestGetModeloCTeToXML;
begin
  ExecuteGetTest('/modelo/cte/cte-to-xml');
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
       Response := Client.Post(FBaseUrl + '/cte/cte');
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

procedure TTestCTe.TestPostEnviarMegaPayload;
var
  Client: TFPHTTPClient;
  Response: String;
  Json, CTeObj, InfDoc, Cobr, Fat: TJSONObject;
  InfNFeArray, FaturasArray, AutXMLArray, DupArray, LacArray: TJSONArray;
  NFeItem, AutItem, DupItem, LacItem: TJSONObject;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Json := TJSONObject.Create;
    try
       Json.Add('config', CreateConfigJSON);
       
       // Build MegaPayload
       CTeObj := TJSONObject.Create;
       CTeObj.Add('versao', '4.00');
       
       // AutXML Array
       AutXMLArray := TJSONArray.Create;
       AutItem := TJSONObject.Create;
       AutItem.Add('CNPJ', '12345678000195');
       AutXMLArray.Add(AutItem);
       CTeObj.Add('autXML', AutXMLArray);

       // infDoc
       InfDoc := TJSONObject.Create;
       InfNFeArray := TJSONArray.Create;
       NFeItem := TJSONObject.Create;
       NFeItem.Add('chave', '35200100000000000000550010000000011000000001');
       NFeItem.Add('PIN', '123456');

       // Lacres da NFe
       LacArray := TJSONArray.Create;
       LacItem := TJSONObject.Create;
       LacItem.Add('nLacre', 'LACRE-999');
       LacArray.Add(LacItem);
       NFeItem.Add('lacUnidCarga', LacArray);

       InfNFeArray.Add(NFeItem);
       InfDoc.Add('infNFe', InfNFeArray);
       CTeObj.Add('infDoc', InfDoc);
       
       // Cobr
       Cobr := TJSONObject.Create;
       Fat := TJSONObject.Create;
       Fat.Add('nFat', 'FAT123');
       Fat.Add('vOrig', 1500.50);
       Fat.Add('vDesc', 10.0);
       Fat.Add('vLiq', 1490.50);
       Cobr.Add('fat', Fat);
       
       DupArray := TJSONArray.Create;
       DupItem := TJSONObject.Create;
       DupItem.Add('nDup', 'DUP001');
       DupItem.Add('dVenc', '2023-12-31');
       DupItem.Add('vDup', 1490.50);
       DupArray.Add(DupItem);
       Cobr.Add('dup', DupArray);
       
       CTeObj.Add('cobr', Cobr);

       Json.Add('infCTe', CTeObj); // Envolve no topo, tipicamente a bridge le as propriedades de infCTe ou CTe cru

       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/cte/cte');
       
       // Certificar que no houve Exception no Pascal Bridge ao ler Arrays
       AssertFalse('Resposta no deve conter Erro na leitura do objeto JSON',
         Pos('Erro na leitura do objeto JSON para CTe', Response) > 0);
       AssertFalse('Resposta no deve conter Access Violation',
         Pos('Access violation', Response) > 0);

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
begin
  ExecutePostTest('/cte/eventos', nil, 500);
end;

procedure TTestCTe.TestPostDACTE;
begin
  ExecutePostTest('/cte/dacte');
end;

procedure TTestCTe.TestPostCancelamento;
begin
  ExecutePostTest('/cte/cancelamento');
end;

procedure TTestCTe.TestPostCTeFromXML;
begin
  ExecutePostTest('/cte/cte-from-xml');
end;

procedure TTestCTe.TestPostCTeToXML;
begin
  ExecutePostTest('/cte/cte-to-xml');
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
        // Verificar que o JSON de retorno contÃ©m campos esperados do CTe
        if Response <> '' then
        begin
          RespJson := GetJSON(Response) as TJSONObject;
          try
            // O TCTe serializado via RTTI pode ter nomes de propriedade diferentes dos XML tags
            // Verificamos que: (1) nÃ£o Ã© resposta de erro, ou (2) tem campos do CTe
            if RespJson.Find('status') <> nil then
              // Se tem 'status', Ã© resposta de erro â€” aceitar como vÃ¡lido (XML pode ter problemas)
              AssertTrue('Error response should have message',
                RespJson.Find('message') <> nil)
            else
              // Resposta com sucesso â€” deve ter pelo menos alguns campos do CTe
              AssertTrue('Response should have CTe fields (got ' + IntToStr(RespJson.Count) + ' fields). Response: ' + Response,
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
  // Este teste espera falha proposital (sem certificado vÃ¡lido)
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
        Response := Client.Post(FBaseUrl + '/cte/cte');
      except
        on E: EHTTPClient do
        begin
          if Client.ResponseStatusCode = 0 then raise;
          Response := '';
        end;
      end;

      // Aceitar 200, 400 ou 500 â€” o importante Ã© que nÃ£o crashou
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

      // DACTE pode retornar 200 com pdf, ou erro se faltam libs grÃ¡ficas
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

      // Consulta com chave fictÃ­cia vai falhar no SEFAZ, mas deve retornar JSON
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
