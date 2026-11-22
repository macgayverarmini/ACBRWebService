program test_cert;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  ACBrNFe, ACBrDFeConfiguracoes;

var
  ACBrNFe1: TACBrNFe;
begin
  WriteLn('Iniciando...');
  ACBrNFe1 := TACBrNFe.Create(nil);
  try
    ACBrNFe1.Configuracoes.Geral.SSLLib := libOpenSSL;
    ACBrNFe1.Configuracoes.Geral.SSLCryptLib := cryOpenSSL;
    ACBrNFe1.Configuracoes.Geral.SSLHttpLib := httpWinHttp;
    ACBrNFe1.Configuracoes.Geral.SSLXmlSignLib := xsLibXml2;
    
    ACBrNFe1.Configuracoes.Certificados.ArquivoPFX := GetEnvironmentVariable('ACBR_DEFAULT_CERT_PATH');
    if ACBrNFe1.Configuracoes.Certificados.ArquivoPFX = '' then
      ACBrNFe1.Configuracoes.Certificados.ArquivoPFX := 'c:\caminho\para\certificado.pfx';
    ACBrNFe1.Configuracoes.Certificados.Senha := GetEnvironmentVariable('ACBR_DEFAULT_CERT_PASSWORD');
    
    WriteLn('Carregando certificado...');
    try
      ACBrNFe1.SSL.CarregarCertificado;
      WriteLn('Certificado carregado com sucesso!');
      WriteLn('Subject: ', ACBrNFe1.SSL.CertSubjectName);
      WriteLn('Validade: ', DateToStr(ACBrNFe1.SSL.CertDataVenc));
    except
      on E: Exception do
        WriteLn('Erro ao carregar: ', E.Message);
    end;
  finally
    ACBrNFe1.Free;
  end;
  WriteLn('Fim.');
end.
