{%RunFlags MESSAGES+}

Unit method.acbr.nfse;

{$mode Delphi}
{$M+}

Interface

Uses streamtools,
RTTI,
ACBrNFSeX,
ACBrNFSeXNotasFiscais,
ACBrNFSeXWebservicesResponse,
ACBrNFSeXWebserviceBase,
ACBrNFSeXConversao,
ACBrNFSeXDANFSeFPDFClass,
ACBrMail,
ACBrDFeSSL,
ACBrDFeConfiguracoes,
ACBrNFSeXConfiguracoes,
synacode,
StrUtils,
Variants,
fpjson, jsonconvert,
Base64,
jsonparser,
Classes, SysUtils,
pcnConversao,
resource.strings.global,
resource.strings.msg;

Type 

  { TACBRBridgeNFSe }

  TACBRBridgeNFSe = Class
    Private 
      fcfg: string;
      facbr: TACBrNFSeX;
      fdanfse: TACBrNFSeXDANFSeFPDF;
      Procedure CarregaConfig;

      Function ReadXMLFromJSON(Const jsonData: TJSONObject): string;
    Public 
      constructor Create(Const Cfg: String);
      destructor Destroy;
      override;

      // Emite uma NFSe
      Function Emitir(Const jNFSe: TJSONObject): TJSONObject;
      // Gerar NFSe
      Function Gerar(Const jNFSe: TJSONObject): TJSONObject;
      // DANFSE
      Function Danfse(Const xmlData: TJSONObject): TJSONObject;
      // Consultar Situacao
      Function ConsultarSituacao(Const jConsulta: TJSONObject): TJSONObject;
      // Consultar Lote
      Function ConsultarLote(Const jConsulta: TJSONObject): TJSONObject;
      // Consultar NFSe Por Rps
      Function ConsultarNFSePorRps(Const jConsulta: TJSONObject): TJSONObject;
      // Consultar NFSe
      Function ConsultarNFSe(Const jConsulta: TJSONObject): TJSONObject;
      // Cancelar NFSe
      Function Cancelar(Const jCancelamento: TJSONObject): TJSONObject;
      // Substituir NFSe
      Function Substituir(Const jSubstituir: TJSONObject): TJSONObject;
      // Distribuicao DFe (Nacional)
      Function Distribuicao(Const jDistribuicao: TJSONObject): TJSONObject;
      // XML para JSON
      Function NFSeFromXML(Const jXML: TJSONObject): TJSONObject;
      // JSON para XML
      Function NFSeToXML(Const jNFSe: TJSONObject): TJSONObject;
      // Enviar Evento NFSe Padrao Nacional
      Function EnviarEvento(Const jEvento: TJSONObject): TJSONObject;
      
      // Teste a configuraÃ§Ã£o passada em JSON
      Function TesteConfig: boolean;
  End;


{ TACBRModelosJSONNFSe - Salva os retornos de modelo de requisiÃ§Ãµes, para facilitar
  documentaÃ§Ã£o ou consulta por parte do programador.}

  TACBRModelosJSONNFSe = Class(TACBRBridgeNFSe)
    Private 
    Public 
      Function ModelConfig: TJSONObject;
      Function ModelEmitir: TJSONObject;
      Function ModelConsultarSituacao: TJSONObject;
      Function ModelConsultarLote: TJSONObject;
      Function ModelConsultarNFSePorRps: TJSONObject;
      Function ModelConsultarNFSe: TJSONObject;
      Function ModelCancelar: TJSONObject;
      Function ModelSubstituir: TJSONObject;
      Function ModelNFSeFromXML: TJSONObject;
      Function ModelNFSeToXML: TJSONObject;
      Function ModelEvento: TJSONObject;
  End;

Implementation


{ TACBRModelosJSONNFSe }

Function TACBRModelosJSONNFSe.ModelConfig: TJSONObject;
Begin
  With facbr.Configuracoes.Geral Do
    Begin
      RetirarAcentos := True;
      Salvar := True;
      SSLLib := TSSLLib.libOpenSSL;
      SSLCryptLib := TSSLCryptLib.cryOpenSSL;
      SSLHttpLib := TSSLHttpLib.httpOpenSSL;
      SSLXmlSignLib := TSSLXmlSignLib.xsLibXml2;
    End;

  With facbr.Configuracoes.WebServices Do
    Begin
      Ambiente := TpcnTipoAmbiente.taHomologacao;
      TimeOut := 5000;
    End;

  With facbr.Configuracoes.Certificados Do
    Begin
      ArquivoPFX := RSDefaultCertPath;
      Senha := RSDefaultCertPassword;
    End;

  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
