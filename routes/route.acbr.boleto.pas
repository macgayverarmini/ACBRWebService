unit route.acbr.boleto;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.boleto,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.routes;

procedure GetModeloBoletoConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloBoletoTitulo(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostBoletoPDF(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostBoletoRemessa(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostBoletoRetorno(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloBoletoPixQRCode(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostBoletoPixQRCode(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostBoletoEnviar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

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

procedure GetModeloBoletoConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONBoleto;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONBoleto.Create('');
  try
    LJson := AcM.ModelConfig;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure GetModeloBoletoTitulo(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONBoleto;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONBoleto.Create('');
  try
    LJson := AcM.ModelTitulo;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostBoletoPDF(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.GerarPDF(O);
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

procedure PostBoletoRemessa(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.GerarRemessa(O);
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

procedure PostBoletoRetorno(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.LerRetorno(O);
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

procedure GetModeloBoletoPixQRCode(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONBoleto;
  LJson: TJSONObject;
begin
  AcM := TACBRModelosJSONBoleto.Create('');
  try
    LJson := AcM.ModelPixQRCode;
    try
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJson.AsJSON);
    finally
      LJson.Free;
    end;
  finally
    AcM.Free;
  end;
end;

procedure PostBoletoPixQRCode(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.GerarPixBrCode(O);
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

procedure PostBoletoEnviar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O, LJson: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  try
    O := GetJSON(Req.Body) as TJSONObject;
  except
    on E: Exception do
    begin
      Res.Status(400).Send(TJSONObject.Create(['message', 'Corpo JSON invalido: ' + E.Message]).AsJSON);
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(ExtractConfig(O, 'config'));
  try
    LJson := Ac.EnviarWebService(O);
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

procedure regRouter;
begin
  THorse.Get(RSModeloBoletoConfigRoute, GetModeloBoletoConfig);
  THorse.Get(RSModeloBoletoTituloRoute, GetModeloBoletoTitulo);
  THorse.Get(RSModeloBoletoPixQRCodeRoute, GetModeloBoletoPixQRCode);
  THorse.Get(RSModeloBoletoPixEMVRoute, GetModeloBoletoPixQRCode);
  THorse.Post(RSBoletoPDFRoute, PostBoletoPDF);
  THorse.Post(RSBoletoRemessaRoute, PostBoletoRemessa);
  THorse.Post(RSBoletoRetornoRoute, PostBoletoRetorno);
  THorse.Post(RSBoletoPixQRCodeRoute, PostBoletoPixQRCode);
  THorse.Post(RSBoletoPixEMVRoute, PostBoletoPixQRCode);
  THorse.Post(RSBoletoEnviarRoute, PostBoletoEnviar);
end;

end.
