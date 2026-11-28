unit TestCTeModelosUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, jsonparser, Base64, method.acbr.cte;

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
    procedure TestRttiNt2026005SnXml;
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

procedure TTestCTeModelosUnit.TestRttiNt2026005SnXml;
var
  Payload, Res: TJSONObject;
  XmlBase64, XmlStr, PayloadStr: String;
begin
  PayloadStr :=
    '{' +
      '"infCTe": { "versao": 4.00 },' +
      '"ide": {' +
        '"cUF": 32, "cCT": 12345678, "CFOP": 5353, "natOp": "TRANSPORTE SN", "modelo": 57, "serie": 1, "nCT": 100,' +
        '"dhEmi": "2027-03-15T10:00:00-03:00", "tpCTe": "tcNormal", "tpAmb": "taHomologacao", "modal": "mdRodoviario",' +
        '"tpServ": "tsNormal", "cMunEnv": 3205309, "xMunEnv": "VITORIA", "UFEnv": "ES",' +
        '"cMunIni": 3205309, "xMunIni": "VITORIA", "UFIni": "ES",' +
        '"cMunFim": 3205309, "xMunFim": "VITORIA", "UFFim": "ES",' +
        '"toma03": { "Toma": "tmRemetente" }' +
      '},' +
      '"emit": {' +
        '"CNPJ": "12345678000199", "IE": "123456789", "xNome": "TRANSPORTADORA SN", "xFant": "TRANSP SN",' +
        '"CRT": "crtSimplesNacional", "tpRegimeIBSCBS": "trSNRegimeRegular",' +
        '"enderEmit": { "xLgr": "RUA A", "nro": "10", "xBairro": "CENTRO", "cMun": 3205309, "xMun": "VITORIA", "UF": "ES", "CEP": 29010000 }' +
      '},' +
      '"vPrest": { "vTPrest": 1000, "vRec": 1000 },' +
      '"imp": {' +
        '"ICMS": { "SituTrib": "cstICMSSN", "ICMSSN": { "indSN": 1 } },' +
        '"IBSCBS": {' +
          '"CST": "cst000", "cClassTrib": "000001",' +
          '"gTribSN": { "gIBSSN": { "pIBSSN": 1.25, "vIBSSN": 12.50 }, "gCBSSN": { "pCBSSN": 2.15, "vCBSSN": 21.50 } }' +
        '},' +
        '"vTotDFe": 1000' +
      '}' +
    '}';
  Payload := GetJSON(PayloadStr) as TJSONObject;
  try
    Res := FAcbrCTeModels.CTeToXML(Payload);
    try
      AssertNotNull('CTeToXML retornou nil', Res);
      XmlBase64 := Res.Get('xml', '');
      if XmlBase64 = '' then
        XmlBase64 := Res.Get('xml_cte', '');
      AssertTrue('CTeToXML deveria retornar xml Base64: ' + Res.AsJSON, XmlBase64 <> '');
      XmlStr := DecodeStringBase64(XmlBase64);
      AssertTrue('XML CTe deveria conter <tpRegimeIBSCBS>1</tpRegimeIBSCBS>: ' + XmlStr, Pos('<tpRegimeIBSCBS>1</tpRegimeIBSCBS>', XmlStr) > 0);
      AssertTrue('XML CTe deveria conter <gTribSN>', Pos('<gTribSN>', XmlStr) > 0);
      AssertTrue('XML CTe deveria conter <vIBSSN>12.50</vIBSSN>', Pos('<vIBSSN>12.50</vIBSSN>', XmlStr) > 0);
      AssertTrue('XML CTe deveria conter <vCBSSN>21.50</vCBSSN>', Pos('<vCBSSN>21.50</vCBSSN>', XmlStr) > 0);
      AssertTrue('XML CTe Simples Puro nao deveria conter <gIBSCBS>', Pos('<gIBSCBS>', XmlStr) = 0);
    finally
      Res.Free;
    end;
  finally
    Payload.Free;
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
