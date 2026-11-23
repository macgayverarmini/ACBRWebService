unit method.acbr.diversos;

{$mode Delphi}
{$M+}

interface

uses
  TypInfo,
  ACBrCMC7,
  ACBrInStore,
  ACBrCargaBal,
  ACBrIBPTax,
  fpjson,
  jsonconvert,
  Base64,
  Classes,
  SysUtils,
  streamtools,
  resource.strings.global,
  ACBrEAD,
  ACBrValidador,
  ACBrMail;

type
  TACBRBridgeDiversos = class
  private
    fChavePrivada: AnsiString;
    fChavePublica: AnsiString;
    procedure DoGetChavePrivada(var Chave: AnsiString);
    procedure DoGetChavePublica(var Chave: AnsiString);
  public
    function ModelCMC7: TJSONObject;
    function ProcessarCMC7(const jCMC7: TJSONObject): TJSONObject;

    function ModelInStore: TJSONObject;
    function DesmembrarInStore(const jInStore: TJSONObject): TJSONObject;

    function ModelCargaBal: TJSONObject;
    function GerarCargaBalanca(const jCarga: TJSONObject): TJSONObject;

    function ModelIBPT: TJSONObject;
    function LerTabelaIBPT(const jIBPT: TJSONObject): TJSONObject;

    function ModelEAD: TJSONObject;
    function ProcessarEAD(const jEAD: TJSONObject): TJSONObject;

    function ModelCalcDigito: TJSONObject;
    function CalcularDigito(const jDigito: TJSONObject): TJSONObject;

    function ModelMail: TJSONObject;
    function EnviarEmail(const jMail: TJSONObject): TJSONObject;
  end;

implementation

{ TACBRBridgeDiversos }

function TACBRBridgeDiversos.ModelCMC7: TJSONObject;
var
  acbr: TACBrCMC7;
begin
  acbr := TACBrCMC7.Create(nil);
  try
    Result := TJSONTools.SafeObjToJson(acbr, 'Erro ao gerar modelo CMC7');
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.ProcessarCMC7(const jCMC7: TJSONObject): TJSONObject;
var
  acbr: TACBrCMC7;
  banda, banco, agencia, comp, numero, conta, tipif, b1, b2, b3: string;
begin
  acbr := TACBrCMC7.Create(nil);
  try
    try
      banda := Trim(jCMC7.Get('CMC7', ''));
      if banda <> '' then
      begin
        if Length(banda) = 34 then
          TJSONTools.JsonToObj(jCMC7, acbr)
        else
          acbr.CMC7 := FormataCMC7(banda);
      end
      else
      begin
        b1 := jCMC7.Get('CMC7Bloco1', jCMC7.Get('Bloco1', ''));
        b2 := jCMC7.Get('CMC7Bloco2', jCMC7.Get('Bloco2', ''));
        b3 := jCMC7.Get('CMC7Bloco3', jCMC7.Get('Bloco3', ''));
        if (b1 <> '') or (b2 <> '') or (b3 <> '') then
          acbr.MontaCMC7(b1, b2, b3)
        else
        begin
          banco := jCMC7.Get('Banco', '');
          agencia := jCMC7.Get('Agencia', '');
          comp := jCMC7.Get('Comp', '');
          numero := jCMC7.Get('Numero', '');
          conta := jCMC7.Get('Conta', '');
          tipif := jCMC7.Get('Tipificacao', '5');
          if tipif = '' then
            tipif := '5';
          acbr.MontaCMC7(banco, agencia, conta, numero, comp, tipif[1]);
        end;
      end;

      Result := TJSONTools.SafeObjToJson(acbr, 'Erro ao serializar CMC7');
      if Assigned(Result) then
      begin
        if Result.Find(RSStatusField) = nil then
          Result.Add(RSStatusField, RSStatusSucesso);
        if Result.Find('Bloco1') = nil then
          Result.Add('Bloco1', acbr.CMC7Bloco1);
        if Result.Find('Bloco2') = nil then
          Result.Add('Bloco2', acbr.CMC7Bloco2);
        if Result.Find('Bloco3') = nil then
          Result.Add('Bloco3', acbr.CMC7Bloco3);
      end;
    except
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.ModelInStore: TJSONObject;
var
  acbr: TACBrInStore;
