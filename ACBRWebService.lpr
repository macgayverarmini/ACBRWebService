program ACBRWebService;

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
  method.acbr.mdfe,
  resource.strings.global,
  resource.strings.msg,
  resource.strings.routes;

  procedure LogInfo(const AMessage: string);
  begin
    WriteLn(AMessage);
  end;

  procedure LogRouteMapping(const AModuleName: string);
  begin
  end;

const
  cAppPort = 9000;

  {$R *.res}

begin

  WriteLn(RSSeparatorLine);
  LogInfo(RSStartingApplication);
  WriteLn(RSSeparatorLine);

  LogInfo(RSInitializingMiddleware);
  THorse.Use(Jhonson);
  LogInfo(RSJsonMiddlewareInitialized);
  THorse.Use(HandleException);
  LogInfo(RSHandleExceptionMiddlewareInitialized);
  WriteLn(RSSeparatorLine);

  LogInfo(RSInitializingRoutes);

  LogRouteMapping('route.acbr.nfe');
  route.acbr.nfe.regRouter;
  LogInfo(RSACBRNFeRoutesMapped);

  LogRouteMapping('route.acbr.cte');
  route.acbr.cte.regrouter;
  LogInfo(RSACBRCTeRoutesMapped);

  LogRouteMapping('route.acbr.mdfe');
  route.acbr.mdfe.regrouter;
  LogInfo(RSACBRMDFeRoutesMapped);

  LogRouteMapping('route.acbr.diversos.extenso');
  route.acbr.diversos.extenso.regRouter;
  LogInfo(RSACBRDiversosExtensoRoutesMapped);

  LogRouteMapping('route.acbr.diversos.validador');
  route.acbr.diversos.validador.regRouter;
  LogInfo(RSACBRDiversosValidadorRoutesMapped);

  LogRouteMapping('route.acbr.certificados');
  route.acbr.certificados.regRouter;
  LogInfo(RSACBRCertificadosRoutesMapped);

  WriteLn(RSSeparatorLine);
  LogInfo(RSHorseApplicationStarted);
  LogInfo(Format(RSListeningOnPort, [cAppPort]));
  WriteLn(RSSeparatorLine);


  THorse.Listen(cAppPort);
  LogInfo(RSApplicationStopped);

end.
