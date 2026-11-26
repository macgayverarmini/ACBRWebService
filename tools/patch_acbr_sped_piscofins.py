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
2. ACBrEPCBlocos.pas (StrToIndSitEsp, StrToIndNatPJ & StrToIndNatRec):
   Empty pipe fields ('||') mapped via StrToIntDef('', 0) to ordinal 0
   (indSitAbertura / indNatPJSocEmpresariaGeral / inrNaoCumulativa) instead of
   indNenhum / indNatPJNenhum / inrNenhum.
3. ACBrEPCBloco_0_Importar.pas (TACBrSpedPCImportar_Bloco0):
   Added missing Reg0900 handler in AnalisaRegistro + Reg0900 implementation.
4. ACBrEPCBloco_M_Class.pas & ACBrEPCBloco_M_Importar.pas:
   Ensure RegistroM200New / RegistroM600New allocate on demand if nil, and clear
   pre-allocated empty RegistroM200 / RegistroM600 on RegM001 so imported files
   without M200/M600 do not emit phantom zeroed M200/M600 records.
5. ACBrSpedPisCofins.pas & ACBrEPCBloco_0_Importar.pas:
   - Preserve pre-configured Bloco_P.Gravado across IniciaGeracao (and reset in
     SaveFileTXT finally), exit WriteBloco_P immediately when Bloco_P.Gravado = True,
     and ensure WriteBloco_1 cascades WriteBloco_M before checking Bloco_P.Gravado so
     setting Bloco_P.Gravado = True via RTTI omits Bloco_P cleanly without skipping
     empty/active Bloco_A..M.
   - Sync ACBrSpedPisCofins.DT_INI / DT_FIN when importing Registro 0000.
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

    new_nat_rec = (
        "function StrToIndNatRec(const AValue: string):TACBrIndNatRec;\n"
        "begin\n"
        "  if Trim(AValue) = '' then\n"
        "    Result := inrNenhum\n"
        "  else\n"
        "    Result := TACBrIndNatRec(StrToIntDef(AValue, Integer(inrNenhum)));\n"
        "end;"
    )

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
    old_nat_rec = (
        "function StrToIndNatRec(const AValue: string):TACBrIndNatRec;\n"
        "begin\n"
        "  Result := TACBrIndNatRec(StrToIntDef(AValue, 0));\n"
        "end;"
    )

    if new_sit in text and new_nat in text and new_nat_rec in text:
        print(f"{path}: StrToIndSitEsp/StrToIndNatPJ/StrToIndNatRec patch already applied (no-op).")
        return

    updated = text
    for label, old_fn, new_fn in (
        ("StrToIndSitEsp", old_sit, new_sit),
        ("StrToIndNatPJ", old_nat, new_nat),
        ("StrToIndNatRec", old_nat_rec, new_nat_rec),
    ):
        if new_fn in updated:
            continue
        if old_fn not in updated:
            raise RuntimeError(f"Could not locate {label} in {path}")
        updated = updated.replace(old_fn, new_fn, 1)

    write_pas(path, updated, enc, crlf)
    print(f"{path}: Patched StrToIndSitEsp, StrToIndNatPJ and StrToIndNatRec empty-field handling.")


def patch_bloco0_importar(imp_dir: pathlib.Path) -> None:
    path = imp_dir / "ACBrEPCBloco_0_Importar.pas"
    text, enc, crlf = read_pas(path)

    if "procedure Reg0900;" in text:
        print(f"{path}: Reg0900 importer patch already applied (no-op).")
    else:
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

        text = (
            text.replace(old_decl, new_decl, 1)
            .replace(old_dispatch, new_dispatch, 1)
            .replace(old_tail, new_tail, 1)
        )
        write_pas(path, text, enc, crlf)
        print(f"{path}: Added Reg0900 to TACBrSpedPCImportar_Bloco0.")

    new_dt_sync = (
        "    DT_INI := ValorD;\n"
        "    DT_FIN := ValorD;\n"
        "    ACBrSpedPisCofins.DT_INI := DT_INI;\n"
        "    ACBrSpedPisCofins.DT_FIN := DT_FIN;"
    )
    if new_dt_sync in text:
        print(f"{path}: Reg0000 DT_INI/DT_FIN sync already applied (no-op).")
    else:
        old_dt_sync = "    DT_INI := ValorD;\n    DT_FIN := ValorD;"
        if old_dt_sync not in text:
            raise RuntimeError(f"Could not locate Reg0000 DT_INI/DT_FIN in {path}")
        write_pas(path, text.replace(old_dt_sync, new_dt_sync, 1), enc, crlf)
        print(f"{path}: Patched Reg0000 to sync ACBrSpedPisCofins.DT_INI/DT_FIN.")


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


