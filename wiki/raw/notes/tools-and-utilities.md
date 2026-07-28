---
title: Tools & Utility Scripts Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - tools/jsonconvert.pas
  - tools/generate_swagger.py
  - tools/update_postman.py
  - tools/compile_resources.py
tags:
  - tools
  - rtti
  - json
  - swagger
  - postman
---

# Tools & Utility Scripts Overview (tools/ folder)

The `tools/` directory contains core helper utilities and automation scripts for the ACBRWebService project.

## Key Components

1. **`jsonconvert.pas` (`TJSONTools`)**: Core Lazarus Pascal RTTI JSON serialization/deserialization utility converting JSON strings to Pascal `TObject` instances and vice-versa.
2. **`generate_swagger.py`**: Python script generating OpenAPI 3.0 / Swagger documentation (`swagger.json`) directly from Horse routes and JSON models.
3. **`update_postman.py`**: Generates updated Postman collection file (`ACBRWebService.postman_collection.json`).
4. **`compile_resources.py`**: Compiles Lazarus `.res` binary resource files for Lazarus projects.
