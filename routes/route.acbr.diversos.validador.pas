unit route.acbr.diversos.validador;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.diversos.validador,
  jsonconvert,
  fpjson,
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloValidador(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostValidar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloValidador(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeValidador;
begin
  Ac := TACBRBridgeValidador.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Modelo));
  finally
    Ac.Free;
  end;
end;

procedure PostValidar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LData: TJSONData;
  O: TJSONObject;
  Ac: TACBRBridgeValidador;
  LBool: TJSONBoolean;
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
  Ac := TACBRBridgeValidador.Create;
  try
    try
      LBool := Ac.Validar(O);
      try
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LBool.AsJSON);
      finally
        LBool.Free;
      end;
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
  THorse.Get(RSModeloDiversosValidadorRoute, GetModeloValidador);
  THorse.Post(RSDiversosValidadorRoute, PostValidar);
end;

end.
