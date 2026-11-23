unit route.acbr.sped;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.sped,
  jsonconvert,
  fpjson,
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloConfigSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloGerarSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConfigSPEDPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloGerarSPEDPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloImportarSPEDPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGerar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostImportarFiscal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostGerarPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostImportarPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloConfigSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSPED;
begin
  AcM := TACBRModelosJSONSPED.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
  finally
    AcM.Free;
  end;
end;

procedure GetModeloGerarSPED(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSPED;
begin
  AcM := TACBRModelosJSONSPED.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelGerar));
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeSPED.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.SPED(O)));
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
  Ac := TACBRBridgeSPED.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Gerar(O)));
    except
      on E: Exception do
        Res.Status(500).Send(E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloConfigSPEDPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSPEDPisCofins;
begin
  AcM := TACBRModelosJSONSPEDPisCofins.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
  finally
    AcM.Free;
  end;
end;

procedure GetModeloGerarSPEDPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSPEDPisCofins;
begin
  AcM := TACBRModelosJSONSPEDPisCofins.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelGerar));
  finally
    AcM.Free;
  end;
end;

procedure PostGerarPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSPEDPisCofins;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeSPEDPisCofins.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Gerar(O)));
    except
      on E: Exception do
        Res.Status(500).Send(E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostImportarFiscal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeSPED;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeSPED.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Importar(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostImportarPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeSPEDPisCofins;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  Ac := TACBRBridgeSPEDPisCofins.Create(TJSONTools.ExtractConfig(O));
  try
    LJson := Ac.Importar(O);
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloImportarSPEDPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSPEDPisCofins;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONSPEDPisCofins.Create('');
  try
    LJson := AcM.ModelImportar;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloSPEDConfigRoute, GetModeloConfigSPED);
  THorse.Get(RSModeloSPEDGerarRoute, GetModeloGerarSPED);
  THorse.Get(RSModeloSPEDPisCofinsConfigRoute, GetModeloConfigSPEDPisCofins);
  THorse.Get(RSModeloSPEDPisCofinsGerarRoute, GetModeloGerarSPEDPisCofins);
  THorse.Get(RSModeloSPEDPisCofinsImportarRoute, GetModeloImportarSPEDPisCofins);
  THorse.Post(RSSPEDRoute, PostSPED);
  THorse.Post(RSSPEDGerarRoute, PostGerar);
  THorse.Post(RSSPEDFiscalImportarRoute, PostImportarFiscal);
  THorse.Post(RSSPEDPisCofinsGerarRoute, PostGerarPisCofins);
  THorse.Post(RSSPEDPisCofinsImportarRoute, PostImportarPisCofins);
end;

end.
