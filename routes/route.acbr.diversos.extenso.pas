unit route.acbr.diversos.extenso;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.diversos.extenso,
  jsonconvert,
  fpjson,
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloExtenso(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostExtenso(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloExtenso(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeExtenso;
begin
  Ac := TACBRBridgeExtenso.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Modelo));
  finally
    Ac.Free;
  end;
end;

procedure PostExtenso(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LData: TJSONData;
  O: TJSONObject;
  Ac: TACBRBridgeExtenso;
begin
  LData := nil;
  try
    LData := GetJSON(Req.Body);
  except
    on E: Exception do
    begin
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
         .Status(400)
         .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
           RSStatusField, RSStatusErro,
           RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message
         ])));
      Exit;
    end;
  end;

  if not Assigned(LData) or not (LData is TJSONObject) then
  begin
    FreeAndNil(LData);
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
         RSStatusField, RSStatusErro,
         RSMessageField, RSInvalidJSONBodyError
       ])));
    Exit;
  end;

  O := TJSONObject(LData);
  Ac := TACBRBridgeExtenso.Create;
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.TraduzValor(O)));
    except
      on E: Exception do
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
           .Status(400)
           .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
             RSStatusField, RSStatusErro,
             RSMessageField, E.Message
           ])));
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloDiversosExtensoRoute, GetModeloExtenso);
  THorse.Post(RSDiversosExtensoRoute, PostExtenso);
end;

end.
