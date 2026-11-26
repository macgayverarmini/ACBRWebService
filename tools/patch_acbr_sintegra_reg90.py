#!/usr/bin/env python3
"""
Idempotent upstream bugfix for TACBrSintegra.GerarRegistros90 in ACBrSintegra.pas.

Upstream issue:
  TACBrSintegra.GerarRegistros90 appends all active record-type totalizers onto a
  single '90' line without chunking. Under Convenio ICMS 57/95 (item 20.1.9), each
  Registro 90 line fits at most 9 (tipo, total) pairs in columns 31..120 before
  padding to 125 and writing total Registro 90 count in column 126. When >9 record
  types have Count > 0, Length(wregistro) exceeds 125 and WriteRecord raises
  'Registro invalido! Deve conter 126 posicoes'.

Fix:
  Emit active (tipo, total) pairs in chunks of at most 9 pairs per Registro 90 line,
  followed by the '99' totalizer line, setting WSeque90 (total Registro 90 lines in
  col 126) and WTotal90 (10 + 11 + all 90 lines) accurately across all lines.
"""

from __future__ import annotations

import pathlib
import re
import sys

MARKER = "WPares: array[0..16] of string;"

NEW_PROC = """procedure TACBrSintegra.GerarRegistros90;
var
  wregistro, WPrefixo90: string;
  WTotal60, WTotal60A, WTotal60D, WTotal60I, WTotal61: Integer;
  wtotal88: Integer;
  WTotal90: Integer;
  WSeque90: Integer;
  WPares: array[0..16] of string;
  WParesCount, WIdx, WCountChunk: Integer;
  I: Integer;

  procedure AddPar90(const ATipo: string; const ACount: Integer);
  begin
    if ACount > 0 then
    begin
      WPares[WParesCount] := ATipo + TBStrZero(IntToStr(ACount), 8);
      Inc(WParesCount);
    end;
  end;

begin
  WPrefixo90 := '90' + TBStrZero(TiraPontos(Registro10.CNPJ), 14) +
    PadRight(TiraPontos(Registro10.Inscricao), 14);
  WParesCount := 0;

  AddPar90('50', Registros50.Count);
  AddPar90('51', Registros51.Count);
  AddPar90('53', Registros53.Count);
  AddPar90('54', Registros54.Count);
  AddPar90('55', Registros55.Count);
  AddPar90('56', Registros56.Count);

  if FVersaoValidador = vv524 then
  begin
    WTotal60A := 0;
    WTotal60D := 0;
    WTotal60I := 0;
    for I := 0 to (Registros60M.Count - 1) do
    begin
      WTotal60A := WTotal60A + Registros60M[I].Regs60A.Count;
      WTotal60D := WTotal60D + Registros60M[I].Regs60D.Count;
      WTotal60I := WTotal60I + Registros60M[I].Regs60I.Count;
    end;
  end
  else
  begin
    WTotal60A := Registros60A.Count;
    WTotal60D := Registros60D.Count;
    WTotal60I := Registros60I.Count;
  end;

  WTotal60 := Registros60M.Count + WTotal60A + WTotal60D + WTotal60I + Registros60R.Count;
  AddPar90('60', WTotal60);

  WTotal61 := Registros61.Count + Registros61R.Count;
  AddPar90('61', WTotal61);

  AddPar90('70', Registros70.Count);
  AddPar90('71', Registros71.Count);
  AddPar90('74', Registros74.Count);
  AddPar90('75', Registros75.Count);
  AddPar90('76', Registros76.Count);
  AddPar90('77', Registros77.Count);
  AddPar90('85', Registros85.Count);
  AddPar90('86', Registros86.Count);

  //totalizador para registros 88
  wtotal88 := 0;
  if FInforma88EAN then
    wtotal88 := wtotal88 + Registros88Ean.Count;

  if Trim(Registro88EC.CRCContabilista) <> '' then
    Inc(wtotal88);
  if Trim(Registro88SF.FCNPJEmpresa) <> '' then
    Inc(wtotal88);

  if FInforma88SME then
    Inc(wtotal88);

  if FInforma88SMS then
    Inc(wtotal88);

  if FRegistros88STES.Count > 0 then
    wtotal88 := wtotal88 + FRegistros88STES.Count;

  if FRegistros88STITNF.Count > 0 then
    wtotal88 := wtotal88 + FRegistros88STITNF.Count;

  if FInforma88C then
  begin
    wtotal88 := wtotal88 + Registros88C.Count;
    wtotal88 := wtotal88 + Registros88D.Count;
    wtotal88 := wtotal88 + Registros88E.Count;
    wtotal88 := wtotal88 + Registros88T.Count;
  end;

  if FInformaSapiMG then
  begin
    wtotal88 := wtotal88 + Registros88SP02.Count;
    wtotal88 := wtotal88 + Registros88SP03.Count;
  end;

  AddPar90('88', wtotal88);

  if WParesCount > 0 then
    WSeque90 := ((WParesCount - 1) div 9) + 2
  else
    WSeque90 := 1;
  WTotal90 := 2 + WSeque90;

  WIdx := 0;
  while WIdx < WParesCount do
  begin
    wregistro := WPrefixo90;
    WCountChunk := 0;
    while (WIdx < WParesCount) and (WCountChunk < 9) do
    begin
      wregistro := wregistro + WPares[WIdx];
      Inc(WIdx);
      Inc(WCountChunk);
    end;
    wregistro := wregistro + Space(125 - Length(wregistro)) + IntToStr(WSeque90);
    WriteRecord(wregistro);
  end;

  wregistro := WPrefixo90 + '99' + TBStrZero(IntToStr(
    Registros50.Count + Registros51.Count +
    Registros53.Count + Registros54.Count + Registros55.Count + Registros56.Count +
    WTotal60 + WTotal61 +
    Registros70.Count + Registros71.Count +
    Registros74.Count + Registros75.Count + Registros76.Count + Registros77.Count +
    Registros85.Count + Registros86.Count + wtotal88 + WTotal90), 8);
  wregistro := wregistro + Space(125 - Length(wregistro)) + IntToStr(WSeque90);
  WriteRecord(wregistro);
end;"""


