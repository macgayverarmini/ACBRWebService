unit method.acbr.diversos;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  TypInfo,
  ACBrCMC7,
  ACBrInStore,
  ACBrCargaBal,
  ACBrIBPTax,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
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
begin
  Result := TJSONObject.Create;
  Result.Add('CMC7', '<00100049<0030000065>900000000109:');
  Result.Add('Banco', '001');
  Result.Add('Agencia', '0004');
  Result.Add('Comp', '003');
  Result.Add('Numero', '000006');
  Result.Add('Conta', '0000000001');
  Result.Add('Tipificacao', '5');
end;

function TACBRBridgeDiversos.ProcessarCMC7(const jCMC7: TJSONObject): TJSONObject;
var
  acbr: TACBrCMC7;
  banda, banco, agencia, comp, numero, conta, tipif: string;
begin
  Result := TJSONObject.Create;
  acbr := TACBrCMC7.Create(nil);
  try
    try
      banda := jCMC7.Get('CMC7', '');
      if banda <> '' then
        acbr.CMC7 := FormataCMC7(banda)
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

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('CMC7', acbr.CMC7);
      Result.Add('Banco', acbr.Banco);
      Result.Add('Agencia', acbr.Agencia);
      Result.Add('DvCCT', string(acbr.DvCCT));
      Result.Add('Comp', acbr.Comp);
      Result.Add('Numero', acbr.Numero);
      Result.Add('Conta', acbr.Conta);
      Result.Add('Tipificacao', string(acbr.Tipificacao));
      Result.Add('DvBcoAg', string(acbr.DvBcoAg));
      Result.Add('DvCMC7', string(acbr.DvCMC7));
      Result.Add('C1', acbr.C1);
      Result.Add('C2', acbr.C2);
      Result.Add('C3', acbr.C3);
      Result.Add('Bloco1', acbr.CMC7Bloco1);
      Result.Add('Bloco2', acbr.CMC7Bloco2);
      Result.Add('Bloco3', acbr.CMC7Bloco3);
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

function TACBRBridgeDiversos.ModelInStore: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Codificacao', '2CCCC0TTTTTT0');
  Result.Add('CodigoEtiqueta', '2000100015009');
end;

function TACBRBridgeDiversos.DesmembrarInStore(const jInStore: TJSONObject): TJSONObject;
var
  acbr: TACBrInStore;
  etiqueta: string;
begin
  Result := TJSONObject.Create;
  acbr := TACBrInStore.Create(nil);
  try
    try
      TJSONTools.JsonToObj(jInStore, acbr);
      if acbr.Codificacao = '' then
        acbr.Codificacao := '2CCCC0TTTTTT0';
      etiqueta := jInStore.Get('CodigoEtiqueta', '');
      acbr.Desmembrar(etiqueta);

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('Prefixo', acbr.Prefixo);
      Result.Add('Codigo', acbr.Codigo);
      Result.Add('Peso', acbr.Peso);
      Result.Add('Total', acbr.Total);
      Result.Add('DV', acbr.DV);
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
begin
  Result := TJSONObject.Create;
  Result.Add('arquivo_base64', 'CONTEUDO_CSV_IBPT_EM_BASE64');
  Result.Add('NCM', '84713012');
end;

