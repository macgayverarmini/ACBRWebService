unit resource.strings.routes;

{$mode Delphi}{$H+}

interface

resourcestring
  // Rotas - NFe
  RSModeloNFeConfigRoute = '/modelo/nfe/config';
  RSModeloNFeEventoRoute = '/modelo/nfe/evento';
  RSModeloNFeDistribuicaoRoute = '/modelo/nfe/distribuicao';
  RSModeloNFeNFeRoute = '/modelo/nfe/nfe';
  RSNFeEventosRoute = '/nfe/eventos';
  RSNFeDistribuicaoRoute = '/nfe/distribuicao';
  RSNFeDANFeRoute = '/nfe/danfe';
  RSNFeNFeRoute = '/nfe/nfe';
  RSNFeStatusRoute = '/nfe/status';
  RSNFeConsultaRoute = '/nfe/consulta';
  RSNFeInutilizacaoRoute = '/nfe/inutilizacao';
  RSNFeCancelamentoRoute = '/nfe/cancelamento';
  RSNFeNFeFromXMLRoute = '/nfe/nfe-from-xml';
  RSNFeNFeToXMLRoute = '/nfe/nfe-to-xml';
  RSNFeValidarRegrasRoute = '/nfe/validar-regras';
  RSNFeDanfeEventoRoute = '/nfe/danfe-evento';
  RSNFeDanfeEscPosRoute = '/nfe/danfe-escpos';
  RSNFeConsultaCadastroRoute = '/nfe/consulta-cadastro';
  RSNFeEmailRoute = '/nfe/email';
  RSModeloNFeStatusRoute = '/modelo/nfe/status';
  RSModeloNFeConsultaRoute = '/modelo/nfe/consulta';
  RSModeloNFeInutilizacaoRoute = '/modelo/nfe/inutilizacao';
  RSModeloNFeCancelamentoRoute = '/modelo/nfe/cancelamento';
  RSModeloNFeNFeFromXMLRoute = '/modelo/nfe/nfe-from-xml';
  RSModeloNFeNFeToXMLRoute = '/modelo/nfe/nfe-to-xml';
  RSModeloNFeValidarRegrasRoute = '/modelo/nfe/validar-regras';
  RSModeloNFeDanfeEventoRoute = '/modelo/nfe/danfe-evento';
  RSModeloNFeDanfeEscPosRoute = '/modelo/nfe/danfe-escpos';
  RSModeloNFeConsultaCadastroRoute = '/modelo/nfe/consulta-cadastro';
  RSModeloNFeEmailRoute = '/modelo/nfe/email';
  
  // Rotas - CTe
  RSModeloCTeConfigRoute = '/modelo/cte/config';
  RSModeloCTeEventoRoute = '/modelo/cte/evento';
  RSModeloCTeDistribuicaoRoute = '/modelo/cte/distribuicao';
  RSModeloCTeCTeRoute = '/modelo/cte/cte';
  RSModeloCTeStatusRoute = '/modelo/cte/status';
  RSModeloCTeConsultaRoute = '/modelo/cte/consulta';
  RSModeloCTeInutilizacaoRoute = '/modelo/cte/inutilizacao';
  RSModeloCTeCancelamentoRoute = '/modelo/cte/cancelamento';
  RSModeloCTeCTeFromXMLRoute = '/modelo/cte/cte-from-xml';
  RSModeloCTeCTeToXMLRoute = '/modelo/cte/cte-to-xml';
  RSCTeEventosRoute = '/cte/eventos';
  RSCTeDistribuicaoRoute = '/cte/distribuicao';
  RSCTeDACTERoute = '/cte/dacte';
  RSCTeCTeRoute = '/cte/cte';
  RSCTeStatusRoute = '/cte/status';
  RSCTeConsultaRoute = '/cte/consulta';
  RSCTeInutilizacaoRoute = '/cte/inutilizacao';
  RSCTeCancelamentoRoute = '/cte/cancelamento';
  RSCTeCTeFromXMLRoute = '/cte/cte-from-xml';
  RSCTeCTeToXMLRoute = '/cte/cte-to-xml';
  RSCTeValidarRegrasRoute = '/cte/validar-regras';
  RSCTeDACTEEventoRoute = '/cte/dacte-evento';
  RSModeloCTeValidarRegrasRoute = '/modelo/cte/validar-regras';
  RSModeloCTeDACTEEventoRoute = '/modelo/cte/dacte-evento';
  
  // Rotas - NFSe
  RSModeloNFSeConfigRoute = '/modelo/nfse/config';
  RSModeloNFSeEmitirRoute = '/modelo/nfse/emitir';
  RSModeloNFSeConsultarSituacaoRoute = '/modelo/nfse/consultarsituacao';
  RSModeloNFSeConsultarLoteRoute = '/modelo/nfse/consultarlote';
  RSModeloNFSeConsultarNFSePorRpsRoute = '/modelo/nfse/consultarnfseporrps';
  RSModeloNFSeConsultarNFSeRoute = '/modelo/nfse/consultarnfse';
  RSModeloNFSeCancelarRoute = '/modelo/nfse/cancelar';
  RSModeloNFSeSubstituirRoute = '/modelo/nfse/substituir';
  RSModeloNFSeNFSeFromXMLRoute = '/modelo/nfse/nfse-from-xml';
  RSModeloNFSeNFSeToXMLRoute = '/modelo/nfse/nfse-to-xml';
  RSNFSeEmitirRoute = '/nfse/emitir';
  RSNFSeGerarRoute = '/nfse/gerar';
  RSNFSeConsultarSituacaoRoute = '/nfse/consultarsituacao';
  RSNFSeConsultarLoteRoute = '/nfse/consultarlote';
  RSNFSeConsultarNFSePorRpsRoute = '/nfse/consultarnfseporrps';
  RSNFSeConsultarNFSeRoute = '/nfse/consultarnfse';
  RSNFSeCancelarRoute = '/nfse/cancelar';
  RSNFSeSubstituirRoute = '/nfse/substituir';
  RSNFSeDANFSeRoute = '/nfse/danfse';
  RSNFSeDistribuicaoRoute = '/nfse/distribuicao';
  RSNFSeNFSeFromXMLRoute = '/nfse/nfse-from-xml';
  RSNFSeNFSeToXMLRoute = '/nfse/nfse-to-xml';
  // Rotas - MDFe
  RSModeloMDFeConfigRoute = '/modelo/mdfe/config';
  RSModeloMDFeEventoRoute = '/modelo/mdfe/evento';
  RSModeloMDFeMDFeRoute = '/modelo/mdfe/mdfe';
  RSModeloMDFeDistribuicaoRoute = '/modelo/mdfe/distribuicao';
  RSMDFeMDFeRoute = '/mdfe/mdfe';
  RSMDFeEventosRoute = '/mdfe/eventos';
  RSMDFeDAMDFeRoute = '/mdfe/damdfe';
  RSMDFeDistribuicaoRoute = '/mdfe/distribuicao';  RSModeloMDFeMDFeFromXMLRoute = '/modelo/mdfe/mdfe-from-xml';
  RSModeloMDFeMDFeToXMLRoute = '/modelo/mdfe/mdfe-to-xml';
  RSMDFeMDFeFromXMLRoute = '/mdfe/mdfe-from-xml';
  RSMDFeMDFeToXMLRoute = '/mdfe/mdfe-to-xml';  RSMDFeDAMDFeEventoRoute = '/mdfe/damdfe-evento';
  RSMDFePDFRoute = '/mdfe/pdf/:chave';  RSMDFeDAMDFeURLRoute = '/mdfe/damdfe-url';
  RSCTeDACTEURLRoute = '/cte/dacte-url';
  RSNFeDANFeURLRoute = '/nfe/danfe-url';
  RSNFSeDANFSeURLRoute = '/nfse/danfse-url';
  
  // Rotas - Certificados
  RSCertificadosUploadRoute = '/certificados/upload';
  RSCertificadosLerDadosRoute = '/certificados/ler-dados';
  
  // Rotas - Diversos
  RSModeloDiversosValidadorRoute = '/modelo/diversos/validador';
  RSDiversosValidadorRoute = '/diversos/validador';
  RSModeloDiversosExtensoRoute = '/modelo/diversos/extenso';
  RSDiversosExtensoRoute = '/diversos/extenso';

  // Rotas - CIOT
  RSModeloCIOTConfigRoute = '/modelo/ciot/config';
  RSCIOTRoute = '/ciot/ciot';
  RSCIOTEnviarRoute = '/ciot/enviar';

  // Rotas - eSocial
  RSModeloeSocialConfigRoute = '/modelo/esocial/config';
  RSeSocialRoute = '/esocial/esocial';
  RSeSocialEnviarRoute = '/esocial/enviar';

  // Rotas - BPe
  RSModeloBPeConfigRoute = '/modelo/bpe/config';
  RSBPeRoute = '/bpe/bpe';
  RSBPeEnviarRoute = '/bpe/enviar';

  // Rotas - SPED
  RSModeloSPEDConfigRoute = '/modelo/sped/config';
  RSSPEDRoute = '/sped/sped';
  RSSPEDGerarRoute = '/sped/gerar';
  RSSPEDFiscalImportarRoute = '/sped/importar';

  // Rotas - Sintegra
  RSModeloSintegraConfigRoute = '/modelo/sintegra/config';
  RSSintegraRoute = '/sintegra/sintegra';
  RSSintegraGerarRoute = '/sintegra/gerar';

  // Rotas - EscPos
  RSModeloEscPosConfigRoute = '/modelo/escpos/config';
  RSEscPosRoute = '/escpos/escpos';
  RSEscPosPortasRoute = '/escpos/portas';

  // Rotas Adicionais - MDFe
  RSModeloMDFeStatusRoute = '/modelo/mdfe/status';
  RSModeloMDFeConsultaRoute = '/modelo/mdfe/consulta';
  RSModeloMDFeCancelamentoRoute = '/modelo/mdfe/cancelamento';
  RSModeloMDFeEncerramentoRoute = '/modelo/mdfe/encerramento';
  RSModeloMDFeNaoEncerradosRoute = '/modelo/mdfe/nao-encerrados';
  RSMDFeStatusRoute = '/mdfe/status';
  RSMDFeConsultaRoute = '/mdfe/consulta';
  RSMDFeCancelamentoRoute = '/mdfe/cancelamento';
  RSMDFeEncerramentoRoute = '/mdfe/encerramento';
  RSMDFeNaoEncerradosRoute = '/mdfe/nao-encerrados';

  // Rotas Adicionais - SPED PIS/COFINS
  RSModeloSPEDPisCofinsConfigRoute = '/modelo/sped/piscofins/config';
  RSSPEDPisCofinsGerarRoute = '/sped/piscofins/gerar';
  RSSPEDPisCofinsImportarRoute = '/sped/piscofins/importar';
  RSSPEDPisCofinsConsolidarRoute = '/sped/piscofins/consolidar';

  // Rotas - Boleto Bancario
  RSModeloBoletoConfigRoute = '/modelo/boleto/config';
  RSModeloBoletoTituloRoute = '/modelo/boleto/titulo';
  RSBoletoPDFRoute = '/boleto/pdf';
  RSBoletoRemessaRoute = '/boleto/remessa';
  RSBoletoRetornoRoute = '/boleto/retorno';
  RSBoletoEnviarRoute = '/boleto/enviar';
  RSModeloBoletoPixQRCodeRoute = '/modelo/boleto/pix-qrcode';
  RSBoletoPixQRCodeRoute = '/boleto/pix-qrcode';

  // Rotas - EFD-Reinf
  RSModeloReinfConfigRoute = '/modelo/reinf/config';
  RSReinfEnviarRoute = '/reinf/enviar';
  RSReinfConsultarRoute = '/reinf/consultar';

  // Rotas - GNRE
  RSModeloGNREConfigRoute = '/modelo/gnre/config';
  RSModeloGNREGuiaRoute = '/modelo/gnre/guia';
  RSGNREEnviarRoute = '/gnre/enviar';
  RSGNREConsultarRoute = '/gnre/consultar';

  // Rotas - Diversos Legado (CMC7, Balanca InStore, CargaBal, IBPTax)
  RSModeloDiversosCMC7Route = '/modelo/diversos/cmc7';
  RSDiversosCMC7Route = '/diversos/cmc7';
  RSModeloDiversosInStoreRoute = '/modelo/diversos/balanca/instore';
  RSDiversosInStoreRoute = '/diversos/balanca/instore';
  RSModeloDiversosCargaBalRoute = '/modelo/diversos/balanca/carga';
  RSDiversosCargaBalRoute = '/diversos/balanca/carga';
  RSModeloDiversosIBPTRoute = '/modelo/diversos/ibpt/config';
  RSDiversosIBPTLerTabelaRoute = '/diversos/ibpt/ler-tabela';
  RSNFePDFRoute = '/nfe/pdf/:chave';
  RSNFSeEventoRoute = '/nfse/evento';
  RSModeloNFSeEventoRoute = '/modelo/nfse/evento';
  RSModeloSPEDPisCofinsImportarRoute = '/modelo/sped/piscofins/importar';
  RSBoletoPixEMVRoute = '/boleto/pix-emv';
  RSModeloBoletoPixEMVRoute = '/modelo/boleto/pix-emv';
  RSModeloDiversosEADRoute = '/modelo/diversos/ead';
  RSDiversosEADRoute = '/diversos/ead';
  RSModeloDiversosCalcDigitoRoute = '/modelo/diversos/calc-digito';
  RSDiversosCalcDigitoRoute = '/diversos/calc-digito';
  RSModeloDiversosMailRoute = '/modelo/diversos/mail';
  RSDiversosMailRoute = '/diversos/mail';

implementation

end.


