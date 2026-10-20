{%RunFlags MESSAGES+}

Unit method.acbr.nfe;

{$mode Delphi}
{$M+}

Interface

Uses streamtools,
RTTI,
ACBrNFe,
ACBrNFe.EnvEvento,
ACBrNFe.EventoClass,
ACBrNFeNotasFiscais,
ACBrNFeDANFeFPDF,
ACBrNFeWebServices,
ACBrDFeDANFeReport,
ACBrMail,
ACBrDFeSSL,
ACBrDFeConfiguracoes,
ACBrNFeConfiguracoes,
ACBrNFe.Classes,
pcnConversaoNFe,
pcnConversao,
pcnProcNFe,
StrUtils,
Variants,
fpjson, jsonconvert,
Base64, synacode,
jsonparser,
Classes, SysUtils,
resource.strings.global,
resource.strings.msg,
  ACBrNFCeDANFeFPDF,
  ACBrNFeDANFeESCPOS,
  ACBrPosPrinter;

Type 


  { TACBRBridgeNFe }

  TACBRBridgeNFe = Class
    Private 
      fcfg: string;
      facbr: TACBrNFe;
      fdanfe: TACBrNFeDANFeFPDF;
      Procedure CarregaConfig;

      Function ReadXMLFromJSON(Const jsonData: TJSONObject): string;
    Public 
      constructor Create(Const Cfg: String);
      destructor Destroy;
      override;

      // Envia um evento
      Function Evento(Const jEventos: TJSONArray): string;
      // DistribuiÃƒÂ§ÃƒÂ£o
      Function Distribuicao(Const jDistribuicao: TJSONObject): TJSONObject;
      // DANFE
      Function Danfe(Const xmlData: TJSONObject): TJSONObject;
      // Envia uma NFE
      Function NFe(Const jNFe: TJSONObject): TJSONObject;
      // Status do ServiÃƒÂ§o
      Function StatusServico(Const jStatus: TJSONObject): TJSONObject;
      // Consulta por chave
      Function Consulta(Const jConsulta: TJSONObject): TJSONObject;
      // Consulta por Recibo (Lote Assíncrono)
      Function ConsultaRecibo(Const jConsulta: TJSONObject): TJSONObject;
      // InutilizaÃƒÂ§ÃƒÂ£o de numeraÃƒÂ§ÃƒÂ£o
      Function Inutilizacao(Const jInutilizacao: TJSONObject): TJSONObject;
      // Cancelamento (atalho)
      Function Cancelamento(Const jCancelamento: TJSONObject): TJSONObject;
      // XML para JSON
      Function NFeFromXML(Const jXML: TJSONObject): TJSONObject;
      // JSON para XML
      Function NFeToXML(Const jNFe: TJSONObject): TJSONObject;
      // Validar regras (offline)
      Function ValidarRegras(Const jNFe: TJSONObject): TJSONObject;
      // PDF de Evento
      Function DanfeEvento(Const xmlEvento: TJSONObject): TJSONObject;
      // Impressão Térmica EscPos do DANFE / DANFCe
      Function DanfeEscPos(Const xmlData: TJSONObject): TJSONObject;
      // Consulta Cadastro de Contribuinte na SEFAZ (UF + CNPJ/CPF/IE)
      Function ConsultaCadastro(Const jConsulta: TJSONObject): TJSONObject;
      // Envio de NF-e/NFC-e por E-mail via TACBrMail
      Function EnviarEmail(Const jEmail: TJSONObject): TJSONObject;

      // Teste a configuraÃƒÂ§ÃƒÂ£o passada em JSON
      Function TesteConfig: boolean;
      // Debug: retorna a config carregada como JSON
      Function DebugConfig: TJSONObject;
      // Envio em lote (array de NFes)
      Function NFeLote(Const jLote: TJSONArray): TJSONObject;
  End;


{ TACBRModelosJSON - Salva os retornos de modelo de requisiÃƒÂ§ÃƒÂµes, para facilitar
  documentaÃƒÂ§ÃƒÂ£o ou consulta por parte do programador.}

  TACBRModelosJSON = Class(TACBRBridgeNFe)
    Private 
    Public 
      // Retorna as configuraÃƒÂ§ÃƒÂµes atuais do componente da ACBR.
      Function ModelConfig: TJSONObject;
      Function ModelEvento: TJSONObject;
      Function ModelDistribuicao: string;
      Function ModelNFe: TJSONObject;
      Function ModelStatusServico: TJSONObject;
      Function ModelConsulta: TJSONObject;
      Function ModelInutilizacao: TJSONObject;
      Function ModelCancelamento: TJSONObject;
      Function ModelNFeFromXML: TJSONObject;
      Function ModelNFeToXML: TJSONObject;
  End;

Implementation



{ TACBRModelosJSON }

Function TACBRModelosJSON.ModelConfig: TJSONObject;
Begin

  With facbr.Configuracoes.Geral Do
    Begin
      FormaEmissao := TpcnTipoEmissao.teNormal;
      ModeloDF := TpcnModeloDF.moNFe;
      VersaoDF := TpcnVersaoDF.ve400;
      RetirarAcentos := True;
      IdCSC := '';
      //cIdToken := '';

      SSLLib := TSSLLib.libOpenSSL;
      SSLCryptLib := TSSLCryptLib.cryOpenSSL;
      SSLHttpLib := TSSLHttpLib.httpOpenSSL;
      SSLXmlSignLib := TSSLXmlSignLib.xsLibXml2;
    End;

  With facbr.Configuracoes.WebServices Do
    Begin
      Ambiente := TpcnTipoAmbiente.taHomologacao;
      UF := RSDefaultUF;
      TimeOut := 5000;
    End;

  With facbr.Configuracoes.Certificados Do
    Begin
      ArquivoPFX := RSDefaultCertPath;
      Senha := RSDefaultCertPassword;
    End;


  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
End;

Function TACBRModelosJSON.ModelEvento: TJSONObject;
Begin
  facbr.EventoNFe.Evento.New;
  Result := TJSONTools.ObjToJson(facbr.EventoNFe);
  facbr.EventoNFe.Evento.Clear;
