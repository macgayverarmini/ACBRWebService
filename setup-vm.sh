#!/bin/bash
# =========================================================================
#  setup-vm.sh — Provisionamento completo da VM de Build
#  Ubuntu 26.04 LTS · FPC 3.3.1 (Trunk) · Lazarus 4.7 (fixes_4)
#
#  Uso:
#    chmod +x setup-vm.sh
#    sudo ./setup-vm.sh
#
#  Este script instala TUDO do zero em ~20 minutos.
#  Testado em Ubuntu 26.04 com 4GB RAM e 6 vCPUs.
# =========================================================================
set -eo pipefail

# --- Configurações ---
INSTALL_DIR="/home/${SUDO_USER:-$USER}/development"
WORKSPACE="/home/${SUDO_USER:-$USER}/workspace"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="/home/$REAL_USER"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] AVISO:${NC} $*"; }
fail() { echo -e "${RED}[$(date '+%H:%M:%S')] ERRO:${NC} $*"; exit 1; }

# --- Verificações ---
if [ "$EUID" -ne 0 ]; then
    fail "Execute com sudo: sudo ./setup-vm.sh"
fi

log "Iniciando provisionamento da VM de Build..."
log "Diretório de instalação: $INSTALL_DIR"
log "Usuário real: $REAL_USER"

# =========================================================================
#  PASSO 1: Dependências do sistema
# =========================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "  PASSO 1/7 — Instalando dependências do sistema"
log "═══════════════════════════════════════════════════════════════"

apt-get update -qq
apt-get install -y --no-install-recommends \
    build-essential \
    git \
    subversion \
    make \
    binutils \
    gdb \
    wget \
    curl \
    unzip \
    dos2unix \
    libgtk2.0-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgdk-pixbuf2.0-dev \
    libx11-dev \
    libatk1.0-dev \
    libglib2.0-dev \
    mingw-w64 \
    gcc-mingw-w64-i686 \
    gcc-mingw-w64-x86-64 \
    binutils-mingw-w64-i686 \
    binutils-mingw-w64-x86-64 \
    libssl-dev \
    ca-certificates \
    python3

log "OK: Dependências instaladas."

# =========================================================================
#  PASSO 2: Instalar fpclazup (gerenciador de versões FPC/Lazarus)
# =========================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "  PASSO 2/7 — Instalando fpclazup"
log "═══════════════════════════════════════════════════════════════"

if command -v fpclazup &>/dev/null; then
    log "fpclazup já instalado: $(which fpclazup)"
else
    FPCLAZUP_URL="https://github.com/LongDirtyAnimAlf/Reinern/releases/latest/download/fpclazup-x86_64-linux"
    wget -q -O /usr/local/bin/fpclazup "$FPCLAZUP_URL"
    chmod +x /usr/local/bin/fpclazup
    log "OK: fpclazup instalado em /usr/local/bin/fpclazup"
fi

# Symlink windres (necessário para cross-compilation de recursos .rc)
if [ ! -f /usr/bin/windres ]; then
    ln -sf /usr/bin/x86_64-w64-mingw32-windres /usr/bin/windres 2>/dev/null || true
    log "OK: Symlink windres criado."
fi

# =========================================================================
#  PASSO 3: Instalar FPC Trunk (3.3.1) com Extended RTTI
# =========================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "  PASSO 3/7 — Compilando FPC 3.3.1 (trunk) com Extended RTTI"
log "  ⏱  Isso leva ~10 minutos..."
log "═══════════════════════════════════════════════════════════════"

sudo -u "$REAL_USER" mkdir -p "$INSTALL_DIR"

# IMPORTANTE: Usamos fpclazup apenas para o FPC, o Lazarus será manual
sudo -u "$REAL_USER" fpclazup \
    --noconfirm \
    --fpcVersion=trunk \
    --lazVersion=trunk \
    --fpcOPT='-dENABLE_DELPHI_RTTI' \
    --installdir="$INSTALL_DIR" 2>&1 | tail -5

FPC_BIN="$INSTALL_DIR/fpc/bin/x86_64-linux"

if [ ! -x "$FPC_BIN/fpc" ]; then
    fail "FPC não foi compilado corretamente. Verifique o log."
fi

FPC_VER=$("$FPC_BIN/fpc" -iV 2>/dev/null)
log "OK: FPC $FPC_VER instalado em $FPC_BIN"

# =========================================================================
#  PASSO 4: Instalar Lazarus fixes_4 (estável)
# =========================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "  PASSO 4/7 — Compilando Lazarus (branch fixes_4, estável)"
log "═══════════════════════════════════════════════════════════════"
log ""
log "  ⚠  IMPORTANTE: Usamos fixes_4 e NÃO trunk!"
log "  O trunk do Lazarus tem bugs de cross-compilation que impedem"
log "  a compilação para Windows (WriteLRSDoubleAsExtended, BuildManager)."
log "  A branch fixes_4 produz Lazarus 4.7 que é 100% funcional."
log ""

LAZARUS_DIR="$INSTALL_DIR/lazarus"

# Remove o Lazarus trunk que o fpclazup instalou
rm -rf "$LAZARUS_DIR"

# Clona a branch estável
sudo -u "$REAL_USER" git clone \
    --branch fixes_4 --depth 1 \
    https://gitlab.com/freepascal.org/lazarus/lazarus.git \
    "$LAZARUS_DIR"

# Copia fpc.cfg para /etc/ (necessário para o make do Lazarus)
cp "$FPC_BIN/fpc.cfg" /etc/fpc.cfg
log "OK: fpc.cfg copiado para /etc/fpc.cfg"

# Compila o lazbuild
cd "$LAZARUS_DIR"
sudo -u "$REAL_USER" make lazbuild \
    OPT='-dENABLE_DELPHI_RTTI' \
    PP="$FPC_BIN/fpc" 2>&1 | tail -3

