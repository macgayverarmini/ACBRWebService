{%RunFlags MESSAGES+}
unit method.acbr.mdfe;

{$mode Delphi}

interface

uses
  streamtools,
  RTTI,
  // Units específicas do MDF-e (ajuste os nomes se necessário na sua versão do ACBr)
  ACBrMDFe,
  ACBrMDFeDAMDFERLClass, // Assumindo componente de relatório RL para DAMDFe
  ACBrMDFeWebServices,
  pcnMDFe,
  pcnConversaoMDFe,
  pcnProcMDFe,
  pcnEnvEventoMDFe,
  pcnConsMDFeNaoEnc,
  // Units comuns e do projeto
  StrUtils,
  LCLIntf, LCLType, Variants, Graphics,
  Controls, Forms, Dialogs, ComCtrls, Buttons, ExtCtrls,
  fpjson, jsonconvert,
  ACBrDFeDANFeReport, // Pode ser necessário ajustar ou usar unit base comum
  ACBrMail, // Se for usar envio de email
  Base64, jsonparser, ACBrDFeSSL,
  ACBrDFeConfiguracoes,
  ACBrMDFeConfiguracoes, // Configurações específicas do MDFe
  Classes, SysUtils;

type

  { TACBRBridgeMDFe }

  TACBRBridgeMDFe = class
  private
    fcfg: string;
    facbr: TACBrMDFe;
    fdamdfe: TACBrMDFeDAMDFERL; // Componente para gerar o DAMDFe
    procedure CarregaConfig;

    function ReadXMLFromJSON(const jsonData: TJSONObject): string;
  public
    constructor Create(const Cfg: string);
    destructor Destroy; override;

    // Envia um Manifesto MDF-e
    function EnviarMDFe(const jMDFe: TJSONObject): TJSONObject;
    // Envia um evento para um MDF-e
    function EnviarEvento(const jEventos: TJSONArray): string; // Retorna string JSON do RetEvento
    // Consulta um MDF-e específico
    function ConsultarMDFe(const jConsulta: TJSONObject): TJSONObject; // Retorna JSON do RetConsSitMDFe
    // Consulta MDF-es não encerrados para um CNPJ
    function ConsultarNaoEncerrados(const jConsulta: TJSONObject): TJSONObject; // Retorna JSON do RetConsMDFeNaoEnc
    // Gera o DAMDFE em PDF
    function GerarDamdfe(const xmlData: TJSONObject): TJSONObject; // Retorna JSON com PDF Base64

    // Testa a configuração passada em JSON
    function TesteConfig: boolean;
  end;

  { TACBRModelosJSONMDFe - Salva os retornos de modelo de requisições MDF-e }

  TACBRModelosJSONMDFe = class(TACBRBridgeMDFe)
  private
  public
    // Retorna as configurações atuais do componente MDF-e da ACBr.
    function ModelConfig: TJSONObject;
    // Retorna um modelo JSON para envio de evento MDF-e.
    function ModelEvento: TJSONObject;
    // Retorna um modelo JSON para envio de MDF-e.
    function ModelMDFe: TJSONObject;
    // Retorna um modelo JSON para consulta de situação de MDF-e.
    function ModelConsultaMDFe: TJSONObject;
    // Retorna um modelo JSON para consulta de MDF-es não encerrados.
    function ModelConsultaNaoEncerrados: TJSONObject;
  end;

implementation

{ TACBRModelosJSONMDFe }

function TACBRModelosJSONMDFe.ModelConfig: TJSONObject;
begin
  // Preenche configurações de exemplo para MDF-e
  with facbr.Configuracoes.Geral do
  begin
    // Ajustar conforme necessário para MDF-e (pode ter menos ou diferentes opções que NFe)
    VersaoDF := TpcnVersaoDFMDFe.ve300; // Exemplo: Versão 3.00
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
    TimeOut := 10000; // MDF-e pode demorar mais
    Visualizar := False;
  end;

  with facbr.Configuracoes.Certificados do
  begin
    ArquivoPFX := 'C:\caminho\seu_certificado.pfx'; // Exemplo
    Senha := 'sua_senha'; // Exemplo
  end;

  with facbr.Configuracoes.Arquivos do
  begin
     // Configurar paths se necessário
     // PathSalvar := 'C:\ACBr\MDFe\';
     // ...
  end;


  Result := TJSONTools.ObjToJson(facbr.Configuracoes);