End;


Function TACBRModelosJSON.ModelNFe: TJSONObject;

Var 
  NF: NotaFiscal;
  Det: TDetCollectionItem;
Begin
  NF := facbr.NotasFiscais.Add;
  NF.NFe.Cobr.Dup.New;
  Det := NF.NFe.Det.New;
  Det.Prod.DI.New.adi.New;
  Det.Prod.NVE.New;
  Det.Prod.arma.New;
  Det.Prod.detExport.New;
  Det.Prod.med.New;
  Det.Prod.rastro.New;

  NF.NFe.Ide.NFref.New;
  NF.NFe.InfAdic.obsCont.New;
  NF.NFe.InfAdic.obsFisco.New;
  NF.NFe.InfAdic.procRef.New;
  NF.NFe.Transp.Reboque.New;
  NF.NFe.Transp.Vol.New.Lacres.New;
  NF.NFe.cana.fordia.New;
  NF.Nfe.cana.deduc.New;
  NF.NFe.pag.New.tBand := TpcnBandeiraCartao.bcAlelo;

  Result := TJSONTools.ObjToJson(NF);
  Result.Delete(RSXMLField);
  Result.Delete(RSXMLOriginalField);
  Result.Delete(RSNomeArqField);
  Result.Delete(RSErroValidacaoCompletoField);
  Result.Delete(RSErroValidacaoField);
  Result.Delete(RSErroRegrasdeNegociosField);
  Result.Delete(RSAlertasField);

  facbr.NotasFiscais.Clear;
End;

Function TACBRModelosJSON.ModelDistribuicao: string;
Begin
  //  Evento := facbr.WebServices.DistribuicaoDFe.new;
  Result := TJSONTools.SafeObjToJsonString(facbr.WebServices.DistribuicaoDFe);
  //  facbr.EventoNFe.Evento.Clear;
End;

Function TACBRModelosJSON.ModelStatusServico: TJSONObject;
Begin
  Result := TJSONObject.Create;
End;

Function TACBRModelosJSON.ModelConsulta: TJSONObject;
Begin
  Result := TJSONObject.Create;
  Result.Add('NFe_Chave', 'Preencha com a Chave de Acesso da NF-e');
End;

Function TACBRModelosJSON.ModelInutilizacao: TJSONObject;
Begin
  facbr.WebServices.Inutilizacao.CNPJ := '00000000000000';
  facbr.WebServices.Inutilizacao.Justificativa := 'Justificativa da Inutilizacao';
  facbr.WebServices.Inutilizacao.Ano := 2023;
  facbr.WebServices.Inutilizacao.Serie := 1;
  facbr.WebServices.Inutilizacao.NumeroInicial := 100;
  facbr.WebServices.Inutilizacao.NumeroFinal := 100;
  facbr.WebServices.Inutilizacao.Modelo := 55;
  Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.Inutilizacao));
End;

Function TACBRModelosJSON.ModelCancelamento: TJSONObject;
Begin
  facbr.EventoNFe.Evento.Clear;
  with facbr.EventoNFe.Evento.New.InfEvento do
  begin
    tpEvento := teCancelamento;
    chNFe := 'Preencha com a Chave de Acesso';
    detEvento.nProt := 'Preencha com o Protocolo';
    detEvento.xJust := 'Justificativa do Cancelamento (min 15 caracteres)';
  end;
  Result := TJSONObject(TJSONTools.ObjToJson(facbr.EventoNFe.Evento.Items[0]));
  facbr.EventoNFe.Evento.Clear;
End;

Function TACBRModelosJSON.ModelNFeFromXML: TJSONObject;
Begin
  Result := TJSONObject.Create;
  Result.Add('xml', 'XML da NF-e em Base64 Ã¢â‚¬â€ retorna a NF-e como JSON');
End;

Function TACBRModelosJSON.ModelNFeToXML: TJSONObject;
Begin
  Result := ModelNFe;
  // O modelo ÃƒÂ© o mesmo da NF-e Ã¢â‚¬â€  envie o JSON da NF-e e receba o XML gerado
End;

{ TACBRBridgeNFe }

Function TACBRBridgeNFe.NFe(Const jNFe: TJSONObject): TJSONObject;
Var 
  Nota: NotaFiscal;
  Lote: integer;
  // Unit pcnProcNFe
  RetWS: TProcNFe;
Begin
  CarregaConfig;

  //Gera objeto TNotaFiscal da unit ACBrNFeNotasFiscais
  Nota := facbr.NotasFiscais.Add;
  
  // Inicia o número do lote do envio da NFe
  Lote := 1;
  
  // Alimenta o objeto Nota com os valores passandos por JSON
  Try
    if Assigned(jNFe.Find('NFe')) then
      TJSONTools.JsonToObj(jNFe, Nota)
    else
      TJSONTools.JsonToObj(jNFe, Nota.NFe);
    Nota.NFe.infNFe.Versao := pcnConversaoNFe.VersaoDFToDbl(facbr.Configuracoes.Geral.VersaoDF);
  Except
    on E: Exception Do
          Begin
            Result := TJSONTools.SafeObjToJson(nil, RSErrorReadingJSON + E.Message);
            Exit;
          End;
  End;

  Try
    facbr.NotasFiscais.GerarNFe;
    facbr.NotasFiscais.Assinar;
    facbr.NotasFiscais.Validar;
    
    // Pede a ACBR para transmitir os dados (síncrono obrigatório)
    facbr.WebServices.Envia(Lote, True, False);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Enviar, 'Erro ao enviar NFe');
    if facbr.NotasFiscais.Count > 0 then
    begin
      Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XML));
      Result.Add('chave', StringReplace(facbr.NotasFiscais.Items[0].NFe.infNFe.ID, 'NFe', '', [rfIgnoreCase]));
    end;
  Finally
  facbr.NotasFiscais.Clear;
End;
End;

