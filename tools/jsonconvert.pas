unit jsonconvert;

{$mode Delphi}

interface

uses
  fpjson,
  Horse.HandleException, jsonparser,
  pcnConversaoNFe, pcnConversao,
  Classes, SysUtils, fpjsonrtti;

type

  { TJSONTools }

  TJSONTools = class
  public
    class function ObjToJsonString(const Obj: TObject): string;
    class function ObjToJson(const Obj: TObject): TJSONObject;

    class procedure JsonStringToObj(const JsonString: string; const Obj: TObject);
    class procedure JsonToObj(const Json: TJSONObject; const Obj: TObject);
  end;

implementation

{ TJSONTools }

class function TJSONTools.ObjToJsonString(const Obj: TObject): string;
var
  Streamer: TJSONStreamer;
begin
  Streamer := TJSONStreamer.Create(nil);
  try
    Streamer.Options := Streamer.Options + [jsoDateTimeAsString, jsoTStringsAsArray];
    Result := Streamer.ObjectToJSONString(Obj);
  finally
    FreeAndNil(Streamer);
  end;
end;

class function TJSONTools.ObjToJson(const Obj: TObject): TJSONObject;
var
  Streamer: TJSONStreamer;
begin
  Streamer := TJSONStreamer.Create(nil);
  try
    Streamer.Options := Streamer.Options + [jsoDateTimeAsString, jsoTStringsAsArray];
    Result := Streamer.ObjectToJSON(Obj);
  finally
    FreeAndNil(Streamer)
  end;
end;

class procedure TJSONTools.JsonStringToObj(const JsonString: string; const Obj: TObject);
var
  Streamer: TJSONDeStreamer;
begin
  Streamer := TJSONDeStreamer.Create(nil);
  try
    Streamer.Options := [jdoIgnorePropertyErrors];
    Streamer.JSONToObject(JsonString, Obj);
  finally
    FreeAndNil(Streamer);
  end;
end;

class procedure TJSONTools.JsonToObj(const Json: TJSONObject; const Obj: TObject);
var
  Streamer: TJSONDeStreamer;
begin
  Streamer := TJSONDeStreamer.Create(nil);
  try
    Streamer.Options := [jdoIgnorePropertyErrors];
    Streamer.JSONToObject(Json, Obj);
  finally
    FreeAndNil(Streamer);
  end;
end;

end.
