#!/bin/bash
# Encerra o script imediatamente se qualquer comando falhar
set -eo pipefail

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

print_header "Verificando ferramentas (svn, git)..."
check_command "svn"
check_command "git"
echo "OK: Ferramentas encontradas."

print_header "Baixando e/ou atualizando dependências"

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

update_svn_repo() {
    local url="$1"; local dir="$2"
    if [ -d "$dir/.svn" ]; then
        echo "Atualizando repositório SVN em '$dir'..."
        svn update "$dir"
    else
        echo "Baixando repositório SVN de '$url' para '$dir'..."
        svn checkout "$url" "$dir"
    fi
}

update_svn_repo "https://svn.code.sf.net/p/acbr/code/trunk2/Fontes" "../acbr/Fontes"
update_svn_repo "https://svn.code.sf.net/p/acbr/code/trunk2/Pacotes" "../acbr/Pacotes"
update_git_repo "https://github.com/HashLoad/horse.git" "../horse-master"
update_git_repo "https://github.com/HashLoad/handle-exception.git" "../handle-exception"
update_git_repo "https://github.com/HashLoad/jhonson.git" "../jhonson"
update_git_repo "https://github.com/fortesinformatica/fortesreport-ce.git" "../fortesreport-ce4"

# Special handling for powerpdf as it's a subdirectory of another repo
echo "Cloning opsi-org/lazarus and extracting powerpdf..."
if [ -d "../lazarus-temp" ]; then
    echo "Updating temporary lazarus repo..."
    (cd "../lazarus-temp" && git pull)
else
    git clone "https://github.com/opsi-org/lazarus.git" "../lazarus-temp"
fi

# Remove existing powerpdf to ensure a clean copy
if [ -d "../powerpdf" ]; then
    echo "Removing existing ../powerpdf..."
    rm -rf "../powerpdf"
fi

echo "Moving powerpdf to ../powerpdf..."
mv "../lazarus-temp/external_libraries/powerpdf" "../powerpdf"

echo "Cleaning up temporary lazarus repo..."
rm -rf "../lazarus-temp"

echo "OK: Dependências baixadas/atualizadas."

print_header "Download de dependências concluído!"