Function TACBRBridgeNFe.NFeLote(Const jLote: TJSONArray): TJSONObject;
Var
  Nota: NotaFiscal;
  i, Lote: integer;
  jNFe: TJSONObject;
Begin
  CarregaConfig;
  Lote := 1;

  // Limpa as notas
  facbr.NotasFiscais.Clear;

  // Adiciona cada NFe do array ao componente
  For i := 0 to jLote.Count - 1 Do
  Begin
    jNFe := jLote.Objects[i];
    Nota := facbr.NotasFiscais.Add;
    Try
      if Assigned(jNFe.Find('NFe')) then
        TJSONTools.JsonToObj(jNFe, Nota)
      else
        TJSONTools.JsonToObj(jNFe, Nota.NFe);
      Nota.NFe.infNFe.Versao := pcnConversaoNFe.VersaoDFToDbl(facbr.Configuracoes.Geral.VersaoDF);
    Except
      on E: Exception Do
      Begin
        Result := TJSONTools.SafeObjToJson(nil, RSErrorReadingJSON + ' (item ' + IntToStr(i) + '): ' + E.Message);
        facbr.NotasFiscais.Clear;
        Exit;
      End;
    End;
  End;

  Try
    facbr.NotasFiscais.GerarNFe;
    facbr.NotasFiscais.Assinar;
    facbr.NotasFiscais.Validar;

    // Envia lote assíncrono (segundo parâmetro = False)
    facbr.WebServices.Envia(Lote, False, False);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao enviar lote');
    if facbr.NotasFiscais.Count > 0 then
      Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XML));
  Finally
    facbr.NotasFiscais.Clear;
  End;
End;


Procedure TACBRBridgeNFe.CarregaConfig;

Var 
  O, CertConfig: TJSONObject;
  tempData: TJSONData;
  b64String: String;
Begin
  if (fcfg = '') or (fcfg = '') then
    raise Exception.Create('Configuracao vazia ou nao informada.');

  O := GetJSON(fcfg) as TJSONObject;
  Try
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
    
    tempData := O.Find('Certificados');
    if Assigned(tempData) and (tempData.JSONType = jtObject) then
    begin
      CertConfig := TJSONObject(tempData);
      b64String := CertConfig.Get('DadosPFXBase64', '');
      if b64String <> '' then
      begin
        facbr.Configuracoes.Certificados.DadosPFX := synacode.DecodeBase64(AnsiString(b64String));
      end;
    end;

    with facbr.Configuracoes.Geral do
    begin
      SSLLib := libNone;
      SSLLib := libOpenSSL;
      SSLCryptLib := cryOpenSSL;
      SSLHttpLib := httpOpenSSL;
      SSLXmlSignLib := xsLibXml2;
    end;

  Finally
    O.Free;
  End;

  // Garante PathSchemas padrão para NFe se não foi informado
  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + 'Schemas' + PathDelim + 'NFe';

  fcfg := '';
End;

Function TACBRBridgeNFe.ReadXMLFromJSON(Const jsonData: TJSONObject): string;
Var 
  xmlRawOrB64: string;
  xmlData: TJSONData;
Begin
  xmlData := jsonData.Find('xml');
  if not Assigned(xmlData) then
    xmlData := jsonData.Find('XML');
  if not Assigned(xmlData) then
    xmlData := jsonData.Find('XMLEvento');
  if not Assigned(xmlData) then
    xmlData := jsonData.Find('xml_evento');
  if not Assigned(xmlData) then
    xmlData := jsonData.Find('xml_nfe');
  if not Assigned(xmlData) then
    xmlData := jsonData.Find('NFeXML');

  If not Assigned(xmlData) Then
    raise Exception.Create(RSErrorReadingXMLParam + 'Parâmetro "xml" não encontrado.');

  xmlRawOrB64 := Trim(xmlData.AsString);
  If xmlRawOrB64 = '' Then
    raise Exception.Create(RSErrorReadingXMLParam + 'Parâmetro "xml" está vazio.');

  if (Length(xmlRawOrB64) > 0) and (xmlRawOrB64[1] = '<') then
  begin
    Result := xmlRawOrB64;
    Exit;
  end;

  Try
    Result := DecodeStringBase64(xmlRawOrB64);
  Except
    on E: Exception Do
          Begin
            raise Exception.Create(RSInvalidBase64XML + E.Message);
          End;
  End;
End;

constructor TACBRBridgeNFe.Create(Const Cfg: String);
Begin
  facbr := TACBrNFe.Create(Nil);
  fdanfe := TACBrNFeDANFeFPDF.Create(Nil);
  fcfg := Cfg;
  facbr.DANFE := fdanfe;
End;

destructor TACBRBridgeNFe.Destroy;
Begin
  facbr.Free;
  FreeAndNil(fdanfe);
  inherited Destroy;
End;

Function TACBRBridgeNFe.Evento(Const jEventos: TJSONArray): string;

Var 
  objEvento: TInfEventoCollectionItem;
  oEvento: TJSONObject;
  I: integer;
  InfEventoData, XmlData: TJSONData;
  InfEvento: TJSONObject;
  xmlStr: string;
Begin
  CarregaConfig;
  Result := '';
  facbr.EventoNFe.Evento.Clear;

  For I := 0 To jEventos.Count - 1 Do
    Begin
      oEvento := jEventos.Items[i] as TJSONObject;
      InfEventoData := oEvento.Find(RSInfEventoField);
      if not Assigned(InfEventoData) then
        InfEventoData := oEvento.Find('infEvento');

      if Assigned(InfEventoData) and (InfEventoData.JSONType = jtObject) then
      begin
        InfEvento := TJSONObject(InfEventoData);
        XmlData := InfEvento.Find(RSLoadXMLField);
      end
      else
        XmlData := oEvento.Find(RSLoadXMLField);

      if Assigned(XmlData) and (Trim(XmlData.AsString) <> '') then
      begin
        xmlStr := Trim(XmlData.AsString);
        if xmlStr[1] <> '<' then
          xmlStr := Base64.DecodeStringBase64(xmlStr);
        facbr.NotasFiscais.LoadFromString(xmlStr);
      end;

      objEvento := facbr.EventoNFe.Evento.New;
      if Assigned(InfEventoData) and (InfEventoData.JSONType = jtObject) then
        TJSONTools.JsonToObj(oEvento, objEvento)
      else
        TJSONTools.JsonToObj(oEvento, objEvento.InfEvento);

      with objEvento.InfEvento do
      begin
        if dhEvento = 0 then dhEvento := Now;
        if (CNPJ = '') and (Length(chNFe) >= 20) then CNPJ := Copy(chNFe, 7, 14);
        if nSeqEvento <= 0 then nSeqEvento := 1;
      end;
    End;

  facbr.EnviarEvento(1);
  Result := TJSONTools.ObjToJsonString(
            facbr.WebServices.EnvEvento.EventoRetorno.retEvento);
