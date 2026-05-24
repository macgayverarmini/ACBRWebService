program benchmark;
{$mode objfpc}{$H+}
uses SysUtils, Classes, streamtools;

var
  t1, t2: QWord;
  i: Integer;
  ms: TMemoryStream;
  s: string;
  testStr: string;
begin
  SetLength(testStr, 10000);
  for i := 1 to 10000 do testStr[i] := 'A';

  t1 := GetTickCount64;
  for i := 1 to 10000 do
  begin
    ms := StringToBase64Stream(testStr);
    ms.Free;
  end;
  t2 := GetTickCount64;
  WriteLn('StringToBase64Stream: ', t2 - t1, ' ms');
end.
