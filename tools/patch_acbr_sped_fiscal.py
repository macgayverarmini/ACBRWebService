#!/usr/bin/env python3
"""
Idempotent upstream bugfixes for TACBrSPEDFiscal (ACBrSpedFiscal.pas).

Upstream issues fixed:
1. WriteRegistro0001 (Bloco_9.Registro9900 '0100'):
   TBloco_0.WriteRegistro0100 guards emission with `if Assigned(Reg0001.Registro0100) then`,
   allowing Registro0100 to be omitted (`nil`). However, TACBrSPEDFiscal.WriteRegistro0001
   unconditionally appended `REG_BLC := '0100'; QTD_REG_BLC := 1` to Bloco_9.Registro9900.
   Guard with `if Assigned(Bloco_0.Registro0001.Registro0100) then`.
2. WriteRegistroE100 (Bloco_9.Registro9900 'E110'):
   TBloco_E.WriteRegistroE110 guards emission with `if Assigned(RegE100.RegistroE110) then`,
   only incrementing RegistroE110Count when assigned. Guard `REG_BLC := 'E110'` with
   `if Bloco_E.RegistroE110Count > 0 then` so `9900|E110|0` is never emitted.
3. WriteRegistroK001 (Bloco_9.Registro9900 'K010'):
   TBloco_K.WriteRegistroK010 guards emission with `if Assigned(RegK001.RegistroK010) then`.
   Guard `REG_BLC := 'K010'` with `and Assigned(Bloco_K.RegistroK001.RegistroK010)`.
"""

from __future__ import annotations

import pathlib
import sys


def read_pas(path: pathlib.Path) -> tuple[str, str, bool]:
    raw = path.read_bytes()
    use_crlf = b"\r\n" in raw
    try:
        text = raw.decode("utf-8")
        enc = "utf-8"
    except UnicodeDecodeError:
        text = raw.decode("cp1252")
        enc = "cp1252"
    return text.replace("\r\n", "\n"), enc, use_crlf


def write_pas(path: pathlib.Path, text: str, enc: str, use_crlf: bool) -> None:
    out = text.replace("\n", "\r\n") if use_crlf else text
    path.write_bytes(out.encode(enc))


def patch_sped_fiscal(efd_dir: pathlib.Path) -> int:
    path = efd_dir / "ACBrSpedFiscal.pas"
    if not path.is_file():
        print(f"ERROR: ACBrSpedFiscal.pas not found at {path}", file=sys.stderr)
        return 1

    text, enc, crlf = read_pas(path)
    changed = False

    # 1. Guard 9900 '0100' when Registro0100 is nil
    new_0100 = (
        "         if Assigned(Bloco_0.Registro0001.Registro0100) then\n"
        "         begin\n"
        "            with New do\n"
        "            begin\n"
        "               REG_BLC := '0100';\n"
        "               QTD_REG_BLC := 1;\n"
        "            end;\n"
        "         end;"
    )
    if new_0100 not in text:
        old_0100 = (
            "         with New do\n"
            "         begin\n"
            "            REG_BLC := '0100';\n"
            "            QTD_REG_BLC := 1;\n"
            "         end;"
        )
        if old_0100 not in text:
            print(f"ERROR: Could not locate unpatched 9900 '0100' block in {path}", file=sys.stderr)
            return 1
        text = text.replace(old_0100, new_0100, 1)
        changed = True

    # 2. Guard 9900 'E110' when RegistroE110Count = 0
    new_e110 = (
        "         if Bloco_E.RegistroE110Count > 0 then\n"
        "         begin\n"
        "            with New do\n"
        "            begin\n"
        "               REG_BLC := 'E110';\n"
        "               QTD_REG_BLC := Bloco_E.RegistroE110Count;\n"
        "            end;\n"
        "         end;"
    )
    if new_e110 not in text:
        old_e110 = (
            "         with New do\n"
            "         begin\n"
            "            REG_BLC := 'E110';\n"
            "            QTD_REG_BLC := Bloco_E.RegistroE110Count;\n"
            "         end;"
        )
        if old_e110 not in text:
            print(f"ERROR: Could not locate unpatched 9900 'E110' block in {path}", file=sys.stderr)
            return 1
        text = text.replace(old_e110, new_e110, 1)
        changed = True

    # 3. Guard 9900 'K010' when RegistroK010 is nil
    new_k010 = "      if (Bloco_0.Registro0000.COD_VER >= vlVersao116) and Assigned(Bloco_K.RegistroK001.RegistroK010) then"
    if new_k010 not in text:
        old_k010 = "      if (Bloco_0.Registro0000.COD_VER >= vlVersao116) then"
        if old_k010 not in text:
            print(f"ERROR: Could not locate unpatched 9900 'K010' guard in {path}", file=sys.stderr)
            return 1
        text = text.replace(old_k010, new_k010, 1)
        changed = True

    if not changed:
        print(f"{path}: TACBrSPEDFiscal 9900 optional-record guards already applied (no-op).")
        return 0

    write_pas(path, text, enc, crlf)
    print(f"{path}: Patched TACBrSPEDFiscal 9900 guards for optional 0100, E110, and K010.")
    return 0


def main() -> int:
    here = pathlib.Path(__file__).resolve()
    efd_dir = (
        pathlib.Path(sys.argv[1]).resolve()
        if len(sys.argv) > 1
        else here.parents[2] / "acbr" / "Fontes" / "ACBrTXT" / "ACBrSPED" / "ACBrSPEDFiscal"
    )
    return patch_sped_fiscal(efd_dir)


if __name__ == "__main__":
    sys.exit(main())