def patch_bloco_p_gravado(epc_dir: pathlib.Path) -> None:
    path = epc_dir / "ACBrSpedPisCofins.pas"
    text, enc, crlf = read_pas(path)
    changed = False

    # 1. Preserve Bloco_P.Gravado across IniciaGeracao when pre-set via RTTI
    new_inicia = (
        "procedure TACBrSPEDPisCofins.IniciaGeracao;\n"
        "var\n"
        "  LBlocoPGravado: Boolean;\n"
        "begin\n"
        "  if FInicializado then exit ;"
    )
    if new_inicia not in text:
        old_inicia = (
            "procedure TACBrSPEDPisCofins.IniciaGeracao;\n"
            "begin\n"
            "  if FInicializado then exit ;"
        )
        if old_inicia not in text:
            raise RuntimeError(f"Could not locate IniciaGeracao header in {path}")
        text = text.replace(old_inicia, new_inicia, 1)
        changed = True

    new_init_p = (
        "  LBlocoPGravado := Bloco_P.Gravado;\n"
        "  InicializaBloco( Bloco_P ) ;\n"
        "  Bloco_P.Gravado := LBlocoPGravado;"
    )
    if new_init_p not in text:
        old_init_p = "  InicializaBloco( Bloco_P ) ;"
        if old_init_p not in text:
            raise RuntimeError(f"Could not locate InicializaBloco(Bloco_P) in {path}")
        text = text.replace(old_init_p, new_init_p, 1)
        changed = True

    # 2. Reset Bloco_P.Gravado in SaveFileTXT finally block
    new_save_finally = (
        "    FACBrTXT.Conteudo.Clear;\n"
        "\n"
        "    Bloco_P.Gravado := False ;\n"
        "    FInicializado := False ;"
    )
    if new_save_finally not in text:
        old_save_finally = (
            "    FACBrTXT.Conteudo.Clear;\n"
            "\n"
            "    FInicializado := False ;"
        )
        if old_save_finally not in text:
            raise RuntimeError(f"Could not locate SaveFileTXT finally block in {path}")
        text = text.replace(old_save_finally, new_save_finally, 1)
        changed = True

    # 3. Exit WriteBloco_P immediately when Bloco_P.Gravado = True (even if IND_MOV = imSemDados)
    new_write_p = (
        "procedure TACBrSPEDPisCofins.WriteBloco_P;\n"
        "begin\n"
        "   if not Bloco_M.Gravado then\n"
        "      WriteBloco_M;\n"
        "\n"
        "   if Bloco_P.Gravado then exit ;\n"
        "\n"
        "   if (Bloco_0.Registro0145Count = 0) and"
    )
    if new_write_p not in text:
        old_write_p = (
            "procedure TACBrSPEDPisCofins.WriteBloco_P;\n"
            "begin\n"
            "   if not Bloco_M.Gravado then\n"
            "      WriteBloco_M;\n"
            "\n"
            "   if ((Bloco_P.Gravado) or (Bloco_0.Registro0145Count = 0)) and"
        )
        if old_write_p not in text:
            raise RuntimeError(f"Could not locate WriteBloco_P guard in {path}")
        text = text.replace(old_write_p, new_write_p, 1)
        changed = True

    # 4. Ensure WriteBloco_1 cascades WriteBloco_M before checking Bloco_P.Gravado
    new_write_1 = (
        "procedure TACBrSPEDPisCofins.WriteBloco_1;\n"
        "begin\n"
        "   if Bloco_1.Gravado then exit ;\n"
        "\n"
        "   if not Bloco_M.Gravado then\n"
        "      WriteBloco_M ;\n"
        "\n"
        "   if not Bloco_P.Gravado then"
    )
    if new_write_1 not in text:
        old_write_1 = (
            "procedure TACBrSPEDPisCofins.WriteBloco_1;\n"
            "begin\n"
            "   if Bloco_1.Gravado then exit ;\n"
            "\n"
            "   if not Bloco_P.Gravado then"
        )
        if old_write_1 not in text:
            raise RuntimeError(f"Could not locate WriteBloco_1 guard in {path}")
        text = text.replace(old_write_1, new_write_1, 1)
        changed = True

    if not changed:
        print(f"{path}: Bloco_P.Gravado RTTI omission patch already applied (no-op).")
        return

    write_pas(path, text, enc, crlf)
    print(f"{path}: Patched IniciaGeracao/SaveFileTXT/WriteBloco_P/WriteBloco_1 for RTTI Bloco_P.Gravado.")


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
    patch_bloco_p_gravado(epc_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main())
