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
  // Bolt optimization: Directly read into native string, avoiding TBytes allocation via TEncoding.UTF8
  AStream.Position := 0;
  if AStream.Size > 0 then
  begin
    SetLength(strBase64, AStream.Size);
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  end
  else
    strBase64 := '';

  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  EncodedStr: string;
begin
  Result := TMemoryStream.Create;
  // Bolt optimization: Pre-compute encoded string to avoid redundant processing, write string directly to buffer
  EncodedStr := base64.EncodeStringBase64(AString);
  if Length(EncodedStr) > 0 then
    Result.WriteBuffer(EncodedStr[1], Length(EncodedStr));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  strContent: string;
begin
  // Bolt optimization: Read directly into native string instead of intermediate TBytes
  AStream.Position := 0;
  if AStream.Size > 0 then
  begin
    SetLength(strContent, AStream.Size);
    AStream.ReadBuffer(strContent[1], AStream.Size);
    Result := base64.EncodeStringBase64(strContent);
  end
  else
    Result := '';
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
