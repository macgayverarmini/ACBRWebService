# Compilation & Test Verification Rules

Whenever you modify any Pascal source files (`.pas`, `.lpr`, `.lpi`), you **MUST** compile cleanly with `lazbuild` and run the FPCUnit `TestRunner` suite before finishing:

1. **Windows (`win64` / `x86_64`, from `src\`):**
   - Stop any running `bin\ACBRWebService-x86_64-win64.exe` first so the binary is not locked.
   - Build service: `C:\fpcupdeluxe\lazarus\lazbuild.exe --max-process-count=1 --os=win64 --cpu=x86_64 ACBRWebService.lpi`
   - Build tests: `C:\fpcupdeluxe\lazarus\lazbuild.exe --max-process-count=1 --os=win64 --cpu=x86_64 tests\unit\TestRunner.lpi`
2. **Linux (`linux` / `x86_64`, from `src/`):**
   - Run `./build.sh` (or `lazbuild -B --os=linux --cpu=x86_64 ACBRWebService.lpi` and `tests/unit/TestRunner.lpi`). See `BUILD_GUIDE.md`.
3. **Runtime & Suite Check:**
   - Start the compiled binary from `bin/` (port `9002`), verify `GET http://localhost:9002/modelo/<modulo>/<operacao>`, and run `tests/unit/TestRunner --all --format=plain` (`0` errors, `0` failures).
