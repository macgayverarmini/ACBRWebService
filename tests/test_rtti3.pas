program test_rtti3;
$mode Delphi$H+
uses SysUtils, jsonconvert, fpjson, ACBrConfiguracoes;

var
  Config: TConfiguracoes;
  J: TJSONObject;
begin
  Config := TConfiguracoes.Create(nil);
  try
    J := TJSONObject.Create;
    J.Add('Geral', TJSONObject.Create);
    J.Objects['Geral'].Add('FormaEmissao', 'teContingencia');
    J.Objects['Geral'].Add('VersaoDF', 've400');
    
    // ACBrConfiguracoes has public properies inside Geral!
    TJSONTools.JsonToObj(J, Config);
    
    Writeln('FormaEmissao: ', GetEnumName(TypeInfo(TpcnTipoEmissao), Ord(Config.Geral.FormaEmissao)));
    Writeln('VersaoDF: ', GetEnumName(TypeInfo(TpcnVersaoDF), Ord(Config.Geral.VersaoDF)));
  finally
    Config.Free;
    J.Free;
  end;
end.
