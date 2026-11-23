unit route.acbr.certificados;

{$mode Delphi}
{$DEFINE UseGenerics}

interface

uses
  method.acbr.certificados,
  jsonconvert,
  fpjson, Horse, Horse.Commons, Classes, SysUtils,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

procedure GetModeloUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);

procedure PostUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
procedure PostLerDadosCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);

procedure regRouter;

implementation

procedure GetModeloUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  Ac: TACBRBridgeCertificados;
begin
  Ac := TACBRBridgeCertificados.Create;
  try
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Send(TJSONTools.JsonAndFree(Ac.ModeloUpload));
  finally
    Ac.Free;
  end;
end;

procedure PostUploadCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  LJsonBody: TJSONData;
  O: TJSONObject;
  Ac: TACBRBridgeCertificados;
  CertificadoBase64, Senha, CNPJ, NomeArquivo: string;
  JsonStr: TJSONString;
begin
  try
    LJsonBody := GetJSON(Req.Body);
  except
    on E: Exception do
    begin
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
         .Status(400)
         .Send(TJSONTools.JsonAndFree(TJSONObject.Create(
           [RSMessageField, RSJSONParseError + E.Message])));
      Exit;
    end;
  end;

  if not Assigned(LJsonBody) then
  begin
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create(
         [RSMessageField, RSInvalidJSONBodyError])));
    Exit;
  end;

  if not (LJsonBody is TJSONObject) then
  begin
    LJsonBody.Free;
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create(
         [RSMessageField, RSNotJSONObjectError])));
    Exit;
  end;
  O := LJsonBody as TJSONObject;
  try
    try
      if O.Find('DadosPFX', JsonStr) or O.Find(RSCertificadoBase64Field, JsonStr) then
      begin
        CertificadoBase64 := JsonStr.Value;
        if CertificadoBase64 = '' then
          raise Exception.Create(RSCertificadoBase64EmptyError);
      end
      else
        raise Exception.Create(RSCertificadoBase64NotFoundError);

      if O.Find('Senha', JsonStr) or O.Find(RSSenhaField, JsonStr) then
      begin
        Senha := JsonStr.Value;
        if Senha = '' then
          raise Exception.Create(RSSenhaEmptyError);
      end
      else
        raise Exception.Create(RSSenhaNotFoundError);

      if O.Find('CNPJ', JsonStr) or O.Find(RSCNPJField, JsonStr) then
        CNPJ := JsonStr.Value
      else
        CNPJ := '';

      if O.Find('ArquivoPFX', JsonStr) or O.Find(RSNomeArquivoField, JsonStr) then
        NomeArquivo := JsonStr.Value
      else
        NomeArquivo := '';

      Ac := TACBRBridgeCertificados.Create;
      try
        LJsonBody := Ac.SalvarCertificado(CertificadoBase64, Senha, CNPJ, NomeArquivo);
        try
          Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJsonBody.AsJSON);
        finally
          LJsonBody.Free;
        end;
      finally
        Ac.Free;
      end;
    except
      on E: Exception do
      begin
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
           .Status(400)
           .Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, E.Message])));
      end;
    end;
  finally
    O.Free;
  end;
end;

procedure PostLerDadosCertificado(Req: THorseRequest; Res: THorseResponse;
  Next: TNextProc);
var
  LJsonBody: TJSONData;
  O: TJSONObject;
  Ac: TACBRBridgeCertificados;
  CertificadoBase64, Senha: string;
  JsonStr: TJSONString;
begin
  try
    LJsonBody := GetJSON(Req.Body);
  except
    on E: Exception do
    begin
      Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
         .Status(400)
         .Send(TJSONTools.JsonAndFree(TJSONObject.Create(
           [RSMessageField, RSJSONParseError + E.Message])));
      Exit;
    end;
  end;

  if not Assigned(LJsonBody) then
  begin
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create(
         [RSMessageField, RSInvalidJSONBodyError])));
    Exit;
  end;

  if not (LJsonBody is TJSONObject) then
  begin
    LJsonBody.Free;
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
       .Status(400)
       .Send(TJSONTools.JsonAndFree(TJSONObject.Create(
         [RSMessageField, RSNotJSONObjectError])));
    Exit;
  end;
  O := LJsonBody as TJSONObject;

  try
    try
      if O.Find('DadosPFX', JsonStr) or O.Find(RSCertificadoBase64Field, JsonStr) then
      begin
        CertificadoBase64 := JsonStr.Value;
        if CertificadoBase64 = '' then
          raise Exception.Create(RSCertificadoBase64EmptyError);
      end
      else
        raise Exception.Create(RSCertificadoBase64NotFoundError);

      if O.Find('Senha', JsonStr) or O.Find(RSSenhaField, JsonStr) then
      begin
        Senha := JsonStr.Value;
        if Senha = '' then
          raise Exception.Create(RSSenhaEmptyError);
      end
      else
        raise Exception.Create(RSSenhaNotFoundError);

      Ac := TACBRBridgeCertificados.Create;
      try
        LJsonBody := Ac.ObterDadosCertificado(CertificadoBase64, Senha);
        try
          Res.ContentType(TMimeTypes.ApplicationJSON.ToString).Send(LJsonBody.AsJSON);
        finally
          LJsonBody.Free;
        end;
      finally
        Ac.Free;
      end;
    except
      on E: Exception do
      begin
        Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
           .Status(400)
           .Send(TJSONTools.JsonAndFree(TJSONObject.Create([RSMessageField, E.Message])));
      end;
    end;
  finally
    O.Free;
  end;
end;

procedure regRouter;
begin
  THorse.Get(RSModeloCertificadosUploadRoute, GetModeloUploadCertificado);
  THorse.Get(RSCertificadosUploadRoute, GetModeloUploadCertificado);

  THorse.Post(RSCertificadosUploadRoute, PostUploadCertificado);
  THorse.Post(RSCertificadosLerDadosRoute, PostLerDadosCertificado);
end;

end.
