unit jsonconvert;

{$mode Delphi}

interface

uses
  fpjson,
  Horse.HandleException, Base64, jsonparser, ACBrDFeSSL,
  ACBrNFe, pcnConversaoNFe, pcnConversao, pcnEnvEventoNFe, ACBrDFeConfiguracoes,
  pcnEventoNFe, ACBrNFeConfiguracoes, Classes, SysUtils, fpjsonrtti;

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
    Streamer.Destroy;
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
    Streamer.Destroy;
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
    Streamer.Destroy;
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
    Streamer.Destroy;
  end;
end;

end.