End;

Function TACBRModelosJSONNFSe.ModelEmitir: TJSONObject;
Var
  Nota: TNotaFiscal;
Begin
  facbr.NotasFiscais.Clear;
  Nota := facbr.NotasFiscais.New;
  Result := TJSONTools.ObjToJson(Nota);
  facbr.NotasFiscais.Clear;
End;

Function TACBRModelosJSONNFSe.ModelConsultarSituacao: TJSONObject;
Begin
  Result := TJSONObject.Create;
  Result.Add('Protocolo', 'Preencha com o Protocolo');
  Result.Add('NumLote', 'Preencha com o Numero do Lote');
End;

Function TACBRModelosJSONNFSe.ModelConsultarLote: TJSONObject;
Begin
  Result := TJSONObject.Create;
  Result.Add('Protocolo', 'Preencha com o Protocolo');
  Result.Add('NumLote', 'Preencha com o Numero do Lote');
End;

Function TACBRModelosJSONNFSe.ModelConsultarNFSePorRps: TJSONObject;
Begin
  Result := TJSONObject.Create;
  Result.Add('NumeroRps', 'Preencha com o Numero do RPS');
  Result.Add('Serie', 'Preencha com a Serie');
  Result.Add('Tipo', 'Preencha com o Tipo (ex: 1)');
  Result.Add('CodVerificacao', 'Preencha com o Codigo de Verificacao (Opcional)');
End;

Function TACBRModelosJSONNFSe.ModelConsultarNFSe: TJSONObject;
Begin
  Result := TJSONObject.Create;
  Result.Add('DataInicial', 'AAAA-MM-DD');
  Result.Add('DataFinal', 'AAAA-MM-DD');
  Result.Add('Pagina', '1');
End;

Function TACBRModelosJSONNFSe.ModelCancelar: TJSONObject;
Var
  InfCancelamento: TInfCancelamento;
Begin
  InfCancelamento := TInfCancelamento.Create;
  Try
    Result := TJSONTools.ObjToJson(InfCancelamento);
  Finally
    InfCancelamento.Free;
  End;
End;

Function TACBRModelosJSONNFSe.ModelSubstituir: TJSONObject;
Var
  Nota: TNotaFiscal;
Begin
  facbr.NotasFiscais.Clear;
  Nota := facbr.NotasFiscais.New;
  Result := TJSONTools.ObjToJson(Nota);
  Result.Add('NumeroNFSe', 'Numero da NFSe a ser substituida');
  Result.Add('CodigoCancelamento', 'Codigo de Cancelamento');
  Result.Add('MotivoCancelamento', 'Motivo do Cancelamento');
  Result.Add('ChaveNFSe', 'Chave da NFSe (se provedor exigir)');
  facbr.NotasFiscais.Clear;
End;


{ TACBRBridgeNFSe }

Procedure TACBRBridgeNFSe.CarregaConfig;
Var 
  O: TJSONObject;
  LPfx: AnsiString;
Begin
  if Trim(fcfg) = '' then
    raise Exception.Create(RSConfigEmptyError);

  try
    O := GetJSON(fcfg) as TJSONObject;
    Try
      TJSONTools.JsonToObj(O, facbr.Configuracoes);
      
      LPfx := TJSONTools.ExtractCertificadoPFX(O);
      if LPfx <> '' then
        facbr.Configuracoes.Certificados.DadosPFX := LPfx;

      with facbr.Configuracoes.Geral do
      begin
        SSLLib := libOpenSSL;
        SSLCryptLib := cryOpenSSL;
        SSLHttpLib := httpOpenSSL;
        SSLXmlSignLib := xsLibXml2;
      end;
    Finally
      O.Free;
    End;
  except
    on E: Exception do
      raise Exception.Create(RSConfigReadError + E.Message);
  end;

  // Garante PathSchemas padrão para NFSe se não foi informado
  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + RSSchemasDir + PathDelim + 'NFSe';

  fcfg := '';