begin
  acbr := TACBrInStore.Create(nil);
  try
    Result := TJSONTools.SafeObjToJson(acbr, 'Erro ao gerar modelo InStore');
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.DesmembrarInStore(const jInStore: TJSONObject): TJSONObject;
var
  acbr: TACBrInStore;
  etiqueta: string;
begin
  acbr := TACBrInStore.Create(nil);
  try
    try
      TJSONTools.JsonToObj(jInStore, acbr);
      etiqueta := jInStore.Get('CodigoEtiqueta', '');
      acbr.Desmembrar(etiqueta);

      Result := TJSONTools.SafeObjToJson(acbr, 'Erro ao serializar InStore');
      if Assigned(Result) and (Result.Find(RSStatusField) = nil) then
        Result.Add(RSStatusField, RSStatusSucesso);
    except
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.ModelCargaBal: TJSONObject;
var
  acbr: TACBrCargaBal;
begin
  acbr := TACBrCargaBal.Create(nil);
  try
    acbr.Produtos.New;
    Result := TJSONTools.SafeObjToJson(acbr, 'Erro ao gerar modelo CargaBal');
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.GerarCargaBalanca(const jCarga: TJSONObject): TJSONObject;
var
  acbr: TACBrCargaBal;
  tamanho: Integer;
  outDir: string;
  SR: TSearchRec;
  arrArquivos: TJSONArray;
  fileObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  acbr := TACBrCargaBal.Create(nil);
  outDir := ExtractFilePath(ParamStr(0)) + 'tmp' + PathDelim +
            'balanca_' + IntToStr(GetTickCount64) + '_' + IntToStr(Random(1000000)) + PathDelim;
  try
    try
      TJSONTools.JsonToObj(jCarga, acbr);

      ForceDirectories(outDir);
      acbr.GerarArquivos(outDir);

      arrArquivos := TJSONArray.Create;
      if FindFirst(outDir + '*.*', faAnyFile - faDirectory, SR) = 0 then
      begin
        repeat
          fileObj := TJSONObject.Create;
          fileObj.Add('nome', SR.Name);
          fileObj.Add('conteudo_base64', FileToStringBase64(outDir + SR.Name, True, tamanho));
          fileObj.Add('tamanho', tamanho);
          arrArquivos.Add(fileObj);
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('modelo', GetEnumName(TypeInfo(TACBrCargaBalModelo), Ord(acbr.Modelo)));
      Result.Add('modelo_str', acbr.ModeloStr);
      Result.Add('arquivos', arrArquivos);
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    if DirectoryExists(outDir) then
    begin
      if FindFirst(outDir + '*.*', faAnyFile - faDirectory, SR) = 0 then
      begin
        repeat
          SysUtils.DeleteFile(outDir + SR.Name);
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;
      RemoveDir(outDir);
    end;
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.ModelIBPT: TJSONObject;
var
  acbr: TACBrIBPTax;
begin
  acbr := TACBrIBPTax.Create(nil);
  try
    Result := TJSONTools.SafeObjToJson(acbr, 'Erro ao gerar modelo IBPTax');
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.LerTabelaIBPT(const jIBPT: TJSONObject): TJSONObject;
var
  acbr: TACBrIBPTax;
  b64Csv, fileName, ncm, ex, descricao: string;
  tabela, I, maxItems: Integer;
  aliqFedNac, aliqFedImp, aliqEst, aliqMun: Double;
  Stream: TStringStream;
  arrItens: TJSONArray;
