unit route.acbr.sped;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.sped,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloConfigSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

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
procedure GetModeloConfigSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSPED;
begin
  AcM := TACBRModelosJSONSPED.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(AcM.ModelConfig.AsJSON);
  finally
    AcM.Free;
  end;
end;

procedure PostSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSPED;
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

  Ac := TACBRBridgeSPED.Create(ExtractConfig(O, 'config'));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.SPED(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSPED;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeSPED.Create(ExtractConfig(O, 'config'));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send<TJSONObject>(Ac.Gerar(O));
    except
      on E: Exception do
        Res.Status(500).Send(E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloSPEDConfigRoute, GetModeloConfigSPED);
  THorse.Post(RSSPEDRoute, PostSPED);
  THorse.Post(RSSPEDGerarRoute, PostGerar);
end;

end.
