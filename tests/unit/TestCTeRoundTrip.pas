unit TestCTeRoundTrip;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fpjson, jsonparser, Base64, TestBase,
  ACBrCTe, ACBrCTe.Classes, ACBrCTeConhecimentos;

type
  { TTestCTeRoundTrip
    Testes de integridade para CT-e:
      FASE 1 — Carrega XML real no ACBr, valida que os valores profundos
               foram parseados corretamente pelo componente.
      FASE 2 — Gera XML a partir do objeto, recarrega, e compara campos-chave.
  }
  TTestCTeRoundTrip = class(TTestCase)
  private
    FACBR: TACBrCTe;
    function GetTestResourcePath: string;
    function LoadCTeFromFile(const FileName: string): TCTe;
    function GetCTeXMLString: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    { === FASE 1 — XML → Objeto ACBr: valida valores profundos === }
    procedure Test_LoadXML_Ide;
    procedure Test_LoadXML_Emit;
    procedure Test_LoadXML_Rem;
    procedure Test_LoadXML_Dest;
    procedure Test_LoadXML_VPrest;
    procedure Test_LoadXML_ICMS;
    procedure Test_LoadXML_InfCarga;
    procedure Test_LoadXML_InfModal;

    { === FASE 2 — Round-trip: XML → Obj → GerarXML → Recarregar → Comparar === }
    procedure Test_RoundTrip_Ide;
    procedure Test_RoundTrip_Emit;
    procedure Test_RoundTrip_Dest;
    procedure Test_RoundTrip_VPrest;
    procedure Test_RoundTrip_ICMS;
  end;

implementation

const
  TEST_CTE_XML = 'cteTestData.xml';

{ -----------------------------------------------------------------------
  SetUp / TearDown
  ----------------------------------------------------------------------- }

procedure TTestCTeRoundTrip.SetUp;
begin
  FACBR := TACBrCTe.Create(nil);
end;

procedure TTestCTeRoundTrip.TearDown;
begin
  FreeAndNil(FACBR);
end;

function TTestCTeRoundTrip.GetTestResourcePath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + '..' + PathDelim + '..' + PathDelim + 'resources' + PathDelim;
end;

function TTestCTeRoundTrip.LoadCTeFromFile(const FileName: string): TCTe;
var
  SL: TStringList;
  FullPath: string;
begin
  FullPath := GetTestResourcePath + FileName;
  if not FileExists(FullPath) then
    Fail('Arquivo XML de teste não encontrado: ' + FullPath);

  SL := TStringList.Create;
  try
    SL.LoadFromFile(FullPath);
    FACBR.Conhecimentos.Clear;
    FACBR.Conhecimentos.LoadFromString(SL.Text);
  finally
    SL.Free;
  end;

  if FACBR.Conhecimentos.Count = 0 then
    Fail('Nenhum CT-e carregado do XML: ' + FullPath);

  Result := FACBR.Conhecimentos.Items[0].CTe;
end;

function TTestCTeRoundTrip.GetCTeXMLString: string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(GetTestResourcePath + TEST_CTE_XML);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

{ -----------------------------------------------------------------------
  FASE 1 — XML → Objeto ACBr: Validação de campos profundos
  Valores esperados do XML real carregado
  ----------------------------------------------------------------------- }

procedure TTestCTeRoundTrip.Test_LoadXML_Ide;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  AssertTrue('cUF assigned', CTe.Ide.cUF > 0);
  AssertTrue('CFOP assigned', CTe.Ide.CFOP > 0);
  AssertTrue('modelo assigned', CTe.Ide.modelo > 0);
  AssertTrue('serie assigned', CTe.Ide.serie > 0);
  AssertTrue('nCT assigned', CTe.Ide.nCT > 0);
  AssertTrue('cMunEnv assigned', CTe.Ide.cMunEnv > 0);
  AssertTrue('xMunEnv assigned', CTe.Ide.xMunEnv <> '');
  AssertTrue('UFEnv assigned', CTe.Ide.UFEnv <> '');
  AssertTrue('cMunIni assigned', CTe.Ide.cMunIni > 0);
  AssertTrue('cMunFim assigned', CTe.Ide.cMunFim > 0);
  AssertTrue('UFFim assigned', CTe.Ide.UFFim <> '');
