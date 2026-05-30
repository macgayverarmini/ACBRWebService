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
  // Optimization: Read directly into a pre-allocated string instead of using TBytes
  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  EncStr: string;
begin
  Result := TMemoryStream.Create;
  // Optimization: Prevent redundant EncodeStringBase64 calls by storing result in a local variable,
  // and write directly from the string without TBytes allocation.
  EncStr := base64.EncodeStringBase64(AString);
  if Length(EncStr) > 0 then
    Result.WriteBuffer(EncStr[1], Length(EncStr));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  rawStr: string;
begin
  // Optimization: Read directly into a pre-allocated string instead of using TBytes
  SetLength(rawStr, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(rawStr[1], AStream.Size);
  Result := base64.EncodeStringBase64(rawStr);
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