begin
  Result := TJSONObject.Create;
  acbr := TACBrIBPTax.Create(nil);
  try
    try
      TJSONTools.JsonToObj(jIBPT, acbr);

      b64Csv := jIBPT.Get('arquivo_base64', '');
      fileName := jIBPT.Get('ArquivoNome', '');
      ncm := jIBPT.Get('NCM', '');

      if b64Csv <> '' then
      begin
        Stream := TStringStream.Create(DecodeStringBase64(b64Csv));
        try
          acbr.AbrirTabela(Stream);
        finally
          Stream.Free;
        end;
      end
      else if acbr.Arquivo.Count > 0 then
        acbr.AbrirTabela(acbr.Arquivo)
      else if fileName <> '' then
        acbr.AbrirTabela(fileName)
      else
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Informe "arquivo_base64", "Arquivo" ou "ArquivoNome" para abrir a tabela IBPT.');
        Exit;
      end;

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('Versao', acbr.VersaoArquivo);
      Result.Add('Chave', acbr.ChaveArquivo);
      Result.Add('Fonte', acbr.Fonte);
      Result.Add('VigenciaInicio', FormatDateTime('yyyy-mm-dd', acbr.VigenciaInicio));
      Result.Add('VigenciaFim', FormatDateTime('yyyy-mm-dd', acbr.VigenciaFim));
      Result.Add('TotalItens', acbr.Itens.Count);

      if ncm <> '' then
      begin
        if acbr.Procurar(ncm, ex, descricao, tabela, aliqFedNac, aliqFedImp, aliqEst, aliqMun, False) then
        begin
          Result.Add('Encontrado', True);
          Result.Add('NCM', ncm);
          Result.Add('Excecao', ex);
          Result.Add('Descricao', descricao);
          Result.Add('Tabela', tabela);
          Result.Add('FederalNacional', aliqFedNac);
          Result.Add('FederalImportado', aliqFedImp);
          Result.Add('Estadual', aliqEst);
          Result.Add('Municipal', aliqMun);
        end
        else
          Result.Add('Encontrado', False);
      end
      else
      begin
        arrItens := TJSONArray.Create;
        maxItems := jIBPT.Get('MaxItens', acbr.Itens.Count);
        if maxItems > acbr.Itens.Count then
          maxItems := acbr.Itens.Count;
        for I := 0 to maxItems - 1 do
          arrItens.Add(TJSONTools.SafeObjToJson(acbr.Itens[I], 'Erro ao serializar item IBPT'));
        Result.Add('Itens', arrItens);
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

procedure TACBRBridgeDiversos.DoGetChavePrivada(var Chave: AnsiString);
begin
  Chave := fChavePrivada;
end;

procedure TACBRBridgeDiversos.DoGetChavePublica(var Chave: AnsiString);
begin
  Chave := fChavePublica;
end;

function TACBRBridgeDiversos.ModelEAD: TJSONObject;
var
  acbr: TACBrEAD;
begin
  acbr := TACBrEAD.Create(nil);
  try
    Result := TJSONTools.SafeObjToJson(acbr, 'Erro ao gerar modelo EAD');
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.ProcessarEAD(const jEAD: TJSONObject): TJSONObject;
var
  acbr: TACBrEAD;
  operacao, conteudo, eadStr, dgstStr: string;
  pubKey, privKey: AnsiString;
  dgst: TACBrEADDgst;
  dgstOrd: Integer;
  ms: TMemoryStream;
  verificado: Boolean;
