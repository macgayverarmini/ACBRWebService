unit route.acbr.boleto;

{$mode Delphi}{$H+}

interface

uses
  method.acbr.boleto,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
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
      Res.Status(400).Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, RSInvalidJSONBodyError + ' ' + E.Message])));
      Exit;
    end;
  end;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
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
