unit route.acbr.sped;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.sped,
  jsonconvert,
  fpjson,
  jsonparser,
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

procedure SendJsonError(Res: THorseResponse; const AStatus: Integer; const AMsg: string);
var
  LErr: TJSONObject;
begin
  LErr := TJSONObject.Create;
  LErr.Add(RSStatusField, RSStatusErro);
  LErr.Add(RSMessageField, AMsg);
  Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
     .Status(AStatus)
     .Send(TJSONTools.JsonAndFree(LErr));
end;

function TryParseJsonObjectBody(Req: THorseRequest; Res: THorseResponse; out AObj: TJSONObject): Boolean;
var
  LData: TJSONData;
begin
  Result := False;
  AObj := nil;
  if Trim(Req.Body) = '' then
  begin
    SendJsonError(Res, 400, RSInvalidJSONBodyError);
    Exit;
  end;
  try
    LData := GetJSON(Req.Body);
  except
    on E: Exception do
    begin
      SendJsonError(Res, 400, RSInvalidJSONBodyError);
      Exit;
    end;
  end;
  if not Assigned(LData) then
  begin
    SendJsonError(Res, 400, RSInvalidJSONBodyError);
    Exit;
  end;
  if not (LData is TJSONObject) then
  begin
    LData.Free;
    SendJsonError(Res, 400, RSNotJSONObjectError);
    Exit;
  end;
  AObj := TJSONObject(LData);
  Result := True;
end;

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
  if not TryParseJsonObjectBody(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeSPED.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.SPED(O)));
    except
      on E: Exception do
        SendJsonError(Res, 500, E.Message);
    end;
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
  if not TryParseJsonObjectBody(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeSPED.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Gerar(O)));
    except
      on E: Exception do
        SendJsonError(Res, 500, E.Message);
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
  if not TryParseJsonObjectBody(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeSPEDPisCofins.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Gerar(O)));
    except
      on E: Exception do
        SendJsonError(Res, 500, E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostImportarFiscal(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSPED;
begin
  if not TryParseJsonObjectBody(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeSPED.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Importar(O)));
    except
      on E: Exception do
        SendJsonError(Res, 500, E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostImportarPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeSPEDPisCofins;
begin
  if not TryParseJsonObjectBody(Req, Res, O) then
    Exit;

  Ac := TACBRBridgeSPEDPisCofins.Create(TJSONTools.ExtractConfig(O));
  try
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(Ac.Importar(O)));
    except
      on E: Exception do
        SendJsonError(Res, 500, E.Message);
    end;
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloImportarSPEDPisCofins(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONSPEDPisCofins;
begin
  AcM := TACBRModelosJSONSPEDPisCofins.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(TJSONTools.JsonAndFree(AcM.ModelImportar));
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
