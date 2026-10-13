@echo off
setlocal enabledelayedexpansion

REM ================================================
REM Ancla las rutas a la ubicacion de este script
REM para poder ejecutarlo desde cualquier carpeta.
REM   docker\build\win\  ->  DOCKER_DIR = ..\..
REM                       ->  ROOT_DIR   = ..\..\..
REM ================================================
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "DOCKER_DIR=%%~fI"
for %%I in ("%SCRIPT_DIR%..\..\..") do set "ROOT_DIR=%%~fI"

REM ================================================
REM Funcion de ayuda
REM ================================================
if "%1"=="--help" (
    echo Uso:
    echo   build.bat PORT=3000 HTTP_PROXY=http://host:puerto HTTPS_PROXY=http://host:puerto NO_PROXY=...
    echo.
    echo Construye la imagen ogdivan/simple-spa a partir de docker\Dockerfile.
    echo El proxy indicado es el del BUILD ^(--build-arg^); puede diferir del
    echo proxy de runtime, que se pasa con "docker run -e".
    echo.
    echo Argumentos disponibles:
    echo   VERSION=      Version/tag a construir ^(por defecto: docker\version\VERSION.txt^)
    echo   IMAGE=        Nombre de la imagen ^(por defecto: ogdivan/simple-spa^)
    echo   PORT=         Puerto del runtime ^(por defecto: 3000^)
    echo   HTTP_PROXY=   Proxy HTTP para el build
    echo   HTTPS_PROXY=  Proxy HTTPS para el build
    echo   NO_PROXY=     Hosts sin proxy para el build
    echo.
    echo Ejemplos:
    echo   build.bat
    echo   build.bat PORT=8080
    echo   build.bat HTTP_PROXY=http://10.0.0.1:8080 HTTPS_PROXY=http://10.0.0.1:8080
    exit /b 0
)

REM ================================================
REM 1. Valores por defecto
REM ================================================
set "IMAGE=ogdivan/simple-spa"
set "PORT=3000"
set "HTTP_PROXY="
set "HTTPS_PROXY="
set "NO_PROXY="
set "VERSION="

REM ================================================
REM 2. Procesar argumentos clave=valor
REM ================================================
:parse
if "%~1"=="" goto :endparse
if /i "%~1"=="VERSION" (
    set "VERSION=%~2"
) else if /i "%~1"=="IMAGE" (
    set "IMAGE=%~2"
) else if /i "%~1"=="PORT" (
    set "PORT=%~2"
) else if /i "%~1"=="HTTP_PROXY" (
    set "HTTP_PROXY=%~2"
) else if /i "%~1"=="HTTPS_PROXY" (
    set "HTTPS_PROXY=%~2"
) else if /i "%~1"=="NO_PROXY" (
    set "NO_PROXY=%~2"
) else (
    echo Parametro desconocido: %~1
    exit /b 1
)
echo Procesando argumento: %~1 = %~2
shift
shift
goto :parse
:endparse

REM ================================================
REM 3. Leer la version desde VERSION.txt si no se indico
REM ================================================
if "%VERSION%"=="" (
    set "VERSION_FILE=%DOCKER_DIR%\version\VERSION.txt"
    if not exist "!VERSION_FILE!" (
        echo ERROR: No existe el archivo de version: !VERSION_FILE!
        exit /b 1
    )
    for /f "usebackq delims=" %%v in ("!VERSION_FILE!") do set "VERSION=%%v"
)

REM Quitar espacios sobrantes de la version
set "VERSION=%VERSION: =%"

if "%VERSION%"=="" (
    echo ERROR: La version esta vacia.
    exit /b 1
)

echo ================================================
echo VERSION:     %VERSION%
echo IMAGE:       %IMAGE%:%VERSION%
echo PORT:        %PORT%
echo HTTP_PROXY:  %HTTP_PROXY%
echo HTTPS_PROXY: %HTTPS_PROXY%
echo NO_PROXY:    %NO_PROXY%
echo ================================================

REM ================================================
REM 4. Ejecutar docker build
REM ================================================
echo Ejecutando docker build...
docker build ^
    --build-arg PORT=%PORT% ^
    --build-arg HTTP_PROXY=%HTTP_PROXY% ^
    --build-arg HTTPS_PROXY=%HTTPS_PROXY% ^
    --build-arg NO_PROXY=%NO_PROXY% ^
    -t "%IMAGE%:%VERSION%" ^
    -f "%DOCKER_DIR%\Dockerfile" ^
    "%ROOT_DIR%"

if not %ERRORLEVEL%==0 (
    echo Build fallo.
    exit /b 1
)

echo Build completado exitosamente: %IMAGE%:%VERSION%
endlocal
exit /b 0
