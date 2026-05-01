@echo off
setlocal enabledelayedexpansion
:: =========================================================================
::  docker-build.bat — Orquestrador de Build ACBRWebService
::  Uso:
::    docker-build.bat              — Build completo (imagem + compilação)
::    docker-build.bat compile      — Só compilação (reutiliza imagem)
::    docker-build.bat image        — Só imagem Docker
::    docker-build.bat auto         — Build completo + notifica listener
:: =========================================================================

set "ORIGINAL_DIR=%cd%"
cd ..

set "IMAGE_NAME=acbr-webservice-builder"
set "NOTIFY_PORT=9999"
set "BUILD_MODE=%~1"

if "%BUILD_MODE%"=="" set "BUILD_MODE=full"

:: --- Verificar Docker ---
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Docker nao esta rodando. Inicie o Docker Desktop e tente novamente.
    cd "%ORIGINAL_DIR%"
    exit /b 1
)

:: --- Build da Imagem ---
if "%BUILD_MODE%"=="compile" goto :COMPILE
if "%BUILD_MODE%"=="auto" goto :BUILD_IMAGE

:BUILD_IMAGE
echo.
echo ========================================================================
echo   FASE 1: Construindo imagem Docker (FPC 3.3.1 Trunk + RTTI)
echo ========================================================================
echo.

docker build --target builder -t %IMAGE_NAME% src
if errorlevel 1 (
    echo [ERRO] Falha ao construir a imagem Docker.
    if "%BUILD_MODE%"=="auto" (
        powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'http://localhost:%NOTIFY_PORT%' -Method POST -Body '{\"status\":\"FAILED\",\"message\":\"Docker image build failed\"}' -ContentType 'application/json' -TimeoutSec 3 } catch {}"
    )
    cd "%ORIGINAL_DIR%"
    exit /b 1
)

if "%BUILD_MODE%"=="image" goto :END
goto :COMPILE

:: --- Compilação via Docker Run ---
:COMPILE
echo.
echo ========================================================================
echo   FASE 2: Compilando projeto (Linux + Win64 + Win32)
echo ========================================================================
echo   Montando diretorio local: %cd%
echo   Notificacao: http://host.docker.internal:%NOTIFY_PORT%
echo ========================================================================
echo.

:: Variável de notificação: se modo "auto", ativa callback
set "NOTIFY_ENV="
if "%BUILD_MODE%"=="auto" set "NOTIFY_ENV=-e NOTIFY_URL=http://host.docker.internal:%NOTIFY_PORT%"

docker run --rm ^
    -v "%cd%:/workspace" ^
    -w "/workspace/src" ^
    %NOTIFY_ENV% ^
    %IMAGE_NAME% ^
    bash -c "dos2unix ./build.sh && chmod +x ./build.sh && ./build.sh"

if errorlevel 1 (
    echo.
    echo [ERRO] Build falhou. Verifique os logs acima.
    if "%BUILD_MODE%"=="auto" (
        powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'http://localhost:%NOTIFY_PORT%' -Method POST -Body '{\"status\":\"FAILED\",\"message\":\"Docker run failed\"}' -ContentType 'application/json' -TimeoutSec 3 } catch {}"
    )
    cd "%ORIGINAL_DIR%"
    exit /b 1
)

:: --- Verificação dos binários ---
echo.
echo ========================================================================
echo   Verificando binarios gerados...
echo ========================================================================
echo.

set "ALL_OK=1"
for %%F in (
    "src\bin\ACBRWebService-x86_64-linux"
    "src\bin\ACBRWebService-x86_64-win64.exe"
    "src\bin\ACBRWebService-i386-win32.exe"
) do (
    if exist "%%~F" (
        for %%A in ("%%~F") do echo   [OK] %%~nxF — %%~zA bytes
    ) else (
        echo   [FALHA] %%~nxF — NAO ENCONTRADO
        set "ALL_OK=0"
    )
)

if "%ALL_OK%"=="1" (
    echo.
    echo   === BUILD COMPLETO COM SUCESSO ===
) else (
    echo.
    echo   === BUILD PARCIAL — Verifique os erros acima ===
)

:END
cd "%ORIGINAL_DIR%"
exit /b 0
