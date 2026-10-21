# 🛠️ Guia Completo de Compilação — ACBRWebService (`BUILD_GUIDE.md`)

Este documento descreve em detalhes toda a arquitetura de compilação do **ACBRWebService**, os requisitos do **Extended RTTI**, os pacotes utilizados e o passo a passo completo para compilar o projeto em outra máquina — tanto **diretamente no Windows** quanto **diretamente no Linux (sem Docker)**.

---

## 📌 1. Visão Geral e Versões Utilizadas

O **ACBRWebService** depende do recurso de **Extended RTTI** (compatível com Delphi) introduzido no **Free Pascal Compiler (FPC) 3.3.1 (Trunk)** para serializar e desserializar automaticamente payloads JSON diretamente para as classes de domínio do ACBr (`TNFe`, `TCTe`, `TMDFe`, `TNFSe`, `TConfiguracoes`, etc.) através da unit `tools/jsonconvert.pas`.

> [!IMPORTANT]
> **Por que não usar FPC 3.2.0 ou 3.2.2 estável?**
> Nas versões 3.2.x do FPC, o RTTI clássico só enxerga propriedades `published` (`$M+`). No passado, era necessário rodar scripts em Python para alterar os fontes do ACBr movendo propriedades de `public` para `published`.
> Com o **FPC 3.3.1 (Trunk)** compilado com `-dENABLE_DELPHI_RTTI` e a diretiva `{$EXTENDEDRTTI ON}` no `ACBr.inc`, a unit `RTTI` (`TRttiContext`) reflete nativamente todas as propriedades `public` e métodos `public` (`.New`) das classes do ACBr, tornando qualquer script Python de alteração de propriedades **obsoleto e desnecessário**.

### Matriz de Versões Recomendadas

| Componente | Windows (Build Nativo) | Linux (Build Nativo / Cross-Compile) | Observações Críticas |
| :--- | :--- | :--- | :--- |
| **FPC (Free Pascal)** | **`3.3.1` (`trunk` / `main`)** | **`3.3.1` (`trunk` / `main`)** | Obrigatório compilar o FPC/RTL com **`-dENABLE_DELPHI_RTTI`** (`EnableRTTI=1` no `fpcupdeluxe`). |
| **Lazarus (`lazbuild`)** | **`4.99` (`trunk` / `main`)** ou **`fixes_4`** | **`4.x` (branch `fixes_4`)** | No Linux, prefira a branch `fixes_4` (Lazarus 4.7+) para evitar bugs de cross-compilation do trunk. |
| **Gerenciador** | **fpcupdeluxe** (`x86_64-win64`) | **fpclazup** + `git` / `make` | Automatizado no Linux pelo script `setup-vm.sh`. |
| **Motor de PDF (DANFE/DACTE/etc.)** | **ACBr FPDF Nativo** | **ACBr FPDF Nativo** | Usa os pacotes `*FPDF.lpk` do próprio ACBr (não requer mais FortesReport nem PowerPDF). |

---

## ⚙️ 2. Configurações Específicas para o Extended RTTI Funcionar

Para que a reflexão via `TRttiContext` em `tools/jsonconvert.pas` funcione em tempo de execução, **duas condições obrigatórias** precisam ser atendidas:

### 2.1. Compilar o FPC 3.3.1 com `-dENABLE_DELPHI_RTTI`
O compilador FPC e sua biblioteca padrão (RTL) precisam ser gerados com suporte ao Extended RTTI ativado:
- **No Windows (`fpcupdeluxe`)**: Na tela **`Setup+`**, marque a opção **`Enable Extended RTTI`** (que grava `EnableRTTI=1` no `fpcupdeluxe.ini` e injeta `-dENABLE_DELPHI_RTTI`).
- **No Linux (`fpclazup` / `make`)**: Passe `--fpcOPT="-dENABLE_DELPHI_RTTI"` ao `fpclazup` e `OPT="-dENABLE_DELPHI_RTTI"` ao compilar o `lazbuild` e os cross-compilers.

