{%RunFlags MESSAGES+}

Unit method.acbr.nfe;

{$MODESWITCH ExtendedRTTI ON}
{$RTTI EXPLICIT PROPERTIES([vcPublic])}

Interface

Uses streamtools,
RTTI,
ACBrNFe,
ACBrNFe.EnvEvento,
ACBrNFe.EventoClass,
ACBrNFeNotasFiscais,
ACBrNFeDANFeRLClass,
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
Controls,
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
      fdanfe: TACBrNFeDANFeRL;
      Procedure CarregaConfig;

      Function ReadXMLFromJSON(Const jsonData: TJSONObject): string;
    Public 
      constructor Create(Const Cfg: String);
      destructor Destroy;
      override;

      // Envia um evento
      Function Evento(Const jEventos: TJSONArray): string;
      // Distribuição
      Function Distribuicao(Const jDistribuicao: TJSONObject): TJSONObject;
      // DANFE
      Function Danfe(Const xmlData: TJSONObject): TJSONObject;
      // Envia uma NFE
      Function NFe(Const jNFe: TJSONObject): TJSONObject;

      // Teste a configuração passada em JSON
      Function TesteConfig: boolean;
  End;


{ TACBRModelosJSON - Salva os retornos de modelo de requisições, para facilitar
  documentação ou consulta por parte do programador.}

  TACBRModelosJSON = Class(TACBRBridgeNFe)
    Private 
    Public 
      // Retorna as configurações atuais do componente da ACBR.
      Function ModelConfig: TJSONObject;
      Function ModelEvento: TJSONObject;
      Function ModelDistribuicao: string;
      Function ModelNFe: TJSONObject;
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
  Result := TJSONTools.ObjToJsonString(facbr.WebServices.DistribuicaoDFe);
  //  facbr.EventoNFe.Evento.Clear;
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

  Result := TJSONObject.Create;
  //Gera objeto TNotaFiscal da unit ACBrNFeNotasFiscais
  Nota := facbr.NotasFiscais.Add;
  // Inicia o número do lote do envio da NFe
  Lote := 1;
  // Alimenta o objeto Nota com os valores passandos por JSON
  Try
    TJSONTools.JsonToObj(jNFe, Nota);
  Except
    on E: Exception Do
          Begin
            Result.Add(RSStatusField, RSStatusErro);
            Result.Add(RSMessageField, RSErrorReadingJSON + E.Message
            );
            Exit;
          End;
End;

Try
  // Pede a ACBR para transmitir os dados
  facbr.WebServices.Envia(Lote, True, False);
Finally
  Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebServices.Retorno));
End;

facbr.NotasFiscais.Clear;
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
  fdanfe := TACBrNFeDANFeRL.Create(Nil);
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

// Esvazia a string para liberar da memória logo o xml
stringXml := RSEmptyString;
// O acesso a propriedade TipoDanfe se faz somente diretamente pelo objeto.
If facbr.NotasFiscais.Items[0].NFe.Ide.tpImp <> TpcnTipoImpressao.tiPaisagem
  Then
  fdanfe.TipoDANFE := tiRetrato
Else
  fdanfe.TipoDANFE := tiPaisagem;


// Como é um aplicativo console, jamais a propriedade MostraStatus deve ser true.
fdanfe.MostraPreview := False;
fdanfe.MostraStatus := False;
fdanfe.MostraSetup := False;

//Gerando arquivo temporário
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

// Converte a stream do relatório para base64
Result.Add(RSPDFField, arquivofinal);
// Chave de Acesso da NF-e
Result.Add(RSChaveField, facbr.NotasFiscais.Items[0].NFe.infNFe.ID);
// Tamanho em Bytes
Result.Add(RSTamanhoField, tamanho.ToString);
// Adiciona o identificador único se ele existir
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


End.