end;

procedure TTestCTeRoundTrip.Test_LoadXML_Emit;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  AssertTrue('CNPJ emit assigned', CTe.Emit.CNPJ <> '');
  AssertTrue('IE emit assigned', CTe.Emit.IE <> '');
  AssertTrue('xNome emit assigned', CTe.Emit.xNome <> '');

  // Endereço do emitente (sub-objeto profundo)
  AssertTrue('xLgr emit assigned', CTe.Emit.EnderEmit.xLgr <> '');
  AssertTrue('nro emit assigned', CTe.Emit.EnderEmit.nro <> '');
  AssertTrue('xBairro emit assigned', CTe.Emit.EnderEmit.xBairro <> '');
  AssertTrue('cMun emit assigned', CTe.Emit.EnderEmit.cMun > 0);
  AssertTrue('CEP emit assigned', CTe.Emit.EnderEmit.CEP > 0);
  AssertTrue('UF emit assigned', CTe.Emit.EnderEmit.UF <> '');
end;

procedure TTestCTeRoundTrip.Test_LoadXML_Rem;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  AssertTrue('CNPJCPF rem assigned', CTe.Rem.CNPJCPF <> '');
  AssertTrue('IE rem assigned', CTe.Rem.IE <> '');
  AssertTrue('xNome rem assigned', CTe.Rem.xNome <> '');
  AssertTrue('UF rem assigned', CTe.Rem.EnderReme.UF <> '');
end;

procedure TTestCTeRoundTrip.Test_LoadXML_Dest;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  AssertTrue('CNPJCPF dest assigned', CTe.Dest.CNPJCPF <> '');
  AssertTrue('IE dest assigned', CTe.Dest.IE <> '');
  AssertTrue('xNome dest assigned', CTe.Dest.xNome <> '');

  AssertTrue('cMun dest assigned', CTe.Dest.EnderDest.cMun > 0);
  AssertTrue('xMun dest assigned', CTe.Dest.EnderDest.xMun <> '');
  AssertTrue('UF dest assigned', CTe.Dest.EnderDest.UF <> '');
  AssertTrue('CEP dest assigned', CTe.Dest.EnderDest.CEP > 0);
end;

procedure TTestCTeRoundTrip.Test_LoadXML_VPrest;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  AssertTrue('vTPrest assigned', Double(CTe.vPrest.vTPrest) > 0);
  AssertTrue('vRec assigned', Double(CTe.vPrest.vRec) > 0);
end;

procedure TTestCTeRoundTrip.Test_LoadXML_ICMS;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  // ICMS00 — tags profundas
  AssertTrue('vBC ICMS assigned', Double(CTe.Imp.ICMS.ICMS00.vBC) > 0);
  AssertTrue('pICMS assigned', Double(CTe.Imp.ICMS.ICMS00.pICMS) > 0);
  AssertTrue('vICMS assigned', Double(CTe.Imp.ICMS.ICMS00.vICMS) > 0);
end;

procedure TTestCTeRoundTrip.Test_LoadXML_InfCarga;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  AssertTrue('vCarga assigned', Double(CTe.InfCTeNorm.InfCarga.vCarga) > 0);
  AssertTrue('proPred assigned', CTe.InfCTeNorm.InfCarga.proPred <> '');
end;

procedure TTestCTeRoundTrip.Test_LoadXML_InfModal;
var
  CTe: TCTe;
begin
  CTe := LoadCTeFromFile(TEST_CTE_XML);

  AssertTrue('RNTRC assigned', CTe.InfCTeNorm.rodo.RNTRC <> '');