end;

function TACBRModelosJSONMDFe.ModelEvento: TJSONObject;
begin
  // Cria um evento MDF-e vazio para gerar o modelo JSON
  facbr.EventoMDFe.Evento.New;
  // Preencher campos mínimos de exemplo se desejado
  // Ex: facbr.EventoMDFe.Evento.Items[0].infEvento.tpEvento := teCancelamento;
  Result := TJSONTools.ObjToJson(facbr.EventoMDFe);
  facbr.EventoMDFe.Evento.Clear; // Limpa após gerar o modelo
end;

function TACBRModelosJSONMDFe.ModelMDFe: TJSONObject;
var
  MDFe: TMDFe;
begin
  // Cria um manifesto MDF-e vazio para gerar o modelo JSON
  MDFe := facbr.Manifestos.Add;
  // Adiciona sub-estruturas para aparecerem no JSON
  MDFe.infMDFe.ide.infMunCarrega.New;
  MDFe.infMDFe.infDoc.infMunDescarga.New.infNF.New; // Exemplo de aninhamento
  MDFe.infMDFe.seg.New;
  MDFe.infMDFe.tot.qNFe := 1; // Exemplo
  MDFe.infMDFe.infModal.rodo.veicTracao; // Acessar para criar se for objeto
  MDFe.infMDFe.infModal.rodo.veicReboque.New;
  MDFe.infMDFe.infModal.rodo.infANTT.infCIOT.New;
  MDFe.infMDFe.infModal.rodo.infANTT.infContratante.New;
  MDFe.infMDFe.infModal.rodo.infANTT.infPag.New.infComp.New;
  MDFe.infMDFe.infModal.rodo.infANTT.infPag.infBanc; // Acessar para criar se for objeto

  Result := TJSONTools.ObjToJson(MDFe);
  // Remover campos internos ou grandes desnecessários para o modelo
  Result.Delete('XML');
  Result.Delete('XMLOriginal');
  Result.Delete('NomeArq');
  Result.Delete('Protocolo');

  facbr.Manifestos.Clear; // Limpa após gerar o modelo
end;

function TACBRModelosJSONMDFe.ModelConsultaMDFe: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('tpAmb', Ord(TpcnTipoAmbiente.taHomologacao)); // Exemplo
  Result.Add('chMDFe', '32...'); // Exemplo de chave
  // Ou Result.Add('nRec', '12345...'); // Exemplo de recibo
end;

function TACBRModelosJSONMDFe.ModelConsultaNaoEncerrados: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('tpAmb', Ord(TpcnTipoAmbiente.taHomologacao)); // Exemplo
  Result.Add('CNPJ', '00000000000191'); // Exemplo
end;

{ TACBRBridgeMDFe }

procedure TACBRBridgeMDFe.CarregaConfig;
var
  O: TJSONObject;
begin
  if fcfg = '' then
    exit;

  O := GetJSON(fcfg) as TJSONObject;
  try
    // Tentar carregar a configuração no componente MDF-e
    TJSONTools.JsonToObj(O, facbr.Configuracoes);
  finally
    O.Free;
  end;

  fcfg := ''; // Limpa a configuração após o uso
end;

function TACBRBridgeMDFe.ReadXMLFromJSON(const jsonData: TJSONObject): string;
var
  xmlBase64: string;
  oXML: TJSONString; // Usar TJSONString para melhor tratamento
begin
  Result := '';
  if not jsonData.Find('xml', oXML) then
     raise Exception.Create('Parâmetro "xml" (contendo o XML em Base64) não encontrado no JSON.');

  xmlBase64 := oXML.AsString; // Obter a string do TJSONString

  if xmlBase64.IsEmpty then
     raise Exception.Create('Parâmetro "xml" está vazio.');

  try
    Result := DecodeStringBase64(xmlBase64);
  except
    on E: Exception do
      raise Exception.Create('A string XML em base64 é inválida: ' + E.Message);
  end;
