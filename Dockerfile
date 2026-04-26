# =========================================================================
# MULTI-STAGE DOCKERFILE - ACBrWebService
# Estágio 1: Builder com Cross-compilation ativado
#
# Estratégia:
#   docker build --target builder  → monta o ambiente (cacheia FPC/Lazarus)
#   docker run (montando volume)   → compila o projeto com fontes locais
#
# O build.sh NÃO roda mais dentro do Dockerfile. Ele roda via docker run
# com volume montado, para que as alterações de código reflitam sem
# precisar reconstruir a imagem toda.
# =========================================================================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências de sistema essenciais
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python3 \
    python3-pip \
    dos2unix \
    wget \
    unzip \
    curl \
    python3-tqdm \
    binutils-mingw-w64 \
    gcc-multilib \
    clang \
    make \
    binutils \
    gdb \
    subversion \
    libgtk2.0-dev \
    libpango1.0-dev \
    libxtst-dev \
    zip \
    libssl-dev \
    libxmlsec1-dev \
    libxml2-dev && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/x86_64-w64-mingw32-windres /usr/bin/windres

RUN wget https://github.com/LongDirtyAnimAlf/Reiniero-fpcup/releases/download/v2.4.0f/fpclazup-x86_64-linux -O /usr/local/bin/fpclazup && \
    chmod +x /usr/local/bin/fpclazup

# Instala FPC (trunk para RTTI) e Lazarus (fixes_4_0 — trunk HEAD pode estar quebrado)
RUN fpclazup --noconfirm --lazVersion=fixes_4_0 --fpcVersion=trunk --fpcOPT="-dENABLE_DELPHI_RTTI" --installdir=/root/development

# Cross-compilers: só FPC, sem recompilar LCL (--onlylazarus=0 pula Lazarus cross)
RUN fpclazup --installdir=/root/development --cputarget=i386 --ostarget=win32 --onlylazarus=0 --autotools --noconfirm --fpcOPT="-dENABLE_DELPHI_RTTI"
RUN fpclazup --installdir=/root/development --cputarget=x86_64 --ostarget=win64 --onlylazarus=0 --autotools --noconfirm --fpcOPT="-dENABLE_DELPHI_RTTI"

ENV PATH="/root/development/lazarus:$PATH"
ENV LAZBUILD_CMD="/root/development/lazarus/lazbuild"
ENV LAZARUS_DIR="/root/development/lazarus"

# Diretório de trabalho default para quando usar docker run
WORKDIR /workspace/src

# =========================================================================
# Estágio 2: Runner - Imagem final de Produção (leve)
# Só é atingido se fizer: docker build (sem --target builder)
# =========================================================================
FROM ubuntu:22.04 AS runner

ENV DEBIAN_FRONTEND=noninteractive

# Instala apenas as bibliotecas de runtime necessárias (OpenSSL, XML2, XMLSec)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libxmlsec1 \
    libxmlsec1-openssl \
    libxml2 \
    ca-certificates \
    tzdata && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia o binário Linux compilado do estágio 1
COPY --from=builder /workspace/src/bin/ACBRWebService-x86_64-linux /app/ACBRWebService

RUN chmod +x /app/ACBRWebService

EXPOSE 9002

CMD ["/app/ACBRWebService"]
