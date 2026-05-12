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
  // ⚡ Bolt: Removed TBytes allocation and UTF-8 roundtrip. Direct string buffer read reduces memory allocation overhead and execution time.
  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  LBase64: string;
begin
  // ⚡ Bolt: Cached EncodeStringBase64 result to avoid evaluating it twice during WriteBuffer. Direct string buffer write avoids TBytes GC overhead.
  LBase64 := base64.EncodeStringBase64(AString);
  Result := TMemoryStream.Create;
  if Length(LBase64) > 0 then
    Result.WriteBuffer(LBase64[1], Length(LBase64));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  LStr: string;
begin
  // ⚡ Bolt: Removed TBytes allocation and UTF-8 roundtrip. Direct string buffer read reduces memory allocation overhead and execution time.
  SetLength(LStr, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(LStr[1], AStream.Size);
  Result := base64.EncodeStringBase64(LStr);
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
