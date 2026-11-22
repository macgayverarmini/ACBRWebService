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
resource.strings.msg,
  IniFiles;

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
      // Consultar Eventos por Chave (Nacional)
      Function ConsultarEventos(Const jConsulta: TJSONObject): TJSONObject;
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
  O, jGeral, jEmit: TJSONObject;
  jNode: TJSONData;
  LPfx: AnsiString;
  vForcarNacional, vPadraoNacional, vNaoAssinarXml, vOk: Boolean;
  vUrlHom, vUrlPro, vVersaoStr, vVersaoNtHom, vVersaoNtPro, vSubversaoSmarApd: string;
  vCodMun: Integer;
  TempIni, IniNT: TMemIniFile;
  sl: TStringList;
  sCodigoMun, sNomeMun, sUFMun, sProvedorMun, LSchemaFile: string;
Begin
  if Trim(fcfg) = '' then
    raise Exception.Create(RSConfigEmptyError);

  vForcarNacional := False;
  vPadraoNacional := False;
  vNaoAssinarXml := False;
  vUrlHom := '';
  vUrlPro := '';
  vVersaoStr := '';
  vVersaoNtHom := '';
  vVersaoNtPro := '';
  vSubversaoSmarApd := '';
  vCodMun := 0;

  // Garante PathSchemas padrão para NFSe antes de SetProvider
  if facbr.Configuracoes.Arquivos.PathSchemas = '' then
    facbr.Configuracoes.Arquivos.PathSchemas := ExtractFilePath(ParamStr(0)) + RSSchemasDir + PathDelim + 'NFSe';

  try
    O := GetJSON(fcfg) as TJSONObject;
    Try
      jGeral := nil;
      jNode := O.Find('Geral');
      if not Assigned(jNode) then jNode := O.Find('geral');
      if Assigned(jNode) and (jNode.JSONType = jtObject) then
        jGeral := TJSONObject(jNode);

      if Assigned(jGeral) then
      begin
        vCodMun := jGeral.Get('CodigoMunicipio', jGeral.Get('codigoMunicipio', 0));
        vVersaoStr := jGeral.Get('Versao', jGeral.Get('versao', ''));
        vForcarNacional := jGeral.Get('ForcarNacional', jGeral.Get('forcarNacional', False));
        vPadraoNacional := jGeral.Get('PadraoNacional', jGeral.Get('padraoNacional', False));
        vNaoAssinarXml := jGeral.Get('NaoAssinarXml', jGeral.Get('naoAssinarXml', False));
        vUrlHom := jGeral.Get('UrlNacionalHom', jGeral.Get('urlNacionalHom', ''));
        vUrlPro := jGeral.Get('UrlNacionalPro', jGeral.Get('urlNacionalPro', ''));
        vVersaoNtHom := jGeral.Get('VersaoNtHom', jGeral.Get('versaoNtHom', ''));
        vVersaoNtPro := jGeral.Get('VersaoNtPro', jGeral.Get('versaoNtPro', ''));
        vSubversaoSmarApd := jGeral.Get('SubversaoSmarApd', jGeral.Get('subversaoSmarApd', ''));
      end;

      vForcarNacional := O.Get('ForcarNacional', O.Get('forcarNacional', vForcarNacional));
      vPadraoNacional := O.Get('PadraoNacional', O.Get('padraoNacional', vPadraoNacional));
      vNaoAssinarXml := O.Get('NaoAssinarXml', O.Get('naoAssinarXml', vNaoAssinarXml));
      if vUrlHom = '' then vUrlHom := O.Get('UrlNacionalHom', O.Get('urlNacionalHom', ''));
      if vUrlPro = '' then vUrlPro := O.Get('UrlNacionalPro', O.Get('urlNacionalPro', ''));
      vUrlHom := Trim(vUrlHom);
      while (vUrlHom <> '') and (vUrlHom[Length(vUrlHom)] = '/') do
        Delete(vUrlHom, Length(vUrlHom), 1);
      vUrlPro := Trim(vUrlPro);
      while (vUrlPro <> '') and (vUrlPro[Length(vUrlPro)] = '/') do
        Delete(vUrlPro, Length(vUrlPro), 1);
      if vVersaoNtHom = '' then vVersaoNtHom := O.Get('VersaoNtHom', O.Get('versaoNtHom', ''));
      if vVersaoNtPro = '' then vVersaoNtPro := O.Get('VersaoNtPro', O.Get('versaoNtPro', ''));
      if vSubversaoSmarApd = '' then vSubversaoSmarApd := O.Get('SubversaoSmarApd', O.Get('subversaoSmarApd', ''));

      TJSONTools.JsonToObj(O, facbr.Configuracoes);

      // Normaliza PathSchemas antes de LerParamsMunicipio e Provider.GetSchemaPath
      if (Trim(facbr.Configuracoes.Arquivos.PathSchemas) = '') or
         SameText(
           ExcludeTrailingPathDelimiter(Trim(facbr.Configuracoes.Arquivos.PathSchemas)),
           ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + RSSchemasDir)
         ) then
        facbr.Configuracoes.Arquivos.PathSchemas :=
          ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + RSSchemasDir) + PathDelim + 'NFSe' + PathDelim;

      if vCodMun = 0 then
        vCodMun := facbr.Configuracoes.Geral.CodigoMunicipio;

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

      // ForcarNacional: sobrescreve INI em memória (ex: E&L API Própria ve101) ANTES de LerParamsMunicipio
      if vForcarNacional and (not vPadraoNacional) and (vCodMun > 0) then
      begin
        if facbr.Configuracoes.WebServices.Params.Count = 0 then
          facbr.LerCidades;

        sCodigoMun := IntToStr(vCodMun);
        TempIni := TMemIniFile.Create('');
        try
          TempIni.SetStrings(facbr.Configuracoes.WebServices.Params);

          sNomeMun := TempIni.ReadString(sCodigoMun, 'Nome', '');
          sUFMun := TempIni.ReadString(sCodigoMun, 'UF', '');
          sProvedorMun := Trim(TempIni.ReadString(sCodigoMun, 'Provedor', ''));
          if sProvedorMun = '' then
            sProvedorMun := 'EL';

          TempIni.EraseSection(sCodigoMun);
          if sNomeMun <> '' then
            TempIni.WriteString(sCodigoMun, 'Nome', sNomeMun);
          if sUFMun <> '' then
            TempIni.WriteString(sCodigoMun, 'UF', sUFMun);
          TempIni.WriteString(sCodigoMun, 'Provedor', sProvedorMun);
          TempIni.WriteString(sCodigoMun, 'Versao', '1.01');
          TempIni.WriteString(sCodigoMun, 'Params', '*|APIPropria:|ServicosAPIPropria:ConsultarNFSeRps,ConsultarNFSePorChave,EnviarEvento,ConsultarEvento');

          TempIni.WriteString(sProvedorMun, 'Versao', '1.01');
          TempIni.WriteString(sProvedorMun, 'Params', 'APIPropria:|ServicosAPIPropria:ConsultarNFSeRps,ConsultarNFSePorChave,EnviarEvento,ConsultarEvento');

          if vUrlHom <> '' then
          begin
            TempIni.WriteString(sCodigoMun, 'HomRecepcionar', vUrlHom);
            TempIni.WriteString(sCodigoMun, 'HomEnviarEvento', vUrlHom);
            TempIni.WriteString(sCodigoMun, 'HomConsultarNFSeRps', vUrlHom);
            TempIni.WriteString(sCodigoMun, 'HomConsultarNFSePorChave', vUrlHom);
            TempIni.WriteString(sCodigoMun, 'HomConsultarEvento', vUrlHom);
          end;
          if vUrlPro <> '' then
          begin
            TempIni.WriteString(sCodigoMun, 'ProRecepcionar', vUrlPro);
            TempIni.WriteString(sCodigoMun, 'ProEnviarEvento', vUrlPro);
            TempIni.WriteString(sCodigoMun, 'ProConsultarNFSeRps', vUrlPro);
            TempIni.WriteString(sCodigoMun, 'ProConsultarNFSePorChave', vUrlPro);
            TempIni.WriteString(sCodigoMun, 'ProConsultarEvento', vUrlPro);
          end;

          sl := TStringList.Create;
          try
            TempIni.GetStrings(sl);
            facbr.Configuracoes.WebServices.Params := sl;
          finally
            sl.Free;
          end;
        finally
          TempIni.Free;
        end;
      end;

      if vForcarNacional then
        facbr.Configuracoes.Geral.LayoutNFSe := lnfsProvedor
      else if vPadraoNacional then
        facbr.Configuracoes.Geral.LayoutNFSe := lnfsPadraoNacionalv101
      else
        facbr.Configuracoes.Geral.LayoutNFSe := lnfsProvedor;

      if vCodMun > 0 then
      begin
        facbr.Configuracoes.Geral.CodigoMunicipio := vCodMun;
        facbr.Configuracoes.Geral.LerParamsMunicipio;
      end;

      if not vPadraoNacional then
      begin
        if vForcarNacional and ((vVersaoStr = '') or (vVersaoStr = '2.04') or (vVersaoStr = '2.00') or SameText(vVersaoStr, 've204') or SameText(vVersaoStr, 've200')) then
          vVersaoStr := '1.01';

        if vVersaoStr <> '' then
        begin
          facbr.Configuracoes.Geral.Versao := StrToVersaoNFSe(vOk, vVersaoStr);
          if not vOk then
          begin
            if (SameText(vVersaoStr, 've100')) or (vVersaoStr = '1.00') then
              facbr.Configuracoes.Geral.Versao := ve100
            else if (SameText(vVersaoStr, 've101')) or (vVersaoStr = '1.01') then
              facbr.Configuracoes.Geral.Versao := ve101
            else if (SameText(vVersaoStr, 've200')) or (vVersaoStr = '2.00') then
              facbr.Configuracoes.Geral.Versao := ve200
            else if (SameText(vVersaoStr, 've201')) or (vVersaoStr = '2.01') then
              facbr.Configuracoes.Geral.Versao := ve201
            else if (SameText(vVersaoStr, 've202')) or (vVersaoStr = '2.02') then
              facbr.Configuracoes.Geral.Versao := ve202
            else if (SameText(vVersaoStr, 've203')) or (vVersaoStr = '2.03') then
              facbr.Configuracoes.Geral.Versao := ve203
            else if (SameText(vVersaoStr, 've204')) or (vVersaoStr = '2.04') then
              facbr.Configuracoes.Geral.Versao := ve204;
          end;
        end;
      end;

      // Reaplica Emitente caso LerParamsMunicipio tenha alterado configurações
      if Assigned(jGeral) then
      begin
        jNode := jGeral.Find('Emitente');
        if not Assigned(jNode) then jNode := jGeral.Find('emitente');
        if Assigned(jNode) and (jNode.JSONType = jtObject) then
        begin
          jEmit := TJSONObject(jNode);
          TJSONTools.JsonToObj(jEmit, facbr.Configuracoes.Geral.Emitente);
        end;
      end;

      if (facbr.Configuracoes.Geral.Provedor = proEL) and (facbr.Configuracoes.Geral.Versao = ve100) and (not vForcarNacional) and (not vPadraoNacional) then
        facbr.Configuracoes.Geral.ConsultaLoteAposEnvio := True
      else
        facbr.Configuracoes.Geral.ConsultaLoteAposEnvio := False;

      if Assigned(facbr.Provider) then
      begin
        if vPadraoNacional or vForcarNacional or (facbr.Configuracoes.Geral.Provedor = proPadraoNacional) or facbr.Configuracoes.Geral.APIPropria then
        begin
          IniNT := TMemIniFile.Create('');
          try
            IniNT.SetStrings(facbr.Configuracoes.WebServices.Params);
            if vVersaoNtPro <> '' then
            begin
              if vVersaoNtPro = '1' then vVersaoNtPro := '009.1.01';
              IniNT.WriteString('OverrideNT', 'ProVersaoNT', vVersaoNtPro);
              facbr.Provider.ConfigWebServices.LoadVersaoNTProducao(IniNT, 'OverrideNT');
            end
            else if facbr.Provider.ConfigWebServices.Producao.VersaoNT = '' then
              facbr.Provider.ConfigWebServices.LoadVersaoNTProducao(IniNT, 'PadraoNacional');

            if vVersaoNtHom <> '' then
            begin
              if vVersaoNtHom = '1' then vVersaoNtHom := '009.1.01';
              IniNT.WriteString('OverrideNT', 'HomVersaoNT', vVersaoNtHom);
              facbr.Provider.ConfigWebServices.LoadVersaoNTHomologacao(IniNT, 'OverrideNT');
            end
            else if facbr.Provider.ConfigWebServices.Homologacao.VersaoNT = '' then
              facbr.Provider.ConfigWebServices.LoadVersaoNTHomologacao(IniNT, 'PadraoNacional');
          finally
            IniNT.Free;
          end;

          LSchemaFile := IncludeTrailingPathDelimiter(facbr.Provider.GetSchemaPath) + facbr.Provider.ConfigSchemas.GerarNFSe;
          if not FileExists(LSchemaFile) then
            facbr.Provider.ConfigSchemas.Validar := False;
        end;

        if vNaoAssinarXml then
        begin
          with facbr.Provider.ConfigAssinar do
          begin
            Rps := False;
            LoteRps := False;
            ConsultarSituacao := False;
            ConsultarLote := False;
            ConsultarNFSeRps := False;
            ConsultarNFSe := False;
            ConsultarNFSePorChave := False;
            ConsultarNFSePorFaixa := False;
            ConsultarNFSeServicoPrestado := False;
            ConsultarNFSeServicoTomado := False;
            ConsultarLinkNFSe := False;
            CancelarNFSe := False;
            RpsGerarNFSe := False;
            LoteGerarNFSe := False;
            RpsSubstituirNFSe := False;
            SubstituirNFSe := False;
            AbrirSessao := False;
            FecharSessao := False;
            GerarToken := False;
            EnviarEvento := False;
            ConsultarEvento := False;
            ConsultarDFe := False;
            ConsultarParam := False;
            ConsultarSeqRps := False;
            IncluirURI := False;
            AssinaturaAdicional := False;
          end;
          facbr.Configuracoes.Geral.Assinaturas := taNaoAssinar;
          facbr.Configuracoes.Geral.Autenticacao.RequerCertificado := False;
          facbr.Configuracoes.Geral.Autenticacao.RequerLogin := True;
          facbr.Configuracoes.Geral.Autenticacao.RequerChaveAcesso := False;
          facbr.Configuracoes.Geral.Autenticacao.RequerChaveAutorizacao := False;
          facbr.Configuracoes.Geral.Autenticacao.RequerFraseSecreta := False;
        end;

        if (facbr.Configuracoes.Geral.Provedor = proSmarAPD) and ((vSubversaoSmarApd = '1') or SameText(vSubversaoSmarApd, 'true')) then
        begin
          if Pos('SubVersao=1', facbr.Provider.ConfigGeral.Params.AsString) = 0 then
            facbr.Provider.ConfigGeral.Params.AsString := facbr.Provider.ConfigGeral.Params.AsString + '|SubVersao=1:';
          if facbr.Configuracoes.Geral.Versao = ve204 then
            facbr.Provider.ConfigAssinar.Rps := False;
        end;
      end;
    Finally
      O.Free;
    End;
  except
    on E: Exception do
      raise Exception.Create(RSConfigReadError + E.Message);
  end;

  // Garante PathSchemas padrao para NFSe quando vazio ou apontando para a raiz Schemas\
  if (Trim(facbr.Configuracoes.Arquivos.PathSchemas) = '') or
     SameText(
       ExcludeTrailingPathDelimiter(Trim(facbr.Configuracoes.Arquivos.PathSchemas)),
       ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + RSSchemasDir)
     ) then
    facbr.Configuracoes.Arquivos.PathSchemas :=
      ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + RSSchemasDir) + PathDelim + 'NFSe' + PathDelim;

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
      if (facbr.NotasFiscais.Count > 0) and (facbr.NotasFiscais.Items[0].XmlNfse <> '') then
        Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XmlNfse));
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
      if (facbr.NotasFiscais.Count > 0) and (facbr.NotasFiscais.Items[0].XmlNfse <> '') then
        Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XmlNfse));
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
  DataInicial, DataFinal, Pagina, ChaveNFSe, NumeroNFSe, IdDPS: TJSONData;
  vDataInicial, vDataFinal: TDateTime;
  vPagina, vChaveNFSe, vNumeroNFSe, vIdDPS: String;