end;

{ -----------------------------------------------------------------------
  FASE 2 — Round-trip: XML → Obj → GerarXML → Recarregar Obj → Comparar
  ----------------------------------------------------------------------- }

procedure TTestCTeRoundTrip.Test_RoundTrip_Ide;
var
  CTe2: TCTe;
  XMLGerado: string;
  cUF1, CFOP1, serie1, nCT1, cMunEnv1, cMunFim1: Integer;
  xMunEnv1, UFFim1: string;
begin
  // 1. Carregar do XML original
  with LoadCTeFromFile(TEST_CTE_XML) do
  begin
    cUF1 := Ide.cUF;
    CFOP1 := Ide.CFOP;
    serie1 := Ide.serie;
    nCT1 := Ide.nCT;
    cMunEnv1 := Ide.cMunEnv;
    xMunEnv1 := Ide.xMunEnv;
    cMunFim1 := Ide.cMunFim;
    UFFim1 := Ide.UFFim;
  end;

  // 2. Gerar XML a partir do objeto carregado
  FACBR.Conhecimentos.GerarCTe;
  XMLGerado := FACBR.Conhecimentos.Items[0].XMLOriginal;
  if XMLGerado = '' then
    XMLGerado := FACBR.Conhecimentos.Items[0].XML;
  AssertTrue('XML gerado não vazio', XMLGerado <> '');

  // 3. Recarregar o XML gerado
  FACBR.Conhecimentos.Clear;
  FACBR.Conhecimentos.LoadFromString(XMLGerado);
  AssertTrue('CT-e recarregado', FACBR.Conhecimentos.Count > 0);
  CTe2 := FACBR.Conhecimentos.Items[0].CTe;

  // 4. Comparar campos-chave
  AssertEquals('RT cUF',     cUF1,     CTe2.Ide.cUF);
  AssertEquals('RT CFOP',    CFOP1,    CTe2.Ide.CFOP);
  AssertEquals('RT serie',   serie1,   CTe2.Ide.serie);
  AssertEquals('RT nCT',     nCT1,     CTe2.Ide.nCT);
  AssertEquals('RT cMunEnv', cMunEnv1, CTe2.Ide.cMunEnv);
  AssertEquals('RT xMunEnv', xMunEnv1, CTe2.Ide.xMunEnv);
  AssertEquals('RT cMunFim', cMunFim1, CTe2.Ide.cMunFim);
  AssertEquals('RT UFFim',   UFFim1,   CTe2.Ide.UFFim);
end;

procedure TTestCTeRoundTrip.Test_RoundTrip_Emit;
var
  CTe2: TCTe;
  XMLGerado: string;
  CNPJ1, IE1, xNome1: string;
  cMun1: Integer;
  UF1: string;
begin
  with LoadCTeFromFile(TEST_CTE_XML) do
  begin
    CNPJ1  := Emit.CNPJ;
    IE1    := Emit.IE;
    xNome1 := Emit.xNome;
    cMun1  := Emit.EnderEmit.cMun;
    UF1    := Emit.EnderEmit.UF;
  end;

  FACBR.Conhecimentos.GerarCTe;
  XMLGerado := FACBR.Conhecimentos.Items[0].XMLOriginal;
  if XMLGerado = '' then
    XMLGerado := FACBR.Conhecimentos.Items[0].XML;

  FACBR.Conhecimentos.Clear;
  FACBR.Conhecimentos.LoadFromString(XMLGerado);
  CTe2 := FACBR.Conhecimentos.Items[0].CTe;

  AssertEquals('RT CNPJ emit',  CNPJ1,  CTe2.Emit.CNPJ);
  AssertEquals('RT IE emit',    IE1,     CTe2.Emit.IE);
  AssertEquals('RT xNome emit', xNome1,  CTe2.Emit.xNome);
  AssertEquals('RT cMun emit',  cMun1,   CTe2.Emit.EnderEmit.cMun);
  AssertEquals('RT UF emit',    UF1,     CTe2.Emit.EnderEmit.UF);
