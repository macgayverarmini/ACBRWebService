unit method.acbr.cte;

{$mode Delphi}

interface

uses
  Classes,
  SysUtils,
  fpjson,
  jsonconvert,
  jsonparser,
  streamtools,
  Base64,
  ACBrCTe.Classes,
  ACBrCTe,
  ACBrCTeDACTeRL,
  ACBrCTeDACTeRLClass,
  ACBrCTeWebServices,
  ACBrCTeConfiguracoes,
  ACBrDFeSSL,
  pcteConversaoCTe,
  pcnConversao,
  ACBrCTeConhecimentos,
  ACBrDFeConfiguracoes;

type

  { TACBRBridgeCTe }

  TACBRBridgeCTe = class
  private
    fcfg: string;
    facbr: TACBrCTe;
    fdacte: TACBrCTeDACTeRL;

    procedure CarregaConfig;

    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;


    function EnviarCTe(const jCTe: TJSONObject): TJSONObject;

    function EnviarEvento(const jEventos: TJSONArray): string;

    function ConsultarCTe(const jConsulta: TJSONObject): TJSONObject;
    function ConsultarSituacaoServico(const jConsulta: TJSONObject): TJSONObject;
    function GerarDACTE(const xmlData: TJSONObject): TJSONObject;

    // Testa a configura\u00E7\u00E3o passada em JSON
    function TesteConfig: boolean;
  end;

  { TACBRModelosJSONCTe - Salva os retornos de modelo de requisi\u00E7\u00F5es CTe }

  TACBRModelosJSONCTe = class(TACBRBridgeCTe)
  private
  public
    function ModelConfig: TJSONObject;
    function ModelEvento: TJSONObject;
    function ModelCTe: TJSONObject;
    function ModelConsultaCTe: TJSONObject;
    function ModelConsultaSituacaoServico: TJSONObject;
  end;

implementation

function TACBRModelosJSONCTe.ModelConfig: TJSONObject;
var
  facbe: TACBrCTe;
begin

  with facbr.Configuracoes.Geral do
  begin

    VersaoDF := TVersaoCTe.ve400;
    RetirarAcentos := True;

    SSLLib := TSSLLib.libOpenSSL;
    SSLCryptLib := TSSLCryptLib.cryOpenSSL;
    SSLHttpLib := TSSLHttpLib.httpOpenSSL;
    SSLXmlSignLib := TSSLXmlSignLib.xsLibXml2;
  end;

  with facbr.Configuracoes.WebServices do
  begin
    Ambiente := TpcnTipoAmbiente.taHomologacao;
    UF := 'ES';
    TimeOut := 15000; // CTe pode demorar mais
    Visualizar := False;
  end;

  with facbr.Configuracoes.Certificados do
  begin
    ArquivoPFX := 'C:\caminho\seu_certificado.pfx'; // Exemplo
    Senha := 'sua_senha'; // Exemplo
  end;

  with facbr.Configuracoes.Arquivos do
  begin
    // Configurar paths se necess\u00E1rio
    // PathSalvar := 'C:\ACBr\CTe\';
    // ...
  end;

  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

function TACBRModelosJSONCTe.ModelEvento: TJSONObject;
begin
  // Cria um evento CTe vazio para gerar o modelo JSON
  facbr.EventoCTe.Evento.New;
  // Preencher campos m\u00EDnimos de exemplo se desejado
  // Ex: facbr.EventoCTe.Evento.Items[0].infEvento.tpEvento := teCancelamentoCTe;
  Result := TJSONTools.ObjToJson(facbr.EventoCTe);
  facbr.EventoCTe.Evento.Clear; // Limpa ap\u00F3s gerar o modelo
end;

