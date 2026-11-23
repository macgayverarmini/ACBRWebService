unit route.acbr.escpos;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.escpos,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloConfigEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetPortasDisponiveis(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure regRouter;

implementation

procedure GetModeloConfigEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONEscPos;
begin
  AcM := TACBRModelosJSONEscPos.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
  finally
    AcM.Free;
  end;
end;

procedure PostEscPos(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LData: TJSONData;
  O: TJSONObject;
  Ac: TACBRBridgeEscPos;
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
  Ac := TACBRBridgeEscPos.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.EscPos(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetPortasDisponiveis(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  Ac: TACBRBridgeEscPos;
begin
  Ac := TACBRBridgeEscPos.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.PortasDisponiveis));
  finally
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloEscPosConfigRoute, GetModeloConfigEscPos);
  THorse.Get(RSEscPosPortasRoute, GetPortasDisponiveis);
  THorse.Post(RSEscPosRoute, PostEscPos);
end;

end.
