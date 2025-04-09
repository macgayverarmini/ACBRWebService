@echo off

SET LAZBUILD="C:\fpcupdeluxe\lazarus\lazbuild.exe"
SET PROJECT="C:\NFMonitor\src\ACBRWebService.lpi"
SET EXECUTABLE="C:\NFMonitor\bin\ACBRWebService.exe"

echo ===================================
echo Pascal Project Build System
echo ===================================

REM Check if lazbuild exists
if not exist %LAZBUILD% (
    echo ERROR: Lazbuild executable not found at %LAZBUILD%
    echo Please check the path in CompileOmniPascalServerProject.bat
    exit /b 1
)

REM Check if project file exists
if not exist %PROJECT% (
    echo ERROR: Project file not found at %PROJECT%
    exit /b 1
)

REM Modify .lpr file in order to avoid nothing-to-do-bug (http://lists.lazarus.freepascal.org/pipermail/lazarus/2016-February/097554.html)
echo. >> "C:\NFMonitor\src\ACBRWebService.lpr"

echo Building project %PROJECT%...

%LAZBUILD% %PROJECT%

if %ERRORLEVEL% NEQ 0 (
    echo Build failed with error code %ERRORLEVEL%
    goto END
)

echo Build completed successfully.

if "%1"=="" goto END

if /i "%1"=="test" (
    if not exist %EXECUTABLE% (
        echo ERROR: Executable not found at %EXECUTABLE%
        exit /b 1
    )
    echo Running application...
    %EXECUTABLE%
)
:END
echo ===================================
