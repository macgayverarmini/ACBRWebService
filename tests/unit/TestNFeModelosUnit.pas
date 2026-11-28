unit TestNFeModelosUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fpjson, jsonparser, Base64, method.acbr.nfe;

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
    procedure TestRttiNt2026005SnXml;
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
    AssertJSONHasField(Json, 'infNFe.Versao');
    AssertJSONHasField(Json, 'Ide.cUF');
    AssertJSONHasField(Json, 'Ide.natOp');
    AssertJSONHasField(Json, 'Emit.CNPJCPF');
    AssertJSONHasField(Json, 'Dest.CNPJCPF');
    AssertJSONHasField(Json, 'Det');
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

procedure TTestNFeModelosUnit.TestRttiNt2026005SnXml;
var
  Payload, Res: TJSONObject;
  XmlBase64, XmlStr: String;
  PayloadStr: String;
begin
  PayloadStr :=
    '{' +
      '"Ide": {' +
        '"cUF": 35, "natOp": "VENDA SN", "indPag": "ipVista", "modelo": 55, "serie": 1, "nNF": 100,' +
        '"dEmi": "2027-03-15T10:00:00-03:00", "tpNF": "tnSaida", "tpEmis": "teNormal", "tpAmb": "taHomologacao",' +
        '"finNFe": "fnNormal", "tpImp": "tiRetrato", "indFinal": "cfConsumidorFinal", "indPres": "pcPresencial",' +
        '"indIntermed": "iiSemOperacao", "idDest": "doInterna", "cMunFG": 3550308' +
      '},' +
      '"Emit": {' +
        '"CNPJCPF": "12345678000199", "IE": "123456789", "xNome": "EMPRESA SN LTDA", "xFant": "EMPRESA SN",' +
        '"CRT": "crtSimplesNacional", "tpRegimeIBSCBS": "trSNRegimeRegular",' +
        '"EnderEmit": { "xLgr": "RUA A", "nro": "10", "xBairro": "CENTRO", "cMun": 3550308, "xMun": "SAO PAULO", "UF": "SP", "CEP": 1001000 }' +
      '},' +
      '"Dest": {' +
        '"CNPJCPF": "98765432000188", "xNome": "CLIENTE TESTE", "indIEDest": "inNaoContribuinte"' +
      '},' +
      '"Det": [{' +
        '"Prod": { "nItem": 1, "cProd": "1", "cEAN": "SEM GTIN", "xProd": "PRODUTO SN", "NCM": "61091000", "CFOP": "5102", "uCom": "UN", "qCom": 1, "vUnCom": 1000, "vProd": 1000, "cEANTrib": "SEM GTIN", "uTrib": "UN", "qTrib": 1, "vUnTrib": 1000, "IndTot": "itSomaTotalNFe", "cAtivSN": "caRevendaMercadorias" },' +
        '"Imposto": {' +
          '"ICMS": { "orig": "oeNacional", "CSOSN": "csosn102" },' +
          '"PIS": { "CST": "pis08" },' +
          '"COFINS": { "CST": "cof08" },' +
          '"IBSCBS": {' +
            '"CST": "cst000", "cClassTrib": "000001",' +
            '"gTribSN": { "gIBSSN": { "pIBSSN": 1.25, "vIBSSN": 12.50 }, "gCBSSN": { "pCBSSN": 2.15, "vCBSSN": 21.50 } }' +
          '}' +
        '}' +
      '}],' +
      '"Total": {' +
        '"ICMSTot": { "vProd": 1000, "vNF": 1000 },' +
        '"IBSCBSTot": { "vBCIBSCBS": 0, "gTribSN": { "vIBSSN": 12.50, "vCBSSN": 21.50 } },' +
        '"vNFTot": 1000' +
      '},' +
      '"Transp": { "modFrete": "mfSemFrete" },' +
      '"pag": [{ "indPag": "ipVista", "tPag": "fpDinheiro", "vPag": 1000 }]' +
    '}';
  Payload := GetJSON(PayloadStr) as TJSONObject;
  try
    Res := FAcbrNFeModels.NFeToXML(Payload);
    try
      AssertNotNull('NFeToXML retornou nil', Res);
      XmlBase64 := Res.Get('xml', '');
      AssertTrue('NFeToXML deveria retornar xml Base64: ' + Res.AsJSON, XmlBase64 <> '');
      XmlStr := DecodeStringBase64(XmlBase64);
      AssertTrue('XML deveria conter <cAtivSN>01</cAtivSN>: ' + XmlStr, Pos('<cAtivSN>01</cAtivSN>', XmlStr) > 0);
      AssertTrue('XML deveria conter <tpRegimeIBSCBS>1</tpRegimeIBSCBS>', Pos('<tpRegimeIBSCBS>1</tpRegimeIBSCBS>', XmlStr) > 0);
      AssertTrue('XML deveria conter <vIBSSN>12.50</vIBSSN>', Pos('<vIBSSN>12.50</vIBSSN>', XmlStr) > 0);
      AssertTrue('XML deveria conter <vCBSSN>21.50</vCBSSN>', Pos('<vCBSSN>21.50</vCBSSN>', XmlStr) > 0);
      AssertTrue('XML Simples Puro nao deveria conter <gIBSCBS>', Pos('<gIBSCBS>', XmlStr) = 0);
    finally
      Res.Free;
    end;
  finally
    Payload.Free;
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
