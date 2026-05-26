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
  // Optimization: Read directly into native string buffer to avoid intermediate TBytes allocation
  SetLength(strBase64, AStream.Size);
  if AStream.Size > 0 then
  begin
    AStream.Position := 0;
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  end;
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  EncodedStr: string;
begin
  // Optimization: Avoid double evaluation of EncodeStringBase64 and intermediate TBytes allocation
  EncodedStr := base64.EncodeStringBase64(AString);
  Result := TMemoryStream.Create;
  if Length(EncodedStr) > 0 then
  begin
    Result.WriteBuffer(EncodedStr[1], Length(EncodedStr));
  end;
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  RawStr: string;
begin
  // Optimization: Read directly into native string buffer to avoid intermediate TBytes allocation
  SetLength(RawStr, AStream.Size);
  if AStream.Size > 0 then
  begin
    AStream.Position := 0;
    AStream.ReadBuffer(RawStr[1], AStream.Size);
  end;
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