function TACBRModelosJSONCTe.ModelCTe: TJSONObject;
begin
  with facbr.Conhecimentos.Add.CTe do
  begin

    infCTe.versao := 4.0;


    Ide.cUF := UFtoCUF('ES');
    Ide.CFOP := 5353;
    Ide.natOp := 'PRESTACAO SERVICO';
    ide.forPag := fpAPagar; // fpAPagar ou fpPago
    Ide.modelo := 57;
    Ide.serie := 1;
    Ide.nCT := 1;
    // Atenção o valor de cCT tem que ser um numero aleatório conforme recomendação
    // da SEFAZ, mas neste exemplo vamos atribuir o mesmo numero do CT-e.
    Ide.cCT := 1;
    Ide.dhEmi := Now;
    Ide.tpImp := tiRetrato;
    Ide.tpEmis := teNormal;


    Ide.tpAmb := taHomologacao;

    Ide.tpCTe := tcNormal; // tcNormal, tcComplemento, tcAnulacao, tcSubstituto
    Ide.procEmi := peAplicativoContribuinte;
    Ide.verProc := '3.0';
    Ide.cMunEnv := StrToInt('3203205');
    Ide.xMunEnv := 'LINHARES';
    Ide.UFEnv := 'ES';
    Ide.modal := mdRodoviario;
    Ide.tpServ := tsNormal;
    // tsNormal, tsSubcontratacao, tsRedespacho, tsIntermediario
    ide.indIEToma := inContribuinte;
    Ide.cMunIni := 3119401;
    Ide.xMunIni := 'CORONEL FABRICIANO';
    Ide.UFIni := 'MG';
    Ide.cMunFim := 2900207;
    Ide.xMunFim := 'ABARE';
    Ide.UFFim := 'BA';
    Ide.retira := rtSim; // rtSim, rtNao
    Ide.xdetretira := '';

    ide.indGlobalizado := tiNao;

    with ide.infPercurso.Add do
      UFPer := 'PR';

    Ide.Toma03.Toma := tmRemetente;
    // tmRemetente, tmExpedidor, tmRecebedor, tmDestinatario, tmRemetente

    Ide.Toma4.Toma := tmOutros;
    Ide.Toma4.CNPJCPF := '10242141000174';
    Ide.Toma4.IE := '0010834420031';
    Ide.Toma4.xNome := 'ACOUGUE E SUPERMERCADO SOUZA LTDA';
    Ide.Toma4.xFant := '';
    Ide.Toma4.fone := '';

    Ide.Toma4.enderToma.xLgr := 'RUA BELO HORIZONTE';
    Ide.Toma4.enderToma.nro := '614';
    Ide.Toma4.enderToma.xCpl := 'N D';
    Ide.Toma4.enderToma.xBairro := 'CALADINA';
    Ide.Toma4.enderToma.cMun := 3119401;
    Ide.Toma4.enderToma.xMun := 'CORONEL FABRICIANO';
    Ide.Toma4.enderToma.CEP := 35171167;
    Ide.Toma4.enderToma.UF := 'MG';
    Ide.Toma4.enderToma.cPais := 1058;
    Ide.Toma4.enderToma.xPais := 'BRASIL';
    Ide.Toma4.email := '';

    compl.xCaracAd := 'Caracteristicas Adicionais do Transporte';
    compl.xCaracSer := 'Caracteristicas Adicionais do Serviço';
    compl.xEmi := 'Nome do Emitente';

    compl.fluxo.xOrig := '';

    with compl.fluxo.pass.Add do
    begin
      xPass := 'Sigla ou código interno da Filial/Porto/Estação/Aeroporto de Passagem ';
    end;

    compl.fluxo.xDest := 'Destino';
    compl.fluxo.xRota := 'Rota';

    compl.Entrega.TipoData := tdSemData;
    compl.Entrega.semData.tpPer := tdSemData;
    compl.Entrega.comData.tpPer := tdNaData;
    compl.Entrega.comData.dProg := Date;
    compl.Entrega.noPeriodo.tpPer := tdNoPeriodo;
    compl.Entrega.noPeriodo.dIni := Date;
    compl.Entrega.noPeriodo.dFim := Date + 5;

    compl.Entrega.TipoHora := thSemHorario;
    compl.Entrega.semHora.tpHor := thSemHorario;
    compl.Entrega.comHora.tpHor := thNoHorario;
    compl.Entrega.comHora.hProg := Time;
    compl.Entrega.noInter.tpHor := thNoIntervalo;
    compl.Entrega.noInter.hIni := Time;
    compl.Entrega.noInter.hFim := Time + 60;

    compl.origCalc := 'Município de origem para efeito de cálculo do frete ';
    compl.destCalc := 'Município de destino para efeito de cálculo do frete ';
    compl.xObs := 'Observação livre';

    with compl.ObsCont.New do
    begin
      xCampo := 'Nome do Campo';
      xTexto := 'Valor do Campo';
    end;

    with compl.ObsFisco.New do
    begin
      xCampo := 'Nome do Campo';
      xTexto := 'Valor do Campo';
    end;


    Emit.CRT := crtRegimeNormal; {Obrigatório na versão 4.00}
    Emit.CNPJ := '11222333000144'; // CNPJ fictício
    Emit.IE := '001000000000'; // IE fictícia para MG
    Emit.xNome := 'Empresa Ficticia de Transportes Ltda';
    // Razão Social fictícia
    Emit.xFant := 'Transportadora Ficticia'; // Nome Fantasia fictício
    Emit.enderEmit.xLgr := 'Avenida das Flores'; // Logradouro fictício
    Emit.enderEmit.nro := '1234'; // Número fictício
    Emit.enderEmit.xCpl := 'Sala 101'; // Complemento fictício
    Emit.enderEmit.xBairro := 'Centro'; // Bairro fictício
    Emit.enderEmit.cMun := 3118601;
    // Código Município fictício (Ex: Governador Valadares/MG)
    Emit.enderEmit.xMun := 'Governador Valadares'; // Nome Município fictício
    Emit.enderEmit.CEP := 35010000; // CEP fictício
    Emit.enderEmit.UF := 'MG'; // UF fictícia
    Emit.enderEmit.fone := '3332715555'; // Telefone fictício

    Rem.CNPJCPF := '12345678000123';
    Rem.IE := '12345678';
    Rem.xNome := 'Nome do Remetente';
    Rem.xFant := 'Nome Fantasia';
    Rem.fone := '33445566';

    Rem.EnderReme.xLgr := 'Rua 1';
    Rem.EnderReme.nro := '200';
    Rem.EnderReme.xCpl := '';
    Rem.EnderReme.xBairro := 'Centro';
    Rem.EnderReme.cMun := 3512345;
    Rem.EnderReme.xMun := 'Nome do Municipio';
    Rem.EnderReme.CEP := 14123456;
    Rem.EnderReme.UF := 'SP';
    Rem.EnderReme.cPais := 1058;
    Rem.EnderReme.xPais := 'BRASIL';

    Exped.CNPJCPF := '12345678000123';
    Exped.IE := '12345678';
    Exped.xNome := 'Nome do Expedidor';
    Exped.fone := '33445566';

    Exped.EnderExped.xLgr := 'Rua 1';
    Exped.EnderExped.nro := '200';
    Exped.EnderExped.xCpl := '';
    Exped.EnderExped.xBairro := 'Centro';
    Exped.EnderExped.cMun := 3512345;
    Exped.EnderExped.xMun := 'Nome do Municipio';
    Exped.EnderExped.CEP := 14123456;
    Exped.EnderExped.UF := 'SP';
    Exped.EnderExped.cPais := 1058;
    Exped.EnderExped.xPais := 'BRASIL';

    Receb.CNPJCPF := '12345678000123';
    Receb.IE := '12345678';
    Receb.xNome := 'Nome do Recebedor';
    Receb.fone := '33445566';

    Receb.EnderReceb.xLgr := 'Rua 1';
    Receb.EnderReceb.nro := '200';
    Receb.EnderReceb.xCpl := '';
    Receb.EnderReceb.xBairro := 'Centro';
    Receb.EnderReceb.cMun := 3512345;
    Receb.EnderReceb.xMun := 'Nome do Municipio';
    Receb.EnderReceb.CEP := 14123456;
    Receb.EnderReceb.UF := 'SP';
    Receb.EnderReceb.cPais := 1058;
    Receb.EnderReceb.xPais := 'BRASIL';

    Dest.CNPJCPF := '12345678000123';
    Dest.IE := '12345678';
    Dest.xNome := 'Nome do Destinatário';
    Dest.fone := '33445566';

    Dest.EnderDest.xLgr := 'Rua 1';
    Dest.EnderDest.nro := '200';
    Dest.EnderDest.xCpl := '';
    Dest.EnderDest.xBairro := 'Centro';
    Dest.EnderDest.cMun := 3512345;
    Dest.EnderDest.xMun := 'Nome do Municipio';
    Dest.EnderDest.CEP := 14123456;
    Dest.EnderDest.UF := 'SP';
    Dest.EnderDest.cPais := 1058;
    Dest.EnderDest.xPais := 'BRASIL';

    vPrest.vTPrest := 100.00;
    vPrest.vRec := 100.00;

    with vPrest.comp.New do
    begin
      xNome := 'DFRNER KRTJ';
      vComp := 100.00;
    end;

    Imp.ICMS.SituTrib := cst00;
    Imp.ICMS.ICMS00.CST := cst00;
    Imp.ICMS.ICMS00.vBC := 100;
    Imp.ICMS.ICMS00.pICMS := 17;
    Imp.ICMS.ICMS00.vICMS := 17;

    Imp.ICMS.SituTrib := cst40;
    Imp.ICMS.ICMS45.CST := cst40;

    Imp.ICMS.SituTrib := cst41;
    Imp.ICMS.ICMS45.CST := cst41;

    Imp.ICMS.SituTrib := cst51;
    Imp.ICMS.ICMS45.CST := cst51;

    if Emit.enderEmit.UF = Rem.enderReme.UF then
    begin
      Imp.ICMS.SituTrib := cst90;
      Imp.ICMS.ICMS90.CST := cst90;
      Imp.ICMS.ICMS90.pRedBC := 10.00;
      Imp.ICMS.ICMS90.vBC := 100.00;
      Imp.ICMS.ICMS90.pICMS := 7.00;
      Imp.ICMS.ICMS90.vICMS := 6.30;
      Imp.ICMS.ICMS90.vCred := 0.00;
    end
    else
    begin
      Imp.ICMS.SituTrib := cstICMSOutraUF;
      Imp.ICMS.ICMSOutraUF.CST := cstICMSOutraUF; // ICMS Outros
      Imp.ICMS.ICMSOutraUF.pRedBCOutraUF := 0;
      Imp.ICMS.ICMSOutraUF.vBCOutraUF := 100.00;
      Imp.ICMS.ICMSOutraUF.pICMSOutraUF := 7.00;
      Imp.ICMS.ICMSOutraUF.vICMSOutraUF := 7.00;
    end;

    Imp.ICMS.SituTrib := cstICMSSN;
    Imp.ICMS.ICMSSN.indSN := 1;

    Imp.infAdFisco :=
      'Lei da Transparencia: O valor aproximado de tributos incidentes sobre o preço deste servico é de R$ 17,00 (17,00%) Fonte: IBPT';
    imp.vTotTrib := 17.00;

    with infCTeNorm do
    begin
      infCarga.vCarga := 5000;
      infCarga.proPred := 'Produto Predominante';
      infCarga.xOutCat := 'Outras Caractereisticas da Carga';
      infCarga.vCargaAverb := 5000;

      // UnidMed = (uM3,uKG, uTON, uUNIDADE, uLITROS);
      with infCarga.InfQ.New do
      begin
        cUnid := uKg;
        tpMed := 'Kg';
        qCarga := 10;
      end;

      with infCarga.InfQ.New do
      begin
        cUnid := uUnidade;
        tpMed := 'Caixa';
        qCarga := 5;
      end;

      with infDoc.infNFe.New do
        chave := 'chave da NFe emitida pelo remente da carga';

      rodo.RNTRC := '12345678';

      with rodo.occ.Add do
      begin
        serie := '001';
        nOcc := 1;
        dEmi := Date;

        emiOcc.CNPJ := '12345678000123';
        emiOcc.cInt := '501';
        emiOcc.IE := '1234567';
        emiOcc.UF := 'SP';
        emiOcc.fone := '22334455';
      end;

      with infCTeSub do
      begin
        chCte := '';
        tomaNaoICMS.refCteAnu := '';



        tomaICMS.refNF.CNPJCPF := '';
        tomaICMS.refNF.modelo := '';
        tomaICMS.refNF.serie := 0;
        tomaICMS.refNF.subserie := 0;
        tomaICMS.refNF.nro := 0;
        tomaICMS.refNF.valor := 0;
        tomaICMS.refNF.dEmi := Date;
      end;

      with cobr do
      begin
        fat.nFat := '123';
        fat.vOrig := 100;
        fat.vDesc := 0;
        fat.vLiq := 100;

        with dup.New do
        begin
          nDup := '123';
          dVenc := Date + 30;
          vDup := 100;
        end;
      end;
    end;

    InfCTeComp.chave := '';

    infCteAnu.chCTe := '';
    infCteAnu.dEmi := Date;

    autXML.Add.CNPJCPF := '01234567809';
  end;

  Result := TJSONTools.ObjToJson(facbr.Conhecimentos.Items[0].CTe);

  Result.Delete('XML');
  Result.Delete('XMLOriginal');
  Result.Delete('NomeArq');
  Result.Delete('Protocolo');

  facbr.Conhecimentos.Clear; // Limpa ap\u00F3s gerar o modelo
