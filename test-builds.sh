J#!/bin/bash

# Script para testar builds multi-plataforma usando Docker
set -e

echo "=========================================="
echo "TESTANDO BUILDS MULTI-PLATAFORMA"
echo "=========================================="

# Array com as combinações de plataforma para testar
declare -a platforms=(
    "linux:x86_64"
    "linux:i386"
    "win64:x86_64"
    "win32:i386"
)

# Função para testar uma plataforma
test_platform() {
    local target_os=$1
    local target_cpu=$2
    local platform_name="${target_os}-${target_cpu}"
    
    echo ""
    echo "=========================================="
    echo "TESTANDO: $platform_name"
    echo "=========================================="
    
    # Constrói a imagem Docker com os argumentos de build
    echo "Construindo imagem para $platform_name..."
    docker build \
        --build-arg TARGET_OS=$target_os \
        --build-arg TARGET_CPU=$target_cpu \
        -f Dockerfile.test \
        -t acbr-test-$platform_name \
        .
    
    if [ $? -eq 0 ]; then
        echo "✅ BUILD SUCESSO: $platform_name"
        
        # Extrai o executável do container para verificação
        echo "Extraindo executável para verificação..."
        container_id=$(docker create acbr-test-$platform_name)
        
        # Tenta extrair de diferentes locais possíveis
        docker cp $container_id:/app/. ./build-output-$platform_name/ 2>/dev/null || true
        
        docker rm $container_id
        
        # Verifica se o executável foi gerado
        echo "Verificando executáveis gerados:"
        find ./build-output-$platform_name -name "ACBRWebService*" -type f 2>/dev/null || echo "Nenhum executável encontrado"
        
    else
        echo "❌ BUILD FALHOU: $platform_name"
        return 1
    fi
}

# Limpa builds anteriores
echo "Limpando builds anteriores..."
rm -rf ./build-output-* 2>/dev/null || true

# Testa cada plataforma
success_count=0
total_count=${#platforms[@]}

for platform in "${platforms[@]}"; do
    IFS=':' read -r target_os target_cpu <<< "$platform"
    
    if test_platform "$target_os" "$target_cpu"; then
        ((success_count++))
    fi
done

echo ""
echo "=========================================="
echo "RESUMO DOS TESTES"
echo "=========================================="
echo "Sucessos: $success_count/$total_count"

if [ $success_count -eq $total_count ]; then
    echo "🎉 TODOS OS BUILDS FUNCIONARAM!"
    echo ""
    echo "Executáveis gerados:"
    find ./build-output-* -name "ACBRWebService*" -type f 2>/dev/null | sort
else
    echo "⚠️  Alguns builds falharam. Verifique os logs acima."
    exit 1
fi

echo ""
echo "Para limpar os arquivos de teste:"
echo "rm -rf ./build-output-*"
echo "docker rmi \$(docker images acbr-test-* -q) 2>/dev/null || true"