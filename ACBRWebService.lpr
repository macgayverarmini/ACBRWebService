program ACBRWebService;

{$mode Delphi}
uses
  {$ifdef unix}
  cthreads,
  {$endif}
  Interfaces,
  SysUtils,
  Horse,
  Horse.Jhonson,
  Horse.HandleException,
  route.acbr.nfe,
  route.acbr.nfse,
  route.acbr.diversos.extenso,
  route.acbr.diversos.validador,
  route.acbr.certificados,
  route.acbr.cte,
  route.acbr.mdfe,
  method.acbr.mdfe,
  route.acbr.ciot,
  route.acbr.esocial,
  route.acbr.bpe,
  route.acbr.sped,
  route.acbr.sintegra,
  route.acbr.escpos,
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
  cAppPort = 9001;



{$DEFINE UseGenerics}

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

  LogRouteMapping('route.acbr.nfse');
  route.acbr.nfse.regRouter;
  LogInfo(RSACBRNFSeRoutesMapped);

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

  LogRouteMapping('route.acbr.ciot');
  route.acbr.ciot.regRouter;

  LogRouteMapping('route.acbr.esocial');
  route.acbr.esocial.regRouter;

  LogRouteMapping('route.acbr.bpe');
  route.acbr.bpe.regRouter;

  LogRouteMapping('route.acbr.sped');
  route.acbr.sped.regRouter;

  LogRouteMapping('route.acbr.sintegra');
  route.acbr.sintegra.regRouter;

  LogRouteMapping('route.acbr.escpos');
  route.acbr.escpos.regRouter;

  WriteLn(RSSeparatorLine);
  LogInfo(RSHorseApplicationStarted);
  LogInfo(Format(RSListeningOnPort, [cAppPort]));
  WriteLn(RSSeparatorLine);


  THorse.Listen(cAppPort);
  LogInfo(RSApplicationStopped);

end.