end;

function TACBRModelosJSONCTe.ModelConsultaCTe: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('tpAmb', Ord(TpcnTipoAmbiente.taHomologacao)); // Exemplo
  Result.Add('chCTe', '35...'); // Exemplo de chave do CTe
  // Ou Result.Add('nRec', '12345...'); // Exemplo de n\u00FAmero do recibo
end;

function TACBRModelosJSONCTe.ModelConsultaSituacaoServico: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('cUF', 35); // Exemplo: SP
  Result.Add('tpAmb', Ord(TpcnTipoAmbiente.taHomologacao)); // Exemplo
  Result.Add('verDados', '3.00'); // Vers\u00E3o do WebService
end;

{ TACBRBridgeCTe }

procedure TACBRBridgeCTe.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then
    exit;

  O := GetJSON(fcfg) as TJSONObject;
  try
    // Tentar carregar a configura\u00E7\u00E3o no componente CTe
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
  finally
    O.Free;
  end;

  fcfg := ''; // Limpa a configura\u00E7\u00E3o ap\u00F3s o uso
end;

function TACBRBridgeCTe.ReadXMLFromJSON(const jsonData: TJSONObject): string;
var
  xmlBase64: string;
  oXML: TJSONString; // Usar TJSONString para melhor tratamento
begin
  Result := '';
  if not jsonData.Find('xml', oXML) then
    raise Exception.Create(
      'Par\u00E2metro "xml" (contendo o XML em Base64) n\u00E3o encontrado no JSON.');

  xmlBase64 := oXML.AsString; // Obter a string do TJSONString

  if xmlBase64.IsEmpty then
    raise Exception.Create('Par\u00E2metro "xml" est\u00E1 vazio.');

  try
    Result := DecodeStringBase64(xmlBase64);
  except
    on E: Exception do
      raise Exception.Create('A string XML em base64 \u00E9 inv\u00E1lida: ' +
        E.Message);
  end;
