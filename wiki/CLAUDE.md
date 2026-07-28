# NFMonitor & ACBRWebService Knowledge Base

> Schema document — read at the start of every session together with `wiki/index.md`.
> Update after every major compile, ingest batch, or structural change.

## Scope

What this wiki covers:
- Architecture, design patterns, and components of NFMonitor and ACBRWebService (Delphi / FireMonkey / ACBr integrations).
- Data models, database tables, web service endpoints, XML/NFe processing, and background services.
- Codebase guidelines, AST/MCP tool usage (`mcp-firemonkey`), and refactoring history.

What this wiki deliberately excludes:
- Third-party binary builds and unparsed compiled assets.
- Unrelated non-Delphi external repositories.

## Operations

This wiki follows the llm-wiki skill's five operations: `compile`, `ingest`, `query`, `lint`, `audit`.
Every operation appends an entry to `log/YYYYMMDD.md`.

## Naming conventions

- **Concept pages** (`wiki/concepts/`): Title Case noun phrases (e.g. `NFe_Processing_Pipeline.md`).
- **Folder-split concepts** (`wiki/concepts/<topic>/`): used when a topic exceeds ~1200 words. Contains `index.md` + one file per aspect.
- **Entity pages** (`wiki/entities/`): Proper names (e.g. `TACBrNFe.md`, `TFDQuery.md`).
- **Summary pages** (`wiki/summaries/`): kebab-case source slug.

All pages require YAML frontmatter: `title`, `type`, `created`, `updated`, `sources`, `tags`.

### Diagrams and formulas
- All diagrams are **mermaid**. No ASCII art.
- All formulas are **KaTeX** (inline `$...$` or block `$$...$$`).

### Raw file policy
- Small text sources → copy into `raw/<subfolder>/`.
- Large binaries → create a pointer file at `raw/refs/<slug>.md` with `kind: ref` and `external_path` fields. Do not copy the binary.

## Current articles

### Concepts
- [[concepts/ACBRWebService_Architecture]]
- [[concepts/NFe_REST_Endpoints]]
- [[concepts/CTe_REST_Endpoints]]
- [[concepts/NFSe_REST_Endpoints]]
- [[concepts/MDFe_REST_Endpoints]]
- [[concepts/ESCPOS_Hardware_Endpoints]]
- [[concepts/Digital_Certificate_Management]]
- [[concepts/SPED_Sintegra_Endpoints]]
- [[concepts/Container_Build_Pipeline]]
- [[concepts/JSON_RTTI_Serialization]]
- [[concepts/API_Documentation_Tools]]

### Entities
- [[entities/ACBr]]
- [[entities/Horse_Framework]]
- [[entities/Lazarus_FPC]]

### Summaries
- [[summaries/readme]]
- [[summaries/route-acbr-nfe]]
- [[summaries/route-acbr-cte]]
- [[summaries/route-acbr-nfse]]
- [[summaries/route-acbr-mdfe]]
- [[summaries/route-acbr-escpos]]
- [[summaries/route-acbr-certificados]]
- [[summaries/route-acbr-sped-sintegra]]
- [[summaries/docker-build-pipeline]]
- [[summaries/nfse-validada]]
- [[summaries/tools-and-utilities]]

## Open research questions

- How is the ACBRWebService SOAP/REST endpoint lifecycle structured?
- What are the primary dataset definitions and database connections in NFMonitor?

## Research gaps

Sources to ingest:
- [ ] Primary source units (`.pas`, `.fmx`) and configuration files in `C:\NFMonitor\src`

## Audit backlog

*(none — run `python3 scripts/audit_review.py <wiki-root> --open` to refresh)*

## Notes for the LLM

- Language: Portuguese / English (bilingual code context)
- Tone: Deep technical, precise Delphi & FireMonkey conventions
- Depth: Deep architectural & implementation level
- Mandatory Rule: Respect user_global rules for `mcp-firemonkey` on any `.pas` and `.fmx` edits.
- Handling contradictions: state both, cite each, add to Open Research Questions.