End;

Function TACBRBridgeNFSe.ReadXMLFromJSON(Const jsonData: TJSONObject): string;
Begin
  Result := TJSONTools.ReadXMLFromJSON(jsonData, ['xml_nfse', 'NFSeXML', 'XMLNFSe', 'XmlRps', 'xml_rps', 'ArquivoXML', 'arquivo_xml']);
End;

constructor TACBRBridgeNFSe.Create(Const Cfg: String);
Begin
  facbr := TACBrNFSeX.Create(Nil);
  fdanfse := TACBrNFSeXDANFSeFPDF.Create(Nil);
  fcfg := Cfg;
  facbr.DANFSe := fdanfse;
End;

destructor TACBRBridgeNFSe.Destroy;
Begin
  facbr.Free;
  FreeAndNil(fdanfse);
  inherited Destroy;
End;

Function TACBRBridgeNFSe.Emitir(Const jNFSe: TJSONObject): TJSONObject;
Var 
  Lote: integer;
  Nota: TNotaFiscal;
  jTargetNode, jPrestNode, jTomNode: TJSONData;
  jTarget: TJSONObject;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Lote := 1;
  facbr.NotasFiscais.Clear;
  Nota := facbr.NotasFiscais.New;
  Try
    TJSONTools.JsonToObj(jNFSe, Nota);
    jTargetNode := jNFSe.Find('NFSe');
    if not Assigned(jTargetNode) then jTargetNode := jNFSe.Find('nfse');
    if Assigned(jTargetNode) and (jTargetNode.JSONType = jtObject) then
      jTarget := TJSONObject(jTargetNode)
    else
      jTarget := jNFSe;
    TJSONTools.JsonToObj(jTarget, Nota.NFSe);
    jPrestNode := jTarget.Find('Prestador');
    if not Assigned(jPrestNode) then jPrestNode := jTarget.Find('prestador');
    if Assigned(jPrestNode) and (jPrestNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jPrestNode), Nota.NFSe.Prestador.IdentificacaoPrestador);
    jTomNode := jTarget.Find('Tomador');
    if not Assigned(jTomNode) then jTomNode := jTarget.Find('tomador');
    if Assigned(jTomNode) and (jTomNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jTomNode), Nota.NFSe.Tomador.IdentificacaoTomador);
  Except
    on E: Exception Do
          Begin
            Result.Add(RSStatusField, RSStatusErro);
            Result.Add(RSMessageField, RSErrorReadingJSON + E.Message);
            facbr.NotasFiscais.Clear;
            Exit;
          End;
  End;

  Try
    facbr.Emitir(Lote.ToString);
    Result.Free;
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.Emite));
    if facbr.NotasFiscais.Count > 0 then
    begin
      if facbr.NotasFiscais.Items[0].XmlNfse <> '' then
        Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XmlNfse))
      else if facbr.NotasFiscais.Items[0].XmlRps <> '' then
        Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XmlRps));
    end;
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao emitir: ' + E.Message);
    End;
  End;

  facbr.NotasFiscais.Clear;
End;

Function TACBRBridgeNFSe.Gerar(Const jNFSe: TJSONObject): TJSONObject;
Var 
  Lote: integer;
  Nota: TNotaFiscal;
  jTargetNode, jPrestNode, jTomNode: TJSONData;
  jTarget: TJSONObject;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Lote := 1;
  facbr.NotasFiscais.Clear;
  Nota := facbr.NotasFiscais.New;
  Try
    TJSONTools.JsonToObj(jNFSe, Nota);
    jTargetNode := jNFSe.Find('NFSe');
    if not Assigned(jTargetNode) then jTargetNode := jNFSe.Find('nfse');
    if Assigned(jTargetNode) and (jTargetNode.JSONType = jtObject) then
      jTarget := TJSONObject(jTargetNode)
    else
      jTarget := jNFSe;
    TJSONTools.JsonToObj(jTarget, Nota.NFSe);
    jPrestNode := jTarget.Find('Prestador');
    if not Assigned(jPrestNode) then jPrestNode := jTarget.Find('prestador');
    if Assigned(jPrestNode) and (jPrestNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jPrestNode), Nota.NFSe.Prestador.IdentificacaoPrestador);
    jTomNode := jTarget.Find('Tomador');
    if not Assigned(jTomNode) then jTomNode := jTarget.Find('tomador');
    if Assigned(jTomNode) and (jTomNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jTomNode), Nota.NFSe.Tomador.IdentificacaoTomador);
  Except
    on E: Exception Do
          Begin
            Result.Add(RSStatusField, RSStatusErro);
            Result.Add(RSMessageField, RSErrorReadingJSON + E.Message);
            facbr.NotasFiscais.Clear;
            Exit;
          End;
  End;

  Try
    facbr.GerarLote(Lote.ToString, 50, meAutomatico);
    Result.Free;
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.Gerar));
    if facbr.NotasFiscais.Count > 0 then
    begin
      if facbr.NotasFiscais.Items[0].XmlNfse <> '' then
        Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XmlNfse))
      else if facbr.NotasFiscais.Items[0].XmlRps <> '' then
        Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XmlRps));
    end;
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao gerar: ' + E.Message);
    End;
  End;

  facbr.NotasFiscais.Clear;
