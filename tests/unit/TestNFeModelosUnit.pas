unit TestNFeModelosUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, Base64, method.acbr.nfe;

type
  { TTestNFeModelosUnit }
  TTestNFeModelosUnit = class(TTestCase)
  private
    FAcbrNFeModels: TACBRModelosJSON;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure AssertJSONHasField(Json: TJSONObject; const FieldPath: String);
  published
    procedure TestModelConfigNFe;
    procedure TestModelNFe;
    procedure TestModelEvento;
    procedure TestMassXmlFiles;
  end;

implementation

{ TTestNFeModelosUnit }

procedure TTestNFeModelosUnit.SetUp;
begin
  FAcbrNFeModels := TACBRModelosJSON.Create('');
end;

procedure TTestNFeModelosUnit.TearDown;
begin
  FAcbrNFeModels.Free;
end;

procedure TTestNFeModelosUnit.AssertJSONHasField(Json: TJSONObject; const FieldPath: String);
var
  Data: TJSONData;
begin
  Data := Json.FindPath(FieldPath);
  if not Assigned(Data) then
    Fail('Expected JSON path not found: ' + FieldPath);
end;

procedure TTestNFeModelosUnit.TestModelConfigNFe;
var
  Json: TJSONObject;
begin
  Json := FAcbrNFeModels.ModelConfig;
  try
    AssertNotNull('ModelConfig returned nil', Json);
    AssertJSONHasField(Json, 'Geral.VersaoDF');
    AssertJSONHasField(Json, 'WebServices.Ambiente');
    AssertJSONHasField(Json, 'Certificados.ArquivoPFX');
    AssertJSONHasField(Json, 'Arquivos.Salvar');
  finally
    Json.Free;
  end;
end;

procedure TTestNFeModelosUnit.TestModelNFe;
var
  Json: TJSONObject;
begin
  Json := FAcbrNFeModels.ModelNFe;
  try
    AssertNotNull('ModelNFe returned nil', Json);
    AssertJSONHasField(Json, 'NFe.infNFe.Versao');
    AssertJSONHasField(Json, 'NFe.Ide.cUF');
    AssertJSONHasField(Json, 'NFe.Ide.natOp');
    AssertJSONHasField(Json, 'NFe.Emit.CNPJCPF');
    AssertJSONHasField(Json, 'NFe.Dest.CNPJCPF');
    AssertJSONHasField(Json, 'NFe.Det');
  finally
    Json.Free;
  end;
end;

procedure TTestNFeModelosUnit.TestModelEvento;
var
  Json: TJSONObject;
begin
  Json := FAcbrNFeModels.ModelEvento;
  try
    AssertNotNull('ModelEvento returned nil', Json);
    AssertJSONHasField(Json, 'Evento');
  finally
    Json.Free;
  end;
end;

procedure TTestNFeModelosUnit.TestMassXmlFiles;
var
  SearchRec: TSearchRec;
  Dir: String;
  Json, Req: TJSONObject;
  SL: TStringList;
  XmlCount, SuccessCount: Integer;
begin
  Dir := '.\test_xmls\';
  if not DirectoryExists(Dir) then
    Exit; // Skip if directory doesn't exist

  XmlCount := 0;
  SuccessCount := 0;
  if FindFirst(Dir + '*-nfe.xml', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          Inc(XmlCount);
          Req := TJSONObject.Create;
          SL := TStringList.Create;
          try
            SL.LoadFromFile(Dir + SearchRec.Name);
            Req.Add('xml_base64', EncodeStringBase64(SL.Text));
            Json := FAcbrNFeModels.NFeFromXML(Req);
            if Assigned(Json) then
            begin
              Inc(SuccessCount);
              Json.Free;
            end;
          except
            // Ignore parse errors
          end;
          SL.Free;
          Req.Free;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
  
  if XmlCount > 0 then
    AssertEquals('Not all NFe XMLs were successfully converted to JSON', XmlCount, SuccessCount);
end;

initialization
  RegisterTest(TTestNFeModelosUnit);
end.
