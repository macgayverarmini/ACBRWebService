unit streamtools;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Base64;

function StreamToBase64String(AStream: TMemoryStream): string;
function FileToStringBase64(const FileName: string; const Apagar: Boolean; out size: integer): string;
function GetFileSize(const FileName: string): Int64;
function Base64StreamToString(AStream: TMemoryStream): string;
function StringToBase64Stream(AString: string): TMemoryStream;
function GenerateUniqueTempToken: string;
function CreateIsolatedTempDir(const ABaseDir: string): string;
function BuildUniqueTempFilePath(const ADir, APrefix, AExt: string): string;
procedure CleanupTempDir(const ADir: string);

implementation

function GenerateUniqueTempToken: string;
var
  LGUID: TGUID;
  LGUIDStr: string;
begin
  LGUID := TGUID.NewGuid;
  LGUIDStr := GUIDToString(LGUID);
  LGUIDStr := StringReplace(LGUIDStr, '{', '', [rfReplaceAll]);
  LGUIDStr := StringReplace(LGUIDStr, '}', '', [rfReplaceAll]);
  LGUIDStr := StringReplace(LGUIDStr, '-', '', [rfReplaceAll]);
  Result := LowerCase(LGUIDStr) + '_' + IntToStr(QWord(PtrUInt(GetCurrentThreadId)));
end;

function CreateIsolatedTempDir(const ABaseDir: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ABaseDir) + GenerateUniqueTempToken + PathDelim;
  ForceDirectories(Result);
end;

function BuildUniqueTempFilePath(const ADir, APrefix, AExt: string): string;
var
  LDir, LExt: string;
begin
  LDir := IncludeTrailingPathDelimiter(ADir);
  if not DirectoryExists(LDir) then
    ForceDirectories(LDir);
  LExt := AExt;
  if (LExt <> '') and (LExt[1] <> '.') then
    LExt := '.' + LExt;
  Result := LDir + APrefix + GenerateUniqueTempToken + LExt;
end;

procedure CleanupTempDir(const ADir: string);
var
  LDir: string;
  LSR: TSearchRec;
begin
  if Trim(ADir) = '' then
    Exit;
  LDir := IncludeTrailingPathDelimiter(ADir);
  if not DirectoryExists(LDir) then
    Exit;
  if FindFirst(LDir + '*', faAnyFile, LSR) = 0 then
  begin
    try
      repeat
        if (LSR.Name <> '.') and (LSR.Name <> '..') then
        begin
          if (LSR.Attr and faDirectory) <> 0 then
            CleanupTempDir(LDir + LSR.Name)
          else
          begin
            try
              SysUtils.DeleteFile(LDir + LSR.Name);
            except
            end;
          end;
        end;
      until FindNext(LSR) <> 0;
    finally
      FindClose(LSR);
    end;
  end;
  try
    RemoveDir(ExcludeTrailingPathDelimiter(LDir));
  except
  end;
end;

function Base64StreamToString(AStream: TMemoryStream): string;
var
  LBytes: TBytes;
  strBase64: string;
begin
  SetLength(LBytes, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.Read(LBytes[0], AStream.Size);
  strBase64 := TEncoding.UTF8.GetString(LBytes);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  strBase64: string;
begin
  strBase64 := base64.EncodeStringBase64(AString);
  Result := TMemoryStream.Create;
  if Length(strBase64) > 0 then
    Result.WriteBuffer(strBase64[1], Length(strBase64));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  S: RawByteString;
begin
  SetLength(S, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.Read(S[1], AStream.Size);
  Result := base64.EncodeStringBase64(S);
end;

function FileToStringBase64(const FileName: string; const Apagar: Boolean; out size: integer): string;
var
  FS: TFileStream;
  streamPdf: TMemoryStream;
begin
  Result := '';
  size := 0;
  streamPdf := TMemoryStream.Create;
  try
    try
      if FileExists(FileName) then
      begin
        FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
        try
          streamPdf.CopyFrom(FS, 0);
        finally
          FS.Free;
        end;
      end;
    finally
      if Apagar and (FileName <> '') and FileExists(FileName) then
      begin
        try
          SysUtils.DeleteFile(FileName);
        except
        end;
      end;
    end;

    if streamPdf.Size = 0 then
      raise Exception.Create('O arquivo gerado não parece ser válido.');

    Result := StreamToBase64String(streamPdf);
    size := streamPdf.Size;
  finally
    streamPdf.Free;
  end;
end;

function GetFileSize(const FileName: string): Int64;
var
  FS: TFileStream;
begin
  Result := 0;
  if FileExists(FileName) then
  begin
    FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      Result := FS.Size;
    finally
      FS.Free;
    end;
  end;
end;

end.
