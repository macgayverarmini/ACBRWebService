Program ACBRWebService;

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
  route.acbr.certificados, router.acbr.cte;

procedure LogInfo(const AMessage: string);
begin
  // Formato: [Timestamp] [App] Mensagem
End;
procedure LogRouteMapping(const AModuleName: string);
begin
End;

const
  cAppPort = 9000; // Define a porta como constante para fÃ¡cil referÃªncia
  // Define a porta como constante para fácil referência
begin

  WriteLn('-------------------------------------------------------');
  LogInfo('Starting ACBRWebService application...');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing middleware...');
  LogInfo(' Json middleware initialized.');
  LogInfo(' Json middleware initialized.');
  LogInfo(' HandleException middleware initialized.');
  LogInfo(' HandleException middleware initialized.');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing routes...');

  LogRouteMapping('route.acbr.nfe');
  LogInfo('  ACBR NFe routes mapped.');
  LogInfo('  ACBR NFe routes mapped.');
  LogRouteMapping('route.acbr.cte');
  route.acbr.nfe.regRouter;
  LogInfo('  ACBR CTe routes mapped.');
  LogInfo('  ACBR CTe routes mapped.');

  LogRouteMapping('route.acbr.diversos.extenso');
  LogInfo('  ACBR Diversos Extenso routes mapped.');
  LogInfo('  ACBR Diversos Extenso routes mapped.');

  LogRouteMapping('route.acbr.diversos.validador');
  LogInfo('  ACBR Diversos Validador routes mapped.');
  LogInfo('  ACBR Diversos Validador routes mapped.');

  LogRouteMapping('route.acbr.certificados');
  LogInfo('  ACBR Certificados routes mapped.');
  LogInfo('  ACBR Certificados routes mapped.');

  WriteLn('-------------------------------------------------------');
  LogInfo('Horse application successfully started.');
  LogInfo(Format('Listening on port %d', [cAppPort]));
  WriteLn('-------------------------------------------------------');

  THorse.Listen(cAppPort);
  LogInfo('ACBRWebService application stopped.');

End.
