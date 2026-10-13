@echo off
setlocal enabledelayedexpansion

REM ================================================
REM Ancla las rutas a la ubicacion de este script
REM para poder ejecutarlo desde cualquier carpeta.
REM   docker\build\win\  ->  DOCKER_DIR = ..\..
REM ================================================
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "DOCKER_DIR=%%~fI"
set "VERSION_FILE=%DOCKER_DIR%\version\VERSION.txt"

REM ================================================
REM Leer la version actual
REM ================================================
set "CURRENT="
if exist "%VERSION_FILE%" (
    for /f "usebackq delims=" %%v in ("%VERSION_FILE%") do set "CURRENT=%%v"
)
set "CURRENT=%CURRENT: =%"

if "%1"=="--help" goto :usage
if "%1"=="-h" goto :usage
if "%1"=="" goto :show

REM ================================================
REM Validar que la version actual sea X.Y.Z
REM ================================================
echo %CURRENT%| findstr /r /c:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo ERROR: version actual no valida en "%VERSION_FILE%": "%CURRENT%"
    echo        se espera el formato X.Y.Z
    exit /b 1
)

for /f "tokens=1,2,3 delims=." %%a in ("%CURRENT%") do (
    set "MAJOR=%%a"
    set "MINOR=%%b"
    set "PATCH=%%c"
)

REM ================================================
REM Determinar la nueva version
REM ================================================
set "ARG=%~1"
if /i "%ARG%"=="major" goto :bump_major
if /i "%ARG%"=="minor" goto :bump_minor
if /i "%ARG%"=="patch" goto :bump_patch

REM convencion CLAVE=valor: cmd divide por '=', asi que queda %1=VERSION y %2=x.y.z
if /i "%ARG%"=="VERSION" (
    set "NEW=%~2"
    goto :validate_explicit
)

REM tambien se admite la forma entrecomillada "VERSION=x.y.z"
echo %ARG%| findstr /i /b /c:"VERSION=" >nul
if errorlevel 1 goto :unknown
for /f "tokens=1,* delims==" %%k in ("%ARG%") do set "NEW=%%l"

:validate_explicit
echo !NEW!| findstr /r /c:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo ERROR: VERSION debe ser semver X.Y.Z ^(recibido: "!NEW!"^)
    exit /b 1
)
goto :write

:bump_major
set /a "NEW_MAJOR=MAJOR+1"
set "NEW=!NEW_MAJOR!.0.0"
goto :write

:bump_minor
set /a "NEW_MINOR=MINOR+1"
set "NEW=!MAJOR!.!NEW_MINOR!.0"
goto :write

:bump_patch
set /a "NEW_PATCH=PATCH+1"
set "NEW=!MAJOR!.!MINOR!.!NEW_PATCH!"
goto :write

:write
> "%VERSION_FILE%" echo !NEW!
echo ================================================
echo VERSION anterior: %CURRENT%
echo VERSION nueva:    !NEW!
echo Archivo:          %VERSION_FILE%
echo ================================================
echo Siguiente paso: crear la rama release/!NEW! y abrir el PR.
endlocal
exit /b 0

:show
echo Uso:
echo   bump.bat major^|minor^|patch   Incrementa la parte indicada ^(semver^).
echo   bump.bat VERSION=x.y.z       Fija una version explicita.
echo   bump.bat                     Muestra la version actual.
echo.
echo Version actual: %CURRENT%
endlocal
exit /b 0

:usage
echo Uso:
echo   bump.bat major^|minor^|patch   Incrementa la parte indicada ^(semver^).
echo   bump.bat VERSION=x.y.z       Fija una version explicita.
echo   bump.bat                     Muestra la version actual.
echo.
echo Version actual: %CURRENT%
endlocal
exit /b 0

:unknown
echo ERROR: argumento no reconocido: "%ARG%"
echo.
echo Uso:
echo   bump.bat major^|minor^|patch   Incrementa la parte indicada ^(semver^).
echo   bump.bat VERSION=x.y.z       Fija una version explicita.
endlocal
exit /b 1
