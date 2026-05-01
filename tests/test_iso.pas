program test_iso;
uses SysUtils, DateUtils;
var d: TDateTime;
begin
  if TryISO8601ToDate('2026-04-26T13:46:56', d) then 
    Writeln('ISO8601ToDate works: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', d));
end.
