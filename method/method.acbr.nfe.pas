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
Base64,
jsonparser,
Classes, SysUtils,
resource.strings.global,
resource.strings.msg;

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

      // Teste a configuraÃƒÂ§ÃƒÂ£o passada em JSON
      Function TesteConfig: boolean;
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
  // O modelo ÃƒÂ© o mesmo da NF-e Ã¢â‚¬â€ envie o JSON da NF-e e receba o XML gerado
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
  // Inicia o nÃƒÂºmero do lote do envio da NFe
  Lote := 1;
  // Alimenta o objeto Nota com os valores passandos por JSON
  Try
    TJSONTools.JsonToObj(jNFe, Nota);
  Except
    on E: Exception Do
          Begin
            Result := TJSONTools.SafeObjToJson(nil, RSErrorReadingJSON + E.Message);
            Exit;
          End;
End;

Try
  // Pede a ACBR para transmitir os dados
  facbr.WebServices.Envia(Lote, True, False);
  Result := TJSONTools.SafeObjToJson(facbr.WebServices.Retorno, 'Erro ao enviar NFe');
Finally
  facbr.NotasFiscais.Clear;
End;
End;


Procedure TACBRBridgeNFe.CarregaConfig;

Var 
  O: TJSONObject;
Begin
  If fcfg = RSEmptyString Then
    exit;

  O := GetJSON(fcfg) as TJSONObject;
  Try
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
  Finally
    O.Free;
End;

fcfg := RSEmptyString;
End;

Function TACBRBridgeNFe.ReadXMLFromJSON(Const jsonData: TJSONObject): string;

Var 
  xmlBase64: string;
Begin
  Try
    xmlBase64 := jsonData.Extract('xml').AsString;
  Except
    on E: Exception Do
          Begin
            raise Exception.Create(
                               RSErrorReadingXMLParam
                                   +
                                   E.Message);
          End;
End;

Try
  Result := DecodeStringBase64(xmlBase64);
  xmlBase64 := RSEmptyString;
Except
  on E: Exception Do
        Begin
          raise Exception.Create(RSInvalidBase64XML + E
                                 .Message);
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
  InfEvento: TJSONObject;
  XmlBase64: TJSONString;
Begin
  CarregaConfig;
  Result := RSEmptyString;



  For I := 0 To jEventos.Count - 1 Do
    Begin
      oEvento := jEventos.Items[i] as TJSONObject;
      InfEvento := oEvento.Extract(RSInfEventoField) as TJSONObject;
      If InfEvento.Find(RSLoadXMLField, XmlBase64) Then
        facbr.NotasFiscais.LoadFromString(Base64.DecodeStringBase64(XmlBase64.
                                          AsString));

      objEvento := facbr.EventoNFe.Evento.New;
      TJSONTools.JsonToObj(oEvento, objEvento);
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

// Esvazia a string para liberar da memÃƒÂ³ria logo o xml
stringXml := RSEmptyString;
// O acesso a propriedade TipoDanfe se faz somente diretamente pelo objeto.
If facbr.NotasFiscais.Items[0].NFe.Ide.tpImp <> TpcnTipoImpressao.tiPaisagem
  Then
  fdanfe.TipoDANFE := tiRetrato
Else
  fdanfe.TipoDANFE := tiPaisagem;


// Como ÃƒÂ© um aplicativo console, jamais a propriedade MostraStatus deve ser true.
fdanfe.MostraPreview := False;
fdanfe.MostraStatus := False;
fdanfe.MostraSetup := False;

//Gerando arquivo temporÃƒÂ¡rio
fileName := GetTempFileName;
// Realiza o processo de transformar o XML em PDF (Danfe)
Try
  fDAnFe.PathPDF := filename;
  facbr.NotasFiscais.ImprimirPDF;
  filename := fdanfe.ArquivoPDF;
Except
  Begin
    Result.Add(RSErrorField, RSPDFGenerationError);
    Exit;
  End;
End;

// Converte o arquivo para base64
Try
  arquivofinal := FileToStringBase64(filename, True, tamanho);
Except
  on E: Exception Do
        Begin
          Result.Add(RSErrorField, E.Message);
          Exit;
        End;
End;

// Converte a stream do relatÃƒÂ³rio para base64
Result.Add(RSPDFField, arquivofinal);
// Chave de Acesso da NF-e
Result.Add(RSChaveField, facbr.NotasFiscais.Items[0].NFe.infNFe.ID);
// Tamanho em Bytes
Result.Add(RSTamanhoField, tamanho.ToString);
// Adiciona o identificador ÃƒÂºnico se ele existir
If xmlData.Find(RSIDField, id) Then
  Result.Add(RSIDField, id);

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
  Chave: TJSONData;
Begin
  CarregaConfig;

  If jConsulta.Find('NFe_Chave', Chave) Then
  Begin
    Try
      facbr.WebServices.Consulta.NFeChave := Chave.AsString;
      facbr.WebServices.Consulta.Executar;
      Result := TJSONTools.SafeObjToJson(facbr.WebServices.Consulta, 'Erro na consulta');
    Except
      on E: Exception Do
        Result := TJSONTools.SafeObjToJson(nil, 'Erro na consulta: ' + E.Message);
    End;
  End
  Else
    Result := TJSONTools.SafeObjToJson(nil, 'Chave nao informada para consulta.');
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
Begin
  CarregaConfig;
  Result := TJSONObject.Create;
  idLote := 1;
  facbr.EventoNFe.Evento.Clear;
  facbr.EventoNFe.idLote := idLote;

  Try
    TJSONTools.JsonToObj(jCancelamento, facbr.EventoNFe.Evento.New);
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao converter JSON para Evento: ' + E.Message);
      Exit;
    End;
  End;

  // Garante tipo de evento cancelamento e data se faltar
  with facbr.EventoNFe.Evento.Items[0].InfEvento do
  begin
    if tpEvento <> teCancelamento then tpEvento := teCancelamento;
    if dhEvento = 0 then dhEvento := Now;
    if CNPJ = '' then CNPJ := Copy(chNFe, 7, 14);
  end;

  Try
    facbr.EnviarEvento(idLote);
    Result := TJSONTools.SafeObjToJson(facbr.WebServices.EnvEvento.EventoRetorno.retEvento, 'Erro ao enviar evento de cancelamento');
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
  xmlString: string;
Begin
  CarregaConfig;

  Try
    Nota := facbr.NotasFiscais.Add;
    TJSONTools.JsonToObj(jNFe, Nota);
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

    Result := TJSONObject.Create;
    Result.Add('xml', EncodeStringBase64(xmlString));
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
      TJSONTools.JsonToObj(jNFe, Nota);
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
  stringXml, fileName: string;
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
    facbr.EventoNFe.Evento.Clear;
    facbr.EventoNFe.LerXMLFromString(stringXml);

    fdanfe.MostraPreview := False;
    fdanfe.MostraStatus := False;

    fileName := GetTempFileName;
    fdanfe.PathPDF := fileName;

    facbr.ImprimirEventoPDF;
    fileName := fdanfe.ArquivoPDF;

    arquivofinal := FileToStringBase64(fileName, True, tamanho);

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


End.