begin
  Result := TJSONObject.Create;
  acbr := TACBrEAD.Create(nil);
  try
    try
      TJSONTools.JsonToObj(jEAD, acbr);

      operacao := LowerCase(Trim(jEAD.Get('Operacao', 'calcular_ead')));
      fChavePrivada := AnsiString(jEAD.Get('ChavePrivada', ''));
      fChavePublica := AnsiString(jEAD.Get('ChavePublica', ''));
      conteudo := jEAD.Get('Conteudo', '');
      if (conteudo = '') and (jEAD.Get('arquivo_base64', '') <> '') then
        conteudo := DecodeStringBase64(jEAD.Get('arquivo_base64', ''));

      eadStr := jEAD.Get('EAD', '');
      dgstStr := Trim(jEAD.Get('Digest', 'dgstMD5'));
      dgstOrd := GetEnumValue(TypeInfo(TACBrEADDgst), dgstStr);
      if (dgstOrd >= Ord(Low(TACBrEADDgst))) and (dgstOrd <= Ord(High(TACBrEADDgst))) then
        dgst := TACBrEADDgst(dgstOrd)
      else
        dgst := dgstMD5;

      if fChavePrivada <> '' then
        acbr.OnGetChavePrivada := DoGetChavePrivada;
      if fChavePublica <> '' then
        acbr.OnGetChavePublica := DoGetChavePublica;

      if operacao = 'gerar_chaves' then
      begin
        pubKey := '';
        privKey := '';
        acbr.GerarChaves(pubKey, privKey);
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add('ChavePublica', string(pubKey));
        Result.Add('ChavePrivada', string(privKey));
      end
      else if operacao = 'verificar_ead' then
      begin
        if eadStr <> '' then
        begin
          ms := TMemoryStream.Create;
          try
            if Length(conteudo) > 0 then
              ms.Write(Pointer(AnsiString(conteudo))^, Length(AnsiString(conteudo)));
            ms.Position := 0;
            verificado := acbr.VerificarEAD(ms, eadStr);
          finally
            ms.Free;
          end;
        end
        else
          verificado := acbr.VerificarEAD(AnsiString(conteudo));

        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add('Valido', verificado);
      end
      else if operacao = 'calcular_hash' then
      begin
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add('Hash', string(acbr.CalcularHash(AnsiString(conteudo), dgst)));
      end
      else if operacao = 'md5' then
      begin
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add('MD5', acbr.MD5FromString(conteudo));
      end
      else
      begin
        eadStr := string(acbr.CalcularEAD(AnsiString(conteudo)));
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add('EAD', eadStr);
        Result.Add('LinhaEAD', 'EAD' + eadStr);
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversos.ModelCalcDigito: TJSONObject;
var
  calc: TACBrCalcDigito;
begin
  calc := TACBrCalcDigito.Create;
  try
    Result := TJSONTools.SafeObjToJson(calc, 'Erro ao gerar modelo CalcDigito');
  finally
    calc.Free;
  end;
end;

function TACBRBridgeDiversos.CalcularDigito(const jDigito: TJSONObject): TJSONObject;
var
  calc: TACBrCalcDigito;
begin
  calc := TACBrCalcDigito.Create;
  try
    try
      calc.FormulaDigito := frModulo11;
      calc.MultiplicadorInicial := 2;
      calc.MultiplicadorFinal := 9;
      TJSONTools.JsonToObj(jDigito, calc);

      if jDigito.Get('CalculoPadrao', False) then
        calc.CalculoPadrao;

      calc.Calcular;

      Result := TJSONTools.SafeObjToJson(calc, 'Erro ao serializar CalcDigito');
      if Assigned(Result) and (Result.Find(RSStatusField) = nil) then
        Result.Add(RSStatusField, RSStatusSucesso);
    except
      on E: Exception do
      begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    calc.Free;
  end;
end;

function TACBRBridgeDiversos.ModelMail: TJSONObject;
var
  mail: TACBrMail;
begin
  mail := TACBrMail.Create(nil);
  try
    Result := TJSONTools.SafeObjToJson(mail, 'Erro ao gerar modelo Mail');
  finally
    mail.Free;
  end;
end;

