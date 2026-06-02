unit streamtools;

{$mode Delphi}

interface

uses
  Classes, SysUtils, Base64;

function StreamToBase64String(AStream: TMemoryStream): string;
function FileToStringBase64(const FileName: string; const Apagar: Boolean; out size: integer): string;
function Base64StreamToString(AStream: TMemoryStream): string;
function StringToBase64Stream(AString: string): TMemoryStream;

implementation

function Base64StreamToString(AStream: TMemoryStream): string;
var
  strBase64: string;
begin
  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  // ⚡ Bolt optimization: Read directly into native string buffer instead of intermediate TBytes + TEncoding
  if AStream.Size > 0 then
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  Base64Str: string;
begin
  Result := TMemoryStream.Create;
  // ⚡ Bolt optimization: Cache EncodeStringBase64 result to avoid evaluating it twice during WriteBuffer.
  // ⚡ Bolt optimization: Removed intermediate TBytes array and TEncoding.UTF8 allocations.
  Base64Str := base64.EncodeStringBase64(AString);
  if Length(Base64Str) > 0 then
    Result.WriteBuffer(Base64Str[1], Length(Base64Str));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  RawStr: string;
begin
  SetLength(RawStr, AStream.Size);
  AStream.Position := 0;
  // ⚡ Bolt optimization: Read directly into native string buffer instead of intermediate TBytes + TEncoding
  if AStream.Size > 0 then
    AStream.ReadBuffer(RawStr[1], AStream.Size);
  Result := base64.EncodeStringBase64(RawStr);
end;

function FileToStringBase64(const FileName: string; const Apagar: Boolean; out size: integer): string;
var
   streamPdf: TMemoryStream;
begin
  streamPdf := TMemoryStream.Create;
  try
    streamPdf.LoadFromFile(fileName);

    if Apagar then
        DeleteFile(fileName);

    if streamPdf.Size = 0 then
    begin
      raise exception.Create('O arquivo gerado não parece ser válido.');
      Exit;
    end;

    // Converte a stream do relatório para base64
    Result := StreamToBase64String(streamPdf);
    // Tamanho em Bytes
    size := streamPdf.Size;
  finally
    streamPdf.Free;
  end;
end;

end.