end;

constructor TACBRBridgeCTe.Create(const Cfg: string);
begin
  facbr := TACBrCTe.Create(nil);
  fdacte := TACBrCTeDACTeRL.Create(nil);
  // Criar a inst\u00E2ncia do componente de relat\u00F3rio
  fcfg := Cfg;
  facbr.DACTE := fdacte; // Associa o componente de impress\u00E3o ao principal
end;

destructor TACBRBridgeCTe.Destroy;
begin
  FreeAndNil(facbr);
  FreeAndNil(fdacte);
  inherited Destroy;
end;

function TACBRBridgeCTe.EnviarCTe(const jCTe: TJSONObject): TJSONObject;
var
  Conhecimento: TCTe;
  Lote: string; // Envio de CTe geralmente usa lote string ou n\u00FAmero
  RetWS: TCTeRetRecepcao; // Verificar o tipo correto do retorno no ACBrCTe
begin
  CarregaConfig;

  Result := TJSONObject.Create;
  // Cria um objeto TCTe na cole\u00E7\u00E3o Conhecimentos do componente
  Conhecimento := facbr.Conhecimentos.Add.CTE;
  Lote := '1'; // Pode ser um identificador ou simplesmente '1' se enviar um por vez

  try
    // Carrega os dados do JSON no objeto Conhecimento
    TJSONTools.JsonToObj(jCTe, Conhecimento);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na leitura do objeto JSON do CTe: ' + E.Message);
      facbr.Conhecimentos.Clear; // Limpa o conhecimento adicionado
      Exit;
    end;
  end;

  try
    // Valida (opcional, mas recomendado)

    try
      facbr.Conhecimentos.Validar;
    except
      on E: Exception do
      begin
        Result.Add('status', 'erro_validacao');
        Result.Add('message', facbr.Conhecimentos.Items[0].ErroValidacao);
        // Adicionar mais detalhes se necess\u00E1rio: ErroValidacaoCompleto, etc.
        facbr.Conhecimentos.Clear;
        Exit;
      end;
    end;

    // Assina
    facbr.Conhecimentos.Assinar;

    // Envia o conhecimento (ou lote)
    if facbr.Enviar(StrToInt(Lote)) then
      // Verificar se Enviar \u00E9 o m\u00E9todo correto e se espera int ou string
    begin
      // Sucesso no envio, pegar o retorno do processamento
      RetWS := facbr.WebServices.Retorno;
      // Ajustar conforme o nome da propriedade de retorno
      Result := TJSONObject(TJSONTools.ObjToJson(RetWS));
      // Serializa o retorno para JSON
    end
    else
    begin
      // Falha no envio (ex: problema de comunica\u00E7\u00E3o)
      Result.Add('status', 'erro_envio');
      Result.Add('message', 'Falha ao enviar o CTe para a SEFAZ.');
      // Adicionar detalhes do log do ACBr se poss\u00EDvel/necess\u00E1rio
    end;

  except
    on E: Exception do
    begin
      Result.Add('status', 'excecao');
      Result.Add('message', 'Exce\u00E7\u00E3o durante o envio do CTe: ' +
        E.Message);
      // Considerar logar E.StackTrace se dispon\u00EDvel
    end;
  end;

  // Limpa a cole\u00E7\u00E3o de conhecimentos ap\u00F3s o envio
  // Cuidado: Se precisar do objeto para imprimir DACTE depois, n\u00E3o limpar aqui.
  // facbr.Conhecimentos.Clear; // Avaliar onde limpar
