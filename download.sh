#!/bin/bash
# Encerra o script imediatamente se qualquer comando falhar
set -eo pipefail

# --- Parâmetros de Repetição Configuráveis ---
# Aumentamos o número de tentativas e o tempo de espera para o SVN.
# Isso torna o script mais resiliente a instabilidades de rede.
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

print_header "Verificando ferramentas (svn, git)..."
check_command "svn"
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

# Função atualizada com lógica de repetição e cleanup para o SVN
update_svn_repo() {
    local url="$1"
    local dir="$2"
    local max_attempts=3
    local attempt=1
    local success=false

    if [ -d "$dir/.svn" ]; then
        # Lógica de UPDATE para um repositório existente
        while [ $attempt -le $max_attempts ] && [ "$success" = false ]; do
            echo "Atualizando repositório SVN em '$dir' (Tentativa $attempt/$max_attempts)..."
            svn cleanup "$dir" || true
            if svn update --non-interactive --trust-server-cert "$dir"; then
                success=true
                echo "Update do SVN bem-sucedido."
            else
                echo "Update do SVN falhou."
                if [ $attempt -lt $max_attempts ]; then
                    echo "Executando 'svn cleanup' antes de tentar novamente em 20 segundos..."
                    # O cleanup pode falhar se não houver nada para limpar, então não saímos em caso de erro.
                    svn cleanup "$dir" || true
                    sleep 20
                fi
                attempt=$((attempt + 1))
            fi
        done
    else
        # Lógica de CHECKOUT para um novo repositório
        while [ $attempt -le $max_attempts ] && [ "$success" = false ]; do
            echo "Baixando repositório SVN de '$url' para '$dir' (Tentativa $attempt/$max_attempts)..."
            if svn checkout --non-interactive --trust-server-cert "$url" "$dir"; then
                success=true
                echo "Checkout do SVN bem-sucedido."
            else
                echo "Checkout do SVN falhou."
                if [ $attempt -lt $max_attempts ]; then
                    echo "Tentando novamente em 20 segundos..."
                    sleep 20
                    svn cleanup "$dir" || true
                fi
                attempt=$((attempt + 1))
            fi
        done
    fi

    if [ "$success" = false ]; then
        echo "ERRO CRÍTICO: Falha ao sincronizar o repositório SVN de '$url' após $max_attempts tentativas."
        exit 1
    fi
}

# --- Chamadas para as funções de download ---
update_svn_repo "https://svn.code.sf.net/p/acbr/code/trunk2/Fontes" "../acbr/Fontes"
update_svn_repo "https://svn.code.sf.net/p/acbr/code/trunk2/Pacotes" "../acbr/Pacotes"
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
