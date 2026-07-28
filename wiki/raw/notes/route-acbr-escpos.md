---
title: Route ACBr ESCPOS Unit Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - routes/route.acbr.escpos.pas
  - method/method.acbr.escpos.pas
tags:
  - escpos
  - printing
  - hardware
---

# Route ACBr ESCPOS (unit route.acbr.escpos)

Defines Horse REST API endpoints for POS thermal receipt printing via ESCPOS protocol.

## Key HTTP Handlers

- `GET /escpos/portas` — Scans system serial/USB COM ports and returns available print ports.
- `GET /escpos/modelo/config` — Sample JSON configuration for ESCPOS printer driver (Epson, Bematech, Daruma, Elgin).
- `POST /escpos/imprimir` — Sends raw text, formatting tags, barcodes, or QR codes to receipt printer.
