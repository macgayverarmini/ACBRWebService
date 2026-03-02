unit TestNFSe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser, TestBase;

type
  { TTestNFSe }
  TTestNFSe = class(TTestBase)
  published
    // GET
    procedure TestGetModeloConfig;
    procedure TestGetModeloEmitir;
    procedure TestGetModeloConsultarSituacao;
    procedure TestGetModeloConsultarLote;
    procedure TestGetModeloConsultarNFSePorRps;
    procedure TestGetModeloConsultarNFSe;
    procedure TestGetModeloCancelar;
    procedure TestGetModeloSubstituir;

    // POST
    procedure TestPostEmitir;
    procedure TestPostGerar;
    procedure TestPostConsultarSituacao;
    procedure TestPostConsultarLote;
    procedure TestPostConsultarNFSePorRps;
    procedure TestPostConsultarNFSe;
    procedure TestPostCancelar;
    procedure TestPostSubstituir;
    procedure TestPostDANFSe;
  end;

implementation

{ TTestNFSe }

// --- GET Tests ---

procedure TTestNFSe.TestGetModeloConfig;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/config');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFSe.TestGetModeloEmitir;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/emitir');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFSe.TestGetModeloConsultarSituacao;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/consultarsituacao');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFSe.TestGetModeloConsultarLote;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/consultarlote');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFSe.TestGetModeloConsultarNFSePorRps;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/consultarnfseporrps');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFSe.TestGetModeloConsultarNFSe;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/consultarnfse');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFSe.TestGetModeloCancelar;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/cancelar');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

procedure TTestNFSe.TestGetModeloSubstituir;
var
  Client: TFPHTTPClient;
  Response: String;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Response := Client.Get(FBaseUrl + '/modelo/nfse/substituir');
    CheckResponse(Response, 200, Client.ResponseStatusCode);
  finally
    Client.Free;
  end;
end;

// --- POST Tests ---

procedure TTestNFSe.TestPostEmitir;
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
       Response := Client.Post(FBaseUrl + '/nfse/emitir');
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

procedure TTestNFSe.TestPostGerar;
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
       Response := Client.Post(FBaseUrl + '/nfse/gerar');
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

procedure TTestNFSe.TestPostConsultarSituacao;
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
       Response := Client.Post(FBaseUrl + '/nfse/consultarsituacao');
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

procedure TTestNFSe.TestPostConsultarLote;
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
       Response := Client.Post(FBaseUrl + '/nfse/consultarlote');
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

procedure TTestNFSe.TestPostConsultarNFSePorRps;
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
       Response := Client.Post(FBaseUrl + '/nfse/consultarnfseporrps');
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

procedure TTestNFSe.TestPostConsultarNFSe;
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
       Response := Client.Post(FBaseUrl + '/nfse/consultarnfse');
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

procedure TTestNFSe.TestPostCancelar;
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
       Response := Client.Post(FBaseUrl + '/nfse/cancelar');
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

procedure TTestNFSe.TestPostSubstituir;
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
       Response := Client.Post(FBaseUrl + '/nfse/substituir');
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

procedure TTestNFSe.TestPostDANFSe;
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
       Response := Client.Post(FBaseUrl + '/nfse/danfse');
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
  RegisterTest(TTestNFSe);
end.