function TACBRBridgeDiversos.LerTabelaIBPT(const jIBPT: TJSONObject): TJSONObject;
var
  acbr: TACBrIBPTax;
  b64Csv, fileName, ncm, ex, descricao: string;
  tabela, I, maxItems: Integer;
  aliqFedNac, aliqFedImp, aliqEst, aliqMun: Double;
  Stream: TStringStream;
  arrItens: TJSONArray;
  itemObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  acbr := TACBrIBPTax.Create(nil);
  try
    try
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
      else if fileName <> '' then
        acbr.AbrirTabela(fileName)
      else
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Informe "arquivo_base64" ou "ArquivoNome" para abrir a tabela IBPT.');
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
        begin
          itemObj := TJSONObject.Create;
          itemObj.Add('NCM', acbr.Itens[I].NCM);
          itemObj.Add('Excecao', acbr.Itens[I].Excecao);
          itemObj.Add('Tabela', Integer(acbr.Itens[I].Tabela));
          itemObj.Add('Descricao', acbr.Itens[I].Descricao);
          itemObj.Add('FederalNacional', acbr.Itens[I].FederalNacional);
          itemObj.Add('FederalImportado', acbr.Itens[I].FederalImportado);
          itemObj.Add('Estadual', acbr.Itens[I].Estadual);
          itemObj.Add('Municipal', acbr.Itens[I].Municipal);
          arrItens.Add(itemObj);
        end;
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
begin
  Result := TJSONObject.Create;
  Result.Add('Operacao', 'calcular_ead | verificar_ead | gerar_chaves | calcular_hash | md5');
  Result.Add('Conteudo', 'Conteudo texto para assinar ou verificar');
  Result.Add('ChavePrivada', '-----BEGIN RSA PRIVATE KEY----- ...');
  Result.Add('ChavePublica', '-----BEGIN PUBLIC KEY----- ...');
  Result.Add('EAD', '');
  Result.Add('Digest', 'dgstMD5');
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
    calc.Documento := '123456789';
    calc.FormulaDigito := frModulo11;
    calc.CalculoPadrao;
    Result := TJSONTools.SafeObjToJson(calc, 'Erro ao gerar modelo CalcDigito');
    if Assigned(Result) then
      Result.Add('CalculoPadrao', True);
  finally
    calc.Free;
  end;
end;

function TACBRBridgeDiversos.CalcularDigito(const jDigito: TJSONObject): TJSONObject;
var
  calc: TACBrCalcDigito;
begin
  Result := TJSONObject.Create;
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

      Result.Add(RSStatusField, RSStatusSucesso);
      Result.Add('Documento', calc.Documento);
      Result.Add('DigitoFinal', calc.DigitoFinal);
      Result.Add('SomaDigitos', calc.SomaDigitos);
      Result.Add('ModuloFinal', calc.ModuloFinal);
    except
      on E: Exception do
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, E.Message);
      end;
    end;
  finally
    calc.Free;
  end;
end;

function TACBRBridgeDiversos.ModelMail: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Host', 'smtp.seudominio.com.br');
  Result.Add('Port', '587');
  Result.Add('Username', 'fiscal@seudominio.com.br');
  Result.Add('Password', 'senha');
  Result.Add('SetSSL', False);
  Result.Add('SetTLS', True);
  Result.Add('IsHTML', True);
  Result.Add('From', 'fiscal@seudominio.com.br');
  Result.Add('FromName', 'Departamento Fiscal');
  Result.Add('Para', 'cliente@empresa.com.br');
  Result.Add('Subject', 'Documento Fiscal Eletronico');
  Result.Add('Body', '<p>Segue em anexo o documento fiscal.</p>');
  Result.Add('ApenasGerarMime', False);
end;

function TACBRBridgeDiversos.EnviarEmail(const jMail: TJSONObject): TJSONObject;
var
  mail: TACBrMail;
  paraStr, bodyStr, altBodyStr, nomeArq, b64Anexo, descAnexo: string;
  arrDest, arrAnexos: TJSONData;
  arr: TJSONArray;
  objAnexo: TJSONObject;
  I: Integer;
  anexoStream, mimeStream: TMemoryStream;
  rawBytes: AnsiString;
begin
  Result := TJSONObject.Create;
  mail := TACBrMail.Create(nil);
  mimeStream := TMemoryStream.Create;
  try
    try
      mail.Clear;
      mail.UseThread := False;
      mail.Port := '587';
      mail.SetTLS := True;
      mail.IsHTML := True;
      TJSONTools.JsonToObj(jMail, mail);
      if mail.From = '' then
        mail.From := mail.Username;

      paraStr := jMail.Get('Para', '');
      if paraStr <> '' then
        mail.AddAddress(paraStr);

      arrDest := jMail.Find('Destinatarios');
      if Assigned(arrDest) and (arrDest.JSONType = jtArray) then
      begin
        arr := TJSONArray(arrDest);
        for I := 0 to arr.Count - 1 do
          mail.AddAddress(arr.Strings[I]);
      end;

      bodyStr := jMail.Get('Body', '');
      if bodyStr <> '' then
        mail.Body.Text := bodyStr;

      altBodyStr := jMail.Get('AltBody', '');
      if altBodyStr <> '' then
        mail.AltBody.Text := altBodyStr;

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
