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
  if AStream.Size = 0 then
    Exit('');

  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  // Read directly into the string without intermediate TBytes
  AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  strEncoded: string;
begin
  Result := TMemoryStream.Create;
  strEncoded := base64.EncodeStringBase64(AString);
  if Length(strEncoded) > 0 then
    Result.WriteBuffer(strEncoded[1], Length(strEncoded));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  strData: string;
begin
  if AStream.Size = 0 then
    Exit('');

  SetLength(strData, AStream.Size);
  AStream.Position := 0;
  // Read directly into the string without intermediate TBytes
  AStream.ReadBuffer(strData[1], AStream.Size);
  Result := base64.EncodeStringBase64(strData);
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
