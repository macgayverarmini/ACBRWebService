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

    if MARKER in normalized:
        print(f"{target}: GerarRegistros90 multi-line chunking patch already applied (no-op).")
        return 0

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

    updated = normalized[: match.start()] + NEW_PROC + "\n" + normalized[match.end() :]
    if use_crlf:
        updated = updated.replace("\n", "\r\n")

    target.write_bytes(updated.encode(encoding))
    print(f"{target}: Patched TACBrSintegra.GerarRegistros90 successfully ({encoding}, crlf={use_crlf}).")
    return 0


def main() -> int:
    target = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else resolve_default_target()
    return patch_file(target)


if __name__ == "__main__":
    sys.exit(main())
