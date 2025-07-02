# =========================================================================
# ESTÁGIO 1: BUILDER - Um ambiente completo para compilar o projeto
# =========================================================================
FROM ubuntu:22.04 AS builder

# Evita que a instalação peça interação do usuário
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências de sistema essenciais e limpa o cache para otimizar a camada
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    subversion \
    python3 \
    python3-pip \
    dos2unix \
    wget \
    unzip \
    binutils-mingw-w64 \
    libgtk2.0-dev && \
    rm -rf /var/lib/apt/lists/*

# Link simbólico para o windres
RUN ln -s /usr/bin/x86_64-w64-mingw32-windres /usr/bin/windres

# Baixa e instala fpclazup
RUN wget https://github.com/LongDirtyAnimAlf/Reiniero-fpcup/releases/download/v2.4.0f/fpclazup-x86_64-linux -O /usr/local/bin/fpclazup && \
    chmod +x /usr/local/bin/fpclazup

# Instala FPC e Lazarus
RUN fpclazup --noconfirm --lazversion=3.6 --fpcversion=3.2.2

# Adiciona as ferramentas do Lazarus ao PATH
ENV PATH="/root/development/lazarus":$PATH

# Define o diretório de trabalho
WORKDIR /app

# Copia todos os arquivos do projeto
COPY . .

# Garante permissões e formato corretos
RUN dos2unix ./download.sh ./build.sh && chmod +x ./download.sh ./build.sh

# Baixa as dependências do projeto
RUN ./download.sh

# Instala dependências Python
RUN pip3 install tqdm

# Executa o script de build
RUN ./build.sh

# =========================================================================
# ESTÁGIO 2: FINAL - A imagem final, leve e pronta para produção
# =========================================================================
FROM ubuntu:22.04

# Instala as dependências MÍNIMAS e o dos2unix para garantir a compatibilidade de scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk2.0-0 \
    xvfb \
    dos2unix && \
    rm -rf /var/lib/apt/lists/*

# Cria um usuário não-root para a aplicação (boa prática de segurança)
RUN groupadd -r appuser && useradd --no-log-init -r -g appuser appuser

# Define o diretório de trabalho
WORKDIR /app

# Copia o script de entrypoint e corrige o formato de linha e permissões
COPY --chown=appuser:appuser entrypoint.sh .
RUN dos2unix ./entrypoint.sh && chmod +x ./entrypoint.sh

# Copia o executável do estágio builder e garante a permissão de execução
COPY --from=builder --chown=appuser:appuser /app/bin/ACBRWebService-x86_64-linux .
RUN chmod +x ./ACBRWebService-x86_64-linux

# Muda para o usuário não-root
USER appuser

# Expõe a porta da aplicação
EXPOSE 9000

# Define o entrypoint para executar nosso script de inicialização
ENTRYPOINT ["./entrypoint.sh"]

# Define o comando padrão que o entrypoint irá executar
CMD ["./ACBRWebService-x86_64-linux"]