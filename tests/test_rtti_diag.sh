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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
ACBR_FONTES="${ACBR_FONTES_DIR:-$REPO_SRC/../acbr/Fontes}"
FPC_BIN="${FPC_COMPILER:-$HOME/development/fpc/bin/x86_64-linux/fpc}"

cd "$REPO_SRC"
"$FPC_BIN" \
  -MObjFPC -Sh \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrCTe/Base/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrCTe/Base/Servicos/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrCTe/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrCTe/DACTE/" \
  -Fu"$ACBR_FONTES/ACBrDFe/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrDFeXs/" \
  -Fu"$ACBR_FONTES/ACBrComum/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrNFe/PCNNFe/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrCTe/PCNCTe/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrNFSeX/" \
  -Fu"$ACBR_FONTES/ACBrTXT/" \
  -Fu"$ACBR_FONTES/ACBrSerial/" \
  -Fu"$ACBR_FONTES/ACBrTCP/" \
  -Fu"$ACBR_FONTES/ACBrOpenSSL/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrBPe/PCNBPe/" \
  -Fu"$ACBR_FONTES/ACBrDFe/ACBrMDFe/PCNMDFe/" \
  -FE/tmp \
  /tmp/test_rtti_cte.pas 2>&1 | tail -10

if [ -f /tmp/test_rtti_cte ]; then
  echo "=== Running ==="
  /tmp/test_rtti_cte 2>&1
fi
