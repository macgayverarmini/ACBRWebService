unit TestStreamTools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, streamtools;

type

  { TTestStreamTools }

  TTestStreamTools = class(TTestCase)
  published
    procedure TestFileToStringBase64_EmptyFile;
    procedure TestFileToStringBase64_EmptyFile_Delete;
    procedure TestFileToStringBase64_ValidFile;
    procedure TestGenerateUniqueTempToken_IsDistinctAndClean;
    procedure TestIsolatedTempDir_CreatesAndCleansUpRecursively;
  end;

implementation

{ TTestStreamTools }

procedure TTestStreamTools.TestFileToStringBase64_EmptyFile;
var
  TempFile: string;
  Size: Integer;
begin
  TempFile := 'empty_test_file_nodelete.pdf';
  with TFileStream.Create(TempFile, fmCreate) do
    Free;

  try
    try
      FileToStringBase64(TempFile, False, Size);
      Fail('Should have raised an exception for empty file');
    except
      on E: Exception do
        AssertEquals('O arquivo gerado não parece ser válido.', E.Message);
    end;
    AssertTrue('File should still exist', FileExists(TempFile));
  finally
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TTestStreamTools.TestFileToStringBase64_EmptyFile_Delete;
var
  TempFile: string;
  Size: Integer;
begin
  TempFile := 'empty_test_file_delete.pdf';
  with TFileStream.Create(TempFile, fmCreate) do
    Free;

  try
    try
      FileToStringBase64(TempFile, True, Size);
      Fail('Should have raised an exception for empty file');
    except
      on E: Exception do
      begin
        AssertEquals('O arquivo gerado não parece ser válido.', E.Message);
        AssertFalse('File should have been deleted', FileExists(TempFile));
      end;
    end;
  finally
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TTestStreamTools.TestFileToStringBase64_ValidFile;
var
  TempFile: string;
  Size: Integer;
  ResultStr: string;
  FS: TFileStream;
  TestData: string;
begin
  TempFile := 'valid_test_file.txt';
  TestData := 'Hello World';
  FS := TFileStream.Create(TempFile, fmCreate);
  try
    FS.WriteBuffer(TestData[1], Length(TestData));
  finally
    FS.Free;
  end;

  try
    ResultStr := FileToStringBase64(TempFile, True, Size);
    AssertEquals('Size should match', Length(TestData), Size);
    AssertEquals('Base64 content mismatch', 'SGVsbG8gV29ybGQ=', ResultStr);
    AssertFalse('File should have been deleted', FileExists(TempFile));
  finally
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

procedure TTestStreamTools.TestGenerateUniqueTempToken_IsDistinctAndClean;
var
  Tok1, Tok2: string;
begin
  Tok1 := GenerateUniqueTempToken;
  Tok2 := GenerateUniqueTempToken;
  AssertTrue('Token must not be empty', Length(Tok1) > 32);
  AssertTrue('Consecutive UUID tokens must differ', Tok1 <> Tok2);
  AssertEquals('Must not contain braces', 0, Pos('{', Tok1) + Pos('}', Tok1));
end;

procedure TTestStreamTools.TestIsolatedTempDir_CreatesAndCleansUpRecursively;
var
  BaseDir, IsoDir, FilePath: string;
  FS: TFileStream;
  Payload: string;
begin
  BaseDir := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'acbr_ws_test';
  IsoDir := CreateIsolatedTempDir(BaseDir);
  AssertTrue('Isolated dir must exist', DirectoryExists(IsoDir));

  FilePath := BuildUniqueTempFilePath(IsoDir, 'danfe_', '.pdf');
  Payload := '%PDF-1.4';
  FS := TFileStream.Create(FilePath, fmCreate);
  try
    FS.WriteBuffer(Payload[1], Length(Payload));
  finally
    FS.Free;
  end;

  AssertTrue('Temp file must exist before cleanup', FileExists(FilePath));
  CleanupTempDir(IsoDir);
  AssertFalse('Temp file must be deleted', FileExists(FilePath));
  AssertFalse('Isolated dir must be removed', DirectoryExists(IsoDir));
  CleanupTempDir(BaseDir);
end;

initialization
  RegisterTest(TTestStreamTools);
end.
