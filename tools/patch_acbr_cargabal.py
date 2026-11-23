#!/usr/bin/env python3
"""
Idempotent upstream fix for TACBrCargaBal DOS CRLF line endings in ACBrCargaBal.pas.

Upstream issue:
  TACBrCargaBal instantiates 14 output TStringList buffers in GerarArquivos plus 3
  helper LTXTeclas TStringLists in PreencherToledo, PreencherToledoMGV7, and
  PreencherTriunfoRdc429 without setting LineBreak := #13#10. On Unix/Linux,
  TStringList.LineBreak defaults to LF (#10), producing scale load files (.TXT)
  (including TXTECLAS.TXT via stlTeclado.Text := LTXTeclas.Text + stlTeclado.Text)
  without pure DOS CRLF (#13#10) line endings required by scale importers.

Fix:
  Explicitly configure LineBreak := #13#10 on all 3 LTXTeclas helper TStringLists
  and all 14 output TStringList instances in TACBrCargaBal.GerarArquivos.
"""

from __future__ import annotations

import pathlib
import sys

LIST_NAMES = (
    "Produto",
    "Setor",
    "Receita",
    "Tara",
    "Nutricional",
    "RelacaoProdutoNutricional",
    "RelacaoProdutoReceita",
    "Fornecedor",
    "Fracionador",
    "Conservacao",
    "Teclado",
    "Extra1",
    "Extra2",
    "Operador",
)


def resolve_default_target() -> pathlib.Path:
    here = pathlib.Path(__file__).resolve()
    return here.parents[2] / "acbr" / "Fontes" / "ACBrDiversos" / "ACBrCargaBal.pas"


def patch_file(target: pathlib.Path) -> int:
    if not target.is_file():
        print(f"ERROR: ACBrCargaBal.pas not found at {target}", file=sys.stderr)
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

    # 1. Helper LTXTeclas TStringLists in PreencherToledo / MGV7 / TriunfoRdc429
    old_tx_spaced = "  LTXTeclas := TStringList.Create;\n  try"
    new_tx_spaced = "  LTXTeclas := TStringList.Create;\n  LTXTeclas.LineBreak := #13#10;\n  try"
    if new_tx_spaced not in normalized:
        if old_tx_spaced not in normalized:
            print(f"ERROR: Missing '{old_tx_spaced}' in {target}", file=sys.stderr)
            return 1
        normalized = normalized.replace(old_tx_spaced, new_tx_spaced, 1)
        changed = True

    old_tx_compact = "  LTXTeclas:=TStringList.Create;\n  try"
    new_tx_compact = "  LTXTeclas:=TStringList.Create;\n  LTXTeclas.LineBreak := #13#10;\n  try"
    if normalized.count(new_tx_compact) < 2:
        if normalized.count(old_tx_compact) != 2:
            print(
                f"ERROR: Expected 2 occurrences of '{old_tx_compact}' in {target}, "
                f"found {normalized.count(old_tx_compact)}",
                file=sys.stderr,
            )
            return 1
        normalized = normalized.replace(old_tx_compact, new_tx_compact, 2)
        changed = True

    # 2. Output TStringLists in GerarArquivos
    if "Produto.LineBreak := #13#10;" not in normalized:
        old_block = (
            "  Produto                   := TStringList.Create;\n"
            "  Setor                     := TStringList.Create;\n"
            "  Receita                   := TStringList.Create;\n"
            "  Tara                      := TStringList.Create;\n"
            "  Nutricional               := TStringList.Create;\n"
            "  RelacaoProdutoNutricional := TStringList.Create;\n"
            "  RelacaoProdutoReceita     := TStringList.Create;\n"
            "  Fornecedor                := TStringList.Create;\n"
            "  Fracionador               := TStringList.Create;\n"
            "  Conservacao               := TStringList.Create;\n"
            "  Teclado                   := TStringList.Create;\n"
            "  Extra1                    := TStringList.Create;\n"
            "  Extra2                    := TStringList.Create;\n"
            "  Operador                  := TStringList.Create;"
        )
        if old_block not in normalized:
            print(
                f"ERROR: Could not locate TStringList.Create block in TACBrCargaBal.GerarArquivos ({target})",
                file=sys.stderr,
            )
            return 1
        linebreak_lines = "\n".join(f"  {name}.LineBreak := #13#10;" for name in LIST_NAMES)
        normalized = normalized.replace(old_block, old_block + "\n" + linebreak_lines, 1)
        changed = True

    if not changed:
        print(f"{target}: TACBrCargaBal CRLF patch already applied (no-op).")
        return 0

    updated = normalized.replace("\n", "\r\n") if use_crlf else normalized
    target.write_bytes(updated.encode(encoding))
    print(f"{target}: Patched TACBrCargaBal (3x LTXTeclas + 14x GerarArquivos TStringLists) with CRLF LineBreak.")
    return 0


def main() -> int:
    target = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else resolve_default_target()
    return patch_file(target)


if __name__ == "__main__":
    sys.exit(main())
