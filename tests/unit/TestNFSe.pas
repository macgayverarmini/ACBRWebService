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
begin
  ExecuteGetTest('/modelo/nfse/config');
end;

procedure TTestNFSe.TestGetModeloEmitir;
begin
  ExecuteGetTest('/modelo/nfse/emitir');
end;

procedure TTestNFSe.TestGetModeloConsultarSituacao;
begin
  ExecuteGetTest('/modelo/nfse/consultarsituacao');
end;

procedure TTestNFSe.TestGetModeloConsultarLote;
begin
  ExecuteGetTest('/modelo/nfse/consultarlote');
end;

procedure TTestNFSe.TestGetModeloConsultarNFSePorRps;
begin
  ExecuteGetTest('/modelo/nfse/consultarnfseporrps');
end;

procedure TTestNFSe.TestGetModeloConsultarNFSe;
begin
  ExecuteGetTest('/modelo/nfse/consultarnfse');
end;

procedure TTestNFSe.TestGetModeloCancelar;
begin
  ExecuteGetTest('/modelo/nfse/cancelar');
end;

procedure TTestNFSe.TestGetModeloSubstituir;
begin
  ExecuteGetTest('/modelo/nfse/substituir');
end;

// --- POST Tests ---

procedure TTestNFSe.TestPostEmitir;
begin
  ExecutePostTest('/nfse/emitir');
end;

procedure TTestNFSe.TestPostGerar;
begin
  ExecutePostTest('/nfse/gerar');
end;

procedure TTestNFSe.TestPostConsultarSituacao;
begin
  ExecutePostTest('/nfse/consultarsituacao');
end;

procedure TTestNFSe.TestPostConsultarLote;
begin
  ExecutePostTest('/nfse/consultarlote');
end;

procedure TTestNFSe.TestPostConsultarNFSePorRps;
begin
  ExecutePostTest('/nfse/consultarnfseporrps');
end;

procedure TTestNFSe.TestPostConsultarNFSe;
begin
  ExecutePostTest('/nfse/consultarnfse');
end;

procedure TTestNFSe.TestPostCancelar;
begin
  ExecutePostTest('/nfse/cancelar');
end;

procedure TTestNFSe.TestPostSubstituir;
begin
  ExecutePostTest('/nfse/substituir');
end;

procedure TTestNFSe.TestPostDANFSe;
begin
  ExecutePostTest('/nfse/danfse');
end;

initialization
  RegisterTest(TTestNFSe);
end.
