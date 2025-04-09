unit route.acbr.mdfe;

{$mode Delphi}{$H+}

interface

uses
  // Unit com a lógica de negócio do MDF-e
  method.acbr.mdfe,
  // Units do Horse e JSON
  fpjson, Horse, Horse.Commons, Classes, SysUtils;

// --- Handlers para Endpoints de Modelos (GET) ---
procedure GetModeloConfigMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure GetModeloConsultaNaoEncerrados(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// --- Handlers para Endpoints de Operações (POST) ---
procedure PostEnviarMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostEventosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostDamdfeMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
procedure PostConsultaNaoEncerrados(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

// Procedure para registrar todas as rotas no Horse
procedure regRouter;

implementation

// --- Implementação dos Handlers de Modelos (GET) ---

procedure GetModeloConfigMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe; // Usar a classe de Modelos
begin
  // Cria instância da classe de modelos (não precisa de config para gerar modelo)
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    // Envia o JSON do modelo de configuração
    Res.Send<TJSONObject>(AcM.ModelConfig);
  finally
    AcM.Free;
  end;
end;

procedure GetModeloEventoMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    // Envia o JSON do modelo de evento
    Res.Send<TJSONObject>(AcM.ModelEvento);
  finally
    AcM.Free;
  end;
end;

procedure GetModeloMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    // Envia o JSON do modelo de MDF-e
    Res.Send<TJSONObject>(AcM.ModelMDFe);
  finally
    AcM.Free;
  end;
end;

procedure GetModeloConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    // Envia o JSON do modelo de consulta
    Res.Send<TJSONObject>(AcM.ModelConsultaMDFe);
  finally
    AcM.Free;
  end;
end;

procedure GetModeloConsultaNaoEncerrados(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  AcM: TACBRModelosJSONMDFe;
begin
  AcM := TACBRModelosJSONMDFe.Create('');
  try
    // Envia o JSON do modelo de consulta de não encerrados
    Res.Send<TJSONObject>(AcM.ModelConsultaNaoEncerrados);
  finally
    AcM.Free;
  end;
end;

// --- Implementação dos Handlers de Operações (POST) ---

procedure PostEnviarMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe; // Usar a classe Bridge
  cfgJson: TJSONStringType; // Para extrair a config
begin
  O := GetJSON(Req.Body) as TJSONObject;
  // Extrai a configuração do corpo da requisição
  if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" não encontrado no corpo da requisição JSON.');

  // Cria a instância da Bridge passando a config como string JSON
  Ac := TACBRBridgeMDFe.Create(cfgJson.AsString);
  try
    // Chama o método de envio, passando o JSON do MDF-e (sem a config)
    // Assume que o JSON principal (O) contém os dados do MDF-e, exceto a chave 'config'
    // Se os dados do MDF-e estiverem sob outra chave, ajuste O.Extract(...)
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.EnviarMDFe(O)); // EnviarMDFe retorna TJSONObject
  finally
    O.Free; // Libera o JSON principal da requisição
    Ac.Free;
  end;
end;

procedure PostEventosMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe;
  jEventos: TJSONArray;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" não encontrado no corpo da requisição JSON.');

  Ac := TACBRBridgeMDFe.Create(cfgJson.AsString);
  try
    // Extrai o array de eventos do JSON principal
    jEventos := O.Extract('eventos') as TJSONArray; // Assume que os eventos estão na chave 'eventos'
    if not Assigned(jEventos) then
       raise Exception.Create('Array "eventos" não encontrado no corpo da requisição JSON.');

    // EnviarEvento retorna uma string JSON
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send(Ac.EnviarEvento(jEventos));
  finally
    // jEventos é extraído, não precisa liberar separadamente
    O.Free;
    Ac.Free;
  end;
end;

procedure PostDamdfeMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
   if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" não encontrado no corpo da requisição JSON.');

  Ac := TACBRBridgeMDFe.Create(cfgJson.AsString);
  try
    // GerarDamdfe espera o JSON com { "config": {...}, "xml": "base64..." }
    // e retorna um TJSONObject com { "pdf": "base64...", "chave": "...", ...}
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.GerarDamdfe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultaMDFe(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
  if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" não encontrado no corpo da requisição JSON.');

  Ac := TACBRBridgeMDFe.Create(cfgJson.AsString);
  try
    // ConsultarMDFe espera o JSON com { "config": {...}, "chMDFe": "..." } ou { "nRec": "..." }
    // e retorna um TJSONObject (RetConsSitMDFe)
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.ConsultarMDFe(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;

procedure PostConsultaNaoEncerrados(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  O: TJSONObject;
  Ac: TACBRBridgeMDFe;
  cfgJson: TJSONStringType;
begin
  O := GetJSON(Req.Body) as TJSONObject;
   if not O.Find('config', cfgJson) then
     raise Exception.Create('Objeto "config" não encontrado no corpo da requisição JSON.');

  Ac := TACBRBridgeMDFe.Create(cfgJson.AsString);
  try
     // ConsultarNaoEncerrados espera o JSON com { "config": {...}, "CNPJ": "..." }
     // e retorna um TJSONObject (RetConsMDFeNaoEnc)
    Res.ContentType(TMimeTypes.ApplicationJSON.ToString)
      .Send<TJSONObject>(Ac.ConsultarNaoEncerrados(O));
  finally
    O.Free;
    Ac.Free;
  end;
end;


// --- Registro das Rotas ---

procedure regRouter;
begin
  // Endpoints de Modelos (GET)
  THorse.Get('/modelo/mdfe/config', GetModeloConfigMDFe);
  THorse.Get('/modelo/mdfe/evento', GetModeloEventoMDFe);
  THorse.Get('/modelo/mdfe/mdfe', GetModeloMDFe);
  THorse.Get('/modelo/mdfe/consulta', GetModeloConsultaMDFe);
  THorse.Get('/modelo/mdfe/consulta-nao-encerrados', GetModeloConsultaNaoEncerrados);

  // Endpoints de Operações (POST)
  THorse.Post('/mdfe/enviar', PostEnviarMDFe);
  THorse.Post('/mdfe/eventos', PostEventosMDFe);
  THorse.Post('/mdfe/damdfe', PostDamdfeMDFe);
  THorse.Post('/mdfe/consulta', PostConsultaMDFe);
  THorse.Post('/mdfe/consulta-nao-encerrados', PostConsultaNaoEncerrados);
end;

end.