End;

Function TACBRBridgeNFe.Distribuicao(Const jDistribuicao: TJSONObject):
                                                                     TJSONObject
;

Var 
  objDistribuicao: TDistribuicaoDFe;
  UF: TJSONString;
  CNPJCPF, ultNSU, NSU, chNFe: TJSONString;

Const 
  CodigosIBGE: array [0..26] Of string = (
                                          '11', '12', '13', '14', '15', '16',
                                          '17', '21', '22', '23', '24',
                                          '25', '26', '27', '28', '29', '31',
                                          '32', '33', '35', '41', '42', '43',
                                          '50', '51', '52', '53');
Begin
  CarregaConfig;

  Result := TJSONObject.Create;

  objDistribuicao := facbr.WebServices.DistribuicaoDFe;

  If jDistribuicao.Find(RSUFField, UF) Then
    Begin
      If Not MatchStr(UF.ToString, CodigosIBGE) Then
        Begin
          Result.Add(RSErrorField, RSInvalidUFCode);
          Exit;
        End;
      objDistribuicao.cUFAutor := StrToInt(UF.ToString);
    End;

  If jDistribuicao.Find(RSCNPJCPFField, CNPJCPF) Then
    objDistribuicao.CNPJCPF := CNPJCPF.ToString;

  If jDistribuicao.Find(RSUltNSUField, ultNSU) Then
    objDistribuicao.ultNSU := ultNSU.ToString;

  If jDistribuicao.Find(RSNSUField, NSU) Then
    objDistribuicao.NSU := NSU.ToString;

  If jDistribuicao.Find(RSChNFeField, chNFe) Then
    objDistribuicao.chNFe := chNFe.ToString;

  Try
    objDistribuicao.Executar;
  Except
    on E: Exception Do
          Begin
            If objDistribuicao.RetDistDFeInt.cStat <> 0 Then
              Result := TJSONObject(TJSONTools.ObjToJson(
                        objDistribuicao.RetDistDFeInt))
            Else
              Result.Add(RSErrorField, E.message);
            Exit;
          End;
End;

Result := TJSONObject(TJSONTools.ObjToJson(objDistribuicao.RetDistDFeInt));
End;

Function TACBRBridgeNFe.Danfe(Const xmlData: TJSONObject): TJSONObject;

Var 
  arquivofinal: string;
  stringXml: string;
  tamanho: integer;
  id: TJSONString;
  fileName: string;
  pdfDir: string;
  chClean: string;
  danfeNFCe: TACBrNFCeDANFeFPDF;
  isNFCe: Boolean;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  Try
    stringXml := ReadXMLFromJSON(xmlData);
  Except
    on E: Exception Do
          Begin
            Result.Add(RSErrorField, E.Message);
            Exit;
          End;
End;

Try
  facbr.NotasFiscais.LoadFromString(stringXml);
Except
  on E: Exception Do
        Begin
          Result.Add(RSErrorField, RSXMLReadError + E.Message);
          Exit;
        End;
End;

// Esvazia a string para liberar da memória logo o xml
stringXml := '';

If facbr.NotasFiscais.Count = 0 Then
Begin
  Result.Add(RSErrorField, 'Nenhuma nota fiscal foi carregada a partir do XML.');
  Exit;
End;

pdfDir := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;
If Not DirectoryExists(pdfDir) Then
  CreateDir(pdfDir);

chClean := StringReplace(facbr.NotasFiscais.Items[0].NFe.infNFe.ID, 'NFe', '', [rfIgnoreCase]);
fileName := pdfDir + chClean + '-nfe.pdf';
If FileExists(fileName) Then
  SysUtils.DeleteFile(fileName);
isNFCe := (facbr.NotasFiscais.Items[0].NFe.Ide.modelo = 65) or
          (facbr.NotasFiscais.Items[0].NFe.Ide.tpImp = TpcnTipoImpressao.tiNFCe);

If isNFCe Then
Begin
  danfeNFCe := TACBrNFCeDANFeFPDF.Create(Nil);
  Try
    danfeNFCe.MostraPreview := False;
    danfeNFCe.MostraStatus := False;
    danfeNFCe.MostraSetup := False;
    danfeNFCe.PathPDF := pdfDir;
    facbr.DANFE := danfeNFCe;
    Try
      facbr.NotasFiscais.ImprimirPDF;
      filename := danfeNFCe.ArquivoPDF;
    Except
      Begin
        facbr.DANFE := fdanfe;
        Result.Add(RSErrorField, RSPDFGenerationError);
        Exit;
      End;
    End;
  Finally
    facbr.DANFE := fdanfe;
    danfeNFCe.Free;
  End;
End
Else
Begin
  If facbr.NotasFiscais.Items[0].NFe.Ide.tpImp <> TpcnTipoImpressao.tiPaisagem Then
    fdanfe.TipoDANFE := tiRetrato
  Else
    fdanfe.TipoDANFE := tiPaisagem;

  fdanfe.MostraPreview := False;
  fdanfe.MostraStatus := False;
  fdanfe.MostraSetup := False;

  Try
    fDAnFe.PathPDF := pdfDir;
    facbr.DANFE := fdanfe;
    facbr.NotasFiscais.ImprimirPDF;
    filename := fdanfe.ArquivoPDF;
  Except
    Begin
      Result.Add(RSErrorField, RSPDFGenerationError);
      Exit;
    End;
  End;
