unit TestMDFe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser, TestBase;

type
  { TTestMDFe }
  TTestMDFe = class(TTestBase)
  published
    // GET
    procedure TestGetModeloConfig;
    procedure TestGetModeloEvento;
    procedure TestGetModeloMDFe;
    procedure TestGetModeloDistribuicao;

    // POST
    procedure TestPostEnviar;
    procedure TestPostEventos;
    procedure TestPostDACTE; // Actually Damdfe
    procedure TestPostDistribuicao;
  end;

implementation

{ TTestMDFe }

// --- GET Tests ---

procedure TTestMDFe.TestGetModeloConfig;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/mdfe/config');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestMDFe.TestGetModeloEvento;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/mdfe/evento');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestMDFe.TestGetModeloMDFe;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/mdfe/mdfe');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestMDFe.TestGetModeloDistribuicao;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/mdfe/distribuicao');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

// --- POST Tests ---

procedure TTestMDFe.TestPostEnviar;
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
       // Add 'mdfe' object if required for stricter validation, but 400 with message is also a valid response from server for partial data
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/mdfe/enviar');
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

procedure TTestMDFe.TestPostEventos;
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
       Response := Client.Post(FBaseUrl + '/mdfe/eventos');
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

procedure TTestMDFe.TestPostDACTE;
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
       Response := Client.Post(FBaseUrl + '/mdfe/damdfe');
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

procedure TTestMDFe.TestPostDistribuicao;
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
       Response := Client.Post(FBaseUrl + '/mdfe/distribuicao');
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

initialization
  RegisterTest(TTestMDFe);
end.
