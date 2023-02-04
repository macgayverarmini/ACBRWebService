{$MODE DELPHI}{$H+}
program ACBRWebService;

uses
  Interfaces, Horse, Horse.Jhonson,
  Horse.HandleException, route.acbr.nfe,
   route.acbr.diversos.extenso,
  route.acbr.diversos.validador, method.acbr.diversos.validador;

begin
  THorse.Use(Jhonson);
  THorse.Use(HandleException);
  route.acbr.nfe.regRouter;
  route.acbr.diversos.extenso.regRouter;
  route.acbr.diversos.validador.regRouter;
  THorse.Listen(9000);



end.

