unit method.acbr.diversos.legado;

{$mode Delphi}
{$M+}

interface

uses
  RTTI,
  ACBrCMC7,
  ACBrInStore,
  ACBrCargaBal,
  ACBrIBPTax,
  Variants,
  fpjson,
  jsonconvert,
  Base64,
  jsonparser,
  Classes, SysUtils,
  streamtools,
  ACBrEAD,
  ACBrValidador,
  ACBrMail;

type
  TACBRBridgeDiversosLegado = class
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

{ TACBRBridgeDiversosLegado }

function TACBRBridgeDiversosLegado.ModelCMC7: TJSONObject;
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

function TACBRBridgeDiversosLegado.ProcessarCMC7(const jCMC7: TJSONObject): TJSONObject;
var
  acbr: TACBrCMC7;
  banda, banco, agencia, comp, numero, conta, tipif: string;
begin
  Result := TJSONObject.Create;
  acbr := TACBrCMC7.Create(nil);
  try
    try
      banda := jCMC7.Get('CMC7', '');
      if banda = '' then
        banda := jCMC7.Get('cmc7', '');

      if banda <> '' then
      begin
        acbr.CMC7 := FormataCMC7(banda);
      end
      else
      begin
        banco := jCMC7.Get('Banco', '');
        agencia := jCMC7.Get('Agencia', '');
        comp := jCMC7.Get('Comp', '');
        numero := jCMC7.Get('Numero', '');
        conta := jCMC7.Get('Conta', '');
        tipif := jCMC7.Get('Tipificacao', '5');
        if tipif = '' then tipif := '5';
        acbr.MontaCMC7(banco, agencia, conta, numero, comp, tipif[1]);
      end;

      Result.Add('status', 'sucesso');
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
        Result.Add('status', 'erro');
        Result.Add('error', E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversosLegado.ModelInStore: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Codificacao', '2CCCC0TTTTTT0');
  Result.Add('CodigoEtiqueta', '2000100015009');
end;

function TACBRBridgeDiversosLegado.DesmembrarInStore(const jInStore: TJSONObject): TJSONObject;
var
  acbr: TACBrInStore;
  codificacao, etiqueta: string;
begin
  Result := TJSONObject.Create;
  acbr := TACBrInStore.Create(nil);
  try
    try
      codificacao := jInStore.Get('Codificacao', '');
      if codificacao = '' then
        codificacao := jInStore.Get('codificacao', '2CCCC0TTTTTT0');
      etiqueta := jInStore.Get('CodigoEtiqueta', '');
      if etiqueta = '' then
        etiqueta := jInStore.Get('codigo', '');

      acbr.Codificacao := codificacao;
      acbr.Desmembrar(etiqueta);

      Result.Add('status', 'sucesso');
      Result.Add('Prefixo', acbr.Prefixo);
      Result.Add('Codigo', acbr.Codigo);
      Result.Add('Peso', acbr.Peso);
      Result.Add('Total', acbr.Total);
      Result.Add('DV', acbr.DV);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('error', E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversosLegado.ModelCargaBal: TJSONObject;
var
  acbr: TACBrCargaBal;
  item: TACBrCargaBalItem;
  arr: TJSONArray;
begin
  acbr := TACBrCargaBal.Create(nil);
  try
    Result := TJSONObject.Create;
    Result.Add('Modelo', Integer(acbr.Modelo));
    item := acbr.Produtos.New;
    arr := TJSONArray.Create;
    arr.Add(TJSONTools.SafeObjToJson(item, 'Erro no item CargaBal'));
    Result.Add('Produtos', arr);
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversosLegado.GerarCargaBalanca(const jCarga: TJSONObject): TJSONObject;
var
  acbr: TACBrCargaBal;
  arrProd: TJSONData;
  arr: TJSONArray;
  I, tamanho: Integer;
  item: TACBrCargaBalItem;
  outDir: string;
  SR: TSearchRec;
  arrArquivos: TJSONArray;
  fileObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  acbr := TACBrCargaBal.Create(nil);
  try
    try
      acbr.Modelo := TACBrCargaBalModelo(jCarga.Get('Modelo', 0));
      arrProd := jCarga.Find('Produtos');
      if not Assigned(arrProd) then
        arrProd := jCarga.Find('produtos');

      if Assigned(arrProd) and (arrProd.JSONType = jtArray) then
      begin
        arr := TJSONArray(arrProd);
        for I := 0 to arr.Count - 1 do
        begin
          if arr.Items[I].JSONType = jtObject then
          begin
            item := acbr.Produtos.New;
            TJSONTools.JsonToObj(TJSONObject(arr.Items[I]), item);
          end;
        end;
      end;

      outDir := ExtractFilePath(ParamStr(0)) + 'balanca_' + IntToStr(GetTickCount64) + PathDelim;
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
      RemoveDir(outDir);

      Result.Add('status', 'sucesso');
      Result.Add('modelo_str', acbr.ModeloStr);
      Result.Add('arquivos', arrArquivos);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('error', E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversosLegado.ModelIBPT: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('arquivo_base64', 'CONTEUDO_CSV_IBPT_EM_BASE64');
  Result.Add('NCM', '84713012');
end;

function TACBRBridgeDiversosLegado.LerTabelaIBPT(const jIBPT: TJSONObject): TJSONObject;
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
      if ncm = '' then ncm := jIBPT.Get('ncm', '');

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
      begin
        acbr.AbrirTabela(fileName);
      end
      else
      begin
        Result.Add('status', 'erro');
        Result.Add('error', 'Informe "arquivo_base64" ou "ArquivoNome" para abrir a tabela IBPT.');
        Exit;
      end;

      Result.Add('status', 'sucesso');
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
        Result.Add('status', 'erro');
        Result.Add('error', E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;



procedure TACBRBridgeDiversosLegado.DoGetChavePrivada(var Chave: AnsiString);
begin
  Chave := fChavePrivada;
end;

procedure TACBRBridgeDiversosLegado.DoGetChavePublica(var Chave: AnsiString);
begin
  Chave := fChavePublica;
end;

function TACBRBridgeDiversosLegado.ModelEAD: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Operacao', 'calcular_ead | verificar_ead | gerar_chaves | calcular_hash | md5');
  Result.Add('Conteudo', 'Conteudo texto para assinar ou verificar');
  Result.Add('ChavePrivada', '-----BEGIN RSA PRIVATE KEY----- ...');
  Result.Add('ChavePublica', '-----BEGIN PUBLIC KEY----- ...');
  Result.Add('EAD', '');
  Result.Add('Digest', 'dgstMD5');
end;

function TACBRBridgeDiversosLegado.ProcessarEAD(const jEAD: TJSONObject): TJSONObject;
var
  acbr: TACBrEAD;
  operacao, conteudo, eadStr, dgstStr: string;
  pubKey, privKey: AnsiString;
  dgst: TACBrEADDgst;
  ms: TMemoryStream;
  verificado: Boolean;
begin
  Result := TJSONObject.Create;
  acbr := TACBrEAD.Create(nil);
  try
    try
      operacao := LowerCase(Trim(jEAD.Get('Operacao', jEAD.Get('operacao', 'calcular_ead'))));
      fChavePrivada := AnsiString(jEAD.Get('ChavePrivada', jEAD.Get('chave_privada', '')));
      fChavePublica := AnsiString(jEAD.Get('ChavePublica', jEAD.Get('chave_publica', '')));
      conteudo := jEAD.Get('Conteudo', jEAD.Get('Valor', jEAD.Get('conteudo', '')));
      if (conteudo = '') and (jEAD.Get('arquivo_base64', '') <> '') then
        conteudo := DecodeStringBase64(jEAD.Get('arquivo_base64', ''));

      eadStr := jEAD.Get('EAD', jEAD.Get('ead', ''));
      dgstStr := LowerCase(Trim(jEAD.Get('Digest', jEAD.Get('digest', 'dgstmd5'))));

      if dgstStr = 'dgstsha1' then dgst := dgstSHA1
      else if dgstStr = 'dgstsha256' then dgst := dgstSHA256
      else if dgstStr = 'dgstsha512' then dgst := dgstSHA512
      else dgst := dgstMD5;

      if fChavePrivada <> '' then
        acbr.OnGetChavePrivada := DoGetChavePrivada;
      if fChavePublica <> '' then
        acbr.OnGetChavePublica := DoGetChavePublica;

      if operacao = 'gerar_chaves' then
      begin
        pubKey := '';
        privKey := '';
        acbr.GerarChaves(pubKey, privKey);
        Result.Add('status', 'sucesso');
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

        Result.Add('status', 'sucesso');
        Result.Add('Valido', verificado);
      end
      else if operacao = 'calcular_hash' then
      begin
        Result.Add('status', 'sucesso');
        Result.Add('Hash', string(acbr.CalcularHash(AnsiString(conteudo), dgst)));
      end
      else if operacao = 'md5' then
      begin
        Result.Add('status', 'sucesso');
        Result.Add('MD5', acbr.MD5FromString(conteudo));
      end
      else
      begin
        eadStr := string(acbr.CalcularEAD(AnsiString(conteudo)));
        Result.Add('status', 'sucesso');
        Result.Add('EAD', eadStr);
        Result.Add('LinhaEAD', 'EAD' + eadStr);
      end;
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('error', E.Message);
      end;
    end;
  finally
    acbr.Free;
  end;
end;

function TACBRBridgeDiversosLegado.ModelCalcDigito: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('Documento', '123456789');
  Result.Add('FormulaDigito', 'frModulo11');
  Result.Add('MultiplicadorInicial', 2);
  Result.Add('MultiplicadorFinal', 9);
  Result.Add('CalculoPadrao', True);
end;

function TACBRBridgeDiversosLegado.CalcularDigito(const jDigito: TJSONObject): TJSONObject;
var
  calc: TACBrCalcDigito;
  formulaStr: string;
begin
  Result := TJSONObject.Create;
  calc := TACBrCalcDigito.Create;
  try
    try
      calc.Documento := jDigito.Get('Documento', jDigito.Get('documento', ''));
      formulaStr := LowerCase(Trim(jDigito.Get('FormulaDigito', jDigito.Get('formula', 'frmodulo11'))));
      if (formulaStr = 'frmodulo10') or (formulaStr = 'modulo10') or (formulaStr = '2') then
        calc.FormulaDigito := frModulo10
      else if (formulaStr = 'frmodulo10pis') or (formulaStr = 'modulo10pis') or (formulaStr = '1') then
        calc.FormulaDigito := frModulo10PIS
      else
        calc.FormulaDigito := frModulo11;

      if jDigito.Get('CalculoPadrao', False) then
        calc.CalculoPadrao
      else
      begin
        calc.MultiplicadorInicial := jDigito.Get('MultiplicadorInicial', 2);
        calc.MultiplicadorFinal := jDigito.Get('MultiplicadorFinal', 9);
      end;

      calc.Calcular;

      Result.Add('status', 'sucesso');
      Result.Add('Documento', calc.Documento);
      Result.Add('DigitoFinal', calc.DigitoFinal);
      Result.Add('SomaDigitos', calc.SomaDigitos);
      Result.Add('ModuloFinal', calc.ModuloFinal);
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('error', E.Message);
      end;
    end;
  finally
    calc.Free;
  end;
end;

function TACBRBridgeDiversosLegado.ModelMail: TJSONObject;
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

function TACBRBridgeDiversosLegado.EnviarEmail(const jMail: TJSONObject): TJSONObject;
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
      mail.Host := jMail.Get('Host', jMail.Get('host', ''));
      mail.Port := jMail.Get('Port', jMail.Get('port', '587'));
      mail.Username := jMail.Get('Username', jMail.Get('username', ''));
      mail.Password := jMail.Get('Password', jMail.Get('password', ''));
      mail.SetSSL := jMail.Get('SetSSL', jMail.Get('setSSL', False));
      mail.SetTLS := jMail.Get('SetTLS', jMail.Get('setTLS', True));
      mail.IsHTML := jMail.Get('IsHTML', jMail.Get('isHTML', True));
      mail.From := jMail.Get('From', jMail.Get('from', mail.Username));
      mail.FromName := jMail.Get('FromName', jMail.Get('fromName', ''));
      mail.Subject := jMail.Get('Subject', jMail.Get('subject', ''));

      paraStr := jMail.Get('Para', jMail.Get('para', ''));
      if paraStr <> '' then
        mail.AddAddress(paraStr);

      arrDest := jMail.Find('Destinatarios');
      if not Assigned(arrDest) then
        arrDest := jMail.Find('destinatarios');
      if Assigned(arrDest) and (arrDest.JSONType = jtArray) then
      begin
        arr := TJSONArray(arrDest);
        for I := 0 to arr.Count - 1 do
          mail.AddAddress(arr.Strings[I]);
      end;

      bodyStr := jMail.Get('Body', jMail.Get('body', ''));
      if bodyStr <> '' then
        mail.Body.Text := bodyStr;

      altBodyStr := jMail.Get('AltBody', jMail.Get('altBody', ''));
      if altBodyStr <> '' then
        mail.AltBody.Text := altBodyStr;

      arrAnexos := jMail.Find('Anexos');
      if not Assigned(arrAnexos) then
        arrAnexos := jMail.Find('anexos');
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
        Result.Add('status', 'sucesso');
        Result.Add('mime_base64', StreamToBase64String(mimeStream));
      end
      else
      begin
        mail.Send(False);
        Result.Add('status', 'sucesso');
        Result.Add('message', 'E-mail enviado com sucesso.');
      end;
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro');
        Result.Add('error', E.Message);
      end;
    end;
  finally
    mimeStream.Free;
    mail.Free;
  end;
end;

end.
