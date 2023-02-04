{$MODE DELPHI}{$H+}
program ACBRWebService;

uses Interfaces,
     Horse,
     Horse.Jhonson,
     Horse.HandleException,
     route.acbr.nfe,
     route, jsonconvert,
     method.acbr.nfe;

begin
  THorse.Use(Jhonson);
  THorse.Use(HandleException);
  route.acbr.nfe.regRouter;
  THorse.Listen(9000);
end.