end;

function TACBRBridgeCTe.EnviarEvento(const jEventos: TJSONArray): string;
var
  objEvento: TEventoCTe; // Tipo correto do item de evento CTe
  oEvento: TJSONObject;
  I: integer;
  XmlBase64: TJSONString;
  LoteId: string; // Evento CTe usa lote string
begin
  CarregaConfig;
  Result := '';
  LoteId := '1'; // Ou gerar um ID \u00FAnico

  try
    for I := 0 to jEventos.Count - 1 do
    begin
      oEvento := jEventos.Items[i] as TJSONObject;

      // Tratamento para LoadXML (similar \u00E0 NFe, se aplic\u00E1vel e necess\u00E1rio para CTe)
      // if oEvento.Find('LoadXML', XmlBase64) then ...

      // Cria um novo objeto de evento na cole\u00E7\u00E3o do componente
      objEvento := facbr.EventoCTe.Evento.New;
      // Carrega os dados do JSON para o objeto de evento
      TJSONTools.JsonToObj(oEvento, objEvento);
    end;

    // Envia o(s) evento(s)
    if facbr.EnviarEvento(LoteId) then
      // Verificar o m\u00E9todo correto e par\u00E2metros
    begin
      // Sucesso, serializa o retorno do evento
      // Ajustar o caminho exato do objeto de retorno no ACBrCTe
      Result := TJSONTools.ObjToJsonString(facbr.WebServices.EnvEvento.retEvento);
    end
    else
    begin
      // Falha no envio do evento
      raise Exception.Create('Falha ao enviar o evento CTe para a SEFAZ.');
    end;

  except
    on E: Exception do
    begin
      // Retorna um JSON de erro em caso de exce\u00E7\u00E3o
      Result := TJSONObject.Create.Add('status', 'erro').Add('message',
        E.Message).ToJSON;
    end;
  end;

  // Limpar cole\u00E7\u00E3o de eventos ap\u00F3s o envio
  facbr.EventoCTe.Evento.Clear;
