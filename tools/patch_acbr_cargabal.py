#!/usr/bin/env python3
"""
Idempotent upstream fixes for TACBrCargaBal in ACBrCargaBal.pas:
1. DOS CRLF (#13#10) line endings on all 3 LTXTeclas helper TStringLists and all 14
   output TStringLists in GerarArquivos.
2. Int64 overload for TACBrCargaBal.LFIll so 64-bit Free Pascal expressions such as
   LFIll(i + 1, 4) in PreencherFilizola resolve to integer zero-padding ('0001')
   instead of widening Int64 -> Currency (Decimais=2 -> '0100').
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

    # 3. Int64 overload for TACBrCargaBal.LFIll (64-bit FPC i + 1 resolution)
    decl_int64 = "    function LFIll(Valor: Int64; Tamanho: Integer; Caracter: Char = '0'): string; overload;"
    if decl_int64 not in normalized:
        decl_int32 = "    function LFIll(Valor: Integer; Tamanho: Integer; Caracter: Char = '0'): string; overload;"
        if decl_int32 not in normalized:
            print(f"ERROR: Could not locate LFIll(Valor: Integer) declaration in {target}", file=sys.stderr)
            return 1
        normalized = normalized.replace(decl_int32, decl_int32 + "\n" + decl_int64, 1)
        changed = True

    impl_int64 = (
        "function TACBrCargaBal.LFill(Valor: Int64; Tamanho: Integer;\n"
        "  Caracter: Char = '0'): string;\n"
        "begin\n"
        "  Result := LFill(IntToStr(Valor), Tamanho, Caracter);\n"
        "end;"
    )
    if impl_int64 not in normalized:
        impl_int32 = (
            "function TACBrCargaBal.LFill(Valor: Integer; Tamanho: Integer;\n"
            "  Caracter: Char = '0'): string;\n"
            "begin\n"
            "  Result := LFill(IntToStr(Valor), Tamanho, Caracter);\n"
            "end;"
        )
        if impl_int32 not in normalized:
            print(f"ERROR: Could not locate TACBrCargaBal.LFill(Valor: Integer) implementation in {target}", file=sys.stderr)
            return 1
        normalized = normalized.replace(impl_int32, impl_int32 + "\n\n" + impl_int64, 1)
        changed = True

    if not changed:
        print(f"{target}: TACBrCargaBal CRLF + Int64 LFIll patches already applied (no-op).")
        return 0

    updated = normalized.replace("\n", "\r\n") if use_crlf else normalized
    target.write_bytes(updated.encode(encoding))
    print(f"{target}: Patched TACBrCargaBal (CRLF LineBreak + Int64 LFIll overload).")
    return 0


def main() -> int:
    target = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else resolve_default_target()
    return patch_file(target)


if __name__ == "__main__":
    sys.exit(main())
