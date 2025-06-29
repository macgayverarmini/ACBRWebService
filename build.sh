#!/bin/bash

# Encerra o script imediatamente se qualquer comando falhar, e trata erros em pipelines
set -eo pipefail

# --- FUNÇÕES AUXILIARES ---

# Função para imprimir um cabeçalho formatado
print_header() {
    echo ""
    echo "========================================================================"
    echo "  $1"
    echo "========================================================================"
}

# --- DETECÇÃO DO LAZARUS ---

print_header "Procurando pelo diretório do Lazarus..."

LAZARUS_DIR=""
if [ -f "./lazbuild" ]; then
    LAZARUS_DIR=$(pwd)
elif [ -f "$HOME/lazarus/lazbuild" ]; then
    LAZARUS_DIR="$HOME/lazarus"
elif [ -f "$HOME/fpcupdeluxe/lazarus/lazbuild" ]; then
    LAZARUS_DIR="$HOME/fpcupdeluxe/lazarus"
elif command -v lazbuild &> /dev/null; then
    LAZARUS_DIR=$(dirname "$(command -v lazbuild)")
else
    echo "ERRO CRÍTICO: O executável 'lazbuild' não foi encontrado."
    exit 1
fi
LAZBUILD_CMD="$LAZARUS_DIR/lazbuild"
echo "OK: Lazarus encontrado em: $LAZARUS_DIR"

# --- VERIFICAÇÃO DE DEPENDÊNCIAS ---
print_header "Verificando dependências..."
if [ ! -f "acbrlist.txt" ]; then
    echo "ERRO: O arquivo 'acbrlist.txt' não foi encontrado."
    echo "Este arquivo é necessário para saber quais pacotes instalar."
    exit 1
fi
echo "OK: acbrlist.txt encontrado."


# --- LIMPEZA FORÇADA ---
print_header "PASSO 1: Limpando configurações antigas do Lazarus (incluindo o diretório .lazarus)"
rm -rf "$HOME/.lazarus"
mkdir -p "$HOME/.lazarus"
echo "AVISO: O diretório de configuração do Lazarus ($HOME/.lazarus) foi removido para garantir uma limpeza completa."
echo "OK: Configurações antigas removidas."


# --- INSTALAÇÃO DOS PACOTES ---

print_header "PASSO 2: Registrando pacotes na IDE Lazarus"

# Adiciona LazReport primeiro, que é uma dependência para outros pacotes
echo "Adicionando link para o pacote LazReport..."
"$LAZBUILD_CMD" --add-package-link "/home/datalider/fpcupdeluxe/lazarus/components/lazreport/source/lazreport.lpk"

# Adiciona o pacote PowerPDF, que é uma dependência do LazReport e de outros pacotes ACBr
echo "Adicionando link para o pacote PowerPDF..."
"$LAZBUILD_CMD" --add-package-link "../powerpdf/pack_powerpdf.lpk"

# Adiciona o pacote FortesReport CE (frce), que é uma dependência de alguns pacotes ACBr
echo "Adicionando link para o pacote FortesReport CE (frce)..."
"$LAZBUILD_CMD" --add-package-link "../fortesreport-ce4/Packages/frce.lpk"

# Adiciona o pacote Horse




# Adiciona os pacotes do ACBr listados em acbrlist.txt
echo "Adicionando links para os pacotes do ACBr..."
ACBR_PKG_DIR="../acbr/Pacotes/Lazarus"

while IFS= read -r package_file || [[ -n "$package_file" ]]; do
    # Remove possíveis caracteres de retorno de carro do Windows (\r) e converte barras invertidas
    package_file=$(echo "$package_file" | tr -d '\r' | tr '\\' '/')
    if [ -n "$package_file" ]; then
        pkg_path="$ACBR_PKG_DIR/$package_file"
        if [ -f "$pkg_path" ]; then
            echo "Adicionando link para o pacote: $package_file"
            "$LAZBUILD_CMD" --add-package-link "$pkg_path"
        else
            echo "AVISO: Pacote não encontrado em '$pkg_path'. Pulando."
        fi
    fi
done < "acbrlist.txt"

echo "OK: Registro de pacotes concluído."

# --- RECOMPILAÇÃO DA IDE ---

print_header "PASSO 3: Recompilando a IDE do Lazarus com os novos pacotes"
echo "Este processo pode levar vários minutos. Por favor, aguarde..."
"$LAZBUILD_CMD" --build-ide=
echo "OK: IDE recompilada com sucesso!"



# --- SCRIPT PÓS-BUILD ---

if [ -f "script_altera_acbr.py" ]; then
    print_header "PASSO 4: Executando script de alteração do ACBr"
    python3 script_altera_acbr.py <<EOF
../acbr/Fontes/ACBrDFe/
s
n
EOF
    echo "OK: Script executado."
fi

if [ -f "compile_resources.py" ]; then
    print_header "PASSO 5: Compilando recursos do ACBr"
    python3 compile_resources.py --lazarus-path "$LAZARUS_DIR" --acbr-path "../acbr/Fontes/"
    echo "OK: Recursos do ACBr compilados."
fi

# --- COMPILAÇÃO FINAL ---

print_header "PASSO 6: Compilando o projeto final (ACBRWebService.lpi)"
if [ -f "ACBRWebService.lpi" ]; then
    "$LAZBUILD_CMD" -B ACBRWebService.lpi
    echo "OK: Projeto compilado com sucesso!"
else
    echo "ERRO: Arquivo de projeto 'ACBRWebService.lpi' não encontrado."
    exit 1
fi

# --- CONCLUSÃO ---

print_header "Build concluído com sucesso!"
echo "O executável deve estar disponível no diretório do seu projeto."
