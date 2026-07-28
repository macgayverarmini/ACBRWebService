---
title: ESCPOS Hardware & Thermal Printing Endpoints
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-escpos.md
tags:
  - escpos
  - hardware
  - printing
---

# ESCPOS Hardware & Thermal Printing Endpoints

The **ESCPOS Hardware Interface** exposes local POS thermal printers (Epson, Bematech, Elgin, Daruma) via REST API calls.

```mermaid
flowchart LR
    Client[HTTP Client] -->|POST /escpos/imprimir| Horse[[Horse_Framework]]
    Horse --> ACBrPosPrinter[[ACBr]]
    ACBrPosPrinter -->|Serial / USB COM / TCP| ThermalPrinter[POS Thermal Receipt Printer]
```

## Route Specifications

| Method | Endpoint Path | Description |
|--------|--------------|-------------|
| `GET` | `/escpos/portas` | Returns JSON array of available COM ports and printer interfaces |
| `GET` | `/escpos/modelo/config` | Returns configuration template for printer models and baud rates |
| `POST` | `/escpos/imprimir` | Transmits print job with formatting tags (`<b>`, `<c>`, `<qrcode>`) |

## Related Pages
- [[ACBRWebService_Architecture]]
- [[route-acbr-escpos]]
- [[ACBr]]
