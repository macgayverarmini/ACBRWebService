#!/bin/bash
# Diagnostic: write a small Pascal test to check RTTI visibility
cat > /tmp/test_rtti_cte.pas << 'EOF'
program test_rtti_cte;

{$mode Delphi}{$H+}

uses
  SysUtils, Classes, RTTI, TypInfo, fpjson,
  ACBrCTe, ACBrCTe.Classes, ACBrCTeConhecimentos;

var
  acbr: TACBrCTe;
  cte: TCTe;
  Ctx: TRttiContext;
  RttiType: TRttiType;
  Props: array of TRttiProperty;
  i: Integer;
begin
  acbr := TACBrCTe.Create(nil);
  try
    cte := acbr.Conhecimentos.Add.CTe;
    
    WriteLn('=== TCTe Properties via Extended RTTI ===');
    Ctx := TRttiContext.Create;
    try
      RttiType := Ctx.GetType(cte.ClassType);
      if RttiType = nil then
      begin
        WriteLn('ERROR: RttiType is nil for TCTe');
        Exit;
      end;
      
      Props := RttiType.GetProperties;
      WriteLn('Total properties found: ', Length(Props));
      for i := 0 to Length(Props) - 1 do
      begin
        WriteLn(Format('  [%d] %s (Kind=%d Vis=%d Readable=%s)', [
          i,
          Props[i].Name,
          Ord(Props[i].PropertyType.TypeKind),
          Ord(Props[i].Visibility),
          BoolToStr(Props[i].IsReadable, True)
        ]));
      end;
    finally
      Ctx.Free;
    end;
    
    WriteLn('');
    WriteLn('=== TCTe Properties via Classic RTTI (published only) ===');
    WriteLn('PropCount via GetTypeData: ', GetTypeData(cte.ClassInfo)^.PropCount);
    
  finally
    acbr.Free;
  end;
end.
EOF

cd /home/datalider/workspace/src
/home/datalider/development/fpc/bin/x86_64-linux/fpc \
  -MObjFPC -Sh \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrCTe/Base/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrCTe/Base/Servicos/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrCTe/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrCTe/DACTE/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrDFeXs/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrComum/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrNFe/PCNNFe/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrCTe/PCNCTe/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrNFSeX/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrTXT/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrSerial/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrTCP/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrOpenSSL/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrBPe/PCNBPe/ \
  -Fu/home/datalider/workspace/acbr/Fontes/ACBrDFe/ACBrMDFe/PCNMDFe/ \
  -FE/tmp \
  /tmp/test_rtti_cte.pas 2>&1 | tail -10

if [ -f /tmp/test_rtti_cte ]; then
  echo "=== Running ==="
  /tmp/test_rtti_cte 2>&1
fi
