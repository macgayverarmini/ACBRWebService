program TestRunner;

{$mode objfpc}{$H+}

uses
  Classes, consoletestrunner, TestCTe, TestNFe, TestMDFe, TestDiversos, TestCertificados, TestNFSe;

type
  TMyTestRunner = class(consoletestrunner.TTestRunner)
  protected
    procedure WriteCustomHelp; override;
  end;

procedure TMyTestRunner.WriteCustomHelp;
begin
  writeln('Custom help for TestRunner');
end;

var
  Application: TMyTestRunner;
begin
  Application := TMyTestRunner.Create(nil);
  Application.Initialize;
  Application.Run;
  Application.Free;
end.
