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
  Result := '';
  if AStream.Size = 0 then Exit;

  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  // ⚡ Bolt: Read directly into native string buffer to avoid TBytes allocations
  // ⚡ Bolt: Use ReadBuffer instead of Read for safer error handling
  AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  EncodedStr: string;
begin
  Result := TMemoryStream.Create;
  // ⚡ Bolt: Store expensive EncodeStringBase64 result in local var to avoid redundant calls
  // ⚡ Bolt: Avoided unnecessary TEncoding.UTF8 round trips
  EncodedStr := base64.EncodeStringBase64(AString);
  if Length(EncodedStr) > 0 then
    Result.WriteBuffer(EncodedStr[1], Length(EncodedStr));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  strStream: string;
begin
  Result := '';
  if AStream.Size = 0 then Exit;

  SetLength(strStream, AStream.Size);
  AStream.Position := 0;
  // ⚡ Bolt: Read directly into native string buffer to avoid TBytes allocations
  // ⚡ Bolt: Use ReadBuffer instead of Read for safer error handling
  AStream.ReadBuffer(strStream[1], AStream.Size);
  Result := base64.EncodeStringBase64(strStream);
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