End;


Function TACBRBridgeNFSe.ConsultarSituacao(Const jConsulta: TJSONObject): TJSONObject;
Var
  Protocolo, NumLote: TJSONData;
  vProt, vLote: string;
Begin
  CarregaConfig;
  Result := nil;

  Protocolo := jConsulta.Find('Protocolo');
  if not Assigned(Protocolo) then Protocolo := jConsulta.Find('protocolo');
  NumLote := jConsulta.Find('NumLote');
  if not Assigned(NumLote) then NumLote := jConsulta.Find('NumeroLote');
  if not Assigned(NumLote) then NumLote := jConsulta.Find('numeroLote');

  vProt := '';
  if Assigned(Protocolo) then vProt := Trim(Protocolo.AsString);
  vLote := '';
  if Assigned(NumLote) then vLote := Trim(NumLote.AsString);

  If (vProt <> '') or (vLote <> '') Then
  Begin
    Try
      facbr.ConsultarSituacao(vProt, vLote);
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaSituacao));
    Except
      on E: Exception Do
      Begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na consulta de situacao: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
    Result := TJSONObject.Create;
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'Protocolo ou NumLote nao informados.');
  End;
End;

Function TACBRBridgeNFSe.ConsultarLote(Const jConsulta: TJSONObject): TJSONObject;
Var
  Protocolo, NumLote: TJSONData;
  vProt, vLote: string;
Begin
  CarregaConfig;
  Result := nil;

  Protocolo := jConsulta.Find('Protocolo');
  if not Assigned(Protocolo) then Protocolo := jConsulta.Find('protocolo');
  NumLote := jConsulta.Find('NumLote');
  if not Assigned(NumLote) then NumLote := jConsulta.Find('NumeroLote');
  if not Assigned(NumLote) then NumLote := jConsulta.Find('numeroLote');

  vProt := '';
  if Assigned(Protocolo) then vProt := Trim(Protocolo.AsString);
  vLote := '';
  if Assigned(NumLote) then vLote := Trim(NumLote.AsString);

  If (vProt <> '') or (vLote <> '') Then
  Begin
    Try
      facbr.ConsultarLoteRps(vProt, vLote);
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaLoteRps));
    Except
      on E: Exception Do
      Begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na consulta de lote: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
    Result := TJSONObject.Create;
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'Protocolo ou NumLote nao informados.');
  End;
End;

Function TACBRBridgeNFSe.ConsultarNFSePorRps(Const jConsulta: TJSONObject): TJSONObject;
Var
  NumRps, Serie, Tipo, CodVerificacao: TJSONData;
  vNumRps, vSerie, vTipo, vCodVerificacao: string;