End;

If (filename = '') or (Not FileExists(filename)) Then
  filename := pdfDir + chClean + '-nfe.pdf';

// Converte o arquivo para base64 preservando em disco para GET /nfe/pdf/:chave
Try
  arquivofinal := FileToStringBase64(filename, False, tamanho);
Except
  on E: Exception Do
        Begin
          Result.Add(RSErrorField, E.Message);
          Exit;
        End;
End;

Result.Add(RSPDFField, arquivofinal);
Result.Add(RSChaveField, chClean);
Result.Add('url', '/nfe/pdf/' + chClean);
Result.Add(RSTamanhoField, tamanho.ToString);
// Adiciona o identificador ÃƒÂºnico se ele existir
If xmlData.Find(RSIDField, id) Then
  Result.Add(RSIDField, id);

facbr.NotasFiscais.Clear;
End;

Function TACBRBridgeNFe.TesteConfig: boolean;
Begin
  Try
    CarregaConfig;
    Result := True;
  Except
    Result := False;
End;
End;

Function TACBRBridgeNFe.DebugConfig: TJSONObject;
Begin
  CarregaConfig;
  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
End;

Function TACBRBridgeNFe.StatusServico(Const jStatus: TJSONObject): TJSONObject;
Begin
  CarregaConfig;
  Try
    facbr.WebServices.StatusServico.Executar;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.StatusServico, 'Erro ao consultar status');
  Except
    on E: Exception Do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao consultar status: ' + E.Message);
  End;
End;

Function TACBRBridgeNFe.Consulta(Const jConsulta: TJSONObject): TJSONObject;
Var
  Chave, XmlNode: TJSONData;
  xmlStr: string;
Begin
  CarregaConfig;

  Chave := jConsulta.Find('NFe_Chave');
  if not Assigned(Chave) then Chave := jConsulta.Find('chave');
  if not Assigned(Chave) then Chave := jConsulta.Find('Chave');
  if not Assigned(Chave) then Chave := jConsulta.Find('chNFe');

  If Assigned(Chave) and (Trim(Chave.AsString) <> '') Then
  Begin
    Try
      facbr.NotasFiscais.Clear;
      facbr.WebServices.Consulta.NFeChave := Trim(Chave.AsString);
      facbr.WebServices.Consulta.Executar;
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consulta, 'Erro na consulta');
    Except
      on E: Exception Do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro na consulta: ' + E.Message);
    End;
  End
  Else
  Begin
    XmlNode := jConsulta.Find('xml');
    if not Assigned(XmlNode) then XmlNode := jConsulta.Find('XML');
    if Assigned(XmlNode) and (Trim(XmlNode.AsString) <> '') then
    begin
      Try
        xmlStr := ReadXMLFromJSON(jConsulta);
        facbr.NotasFiscais.Clear;
        facbr.NotasFiscais.LoadFromString(xmlStr);
        facbr.Consultar;
        Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consulta, 'Erro na consulta por XML');
        if facbr.NotasFiscais.Count > 0 then
          Result.Add('xml_atualizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XML));
      Except
        on E: Exception Do
          Result := TJSONTools.SafeObjToJson(nil, 'Erro na consulta por XML: ' + E.Message);
      End;
    end
    else
      Result := TJSONTools.SafeObjToJson(nil, 'Chave nao informada para consulta.');
  End;
End;

Function TACBRBridgeNFe.ConsultaRecibo(Const jConsulta: TJSONObject): TJSONObject;
Var
  Recibo: TJSONData;
Begin
  CarregaConfig;

  If jConsulta.Find('Recibo', Recibo) Then
  Begin
    Try
      facbr.WebServices.Retorno.Recibo := Recibo.AsString;
      facbr.WebServices.Retorno.Executar;
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro na consulta do recibo');
    Except
      on E: Exception Do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro na consulta do recibo: ' + E.Message);
    End;
  End
  Else
    Result := TJSONTools.SafeObjToJson(nil, 'Recibo nao informado para consulta.');
End;

Function TACBRBridgeNFe.Inutilizacao(Const jInutilizacao: TJSONObject): TJSONObject;
Begin
  CarregaConfig;

  Try
    TJSONTools.JsonToObj(jInutilizacao, facbr.WebServices.Inutilizacao);
    facbr.WebServices.Inutilizacao.Executar;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.Inutilizacao, 'Erro na inutilizacao');
  Except
    on E: Exception Do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro na inutilizacao: ' + E.Message);
  End;
End;