end;

constructor TACBRBridgeMDFe.Create(const Cfg: string);
begin
  facbr := TACBrMDFe.Create(nil);
  fdamdfe := TACBrMDFeDAMDFERL.Create(nil);
  fcfg := Cfg;
  facbr.DAMDFE := fdamdfe; // Associa o componente de impressão ao principal
end;

destructor TACBRBridgeMDFe.Destroy;
begin
  FreeAndNil(facbr);
  FreeAndNil(fdamdfe);
  inherited Destroy;
end;

function TACBRBridgeMDFe.EnviarMDFe(const jMDFe: TJSONObject): TJSONObject;
var
  Manifesto: TMDFe;
  Lote: string; // Envio de MDFe geralmente não usa lote numérico como NFe
  RetWS: TProcMDFe; // Verificar o tipo correto do retorno
begin
  CarregaConfig;

  Result := TJSONObject.Create;
  // Cria um objeto TMDFe na coleção Manifestos do componente
  Manifesto := facbr.Manifestos.Add;
  Lote := '1'; // Pode ser um identificador ou simplesmente '1' se enviar um por vez

  try
    // Carrega os dados do JSON no objeto Manifesto
    TJSONTools.JsonToObj(jMDFe, Manifesto);
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na leitura do objeto JSON do MDF-e: ' + E.Message);
      facbr.Manifestos.Clear; // Limpa o manifesto adicionado
      Exit;
    end;
  end;

  try
    // Valida (opcional, mas recomendado)
    facbr.Manifestos.Validar;
    if not facbr.Manifestos.Items[0].Valido then
    begin
       Result.Add('status', 'erro_validacao');
       Result.Add('message', facbr.Manifestos.Items[0].ErroValidacao);
       // Adicionar mais detalhes se necessário: ErroValidacaoCompleto, etc.
       facbr.Manifestos.Clear;
       Exit;
    end;

    // Assina
    facbr.Manifestos.Assinar;

    // Envia o manifesto (ou lote)
    if facbr.EnviarManifesto(Lote) then // Verificar se EnviarManifesto é o método correto
    begin
       // Sucesso no envio, pegar o retorno do processamento
       RetWS := facbr.WebServices.Retorno; // Ajustar conforme o nome da propriedade de retorno
       Result := TJSONObject(TJSONTools.ObjToJson(RetWS)); // Serializa o retorno para JSON
    end
    else
    begin
       // Falha no envio (ex: problema de comunicação)
       Result.Add('status', 'erro_envio');
       Result.Add('message', 'Falha ao enviar o MDF-e para a SEFAZ.');
       // Adicionar detalhes do log do ACBr se possível/necessário
    end;

  except
      on E: Exception do
      begin
          Result.Add('status', 'excecao');
          Result.Add('message', 'Exceção durante o envio do MDF-e: ' + E.Message);
          // Considerar logar E.StackTrace se disponível
      end;
  end;

  // Limpa a coleção de manifestos após o envio
  // Cuidado: Se precisar do objeto para imprimir DAMDFE depois, não limpar aqui.
  // facbr.Manifestos.Clear; // Avaliar onde limpar
end;

function TACBRBridgeMDFe.EnviarEvento(const jEventos: TJSONArray): string;
var
  objEvento: TEventoMDFe; // Tipo correto do item de evento MDFe
  oEvento: TJSONObject;
  I: integer;
  // InfEvento: TJSONObject; // Desnecessário se o JSON já tem a estrutura correta
  XmlBase64: TJSONString;
  LoteId: string; // Evento MDFe usa lote string