Begin
  CarregaConfig;
  Result := nil;

  NumRps := jConsulta.Find('NumeroRps');
  if not Assigned(NumRps) then NumRps := jConsulta.Find('numeroRps');
  Serie := jConsulta.Find('Serie');
  if not Assigned(Serie) then Serie := jConsulta.Find('SerieRps');
  if not Assigned(Serie) then Serie := jConsulta.Find('serieRps');
  Tipo := jConsulta.Find('Tipo');
  if not Assigned(Tipo) then Tipo := jConsulta.Find('TipoRps');
  if not Assigned(Tipo) then Tipo := jConsulta.Find('tipoRps');
  CodVerificacao := jConsulta.Find('CodVerificacao');
  if not Assigned(CodVerificacao) then CodVerificacao := jConsulta.Find('CodigoVerificacao');
  if not Assigned(CodVerificacao) then CodVerificacao := jConsulta.Find('codigoVerificacao');

  If Assigned(NumRps) and (Trim(NumRps.AsString) <> '') Then
  Begin
    Try
      vNumRps := Trim(NumRps.AsString);
      vSerie := '1';
      if Assigned(Serie) and (Trim(Serie.AsString) <> '') then
        vSerie := Trim(Serie.AsString);
      vTipo := '1';
      if Assigned(Tipo) and (Trim(Tipo.AsString) <> '') then
        vTipo := Trim(Tipo.AsString);
      vCodVerificacao := '';
      if Assigned(CodVerificacao) then
        vCodVerificacao := Trim(CodVerificacao.AsString);

      facbr.ConsultarNFSePorRps(vNumRps, vSerie, vTipo, vCodVerificacao);
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaNFSeporRps));
    Except
      on E: Exception Do
      Begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na consulta por RPS: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
    Result := TJSONObject.Create;
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'NumeroRps, Serie ou Tipo nao informados.');
  End;
End;

Function TACBRBridgeNFSe.ConsultarNFSe(Const jConsulta: TJSONObject): TJSONObject;
Var
  DataInicial, DataFinal, Pagina: TJSONData;
  vDataInicial, vDataFinal: TDateTime;
  vPagina: String;
Begin
  CarregaConfig;
  Result := nil;

  vDataInicial := 0;
  vDataFinal := 0;
  vPagina := '1';

  If jConsulta.Find('DataInicial', DataInicial) Then vDataInicial := StrToDateDef(DataInicial.AsString, 0);
  If jConsulta.Find('DataFinal', DataFinal) Then vDataFinal := StrToDateDef(DataFinal.AsString, 0);
  If jConsulta.Find('Pagina', Pagina) Then vPagina := Pagina.AsString;

  Try
    facbr.ConsultarNFSePorPeriodo(vDataInicial, vDataFinal, StrToIntDef(vPagina, 1));
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaNFSe));
  Except
    on E: Exception Do
    Begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro na consulta NFSe: ' + E.Message);
    End;
  End;
End;

Function TACBRBridgeNFSe.Cancelar(Const jCancelamento: TJSONObject): TJSONObject;
Var
  InfCancelamento: TInfCancelamento;
Begin
  CarregaConfig;
  Result := nil;

  InfCancelamento := TInfCancelamento.Create;
  Try
    Try
      TJSONTools.JsonToObj(jCancelamento, InfCancelamento);
    Except
      on E: Exception Do
      Begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao converter JSON para InfCancelamento: ' + E.Message);
        Exit;
      End;
    End;

    Try
      facbr.CancelarNFSe(InfCancelamento);
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.CancelaNFSe));
    Except
      on E: Exception Do
      Begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao cancelar: ' + E.Message);
      End;
    End;
  Finally
    InfCancelamento.Free;
  End;
End;

Function TACBRBridgeNFSe.Substituir(Const jSubstituir: TJSONObject): TJSONObject;
Var
  CodigoCancelamento, NumeroNFSe, jTargetNode, jPrestNode, jTomNode: TJSONData;
  Nota: TNotaFiscal;
  jTarget: TJSONObject;