if [ ! -x "$LAZARUS_DIR/lazbuild" ]; then
    fail "lazbuild não foi compilado. Verifique o log."
fi

LAZ_VER=$("$LAZARUS_DIR/lazbuild" --version 2>/dev/null)
log "OK: Lazarus $LAZ_VER (lazbuild) compilado."

# =========================================================================
#  PASSO 5: Cross-compilers Win32 + Win64
# =========================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "  PASSO 5/7 — Compilando cross-compilers (Win32 + Win64)"
log "  ⏱  ~3 minutos cada..."
log "═══════════════════════════════════════════════════════════════"

FPC_DIR="$INSTALL_DIR/fpc"

# --- Win32 (i386) ---
log "Compilando cross-compiler Win32 (i386)..."
cd "$FPC_DIR"
sudo -u "$REAL_USER" make crossall \
    OS_TARGET=win32 CPU_TARGET=i386 \
    FPC="$FPC_BIN/fpc" \
    OPT='-dENABLE_DELPHI_RTTI' 2>&1 | tail -3

sudo -u "$REAL_USER" make crossinstall \
    OS_TARGET=win32 CPU_TARGET=i386 \
    FPC="$FPC_BIN/fpc" \
    INSTALL_PREFIX="$FPC_DIR" \
    OPT='-dENABLE_DELPHI_RTTI' 2>&1 | tail -1

log "OK: Win32 cross-compiler instalado."

# --- Win64 (x86_64) ---
log "Compilando cross-compiler Win64 (x86_64)..."
sudo -u "$REAL_USER" make crossall \
    OS_TARGET=win64 CPU_TARGET=x86_64 \
    FPC="$FPC_BIN/fpc" \
    OPT='-dENABLE_DELPHI_RTTI' 2>&1 | tail -3

sudo -u "$REAL_USER" make crossinstall \
    OS_TARGET=win64 CPU_TARGET=x86_64 \
    FPC="$FPC_BIN/fpc" \
    INSTALL_PREFIX="$FPC_DIR" \
    OPT='-dENABLE_DELPHI_RTTI' 2>&1 | tail -1

log "OK: Win64 cross-compiler instalado."

# --- Symlinks dos cross-compilers ---
log "Criando symlinks dos cross-compilers..."

ln -sf "$FPC_DIR/lib/fpc/3.3.1/ppcross386" "$FPC_BIN/ppcross386"
ln -sf "$FPC_DIR/lib/fpc/3.3.1/ppcrossx64" "$FPC_BIN/ppcrossx64"

# Symlinks das units cross para que o fpc.cfg as encontre
ln -sf "$FPC_DIR/lib/fpc/3.3.1/units/i386-win32"   "$FPC_DIR/units/i386-win32"
ln -sf "$FPC_DIR/lib/fpc/3.3.1/units/x86_64-win64"  "$FPC_DIR/units/x86_64-win64"

log "OK: Symlinks criados."

# Verificação
for target in ppcross386 ppcrossx64; do
    if [ ! -f "$FPC_BIN/$target" ]; then
        warn "Cross-compiler $target não encontrado!"
    else
        log "  ✓ $target"
    fi
done

# =========================================================================
#  PASSO 6: Configuração do ambiente
# =========================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "  PASSO 6/7 — Configurando ambiente do usuário"
log "═══════════════════════════════════════════════════════════════"

# Adiciona ao PATH do usuário
PROFILE_FILE="$REAL_HOME/.profile"
if ! grep -q "development/fpc/bin" "$PROFILE_FILE" 2>/dev/null; then
    cat >> "$PROFILE_FILE" << 'ENVEOF'

# --- FPC/Lazarus Build Environment ---
export PATH="$HOME/development/fpc/bin/x86_64-linux:$HOME/development/lazarus:$PATH"
export LAZBUILD_CMD="$HOME/development/lazarus/lazbuild"
export LAZARUS_DIR="$HOME/development/lazarus/"
export FPC_COMPILER="$HOME/development/fpc/bin/x86_64-linux/fpc"
ENVEOF
    log "OK: Variáveis de ambiente adicionadas a $PROFILE_FILE"
fi

# Cria diretório de workspace
sudo -u "$REAL_USER" mkdir -p "$WORKSPACE/src"
log "OK: Workspace criado em $WORKSPACE"

# =========================================================================
#  PASSO 7: Verificação final
# =========================================================================
log ""
log "═══════════════════════════════════════════════════════════════"
log "  PASSO 7/7 — Verificação final"
log "═══════════════════════════════════════════════════════════════"

echo ""
log "  FPC:        $("$FPC_BIN/fpc" -iV 2>/dev/null || echo 'FALHA')"
log "  Lazarus:    $("$LAZARUS_DIR/lazbuild" --version 2>/dev/null || echo 'FALHA')"
log "  ppcross386: $(test -f "$FPC_BIN/ppcross386" && echo 'OK' || echo 'FALHA')"
log "  ppcrossx64: $(test -f "$FPC_BIN/ppcrossx64" && echo 'OK' || echo 'FALHA')"
log "  mingw-w64:  $(x86_64-w64-mingw32-gcc --version 2>/dev/null | head -1 || echo 'FALHA')"

echo ""
log "═══════════════════════════════════════════════════════════════"
log "  ✅ VM PRONTA PARA BUILD!"
log ""
log "  Para compilar o projeto:"
log "    cd $WORKSPACE/src"
log "    bash build.sh"
log ""
log "  Para instalar como GitHub Actions self-hosted runner:"
log "    Veja BUILD_VM.md na raiz do projeto."
log "═══════════════════════════════════════════════════════════════"