Function TACBRBridgeNFe.Cancelamento(Const jCancelamento: TJSONObject): TJSONObject;
Var
  idLote: Integer;
  evtItem: TInfEventoCollectionItem;
  sChave, sProt, sJust, sCnpj, sChaveSubst: string;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;
  idLote := 1;
  facbr.EventoNFe.Evento.Clear;
  facbr.EventoNFe.idLote := idLote;

  evtItem := facbr.EventoNFe.Evento.New;
  Try
    if Assigned(jCancelamento.Find('InfEvento')) or Assigned(jCancelamento.Find('infEvento')) then
      TJSONTools.JsonToObj(jCancelamento, evtItem)
    else
      TJSONTools.JsonToObj(jCancelamento, evtItem.InfEvento);
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao converter JSON para Evento: ' + E.Message);
      Exit;
    End;
  End;

  // Suporte a campos planos (chave, protocolo, justificativa, cnpj, chNFeSubstituta)
  sChave := jCancelamento.Get('chave', jCancelamento.Get('chNFe', ''));
  sProt := jCancelamento.Get('protocolo', jCancelamento.Get('nProt', ''));
  sJust := jCancelamento.Get('justificativa', jCancelamento.Get('xJust', ''));
  sCnpj := jCancelamento.Get('cnpj', jCancelamento.Get('CNPJ', ''));
  sChaveSubst := jCancelamento.Get('chNFeSubstituta', jCancelamento.Get('chNFeRef', ''));

  // Garante tipo de evento cancelamento (ou substituicao 110112) e data se faltar
  with evtItem.InfEvento do
  begin
    if (chNFe = '') and (sChave <> '') then chNFe := sChave;
    if (detEvento.nProt = '') and (sProt <> '') then detEvento.nProt := sProt;
    if (detEvento.xJust = '') and (sJust <> '') then detEvento.xJust := sJust;
    if (CNPJ = '') and (sCnpj <> '') then CNPJ := sCnpj;
    if (detEvento.chNFeRef = '') and (sChaveSubst <> '') then detEvento.chNFeRef := sChaveSubst;

    if detEvento.chNFeRef <> '' then
      tpEvento := teCancSubst
    else if (tpEvento <> teCancelamento) and (tpEvento <> teCancSubst) then
      tpEvento := teCancelamento;

    if dhEvento = 0 then dhEvento := Now;
    if (CNPJ = '') and (Length(chNFe) >= 20) then CNPJ := Copy(chNFe, 7, 14);
    if nSeqEvento <= 0 then nSeqEvento := 1;
  end;

  Try
    facbr.EnviarEvento(idLote);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento, 'Erro ao enviar evento de cancelamento');
  Except
    on E: Exception Do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao enviar evento de cancelamento: ' + E.Message);
  End;
End;

Function TACBRBridgeNFe.NFeFromXML(Const jXML: TJSONObject): TJSONObject;
Var
  xmlBase64: string;
Begin
  CarregaConfig;
  Try
    xmlBase64 := ReadXMLFromJSON(jXML);
    facbr.NotasFiscais.LoadFromString(xmlBase64);
    If facbr.NotasFiscais.Count > 0 Then
    Begin
      Result := TJSONTools.SafeObjToJson(facbr.NotasFiscais.Items[0].NFe, 'Erro na conversao XML para JSON');
      if Result.Find(RSStatusField) = nil then
      begin
        Result.Delete(RSXMLField);
        Result.Delete(RSXMLOriginalField);
        Result.Delete(RSNomeArqField);
        Result.Delete(RSErroValidacaoCompletoField);
        Result.Delete(RSErroValidacaoField);
        Result.Delete(RSErroRegrasdeNegociosField);
        Result.Delete(RSAlertasField);
      end;
    End
    Else
      Result := TJSONTools.SafeObjToJson(nil, 'Nenhuma NF-e carregada do XML.');
  Except
    on E: Exception Do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro na conversao XML para JSON: ' + E.Message);
  End;
  facbr.NotasFiscais.Clear;
End;

Function TACBRBridgeNFe.NFeToXML(Const jNFe: TJSONObject): TJSONObject;
Var
  Nota: NotaFiscal;
  xmlString, chClean: string;
Begin
  CarregaConfig;

  Try
    Nota := facbr.NotasFiscais.Add;
    if Assigned(jNFe.Find('NFe')) then
      TJSONTools.JsonToObj(jNFe, Nota)
    else
      TJSONTools.JsonToObj(jNFe, Nota.NFe);
    Nota.NFe.infNFe.Versao := pcnConversaoNFe.VersaoDFToDbl(facbr.Configuracoes.Geral.VersaoDF);
  Except
    on E: Exception Do
    Begin
      Result := TJSONTools.SafeObjToJson(nil, RSErrorReadingJSON + E.Message);
      facbr.NotasFiscais.Clear;
      Exit;
    End;
  End;

  Try
    facbr.NotasFiscais.GerarNFe;
    xmlString := facbr.NotasFiscais.Items[0].XMLOriginal;
    If xmlString = '' Then
      xmlString := facbr.NotasFiscais.Items[0].XML;
    chClean := StringReplace(facbr.NotasFiscais.Items[0].NFe.infNFe.ID, 'NFe', '', [rfIgnoreCase]);

    Result := TJSONObject.Create;
    Result.Add('xml', EncodeStringBase64(xmlString));
    Result.Add('xml_raw', xmlString);
    Result.Add('chave', chClean);
  Except
    on E: Exception Do
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao gerar XML da NF-e: ' + E.Message);
  End;

  facbr.NotasFiscais.Clear;
End;

