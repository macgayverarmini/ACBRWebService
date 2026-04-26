#!/bin/bash
# =========================================================================
#  build.sh — ACBRWebService Multi-Platform Builder
#  FPC 3.3.1 (Trunk) + Lazarus 4.99 — Extended RTTI (-dENABLE_DELPHI_RTTI)
# =========================================================================
set -eo pipefail

# --- Configurações de Notificação ---
# Se NOTIFY_URL estiver definida, envia POST ao final (sucesso ou falha).
# Exemplo: NOTIFY_URL="http://host.docker.internal:9999"
NOTIFY_URL="${NOTIFY_URL:-}"

BUILD_START=$(date +%s)
BUILD_LOG="/tmp/build_output.log"
TARGETS_BUILT=()
TARGETS_FAILED=()

# --- Funções Auxiliares ---
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$BUILD_LOG"; }
separator() { log "========================================================================"; }

notify() {
    local status="$1"
    local message="$2"
    local elapsed=$(( $(date +%s) - BUILD_START ))
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))

    log ""
    separator
    log "  BUILD $status em ${mins}m${secs}s"
    log "  Alvos OK:    ${TARGETS_BUILT[*]:-nenhum}"
    log "  Alvos FALHA: ${TARGETS_FAILED[*]:-nenhum}"
    separator

    if [ -n "$NOTIFY_URL" ]; then
        local payload
        payload=$(cat <<EOF
{
  "status": "$status",
  "message": "$message",
  "elapsed_seconds": $elapsed,
  "targets_ok": "${TARGETS_BUILT[*]}",
  "targets_failed": "${TARGETS_FAILED[*]}"
}
EOF
)
        # Tenta notificar, mas não falha se o listener não estiver disponível
        curl -s -X POST -H "Content-Type: application/json" \
             -d "$payload" "$NOTIFY_URL" --connect-timeout 3 || true
    fi
}

# Trap global: se o script morrer por qualquer razão, notifica falha
trap 'notify "FAILED" "Script interrompido inesperadamente"' ERR

# --- PASSO 1: Verificação de dependências ---
separator
log "PASSO 1/5 — Verificação de dependências"
separator

if [ ! -f "acbrlist.txt" ]; then
    log "ERRO: O arquivo 'acbrlist.txt' não foi encontrado."
    exit 1
fi
log "OK: acbrlist.txt encontrado."

if [ ! -f "ACBRWebService.lpi" ]; then
    log "ERRO: Arquivo de projeto 'ACBRWebService.lpi' não encontrado."
    exit 1
fi
log "OK: ACBRWebService.lpi encontrado."

if [ -z "$LAZBUILD_CMD" ]; then
    log "ERRO: Variável LAZBUILD_CMD não está definida."
    exit 1
fi
if [ ! -x "$LAZBUILD_CMD" ]; then
    log "ERRO: lazbuild não encontrado ou sem permissão em: $LAZBUILD_CMD"
    exit 1
fi
log "OK: lazbuild encontrado em $LAZBUILD_CMD"

# Flags globais: apontar diretórios explicitamente (evita depender do XML)
FPC_COMPILER="${FPC_COMPILER:-/home/datalider/development/fpc/bin/x86_64-linux/fpc}"
LAZBUILD_OPTS="--lazarusdir=$LAZARUS_DIR --compiler=$FPC_COMPILER"
log "FPC Compiler: $FPC_COMPILER"
log "Lazarus Dir : $LAZARUS_DIR"

# Verifica versão do compilador
FPC_VERSION=$("$LAZBUILD_CMD" $LAZBUILD_OPTS --version 2>/dev/null | head -1 || echo "desconhecida")
log "Versão do Lazarus/lazbuild: $FPC_VERSION"

# --- PASSO 2: Registro de pacotes ---
separator
log "PASSO 2/5 — Registro de pacotes ACBr"
separator

# LazReport primeiro (dependência)
log "Adicionando LazReport..."
"$LAZBUILD_CMD" $LAZBUILD_OPTS --add-package-link "$LAZARUS_DIR/components/lazreport/source/lazreport.lpk" 2>&1 | tee -a "$BUILD_LOG"

ACBR_PKG_DIR="../acbr/Pacotes/Lazarus"
PKG_COUNT=0
PKG_SKIP=0

