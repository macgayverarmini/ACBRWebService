program test_rtti2;
{$mode objfpc}{$H+}
uses SysUtils, fpjson, jsonparser, fpjsonrtti, pcteCTe;
var
  cte: TCTe;
  streamer: TJSONDeStreamer;
  json: TJSONObject;
begin
  cte := TCTe.Create;
  json := GetJSON('{"ide": {"cUF": 35, "CFOP": 5352}, "vPrest": {"vTPrest": 10265.06}}') as TJSONObject;
  streamer := TJSONDeStreamer.Create(nil);
  streamer.Options := [jdoIgnorePropertyErrors, jdoCaseInsensitive];
  streamer.JSONToObject(json, cte);
  Writeln('cUF: ', cte.ide.cUF);
  Writeln('CFOP: ', cte.ide.CFOP);
  Writeln('vTPrest: ', cte.vPrest.vTPrest);
  cte.Free;
  json.Free;
  streamer.Free;
end.