Begin
  CarregaConfig;
  Result := nil;

  // Carrega RPS contida no JSON para Substituição
  facbr.NotasFiscais.Clear;
  Nota := facbr.NotasFiscais.New;
  Try
    TJSONTools.JsonToObj(jSubstituir, Nota);
    jTargetNode := jSubstituir.Find('NFSe');
    if not Assigned(jTargetNode) then jTargetNode := jSubstituir.Find('nfse');
    if Assigned(jTargetNode) and (jTargetNode.JSONType = jtObject) then
      jTarget := TJSONObject(jTargetNode)
    else
      jTarget := jSubstituir;
    TJSONTools.JsonToObj(jTarget, Nota.NFSe);
    jPrestNode := jTarget.Find('Prestador');
    if not Assigned(jPrestNode) then jPrestNode := jTarget.Find('prestador');
    if Assigned(jPrestNode) and (jPrestNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jPrestNode), Nota.NFSe.Prestador.IdentificacaoPrestador);
    jTomNode := jTarget.Find('Tomador');
    if not Assigned(jTomNode) then jTomNode := jTarget.Find('tomador');
    if Assigned(jTomNode) and (jTomNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jTomNode), Nota.NFSe.Tomador.IdentificacaoTomador);
  Except
    on E: Exception Do
    Begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao converter RPS para JSON: ' + E.Message);
      Exit;
    End;
  End;

  If jSubstituir.Find('NumeroNFSe', NumeroNFSe) and jSubstituir.Find('CodigoCancelamento', CodigoCancelamento) Then
  Begin
    Try
      facbr.SubstituirNFSe(NumeroNFSe.AsString, CodigoCancelamento.AsString, 
        jSubstituir.GetPath('MotivoCancelamento').AsString,
        jSubstituir.GetPath('ChaveNFSe').AsString);

      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.SubstituiNFSe));
    Except
      on E: Exception Do
      Begin
        Result := TJSONObject.Create;
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na substituicao: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
    Result := TJSONObject.Create;
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'NumeroNFSe ou CodigoCancelamento nao informados.');
  End;
End;

Function TACBRBridgeNFSe.Distribuicao(Const jDistribuicao: TJSONObject): TJSONObject;
Var
  CNPJ, Chave: TJSONData;
  NSU: TJSONData;
Begin
  CarregaConfig;
  Result := nil;
  Try
    If jDistribuicao.Find('Chave', Chave) Then
      facbr.ConsultarDFe(Chave.AsString)
    Else If jDistribuicao.Find('NSU', NSU) Then
    Begin
      If jDistribuicao.Find('CNPJ', CNPJ) Then
        facbr.ConsultarDFe(CNPJ.AsString, NSU.AsInteger)
      Else
        facbr.ConsultarDFe(NSU.AsInteger);
    End
    Else
    Begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Parametros insuficientes para consultar DFe. Informe Chave ou NSU.');
      Exit;
    End;
    
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultarDFe));
  Except
    on E: Exception Do
    Begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro na consulta de distribuicao (DFe): ' + E.Message);
    End;
  End;
End;

Function TACBRBridgeNFSe.Danfse(Const xmlData: TJSONObject): TJSONObject;
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

  stringXml := '';

  If facbr.NotasFiscais.Count = 0 Then
  Begin
    Result.Add(RSErrorField, 'Nenhuma NFS-e carregada a partir do XML.');
    Exit;
  End;

  fdanfse.MostraPreview := False;
  fdanfse.MostraStatus := False;
  fdanfse.MostraSetup := False;

  fileName := ExtractFilePath(ParamStr(0)) + RSPDFDir + PathDelim;
  if not DirectoryExists(fileName) then
    CreateDir(fileName);
  Try
    fdanfse.Cancelada := facbr.NotasFiscais.Items[0].NFSe.NfseCancelamento.DataHora <> 0;
    fdanfse.PathPDF := filename;
    facbr.NotasFiscais.ImprimirPDF;
    filename := fdanfse.ArquivoPDF;
  Except
    Begin
      Result.Add(RSErrorField, RSPDFGenerationError);
      Exit;
    End;
  End;

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

  If facbr.NotasFiscais.Items[0].NFSe.IdentificacaoRps.Numero <> '' Then
    Result.Add(RSChaveField, facbr.NotasFiscais.Items[0].NFSe.IdentificacaoRps.Numero)
  Else
    Result.Add(RSChaveField, facbr.NotasFiscais.Items[0].NFSe.Numero);

  Result.Add(RSTamanhoField, tamanho.ToString);

  If xmlData.Find(RSIDField, id) Then
    Result.Add(RSIDField, id);

  facbr.NotasFiscais.Clear;
End;

Function TACBRBridgeNFSe.NFSeFromXML(Const jXML: TJSONObject): TJSONObject;
Var 
  stringXml: string;