begin
  CarregaConfig;
  Result := '';
  LoteId := '1'; // Ou gerar um ID único

  try
    for I := 0 to jEventos.Count - 1 do
    begin
      oEvento := jEventos.Items[i] as TJSONObject;

      // Tratamento para LoadXML (similar à NFe, se aplicável e necessário para MDFe)
      // if oEvento.Find('LoadXML', XmlBase64) then ...

      // Cria um novo objeto de evento na coleção do componente
      objEvento := facbr.EventoMDFe.Evento.New;
      // Carrega os dados do JSON para o objeto de evento
      TJSONTools.JsonToObj(oEvento, objEvento);
    end;

    // Envia o(s) evento(s)
    if facbr.EnviarEvento(LoteId) then
    begin
      // Sucesso, serializa o retorno do evento
      // Ajustar o caminho exato do objeto de retorno no ACBrMDFe
      Result := TJSONTools.ObjToJsonString(facbr.WebServices.EnvEvento.retEvento);
    end
    else
    begin
       // Falha no envio do evento
       raise Exception.Create('Falha ao enviar o evento MDF-e para a SEFAZ.');
    end;

  except
      on E: Exception do
      begin
          // Retorna um JSON de erro em caso de exceção
          Result := TJSONObject.Create.Add('status','erro').Add('message', E.Message).ToJSON;
      end;
  end;

  // Limpar coleção de eventos após o envio
  facbr.EventoMDFe.Evento.Clear;
end;

