---
title: Container Build & CI/CD Pipeline Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - Dockerfile
  - docker-build.bat
  - build.sh
  - .github/workflows/
tags:
  - docker
  - build
  - ci-cd
---

# Container Build & CI/CD Pipeline

Details the multi-platform build setup for compiling Lazarus / FPC Pascal binaries inside Docker and GitHub Actions.

## Key Build Pipelines

- **Docker Build (`docker-build.bat`)**: Uses Ubuntu container with FPC 3.2.0, Lazarus 2.2.0, and cross-compilers (`i386-win32`, `x86_64-win64`, `x86_64-linux`) to build binaries cleanly without installing FPC locally.
- **GitHub Actions**: Automated release triggering on Git tags starting with `v*`, compiling multi-target binaries and releasing zip artifacts.
