unit streamtools;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Base64;

function StreamToBase64String(AStream: TMemoryStream): string;
function FileToStringBase64(const FileName: string; const Apagar: Boolean; out size: integer): string;function GetFileSize(const FileName: string): Int64;
function Base64StreamToString(AStream: TMemoryStream): string;
function StringToBase64Stream(AString: string): TMemoryStream;

implementation

function Base64StreamToString(AStream: TMemoryStream): string;
var
  LBytes: TBytes;
  strBase64: string;
begin
  SetLength(LBytes, AStream.Size);
  AStream.Position := 0;
  AStream.Read(LBytes[0], AStream.Size);
  strBase64 := TEncoding.UTF8.GetString(LBytes);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AString);
  Result := TMemoryStream.Create;
  Result.WriteBuffer(base64.EncodeStringBase64(TEncoding.UTF8.GetString(LBytes))[1], Length(base64.EncodeStringBase64(TEncoding.UTF8.GetString(LBytes))));
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
    if FileExists(FileName) then
    begin
      FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
      try
        streamPdf.CopyFrom(FS, 0);
      finally
        FS.Free;
      end;
    end;

    if Apagar then
    begin
      try
        DeleteFile(fileName);
      except
      end;
    end;

    if streamPdf.Size = 0 then
    begin
      raise Exception.Create('O arquivo gerado não parece ser válido.');
      Exit;
    end;

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

