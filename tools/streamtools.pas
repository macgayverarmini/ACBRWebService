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
  // Optimization: Read directly into string to avoid TBytes allocation overhead
  if AStream.Size = 0 then Exit('');
  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  encodedStr: string;
begin
  // Optimization: Cache Encoded string to avoid double evaluation in inline arguments
  // and directly use the native string input avoiding TBytes
  encodedStr := base64.EncodeStringBase64(AString);
  Result := TMemoryStream.Create;
  if Length(encodedStr) > 0 then
    Result.WriteBuffer(encodedStr[1], Length(encodedStr));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  rawStr: string;
begin
  // Optimization: Read directly into native string to avoid TBytes allocation
  if AStream.Size = 0 then Exit('');
  SetLength(rawStr, AStream.Size);
  AStream.Position := 0;
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
