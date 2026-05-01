program TestCTeProps;
{$mode objfpc}{$H+}
uses SysUtils, Rtti, pcteCTe;
var
  Ctx: TRttiContext;
  T: TRttiType;
  Props: array of TRttiProperty;
  i: Integer;
begin
  Ctx := TRttiContext.Create(False);
  T := Ctx.GetType(TCTe);
  if T <> nil then
  begin
    Props := T.GetProperties;
    WriteLn('TCTe tem ', Length(Props), ' propriedades.');
    if Length(Props) > 0 then
      for i := 0 to Length(Props) - 1 do
        WriteLn(' - ', Props[i].Name);
  end
  else
    WriteLn('TCTe nil');
end.
