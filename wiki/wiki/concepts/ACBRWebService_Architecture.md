---
title: ACBRWebService Architecture
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/readme.md
tags:
  - architecture
  - rest-api
  - horse
---

# ACBRWebService Architecture

The **ACBRWebService** is designed as an unauthenticated REST microservice bridge wrapping the [[entities/ACBr]] Pascal component suite for fiscal document processing and hardware automation.

```mermaid
flowchart TD
    Req[Incoming HTTP Request] --> Horse[[entities/Horse_Framework]]
    Horse --> Middleware[Jhonson & Handle-Exception Middleware]
    Middleware --> RTTI[Lazarus RTTI JSON Serializer]
    RTTI --> Components[[entities/ACBr]]
    Components --> SEFAZ[SEFAZ / Hardware / Printers]
```

## Component Architecture

1. **HTTP Layer**: Uses [[entities/Horse_Framework]] for route registration and endpoint management.
2. **Serialization Layer**: Leverages Lazarus FPC RTTI (`fpjson` / `jsonrtti`) to reflect incoming JSON body directly to Pascal object instances (`TObject`).
3. **Business & Fiscal Layer**: Delegates document validation, XML parsing, NFe/CTe generation, and ESCPOS printing to [[entities/ACBr]].
4. **Target Platform**: Exclusively targets [[entities/Lazarus_FPC]] compiler environments.
