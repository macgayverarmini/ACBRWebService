# Use uma imagem base do Ubuntu que seja compatível com as dependências
FROM ubuntu:22.04

# Evita que a instalação peça interação do usuário
ENV DEBIAN_FRONTEND=noninteractive

# Instala todas as dependências de sistema de uma vez
# Inclui git, svn, python, e o compilador C++ para o Lazarus
RUN apt-get update && apt-get install -y \
    git \
    subversion \
    python3 \
    python3-pip \
    dos2unix \
    fpc \
    lazarus     && rm -rf /var/lib/apt/lists/*RUN find / -name lazreport.lpk 2>/dev/null || echo "lazreport.lpk not found"

# Define o diretório de trabalho
WORKDIR /app

# Copia todos os arquivos do projeto para o diretório de trabalho
# Isso inclui os scripts, o código-fonte e os arquivos de configuração
COPY . .

# Converte os line-endings para o formato Unix e garante permissão de execução
RUN dos2unix ./download.sh ./build.sh && chmod +x ./download.sh ./build.sh

# Baixa as dependências externas (ACBr, Horse, etc.)
# Centraliza a lógica de download no script, como no CI
RUN ./download.sh

# Instala as dependências Python necessárias para os scripts
RUN pip3 install tqdm

# Executa o script de build principal que compila pacotes e o projeto
# Este é o comando final que produz o executável
CMD ["./build.sh"]
