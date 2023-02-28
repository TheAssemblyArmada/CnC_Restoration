@echo off
echo Watcom Build Environment
SETLOCAL
SET WATCOM=C:\WATCOM
SET PATH=%WATCOM%\BINW;%PATH%
SET PATH=%WATCOM%\BINNT;%PATH%
SET INCLUDE=%WATCOM%\H\NT;%INCLUDE%
SET INCLUDE=%WATCOM%\H\NT;%INCLUDE%
SET INCLUDE=%INCLUDE%;%WATCOM%\H\NT\DIRECTX
SET INCLUDE=%INCLUDE%;%WATCOM%\H\NT\DDK
SET INCLUDE=%WATCOM%\H;%INCLUDE%
SET WATCOM=%WATCOM%
SET EDPATH=%WATCOM%\EDDAT
SET WHTMLHELP=%WATCOM%\BINNT\HELP
SET WIPFC=%WATCOM%\WIPFC
SET ASM_WASM=WASM.EXE

echo ===========================================
echo Command and Conquer Build Script
echo ===========================================
echo.

REM Copy binaries to the game install directory.
SET COPY_BINARIES=0

REM Path to copy the binaries to.
SET INSTALLPATH=C:\WESTWOOD\CNC95

echo Building ENGLISH binaries
echo -------------------------
echo.
cd TIBERIANDAWN
wmake ENGLISH=1
cd ..

REM echo.
REM echo Building FRENCH binaries
REM echo ------------------------
REM echo.
REM wmake FRENCH=1

REM echo.
REM echo Building GERMAN binaries
REM echo ------------------------
REM echo.
REM wmake GERMAN=1

REM echo.
REM echo Building JAPANESE binaries
REM echo --------------------------
REM echo.
REM wmake JAPANESE=1
ENDLOCAL
pause
