# 🌐 ACBRWebService

**API REST para integração com a biblioteca ACBR via HTTP.**

> Transforme qualquer microservice em uma central poderosa de documentos fiscais, validações e impressão — tudo via endpoints simples.

---

## 💡 Sobre o Projeto

O ACBRWebService expõe o poder da [ACBR](https://www.projetoacbr.com.br/) através de uma API REST. Com ele você pode:

- ✅ **Validar documentos nacionais** (CPF, CNPJ, etc.) direto de qualquer backend
- 📄 **Gerar DANFE / DACTE / DAMDFE / DANFSe** a partir de XML, recebendo o PDF em Base64 ou URL
- 🖨️ **Enviar comandos ESCPOS** para impressoras, transformando qualquer estação (até um Raspberry Pi) em central de impressão
- ⚖️ **Ler peso de balanças** conectadas
- 📦 **Emitir e consultar** NFe, NFCe, CTe, MDFe, NFSe, BPe, GNRE, CIOT, eSocial, EFD-Reinf, SPED, Sintegra e Boletos

> **💡 Sem autenticação por padrão.** A ideia é usar junto a outro backend ou serviços de automação como o [N8N](https://n8n.io/) — imagine integrar dentro de um container Docker do N8N!

> **⚠️ Lazarus + FPC 3.3.1 (Extended RTTI) only.** Este projeto utiliza o **Extended RTTI** (`TRttiContext`) do Free Pascal 3.3.1 (`trunk`) para serializar e desserializar dinamicamente JSON $\leftrightarrow$ `TObject` (incluindo propriedades `public` e métodos `.New` das classes do ACBr).

---

## 🚛 Documento Auxiliar do CT-e (DACTE)

O **ACBRWebService** oferece suporte completo para a geração e download do **DACTE (Documento Auxiliar do Conhecimento de Transporte Eletrônico)** em formato PDF, integrado à biblioteca ACBr.

### 📍 Endpoints da API DACTE

| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/cte/dacte` | Gera o PDF do DACTE a partir do XML e retorna a chave, tamanho, URL de download e o PDF codificado em **Base64**. |
| `POST` | `/cte/dacte-url` | **Versão otimizada**: Gera o PDF no servidor e retorna apenas a chave e a URL de download `/cte/pdf/:chave` (sem o payload pesado de Base64). |
| `GET`  | `/cte/pdf/:chave` | Download direto do arquivo PDF (`dacte.pdf`) pela chave de 44 dígitos do CT-e. |
| `POST` | `/cte/dacte-evento` | Gera o PDF do DACTE para eventos de CT-e (ex: Cancelamento, Carta de Correção - CC-e). |
| `GET`  | `/modelo/cte/dacte-evento` | Retorna o modelo JSON de exemplo para a requisição de evento DACTE. |

---

### 📥 Exemplo de Requisição (`POST /cte/dacte` ou `/cte/dacte-url`)

```json
{
  "id": "req-12345",
  "xml": "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz48Y1RlUHJvYy...==",
  "config": {
    "SSLLib": 4,
    "Arquivos": {
      "PathSalvar": "C:\\BuildWebService\\src\\bin\\Docs"
    }
  }
}
```

> **Nota:** O campo `xml` aceita o XML do CT-e em Base64 ou a string XML direta.

---

### 📤 Exemplo de Resposta (`POST /cte/dacte`)

```json
{
  "id": "req-12345",
  "chave": "35210403911545000148570010000001011000001018",
  "url": "/cte/pdf/35210403911545000148570010000001011000001018",
  "tamanho": "142850",
  "pdf": "JVBERi0xLjQ... (Base64 do PDF) ..."
}
```

---

### ⚡ Dica de Alta Performance: Geração Leve via `/cte/dacte-url`

Para evitar tráfego excessivo em redes ou na integração com **N8N** / **Zapier**, utilize a rota `/cte/dacte-url`. O PDF é gerado no servidor e você recebe diretamente a URL de download.

```bash
# Geração leve via URL
curl -X POST http://localhost:8080/cte/dacte-url \
  -H "Content-Type: application/json" \
  -d '{"xml": "<xml_base64_ou_string>"}'

# Baixar o PDF diretamente
curl -o dacte.pdf http://localhost:8080/cte/pdf/35210403911545000148570010000001011000001018
```

---

## 📋 Requisitos e Arquitetura RTTI

> 📖 **Para o guia passo a passo completo de compilação em outra máquina (Windows ou Linux), consulte o arquivo [BUILD_GUIDE.md](BUILD_GUIDE.md).**

| Requisito | Versão / Configuração Obrigatória |
|-----------|----------------------------------|
| Free Pascal Compiler (FPC) | **`3.3.1` (Trunk / `main`)** compilado com **`-dENABLE_DELPHI_RTTI`** (`EnableRTTI=1`) |
| Lazarus (`lazbuild`) | **`4.99` (Trunk)** no Windows ou **`4.x` (branch `fixes_4`)** no Linux |
| fpcupdeluxe (Windows) | [Releases fpcupdeluxe](https://github.com/LongDirtyAnimAlf/fpcupdeluxe/releases) (`x86_64-win64`) |
| fpclazup (Linux) | [Releases fpclazup](https://github.com/LongDirtyAnimAlf/Reiniero-fpcup/releases) |
| Git | Qualquer versão recente |

### ⚙️ Configuração Obrigatória do Extended RTTI

O motor de serialização (`tools/jsonconvert.pas`) utiliza o **Extended RTTI** (`TRttiContext`) do FPC 3.3.1 para mapear automaticamente JSON $\leftrightarrow$ propriedades `public` e métodos `.New` das classes do ACBr, sem necessidade de scripts externos de alteração de fontes:

1. **No Compilador FPC 3.3.1**: Deve ser compilado com a flag **`-dENABLE_DELPHI_RTTI`** (opção `Enable Extended RTTI` / `EnableRTTI=1` no `fpcupdeluxe`).
2. **No `ACBr.inc`**: O arquivo `acbr/Fontes/ACBrComum/ACBr.inc` deve conter a diretiva **`{$EXTENDEDRTTI ON}`** logo na linha 3:
   ```pascal
   {$IFNDEF ACBr_INC}
   {$DEFINE ACBr_INC}
   {$EXTENDEDRTTI ON}
   ```

### Dependências (baixadas via `download.sh`)

| Dependência | Finalidade / Repositório |
|------------|--------------------------|
| ACBr | Suíte fiscal e geração nativa de PDF via **FPDF** (`ACBr_*_FPDF`) |
| Horse | [HashLoad/horse](https://github.com/HashLoad/horse) — Servidor HTTP e Roteamento |
| Handle-Exception | [HashLoad/handle-exception](https://github.com/HashLoad/handle-exception) — Middleware de exceções |
| Jhonson | [HashLoad/jhonson](https://github.com/HashLoad/jhonson) — Middleware JSON |

---

## 🛠️ Compilação Primária (Windows e Linux Nativo)

### 🪟 Opção 1: Build Direto no Windows

1. Instale o **FPC 3.3.1 (`trunk`)** e **Lazarus (`4.99` / `fixes_4`)** em `C:\fpcupdeluxe` usando o `fpcupdeluxe-x86_64-win64.exe` com a opção **`Enable Extended RTTI`** marcada em `Setup+`.
2. Garanta que `acbr\Fontes\ACBrComum\ACBr.inc` contenha `{$EXTENDEDRTTI ON}` no topo e registre os pacotes `.lpk` do ACBr no `lazbuild` (veja o comando completo em **[BUILD_GUIDE.md](BUILD_GUIDE.md)**).
3. Compile o projeto executando o script `compile_win.bat` ou via linha de comando:
   ```powershell
   cd C:\BuildWebService\src
   & "C:\fpcupdeluxe\lazarus\lazbuild.exe" --max-process-count=1 -B --os=win64 --cpu=x86_64 ACBRWebService.lpi
   ```
   O executável será gerado em `src\bin\ACBRWebService-x86_64-win64.exe`.

---

### 🐧 Opção 2: Build Direto no Linux (Sem Docker)

Para compilar diretamente em servidores ou estações Linux (Ubuntu 22.04 / 24.04 LTS ou compatível):

#### 1️⃣ Provisionamento Automático do Ambiente (`setup-vm.sh`)
O script `setup-vm.sh` instala todas as dependências de sistema, compila o **FPC 3.3.1 (`trunk`)** com `-dENABLE_DELPHI_RTTI`, o **Lazarus (`fixes_4`)** e os cross-compilers Windows:

```bash
cd ~/BuildWebService/src
chmod +x setup-vm.sh
sudo ./setup-vm.sh
source ~/.profile
```

#### 2️⃣ Download das Dependências
```bash
cd ~/BuildWebService/src
chmod +x download.sh
./download.sh
```
> Confirme que `../acbr/Fontes/ACBrComum/ACBr.inc` possui `{$EXTENDEDRTTI ON}` na linha 3.

#### 3️⃣ Compilação
Para registrar os pacotes do ACBr e compilar todos os alvos (Linux x86_64, Windows x86_64 e Windows i386):
```bash
dos2unix build.sh
chmod +x build.sh
./build.sh
```

Ou para compilar **apenas um alvo específico**:
```bash
# Linux 64-bit (nativo)
"$LAZBUILD_CMD" --lazarusdir="$LAZARUS_DIR" --compiler="$FPC_COMPILER" -B --os=linux --cpu=x86_64 ACBRWebService.lpi

# Windows 64-bit (cross-compile)
"$LAZBUILD_CMD" --lazarusdir="$LAZARUS_DIR" --compiler="$FPC_COMPILER" -B --os=win64 --cpu=x86_64 --ws=nogui ACBRWebService.lpi

# Windows 32-bit (cross-compile)
"$LAZBUILD_CMD" --lazarusdir="$LAZARUS_DIR" --compiler="$FPC_COMPILER" -B --os=win32 --cpu=i386 --ws=nogui ACBRWebService.lpi
```

---

## 📦 Release e Alternativas de Build (CI/CD e Docker)

O projeto gera binários para **3 plataformas** no diretório `bin/`:

| Plataforma | Arquivo |
|-----------|---------|
| 🐧 Linux x86_64 | `ACBRWebService-x86_64-linux` |
| 🪟 Windows x86_64 | `ACBRWebService-x86_64-win64.exe` |
| 🪟 Windows i386 | `ACBRWebService-i386-win32.exe` |

### 🤖 Release Automático (GitHub Actions)

O workflow de CI/CD (`.github/workflows/release.yml`) é acionado ao enviar uma **tag Git** com prefixo `v`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

### 🐳 Build via Docker (Opcional)

Se preferir compilar dentro de um container isolado sem instalar o FPC/Lazarus na máquina host:

```cmd
docker-build.bat
```
Ou manualmente:
```bash
docker build --target builder -t acbr-webservice-builder src
docker run --rm -v "$(pwd):/workspace" -w "/workspace/src" acbr-webservice-builder bash -c "dos2unix ./build.sh && chmod +x ./build.sh && ./build.sh"
```

---

## 📝 Licença

O projeto ACBRWebService é licenciado sob a mesma licença do projeto ACBR.

## ⚠️ Aviso

O nome "ACBR" pertence ao [Projeto ACBr](https://www.projetoacbr.com.br/). Este projeto não tem vínculo oficial.
A ACBR agora também possui uma API própria — confira em [acbr.api.br](https://www.acbr.api.br/).

---

## 🤖 Regras para Inteligência Artificial

Este repositório possui diretrizes rigorosas para agentes de IA para evitar a geração de arquivos indesejados e vazamentos. 
Consulte o arquivo **[docs/ai_rules.md](docs/ai_rules.md)** para entender os limites de workspace e o uso obrigatório de diretórios temporários (`/tmp`).
