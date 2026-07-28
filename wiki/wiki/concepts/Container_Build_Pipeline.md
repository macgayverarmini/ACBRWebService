---
title: Container & Cross-Platform Build Pipeline
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/docker-build-pipeline.md
tags:
  - docker
  - build
  - fpc
  - cross-compilation
---

# Container & Cross-Platform Build Pipeline

The **Container Build Pipeline** allows building ACBRWebService multi-architecture binaries without installing Free Pascal or Lazarus on the local host machine.

```mermaid
flowchart TD
    Host[Windows / Linux Host] -->|docker-build.bat| DockerContainer[Docker Builder Container]
    DockerContainer -->|FPC + Lazarus + Cross-Compilers| Build[build.sh Execution]
    Build --> BinLinux[ACBRWebService-x86_64-linux]
    Build --> BinWin64[ACBRWebService-x86_64-win64.exe]
    Build --> BinWin32[ACBRWebService-i386-win32.exe]
    Build -->|GitHub Tag v*| GitHubActions[GitHub Actions Release Artifacts]
```

## Binary Outputs

- `ACBRWebService-x86_64-linux`
- `ACBRWebService-x86_64-win64.exe`
- `ACBRWebService-i386-win32.exe`

## Related Pages
- [[ACBRWebService_Architecture]]
- [[Lazarus_FPC]]
- [[docker-build-pipeline]]
