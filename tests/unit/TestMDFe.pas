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
begin
  ExecuteGetTest('/modelo/mdfe/config');
end;

procedure TTestMDFe.TestGetModeloEvento;
begin
  ExecuteGetTest('/modelo/mdfe/evento');
end;

procedure TTestMDFe.TestGetModeloMDFe;
begin
  ExecuteGetTest('/modelo/mdfe/mdfe');
end;

procedure TTestMDFe.TestGetModeloDistribuicao;
begin
  ExecuteGetTest('/modelo/mdfe/distribuicao');
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
       Response := Client.Post(FBaseUrl + '/mdfe/mdfe');
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
begin
  ExecutePostTest('/mdfe/eventos', nil, 500);
end;

procedure TTestMDFe.TestPostDACTE;
begin
  ExecutePostTest('/mdfe/damdfe');
end;

procedure TTestMDFe.TestPostDistribuicao;
begin
  ExecutePostTest('/mdfe/distribuicao');
end;

initialization
  RegisterTest(TTestMDFe);
end.
