#!/usr/bin/env python3
"""
Idempotent upstream bugfixes for ACBrSPEDPisCofins & ACBrSPEDPisCofinsImportar.

Upstream issues fixed:
1. ACBrEPCBloco_C_Class.pas (TBloco_C.WriteRegistroC175):
   Fields 07 (ALIQ_PIS), 08 (QUANT_BC_PIS), 09 (ALIQ_PIS_QUANT), 13 (ALIQ_COFINS),
   14 (QUANT_BC_COFINS), and 15 (ALIQ_COFINS_QUANT) called VLFill(..., 3|4) without
   a custom mask, causing CurMascara='#0.00' to truncate 3/4-decimal fields to 2
   decimals. Switch those 6 fields to VDFill(..., 3|4), matching WriteRegistroC170,
   C181, C191, C381, C481, and C491 in the same unit.
2. ACBrEPCBlocos.pas (StrToIndSitEsp & StrToIndNatPJ):
   Empty pipe fields ('||') mapped via StrToIntDef('', 0) to ordinal 0
   (indSitAbertura / indNatPJSocEmpresariaGeral) instead of indNenhum / indNatPJNenhum.
3. ACBrEPCBloco_0_Importar.pas (TACBrSpedPCImportar_Bloco0):
   Added missing Reg0900 handler in AnalisaRegistro + Reg0900 implementation.
4. ACBrEPCBloco_M_Class.pas & ACBrEPCBloco_M_Importar.pas:
   Ensure RegistroM200New / RegistroM600New allocate on demand if nil, and clear
   pre-allocated empty RegistroM200 / RegistroM600 on RegM001 so imported files
   without M200/M600 do not emit phantom zeroed M200/M600 records.
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


def patch_c175(epc_dir: pathlib.Path) -> None:
    path = epc_dir / "ACBrEPCBloco_C_Class.pas"
    text, enc, crlf = read_pas(path)

    new_block = (
        "              {06} VLFill( VL_BC_PIS, 0, 2)        +\n"
        "              {07} VDFill( ALIQ_PIS, 4)            +\n"
        "              {08} VDFill( QUANT_BC_PIS, 3)        +\n"
        "              {09} VDFill( ALIQ_PIS_QUANT, 4)      +\n"
        "              {10} VLFill( VL_PIS, 0, 2)           +\n"
        "              {11}  LFill( CstCofinsToStr(CST_COFINS) ) +\n"
        "              {12} VLFill( VL_BC_COFINS, 0, 2)     +\n"
        "              {13} VDFill( ALIQ_COFINS, 4)         +\n"
        "              {14} VDFill( QUANT_BC_COFINS, 3)     +\n"
        "              {15} VDFill( ALIQ_COFINS_QUANT, 4)   +"
    )
    if new_block in text:
        print(f"{path}: WriteRegistroC175 VDFill patch already applied (no-op).")
        return

    old_block = (
        "              {06} VLFill( VL_BC_PIS, 0, 2)        +\n"
        "              {07} VLFill( ALIQ_PIS, 8, 4)         +\n"
        "              {08} VLFill( QUANT_BC_PIS, 0, 3)     +\n"
        "              {09} VLFill( ALIQ_PIS_QUANT, 0, 4)   +\n"
        "              {10} VLFill( VL_PIS, 0, 2)           +\n"
        "              {11}  LFill( CstCofinsToStr(CST_COFINS) ) +\n"
        "              {12} VLFill( VL_BC_COFINS, 0, 2)     +\n"
        "              {13} VLFill( ALIQ_COFINS, 8, 4)      +\n"
        "              {14} VLFill( QUANT_BC_COFINS, 0, 3)  +\n"
        "              {15} VLFill( ALIQ_COFINS_QUANT, 0, 4)+"
    )
    if old_block not in text:
        raise RuntimeError(f"Could not locate WriteRegistroC175 target block in {path}")

    write_pas(path, text.replace(old_block, new_block, 1), enc, crlf)
    print(f"{path}: Patched WriteRegistroC175 3/4-decimal fields to VDFill.")


def patch_blocos_enums(epc_dir: pathlib.Path) -> None:
    path = epc_dir / "ACBrEPCBlocos.pas"
    text, enc, crlf = read_pas(path)

    new_sit = (
        "function StrToIndSitEsp(const AValue: string): TACBrIndSitEsp;\n"
        "begin\n"
        "   if Trim(AValue) = '' then\n"
        "      Result := indNenhum\n"
        "   else\n"
        "      Result := TACBrIndSitEsp( StrToIntDef( AValue, Integer(indNenhum)) );\n"
        "end;"
    )
    new_nat = (
        "function StrToIndNatPJ(const AValue: string): TACBrIndNatPJ;\n"
        "begin\n"
        "   if Trim(AValue) = '' then\n"
        "      Result := indNatPJNenhum\n"
        "   else\n"
        "      Result := TACBrIndNatPJ( StrToIntDef( AValue, Integer(indNatPJNenhum)) );\n"
        "end;"
    )

    if new_sit in text and new_nat in text:
        print(f"{path}: StrToIndSitEsp/StrToIndNatPJ patch already applied (no-op).")
        return

    old_sit = (
        "function StrToIndSitEsp(const AValue: string): TACBrIndSitEsp;\n"
        "begin\n"
        "   Result := TACBrIndSitEsp( StrToIntDef( AValue, 0) );\n"
        "end;"
    )
    old_nat = (
        "function StrToIndNatPJ(const AValue: string): TACBrIndNatPJ;\n"
        "begin\n"
        "   Result := TACBrIndNatPJ( StrToIntDef( AValue, 0) );\n"
        "end;"
    )

    if old_sit not in text or old_nat not in text:
        raise RuntimeError(f"Could not locate StrToIndSitEsp/StrToIndNatPJ in {path}")

    updated = text.replace(old_sit, new_sit, 1).replace(old_nat, new_nat, 1)
    write_pas(path, updated, enc, crlf)
    print(f"{path}: Patched StrToIndSitEsp and StrToIndNatPJ empty-field handling.")


def patch_bloco0_importar(imp_dir: pathlib.Path) -> None:
    path = imp_dir / "ACBrEPCBloco_0_Importar.pas"
    text, enc, crlf = read_pas(path)

    if "procedure Reg0900;" in text:
        print(f"{path}: Reg0900 importer patch already applied (no-op).")
        return

    old_decl = "    procedure Reg0600;\n  public"
    new_decl = "    procedure Reg0600;\n    procedure Reg0900;\n  public"

    old_dispatch = "  else if (vHead = '0600') then\n    Reg0600;\nend;"
    new_dispatch = (
        "  else if (vHead = '0600') then\n"
        "    Reg0600\n"
        "  else if (vHead = '0900') then\n"
        "    Reg0900;\n"
        "end;"
    )

    old_tail = (
        "procedure TACBrSpedPCImportar_Bloco0.Reg0600;\n"
        "begin\n"
        "\n"
        "  with ACBrSpedPisCofins.Bloco_0.Registro0600New do\n"
        "  begin\n"
        "    DT_ALT := ValorD;\n"
        "    COD_CCUS := Valor;\n"
        "    CCUS := Valor;\n"
        "  end;\n"
        "end;\n"
        "\n"
        "end."
    )
    new_tail = (
        "procedure TACBrSpedPCImportar_Bloco0.Reg0600;\n"
        "begin\n"
        "\n"
        "  with ACBrSpedPisCofins.Bloco_0.Registro0600New do\n"
        "  begin\n"
        "    DT_ALT := ValorD;\n"
        "    COD_CCUS := Valor;\n"
        "    CCUS := Valor;\n"
        "  end;\n"
        "end;\n"
        "\n"
        "procedure TACBrSpedPCImportar_Bloco0.Reg0900;\n"
        "begin\n"
        "  with ACBrSpedPisCofins.Bloco_0.Registro0900New do\n"
        "  begin\n"
        "    REC_TOTAL_BLOCO_A := ValorF;\n"
        "    REC_NRB_BLOCO_A := ValorFV;\n"
        "    REC_TOTAL_BLOCO_C := ValorF;\n"
        "    REC_NRB_BLOCO_C := ValorFV;\n"
        "    REC_TOTAL_BLOCO_D := ValorF;\n"
        "    REC_NRB_BLOCO_D := ValorFV;\n"
        "    REC_TOTAL_BLOCO_F := ValorF;\n"
        "    REC_NRB_BLOCO_F := ValorFV;\n"
        "    REC_TOTAL_BLOCO_I := ValorF;\n"
        "    REC_NRB_BLOCO_I := ValorFV;\n"
        "    REC_TOTAL_BLOCO_1 := ValorF;\n"
        "    REC_NRB_BLOCO_1 := ValorFV;\n"
        "    REC_TOTAL_PERIODO := ValorF;\n"
        "    REC_TOTAL_NRB_PERIODO := ValorFV;\n"
        "  end;\n"
        "end;\n"
        "\n"
        "end."
    )

    if old_decl not in text or old_dispatch not in text or old_tail not in text:
        raise RuntimeError(f"Could not locate target anchors in {path}")

    updated = (
        text.replace(old_decl, new_decl, 1)
        .replace(old_dispatch, new_dispatch, 1)
        .replace(old_tail, new_tail, 1)
    )
    write_pas(path, updated, enc, crlf)
    print(f"{path}: Added Reg0900 to TACBrSpedPCImportar_Bloco0.")


def patch_bloco_m(epc_dir: pathlib.Path, imp_dir: pathlib.Path) -> None:
    cls_path = epc_dir / "ACBrEPCBloco_M_Class.pas"
    cls_text, cls_enc, cls_crlf = read_pas(cls_path)

    new_m200 = (
        "function TBloco_M.RegistroM200New: TRegistroM200;\n"
        "begin\n"
        "   if not Assigned(FRegistroM001.RegistroM200) then\n"
        "      FRegistroM001.RegistroM200 := TRegistroM200.Create;\n"
        "   Result := FRegistroM001.RegistroM200;\n"
        "end;"
    )
    new_m600 = (
        "function TBloco_M.RegistroM600New: TRegistroM600;\n"
        "begin\n"
        "   if not Assigned(FRegistroM001.RegistroM600) then\n"
        "      FRegistroM001.RegistroM600 := TRegistroM600.Create;\n"
        "   Result := FRegistroM001.RegistroM600;\n"
        "end;"
    )
    if new_m200 in cls_text and new_m600 in cls_text:
        print(f"{cls_path}: RegistroM200New/M600New lazy-alloc patch already applied (no-op).")
    else:
        old_m200 = (
            "function TBloco_M.RegistroM200New: TRegistroM200;\n"
            "begin\n"
            "   Result := FRegistroM001.RegistroM200;\n"
            "end;"
        )
        old_m600 = (
            "function TBloco_M.RegistroM600New: TRegistroM600;\n"
            "begin\n"
            "   Result := FRegistroM001.RegistroM600;\n"
            "end;"
        )
        if old_m200 not in cls_text or old_m600 not in cls_text:
            raise RuntimeError(f"Could not locate RegistroM200New/M600New in {cls_path}")
        write_pas(
            cls_path,
            cls_text.replace(old_m200, new_m200, 1).replace(old_m600, new_m600, 1),
            cls_enc,
            cls_crlf,
        )
        print(f"{cls_path}: Patched RegistroM200New/RegistroM600New lazy allocation.")

    imp_path = imp_dir / "ACBrEPCBloco_M_Importar.pas"
    imp_text, imp_enc, imp_crlf = read_pas(imp_path)

    new_reg_m001 = (
        "procedure TACBrSpedPCImportar_BlocoM.RegM001;\n"
        "begin\n"
        "  with ACBrSpedPisCofins.Bloco_M.RegistroM001New do\n"
        "  begin\n"
        "    IND_MOV := StrToIndMov(Valor);\n"
        "    if Assigned(RegistroM200) then\n"
        "    begin\n"
        "      RegistroM200.Free;\n"
        "      RegistroM200 := nil;\n"
        "    end;\n"
        "    if Assigned(RegistroM600) then\n"
        "    begin\n"
        "      RegistroM600.Free;\n"
        "      RegistroM600 := nil;\n"
        "    end;\n"
        "  end;\n"
        "end;"
    )
    if new_reg_m001 in imp_text:
        print(f"{imp_path}: RegM001 patch already applied (no-op).")
    else:
        old_reg_m001 = (
            "procedure TACBrSpedPCImportar_BlocoM.RegM001;\n"
            "begin\n"
            "  with ACBrSpedPisCofins.Bloco_M.RegistroM001New do\n"
            "  begin\n"
            "    IND_MOV := StrToIndMov(Valor);\n"
            "  end;\n"
            "end;"
        )
        if old_reg_m001 not in imp_text:
            raise RuntimeError(f"Could not locate RegM001 in {imp_path}")
        write_pas(imp_path, imp_text.replace(old_reg_m001, new_reg_m001, 1), imp_enc, imp_crlf)
        print(f"{imp_path}: Patched RegM001 to clear pre-allocated M200/M600 until imported.")


def main() -> int:
    here = pathlib.Path(__file__).resolve()
    sped_root = (
        pathlib.Path(sys.argv[1]).resolve()
        if len(sys.argv) > 1
        else here.parents[2] / "acbr" / "Fontes" / "ACBrTXT" / "ACBrSPED"
    )
    epc_dir = sped_root / "ACBrSPEDPisCofins"
    imp_dir = sped_root / "ACBrSPEDPisCofinsImportar"

    if not epc_dir.is_dir() or not imp_dir.is_dir():
        print(f"ERROR: Expected ACBrSPEDPisCofins directories under {sped_root}", file=sys.stderr)
        return 1

    patch_c175(epc_dir)
    patch_blocos_enums(epc_dir)
    patch_bloco0_importar(imp_dir)
    patch_bloco_m(epc_dir, imp_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
