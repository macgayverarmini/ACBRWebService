# ESTÁGIO 1: BUILDER - Um ambiente completo para compilar o projeto
# =========================================================================
FROM ubuntu:22.04 AS builder

# Evita que a instalação peça interação do usuário
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências de sistema essenciais
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    subversion \
    python3 \
    python3-pip \
    dos2unix \
    wget \
    unzip \
    binutils-mingw-w64 \
    libgtk2.0-dev \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Não ter esse ln é a causa de problemas ao compilar projetos que usam arquivos *.rc no lazarus
RUN ln -s /usr/bin/x86_64-w64-mingw32-windres /usr/bin/windres

# Baixa a versão específica do fpclazup (ferramenta CLI) usando o link direto
# Se você está lendo isso, entre no git dele, e da uma estrela, ele merece!
RUN wget https://github.com/LongDirtyAnimAlf/Reiniero-fpcup/releases/download/v2.4.0f/fpclazup-x86_64-linux -O /usr/local/bin/fpclazup && \
    chmod +x /usr/local/bin/fpclazup

# Instala o FPC e o Lazarus de forma não-interativa com as versões especificadas
RUN fpclazup --noconfirm --lazversion=3.6 --fpcversion=3.2.2

# Adiciona as ferramentas do Lazarus ao PATH do ambiente
ENV PATH="/root/development/lazarus":$PATH

# Define o diretório de trabalho
WORKDIR /app

# Copia todos os arquivos do seu projeto para dentro do contêiner
# DICA: Use um arquivo .dockerignore para evitar copiar arquivos desnecessários
COPY . .

# Garante que os scripts tenham o formato e permissões corretos para Linux
RUN dos2unix ./download.sh ./build.sh && chmod +x ./download.sh ./build.sh

# Baixa as dependências do projeto (ACBr, Horse, etc.)
RUN ./download.sh

# Instala as dependências Python para os scripts de build
RUN pip3 install tqdm

# Executa o script de build DURANTE a construção da imagem
# Assumimos que este script gera o executável em /app/bin/ACBRWebService-x86_64-linux
RUN ./build.sh

# =========================================================================
# ESTÁGIO 2: FINAL - A imagem final, leve e pronta para produção
# =========================================================================
FROM ubuntu:22.04

# Instala apenas as dependências mínimas para EXECUTAR a aplicação
RUN apt-get update && apt-get install -y \
    libgtk2.0-0 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho
WORKDIR /app

# Copia APENAS o executável compilado do estágio 'builder' para a imagem final.
# O caminho de origem é /app/bin/... no 'builder' e o de destino é /app/ (o WORKDIR atual) no 'final'.
COPY --from=builder /app/bin/ACBRWebService-x86_64-linux .

# Garante que o executável tenha permissão de execução no novo estágio.
# O caminho agora é relativo ao WORKDIR /app.
RUN chmod +x ./ACBRWebService-x86_64-linux

# A porta que a aplicação expõe
EXPOSE 8080


CMD ["./ACBRWebService-x86_64-linux"]