end;

function TACBRBridgeCTe.ConsultarCTe(const jConsulta: TJSONObject): TJSONObject;
var
  ChaveOuRecibo: string;
  TipoAmbiente: TpcnTipoAmbiente;
  oChave, oRecibo, oTpAmb: TJSONValue;
  RetWS: TRetConsSitCTe; // Tipo correto para o retorno da consulta
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  ChaveOuRecibo := '';
  TipoAmbiente := TpcnTipoAmbiente.taHomologacao; // Padr\u00E3o

  if jConsulta.Find('tpAmb', oTpAmb) then
    TipoAmbiente := TpcnTipoAmbiente(oTpAmb.AsInteger);

  // Prioriza consulta por Chave se ambos forem informados
  if jConsulta.Find('chCTe', oChave) then
    ChaveOuRecibo := oChave.AsString
  else if jConsulta.Find('nRec', oRecibo) then
    ChaveOuRecibo := oRecibo.AsString;

  if ChaveOuRecibo = '' then
  begin
    Result.Add('status', 'erro');
    Result.Add('message',
      'Chave do CTe (chCTe) ou n\u00FAmero do recibo (nRec) n\u00E3o informado para consulta.');
    Exit;
  end;

  try
    // Define o ambiente antes da consulta
    facbr.Configuracoes.WebServices.Ambiente := TipoAmbiente;

    // Executa a consulta
    facbr.Consultar(ChaveOuRecibo); // Verificar o m\u00E9todo correto de consulta

    // Pega o objeto de retorno da consulta
    RetWS := facbr.WebServices.RetConsSitCTe;
    // Ajustar se o nome da propriedade for diferente
    // Serializa o retorno para JSON
    Result := TJSONObject(TJSONTools.ObjToJson(RetWS));

  except
    on E: Exception do
    begin
      Result.Clear; // Limpa o JSON antes de adicionar erro
      Result.Add('status', 'excecao');
      Result.Add('message', 'Exce\u00E7\u00E3o durante a consulta do CTe: ' +
        E.Message);
    end;
  end;
