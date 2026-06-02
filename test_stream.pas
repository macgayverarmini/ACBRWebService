program test_stream;
{$mode Delphi}
uses Classes, SysUtils, Base64;

function Base64StreamToString(AStream: TMemoryStream): string;
var
  strBase64: string;
begin
  SetLength(strBase64, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(strBase64[1], AStream.Size);
  Result := base64.DecodeStringBase64(strBase64);
end;

function StringToBase64Stream(AString: string): TMemoryStream;
var
  Base64Str: string;
begin
  Result := TMemoryStream.Create;
  Base64Str := base64.EncodeStringBase64(AString);
  if Length(Base64Str) > 0 then
    Result.WriteBuffer(Base64Str[1], Length(Base64Str));
  Result.Position := 0;
end;

function StreamToBase64String(AStream: TMemoryStream): string;
var
  RawStr: string;
begin
  SetLength(RawStr, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then
    AStream.ReadBuffer(RawStr[1], AStream.Size);
  Result := base64.EncodeStringBase64(RawStr);
end;

var
  ms: TMemoryStream;
  s, decoded, encoded: string;
begin
  s := 'Hello World! This is a test string.';
  ms := StringToBase64Stream(s);
  try
    decoded := Base64StreamToString(ms);
    WriteLn('Decoded: ', decoded);

    encoded := StreamToBase64String(ms);
    WriteLn('Encoded: ', encoded);
  finally
    ms.Free;
  end;
end.
