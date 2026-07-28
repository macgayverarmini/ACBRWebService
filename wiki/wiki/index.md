# Index — NFMonitor & ACBRWebService

> Comprehensive architecture, REST endpoint reference, and component knowledge base for ACBRWebService & NFMonitor.

## 🔖 Navigation
- [[#Concepts]] · [[#Entities]] · [[#Summaries]] · [[#Open Questions]]

## Concepts

### Architecture & Design
- [[ACBRWebService_Architecture]] — Core REST microservice architecture wrapping ACBr via Horse & Lazarus RTTI
- [[JSON_RTTI_Serialization]] — Lazarus FPC RTTI reflection engine, in-memory Base64 PFX, and XML ⇄ JSON round-tripping
- [[Container_Build_Pipeline]] — Docker containerized multi-architecture cross-compilation pipeline (Linux & Windows)
- [[API_Documentation_Tools]] — Automated OpenAPI 3.0 Swagger and Postman collection generators

### Document Endpoints & Pipelines
- [[NFe_REST_Endpoints]] — Specification of NFe (Model 55/65) endpoints, DANFE rendering, and SEFAZ pipeline
- [[CTe_REST_Endpoints]] — Specification of CTe (Model 57) transport invoice endpoints and DACTE rendering
- [[NFSe_REST_Endpoints]] — Specification of municipal service invoice (NFSe/RPS) endpoints and provider queries
- [[MDFe_REST_Endpoints]] — Specification of cargo manifest (MDFe Model 58) endpoints and DAMDFE rendering
- [[SPED_Sintegra_Endpoints]] — SPED EFD Fiscal and Sintegra accounting file generation endpoints

### Hardware & Security Integration
- [[ESCPOS_Hardware_Endpoints]] — Thermal receipt printing (Epson/Bematech) and serial port discovery
- [[Digital_Certificate_Management]] — ICP-Brasil A1 PFX certificate upload, parsing, and expiration validation

## Entities

- [[ACBr]] — Open-source commercial automation component suite for Brazilian tax documents (NFe/CTe/NFSe)
- [[Horse_Framework]] — Minimalist web framework for Free Pascal and Delphi
- [[Lazarus_FPC]] — Free Pascal Compiler and Lazarus IDE target compilation environment

## Summaries (chronological)

- 2026-07-28 — [[readme]] — Official ACBRWebService project overview, requirements, and build setup
- 2026-07-28 — [[route-acbr-nfe]] — Route definitions and HTTP handlers for NFe operations
- 2026-07-28 — [[route-acbr-cte]] — Route definitions and HTTP handlers for CTe transport invoices
- 2026-07-28 — [[route-acbr-nfse]] — Route definitions and HTTP handlers for NFSe municipal service invoices
- 2026-07-28 — [[route-acbr-mdfe]] — Route definitions and HTTP handlers for MDFe cargo manifests
- 2026-07-28 — [[route-acbr-escpos]] — Route definitions and HTTP handlers for POS ESCPOS printing
- 2026-07-28 — [[route-acbr-certificados]] — Route definitions and HTTP handlers for A1 PFX digital certificates
- 2026-07-28 — [[route-acbr-sped-sintegra]] — Route definitions for SPED EFD and Sintegra fiscal reporting
- 2026-07-28 — [[docker-build-pipeline]] — Containerized cross-compilation pipeline details
- 2026-07-28 — [[nfse-validada]] — Technical validation memo detailing RTTI RPS fixes and National DFe integration
- 2026-07-28 — [[tools-and-utilities]] — Overview of TJSONTools, Swagger generator, and Postman builders

## Open Questions

- How is the ACBRWebService SOAP/REST endpoint lifecycle structured?
- What are the primary dataset definitions and database connections in NFMonitor?
