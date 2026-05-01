program test_cte_rtti;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, RTTI, TypInfo, pcteCTe;

var
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Props: TRttiPropertyArray;
  i: Integer;
begin
  WriteLn('Testing TCTe properties...');
  Ctx := TRttiContext.Create(False);
  try
    RttiType := Ctx.GetType(TCTe);
    if RttiType = nil then
    begin
      WriteLn('TCTe type not found in RTTI!');
      Exit;
    end;

    Props := RttiType.GetProperties;
    WriteLn('TCTe Props Count: ', Length(Props));
    for i := 0 to Length(Props) - 1 do
      WriteLn('  - ', Props[i].Name, ' Vis=', Ord(Props[i].Visibility));
  finally
    Ctx.Free;
  end;
end.
