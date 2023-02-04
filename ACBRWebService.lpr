{$MODE DELPHI}{$H+}
program ACBRWebService;

uses Interfaces,
     Horse,
     Horse.Jhonson,
     Horse.HandleException,
     route.acbr.nfe,
     route, jsonconvert,
     method.acbr.nfe, method.acbr.diversos.extenso, route.acbr.diversos.extenso;

begin
  THorse.Use(Jhonson);
  THorse.Use(HandleException);
  route.acbr.nfe.regRouter;
  route.acbr.diversos.extenso.regRouter;
  THorse.Listen(9000);
end.