Begin
  CarregaConfig;
  Result := nil;

  vDataInicial := 0;
  vDataFinal := 0;
  vPagina := '1';
  vChaveNFSe := '';
  vNumeroNFSe := '';
  vIdDPS := '';

  If jConsulta.Find('DataInicial', DataInicial) Then vDataInicial := StrToDateDef(DataInicial.AsString, 0)
  Else If jConsulta.Find('dataInicial', DataInicial) Then vDataInicial := StrToDateDef(DataInicial.AsString, 0);

  If jConsulta.Find('DataFinal', DataFinal) Then vDataFinal := StrToDateDef(DataFinal.AsString, 0)
  Else If jConsulta.Find('dataFinal', DataFinal) Then vDataFinal := StrToDateDef(DataFinal.AsString, 0);

  If jConsulta.Find('Pagina', Pagina) Then vPagina := Pagina.AsString
  Else If jConsulta.Find('pagina', Pagina) Then vPagina := Pagina.AsString;

  If jConsulta.Find('ChaveNFSe', ChaveNFSe) Then vChaveNFSe := Trim(ChaveNFSe.AsString)
  Else If jConsulta.Find('chaveNfse', ChaveNFSe) Then vChaveNFSe := Trim(ChaveNFSe.AsString)
  Else If jConsulta.Find('chave', ChaveNFSe) Then vChaveNFSe := Trim(ChaveNFSe.AsString);

  If jConsulta.Find('NumeroNFSe', NumeroNFSe) Then vNumeroNFSe := Trim(NumeroNFSe.AsString)
  Else If jConsulta.Find('numeroNfse', NumeroNFSe) Then vNumeroNFSe := Trim(NumeroNFSe.AsString)
  Else If jConsulta.Find('numero', NumeroNFSe) Then vNumeroNFSe := Trim(NumeroNFSe.AsString);

  If jConsulta.Find('IdDPS', IdDPS) Then vIdDPS := Trim(IdDPS.AsString)
  Else If jConsulta.Find('idDps', IdDPS) Then vIdDPS := Trim(IdDPS.AsString)
  Else If jConsulta.Find('idDPS', IdDPS) Then vIdDPS := Trim(IdDPS.AsString);

  Try
    facbr.NotasFiscais.Clear;
    if vIdDPS <> '' then
      facbr.ConsultarDPSPorChave(vIdDPS)
    else if vChaveNFSe <> '' then
      facbr.ConsultarNFSePorChave(vChaveNFSe)
    else if vNumeroNFSe <> '' then
      facbr.ConsultarNFSePorNumero(vNumeroNFSe, StrToIntDef(vPagina, 1))
    else
      facbr.ConsultarNFSePorPeriodo(vDataInicial, vDataFinal, StrToIntDef(vPagina, 1));

    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultaNFSe));
    if (facbr.NotasFiscais.Count > 0) and (facbr.NotasFiscais.Items[0].XmlNfse <> '') then
      Result.Add('xml_autorizado', EncodeStringBase64(facbr.NotasFiscais.Items[0].XmlNfse));
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
  LNSU: Int64;
  LNSUInt: Integer;
  LSchemaFile: string;