Function TACBRBridgeNFe.ValidarRegras(Const jNFe: TJSONObject): TJSONObject;
Var
  Nota: NotaFiscal;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  Try
    facbr.NotasFiscais.Clear;
    Nota := facbr.NotasFiscais.Add;

    Try
      if Assigned(jNFe.Find('NFe')) then
        TJSONTools.JsonToObj(jNFe, Nota)
      else
        TJSONTools.JsonToObj(jNFe, Nota.NFe);
      Nota.NFe.infNFe.Versao := pcnConversaoNFe.VersaoDFToDbl(facbr.Configuracoes.Geral.VersaoDF);
    Except
      on E: Exception Do
      Begin
        Result.Add(RSStatusField, 'erro_parse');
        Result.Add(RSMessageField, 'Erro na conversao JSON para Objeto: ' + E.Message);
        Exit;
      End;
    End;

    Try
      facbr.NotasFiscais.Items[0].Assinar;
      facbr.NotasFiscais.Items[0].Validar;

      Result := TJSONObject.Create;
      Result.Add(RSStatusField, 'sucesso');
      Result.Add(RSMessageField, 'XML Valido e Assinado');
      Result.Add('xml_assinado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XML));
      Result.Add('chave', StringReplace(facbr.NotasFiscais.Items[0].NFe.infNFe.ID, 'NFe', '', [rfIgnoreCase]));
    Except
      on E: Exception Do
      Begin
        Result := TJSONTools.SafeObjToJson(nil, E.Message);
        Result.Delete(RSStatusField);
        Result.Add(RSStatusField, 'erro_validacao');
        If facbr.NotasFiscais.Items[0].ErroValidacao <> '' Then
          Result.Add('detalhes', facbr.NotasFiscais.Items[0].ErroValidacao);
      End;
    End;

  Finally
    facbr.NotasFiscais.Clear;
  End;
End;

Function TACBRBridgeNFe.DanfeEvento(Const xmlEvento: TJSONObject): TJSONObject;
Var
  arquivofinal: string;
  stringXml, nfeXmlStr, fileName: string;
  nfeXmlNode: TJSONData;
  tamanho: integer;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  Try
    stringXml := ReadXMLFromJSON(xmlEvento);
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, E.Message);
      Exit;
    End;
  End;

  Try
    facbr.NotasFiscais.Clear;
    nfeXmlNode := xmlEvento.Find('XML');
    if not Assigned(nfeXmlNode) then nfeXmlNode := xmlEvento.Find('xml_nfe');
    if not Assigned(nfeXmlNode) then nfeXmlNode := xmlEvento.Find('NFeXML');
    if Assigned(nfeXmlNode) and (Trim(nfeXmlNode.AsString) <> '') then
    begin
      nfeXmlStr := Trim(nfeXmlNode.AsString);
      if nfeXmlStr[1] <> '<' then
        nfeXmlStr := DecodeStringBase64(nfeXmlStr);
      if nfeXmlStr <> stringXml then
        facbr.NotasFiscais.LoadFromString(nfeXmlStr);
    end;

    facbr.EventoNFe.Evento.Clear;
    facbr.EventoNFe.LerXMLFromString(stringXml);

    If facbr.EventoNFe.Evento.Count = 0 Then
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Nenhum evento foi carregado a partir do XML.');
      Exit;
    End;

    If facbr.NotasFiscais.Count = 0 Then
      facbr.NotasFiscais.Add.NFe.infNFe.ID := 'NFe' + facbr.EventoNFe.Evento.Items[0].InfEvento.chNFe;

    fdanfe.MostraPreview := False;
    fdanfe.MostraStatus := False;

    fileName := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;
    if not DirectoryExists(fileName) then
      CreateDir(fileName);
    fdanfe.PathPDF := fileName;

    facbr.ImprimirEventoPDF;
    fileName := fdanfe.ArquivoPDF;
    if (fileName = '') or (not FileExists(fileName)) then
      fileName := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim +
        TpEventoToStr(facbr.EventoNFe.Evento.Items[0].InfEvento.tpEvento) +
        StringReplace(facbr.EventoNFe.Evento.Items[0].InfEvento.chNFe, 'NFe', '', [rfIgnoreCase]) + '-nfe.pdf';

    arquivofinal := FileToStringBase64(fileName, False, tamanho);

    Result.Add(RSPDFField, arquivofinal);
    Result.Add(RSTamanhoField, tamanho.ToString);
    Result.Add(RSStatusField, 'sucesso');
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao gerar PDF do Evento: ' + E.Message);
    End;
  End;
End;



Function TACBRBridgeNFe.DanfeEscPos(Const xmlData: TJSONObject): TJSONObject;
Var
  stringXml, tempFile, bufferTxt, chClean: string;
  escPosDanfe: TACBrNFeDANFeESCPOS;
  posPrinter: TACBrPosPrinter;
Begin
  if fcfg <> '' then
    CarregaConfig;
  Result := TJSONObject.Create;

  Try
    stringXml := ReadXMLFromJSON(xmlData);
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, E.Message);
      Exit;
    End;
  End;

  escPosDanfe := TACBrNFeDANFeESCPOS.Create(Nil);
  posPrinter := TACBrPosPrinter.Create(Nil);
  Try
    Try
      facbr.NotasFiscais.Clear;
      facbr.NotasFiscais.LoadFromString(stringXml);
      If facbr.NotasFiscais.Count = 0 Then
      Begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Nenhuma nota fiscal foi carregada a partir do XML.');
        Exit;
      End;

      posPrinter.IgnorarTags := xmlData.Get('IgnorarTags', False);
      posPrinter.Modelo := TACBrPosPrinterModelo(xmlData.Get('ModeloImpressora', Integer(ppTexto)));
      posPrinter.ColunasFonteNormal := xmlData.Get('ColunasFonteNormal', 48);

      tempFile := ExtractFilePath(ParamStr(0)) + 'escpos_' + IntToStr(GetTickCount64) + '.txt';
      posPrinter.Porta := tempFile;

      escPosDanfe.PosPrinter := posPrinter;
      escPosDanfe.ImprimeEmUmaLinha := xmlData.Get('ImprimeEmUmaLinha', False);
      facbr.DANFE := escPosDanfe;

      escPosDanfe.ImprimirDANFE;

      bufferTxt := posPrinter.Buffer.Text;
      If FileExists(tempFile) Then
        SysUtils.DeleteFile(tempFile);

      chClean := StringReplace(facbr.NotasFiscais.Items[0].NFe.infNFe.ID, 'NFe', '', [rfIgnoreCase]);

      Result.Add(RSStatusField, 'sucesso');
      Result.Add(RSChaveField, chClean);
      Result.Add('modelo', facbr.NotasFiscais.Items[0].NFe.Ide.modelo);
      Result.Add('buffer_texto', bufferTxt);
      Result.Add('buffer_base64', EncodeStringBase64(bufferTxt));
    Except
      on E: Exception Do
      Begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Erro ao gerar DANFE EscPos: ' + E.Message);
      End;
    End;
  Finally
    facbr.DANFE := fdanfe;
    facbr.NotasFiscais.Clear;
    posPrinter.Free;
    escPosDanfe.Free;
  End;
End;


Function TACBRBridgeNFe.ConsultaCadastro(Const jConsulta: TJSONObject): TJSONObject;
Var
  ufStr, cnpjStr, cpfStr, ieStr, docStr: string;
  porIE: Boolean;