function TACBRBridgeMDFe.ConsultarMDFe(const jConsulta: TJSONObject): TJSONObject;
var
  ChaveOuRecibo: string;
  TipoAmbiente : TpcnTipoAmbiente;
  oChave, oRecibo, oTpAmb : TJSONValue;
  RetWS : TRetConsSitMDFe; // Tipo correto para o retorno da consulta
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  ChaveOuRecibo := '';
  TipoAmbiente := TpcnTipoAmbiente.taHomologacao; // Padrão

  if jConsulta.Find('tpAmb', oTpAmb) then
     TipoAmbiente := TpcnTipoAmbiente(oTpAmb.AsInteger);

  // Prioriza consulta por Chave se ambos forem informados
  if jConsulta.Find('chMDFe', oChave) then
     ChaveOuRecibo := oChave.AsString
  else if jConsulta.Find('nRec', oRecibo) then
     ChaveOuRecibo := oRecibo.AsString;

  if ChaveOuRecibo = '' then
  begin
     Result.Add('status', 'erro');
     Result.Add('message', 'Chave do MDF-e (chMDFe) ou número do recibo (nRec) não informado para consulta.');
     Exit;
  end;

  try
    // Define o ambiente antes da consulta
    facbr.Configuracoes.WebServices.Ambiente := TipoAmbiente;

    // Executa a consulta
    facbr.ConsultarManifesto(ChaveOuRecibo);

    // Pega o objeto de retorno da consulta
    RetWS := facbr.WebServices.RetConsSitMDFe; // Ajustar se o nome da propriedade for diferente
    // Serializa o retorno para JSON
    Result := TJSONObject(TJSONTools.ObjToJson(RetWS));

  except
    on E: Exception do
    begin
       Result.Clear; // Limpa o JSON antes de adicionar erro
       Result.Add('status', 'excecao');
       Result.Add('message', 'Exceção durante a consulta do MDF-e: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeMDFe.ConsultarNaoEncerrados(const jConsulta: TJSONObject): TJSONObject;
var
  CNPJ : string;
  TipoAmbiente : TpcnTipoAmbiente;
  oCNPJ, oTpAmb : TJSONValue;
  RetWS : TRetConsMDFeNaoEnc; // Tipo correto do retorno
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  CNPJ := '';
  TipoAmbiente := TpcnTipoAmbiente.taHomologacao; // Padrão

  if jConsulta.Find('tpAmb', oTpAmb) then
     TipoAmbiente := TpcnTipoAmbiente(oTpAmb.AsInteger);

  if jConsulta.Find('CNPJ', oCNPJ) then
     CNPJ := oCNPJ.AsString;

  if CNPJ = '' then
  begin
     Result.Add('status', 'erro');
     Result.Add('message', 'CNPJ do emitente não informado para consulta de não encerrados.');
     Exit;
  end;

   try
    // Define o ambiente antes da consulta
    facbr.Configuracoes.WebServices.Ambiente := TipoAmbiente;

    // Executa a consulta de não encerrados
    facbr.ConsultarNaoEncerrados(CNPJ);

    // Pega o objeto de retorno da consulta
    RetWS := facbr.WebServices.ConsNaoEnc.RetConsMDFeNaoEnc; // Ajustar se o caminho for diferente
    // Serializa o retorno para JSON
    Result := TJSONObject(TJSONTools.ObjToJson(RetWS));

  except
    on E: Exception do
    begin
       Result.Clear; // Limpa o JSON antes de adicionar erro
       Result.Add('status', 'excecao');
       Result.Add('message', 'Exceção durante a consulta de MDF-es não encerrados: ' + E.Message);
    end;
  end;
end;

function TACBRBridgeMDFe.GerarDamdfe(const xmlData: TJSONObject): TJSONObject;
var
  pdfBase64: string;
  stringXml: string;
  tamanho: integer;
  oId: TJSONString;
  fileName: string;
  chaveMDFe: string;
begin
  CarregaConfig;
  Result := TJSONObject.Create;
  chaveMDFe := '';

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

  // Limpa manifestos anteriores e carrega o XML fornecido
  facbr.Manifestos.Clear;
  try
    facbr.Manifestos.LoadFromString(stringXml);
    if facbr.Manifestos.Count > 0 then
       chaveMDFe := facbr.Manifestos.Items[0].MDFe.infMDFe.ID; // Pega a chave do MDFe carregado
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro na leitura do XML do MDF-e: ' + E.Message);
      Exit;
    end;
  end;

  // Esvazia a string para liberar memória
  stringXml := '';

  // Configura o componente DAMDFE
  // fdamdfe.TipoDAMDFE := ??? // Se houver tipos (retrato/paisagem), configurar aqui
  fdamdfe.MostraPreview := False;
  fdamdfe.MostraStatus := False;
  // fdamdfe.MostraSetup := False; // Verificar se existe essa propriedade

  // Gera o nome do arquivo temporário
  fileName := GetTempFileName('.pdf'); // Adicionar extensão é boa prática

  try
    // Define o caminho de saída e manda imprimir
    fdamdfe.PathSalvar := ExtractFilePath(fileName); // ACBrRL usa PathSalvar
    fdamdfe.NomeArquivo := ExtractFileName(fileName); // E NomeArquivo
    // Certifique-se que o Manifesto a ser impresso está carregado
    if facbr.Manifestos.Count > 0 then
    begin
      facbr.Manifestos.Items[0].ImprimirDAMDFePDF; // Ou facbr.ImprimirDAMDFePDF se for método direto
      fileName := fdamdfe.PathSalvar + fdamdfe.NomeArquivo; // Recompõe o nome completo
    end
    else
    begin
       raise Exception.Create('Nenhum MDF-e carregado para gerar o DAMDFE.');
    end;
  except
     on E: Exception do
     begin
        Result.Add('status', 'erro');
        Result.Add('message', 'Falha ao gerar o PDF do DAMDFE: ' + E.Message);
        if FileExists(fileName) then DeleteFile(fileName); // Tenta limpar temp file
        Exit;
     end;
  end;

  // Verifica se o arquivo foi realmente criado
  if not FileExists(fileName) then
  begin
     Result.Add('status', 'erro');
     Result.Add('message', 'Arquivo PDF do DAMDFE não foi encontrado após a geração.');
     Exit;
  end;


  // Converte o arquivo para base64
  try
    pdfBase64 := FileToStringBase64(fileName, True, tamanho); // True para apagar o temp file
  except
    on E: Exception do
    begin
      Result.Add('status', 'erro');
      Result.Add('message', 'Erro ao converter PDF para Base64: ' + E.Message);
      // Não tenta apagar de novo se já falhou
      Exit;
    end;
  end;

  // Monta o JSON de retorno
  Result.Add('pdf', pdfBase64);
  Result.Add('chave', chaveMDFe);
  Result.Add('tamanho', tamanho); // Tamanho em Bytes

  // Adiciona o identificador único se ele existir no JSON de entrada
  if xmlData.Find('id', oId) then
    Result.Add('id', oId.AsString);

end;

function TACBRBridgeMDFe.TesteConfig: boolean;
begin
  try
    CarregaConfig;
    Result := True;
  except
    on E: Exception do // Captura qualquer exceção durante o carregamento
    begin
      // Opcional: Logar E.Message para depuração
      Result := False;
    end;
  end;
end;

end.