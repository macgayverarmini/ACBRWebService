#!/bin/bash

# Encerra o script imediatamente se qualquer comando falhar
set -e

echo "========================================="
echo "PASSO 1: Baixando depend�ncias (ACBr via SVN Seletivo e Robusto)..."
echo "========================================="
# Limpa o diret�rio de depend�ncias para garantir um clone limpo
rm -rf deps
mkdir -p deps

# --- L�GICA DE DOWNLOAD SUPER ROBUSTA ---
ACBR_DIR="./deps/acbr"
ACBR_SVN_URL="https://svn.code.sf.net/p/acbr/code/trunk2"
# Adiciona um timeout de 300 segundos (5 minutos) para os comandos SVN
SVN_OPTIONS="--config-option servers:global:http-timeout=300"

# Fun��o para realizar o checkout seletivo
perform_selective_checkout() {
    echo "Baixando ACBr do reposit�rio SVN oficial (apenas diret�rios necess�rios)..."
    # 1. Come�a com um checkout "vazio" (apenas o n�vel raiz)
    svn checkout $SVN_OPTIONS --depth empty "$ACBR_SVN_URL" "$ACBR_DIR"
    # 2. Atualiza apenas os diret�rios que realmente precisamos
    svn update $SVN_OPTIONS --set-depth infinity "$ACBR_DIR/Fontes"
    svn update $SVN_OPTIONS --set-depth infinity "$ACBR_DIR/Pacotes"
    echo "Checkout seletivo do ACBr conclu�do com sucesso."
}

# Loop de retentativa
MAX_ATTEMPTS=5
ATTEMPT_NUM=1
until (perform_selective_checkout); do
    if (( ATTEMPT_NUM == MAX_ATTEMPTS )); then
      echo "ERRO CR�TICO: O checkout do ACBr falhou ap�s $MAX_ATTEMPTS tentativas."
      exit 1
    fi
    echo "------------------------------------------------------------------------"
    echo "Tentativa de checkout $ATTEMPT_NUM falhou. Limpando e tentando novamente em 20 segundos..."
    echo "------------------------------------------------------------------------"
    # Remove completamente o diret�rio que falhou para evitar o erro "locked"
    rm -rf "$ACBR_DIR"
    mkdir -p "$ACBR_DIR"
    sleep 20
    ((ATTEMPT_NUM++))
done

# Baixa as outras depend�ncias via Git
echo "Baixando outras depend�ncias do Git..."
git clone https://github.com/HashLoad/horse.git ./deps/horse-master
git clone https://github.com/HashLoad/handle-exception.git ./deps/handle-exception
git clone https://github.com/HashLoad/jhonson.git ./deps/jhonson
git clone https://github.com/fortesinformatica/fortesreport-ce.git ./deps/fortesreport-ce4

echo "========================================="
echo "PASSO 2: Compilando pacotes de depend�ncia..."
echo "========================================="
lazbuild -B ./deps/acbr/Pacotes/Lazarus/synapse/laz_synapse.lpk
lazbuild -B ./deps/fortesreport-ce4/Packages/frce.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrComum/ACBrComum.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrOpenSSL/ACBrOpenSSL.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDiversos/ACBrDiversos.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrTCP/ACBrTCP.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/PCNComum/PCNComum.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDFe/ACBrDFeComum.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDFe/ACBrNFe/ACBr_NFe.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDFe/ACBrNFe/DANFE/NFe/Fortes/ACBr_NFe_DanfeRL.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDFe/ACBrCTe/ACBr_CTe.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDFe/ACBrCTe/DACTE/Fortes/ACBr_CTe_DACTeRL.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDFe/ACBrMDFe/ACBr_MDFe.lpk
lazbuild -B ./deps/acbr/Pacotes/Lazarus/ACBrDFe/ACBrMDFe/DAMDFE/Fortes/ACBr_MDFe_DAMDFeRL.lpk

echo "========================================="
echo "PASSO 3: Executando script de altera��o do ACBr..."
echo "========================================="
yes s | python3 script_altera_acbr.py ./deps/acbr/Fontes/ACBrDFe/

echo "========================================="
echo "PASSO 4: Compilando o projeto principal..."
echo "========================================="
lazbuild -B ACBRWebService.lpi

echo "====================================================="
echo "Build de teste local conclu�do com sucesso!"
echo "O execut�vel est� na pasta 'bin/' do seu projeto."
echo "====================================================="