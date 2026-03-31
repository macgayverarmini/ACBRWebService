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
    procedure TestGetModeloStatusServicoNFe;
    procedure TestGetModeloConsultaNFe;
    procedure TestGetModeloInutilizacaoNFe;
    procedure TestGetModeloCancelamentoNFe;
    procedure TestGetModeloNFeFromXML;
    procedure TestGetModeloNFeToXML;
    procedure TestGetModeloValidarRegrasNFe;
    procedure TestGetModeloDanfeEvento;

    // POST
    procedure TestPostEventos;
    procedure TestPostDistribuicao;
    procedure TestPostDANFe;
    procedure TestPostNFe;
    procedure TestPostStatusServicoNFe;
    procedure TestPostConsultaNFe;
    procedure TestPostInutilizacaoNFe;
    procedure TestPostCancelamentoNFe;
    procedure TestPostNFeFromXML;
    procedure TestPostNFeToXML;
    procedure TestPostValidarRegrasNFe;
    procedure TestPostDanfeEvento;
  end;

implementation

{ TTestNFe }

// --- GET Tests ---

procedure TTestNFe.TestGetModeloConfig;
begin
  ExecuteGetTest('/modelo/nfe/config');
end;

procedure TTestNFe.TestGetModeloEvento;
begin
  ExecuteGetTest('/modelo/nfe/evento');
end;

procedure TTestNFe.TestGetModeloDistribuicao;
begin
  ExecuteGetTest('/modelo/nfe/distribuicao');
end;

procedure TTestNFe.TestGetModeloNFe;
begin
  ExecuteGetTest('/modelo/nfe/nfe');
end;

procedure TTestNFe.TestGetModeloStatusServicoNFe;
begin
  ExecuteGetTest('/modelo/nfe/status');
end;

procedure TTestNFe.TestGetModeloConsultaNFe;
begin
  ExecuteGetTest('/modelo/nfe/consulta');
end;

procedure TTestNFe.TestGetModeloInutilizacaoNFe;
begin
  ExecuteGetTest('/modelo/nfe/inutilizacao');
end;

procedure TTestNFe.TestGetModeloCancelamentoNFe;
begin
  ExecuteGetTest('/modelo/nfe/cancelamento');
end;

procedure TTestNFe.TestGetModeloNFeFromXML;
begin
  ExecuteGetTest('/modelo/nfe/nfe-from-xml');
end;

procedure TTestNFe.TestGetModeloNFeToXML;
begin
  ExecuteGetTest('/modelo/nfe/nfe-to-xml');
end;

procedure TTestNFe.TestGetModeloValidarRegrasNFe;
begin
  ExecuteGetTest('/modelo/nfe/validar-regras');
end;

procedure TTestNFe.TestGetModeloDanfeEvento;
begin
  ExecuteGetTest('/modelo/nfe/danfe-evento');
end;

// --- POST Tests ---

procedure TTestNFe.TestPostEventos;
begin
  ExecutePostTest('/nfe/eventos', nil, 500);
end;

procedure TTestNFe.TestPostDistribuicao;
begin
  ExecutePostTest('/nfe/distribuicao');
end;

procedure TTestNFe.TestPostDANFe;
begin
  ExecutePostTest('/nfe/danfe');
end;

procedure TTestNFe.TestPostNFe;
begin
  ExecutePostTest('/nfe/nfe', nil, 500);
end;

procedure TTestNFe.TestPostStatusServicoNFe;
begin
  ExecutePostTest('/nfe/status');
end;

procedure TTestNFe.TestPostConsultaNFe;
begin
  ExecutePostTest('/nfe/consulta');
end;

procedure TTestNFe.TestPostInutilizacaoNFe;
begin
  ExecutePostTest('/nfe/inutilizacao');
end;

procedure TTestNFe.TestPostCancelamentoNFe;
begin
  ExecutePostTest('/nfe/cancelamento');
end;

procedure TTestNFe.TestPostNFeFromXML;
begin
  ExecutePostTest('/nfe/nfe-from-xml');
end;

procedure TTestNFe.TestPostNFeToXML;
begin
  ExecutePostTest('/nfe/nfe-to-xml');
end;

procedure TTestNFe.TestPostValidarRegrasNFe;
begin
  ExecutePostTest('/nfe/validar-regras');
end;

procedure TTestNFe.TestPostDanfeEvento;
begin
  ExecutePostTest('/nfe/danfe-evento');
end;

initialization
  RegisterTest(TTestNFe);
end.