### 2.2. Incluir `{$EXTENDEDRTTI ON}` no `ACBr.inc`
Por padrão, mesmo com o FPC compilado com suporte a Extended RTTI, o compilador só emite tabelas estendidas para seções `public` quando a diretiva `{$EXTENDEDRTTI ON}` está ativa na unit compilada.
Como praticamente todas as classes de documentos fiscais do ACBr declaram suas propriedades como `public` e todas as units do ACBr incluem o arquivo `ACBr.inc`, adicione **`{$EXTENDEDRTTI ON}` logo na linha 3** do arquivo `acbr/Fontes/ACBrComum/ACBr.inc`:

```pascal
{$IFNDEF ACBr_INC}
{$DEFINE ACBr_INC}
{$EXTENDEDRTTI ON}
```

Além disso, verifique se as seguintes diretivas estão ativas (descomentadas) no `acbr/Fontes/ACBrComum/ACBr.inc`:
```pascal
{$DEFINE DFE_SEM_XMLSEC}
{$DEFINE DFE_SEM_CAPICOM}
{$DEFINE DFE_SEM_MSXML}
{$DEFINE USE_ACBr_XMLDOCUMENT}
{$DEFINE USE_MINGW}
```

> [!WARNING]
> Sempre que alterar o `ACBr.inc`, compile o projeto com a flag **`-B`** (`lazbuild -B ...`) para forçar a recompilação de todas as units (`.ppu`) do ACBr com as tabelas de Extended RTTI embutidas.

---

## 📁 3. Estrutura de Diretórios e Dependências

