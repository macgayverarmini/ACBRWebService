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

    // POST
    procedure TestPostEventos;
    procedure TestPostDistribuicao;
    procedure TestPostDANFe;
    procedure TestPostNFe;
  end;

implementation

{ TTestNFe }

// --- GET Tests ---

procedure TTestNFe.TestGetModeloConfig;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfe/config');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFe.TestGetModeloEvento;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfe/evento');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFe.TestGetModeloDistribuicao;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfe/distribuicao');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFe.TestGetModeloNFe;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfe/nfe');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

// --- POST Tests ---

procedure TTestNFe.TestPostEventos;
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
       Response := Client.Post(FBaseUrl + '/nfe/eventos');
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

procedure TTestNFe.TestPostDistribuicao;
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
       Response := Client.Post(FBaseUrl + '/nfe/distribuicao');
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

procedure TTestNFe.TestPostDANFe;
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
       Response := Client.Post(FBaseUrl + '/nfe/danfe');
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

procedure TTestNFe.TestPostNFe;
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
       Response := Client.Post(FBaseUrl + '/nfe/nfe');
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
  RegisterTest(TTestNFe);
end.
