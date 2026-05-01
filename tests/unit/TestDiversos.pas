unit TestDiversos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser, TestBase;

type
  { TTestDiversos }
  TTestDiversos = class(TTestBase)
  published
    procedure TestGetModeloExtenso;
    procedure TestGetTraduzValor; // GET with body
    procedure TestGetModeloValidador;
    procedure TestPostValidar; // POST with body
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
       // Note: The API is defined as GET but requires a body.
       // Standard GET requests usually don't have a body, but we simulate it here.
       // If FPHTTPClient strips the body on GET, this might fail or the server receives empty body.
       // Let's rely on Client.Method := 'GET' + RequestBody set.
       Response := Client.Get(FBaseUrl + '/diversos/extenso');
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
       // Add required fields for validation, e.g., CPF or CNPJ
       Json.Add('TipoDocto', 'docCPF'); 
       Json.Add('Documento', '12345678909'); // Dummy invalid CPF
       Client.RequestBody := TStringStream.Create(Json.AsJSON);
       Response := Client.Post(FBaseUrl + '/diversos/validador');
       CheckResponse(Response, 200, Client.ResponseStatusCode);
    finally
       Json.Free;
    end;
  finally
     Client.Free;
  end;
end;

initialization
  RegisterTest(TTestDiversos);
end.