CP1252_MARKER = "function SintegraUtf8ToCp1252Raw"

CP1252_HELPERS = """function SintegraUnicodeToCp1252Byte(const ACodePoint: Cardinal): Byte;
begin
  case ACodePoint of
    0..$7F, $A0..$FF: Result := Byte(ACodePoint);
    $20AC: Result := $80;
    $201A: Result := $82;
    $0192: Result := $83;
    $201E: Result := $84;
    $2026: Result := $85;
    $2020: Result := $86;
    $2021: Result := $87;
    $02C6: Result := $88;
    $2030: Result := $89;
    $0160: Result := $8A;
    $2039: Result := $8B;
    $0152: Result := $8C;
    $017D: Result := $8E;
    $2018: Result := $91;
    $2019: Result := $92;
    $201C: Result := $93;
    $201D: Result := $94;
    $2022: Result := $95;
    $2013: Result := $96;
    $2014: Result := $97;
    $02DC: Result := $98;
    $2122: Result := $99;
    $0161: Result := $9A;
    $203A: Result := $9B;
    $0153: Result := $9C;
    $017E: Result := $9E;
    $0178: Result := $9F;
    $80..$9F: Result := Byte(ACodePoint);
  else
    Result := Ord(' ');
  end;
end;

function SintegraIsValidUtf8(const ARaw: RawByteString): Boolean;
var
  I, Len: Integer;
  B, B2, B3, B4: Byte;
begin
  Result := True;
  Len := Length(ARaw);
  I := 1;
  while I <= Len do
  begin
    B := Byte(ARaw[I]);
    if B <= $7F then
      Inc(I)
    else if (B and $E0) = $C0 then
    begin
      if (B < $C2) or (I + 1 > Len) then Exit(False);
      B2 := Byte(ARaw[I + 1]);
      if (B2 and $C0) <> $80 then Exit(False);
      Inc(I, 2);
    end
    else if (B and $F0) = $E0 then
    begin
      if I + 2 > Len then Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      if ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) then Exit(False);
      if (B = $E0) and (B2 < $A0) then Exit(False);
      Inc(I, 3);
    end
    else if (B and $F8) = $F0 then
    begin
      if I + 3 > Len then Exit(False);
      B2 := Byte(ARaw[I + 1]);
      B3 := Byte(ARaw[I + 2]);
      B4 := Byte(ARaw[I + 3]);
      if ((B2 and $C0) <> $80) or ((B3 and $C0) <> $80) or ((B4 and $C0) <> $80) then Exit(False);
      Inc(I, 4);
    end
    else
      Exit(False);
  end;
end;

function SintegraUtf8ToCp1252Raw(const S: string): RawByteString;
var
  InRaw: RawByteString;
  I, Len, OutLen: Integer;
  B, B2, B3, B4: Byte;
  CP: Cardinal;
begin
  InRaw := S;
  if not SintegraIsValidUtf8(InRaw) then
  begin
    Result := InRaw;
    Exit;
  end;
  Len := Length(InRaw);
  SetLength(Result, Len);
  OutLen := 0;
  I := 1;
  while I <= Len do
  begin
    B := Byte(InRaw[I]);
    if B <= $7F then
    begin
      CP := B;
      Inc(I);
    end
    else if (B and $E0) = $C0 then
    begin
      B2 := Byte(InRaw[I + 1]);
      CP := (Cardinal(B and $1F) shl 6) or Cardinal(B2 and $3F);
      Inc(I, 2);
    end
    else if (B and $F0) = $E0 then
    begin
      B2 := Byte(InRaw[I + 1]);
      B3 := Byte(InRaw[I + 2]);
      CP := (Cardinal(B and $0F) shl 12) or (Cardinal(B2 and $3F) shl 6) or Cardinal(B3 and $3F);
      Inc(I, 3);
    end
    else
    begin
      B2 := Byte(InRaw[I + 1]);
      B3 := Byte(InRaw[I + 2]);
      B4 := Byte(InRaw[I + 3]);
      CP := (Cardinal(B and $07) shl 18) or (Cardinal(B2 and $3F) shl 12) or (Cardinal(B3 and $3F) shl 6) or Cardinal(B4 and $3F);
      Inc(I, 4);
    end;
    Inc(OutLen);
    Result[OutLen] := AnsiChar(SintegraUnicodeToCp1252Byte(CP));
  end;
  SetLength(Result, OutLen);
end;

procedure TACBrSintegra.WriteRecord(const Rec: string; vSapiMG : Boolean);
{$IFDEF FPC}
var
  wRecAnsi: RawByteString;
begin
  wRecAnsi := SintegraUtf8ToCp1252Raw(Rec);
  SetCodePage(wRecAnsi, 1252, False);
  if not vSapiMG then
  begin
    if Length(wRecAnsi) <> 126 then
      raise Exception.Create(ACBrStr('Registro inválido!'+#13+
        'Deve conter 126 posições. '+#13+
        'Registro: '+Rec+#13+
        'possui '+IntToStr(Length(wRecAnsi))+' posições.'));
  end;
  write(Arquivo, wRecAnsi + #13+#10 );
end;
{$ELSE}
begin
  //adicionado variavel para checar a geração dos registro para o SAPI MG
  //para não ocorrer problemas com a geração dos outros arquivos somente informo True nesta
  //variavel para os registros SP02 e SP03
  if not vSapiMG then
  begin
    if Length(Rec)<>126 then
      raise Exception.Create(ACBrStr('Registro inválido!'+#13+
        'Deve conter 126 posições. '+#13+
        'Registro: '+Rec+#13+
        'possui '+IntToStr(Length(Rec))+' posições.'));
    // mudança compatibilidade linux
  end;
  write(Arquivo, Rec + #13+#10 );
end;
{$ENDIF}"""


