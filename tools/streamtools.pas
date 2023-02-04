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
  LBytes: TBytes;
  strBase64: string;
begin
  SetLength(LBytes, AStream.Size);
  AStream.Position := 0;
  AStream.Read(LBytes[0], AStream.Size);
  strBase64 := TEncoding.UTF8.GetString(LBytes);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AString);
  Result := TMemoryStream.Create;
  Result.WriteBuffer(base64.EncodeStringBase64(TEncoding.UTF8.GetString(LBytes))[1], Length(base64.EncodeStringBase64(TEncoding.UTF8.GetString(LBytes))));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AStream.Size);
  AStream.Position := 0;
  AStream.Read(LBytes[0], AStream.Size);
  Result := base64.EncodeStringBase64(TEncoding.UTF8.GetString(LBytes));
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

