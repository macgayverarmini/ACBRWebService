unit TestBase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser,
  Base64;

const
  // Chave de acesso fictícia válida (dígito verificador correto) para testes
  TEST_CTE_ACCESS_KEY = '35260211222333000144570010000000011000000019';
  // Nome do arquivo XML de teste obfuscado
  TEST_CTE_XML_FILE = 'cteTestData.xml';

type
  { TTestBase }
  TTestBase = class(TTestCase)
  protected
    FBaseUrl: String;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure CheckResponse(Response: String; ExpectedCode: Integer = 200; ActualCode: Integer = 200);
    procedure ExecuteGetTest(const Endpoint: String; ExpectedCode: Integer = 200);
    procedure ExecutePostTest(const Endpoint: String; Payload: TJSONObject = nil; ExpectedCode: Integer = 200);
    function CreateConfigJSON(UF: String = 'SP'; Ambiente: String = '1'): TJSONObject;
    function GetTestResourcePath: String;
    function LoadTestXMLAsBase64(const FileName: String): String;
    function LoadTestXMLRaw(const FileName: String): String;
  end;

implementation

{ TTestBase }

procedure TTestBase.ExecuteGetTest(const Endpoint: String; ExpectedCode: Integer);
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    try
      Response := Client.Get(FBaseUrl + Endpoint);
    except
      on E: EHTTPClient do
      begin
        // Catch HTTP error status codes that raise exceptions in TFPHTTPClient
        Response := Client.ResponseHeaders.Text; // or anything else to indicate we handled it
      end;
    end;
    CheckResponse(Response, ExpectedCode, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestBase.ExecutePostTest(const Endpoint: String; Payload: TJSONObject; ExpectedCode: Integer);
var
  Client: TFPHTTPClient;
  Response: String;
  Json: TJSONObject;
  OwnsPayload: Boolean;
begin
  Client := TFPHTTPClient.Create(nil);
  OwnsPayload := False;
  if Payload = nil then
  begin
    Json := TJSONObject.Create;
    Json.Add('config', CreateConfigJSON);
    Payload := Json;
    OwnsPayload := True;
  end;

  try
    Client.AddHeader('Content-Type', 'application/json');
    Client.RequestBody := TStringStream.Create(Payload.AsJSON);
    try
      try
        Response := Client.Post(FBaseUrl + Endpoint);
      except
        on E: EHTTPClient do
        begin
          // Catch HTTP errors
          Response := Client.ResponseHeaders.Text;
        end;
      end;
      CheckResponse(Response, ExpectedCode, Client.ResponseStatusCode);
    finally
      Client.RequestBody.Free;
    end;
  finally
    if OwnsPayload then
      Payload.Free;
    Client.Free;
  end;
end;

procedure TTestBase.SetUp;
begin
  FBaseUrl := 'http://localhost:9000';
end;

procedure TTestBase.TearDown;
begin
  // Common cleanup if necessary
end;

procedure TTestBase.CheckResponse(Response: String; ExpectedCode: Integer; ActualCode: Integer);
var
  Json: TJSONData;
begin
   AssertEquals('Status code mismatch', ExpectedCode, ActualCode);
   
   if Response <> '' then
   begin
     if (ExpectedCode >= 500) and (Pos('<html', LowerCase(Response)) > 0) then
     begin
       // Accept HTML error page if we expected an error
       Exit;
     end;

     try
       Json := GetJSON(Response);
       try
         // Valid JSON
       finally
         Json.Free;
       end;
     except
       if ExpectedCode = 200 then
         Fail('Response is not valid JSON: ' + Response)
       else
         // If we expected an error code, maybe the response isn't JSON (like default 404/500 HTML)
         // So ignore JSON error if we got the expected status code
         ; 
     end;
   end;
end;

function TTestBase.CreateConfigJSON(UF: String; Ambiente: String): TJSONObject;
var
  Geral, WebServices, Certificados, Arquivos: TJSONObject;
begin
  Result := TJSONObject.Create;

  // Geral
  Geral := TJSONObject.Create;
  Geral.Add('SSLLib', 'libOpenSSL');
  Geral.Add('SSLCryptLib', 'cryOpenSSL');
  Geral.Add('SSLHttpLib', 'httpOpenSSL');
  Geral.Add('SSLXmlSignLib', 'xsLibXml2');
  Geral.Add('RetirarAcentos', True);
  Geral.Add('VersaoDF', 've400');
  Result.Add('Geral', Geral);

  // WebServices
  WebServices := TJSONObject.Create;
  WebServices.Add('Ambiente', 'taHomologacao');
  WebServices.Add('UF', UF);
  WebServices.Add('TimeOut', 5000);
  WebServices.Add('Visualizar', False);
  WebServices.Add('Tentativas', 5);
  Result.Add('WebServices', WebServices);

  // Certificados (vazio para testes sem certificado real)
  Certificados := TJSONObject.Create;
  Certificados.Add('ArquivoPFX', '');
  Certificados.Add('Senha', '');
  Result.Add('Certificados', Certificados);

  // Arquivos
  Arquivos := TJSONObject.Create;
  Arquivos.Add('Salvar', False);
  Result.Add('Arquivos', Arquivos);
end;

function TTestBase.GetTestResourcePath: String;
begin
  // From src/tests/unit/ go up to src/resources/
  Result := ExtractFilePath(ParamStr(0)) + '..' + PathDelim + '..' + PathDelim + 'resources' + PathDelim;
end;

function TTestBase.LoadTestXMLRaw(const FileName: String): String;
var
  SL: TStringList;
  FullPath: String;
begin
  FullPath := GetTestResourcePath + FileName;
  if not FileExists(FullPath) then
    Fail('Test XML file not found: ' + FullPath);
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FullPath);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function TTestBase.LoadTestXMLAsBase64(const FileName: String): String;
var
  RawXML: String;
begin
  RawXML := LoadTestXMLRaw(FileName);
  Result := EncodeStringBase64(RawXML);
end;

end.

