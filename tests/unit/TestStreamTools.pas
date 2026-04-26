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
  end;

implementation

{ TTestStreamTools }

procedure TTestStreamTools.TestFileToStringBase64_EmptyFile;
var
  TempFile: string;
  Size: Integer;
begin
  TempFile := 'empty_test_file_nodelete.pdf';
  // Create an empty file
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
    // Since Apagar was false, file should still exist
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
  // Create an empty file
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
        // Since Apagar was true, file should be deleted even if exception occurs
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
    // 'Hello World' in Base64 is 'SGVsbG8gV29ybGQ='
    AssertEquals('Base64 content mismatch', 'SGVsbG8gV29ybGQ=', ResultStr);
    AssertFalse('File should have been deleted', FileExists(TempFile));
  finally
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

initialization
  RegisterTest(TTestStreamTools);
end.
