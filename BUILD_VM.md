# 🏗️ Build VM — Guia de Compilação do ACBRWebService

> **Este projeto usa uma VM Ubuntu 26.04 dedicada** para compilar os binários
> de produção para Linux, Windows 32-bit e Windows 64-bit.
>
> A VM substitui o pipeline Docker anterior que tinha problemas de
> memória e instabilidade. O build completo leva **~3 minutos** na VM
> (vs 45+ minutos no Docker que frequentemente falhava).

---

## 📋 Resumo do Ambiente

| Componente | Versão | Nota |
|-----------|--------|------|
| **SO** | Ubuntu 26.04 LTS | VM dedicada |
| **FPC** | 3.3.1 (trunk) | Com `-dENABLE_DELPHI_RTTI` |
| **Lazarus** | 4.7 (branch `fixes_4`) | ⚠️ NÃO usar trunk (veja abaixo) |
| **Cross-compilers** | ppcross386 + ppcrossx64 | Win32 e Win64 |
| **Linker Windows** | mingw-w64 | gcc-mingw-w64-i686 + x86-64 |
| **Tempo de build** | ~3 minutos | 3 targets simultâneos |

### Binários gerados

```
bin/ACBRWebService-x86_64-linux      (~126MB)
bin/ACBRWebService-x86_64-win64.exe  (~188MB)
bin/ACBRWebService-i386-win32.exe    (~158MB)
```

---

## 🚀 Setup rápido (VM do zero)

Se você está criando uma VM nova, use o script automatizado:

```bash
# 1. Criar uma VM Ubuntu 26.04 com pelo menos 4GB RAM e 4 vCPUs
# 2. Copiar o script para a VM
scp setup-vm.sh usuario@IP_DA_VM:/tmp/

# 3. Executar (leva ~20 minutos)
ssh usuario@IP_DA_VM
sudo bash /tmp/setup-vm.sh

# 4. Clonar o projeto
cd ~/workspace
git clone https://github.com/macgayverarmini/ACBRWebService.git src
cd src && bash download.sh  # baixa dependências (ACBr, Horse, etc.)

# 5. Compilar
bash build.sh
```

O script `setup-vm.sh` instala automaticamente:
- Todas as dependências do sistema (build-essential, mingw-w64, etc.)
- FPC 3.3.1 trunk com Extended RTTI
- Lazarus 4.7 (branch fixes_4)
- Cross-compilers Win32 e Win64
- Configuração do PATH e variáveis de ambiente

---

## ⚠️ Armadilhas conhecidas (Lessons Learned)

### 1. NÃO use Lazarus trunk para cross-compilation

O trunk (`main`) do Lazarus tem bugs intermitentes que impedem a
cross-compilation:

- **`WriteLRSDoubleAsExtended` não encontrado** — `projresproc.pas`
  (LazUtils) referencia uma função da LCL, quebrando a compilação
  quando o target é Windows.
- **`BuildManager` unit não encontrada** — Commits faltando no trunk
  que quebram a compilação do lazbuild.

**Solução**: Use sempre a branch `fixes_4`:
```bash
git clone --branch fixes_4 https://gitlab.com/freepascal.org/lazarus/lazarus.git
```

### 2. fpc.cfg precisa estar em /etc/

O `make lazbuild` do Lazarus não encontra o `fpc.cfg` que o fpclazup
cria em `fpc/bin/x86_64-linux/fpc.cfg`. Copie para `/etc/`:
```bash
sudo cp ~/development/fpc/bin/x86_64-linux/fpc.cfg /etc/fpc.cfg
```

### 3. Symlinks das units cross-compiladas

O `make crossinstall` coloca as units em `lib/fpc/3.3.1/units/`, mas
o `fpc.cfg` procura em `fpc/units/`. Crie symlinks:
```bash
ln -sf ~/development/fpc/lib/fpc/3.3.1/units/i386-win32  ~/development/fpc/units/i386-win32
ln -sf ~/development/fpc/lib/fpc/3.3.1/units/x86_64-win64 ~/development/fpc/units/x86_64-win64
```

### 4. Symlinks dos binários ppcross

Mesma lógica — o `crossinstall` coloca os binários ppcross em `lib/fpc/3.3.1/`,
mas o FPC procura em `fpc/bin/x86_64-linux/`:
```bash
ln -sf ~/development/fpc/lib/fpc/3.3.1/ppcross386 ~/development/fpc/bin/x86_64-linux/ppcross386
ln -sf ~/development/fpc/lib/fpc/3.3.1/ppcrossx64 ~/development/fpc/bin/x86_64-linux/ppcrossx64
```

