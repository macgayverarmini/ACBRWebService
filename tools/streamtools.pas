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
  if AStream.Size > 0 then
  begin
    // ⚡ Bolt: Direct string allocation avoids intermediate TBytes and TEncoding overhead
    SetLength(strBase64, AStream.Size);
    AStream.Position := 0;
    AStream.ReadBuffer(strBase64[1], AStream.Size);
    Result := base64.DecodeStringBase64(strBase64);
  end
  else
    Result := '';
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  LBase64Str: string;
begin
  Result := TMemoryStream.Create;
  // ⚡ Bolt: Cache base64 result to avoid double evaluation and intermediate TBytes allocation
  LBase64Str := base64.EncodeStringBase64(AString);
  if Length(LBase64Str) > 0 then
    Result.WriteBuffer(LBase64Str[1], Length(LBase64Str));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  strContent: string;
begin
  if AStream.Size > 0 then
  begin
    // ⚡ Bolt: Direct string allocation avoids intermediate TBytes and TEncoding overhead
    SetLength(strContent, AStream.Size);
    AStream.Position := 0;
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
