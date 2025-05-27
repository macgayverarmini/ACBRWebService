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
  router.acbr.cte;

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
  THorse.Use(Jhonson);
  THorse.Use(HandleException);

  WriteLn('-------------------------------------------------------');
  LogInfo('Starting ACBRWebService application...');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing middleware...');
  LogInfo(' Json middleware initialized.');
  LogInfo(' HandleException middleware initialized.');
  WriteLn('-------------------------------------------------------');

  LogInfo('Initializing routes...');
  LogRouteMapping('route.acbr.nfe');
  LogInfo('  ACBR NFe routes mapped.');
  LogRouteMapping('route.acbr.cte');
  route.acbr.nfe.regRouter;
  LogInfo('  ACBR CTe routes mapped.');
  LogRouteMapping('route.acbr.diversos.extenso');
  router.acbr.cte.regrouter;
  LogInfo('  ACBR Diversos Extenso routes mapped.');
  route.acbr.diversos.extenso.regRouter;
  LogInfo('  ACBR Diversos Validador routes mapped.');
  route.acbr.certificados.regRouter;
  WriteLn('-------------------------------------------------------');
  LogInfo('Horse application successfully started.');
  LogInfo(Format('Listening on port %d', [cAppPort]));
  WriteLn('-------------------------------------------------------');

  THorse.Listen(cAppPort);
  LogInfo('ACBRWebService application stopped.');

end.