Begin
  CarregaConfig;
  Result := nil;

  if facbr.Configuracoes.Geral.Provedor <> proPadraoNacional then
  begin
    facbr.Configuracoes.Geral.LayoutNFSe := lnfsPadraoNacionalv101;
    facbr.SetProvedor(proPadraoNacional, ve101, False);
    if Assigned(facbr.Provider) then
    begin
      LSchemaFile := IncludeTrailingPathDelimiter(facbr.Provider.GetSchemaPath) + facbr.Provider.ConfigSchemas.GerarNFSe;
      if not FileExists(LSchemaFile) then
        facbr.Provider.ConfigSchemas.Validar := False;
    end;
  end;

  Try
    If jDistribuicao.Find('Chave', Chave) and (Trim(Chave.AsString) <> '') Then
      facbr.ConsultarDFe(Trim(Chave.AsString))
    Else If jDistribuicao.Find('NSU', NSU) Then
    Begin
      LNSU := StrToInt64Def(Trim(NSU.AsString), 0);
      if LNSU > High(Integer) then
        LNSUInt := High(Integer)
      else if LNSU < 0 then
        LNSUInt := 0
      else
        LNSUInt := Integer(LNSU);

      If jDistribuicao.Find('CNPJ', CNPJ) and (Trim(CNPJ.AsString) <> '') Then
        facbr.ConsultarDFe(Trim(CNPJ.AsString), LNSUInt)
      Else
        facbr.ConsultarDFe(LNSUInt);
    End
    Else
    Begin
      Result := TJSONObject.Create;
      Result.Add(RSStatusField, RSStatusErro);
      Result.Add(RSMessageField, 'Parametros insuficientes para consultar DFe. Informe Chave ou NSU.');
      Exit;
    End;

    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultarDFe));
    if Assigned(Result) then
    begin
      if Result.Find('ArquivoRetorno') = nil then
        Result.Add('ArquivoRetorno', facbr.WebService.ConsultarDFe.ArquivoRetorno);
      if Result.Find('XmlRetorno') = nil then
        Result.Add('XmlRetorno', facbr.WebService.ConsultarDFe.XmlRetorno);
    end;
  Except
    on E: Exception Do
    Begin
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultarDFe));
      if not Assigned(Result) then
        Result := TJSONObject.Create;
      if Result.Find(RSStatusField) = nil then
        Result.Add(RSStatusField, RSStatusErro);
      if Result.Find(RSMessageField) = nil then
        Result.Add(RSMessageField, 'Erro na consulta de distribuicao (DFe): ' + E.Message);
      if Result.Find('ArquivoRetorno') = nil then
        Result.Add('ArquivoRetorno', facbr.WebService.ConsultarDFe.ArquivoRetorno);
      if Result.Find('XmlRetorno') = nil then
        Result.Add('XmlRetorno', facbr.WebService.ConsultarDFe.XmlRetorno);
    End;
  End;
