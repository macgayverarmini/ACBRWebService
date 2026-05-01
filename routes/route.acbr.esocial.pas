unit route.acbr.esocial;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.esocial,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloConfigeSocial(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PosteSocial(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure regRouter;

implementation


function ExtractConfig(O: TJSONObject; const Field: string): string;
var
  Data: TJSONData;
begin
  Result := '';
  if Assigned(O) then
  begin
    Data := O.Extract(Field);
    if Assigned(Data) then
    begin
      Result := Data.AsJSON;
      Data.Free;
    end;
  end;
end;
procedure GetModeloConfigeSocial(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONeSocial;
begin
  AcM := TACBRModelosJSONeSocial.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelConfig.AsJSON);
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
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON inválido.']).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeeSocial.Create(ExtractConfig(O, 'config'));
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
