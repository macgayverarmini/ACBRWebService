# 🌐 ACBRWebService

**API REST para integração com a biblioteca ACBR via HTTP.**

> Transforme qualquer microservice em uma central poderosa de documentos fiscais, validações e impressão — tudo via endpoints simples.

---

## 💡 Sobre o Projeto

O ACBRWebService expõe o poder da [ACBR](https://www.projetoacbr.com.br/) através de uma API REST. Com ele você pode:

- ✅ **Validar documentos nacionais** (CPF, CNPJ, etc.) direto de qualquer backend
- 📄 **Gerar DANFE** a partir de XML, recebendo o PDF em Base64
- 🖨️ **Enviar comandos ESCPOS** para impressoras, transformando qualquer estação (até um Raspberry Pi) em central de impressão
- ⚖️ **Ler peso de balanças** conectadas
- 📦 **Emitir e consultar** NFe, CTe, e muito mais

> **💡 Sem autenticação por padrão.** A ideia é usar junto a outro backend ou serviços de automação como o [N8N](https://n8n.io/) — imagine integrar dentro de um container Docker do N8N!

> **⚠️ Lazarus only.** Este projeto não funciona com Delphi. O RTTI do Lazarus para conversão JSON → TObject é mais eficiente, e é justamente isso que torna este código viável.

---

## 📋 Requisitos

| Requisito | Versão / Link |
|-----------|--------------|
| Free Pascal Compiler (FPC) | `3.2.0` |
| Lazarus | `2.2.0` |
| fpcupdeluxe | [v2.2.0n](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases/tag/v2.2.0n) |
| Git | Qualquer versão recente |
| Python 3 | Qualquer versão recente |

### Dependências (baixadas automaticamente via `download.sh`)

| Dependência | Repositório |
|------------|-------------|
| ACBR | [acbr-mirror](https://github.com/macgayverarmini/acbr-mirror.git) |
| FortesReport-CE4 | [fortesinformatica](http://www.fortesinformatica.com.br/produtos/report-ce/) |
| Horse | [HashLoad/horse](https://github.com/HashLoad/horse) |
| Handle-Exception | [HashLoad/handle-exception](https://github.com/HashLoad/handle-exception) |
| Jhonson | [HashLoad/jhonson](https://github.com/HashLoad/jhonson) |
| PowerPDF | Extraído do [opsi-org/lazarus](https://github.com/opsi-org/lazarus) |

---

## 🚀 Instalação

```bash
# 1. Clone o repositório
git clone https://github.com/macgayverarmini/ACBRWebService.git
cd ACBRWebService

# 2. Baixe todas as dependências automaticamente
chmod +x download.sh
./download.sh

# 3. Execute o script que ajusta as propriedades do ACBR
python3 script_altera_acbr.py
```

> **Pré-requisitos:** Certifique-se de ter o [fpcupdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe), Git e Python 3 instalados antes de prosseguir.

---

## 📦 Release

O projeto gera binários para **3 plataformas**:

| Plataforma | Arquivo |
|-----------|---------|
| 🐧 Linux x86_64 | `ACBRWebService-x86_64-linux` |
| 🪟 Windows x86_64 | `ACBRWebService-x86_64-win64.exe` |
| 🪟 Windows i386 | `ACBRWebService-i386-win32.exe` |

### 🤖 Release Automático (GitHub Actions)

O workflow de CI/CD é acionado automaticamente ao criar uma **tag Git** com prefixo `v`.

**Passo a passo:**

1. Certifique-se que o código na branch `main` está estável
2. Crie e envie uma tag versionada ([SemVer](https://semver.org/)):
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Acompanhe o progresso na aba **Actions** do repositório
4. O release estará disponível na aba **Releases** com os zips:
   - `ACBRWebService-v1.0.0-Linux-x86_64.zip`
   - `ACBRWebService-v1.0.0-Windows-x86_64.zip`
   - `ACBRWebService-v1.0.0-Windows-i386.zip`

> O workflow instala dependências, configura FPC/Lazarus com cross-compilers, compila para os 3 targets e publica tudo automaticamente.

---

### 🐳 Build via Docker no Windows (WSL2)

A forma **mais simples** de compilar no Windows — sem precisar instalar FPC, Lazarus ou qualquer dependência manualmente. Tudo roda dentro de um container Docker.

**Pré-requisitos:**
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e rodando com **backend WSL2**
- WSL2 habilitado no Windows ([guia oficial](https://learn.microsoft.com/pt-br/windows/wsl/install))

**Passo a passo:**

1. Abra o **terminal** (CMD, PowerShell ou terminal do WSL) na pasta do projeto:
   ```bash
   cd ACBRWebService
   ```

2. Execute o build com Docker usando o script `.bat`:
   ```cmd
   docker-build.bat
   ```

   Ou, se preferir rodar os comandos manualmente:
   ```bash
   # Construir a imagem (instala FPC, Lazarus, cross-compilers e compila tudo)
   docker build -t acbr-webservice-builder .

   # Copiar os binários gerados para sua máquina
   docker run --rm -v "$(pwd)/bin:/output" acbr-webservice-builder sh -c "cp /app/bin/* /output/"
   ```

3. Os binários compilados estarão no diretório `bin/`:
   - `ACBRWebService-x86_64-linux`
   - `ACBRWebService-x86_64-win64.exe`
   - `ACBRWebService-i386-win32.exe`

> **💡 Dica:** O primeiro build demora bastante (~20-40 min) pois instala FPC/Lazarus e cross-compilers dentro do container. Builds subsequentes são muito mais rápidos graças ao cache de camadas do Docker.

> **⚠️ Atenção:** Certifique-se que o Docker Desktop está configurado com recursos suficientes (mínimo 4GB de RAM para o WSL2).

---

### 🔧 Release Manual (Local — sem Docker)

Para quem quer compilar **diretamente no Linux** sem Docker. Requer ambiente **Ubuntu 22.04** (ou compatível).

#### 1️⃣ Dependências de Sistema

```bash
sudo apt-get update
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential git python3 python3-pip python3-tqdm dos2unix wget unzip zip \
  subversion clang gdb binutils-mingw-w64-x86-64 libx11-dev libgtk2.0-dev \
  libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev gcc-multilib libgtk2.0-dev:i386
sudo apt-get --fix-broken install -y

# Link simbólico necessário para cross-compilação Windows
sudo ln -s /usr/bin/x86_64-w64-mingw32-windres /usr/bin/windres
```

#### 2️⃣ Instalação do FPC/Lazarus + Cross-Compilers

```bash
# Instalar fpclazup
sudo wget https://github.com/LongDirtyAnimAlf/Reiniero-fpcup/releases/download/v2.4.0f/fpclazup-x86_64-linux \
  -O /usr/local/bin/fpclazup
sudo chmod +x /usr/local/bin/fpclazup

# Instalar Lazarus + FPC nativo
fpclazup --noconfirm lazVersion=fixes-4.0.gitlab fpcVersion=fixes-3.2.gitlab \
  --installdir=$HOME/development

# Instalar cross-compilers para Windows
fpclazup --installdir=$HOME/development --cputarget=i386 --ostarget=win32 --autotools --noconfirm
fpclazup --installdir=$HOME/development --cputarget=x86_64 --ostarget=win64 --autotools --noconfirm

# Adicionar ao PATH (coloque no ~/.bashrc para tornar permanente)
export PATH="$HOME/development/lazarus:$PATH"
```

#### 3️⃣ Download das Dependências

```bash
git clone https://github.com/macgayverarmini/ACBRWebService.git
cd ACBRWebService
chmod +x download.sh
./download.sh
```

#### 4️⃣ Compilação Multiplataforma

```bash
export LAZBUILD_CMD="$HOME/development/lazarus/lazbuild"
export LAZARUS_DIR="$HOME/development/lazarus/"
dos2unix build.sh
chmod +x build.sh
./build.sh
```

O `build.sh` irá:
- Registrar os pacotes ACBR no Lazarus
- Recompilar a IDE com os pacotes
- Executar `script_altera_acbr.py` e `compile_resources.py`
- Compilar para Linux x86_64, Windows x86_64 e Windows i386

Os binários são gerados no diretório `bin/`.

#### 5️⃣ Empacotamento

```bash
VERSION="v1.0.0"  # Ajuste para a versão desejada
mkdir -p release

zip -j "release/ACBRWebService-${VERSION}-Linux-x86_64.zip"   bin/ACBRWebService-x86_64-linux
zip -j "release/ACBRWebService-${VERSION}-Windows-x86_64.zip" bin/ACBRWebService-x86_64-win64.exe
zip -j "release/ACBRWebService-${VERSION}-Windows-i386.zip"   bin/ACBRWebService-i386-win32.exe
```

---

### 🎯 Compilação para uma Única Plataforma

Se precisar compilar para apenas um target:

```bash
# Linux 64-bit (nativo)
lazbuild -B --os=linux --cpu=x86_64 ACBRWebService.lpi

# Windows 64-bit (cross-compile)
lazbuild -B --os=win64 --cpu=x86_64 ACBRWebService.lpi

# Windows 32-bit (cross-compile)
lazbuild -B --os=win32 --cpu=i386 ACBRWebService.lpi
```

> **Nota:** Cross-compilação Windows requer os cross-compilers instalados (etapa 2️⃣ acima).

---

## 📝 Licença

O projeto ACBRWebService é licenciado sob a mesma licença do projeto ACBR.

## ⚠️ Aviso

O nome "ACBR" pertence ao [Projeto ACBr](https://www.projetoacbr.com.br/). Este projeto não tem vínculo oficial.
A ACBR agora também possui uma API própria — confira em [acbr.api.br](https://www.acbr.api.br/).
