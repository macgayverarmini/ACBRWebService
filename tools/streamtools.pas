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
  // ⚡ Bolt: Read directly into a string, avoiding intermediate TBytes arrays
  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  LEncodedStr: string;
begin
  Result := TMemoryStream.Create;
  // ⚡ Bolt: Cache EncodeStringBase64 result to avoid double evaluation
  // ⚡ Bolt: Write directly from string to stream, avoiding intermediate TBytes arrays
  LEncodedStr := base64.EncodeStringBase64(AString);
  if Length(LEncodedStr) > 0 then
    Result.WriteBuffer(LEncodedStr[1], Length(LEncodedStr));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  LRawStr: string;
begin
  // ⚡ Bolt: Read directly into string to avoid intermediate TBytes conversion overhead
  SetLength(LRawStr, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(LRawStr[1], AStream.Size);
  Result := base64.EncodeStringBase64(LRawStr);
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
