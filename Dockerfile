# Use uma imagem base do Ubuntu, a mesma usada pelo GitHub Actions
FROM ubuntu:22.04

# Evita que a instala��o pe�a intera��o do usu�rio
ENV DEBIAN_FRONTEND=noninteractive

# Instala as depend�ncias de sistema, incluindo o 'subversion'
RUN apt-get update && apt-get install -y \
    git \
    subversion \
    python3 \
    python3-pip \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Instala a depend�ncia Python (tqdm)
RUN pip3 install tqdm

# Instala o FPC e o Lazarus
RUN wget -O - https://pascal-programming.com/fpc-lazarus.asc | gpg --dearmor | tee /usr/share/keyrings/lazarus.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/lazarus.gpg] https://pascal-programming.com/fpc-lazarus/laz-fpc-3-2-2-ubuntu-22-04 ./" > /etc/apt/sources.list.d/lazarus.list
RUN apt-get update && apt-get install -y fpc lazarus

# Define um diret�rio de trabalho dentro do container
WORKDIR /app

# Copia o seu script de build e o prepara
COPY build.sh .
RUN dos2unix build.sh
RUN chmod +x build.sh

# Define o comando padr�o para iniciar o build
CMD ["./build.sh"]