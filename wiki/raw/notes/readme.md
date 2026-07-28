# 🌐 ACBRWebService

**API REST para integração com a biblioteca ACBR via HTTP.**

> Transforme qualquer microservice em uma central poderosa de documentos fiscais, validações e impressão — tudo via endpoints simples.

---

## 💡 Sobre o Projeto

O ACBRWebService expõe o poder da ACBR através de uma API REST baseada em Lazarus / FPC e o framework Horse.
- Validar documentos nacionais (CPF, CNPJ)
- Gerar DANFE / PDF a partir de XML (Base64)
- Enviar comandos ESCPOS para impressoras
- Ler peso de balanças conectadas
- Emitir e consultar NFe, CTe, etc.

## Requisitos & Dependências
- Free Pascal Compiler (FPC 3.2.0)
- Lazarus 2.2.0
- Horse, Handle-Exception, Jhonson
- ACBR, FortesReport-CE4, PowerPDF

## Build & Release
- Suporta Linux x86_64, Windows x86_64, Windows i386.
- Suporta Docker build (WSL2) e GitHub Actions CI/CD.
