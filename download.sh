#!/bin/bash
# Encerra o script imediatamente se qualquer comando falhar
set -eo pipefail

# --- Parâmetros de Repetição Configuráveis ---
# Parâmetros mantidos para compatibilidade, mas não mais necessários para Git.
MAX_ATTEMPTS=5
RETRY_DELAY_SECONDS=20

# Função para imprimir um cabeçalho formatado
print_header() {
    echo ""
    echo "========================================================================"
    echo "  $1"
    echo "========================================================================"
}

# Função para verificar a existência de um comando
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERRO CRÍTICO: O comando '$1' não foi encontrado, mas é necessário."
        echo "Por favor, instale '$1' e tente novamente."
        exit 1
    fi
}

print_header "Verificando ferramentas (git)..."
check_command "git"
echo "OK: Ferramentas encontradas."

print_header "Baixando e/ou atualizando dependências"

# --- LÓGICA DE GIT RESTAURADA ---
# Função de clone/update do Git restaurada para o comportamento original (clone completo).
update_git_repo() {
    local url="$1"; local dir="$2"
    if [ -d "$dir/.git" ]; then
        echo "Atualizando repositório Git em '$dir'..."
        (cd "$dir" && git pull)
    else
        echo "Clonando repositório Git de '$url' para '$dir'..."
        git clone "$url" "$dir"
    fi
}

# Função para clonar/atualizar repositório ACBR do mirror Git
update_acbr_repo() {
    local mirror_url="https://github.com/macgayverarmini/acbr-mirror.git"
    local acbr_dir="../acbr"
    
    if [ -d "$acbr_dir/.git" ]; then
        echo "Atualizando repositório ACBR mirror em '$acbr_dir'..."
        (cd "$acbr_dir" && git pull)
    else
        echo "Clonando repositório ACBR mirror de '$mirror_url' para '$acbr_dir'..."
        git clone "$mirror_url" "$acbr_dir"
    fi
}

# --- Chamadas para as funções de download ---
update_acbr_repo
update_git_repo "https://github.com/HashLoad/horse.git" "../horse-master"
update_git_repo "https://github.com/HashLoad/handle-exception.git" "../handle-exception"
update_git_repo "https://github.com/HashLoad/jhonson.git" "../jhonson"
update_git_repo "https://github.com/fortesinformatica/fortesreport-ce.git" "../fortesreport-ce4"

# --- LÓGICA DO POWERPDF RESTAURADA ---
# Tratamento especial para o powerpdf, restaurado para o comportamento original.
print_header "Baixando e extraindo PowerPDF"
echo "Clonando opsi-org/lazarus e extraindo powerpdf..."
if [ -d "../lazarus-temp" ]; then
    echo "Atualizando repositório temporário lazarus..."
    (cd "../lazarus-temp" && git pull)
else
    git clone "https://github.com/opsi-org/lazarus.git" "../lazarus-temp"
fi

# Remove o powerpdf existente para garantir uma cópia limpa
if [ -d "../powerpdf" ]; then
    echo "Removendo ../powerpdf existente..."
    rm -rf "../powerpdf"
fi

echo "Movendo powerpdf para ../powerpdf..."
mv "../lazarus-temp/external_libraries/powerpdf" "../powerpdf"

echo "Limpando repositório temporário lazarus..."
rm -rf "../lazarus-temp"

echo "OK: Dependências baixadas/atualizadas."

print_header "Download de dependências concluído!"