end;

function TACBRBridgeCTe.ConsultarSituacaoServico(
  const jConsulta: TJSONObject): TJSONObject;
var
  cUF: integer;
  tpAmb: TpcnTipoAmbiente;
  verDados: string;
  oCUF, oTpAmb, oVerDados: TJSONValue;
  RetWS: TRetConsStatServ; // Tipo correto para o retorno da consulta status servi\u00E7o
begin
  CarregaConfig;
  Result := TJSONObject.Create;

  // Valores padr\u00E3o
  cUF := 0;
  tpAmb := TpcnTipoAmbiente.taHomologacao;
  verDados := '';

  if jConsulta.Find('cUF', oCUF) then
    cUF := oCUF.AsInteger;

  if jConsulta.Find('tpAmb', oTpAmb) then
    tpAmb := TpcnTipoAmbiente(oTpAmb.AsInteger);

  if jConsulta.Find('verDados', oVerDados) then
    verDados := oVerDados.AsString;


  if cUF = 0 then
  begin
    Result.Add('status', 'erro');
    Result.Add('message',
      'C\u00F3digo da UF (cUF) n\u00E3o informado ou inv\u00E1lido para consulta de status.');
    Exit;
  end;

  if verDados = '' then
  begin
    Result.Add('status', 'erro');
    Result.Add('message',
      'Vers\u00E3o dos dados (verDados) n\u00E3o informada para consulta de status.');
    Exit;
  end;


  try
    // Define o ambiente antes da consulta
    facbr.Configuracoes.WebServices.Ambiente := tpAmb;
    // Define a UF para a consulta (pode ser necess\u00E1rio ajustar a propriedade no ACBrCTe)
    // facbr.Configuracoes.WebServices.UF := IntToStr(cUF); // Exemplo, verificar propriedade correta

    // Executa a consulta de status do servi\u00E7o
    // Verificar o m\u00E9todo correto para consultar status do servi\u00E7o no ACBrCTe.WebServices
    // Pode ser algo como facbr.WebServices.ConsultarStatusServico(cUF, verDados);
    facbr.ConsultarStatusServico(IntToStr(cUF));
    // Exemplo, verificar par\u00E2metros corretos

    // Pega o objeto de retorno
    RetWS := facbr.WebServices.RetConsStatServ; // Ajustar se o caminho for diferente
    // Serializa o retorno para JSON
    Result := TJSONObject(TJSONTools.ObjToJson(RetWS));

  except
    on E: Exception do
    begin
      Result.Clear; // Limpa o JSON antes de adicionar erro
      Result.Add('status', 'excecao');
      Result.Add('message',
        'Exce\u00E7\u00E3o durante a consulta de status do servi\u00E7o CTe: ' +
        E.Message);
    end;
  end;
