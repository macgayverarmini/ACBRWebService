---
title: Lazarus & Free Pascal Compiler (FPC)
type: entity
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/readme.md
tags:
  - lazarus
  - fpc
  - pascal
---

# Lazarus & Free Pascal Compiler (FPC)

**Lazarus** is a cross-platform IDE for the **Free Pascal Compiler (FPC)**.

- **Role in ACBRWebService**: Target compilation environment (FPC 3.2.0 / Lazarus 2.2.0). The project relies specifically on Lazarus FPC RTTI for dynamic JSON-to-Object transformation.
- **Note**: ACBRWebService is **Lazarus-only** and does not target Delphi due to RTTI implementation differences.
