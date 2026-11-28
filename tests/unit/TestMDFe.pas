unit TestMDFe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, fphttpclient, fpjson, jsonparser,
  Base64, TestBase;

type
  { TTestMDFe }
  TTestMDFe = class(TTestBase)
  published
    // GET
    procedure TestGetModeloConfig;
    procedure TestGetModeloEvento;
    procedure TestGetModeloMDFe;
    procedure TestGetModeloDistribuicao;
    procedure TestGetModeloMDFeFromXML;
    procedure TestGetModeloMDFeToXML;
    procedure TestGetModeloValidarRegras;
    procedure TestGetModeloEventoToXML;
    procedure TestGetModeloEmail;
    procedure TestPostMDFeFromXML;
    procedure TestPostMDFeToXML;
    procedure TestPostEventoToXML;

    // POST
    procedure TestPostEnviar;
    procedure TestPostEventos;
    procedure TestPostDACTE; // Actually Damdfe
    procedure TestPostDistribuicao;
    procedure TestPostDAMDFEEvento;
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

procedure TTestMDFe.TestGetModeloMDFeFromXML;
begin
  ExecuteGetTest('/modelo/mdfe/mdfe-from-xml');
end;

procedure TTestMDFe.TestGetModeloMDFeToXML;
begin
  ExecuteGetTest('/modelo/mdfe/mdfe-to-xml');
end;

procedure TTestMDFe.TestGetModeloValidarRegras;
begin
  ExecuteGetTest('/modelo/mdfe/validar-regras');
end;

procedure TTestMDFe.TestGetModeloEventoToXML;
begin
  ExecuteGetTest('/modelo/mdfe/evento-to-xml');
end;

procedure TTestMDFe.TestGetModeloEmail;
begin
  ExecuteGetTest('/modelo/mdfe/email');
end;

procedure TTestMDFe.TestPostMDFeFromXML;
begin
  ExecutePostTest('/mdfe/mdfe-from-xml');
end;

procedure TTestMDFe.TestPostMDFeToXML;
begin
  ExecutePostTest('/mdfe/mdfe-to-xml');
end;

procedure TTestMDFe.TestPostEventoToXML;
var
  Client: TFPHTTPClient;
  Response, DecodedXml: String;
  Payload, DetObj, RespJson: TJSONObject;
begin
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Payload := TJSONObject.Create;
    try
      Payload.Add('config', CreateConfigJSON);
      Payload.Add('chMDFe', '35260112345678000195580010000000011000000018');
      Payload.Add('CNPJCPF', '12345678000195');
      Payload.Add('tpEvento', 'teEncerramento');
      Payload.Add('nSeqEvento', 1);
      DetObj := TJSONObject.Create;
      DetObj.Add('nProt', '935260000000001');
      DetObj.Add('dtEnc', '2026-01-31');
      DetObj.Add('cUF', 35);
      DetObj.Add('cMun', 3550308);
      Payload.Add('detEvento', DetObj);

      Client.RequestBody := TStringStream.Create(Payload.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/mdfe/evento-to-xml');
      finally
        Client.RequestBody.Free;
      end;

      CheckResponse(Response, 200, Client.ResponseStatusCode);
      RespJson := GetJSON(Response) as TJSONObject;
      try
        AssertEquals('Expected status = sucesso', 'sucesso', RespJson.Get('status', ''));
        DecodedXml := DecodeStringBase64(RespJson.Get('xml', ''));
        AssertTrue('Expected eventoMDFe XML', Pos('eventoMDFe', DecodedXml) > 0);
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
      Client.RequestBody := TStringStream.Create(Json.AsJSON);
      try
        Response := Client.Post(FBaseUrl + '/mdfe/mdfe');
      finally
        Client.RequestBody.Free;
      end;
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

procedure TTestMDFe.TestPostDAMDFEEvento;
begin
  ExecutePostTest('/mdfe/damdfe-evento');
end;

initialization
  RegisterTest(TTestMDFe);
end.