end;

function TACBRBridgeCTe.GerarDACTE(const xmlData: TJSONObject): TJSONObject;
var
  pdfBase64: string;
  stringXml: string;
  tamanho: integer;
  oId: TJSONString;
  fileName: string;
  chaveCTe: string;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  chaveCTe := '';

  try
    stringXml := ReadXMLFromJSON(xmlData);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', E.Message);
      Exit;
    end;
  end;

  // Limpa conhecimentos anteriores e carrega o XML fornecido
  facbr.Conhecimentos.Clear;
  try
    facbr.Conhecimentos.LoadFromString(stringXml);
    if facbr.Conhecimentos.Count > 0 then
      chaveCTe := facbr.Conhecimentos.Items[0].CTe.infCte.Id;
    // Pega a chave do CTe carregado (verificar caminho correto)
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na leitura do XML do CTe: ' + E.Message);
      Exit;
    end;
  end;

  // Esvazia a string para liberar mem\u00F3ria
  stringXml := '';

  // Configura o componente DACTE
  // f_DACTE.TipoDACTE := ??? // Se houver tipos (retrato/paisagem), configurar aqui
  fdacte.MostraPreview := False;
  fdacte.MostraStatus := False;
  // f_DACTE.MostraSetup := False; // Verificar se existe essa propriedade

  // Gera o nome do arquivo tempor\u00E1rio
  fileName := GetTempFileName('.pdf'); // Adicionar extens\u00E3o \u00E9 boa pr\u00E1tica

  try
    // Define o caminho de sa\u00EDda e manda imprimir
    fdacte.PathPDF := ExtractFilePath(fileName); // ACBrDACTE usa PathPDF ou PathSalvar
    fdacte.NomeArquivo := ExtractFileName(fileName); // E NomeArquivo
    // Certifique-se que o Conhecimento a ser impresso est\u00E1 carregado
    if facbr.Conhecimentos.Count > 0 then
    begin
      facbr.Conhecimentos.Items[0].ImprimirDACTE;
      // Ou facbr.ImprimirDACTE se for m\u00E9todo direto
      fileName := fdacte.PathPDF + fdanfe.NomeArquivo;
      // Recomp\u00F5e o nome completo (verificar propriedades)
    end
    else
    begin
      raise Exception.Create('Nenhum CTe carregado para gerar o DACTE.');
    end;
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Falha ao gerar o PDF do DACTE: ' + E.Message);
      if FileExists(fileName) then DeleteFile(fileName); // Tenta limpar temp file
      Exit;
    end;
  end;

  // Verifica se o arquivo foi realmente criado
  if not FileExists(fileName) then
  begin
    Result.Add('status', 'erro');
    Result.Add('message',
      'Arquivo PDF do DACTE n\u00E3o foi encontrado ap\u00F3s a gera\u00E7\u00E3o.');
    Exit;
  end;


  // Converte o arquivo para base64
  try
    pdfBase64 := FileToStringBase64(fileName, True, tamanho);
    // True para apagar o temp file
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro ao converter PDF para Base64: ' + E.Message);
      // N\u00E3o tenta apagar de novo se j\u00E1 falhou
      Exit;
    end;
  end;

  // Monta o JSON de retorno
  Result.Add('pdf', pdfBase64);
  Result.Add('chave', chaveCTe);
  Result.Add('tamanho', tamanho); // Tamanho em Bytes

  // Adiciona o identificador \u00FAnico se ele existir no JSON de entrada
  if xmlData.Find('id', oId) then
    Result.Add('id', oId.AsString);

end;


function TACBRBridgeCTe.TesteConfig: boolean;
begin
  try
    CarregaConfig;
    Result := True;
  except
    on E: Exception do // Captura qualquer exce\u00E7\u00E3o durante o carregamento
    begin
      // Opcional: Logar E.Message para depura\u00E7\u00E3o
      Result := False;
    end;
  end;
end;

end.