end;

procedure TTestCTeRoundTrip.Test_RoundTrip_Dest;
var
  CTe2: TCTe;
  XMLGerado: string;
  CNPJ1, IE1, xNome1: string;
begin
  with LoadCTeFromFile(TEST_CTE_XML) do
  begin
    CNPJ1  := Dest.CNPJCPF;
    IE1    := Dest.IE;
    xNome1 := Dest.xNome;
  end;

  FACBR.Conhecimentos.GerarCTe;
  XMLGerado := FACBR.Conhecimentos.Items[0].XMLOriginal;
  if XMLGerado = '' then
    XMLGerado := FACBR.Conhecimentos.Items[0].XML;

  FACBR.Conhecimentos.Clear;
  FACBR.Conhecimentos.LoadFromString(XMLGerado);
  CTe2 := FACBR.Conhecimentos.Items[0].CTe;

  AssertEquals('RT CNPJCPF dest',  CNPJ1,  CTe2.Dest.CNPJCPF);
  AssertEquals('RT IE dest',       IE1,     CTe2.Dest.IE);
  AssertEquals('RT xNome dest',    xNome1,  CTe2.Dest.xNome);
end;

procedure TTestCTeRoundTrip.Test_RoundTrip_VPrest;
var
  CTe2: TCTe;
  XMLGerado: string;
  vTPrest1, vRec1: Currency;
begin
  with LoadCTeFromFile(TEST_CTE_XML) do
  begin
    vTPrest1 := vPrest.vTPrest;
    vRec1    := vPrest.vRec;
  end;

  FACBR.Conhecimentos.GerarCTe;
  XMLGerado := FACBR.Conhecimentos.Items[0].XMLOriginal;
  if XMLGerado = '' then
    XMLGerado := FACBR.Conhecimentos.Items[0].XML;

  FACBR.Conhecimentos.Clear;
  FACBR.Conhecimentos.LoadFromString(XMLGerado);
  CTe2 := FACBR.Conhecimentos.Items[0].CTe;

  AssertEquals('RT vTPrest', Double(vTPrest1), Double(CTe2.vPrest.vTPrest));
  AssertEquals('RT vRec',    Double(vRec1),    Double(CTe2.vPrest.vRec));
end;

procedure TTestCTeRoundTrip.Test_RoundTrip_ICMS;
var
  CTe2: TCTe;
  XMLGerado: string;
  vBC1, pICMS1, vICMS1: Currency;
begin
  with LoadCTeFromFile(TEST_CTE_XML) do
  begin
    vBC1   := Imp.ICMS.ICMS00.vBC;
    pICMS1 := Imp.ICMS.ICMS00.pICMS;
    vICMS1 := Imp.ICMS.ICMS00.vICMS;
  end;

  FACBR.Conhecimentos.GerarCTe;
  XMLGerado := FACBR.Conhecimentos.Items[0].XMLOriginal;
  if XMLGerado = '' then
    XMLGerado := FACBR.Conhecimentos.Items[0].XML;

  FACBR.Conhecimentos.Clear;
  FACBR.Conhecimentos.LoadFromString(XMLGerado);
  CTe2 := FACBR.Conhecimentos.Items[0].CTe;

  AssertEquals('RT vBC',    Double(vBC1),    Double(CTe2.Imp.ICMS.ICMS00.vBC));
  AssertEquals('RT pICMS',  Double(pICMS1),  Double(CTe2.Imp.ICMS.ICMS00.pICMS));
  AssertEquals('RT vICMS',  Double(vICMS1),  Double(CTe2.Imp.ICMS.ICMS00.vICMS));
end;

initialization
  RegisterTest(TTestCTeRoundTrip);
end.
