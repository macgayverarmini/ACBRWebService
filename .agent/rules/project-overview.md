# Project Overview Rules

This project is a Lazarus/Delphi web service (`.lpr`, `.pas` files).
It heavily utilizes the ACBr library for Brazilian fiscal document processing (NFe, CTe, MDFe, Certificados).

**Key Directories and Their Purpose:**
- `method/`: Contains the business logic and calls to ACBr components.
- `routes/`: Defines API endpoints for the web service.
- `resources/`: Stores string resources and other application assets.
- `tools/`: Contains utility units (e.g., `jsonconvert.pas`, `streamtools.pas`).

**Project Conventions:**
- Prefer Object Pascal/Delphi idioms.
- Follow existing file naming conventions (e.g., `method.acbr.nfe.pas`, `route.acbr.cte.pas`).
- For configuration, if needed, favor the use of `.ini` files due to native support in Lazarus/Delphi.
- Build scripts include `build.sh`, `docker-build.bat`, and `Dockerfile` indicating a multi-platform and containerized environment.

This rule will guide the agent in understanding the project's technological stack, structure, and preferred approaches for new features or modifications.