while IFS= read -r package_file || [[ -n "$package_file" ]]; do
    package_file=$(echo "$package_file" | tr -d '\r' | tr '\\' '/')
    if [ -n "$package_file" ]; then
        pkg_path=$(find "$ACBR_PKG_DIR" -ipath "$ACBR_PKG_DIR/$package_file" -print -quit 2>/dev/null)
        if [ -n "$pkg_path" ] && [ -f "$pkg_path" ]; then
            "$LAZBUILD_CMD" $LAZBUILD_OPTS --add-package-link "$pkg_path" 2>&1 | tee -a "$BUILD_LOG"
            PKG_COUNT=$((PKG_COUNT + 1))
        else
            log "AVISO: Pacote não encontrado: $package_file"
            PKG_SKIP=$((PKG_SKIP + 1))
        fi
    fi
done < "acbrlist.txt"

log "Pacotes registrados: $PKG_COUNT | Ignorados: $PKG_SKIP"

# --- PASSO 3: Rebuild da IDE ---
separator
log "PASSO 3/5 — Recompilação da IDE Lazarus (pode levar vários minutos)"
separator

STEP_START=$(date +%s)
"$LAZBUILD_CMD" $LAZBUILD_OPTS --build-ide= 2>&1 | tee -a "$BUILD_LOG"
STEP_ELAPSED=$(( $(date +%s) - STEP_START ))
log "IDE recompilada em ${STEP_ELAPSED}s"

# --- PASSO 3.5: Recursos (se existir) ---
if [ -f "compile_resources.py" ]; then
    log "Compilando recursos do ACBr..."
    python3 compile_resources.py --lazarus-path "$LAZARUS_DIR" --acbr-path "../acbr/Fontes/" 2>&1 | tee -a "$BUILD_LOG"
    log "OK: Recursos compilados."
fi

# --- PASSO 4: Compilação Multi-Plataforma ---
separator
log "PASSO 4/5 — Compilação Multi-Plataforma"
separator

# Garante que o diretório de saída existe
mkdir -p bin

compile_target() {
    local os_name="$1"
    local cpu_name="$2"
    local label="$3"
    local ws="$4"

    log ""
    log "--- Compilando: $label ($cpu_name-$os_name) ws=$ws ---"
    STEP_START=$(date +%s)

    local ws_flag=""
    if [ -n "$ws" ]; then
        ws_flag="--ws=$ws"
    fi

    if "$LAZBUILD_CMD" $LAZBUILD_OPTS -B --os="$os_name" --cpu="$cpu_name" $ws_flag ACBRWebService.lpi 2>&1 | tee -a "$BUILD_LOG"; then
        STEP_ELAPSED=$(( $(date +%s) - STEP_START ))
        log "OK: $label compilado em ${STEP_ELAPSED}s"
        TARGETS_BUILT+=("$label")
        return 0
    else
        STEP_ELAPSED=$(( $(date +%s) - STEP_START ))
        log "FALHA: $label falhou após ${STEP_ELAPSED}s"
        TARGETS_FAILED+=("$label")
        return 1
    fi
}

# Compilar na ordem: Linux (host) → Win64 → Win32
# --ws=nogui para Windows evita recompilação da LCL (serviço sem GUI)
compile_target "linux"  "x86_64" "Linux-x86_64"  ""
compile_target "win64"  "x86_64" "Windows-x86_64" "nogui"
compile_target "win32"  "i386"   "Windows-i386"   "nogui"

# --- PASSO 5: Verificação final ---
separator
log "PASSO 5/5 — Verificação dos binários gerados"
separator

EXPECTED_FILES=(
    "bin/ACBRWebService-x86_64-linux"
    "bin/ACBRWebService-x86_64-win64.exe"
    "bin/ACBRWebService-i386-win32.exe"
)

ALL_OK=true
for f in "${EXPECTED_FILES[@]}"; do
    if [ -f "$f" ]; then
        SIZE=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null)
        SIZE_MB=$(( SIZE / 1024 / 1024 ))
        log "  ✓ $f (${SIZE_MB}MB)"
    else
        log "  ✗ $f — NÃO ENCONTRADO"
        ALL_OK=false
    fi
done

if [ ${#TARGETS_FAILED[@]} -gt 0 ]; then
    notify "PARTIAL" "${#TARGETS_BUILT[@]} de 3 alvos compilados"
    exit 1
elif [ "$ALL_OK" = true ]; then
    notify "SUCCESS" "Todos os 3 alvos compilados com sucesso"
    exit 0
else
    notify "FAILED" "Binários esperados não foram encontrados"
    exit 1
fi