End;

Function TACBRBridgeNFSe.ConsultarEventos(Const jConsulta: TJSONObject): TJSONObject;
Var
  ChaveNode, TipoEvNode, SeqNode: TJSONData;
  LChave, LTipoEvStr, LSchemaFile: string;
  LTpEv: TtpEvento;
  LNSeq: Integer;
  ok: Boolean;
  LResArr: TJSONArray;
  LResObj: TJSONObject;
  I: Integer;
Begin
  CarregaConfig;
  Result := nil;

  if facbr.Configuracoes.Geral.Provedor <> proPadraoNacional then
  begin
    facbr.Configuracoes.Geral.LayoutNFSe := lnfsPadraoNacionalv101;
    facbr.SetProvedor(proPadraoNacional, ve101, False);
    if Assigned(facbr.Provider) then
    begin
      LSchemaFile := IncludeTrailingPathDelimiter(facbr.Provider.GetSchemaPath) + facbr.Provider.ConfigSchemas.GerarNFSe;
      if not FileExists(LSchemaFile) then
        facbr.Provider.ConfigSchemas.Validar := False;
    end;
  end;

  LChave := '';
  If jConsulta.Find('Chave', ChaveNode) and (Trim(ChaveNode.AsString) <> '') Then
    LChave := Trim(ChaveNode.AsString)
  Else If jConsulta.Find('ChaveNFSe', ChaveNode) and (Trim(ChaveNode.AsString) <> '') Then
    LChave := Trim(ChaveNode.AsString)
  Else If jConsulta.Find('chNFSe', ChaveNode) and (Trim(ChaveNode.AsString) <> '') Then
    LChave := Trim(ChaveNode.AsString)
  Else If jConsulta.Find('chave', ChaveNode) and (Trim(ChaveNode.AsString) <> '') Then
    LChave := Trim(ChaveNode.AsString);

  if (Length(LChave) >= 47) and SameText(Copy(LChave, 1, 3), 'NFS') then
    LChave := Trim(Copy(LChave, 4, MaxInt));

  if LChave = '' then
  begin
    Result := TJSONObject.Create;
    Result.Add(RSStatusField, RSStatusErro);
    Result.Add(RSMessageField, 'Parametro Chave obrigatorio para consultar eventos da NFS-e.');
    Exit;
  end;

  LTipoEvStr := '';
  if jConsulta.Find('TipoEvento', TipoEvNode) then
    LTipoEvStr := Trim(TipoEvNode.AsString)
  else if jConsulta.Find('tpEvento', TipoEvNode) then
    LTipoEvStr := Trim(TipoEvNode.AsString);

  LNSeq := 0;
  if jConsulta.Find('nSeqEvento', SeqNode) then
    LNSeq := StrToIntDef(Trim(SeqNode.AsString), 0);

  Try
    if LTipoEvStr <> '' then
    begin
      LTpEv := ACBrNFSeXConversao.StrTotpEvento(ok, LTipoEvStr);
      if ok and (LTpEv <> teNenhum) then
      begin
        if LNSeq > 0 then
          facbr.ConsultarEvento(LChave, LTpEv, LNSeq)
        else
          facbr.ConsultarEvento(LChave, LTpEv);
      end
      else
        facbr.ConsultarEvento(LChave);
    end
    else
      facbr.ConsultarEvento(LChave);

    Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultarEvento));
    if not Assigned(Result) then
      Result := TJSONObject.Create;
    if Result.Find('ArquivoRetorno') = nil then
      Result.Add('ArquivoRetorno', facbr.WebService.ConsultarEvento.ArquivoRetorno);
    if Result.Find('XmlRetorno') = nil then
      Result.Add('XmlRetorno', facbr.WebService.ConsultarEvento.XmlRetorno);
    if Assigned(facbr.WebService.ConsultarEvento.Resumos) and
       (facbr.WebService.ConsultarEvento.Resumos.Count > 0) and
       (Result.Find('Resumos') = nil) then
    begin
      LResArr := TJSONArray.Create;
      for I := 0 to facbr.WebService.ConsultarEvento.Resumos.Count - 1 do
      begin
        if Assigned(facbr.WebService.ConsultarEvento.Resumos[I]) then
        begin
          LResObj := TJSONObject.Create;
          LResObj.Add('ChaveDFe', facbr.WebService.ConsultarEvento.Resumos[I].ChaveDFe);
          LResObj.Add('idNota', facbr.WebService.ConsultarEvento.Resumos[I].idNota);
          LResObj.Add('TipoEvento', facbr.WebService.ConsultarEvento.Resumos[I].TipoEvento);
          LResObj.Add('XmlRetorno', facbr.WebService.ConsultarEvento.Resumos[I].XmlRetorno);
          LResArr.Add(LResObj);
        end;
      end;
      Result.Add('Resumos', LResArr);
    end;
  Except
    on E: Exception Do
    Begin
      Result := TJSONObject(TJSONTools.ObjToJson(facbr.WebService.ConsultarEvento));
      if not Assigned(Result) then
        Result := TJSONObject.Create;
      if Result.Find(RSStatusField) = nil then
        Result.Add(RSStatusField, RSStatusErro);
      if Result.Find(RSMessageField) = nil then
        Result.Add(RSMessageField, 'Erro ao consultar eventos da NFS-e: ' + E.Message);
      if Result.Find('ArquivoRetorno') = nil then
        Result.Add('ArquivoRetorno', facbr.WebService.ConsultarEvento.ArquivoRetorno);
      if Result.Find('XmlRetorno') = nil then
        Result.Add('XmlRetorno', facbr.WebService.ConsultarEvento.XmlRetorno);
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
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teRejeicaoPrestador
          else if SameText(tpEventoStr, 'e203202') or SameText(tpEventoStr, '203202') or SameText(tpEventoStr, 'teConfirmacaoTomador') then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teConfirmacaoTomador
          else if SameText(tpEventoStr, 'e203206') or SameText(tpEventoStr, '203206') or SameText(tpEventoStr, 'teRejeicaoTomador') then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teRejeicaoTomador
          else if SameText(tpEventoStr, 'e205208') or SameText(tpEventoStr, '205208') or SameText(tpEventoStr, 'teAnulacaoRejeicao') then
            Evento.pedRegEvento.tpEvento := ACBrNFSeXConversao.teAnulacaoRejeicao;
        end;
      end;

      if Evento.pedRegEvento.tpEvento in [
        ACBrNFSeXConversao.teConfirmacaoTomador,
        ACBrNFSeXConversao.teRejeicaoTomador,
        ACBrNFSeXConversao.teConfirmacaoIntermediario,
        ACBrNFSeXConversao.teRejeicaoIntermediario,
        ACBrNFSeXConversao.teAnulacaoRejeicao
      ] then
      begin
        if facbr.Configuracoes.Geral.Provedor <> proPadraoNacional then
        begin
          facbr.Configuracoes.Geral.LayoutNFSe := lnfsPadraoNacionalv101;
          facbr.SetProvedor(proPadraoNacional, ve101, False);
          if Assigned(facbr.Provider) and (not FileExists(IncludeTrailingPathDelimiter(facbr.Provider.GetSchemaPath) + facbr.Provider.ConfigSchemas.GerarNFSe)) then
            facbr.Provider.ConfigSchemas.Validar := False;
        end;
      end
      else if (Length(Evento.pedRegEvento.chNFSe) >= 50) or (Evento.pedRegEvento.tpEvento <> ACBrNFSeXConversao.teNenhum) then
      begin
        if (facbr.Configuracoes.Geral.LayoutNFSe = lnfsProvedor) and (not facbr.Configuracoes.Geral.APIPropria) and (facbr.Configuracoes.Geral.Provedor <> proEL) then
        begin
          facbr.Configuracoes.Geral.LayoutNFSe := lnfsPadraoNacionalv101;
          facbr.Configuracoes.Geral.LerParamsMunicipio;
        end;
      end;

      if Evento.pedRegEvento.dhEvento = 0 then
        Evento.pedRegEvento.dhEvento := Now;
      if Evento.pedRegEvento.nPedRegEvento = 0 then
        Evento.pedRegEvento.nPedRegEvento := 1;
      if Evento.pedRegEvento.verAplic = '' then
        Evento.pedRegEvento.verAplic := 'ACBRWebService';
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
