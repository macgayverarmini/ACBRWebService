@echo off
setlocal

rem Path to lazbuild
set LAZBUILD_CMD=C:\fpcupdeluxe\lazarus\lazbuild.exe

if not exist "%LAZBUILD_CMD%" (
    echo Error: lazbuild not found at %LAZBUILD_CMD%
    echo Please update the script with the correct path to lazbuild.exe.
    exit /b 1
)

echo Compiling ACBRWebService...
cd src
"%LAZBUILD_CMD%" -B --os=win64 --cpu=x86_64 ACBRWebService.lpi
cd ..
if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed!
    exit /b 1
)

echo Compilation successful!
endlocal
