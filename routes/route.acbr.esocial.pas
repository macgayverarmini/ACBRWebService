unit route.acbr.esocial;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.esocial,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloConfigeSocial(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PosteSocial(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure regRouter;

implementation

procedure GetModeloConfigeSocial(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONeSocial;
begin
  AcM := TACBRModelosJSONeSocial.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
  finally
    AcM.Free;
  end;
end;

procedure PosteSocial(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeeSocial;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeeSocial.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.eSocial(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloeSocialConfigRoute, GetModeloConfigeSocial);
  THorse.Post(RSeSocialRoute, PosteSocial);
end;

end.
