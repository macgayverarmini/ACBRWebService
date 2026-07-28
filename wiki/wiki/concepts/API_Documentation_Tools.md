---
title: API Documentation & Postman Generators
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/tools-and-utilities.md
tags:
  - swagger
  - postman
  - documentation
---

# API Documentation & Postman Generators

The **API Documentation & Postman Generators** dynamically parse Horse route definitions and JSON models to generate updated OpenAPI 3.0 specs (`swagger.json`) and Postman collections.

```mermaid
flowchart LR
    Routes[Pascal Units routes/route.*.pas] --> PyGen[generate_swagger.py / update_postman.py]
    PyGen --> Swagger[swagger.json / OpenAPI 3.0]
    PyGen --> Postman[ACBRWebService.postman_collection.json]
```

## Related Pages
- [[ACBRWebService_Architecture]]
- [[tools-and-utilities]]
