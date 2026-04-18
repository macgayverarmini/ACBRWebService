# =========================================================================
# DOCKERFILE DE TESTE - Para testar builds multi-plataforma
# =========================================================================
FROM ubuntu:22.04

# Evita que a instalação peça interação do usuário
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências de sistema essenciais (incluindo suporte para 32 bits)
RUN apt-get update && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python3 \
    python3-pip \
    dos2unix \
    wget \
    unzip \
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
    zip && \
    rm -rf /var/lib/apt/lists/*

# Link simbólico para o windres
RUN ln -s /usr/bin/x86_64-w64-mingw32-windres /usr/bin/windres

# Baixa e instala fpclazup
RUN wget https://github.com/LongDirtyAnimAlf/Reiniero-fpcup/releases/download/v2.4.0f/fpclazup-x86_64-linux -O /usr/local/bin/fpclazup && \
    chmod +x /usr/local/bin/fpclazup

# Instala FPC e Lazarus
RUN fpclazup --noconfirm lazVersion=fixes-4.0.gitlab fpcVersion=fixes-3.2.gitlab --installdir=/root/development
RUN fpclazup --cputarget=i386 --ostarget=win32 --autotools --noconfirm
RUN fpclazup --cputarget=x86_64 --ostarget=win64 --autotools --noconfirm


# Adiciona as ferramentas do Lazarus ao PATH
ENV PATH="/root/development/lazarus:$PATH"

# Define o diretório de trabalho padrão do container
WORKDIR /workspace/src

# O código fonte será montado aqui durante o 'docker run', não usando COPY para não pesar a imagem.
# O ENTRYPOINT / CMD pode ser omitido; vamos executar e descartar o container facilmente.
