@echo off

SET LAZBUILD="C:\fpcupdeluxe\lazarus\lazbuild.exe"
SET PROJECT="C:\NFMonitor\src\ACBRWebService.lpi"

REM Modify .lpr file in order to avoid nothing-to-do-bug (http://lists.lazarus.freepascal.org/pipermail/lazarus/2016-February/097554.html)
echo. >> "C:\NFMonitor\src\ACBRWebService.lpr"

%LAZBUILD% %PROJECT%

if %ERRORLEVEL% NEQ 0 GOTO END

echo. 

if "%1"=="" goto END

if /i %1%==test (
  "C:\NFMonitor\bin\ACBRWebService.exe" 
)
:END