function TACBRBridgeDiversos.EnviarEmail(const jMail: TJSONObject): TJSONObject;
var
  mail: TACBrMail;
  nomeArq, b64Anexo, descAnexo: string;
  jNode, arrAnexos: TJSONData;
  arr: TJSONArray;
  objAnexo: TJSONObject;
  I: Integer;
  anexoStream, mimeStream: TMemoryStream;
  rawBytes: AnsiString;

  procedure AddEmailsFromNode(const AKey: string; const AKind: Integer);
  var
    LNode: TJSONData;
    LArr: TJSONArray;
    K: Integer;
    LEmail: string;
  begin
    LNode := jMail.Find(AKey);
    if not Assigned(LNode) then
      Exit;
    if LNode.JSONType = jtString then
    begin
      LEmail := Trim(LNode.AsString);
      if LEmail <> '' then
      begin
        case AKind of
          0: mail.AddAddress(LEmail);
          1: mail.AddCC(LEmail);
          2: mail.AddBCC(LEmail);
          3: mail.AddReplyTo(LEmail);
        end;
      end;
    end
    else if LNode.JSONType = jtArray then
    begin
      LArr := TJSONArray(LNode);
      for K := 0 to LArr.Count - 1 do
      begin
        LEmail := Trim(LArr.Items[K].AsString);
        if LEmail <> '' then
        begin
          case AKind of
            0: mail.AddAddress(LEmail);
            1: mail.AddCC(LEmail);
            2: mail.AddBCC(LEmail);
            3: mail.AddReplyTo(LEmail);
          end;
        end;
      end;
    end;
  end;

begin
  Result := TJSONObject.Create;
  mail := TACBrMail.Create(nil);
  mimeStream := TMemoryStream.Create;
  try
    try
      mail.Clear;
      mail.Port := '587';
      mail.SetTLS := True;
      mail.IsHTML := True;
      TJSONTools.JsonToObj(jMail, mail);
      mail.UseThread := False;
      if mail.From = '' then
        mail.From := mail.Username;

      AddEmailsFromNode('To', 0);
      AddEmailsFromNode('Para', 0);
      AddEmailsFromNode('Destinatarios', 0);
      AddEmailsFromNode('CC', 1);
      AddEmailsFromNode('Cc', 1);
      AddEmailsFromNode('Copia', 1);

      jNode := jMail.Find('BCC');
      if Assigned(jNode) and (jNode.JSONType = jtString) and (Trim(jNode.AsString) <> '') then
        mail.AddBCC(Trim(jNode.AsString));

      jNode := jMail.Find('ReplyTo');
      if Assigned(jNode) and (jNode.JSONType = jtString) and (Trim(jNode.AsString) <> '') then
        mail.AddReplyTo(Trim(jNode.AsString));

      jNode := jMail.Find('Body');
      if Assigned(jNode) and (jNode.JSONType = jtString) then
        mail.Body.Text := jNode.AsString;

      jNode := jMail.Find('AltBody');
      if Assigned(jNode) and (jNode.JSONType = jtString) then
        mail.AltBody.Text := jNode.AsString;

      arrAnexos := jMail.Find('Anexos');
      if Assigned(arrAnexos) and (arrAnexos.JSONType = jtArray) then
      begin
        arr := TJSONArray(arrAnexos);
        for I := 0 to arr.Count - 1 do
        begin
          if arr.Items[I].JSONType = jtObject then
          begin
            objAnexo := TJSONObject(arr.Items[I]);
            nomeArq := objAnexo.Get('nome', 'anexo_' + IntToStr(I + 1) + '.dat');
            descAnexo := objAnexo.Get('descricao', nomeArq);
            b64Anexo := objAnexo.Get('conteudo_base64', '');
            if b64Anexo <> '' then
            begin
              anexoStream := TMemoryStream.Create;
              try
                rawBytes := DecodeStringBase64(b64Anexo);
                if Length(rawBytes) > 0 then
                  anexoStream.Write(Pointer(rawBytes)^, Length(rawBytes));
                anexoStream.Position := 0;
                mail.AddAttachment(anexoStream, descAnexo, adAttachment);
              finally
                anexoStream.Free;
              end;
            end;
          end;
        end;
      end;

      if jMail.Get('ApenasGerarMime', False) then
      begin
        mail.SaveToStream(mimeStream);
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add('mime_base64', StreamToBase64String(mimeStream));
      end
      else
      begin
        mail.Send(False);
        Result.Add(RSStatusField, RSStatusSucesso);
        Result.Add(RSMessageField, 'E-mail enviado com sucesso.');
      end;
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    mimeStream.Free;
    mail.Free;
  end;
end;

end.
