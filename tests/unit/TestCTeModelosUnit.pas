unit TestCTeModelosUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, Base64, method.acbr.cte;

type
  { TTestCTeModelosUnit }
  TTestCTeModelosUnit = class(TTestCase)
  private
    FAcbrCTeModels: TACBRModelosJSONCTe;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    procedure AssertJSONHasField(Json: TJSONObject; const FieldPath: String);
  published
    procedure TestModelConfigCTe;
    procedure TestModelCTe;
    procedure TestModelEvento;
    procedure TestMassXmlFiles;
  end;

implementation

{ TTestCTeModelosUnit }

procedure TTestCTeModelosUnit.SetUp;
begin
  // Create without needing a real config for tests just to generate the models
  FAcbrCTeModels := TACBRModelosJSONCTe.Create('');
end;

procedure TTestCTeModelosUnit.TearDown;
begin
  FAcbrCTeModels.Free;
end;

procedure TTestCTeModelosUnit.AssertJSONHasField(Json: TJSONObject; const FieldPath: String);
var
  Data: TJSONData;
begin
  Data := Json.FindPath(FieldPath);
  if not Assigned(Data) then
    Fail('Expected JSON path not found: ' + FieldPath);
end;

procedure TTestCTeModelosUnit.TestModelConfigCTe;
var
  Json: TJSONObject;
begin
  Json := FAcbrCTeModels.ModelConfig;
  try
    AssertNotNull('ModelConfig returned nil', Json);
    AssertJSONHasField(Json, 'Geral.VersaoDF');
    AssertJSONHasField(Json, 'Geral.SSLLib');
    AssertJSONHasField(Json, 'WebServices.Ambiente');
    AssertJSONHasField(Json, 'WebServices.TimeOut');
    AssertJSONHasField(Json, 'Certificados.ArquivoPFX');
    AssertJSONHasField(Json, 'Arquivos.Salvar');
  finally
    Json.Free;
  end;
end;

procedure TTestCTeModelosUnit.TestModelCTe;
var
  Json: TJSONObject;
begin
  Json := FAcbrCTeModels.ModelCTe;
  try
    AssertNotNull('ModelCTe returned nil', Json);
    AssertJSONHasField(Json, 'infCTe.versao');
    AssertJSONHasField(Json, 'ide.cUF');
    AssertJSONHasField(Json, 'ide.CFOP');
    AssertJSONHasField(Json, 'ide.natOp');
    AssertJSONHasField(Json, 'emit.CNPJ');
    AssertJSONHasField(Json, 'emit.enderEmit.xMun');
    AssertJSONHasField(Json, 'autXML');
  finally
    Json.Free;
  end;
end;

procedure TTestCTeModelosUnit.TestModelEvento;
var
  Json: TJSONObject;
begin
  Json := FAcbrCTeModels.ModelEvento;
  try
    AssertNotNull('ModelEvento returned nil', Json);
    // Even if it's empty EventoCTe, it should serialize something like 'Evento' array
    AssertJSONHasField(Json, 'Evento');
  finally
    Json.Free;
  end;
end;

procedure TTestCTeModelosUnit.TestMassXmlFiles;
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
  if FindFirst(Dir + '*-cte.xml', faAnyFile, SearchRec) = 0 then
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
            Json := FAcbrCTeModels.CTeFromXML(Req);
            if Assigned(Json) then
            begin
              Inc(SuccessCount);
              Json.Free;
            end;
          except
            // Ignore parse errors, just continue
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
    AssertEquals('Not all CTe XMLs were successfully converted to JSON', XmlCount, SuccessCount);
end;

initialization
  RegisterTest(TTestCTeModelosUnit);
end.