### 5. lazbuild precisa de --lazarusdir e --compiler

Se o `environmentoptions.xml` estiver corrompido ou ausente, o lazbuild
não sabe onde está o Lazarus. O `build.sh` resolve isso passando os
flags explicitamente:
```bash
lazbuild --lazarusdir=/home/user/development/lazarus \
         --compiler=/home/user/development/fpc/bin/x86_64-linux/fpc \
         -B ACBRWebService.lpi
```

### 6. LPI com CRLF causa "Project has no main unit"

O arquivo `.lpi` vindo do Windows tem line endings `\r\n`. Converta:
```bash
dos2unix ACBRWebService.lpi ACBRWebService.lpr
```

### 7. Docker consome memória excessiva

O build no Docker Desktop chegou a consumir 11GB+ de RAM e frequentemente
falhava com OOM. A VM dedicada com 4GB funciona perfeitamente porque
não tem o overhead do Docker.

### 8. --ws=nogui para targets Windows

O ACBRWebService é um serviço sem interface gráfica. Para cross-compilation
Windows, use `--ws=nogui` para evitar que o lazbuild tente compilar
widgets GTK2 para Windows:
```bash
lazbuild -B --os=win64 --cpu=x86_64 --ws=nogui ACBRWebService.lpi
```

---

## 🔧 Variáveis de ambiente do build

O `build.sh` espera estas variáveis:

```bash
export LAZBUILD_CMD=~/development/lazarus/lazbuild
export LAZARUS_DIR=~/development/lazarus/
export FPC_COMPILER=~/development/fpc/bin/x86_64-linux/fpc
export PATH=~/development/fpc/bin/x86_64-linux:~/development/lazarus:$PATH
```

Se você usou o `setup-vm.sh`, elas são adicionadas automaticamente ao `~/.profile`.

---

## 🤖 GitHub Actions (Self-Hosted Runner)

Para usar a VM como runner do GitHub Actions:

```bash
# 1. No GitHub: Settings → Actions → Runners → New self-hosted runner
# 2. Na VM:
mkdir ~/actions-runner && cd ~/actions-runner
curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v2.XXX/actions-runner-linux-x64-2.XXX.tar.gz
tar xzf actions-runner.tar.gz
./config.sh --url https://github.com/macgayverarmini/ACBRWebService --token TOKEN_DO_GITHUB
sudo ./svc.sh install
sudo ./svc.sh start
```

No workflow (`.github/workflows/release.yml`), troque:
```yaml
# De:
runs-on: ubuntu-latest
# Para:
runs-on: self-hosted
```

Vantagens:
- **Sem limite de minutos** (runners self-hosted são gratuitos)
- **Build em ~3 minutos** (FPC/Lazarus já estão instalados)
- **Sem Docker** (roda nativamente na VM)

---

## 📁 Estrutura na VM

```
~/development/
├── fpc/                          # FPC 3.3.1 trunk
│   ├── bin/x86_64-linux/
│   │   ├── fpc                   # Compilador nativo
│   │   ├── fpc.cfg               # Configuração
│   │   ├── ppcross386 → (symlink)
│   │   └── ppcrossx64 → (symlink)
│   ├── units/
│   │   ├── x86_64-linux/         # Units nativas
│   │   ├── i386-win32 → (symlink)
│   │   └── x86_64-win64 → (symlink)
│   └── lib/fpc/3.3.1/
│       ├── ppcross386            # Cross-compiler Win32
│       ├── ppcrossx64            # Cross-compiler Win64
│       └── units/
│           ├── i386-win32/       # Units Win32
│           └── x86_64-win64/     # Units Win64
└── lazarus/                      # Lazarus 4.7 (fixes_4)
    └── lazbuild                  # Build tool

~/workspace/
├── src/                          # Este repositório
│   ├── build.sh                  # Script de build principal
│   ├── setup-vm.sh               # Provisionamento da VM
│   ├── download.sh               # Download de dependências
│   └── ACBRWebService.lpi        # Projeto Lazarus
├── acbr/                         # Fontes do ACBr
├── horse-master/                 # Framework HTTP
├── jhonson/                      # JSON middleware
└── handle-exception/             # Exception handler
```
