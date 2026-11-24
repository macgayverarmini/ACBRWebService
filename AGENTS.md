# ACBRWebService — AI Agent Architecture & RTTI Governance (`AGENTS.md`)

**`ACBRWebService`** is an open-source, stack-agnostic HTTP REST/JSON microservice in Object Pascal (Lazarus + Free Pascal `3.3.1` `-dENABLE_DELPHI_RTTI` + Horse on port `9002`) built **100% on Extended RTTI reflection** over official [Projeto ACBr](https://www.projetoacbr.com.br/) components.

## 1. `[ACBR-RTTI-CORE-PURITY]` — Core Architectural Law (Zero Hardcoded Logic)

AI agents **HAVE FULL PERMISSION** to add missing ACBr component bridges, methods, routes, and FPCUnit tests, **PROVIDED** every change strictly preserves the native Extended RTTI engine (`TJSONTools.JsonToObj`, `TJSONTools.ObjToJson`, and `TJSONTools.SafeObjToJson` in [`tools/jsonconvert.pas`](tools/jsonconvert.pas) with `{$EXTENDEDRTTI ON}`).

### ALLOWED & ENCOURAGED (`DO`)
1. **Expose Native ACBr Capabilities via RTTI:** Add or extend `method/method.acbr.<mod>.pas` (`{$mode Delphi}` + `{$M+}`), `routes/route.acbr.<mod>.pas`, `resources/resource.strings.routes.pas`, and `ACBRWebService.lpr`.
2. **Pure `TJSONTools` Hydration & Serialization:**
   - Extract `"config"` via `TJSONTools.ExtractConfig(O)` and apply `TJSONTools.JsonToObj` directly onto `facbr.Configuracoes` / `facbr`.
   - Populate ACBr objects, records (`tkRecord`), and collections exclusively via `TJSONTools.JsonToObj(jData, facbr)`.
   - Execute the native ACBr component method (`Enviar`, `Assinar`, `ValidarRegrasdeNegocios`, `SaveFileTXT`, `GeraArquivo`, `GerarDados`, `Imprimir`, etc.).
   - Return results via `TJSONTools.ObjToJson` / `SafeObjToJson` (using `FileToStringBase64` in [`tools/streamtools.pas`](tools/streamtools.pas) solely to transport PDF/TXT/spool files written by ACBr).
3. **Real Dynamic Models (`GET /modelo/<mod>/<op>`):** Every model endpoint MUST instantiate `TACBRModelosJSON<Mod>` and return `TJSONTools.SafeObjToJson(facbr)` on a clean, unmodified ACBr instance.
4. **Upstream ACBr Component Fixes:** If an upstream ACBr unit (`../acbr/Fontes/`) has a verified bug, fix it generically via an idempotent script in `tools/patch_acbr_*.py` while keeping `{$EXTENDEDRTTI ON}` in `ACBr.inc`.
5. **Pascal Discipline:** Prefer `mcp-firemonkey` AST tools when editing `.pas` files, ensure `try..finally` cleanup without leaks, and maintain strict RFC 8259 UTF-8 output.

### STRICTLY FORBIDDEN (`DO NOT` — "Proibido Chumbar Código")
1. **NO Consumer / Tenant Hardcoding:** Never embed consumer-specific business rules, tenant defaults (hardcoded UFs, CNPJs, series, environments, or machine paths), or `*.legado.pas` wrapper units. Domain and RFB/SEFAZ code mapping to Pascal Enum identifiers belongs 100% in the HTTP client consuming `:9002`.
2. **NO Manual JSON Field-by-Field Bypass:** Never write manual `jObj.Get(...)` / `jObj.Strings[...]` / property-by-property assignments or custom DTO serializers that bypass `TJSONTools` when ACBr already exposes those fields as `published`/`public` RTTI properties.
3. **NO Synthetic `/modelo/*` Payloads:** Never hand-craft `TJSONObject` schemas or inject fake/example default strings in `/modelo/*` routes.
4. **NO Post-Processing of Fiscal Outputs & NO Fake Fallbacks:** Never regex, concatenate, or patch XML, SPED TXT, Sintegra TXT, CNAB, CargaBal, or PDF strings after ACBr generates them, and never mock responses or swallow real OpenSSL/XSD/SEFAZ exceptions.

## 2. Mandatory Build & Test Verification

Never mark Pascal changes complete without compiling cleanly and passing `TestRunner` (`100%` green):
- **Windows (`win64`):**
  - Stop any running `bin\ACBRWebService-x86_64-win64.exe` before linking.
  - Build service: `C:\fpcupdeluxe\lazarus\lazbuild.exe --max-process-count=1 --os=win64 --cpu=x86_64 ACBRWebService.lpi`
  - Build tests: `C:\fpcupdeluxe\lazarus\lazbuild.exe --max-process-count=1 --os=win64 --cpu=x86_64 tests\unit\TestRunner.lpi`
  - Start `bin\ACBRWebService-x86_64-win64.exe` with working directory `bin\` (`:9002`) and run `tests\unit\TestRunner.exe --all --format=plain`.
- **Linux (`x86_64`):** Run `./build.sh` (or `lazbuild -B --os=linux --cpu=x86_64 ACBRWebService.lpi` + `tests/unit/TestRunner.lpi`) and `./tests/unit/TestRunner --all --format=plain`. Full details: [`BUILD_GUIDE.md`](BUILD_GUIDE.md) & [`API_ROUTES.md`](API_ROUTES.md).
- **Security:** Never commit `.pfx`/`.p12`/`.pem`, production `.ini`, real XML/PDF documents, or `bin/`/`lib/`/`tmp/` build outputs.