O projeto `ACBRWebService.lpi` espera a seguinte estrutura de diretórios dentro da pasta raiz do workspace (ex: `C:\BuildWebService\` no Windows ou `~/BuildWebService/` no Linux):

```text
BuildWebService/            # Raiz do Workspace
├── acbr/                   # Fontes e Pacotes da suíte ACBr
├── horse-master/           # Framework HTTP Horse (https://github.com/HashLoad/horse.git)
├── handle-exception/       # Middleware de exceções (https://github.com/HashLoad/handle-exception.git)
├── jhonson/                # Middleware JSON (https://github.com/HashLoad/jhonson.git)
└── src/                    # Código-fonte do ACBRWebService
    ├── ACBRWebService.lpi
    ├── ACBRWebService.lpr
    ├── compile_win.bat     # Script de build rápido no Windows
    ├── build.sh            # Script de build no Linux
    ├── setup-vm.sh         # Script de provisionamento completo no Linux (sem Docker)
    ├── download.sh         # Script que clona/atualiza acbr, horse, handle-exception e jhonson
    ├── routes/             # Rotas HTTP (Horse)
    ├── method/             # Pontes e regras de negócio ACBr
    ├── tools/              # Utilitários (jsonconvert.pas, streamtools.pas)
    ├── resources/          # Strings e recursos
    └── bin/                # Executáveis gerados, DLLs, .ini de serviços e pasta Schemas/
```

### Lista Completa de Pacotes `.lpk` do ACBr Utilizados
O projeto registra e utiliza os seguintes pacotes do diretório `acbr/Pacotes/Lazarus/`:

1. **Base, Criptografia e Rede:**
   - `synapse/laz_synapse.lpk`
   - `ACBrComum/ACBrComum.lpk`
   - `ACBrDiversos/ACBrDiversos.lpk`
   - `PCNComum/PCNComum.lpk`
   - `ACBrOpenSSL/ACBrOpenSSL.lpk`
   - `ACBrLibXML2/ACBrLibXML2.lpk`
   - `ACBrIntegrador/ACBr_Integrador.lpk`
   - `ACBrTCP/ACBrTCP.lpk`
   - `ACBrSerial/ACBrSerial.lpk`
   - `ACBrTXT/ACBrTXTComum.lpk`
2. **Núcleo DFe:**
   - `ACBrDFe/ACBrDFeComum.lpk`
3. **Módulos Fiscais (DFe) e Impressão FPDF:**
   - `ACBrDFe/ACBrNFe/ACBr_NFe.lpk`
   - `ACBrDFe/ACBrNFe/DANFE/NFe/FPDF/ACBr_NFe_DanfeFPDF.lpk`
   - `ACBrDFe/ACBrCTe/ACBr_CTe.lpk`
   - `ACBrDFe/ACBrCTe/DACTE/FPDF/ACBr_CTe_DACTeFPDF.lpk`
   - `ACBrDFe/ACBrMDFe/ACBr_MDFe.lpk`
   - `ACBrDFe/ACBrMDFe/DAMDFE/FPDF/ACBr_MDFe_DAMDFeFPDF.lpk`
   - `ACBrDFe/ACBrNFSeX/ACBr_NFSeX.lpk`
   - `ACBrDFe/ACBrNFSeX/DANFSE/FPDF/ACBr_NFSeXDanfseFPDF.lpk`
   - `ACBrDFe/ACBrBPe/ACBr_BPe.lpk`
   - `ACBrDFe/ACBrCIOT/ACBr_CIOT.lpk`
   - `ACBrDFe/ACBreSocial/ACBre_Social.lpk`
   - `ACBrDFe/ACBrReinf/ACBr_Reinf.lpk`
   - `ACBrDFe/ACBrGNRE/ACBr_GNRE.lpk`
4. **Pagamentos, Boleto e Obrigações Acessórias:**
   - `ACBrPIXCD/ACBr_PIXCD.lpk`
   - `ACBrBoleto/ACBr_Boleto.lpk`
   - `ACBrBoleto/FC/FPDF/ACBr_BoletoFC_FPDF.lpk`
   - `ACBrTXT/ACBrSPED/ACBr_SPED.lpk`
   - `ACBrTXT/ACBrSintegra/ACBr_Sintegra.lpk`

---

## 🪟 4. Build Primário 1: Compilando Diretamente no Windows

### Passo 1: Instalar FPC 3.3.1 + Lazarus com `fpcupdeluxe`
1. Crie a pasta `C:\fpcupdeluxe` e baixe o `fpcupdeluxe-x86_64-win64.exe` em [fpcupdeluxe Releases](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases).
2. Execute o `fpcupdeluxe-x86_64-win64.exe`:
   - Defina o caminho de instalação como `C:\fpcupdeluxe`.
   - Em **FPC Version**, selecione **`trunk`** (ou `3.3.1.gitlab`).
   - Em **Lazarus Version**, selecione **`trunk`** (`4.99.gitlab`) ou **`fixes-4.0`**.
   - Clique no botão **`Setup+`**:
     - Marque **`Use GitLab`**.
     - **Obrigatório:** Marque **`Enable Extended RTTI`** (`EnableRTTI=1`).
     - Clique em **OK**.
   - Clique em **`Install/update FPC+Lazarus`** e aguarde a conclusão.

### Passo 2: Preparar o Workspace (`C:\BuildWebService`)
1. Clone o repositório e baixe as dependências na pasta `C:\BuildWebService`:
   ```powershell
   mkdir C:\BuildWebService
   cd C:\BuildWebService
   git clone https://github.com/HashLoad/horse.git horse-master
   git clone https://github.com/HashLoad/handle-exception.git handle-exception
   git clone https://github.com/HashLoad/jhonson.git jhonson
   # Clone também o repositório do ACBr na pasta acbr/ e o projeto na pasta src/
   ```
2. Confirme que `C:\BuildWebService\acbr\Fontes\ACBrComum\ACBr.inc` contém `{$EXTENDEDRTTI ON}` logo na linha 3.

### Passo 3: Registrar os Pacotes `.lpk` no Lazarus
Abra o PowerShell e execute o bloco abaixo para registrar todos os pacotes no `lazbuild`:

```powershell
$lazbuild = "C:\fpcupdeluxe\lazarus\lazbuild.exe"
$acbrPkgDir = "C:\BuildWebService\acbr\Pacotes\Lazarus"

$pkgs = @(
  "synapse\laz_synapse.lpk",
  "ACBrComum\ACBrComum.lpk",
  "ACBrDiversos\ACBrDiversos.lpk",
  "PCNComum\PCNComum.lpk",
  "ACBrOpenSSL\ACBrOpenSSL.lpk",
  "ACBrLibXML2\ACBrLibXML2.lpk",
  "ACBrIntegrador\ACBr_Integrador.lpk",
  "ACBrTCP\ACBrTCP.lpk",
  "ACBrSerial\ACBrSerial.lpk",
  "ACBrTXT\ACBrTXTComum.lpk",
  "ACBrDFe\ACBrDFeComum.lpk",
  "ACBrDFe\ACBrNFe\ACBr_NFe.lpk",
  "ACBrDFe\ACBrNFe\DANFE\NFe\FPDF\ACBr_NFe_DanfeFPDF.lpk",
  "ACBrDFe\ACBrCTe\ACBr_CTe.lpk",
  "ACBrDFe\ACBrCTe\DACTE\FPDF\ACBr_CTe_DACTeFPDF.lpk",
  "ACBrDFe\ACBrMDFe\ACBr_MDFe.lpk",
  "ACBrDFe\ACBrMDFe\DAMDFE\FPDF\ACBr_MDFe_DAMDFeFPDF.lpk",
  "ACBrDFe\ACBrNFSeX\ACBr_NFSeX.lpk",
  "ACBrDFe\ACBrNFSeX\DANFSE\FPDF\ACBr_NFSeXDanfseFPDF.lpk",
  "ACBrDFe\ACBrBPe\ACBr_BPe.lpk",
  "ACBrDFe\ACBrCIOT\ACBr_CIOT.lpk",
  "ACBrDFe\ACBreSocial\ACBre_Social.lpk",
  "ACBrDFe\ACBrReinf\ACBr_Reinf.lpk",
  "ACBrDFe\ACBrGNRE\ACBr_GNRE.lpk",
  "ACBrPIXCD\ACBr_PIXCD.lpk",
  "ACBrBoleto\ACBr_Boleto.lpk",
  "ACBrBoleto\FC\FPDF\ACBr_BoletoFC_FPDF.lpk",
  "ACBrTXT\ACBrSPED\ACBr_SPED.lpk",
  "ACBrTXT\ACBrSintegra\ACBr_Sintegra.lpk"
)

foreach ($p in $pkgs) {
  & $lazbuild --add-package-link "$acbrPkgDir\$p"
}
```

### Passo 4: Compilar o Executável Windows x64
Execute o comando abaixo dentro de `C:\BuildWebService\src`:

```powershell
cd C:\BuildWebService\src
& "C:\fpcupdeluxe\lazarus\lazbuild.exe" --max-process-count=1 -B --os=win64 --cpu=x86_64 ACBRWebService.lpi
```
*(Ou simplesmente execute `compile_win.bat`)*.

O executável será gerado em:
`C:\BuildWebService\src\bin\ACBRWebService-x86_64-win64.exe`

---

## 🐧 5. Build Primário 2: Compilando Diretamente no Linux (Sem Docker)

Para servidores ou estações Linux (Ubuntu 22.04 / 24.04 LTS ou Debian compatível), todo o provisionamento do compilador é feito diretamente no host através do script `setup-vm.sh`.

### Passo 1: Provisionar FPC 3.3.1 (com RTTI) + Lazarus `fixes_4`
Dentro da pasta `src/`, execute:

```bash
chmod +x setup-vm.sh
sudo ./setup-vm.sh
```

O script `setup-vm.sh` realiza automaticamente as 7 etapas:
1. Instala as bibliotecas de desenvolvimento (`build-essential`, `libgtk2.0-dev`, `libcairo2-dev`, `libpango1.0-dev`, `libssl-dev`, `libxml2-dev`, `libxmlsec1-dev`, `mingw-w64`, `git`, `subversion`, `dos2unix`).
2. Instala o `fpclazup` em `/usr/local/bin/fpclazup`.
3. Baixa e compila o **FPC 3.3.1 (`trunk`)** em `~/development/fpc` com **`--fpcOPT='-dENABLE_DELPHI_RTTI'`**.
4. Clona o **Lazarus (branch `fixes_4`)** em `~/development/lazarus`, copia `fpc.cfg` para `/etc/fpc.cfg` e compila o `lazbuild` com **`OPT='-dENABLE_DELPHI_RTTI'`**.
5. Compila os cross-compilers Windows (`ppcross386` e `ppcrossx64`) também com `OPT='-dENABLE_DELPHI_RTTI'`.
6. Configura as variáveis `PATH`, `LAZBUILD_CMD`, `LAZARUS_DIR` e `FPC_COMPILER` no `~/.profile`.

Recarregue o perfil do terminal após o término:
```bash
source ~/.profile
```

### Passo 2: Baixar Dependências e Verificar `ACBr.inc`
```bash
cd ~/BuildWebService/src
chmod +x download.sh
./download.sh
```
Verifique se `../acbr/Fontes/ACBrComum/ACBr.inc` possui `{$EXTENDEDRTTI ON}` na linha 3.

### Passo 3: Compilar no Linux
Para compilar **todos os 3 alvos** (Linux x86_64, Windows x86_64 e Windows i386) registrando os pacotes automaticamente:
```bash
cd ~/BuildWebService/src
dos2unix build.sh
chmod +x build.sh
./build.sh
```

Ou, se desejar compilar **apenas o binário Linux x86_64 nativo**:
```bash
"$LAZBUILD_CMD" --lazarusdir="$LAZARUS_DIR" --compiler="$FPC_COMPILER" -B --os=linux --cpu=x86_64 ACBRWebService.lpi
```

Os binários serão gerados em `src/bin/`:
- `src/bin/ACBRWebService-x86_64-linux`
- `src/bin/ACBRWebService-x86_64-win64.exe`
- `src/bin/ACBRWebService-i386-win32.exe`

---

## 📦 6. Arquivos Necessários em Tempo de Execução (`src/bin/`)

Para executar o binário gerado em qualquer máquina ou servidor de produção, a pasta `bin/` deve conter junto ao executável:

1. **Arquivos `.ini` de Serviços Fiscais:**
   - `ACBrNFeServicos.ini`
   - `ACBrCTeServicos.ini`
   - `ACBrMDFeServicos.ini`
   - `ACBrNFSeXServicos.ini`
2. **Diretório `Schemas/`:**
   - Contendo as subpastas com os arquivos `.xsd` atualizados (`Schemas/NFe`, `Schemas/CTe`, `Schemas/MDFe`, `Schemas/NFSe`, etc.).
3. **Bibliotecas Dinâmicas (OpenSSL + LibXml2):**
   - **No Windows x64** (na mesma pasta do `.exe`, disponíveis em `acbr/DLLs/`):
     - OpenSSL 1.1 x64: `libcrypto-1_1-x64.dll`, `libssl-1_1-x64.dll` (e/ou `libeay32.dll`, `ssleay32.dll`)
     - LibXml2 / XSLT / Ícones (MinGW x64): `libxml2-2.dll`, `libxml2.dll`, `libxmlsec1.dll`, `libxmlsec1-openssl.dll`, `libxslt-1.dll`, `libxslt.dll`, `libexslt-0.dll`, `libexslt.dll`, `libiconv-2.dll`, `libiconv.dll`, `libintl-8.dll`, `libcharset-1.dll`, `libltdl-7.dll`, `libgcc_s_seh-1.dll`, `libwinpthread-1.dll`, `zlib1.dll`.
   - **No Linux (Ubuntu/Debian)**:
     ```bash
     sudo apt-get update && sudo apt-get install -y \
       libxml2 libxmlsec1 libxmlsec1-openssl openssl ca-certificates tzdata
     ```
