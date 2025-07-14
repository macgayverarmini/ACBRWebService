#!/bin/bash

# Teste rápido - apenas compila sem extrair arquivos
set -e

TARGET_OS=${1:-linux}
TARGET_CPU=${2:-x86_64}

echo "🔨 Testando build: $TARGET_OS-$TARGET_CPU"

docker build \
    --build-arg TARGET_OS=$TARGET_OS \
    --build-arg TARGET_CPU=$TARGET_CPU \
    -f Dockerfile.test \
    -t acbr-quick-test \
    . 

if [ $? -eq 0 ]; then
    echo "✅ Build funcionou!"
    echo ""
    echo "Para testar outras plataformas:"
    echo "./quick-test.sh win64 x86_64"
    echo "./quick-test.sh win32 i386"
    echo "./quick-test.sh linux i386"
else
    echo "❌ Build falhou!"
    exit 1
fi