{%RunFlags MESSAGES+}

Unit method.acbr.nfse;

{$mode Delphi}
{$M+}

Interface

Uses streamtools,
RTTI,
ACBrNFSeX,
ACBrNFSeXWebservicesResponse,
ACBrNFSeXWebserviceBase,
ACBrNFSeXConversao,
ACBrNFSeXDANFSeFPDFClass,
ACBrMail,
ACBrDFeSSL,
ACBrDFeConfiguracoes,
ACBrNFSeXConfiguracoes,
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
Begin
  Result := TJSONObject.Create;
End;

Function TACBRModelosJSONNFSe.ModelConsultarSituacao: TJSONObject;
Begin
  Result := TJSONObject.Create;
End;

Function TACBRModelosJSONNFSe.ModelConsultarLote: TJSONObject;
Begin
  Result := TJSONObject.Create;
End;

Function TACBRModelosJSONNFSe.ModelConsultarNFSePorRps: TJSONObject;
Begin
  Result := TJSONObject.Create;
End;

Function TACBRModelosJSONNFSe.ModelConsultarNFSe: TJSONObject;
Begin
  Result := TJSONObject.Create;
End;

Function TACBRModelosJSONNFSe.ModelCancelar: TJSONObject;
Begin
  Result := TJSONObject.Create;
End;

Function TACBRModelosJSONNFSe.ModelSubstituir: TJSONObject;
Begin
  Result := TJSONObject.Create;
End;


{ TACBRBridgeNFSe }

Procedure TACBRBridgeNFSe.CarregaConfig;
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

Function TACBRBridgeNFSe.ReadXMLFromJSON(Const jsonData: TJSONObject): string;
Var 
  xmlBase64: string;
Begin
  Try
    xmlBase64 := jsonData.Extract('xml').AsString;
  Except
    on E: Exception Do
          Begin
            raise Exception.Create(RSErrorReadingXMLParam + E.Message);
          End;
  End;

  Try
    Result := DecodeStringBase64(xmlBase64);
    xmlBase64 := RSEmptyString;
  Except
    on E: Exception Do
          Begin
            raise Exception.Create(RSInvalidBase64XML + E.Message);
          End;
  End;
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
Begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Lote := 1;
  Try
    TJSONTools.JsonToObj(jNFSe, facbr.NotasFiscais);
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
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.Emite));
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
Begin
  CarregaConfig;
  Result := TJSONObject.Create;
  Lote := 1;
  Try
    TJSONTools.JsonToObj(jNFSe, facbr.NotasFiscais);
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
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.Gerar));
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
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  If jConsulta.Find('Protocolo', Protocolo) and jConsulta.Find('NumLote', NumLote) Then
  Begin
    Try
      facbr.ConsultarSituacao(Protocolo.AsString, NumLote.AsString);
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaSituacao));
    Except
      on E: Exception Do
      Begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na consulta de situacao: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'Protocolo ou NumLote nao informados.');
  End;
End;

Function TACBRBridgeNFSe.ConsultarLote(Const jConsulta: TJSONObject): TJSONObject;
Var
  Protocolo, NumLote: TJSONData;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  If jConsulta.Find('Protocolo', Protocolo) and jConsulta.Find('NumLote', NumLote) Then
  Begin
    Try
      facbr.ConsultarLoteRps(Protocolo.AsString, NumLote.AsString);
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaLoteRps));
    Except
      on E: Exception Do
      Begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na consulta de lote: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'Protocolo ou NumLote nao informados.');
  End;
End;

Function TACBRBridgeNFSe.ConsultarNFSePorRps(Const jConsulta: TJSONObject): TJSONObject;
Var
  NumRps, Serie, Tipo, CodVerificacao: TJSONData;
  vCodVerificacao: string;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  If jConsulta.Find('NumeroRps', NumRps) and jConsulta.Find('Serie', Serie) and jConsulta.Find('Tipo', Tipo) Then
  Begin
    Try
      vCodVerificacao := '';
      If jConsulta.Find('CodVerificacao', CodVerificacao) Then
        vCodVerificacao := CodVerificacao.AsString;

      facbr.ConsultarNFSePorRps(NumRps.AsString, Serie.AsString, Tipo.AsString, vCodVerificacao);
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaNFSeporRps));
    Except
      on E: Exception Do
      Begin
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na consulta por RPS: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'NumeroRps, Serie ou Tipo nao informados.');
  End;
End;

Function TACBRBridgeNFSe.ConsultarNFSe(Const jConsulta: TJSONObject): TJSONObject;
Var
  DataInicial, DataFinal, NumeroNFSe, Pagina, CNPJTomador, IMTomador, NomeIntermediario, 
  CNPJIntermediario, IMIntermediario: TJSONData;
  vDataInicial, vDataFinal: TDateTime;
  vNumeroNFSe: Integer;
  vPagina, vCNPJTomador, vIMTomador, vNomeIntermediario, vCNPJIntermediario, vIMIntermediario: String;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

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
  Result := TJSONObject.Create;

  InfCancelamento := TInfCancelamento.Create;
  Try
    Try
      TJSONTools.JsonToObj(jCancelamento, InfCancelamento);
    Except
      on E: Exception Do
      Begin
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
  CodigoCancelamento, MotivoCancelamento, NumeroNFSe, ChaveNFSe: TJSONData;
Begin
  CarregaConfig;
  Result := TJSONObject.Create;

  // Carrega RPS contida no JSON para SubstituiÃ§Ã£o
  Try
    TJSONTools.JsonToObj(jSubstituir, facbr.NotasFiscais);
  Except
    on E: Exception Do
    Begin
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
        Result.Add(RSStatusField, RSStatusErro);
        Result.Add(RSMessageField, 'Erro na substituicao: ' + E.Message);
      End;
    End;
  End
  Else
  Begin
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
  Result := TJSONObject.Create;
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
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Parametros insuficientes para consultar DFe. Informe Chave ou NSU.');
      Exit;
    End;
    
    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultarDFe));
  Except
    on E: Exception Do
    Begin
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

  stringXml := RSEmptyString;

  fdanfse.MostraPreview := False;
  fdanfse.MostraStatus := False;
  fdanfse.MostraSetup := False;

  fileName := GetTempFileName;
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
    arquivofinal := FileToStringBase64(filename, True, tamanho);
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

End.