def resolve_default_target() -> pathlib.Path:
    here = pathlib.Path(__file__).resolve()
    return here.parents[2] / "acbr" / "Fontes" / "ACBrTXT" / "ACBrSintegra" / "ACBrSintegra.pas"


def patch_file(target: pathlib.Path) -> int:
    if not target.is_file():
        print(f"ERROR: ACBrSintegra.pas not found at {target}", file=sys.stderr)
        return 1

    raw = target.read_bytes()
    use_crlf = b"\r\n" in raw
    try:
        text = raw.decode("utf-8")
        encoding = "utf-8"
    except UnicodeDecodeError:
        text = raw.decode("cp1252")
        encoding = "cp1252"

    normalized = text.replace("\r\n", "\n")
    changed = False

    if MARKER not in normalized:
        pattern = re.compile(
            r"^procedure TACBrSintegra\.GerarRegistros90;\n"
            r".*?"
            r"^end;\n(?=\nfunction TACBrSintegra\.GetRegistro60M\b)",
            re.MULTILINE | re.DOTALL,
        )
        match = pattern.search(normalized)
        if not match:
            print(
                f"ERROR: Could not locate unpatched TACBrSintegra.GerarRegistros90 block in {target}",
                file=sys.stderr,
            )
            return 1
        normalized = normalized[: match.start()] + NEW_PROC + "\n" + normalized[match.end() :]
        changed = True
    else:
        print(f"{target}: GerarRegistros90 multi-line chunking patch already applied (no-op).")

    if CP1252_MARKER not in normalized:
        wr_pattern = re.compile(
            r"^procedure TACBrSintegra\.WriteRecord\(const Rec: string; vSapiMG : Boolean\);\n"
            r".*?"
            r"^end;\n(?=\nprocedure TACBrSintegra\.GeraArquivo;)",
            re.MULTILINE | re.DOTALL,
        )
        wr_match = wr_pattern.search(normalized)
        if not wr_match:
            print(
                f"ERROR: Could not locate TACBrSintegra.WriteRecord block in {target}",
                file=sys.stderr,
            )
            return 1
        normalized = normalized[: wr_match.start()] + CP1252_HELPERS + "\n" + normalized[wr_match.end() :]
        normalized = normalized.replace(
            "  Rewrite(Arquivo);\n  try",
            "  Rewrite(Arquivo);\n  {$IFDEF FPC}SetTextCodePage(Arquivo, 1252);{$ENDIF}\n  try",
            1,
        )
        for old_copy, new_copy in [
            ("Copy(Registro10.RazaoSocial,1,35)", "LeftStrNativeString(Registro10.RazaoSocial,35)"),
            ("Copy(Registro10.Cidade,1,30)", "LeftStrNativeString(Registro10.Cidade,30)"),
            ("Copy(Registro11.Endereco,1,34)", "LeftStrNativeString(Registro11.Endereco,34)"),
            ("Copy(Registro11.Complemento,1,22)", "LeftStrNativeString(Registro11.Complemento,22)"),
            ("Copy(Registro11.Bairro,1,15)", "LeftStrNativeString(Registro11.Bairro,15)"),
            ("Copy(Registro11.Responsavel,1,28)", "LeftStrNativeString(Registro11.Responsavel,28)"),
            ("Copy(Trim(Registros75[i].Descricao),1,53)", "LeftStrNativeString(Trim(Registros75[i].Descricao),53)"),
        ]:
            normalized = normalized.replace(old_copy, new_copy)
        changed = True
    else:
        print(f"{target}: FPC UTF-8 -> CP1252 WriteRecord patch already applied (no-op).")

    if not changed:
        return 0

    updated = normalized
    if use_crlf:
        updated = updated.replace("\n", "\r\n")

    target.write_bytes(updated.encode(encoding))
    print(f"{target}: Patched TACBrSintegra successfully ({encoding}, crlf={use_crlf}).")
    return 0


def main() -> int:
    target = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else resolve_default_target()
    return patch_file(target)


if __name__ == "__main__":
    sys.exit(main())
