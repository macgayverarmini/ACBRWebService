# Project Overview & RTTI Architecture

`ACBRWebService` is an open-source, stack-agnostic HTTP REST/JSON microservice in Object Pascal (Lazarus + Free Pascal `3.3.1` `-dENABLE_DELPHI_RTTI` + Horse on port `9002`) exposing official **Projeto ACBr** components via **100% Extended RTTI** (`AGENTS.md`).

**Key Directories:**
- `tools/`: Core Extended RTTI engine (`jsonconvert.pas`: `TJSONTools.JsonToObj`, `ObjToJson`, `SafeObjToJson`, `ExtractConfig`), binary helpers (`streamtools.pas`), and idempotent upstream ACBr patch scripts (`patch_acbr_*.py`).
- `method/`: Pure RTTI bridges (`method.acbr.*.pas` — `TACBRBridge*` + `TACBRModelosJSON*`) over ACBr components. Contains **zero** consumer ERP business logic.
- `routes/`: Horse HTTP endpoints (`route.acbr.*.pas` — `POST /<mod>/<op>` and `GET /modelo/<mod>/<op>`).
- `resources/`: Route and message string constants (`resource.strings.routes.pas`, `resource.strings.msg.pas`).
- `tests/unit/`: FPCUnit automated integration/RTTI suite (`TestRunner.lpi`).

**Core Conventions (`[ACBR-RTTI-CORE-PURITY]`):**
- Agents may freely add missing ACBr component bridges, routes, and tests, provided they strictly use `TJSONTools.JsonToObj` / `ObjToJson` / `SafeObjToJson` (`{$mode Delphi}` + `{$M+}` + `{$EXTENDEDRTTI ON}`).
- Never hardcode ERP/tenant logic, never write manual JSON field-by-field parsers bypassing RTTI, never craft synthetic `/modelo/*` JSON, and never post-process fiscal TXT/XML/PDF outputs.