Begin
  CarregaConfig;
  Result := nil;

  Try
    stringXml := ReadXMLFromJSON(jXML);
  Except
    on E: Exception Do
    Begin
      Result := TJSONObject.Create;
      Result.Add(RSErrorField, E.Message);
      Exit;
    End;
  End;

  Try
    facbr.NotasFiscais.LoadFromString(stringXml);
  Except
    on E: Exception Do
    Begin
      Result := TJSONObject.Create;
      Result.Add(RSErrorField, RSXMLReadError + E.Message);
      Exit;
    End;
  End;

  stringXml := '';

  If facbr.NotasFiscais.Count = 0 Then
  Begin
    Result := TJSONObject.Create;
    Result.Add(RSErrorField, 'Nenhuma NFS-e carregada a partir do XML.');
    Exit;
  End;

  Try
    Result := TJSONTools.ObjToJson(facbr.NotasFiscais.Items[0]);
    Result.Delete(RSXMLField);
    Result.Delete(RSXMLOriginalField);
    Result.Delete(RSNomeArqField);
    Result.Delete(RSErroValidacaoCompletoField);
    Result.Delete(RSErroValidacaoField);
    Result.Delete(RSErroRegrasdeNegociosField);
    Result.Delete(RSAlertasField);
  Except
    on E: Exception Do
    Begin
      FreeAndNil(Result);
      Result := TJSONTools.SafeObjToJson(nil, 'Erro ao converter objeto para JSON: ' + E.Message);
    End;
  End;

  facbr.NotasFiscais.Clear;
End;

Function TACBRBridgeNFSe.NFSeToXML(Const jNFSe: TJSONObject): TJSONObject;
Var
  Nota: TNotaFiscal;
  xmlString: string;
  jTargetNode, jPrestNode, jTomNode: TJSONData;
  jTarget: TJSONObject;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  facbr.NotasFiscais.Clear;
  Nota := facbr.NotasFiscais.New;
  Try
    TJSONTools.JsonToObj(jNFSe, Nota);
    jTargetNode := jNFSe.Find('NFSe');
    if not Assigned(jTargetNode) then jTargetNode := jNFSe.Find('nfse');
    if Assigned(jTargetNode) and (jTargetNode.JSONType = jtObject) then
      jTarget := TJSONObject(jTargetNode)
    else
      jTarget := jNFSe;
    TJSONTools.JsonToObj(jTarget, Nota.NFSe);
    jPrestNode := jTarget.Find('Prestador');
    if not Assigned(jPrestNode) then jPrestNode := jTarget.Find('prestador');
    if Assigned(jPrestNode) and (jPrestNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jPrestNode), Nota.NFSe.Prestador.IdentificacaoPrestador);
    jTomNode := jTarget.Find('Tomador');
    if not Assigned(jTomNode) then jTomNode := jTarget.Find('tomador');
    if Assigned(jTomNode) and (jTomNode.JSONType = jtObject) then
      TJSONTools.JsonToObj(TJSONObject(jTomNode), Nota.NFSe.Tomador.IdentificacaoTomador);
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, RSErrorReadingJSON + E.Message);
      facbr.NotasFiscais.Clear;
      Exit;
    End;
  End;

  Try
    xmlString := Nota.GerarXML;
    Result.Add(RSXmlKey, EncodeStringBase64(xmlString));
  Except
    on E: Exception Do
    Begin
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Erro ao gerar XML: ' + E.Message);
    End;
  End;

  facbr.NotasFiscais.Clear;
End;

Function TACBRModelosJSONNFSe.ModelNFSeFromXML: TJSONObject;
Begin
  Result := TJSONObject.Create;
  Result.Add(RSXmlKey, 'XML da NFS-e em Base64 — retorna a NFS-e como JSON');
End;

Function TACBRModelosJSONNFSe.ModelNFSeToXML: TJSONObject;
Begin
  Result := ModelEmitir;
End;

Function TACBRBridgeNFSe.TesteConfig: boolean;
Begin
  Try
    CarregaConfig;
    Result := True;
  Except
    Result := False;
  End;
End;


