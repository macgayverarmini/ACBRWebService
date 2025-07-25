# =========================================================================
# DOCKERFILE DE TESTE - Para testar builds multi-plataforma
# =========================================================================
FROM ubuntu:22.04

# Evita que a instalação peça interação do usuário
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências de sistema essenciais (incluindo suporte para 32 bits)
RUN apt-get update && \
    # Adiciona arquitetura i386 para suporte a 32 bits
    apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpango1.0-dev \
    git \
    python3 \
    python3-pip \
    dos2unix \
    libpango \
    wget \
    unzip \
    python3-tqdm \
    binutils-mingw-w64 \
    libgtk2.0-dev \
    gcc-multilib \
    clang \
    make \ 
    binutils \ 
    gdb \ 
    subversion \
    zip \
    libx11-dev \ 
    libgtk2.0-dev \
    libgdk-pixbuf2.0-dev \
    libcairo2-dev \
    libpango1.0-dev && \
    rm -rf /var/lib/apt/lists/*
RUN dpkg -i --force-overwrite /var/cache/apt/archives/libpango1.0-dev_1.52.1+ds-1build1_amd64.deb
RUN apt --fix-broken install

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

# Define o diretório de trabalho
WORKDIR /app

# Copia todos os arquivos do projeto
COPY . .

# Garante permissões e formato corretos
RUN dos2unix ./download.sh ./build.sh && chmod +x ./download.sh ./build.sh

# Baixa as dependências do projeto
RUN ./download.sh

ENV LAZBUILD_CMD="/root/development/lazarus/lazbuild"
ENV LAZARUS_DIR="/root/development/lazarus/"

# Executa o script de build
RUN ./build.sh
