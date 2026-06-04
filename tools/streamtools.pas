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
  // ⚡ Bolt Optimization: Replace intermediate TBytes arrays with native strings
  // Read directly into string using ReadBuffer to avoid TEncoding.UTF8.GetString overhead
  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  LBase64Str: string;
begin
  Result := TMemoryStream.Create;
  // ⚡ Bolt Optimization: Avoid unnecessary string-to-bytes-to-string round-trips
  // Pre-compute EncodeStringBase64 to prevent redundant evaluation in WriteBuffer arguments
  LBase64Str := base64.EncodeStringBase64(AString);
  if Length(LBase64Str) > 0 then
    Result.WriteBuffer(LBase64Str[1], Length(LBase64Str));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  strContent: string;
begin
  // ⚡ Bolt Optimization: Replace intermediate TBytes arrays with native strings
  // Read directly into string using ReadBuffer to avoid TEncoding.UTF8.GetString overhead
  SetLength(strContent, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(strContent[1], AStream.Size);
  Result := base64.EncodeStringBase64(strContent);
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
