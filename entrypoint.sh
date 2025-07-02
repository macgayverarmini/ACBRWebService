#!/bin/sh

# Sai imediatamente se um comando falhar
set -e

# Inicia o X Virtual Framebuffer no display :99 em background
echo "Iniciando Xvfb..."
# CORREÇÃO: Adicionada a flag -nolisten tcp para evitar problemas de permissão em /tmp com usuário não-root.
Xvfb :99 -ac -screen 0 1280x1024x16 -nolisten tcp &

# Exporta a variável de ambiente DISPLAY para que a aplicação a utilize
export DISPLAY=:99

# Aguarda um instante para garantir que o Xvfb esteja pronto
sleep 2

echo "Iniciando a aplicação..."
# Substitui o processo do shell pelo comando passado como argumento (o CMD do Dockerfile)
# Isso garante que os sinais do Docker (como SIGTERM) sejam recebidos pela sua aplicação
exec "$@"