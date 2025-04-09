program ACBRWebService;

{$MODE DELPHI}{$H+}

uses
  Interfaces,
  SysUtils, // Adicionado para usar FormatDateTime e Now
  Horse,
  Horse.Jhonson,
  Horse.HandleException,
  route.acbr.nfe,
  route.acbr.diversos.extenso,
  route.acbr.diversos.validador,
  route.acbr.certificados;

// Helper simples para log formatado (Opcional, mas ajuda a organizar)
procedure LogInfo(const AMessage: string);
begin
  // Formato: [Timestamp] [App] Mensagem
  WriteLn(FormatDateTime('[yyyy-mm-dd hh:nn:ss]', Now), ' [Horse] ', AMessage);
end;

procedure LogRouteMapping(const AModuleName: string);
begin
  LogInfo(Format('Mapping routes defined in %s...', [AModuleName]));
end;

const
  cAppPort = 9000; // Define a porta como constante para fácil referência

begin
  WriteLn('-------------------------------------------------------');
  LogInfo('Starting ACBRWebService application...');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing middleware...');
  THorse.Use(Jhonson);
  LogInfo('  ✓ Jhonson middleware initialized.');
  THorse.Use(HandleException);
  LogInfo('  ✓ HandleException middleware initialized.');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing routes...');

  // Log antes de chamar cada registrador de rota
  LogRouteMapping('route.acbr.nfe');
  route.acbr.nfe.regRouter;
  LogInfo('  ✓ ACBR NFe routes mapped.');

  LogRouteMapping('route.acbr.diversos.extenso');
  route.acbr.diversos.extenso.regRouter;
  LogInfo('  ✓ ACBR Diversos Extenso routes mapped.');

  LogRouteMapping('route.acbr.diversos.validador');
  route.acbr.diversos.validador.regRouter;
  LogInfo('  ✓ ACBR Diversos Validador routes mapped.');

  LogRouteMapping('route.acbr.certificados');
  route.acbr.certificados.regRouter;
  LogInfo('  ✓ ACBR Certificados routes mapped.');

  WriteLn('-------------------------------------------------------');
  LogInfo('Horse application successfully started.');
  LogInfo(Format('Listening on port %d', [cAppPort]));
  WriteLn('-------------------------------------------------------');

  // THorse.Listen é bloqueante. As mensagens acima são exibidas antes
  // do servidor começar a aceitar conexões.
  THorse.Listen(cAppPort);

  // Código abaixo só executa se o Listen parar (raro em execuções normais)
  LogInfo('ACBRWebService application stopped.');

end.
 
 
