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

function TryParseJsonObject(const ABody: string; Res: THorseResponse; out AObj: TJSONObject): Boolean;
var
  LData: TJSONData;
begin
  Result := False;
  AObj := nil;
  LData := nil;
  try
    LData := GetJSON(ABody);
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

  if not Assigned(LData) then
  begin
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
         RSStatusField, RSStatusErro,
         RSMessageField, RSInvalidJSONBodyError
       ])));
    Exit;
  end;

  if not (LData is TJSONObject) then
  begin
    LData.Free;
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create([
         RSStatusField, RSStatusErro,
         RSMessageField, RSNotJSONObjectError
       ])));
    Exit;
  end;

  AObj := TJSONObject(LData);
  Result := True;
end;

procedure GetModeloBoletoConfig(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONBoleto;
begin
  AcM := TACBRModelosJSONBoleto.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(AcM.ModelConfig));
  finally
    AcM.Free;
  end;
end;

procedure GetModeloBoletoTitulo(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONBoleto;
begin
  AcM := TACBRModelosJSONBoleto.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(AcM.ModelTitulo));
  finally
    AcM.Free;
  end;
end;

procedure PostBoletoPDF(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.GerarPDF(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostBoletoRemessa(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.GerarRemessa(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostBoletoRetorno(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.LerRetorno(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure GetModeloBoletoPixQRCode(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONBoleto;
begin
  AcM := TACBRModelosJSONBoleto.Create('');
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(AcM.ModelPixQRCode));
  finally
    AcM.Free;
  end;
end;

procedure PostBoletoPixQRCode(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.GerarPixQRCode(O)));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostBoletoEnviar(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeBoleto;
begin
  if not TryParseJsonObject(Req.Body, Res, O) then
    Exit;

  Ac := TACBRBridgeBoleto.Create(TJSONTools.ExtractConfig(O));
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.EnviarWebService(O)));
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
