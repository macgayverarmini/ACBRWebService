#!/bin/bash

# Script para testar um build específico
set -e

# Parâmetros padrão
TARGET_OS=${1:-linux}
TARGET_CPU=${2:-x86_64}

echo "=========================================="
echo "TESTANDO BUILD: $TARGET_OS-$TARGET_CPU"
echo "=========================================="

# Constrói a imagem Docker
echo "Construindo imagem..."
docker build \
    --build-arg TARGET_OS=$TARGET_OS \
    --build-arg TARGET_CPU=$TARGET_CPU \
    -f Dockerfile.test \
    -t acbr-test-single \
    .

if [ $? -eq 0 ]; then
    echo "✅ BUILD SUCESSO!"
    
    # Executa o container para inspecionar
    echo ""
    echo "Executando container para inspeção..."
    docker run --rm -it acbr-test-single bash -c "
        echo '=== EXECUTÁVEIS ENCONTRADOS ==='
        find /app -name 'ACBRWebService*' -type f 2>/dev/null || echo 'Nenhum executável encontrado'
        echo ''
        echo '=== ESTRUTURA DE DIRETÓRIOS ==='
        ls -la /app/
        echo ''
        echo '=== CONTEÚDO DO BIN (se existir) ==='
        ls -la /app/bin/ 2>/dev/null || echo 'Diretório bin não existe'
        echo ''
        echo 'Container pronto para inspeção. Digite exit para sair.'
        bash
    "
else
    echo "❌ BUILD FALHOU!"
    exit 1
fi