Function TACBRBridgeNFSe.EnviarEvento(Const jEvento: TJSONObject): TJSONObject;
Var
  Evento: TInfEvento;
  jInfData, jPedData: TJSONData;
  jInf, jPed: TJSONObject;
  tpEventoStr, chNFSe, chSub, xMotivo: string;
  cMotivo, tpAmbVal: Integer;
  ok: Boolean;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  Evento := TInfEvento.Create;
  Try
    Try
      jInf := jEvento;
      jInfData := jEvento.Find('infEvento');
      if not Assigned(jInfData) then
        jInfData := jEvento.Find('InfEvento');
      if Assigned(jInfData) and (jInfData.JSONType = jtObject) then
        jInf := TJSONObject(jInfData);

      jPed := jInf;
      if jInf.Find('pedRegEvento', jPedData) and (jPedData.JSONType = jtObject) then
      begin
        jPed := TJSONObject(jPedData);
        jInf := jPed;
      end
      else if jEvento.Find('pedRegEvento', jPedData) and (jPedData.JSONType = jtObject) then
      begin
        jPed := TJSONObject(jPedData);
        jInf := jPed;
      end;

      TJSONTools.JsonToObj(jEvento, Evento);
      TJSONTools.JsonToObj(jInf, Evento.pedRegEvento);

      chNFSe := jInf.Get('chNFSe', jEvento.Get('chNFSe', ''));
      if chNFSe <> '' then
        Evento.pedRegEvento.chNFSe := chNFSe;

      chSub := jInf.Get('chSubstituta', jEvento.Get('chSubstituta', ''));
      if chSub <> '' then
        Evento.pedRegEvento.chSubstituta := chSub;

      cMotivo := jInf.Get('cMotivo', jEvento.Get('cMotivo', 0));
      if cMotivo > 0 then
        Evento.pedRegEvento.cMotivo := cMotivo;

      tpAmbVal := jInf.Get('tpAmb', jEvento.Get('tpAmb', 0));
      if tpAmbVal > 0 then
        Evento.pedRegEvento.tpAmb := tpAmbVal;

      xMotivo := jInf.Get('xMotivo', jEvento.Get('xMotivo', ''));
      if xMotivo = '' then
        xMotivo := jInf.Get('justificativa', jEvento.Get('justificativa', ''));
      if xMotivo <> '' then
        Evento.pedRegEvento.xMotivo := xMotivo;

      tpEventoStr := jInf.Get('tpEvento', jEvento.Get('tpEvento', ''));

      if tpEventoStr <> '' then
      begin
        Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.StrTotpEvento(ok, tpEventoStr);
        if not ok then
        begin
          if tpEventoStr = 'e101101' then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teCancelamento
          else if tpEventoStr = 'e105102' then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teCancelamentoSubstituicao
          else if tpEventoStr = 'e101103' then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teAnaliseParaCancelamento
          else if tpEventoStr = 'e202201' then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teConfirmacaoPrestador
          else if tpEventoStr = 'e202205' then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teRejeicaoPrestador;
        end;
      end;

      if (Length(Evento.pedRegEvento.chNFSe) >= 50) or (Evento.pedRegEvento.tpEvento <> ACBrNFSeXConversao.teNenhum) then
      begin
        if facbr.Configuracoes.Geral.LayoutNFSe = lnfsProvedor then
          facbr.Configuracoes.Geral.LayoutNFSe := lnfsPadraoNacionalv1;
      end;

      if Evento.pedRegEvento.dhEvento = 0 then
        Evento.pedRegEvento.dhEvento := Now;
      if Evento.pedRegEvento.nPedRegEvento = 0 then
        Evento.pedRegEvento.nPedRegEvento := 1;
      if Evento.pedRegEvento.verAplic = '' then
        Evento.pedRegEvento.verAplic := 'DataLiderERP';
      if Evento.pedRegEvento.tpAmb = 0 then
      begin
        if facbr.Configuracoes.WebServices.Ambiente = taProducao then
          Evento.pedRegEvento.tpAmb := 1
        else
          Evento.pedRegEvento.tpAmb := 2;
      end;

      facbr.EnviarEvento(Evento);
      Result.Free;
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.EnviarEvento));
    Except
      on E: Exception Do
      Begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro ao enviar evento NFSe: ' + E.Message);
      End;
    End;
  Finally
    Evento.Free;
  End;
End;



Function TACBRModelosJSONNFSe.ModelEvento: TJSONObject;
Var
  Evento: TInfEvento;
Begin
  Evento := TInfEvento.Create;
  Try
    Result := TJSONTools.ObjToJson(Evento);
  Finally
    Evento.Free;
  End;
End;


End.