Begin
  CarregaConfig;
  ufStr := Trim(jConsulta.Get('UF', jConsulta.Get('uf', '')));
  cnpjStr := Trim(jConsulta.Get('CNPJ', jConsulta.Get('cnpj', '')));
  cpfStr := Trim(jConsulta.Get('CPF', jConsulta.Get('cpf', '')));
  ieStr := Trim(jConsulta.Get('IE', jConsulta.Get('ie', '')));
  docStr := Trim(jConsulta.Get('Documento', jConsulta.Get('documento', '')));

  if (docStr <> '') and (cnpjStr = '') and (cpfStr = '') and (ieStr = '') then
  begin
    porIE := jConsulta.Get('PorIE', jConsulta.Get('porIE', False));
    if porIE then
      ieStr := docStr
    else if Length(docStr) = 11 then
      cpfStr := docStr
    else
      cnpjStr := docStr;
  end;

  if ufStr = '' then
  begin
    Result := TJSONTools.SafeObjToJson(nil, 'UF nao informada para consulta de cadastro na SEFAZ.');
    Exit;
  end;

  try
    facbr.SSL.CarregarCertificado;
    facbr.WebServices.ConsultaCadastro.UF := ufStr;
    facbr.WebServices.ConsultaCadastro.CNPJ := cnpjStr;
    facbr.WebServices.ConsultaCadastro.CPF := cpfStr;
    facbr.WebServices.ConsultaCadastro.IE := ieStr;
    try
      facbr.WebServices.ConsultaCadastro.Executar;
    except
      on E: Exception do
      begin
        if facbr.WebServices.ConsultaCadastro.cStat = 0 then
          raise;
      end;
    end;
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.ConsultaCadastro, 'Erro na consulta de cadastro');
  except
    on E: Exception do
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.ConsultaCadastro, 'Erro na consulta de cadastro: ' + E.Message);
  end;
End;


Function TACBRBridgeNFe.EnviarEmail(Const jEmail: TJSONObject): TJSONObject;
Var
  stringXml, para, assunto, msgTxt, pdfDir: string;
  enviaPdf: Boolean;
  mailComponent: TACBrMail;
  jMailCfg, jCc: TJSONData;
  msgLines, ccLines: TStringList;
  I: Integer;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  Try
    stringXml := ReadXMLFromJSON(jEmail);
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSErrorField, E.Message);
      Exit;
    End;
  End;

  para := Trim(jEmail.Get('para', jEmail.Get('Para', jEmail.Get('destinatario', jEmail.Get('email', '')))));
  if para = '' then
  begin
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSErrorField, 'Destinatario ("para" / "email") nao informado para envio de e-mail.');
    Exit;
  end;

  assunto := jEmail.Get('assunto', jEmail.Get('Assunto', 'Nota Fiscal Eletronica'));
  msgTxt := jEmail.Get('mensagem', jEmail.Get('Mensagem', 'Segue em anexo o documento fiscal eletronico.'));
  enviaPdf := jEmail.Get('enviaPDF', jEmail.Get('EnviaPDF', True));

  mailComponent := TACBrMail.Create(Nil);
  msgLines := TStringList.Create;
  ccLines := TStringList.Create;
  Try
    Try
      jMailCfg := jEmail.Find('mail');
      if not Assigned(jMailCfg) then jMailCfg := jEmail.Find('Mail');
      if not Assigned(jMailCfg) then jMailCfg := jEmail.Find('smtp');
      if Assigned(jMailCfg) and (jMailCfg.JSONType = jtObject) then
        TJSONTools.JsonToObj(TJSONObject(jMailCfg), mailComponent)
      else
      begin
        mailComponent.Host := jEmail.Get('Host', jEmail.Get('host', ''));
        mailComponent.Port := IntToStr(jEmail.Get('Port', jEmail.Get('port', 587)));
        mailComponent.Username := jEmail.Get('Username', jEmail.Get('username', ''));
        mailComponent.Password := jEmail.Get('Password', jEmail.Get('password', ''));
        mailComponent.From := jEmail.Get('From', jEmail.Get('from', mailComponent.Username));
        mailComponent.FromName := jEmail.Get('FromName', jEmail.Get('fromName', ''));
        mailComponent.SetSSL := jEmail.Get('SetSSL', jEmail.Get('setSSL', False));
        mailComponent.SetTLS := jEmail.Get('SetTLS', jEmail.Get('setTLS', True));
      end;

      msgLines.Text := msgTxt;

      jCc := jEmail.Find('cc');
      if not Assigned(jCc) then jCc := jEmail.Find('CC');
      if Assigned(jCc) then
      begin
        if jCc.JSONType = jtArray then
        begin
          for I := 0 to TJSONArray(jCc).Count - 1 do
            ccLines.Add(TJSONArray(jCc).Items[I].AsString);
        end
        else if Trim(jCc.AsString) <> '' then
          ccLines.Text := StringReplace(jCc.AsString, ';', LineEnding, [rfReplaceAll]);
      end;

      facbr.NotasFiscais.Clear;
      facbr.NotasFiscais.LoadFromString(stringXml);
      if facbr.NotasFiscais.Count = 0 then
      begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Nenhuma nota fiscal foi carregada a partir do XML para envio de e-mail.');
        Exit;
      end;

      pdfDir := ExtractFilePath(ParamStr(0)) + 'pdf' + PathDelim;
      if not DirectoryExists(pdfDir) then
        CreateDir(pdfDir);
      fdanfe.PathPDF := pdfDir;
      fdanfe.MostraPreview := False;
      fdanfe.MostraStatus := False;
      fdanfe.MostraSetup := False;

      facbr.DANFE := fdanfe;
      facbr.MAIL := mailComponent;

      facbr.NotasFiscais.Items[0].EnviarEmail(para, assunto, msgLines, enviaPdf, ccLines, nil, nil);

      Result.Add(RSStatusField, 'sucesso');
      Result.Add('para', para);
      Result.Add('assunto', assunto);
    Except
      on E: Exception Do
      Begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSErrorField, 'Erro ao enviar e-mail da NF-e: ' + E.Message);
      End;
    End;
  Finally
    facbr.MAIL := Nil;
    facbr.NotasFiscais.Clear;
    ccLines.Free;
    msgLines.Free;
    mailComponent.Free;
  End;
End;


End.
