program ACBRWebService;

{$mode Delphi}
uses
  {$ifdef unix}
  cthreads,
  Math,
  {$endif}
  Interfaces,
  SysUtils,
  Classes,
  Horse,
  Horse.HandleException,
  route.acbr.nfe,
  route.acbr.nfse,
  route.acbr.diversos.extenso,
  route.acbr.diversos.validador,
  route.acbr.certificados,
  route.acbr.cte,
  route.acbr.mdfe,
  route.acbr.ciot,
  route.acbr.esocial,
  route.acbr.bpe,
  route.acbr.sped,
  route.acbr.sintegra,
  route.acbr.escpos,
  route.acbr.boleto,
  route.acbr.reinf,
  route.acbr.gnre,
  route.acbr.diversos.legado,
  resource.strings.global,
  resource.strings.msg;

  procedure LogInfo(const AMessage: string);
  begin
    WriteLn(AMessage);
  end;

const
  cAppPort = 9002;

{$DEFINE UseGenerics}

begin
  {$ifdef unix}
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  {$endif}

  WriteLn(RSSeparatorLine);
  LogInfo(RSStartingApplication);
  WriteLn(RSSeparatorLine);

  LogInfo(RSInitializingMiddleware);
  THorse.Use(HandleException);
  LogInfo(RSHandleExceptionMiddlewareInitialized);
  WriteLn(RSSeparatorLine);

  LogInfo(RSInitializingRoutes);

  route.acbr.nfe.regRouter;
  LogInfo(RSACBRNFeRoutesMapped);

  route.acbr.nfse.regRouter;
  LogInfo(RSACBRNFSeRoutesMapped);

  route.acbr.cte.regRouter;
  LogInfo(RSACBRCTeRoutesMapped);

  route.acbr.mdfe.regRouter;
  LogInfo(RSACBRMDFeRoutesMapped);

  route.acbr.diversos.extenso.regRouter;
  LogInfo(RSACBRDiversosExtensoRoutesMapped);

  route.acbr.diversos.validador.regRouter;
  LogInfo(RSACBRDiversosValidadorRoutesMapped);

  route.acbr.certificados.regRouter;
  LogInfo(RSACBRCertificadosRoutesMapped);

  route.acbr.ciot.regRouter;
  LogInfo(RSACBRCIOTRoutesMapped);

  route.acbr.esocial.regRouter;
  LogInfo(RSACBReSocialRoutesMapped);

  route.acbr.bpe.regRouter;
  LogInfo(RSACBRBPeRoutesMapped);

  route.acbr.sped.regRouter;
  LogInfo(RSACBRSPEDRoutesMapped);

  route.acbr.sintegra.regRouter;
  LogInfo(RSACBRSintegraRoutesMapped);

  route.acbr.escpos.regRouter;
  LogInfo(RSACBREscPosRoutesMapped);

  route.acbr.boleto.regRouter;
  LogInfo(RSACBRBoletoRoutesMapped);

  route.acbr.reinf.regRouter;
  LogInfo(RSACBRReinfRoutesMapped);

  route.acbr.gnre.regRouter;
  LogInfo(RSACBRGNRERoutesMapped);

  route.acbr.diversos.legado.regRouter;
  LogInfo(RSACBRDiversosLegadoRoutesMapped);

  WriteLn(RSSeparatorLine);
  LogInfo(RSHorseApplicationStarted);
  LogInfo(Format(RSListeningOnPort, [cAppPort]));
  WriteLn(RSSeparatorLine);


  THorse.Listen(cAppPort);
  LogInfo(RSApplicationStopped);

end.
