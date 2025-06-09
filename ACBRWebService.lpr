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
  route.acbr.certificados,
  route.acbr.cte,
  route.acbr.mdfe,
  method.acbr.mdfe;

  procedure LogInfo(const AMessage: string);
  begin
    WriteLn(AMessage);
  end;

  procedure LogRouteMapping(const AModuleName: string);
  begin
  end;

const
  cAppPort = 9000; // Define a porta como constante para fÃ¡cil referÃªncia
  // Define a porta como constante para fácil referência
begin

  WriteLn('-------------------------------------------------------');
  LogInfo('Starting ACBRWebService application...');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing middleware...');
  THorse.Use(Jhonson);
  LogInfo(' Json middleware initialized.');
  THorse.Use(HandleException);
  LogInfo(' HandleException middleware initialized.');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing routes...');

  LogRouteMapping('route.acbr.nfe');
  route.acbr.nfe.regRouter;
  LogInfo('  ACBR NFe routes mapped.');

  LogRouteMapping('route.acbr.cte');
  route.acbr.cte.regrouter;
  LogInfo('  ACBR CTe routes mapped.');

  LogRouteMapping('route.acbr.mdfe');
  route.acbr.mdfe.regrouter;
  LogInfo('  ACBR MDFe routes mapped.');

  LogRouteMapping('route.acbr.diversos.extenso');
  route.acbr.diversos.extenso.regRouter;
  LogInfo('  ACBR Diversos Extenso routes mapped.');

  LogRouteMapping('route.acbr.diversos.validador');
  route.acbr.diversos.validador.regRouter;
  LogInfo('  ACBR Diversos Validador routes mapped.');

  LogRouteMapping('route.acbr.certificados');
  route.acbr.certificados.regRouter;
  LogInfo('  ACBR Certificados routes mapped.');

  WriteLn('-------------------------------------------------------');
  LogInfo('Horse application successfully started.');
  LogInfo(Format('Listening on port %d', [cAppPort]));
  WriteLn('-------------------------------------------------------');

  THorse.Listen(cAppPort);
  LogInfo('ACBRWebService application stopped.');

end.
