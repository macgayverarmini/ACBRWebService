#!/bin/bash

# Encerra o script imediatamente se qualquer comando falhar, e trata erros em pipelines
set -eo pipefail

# --- VERIFICAÇÃO DE DEPENDÊNCIAS ---
if [ ! -f "acbrlist.txt" ]; then
    echo "ERRO: O arquivo 'acbrlist.txt' não foi encontrado."
    echo "Este arquivo é necessário para saber quais pacotes instalar."
    exit 1
fi
echo "OK: acbrlist.txt encontrado."



# --- INSTALAÇÃO DOS PACOTES ---

# Adiciona LazReport primeiro, que é uma dependência para outros pacotes
echo "Adicionando link para o pacote LazReport..."
"$LAZBUILD_CMD" --add-package-link "$LAZARUS_DIR/components/lazreport/source/lazreport.lpk"

# Adiciona o pacote PowerPDF, que é uma dependência do LazReport e de outros pacotes ACBr
echo "Adicionando link para o pacote PowerPDF..."
"$LAZBUILD_CMD" --add-package-link "../powerpdf/pack_powerpdf.lpk"

# Adiciona o pacote FortesReport CE (frce), que é uma dependência de alguns pacotes ACBr
echo "Adicionando link para o pacote FortesReport CE (frce)..."
"$LAZBUILD_CMD" --add-package-link "../fortesreport-ce4/Packages/frce.lpk"


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


echo "Este processo pode levar vários minutos. Por favor, aguarde..."
"$LAZBUILD_CMD" --build-ide=
echo "OK: IDE recompilada com sucesso!"


# --- SCRIPT PÓS-BUILD ---

if [ -f "script_altera_acbr.py" ]; then    
    python3 script_altera_acbr.py <<EOF
../acbr/Fontes/ACBrDFe/
s
n
EOF
    echo "OK: Script executado."
fi

if [ -f "compile_resources.py" ]; then
    
    python3 compile_resources.py --lazarus-path "$LAZARUS_DIR" --acbr-path "../acbr/Fontes/"
    echo "OK: Recursos do ACBr compilados."
fi

# --- COMPILAÇÃO FINAL ---



if [ -f "ACBRWebService.lpi" ]; then
    # Compila com os parâmetros de plataforma específicos
    "$LAZBUILD_CMD" -B --os="linux" --cpu="x86_64" ACBRWebService.lpi
    echo "OK: Projeto compilado com sucesso!"
else
    echo "ERRO: Arquivo de projeto 'ACBRWebService.lpi' não encontrado."
    exit 1
fi


if [ -f "ACBRWebService.lpi" ]; then
    # Compila com os parâmetros de plataforma específicos
    "$LAZBUILD_CMD" -B --os="win64" --cpu="x86_64" ACBRWebService.lpi
    echo "OK: Projeto compilado com sucesso!"
else
    echo "ERRO: Arquivo de projeto 'ACBRWebService.lpi' não encontrado."
    exit 1
fi

if [ -f "ACBRWebService.lpi" ]; then
    # Compila com os parâmetros de plataforma específicos
    "$LAZBUILD_CMD" -B --os="win32" --cpu="i386" ACBRWebService.lpi
    echo "OK: Projeto compilado com sucesso!"
else
    echo "ERRO: Arquivo de projeto 'ACBRWebService.lpi' não encontrado."
    exit 1
fi

# --- CONCLUSÃO ---

echo "O executável deve estar disponível no diretório do seu projeto."