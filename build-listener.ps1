<#
.SYNOPSIS
    build-listener.ps1 — Listener HTTP para notificações do build Docker.

.DESCRIPTION
    Abre um servidor HTTP na porta 9999 e fica esperando o build.sh enviar
    um POST com o resultado. Quando recebe, exibe o resultado e opcionalmente
    emite um som ou abre o terminal.

.EXAMPLE
    .\build-listener.ps1                  # Escuta na porta 9999
    .\build-listener.ps1 -Port 8888       # Escuta numa porta diferente
    .\build-listener.ps1 -Timeout 3600    # Timeout de 1 hora
#>
param(
    [int]$Port = 9999,
    [int]$Timeout = 7200  # 2 horas (default)
)

$ErrorActionPreference = "Stop"

# --- Banner ---
Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  ACBRWebService Build Listener" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "  Porta:   $Port" -ForegroundColor Gray
Write-Host "  Timeout: $Timeout segundos" -ForegroundColor Gray
Write-Host "  PID:     $PID" -ForegroundColor Gray
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Aguardando notificacao do Docker build..." -ForegroundColor Yellow
Write-Host "  (Pressione Ctrl+C para cancelar)" -ForegroundColor DarkGray
Write-Host ""

# --- Criar listener HTTP ---
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")

try {
    $listener.Start()
} catch {
    Write-Host "[ERRO] Nao foi possivel abrir a porta $Port." -ForegroundColor Red
    Write-Host "       Tente executar como Administrador ou use outra porta." -ForegroundColor Red
    Write-Host "       Erro: $_" -ForegroundColor DarkRed
    exit 1
}

$startTime = Get-Date
$received = $false

try {
    while (-not $received) {
        # Verifica timeout
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -ge $Timeout) {
            Write-Host ""
            Write-Host "[TIMEOUT] Nenhuma notificacao recebida em $Timeout segundos." -ForegroundColor Red
            break
        }

        # Espera conexão com timeout de 5 segundos (para permitir Ctrl+C)
        $contextTask = $listener.GetContextAsync()
        $waitResult = $contextTask.AsyncWaitHandle.WaitOne(5000)

        if (-not $waitResult) {
            # Mostra um "heartbeat" a cada 30 segundos
            $secs = [math]::Floor($elapsed.TotalSeconds)
            if ($secs % 30 -eq 0 -and $secs -gt 0) {
                $mins = [math]::Floor($elapsed.TotalMinutes)
                Write-Host "  ... aguardando ha ${mins}m (timeout em $([math]::Floor(($Timeout - $secs) / 60))m)" -ForegroundColor DarkGray
            }
            continue
        }

        $context = $contextTask.Result
        $request = $context.Request
        $response = $context.Response

        # Lê o body do POST
        $reader = New-Object System.IO.StreamReader($request.InputStream)
        $body = $reader.ReadToEnd()
        $reader.Close()

        # Responde ao Docker/curl
        $responseString = "OK"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
        $response.ContentLength64 = $buffer.Length
        $response.StatusCode = 200
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.OutputStream.Close()

        $received = $true

        # --- Processa o resultado ---
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "  NOTIFICACAO RECEBIDA!" -ForegroundColor Cyan
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host ""

        try {
            $data = $body | ConvertFrom-Json

            $totalMins = [math]::Floor($data.elapsed_seconds / 60)
            $totalSecs = $data.elapsed_seconds % 60

            switch ($data.status) {
                "SUCCESS" {
                    Write-Host "  Status:  SUCESSO" -ForegroundColor Green
                    Write-Host "  Tempo:   ${totalMins}m${totalSecs}s" -ForegroundColor Green
                    Write-Host "  Alvos:   $($data.targets_ok)" -ForegroundColor Green
                    Write-Host ""

                    # Beep de sucesso (3 beeps curtos)
                    [console]::beep(800, 200)
                    Start-Sleep -Milliseconds 100
                    [console]::beep(1000, 200)
                    Start-Sleep -Milliseconds 100
                    [console]::beep(1200, 300)
                }
                "PARTIAL" {
                    Write-Host "  Status:  PARCIAL" -ForegroundColor Yellow
                    Write-Host "  Tempo:   ${totalMins}m${totalSecs}s" -ForegroundColor Yellow
                    Write-Host "  OK:      $($data.targets_ok)" -ForegroundColor Green
                    Write-Host "  FALHA:   $($data.targets_failed)" -ForegroundColor Red
                    Write-Host ""

                    # Beep de aviso
                    [console]::beep(400, 500)
                    Start-Sleep -Milliseconds 200
                    [console]::beep(400, 500)
                }
                "FAILED" {
                    Write-Host "  Status:  FALHOU" -ForegroundColor Red
                    Write-Host "  Tempo:   ${totalMins}m${totalSecs}s" -ForegroundColor Red
                    Write-Host "  Msg:     $($data.message)" -ForegroundColor Red
                    Write-Host ""

                    # Beep de erro (tom grave longo)
                    [console]::beep(200, 1000)
                }
                default {
                    Write-Host "  Status desconhecido: $($data.status)" -ForegroundColor Magenta
                    Write-Host "  Body: $body" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "  (Nao foi possivel parsear JSON)" -ForegroundColor DarkGray
            Write-Host "  Body bruto: $body" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan

        # --- Verificar binários no disco ---
        Write-Host ""
        Write-Host "  Verificando binarios no disco..." -ForegroundColor Gray

        $binDir = Join-Path $PSScriptRoot "bin"
        $expectedFiles = @(
            "ACBRWebService-x86_64-linux",
            "ACBRWebService-x86_64-win64.exe",
            "ACBRWebService-i386-win32.exe"
        )

        foreach ($f in $expectedFiles) {
            $fullPath = Join-Path $binDir $f
            if (Test-Path $fullPath) {
                $size = (Get-Item $fullPath).Length
                $sizeMB = [math]::Round($size / 1MB, 1)
                $lastWrite = (Get-Item $fullPath).LastWriteTime.ToString("HH:mm:ss")
                Write-Host "    [OK] $f — ${sizeMB}MB (${lastWrite})" -ForegroundColor Green
            } else {
                Write-Host "    [--] $f — nao encontrado" -ForegroundColor DarkGray
            }
        }

        Write-Host ""
    }
} finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "  Listener encerrado." -ForegroundColor DarkGray
}
