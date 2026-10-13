@echo off
setlocal enabledelayedexpansion

REM ================================================
REM Ancla las rutas a la ubicacion de este script.
REM   docker\build\win\  ->  DOCKER_DIR = ..\..
REM ================================================
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "DOCKER_DIR=%%~fI"

REM ================================================
REM Funcion de ayuda
REM ================================================
if "%1"=="--help" (
    echo Uso:
    echo   run.bat PORT=3000 HTTP_PROXY=http://host:puerto HTTPS_PROXY=http://host:puerto
    echo.
    echo Ejecuta el contenedor de simple-spa. El proxy indicado es el del RUNTIME
    echo ^(-e^) y puede diferir del proxy de build.
    echo.
    echo Argumentos disponibles:
    echo   VERSION=      Version/tag a ejecutar ^(por defecto: docker\version\VERSION.txt^)
    echo   IMAGE=        Nombre de la imagen ^(por defecto: ogdivan/simple-spa^)
    echo   NAME=         Nombre del contenedor ^(por defecto: simple-spa^)
    echo   PORT=         Puerto host/contenedor ^(por defecto: 3000^)
    echo   HTTP_PROXY=   Proxy HTTP para el runtime
    echo   HTTPS_PROXY=  Proxy HTTPS para el runtime
    echo   NO_PROXY=     Hosts sin proxy para el runtime
    echo   DETACH=       Y en segundo plano, N en primer plano ^(por defecto: Y^)
    echo.
    echo Ejemplos:
    echo   run.bat
    echo   run.bat PORT=8080
    echo   run.bat HTTP_PROXY=http://10.0.0.1:8080
    exit /b 0
)

REM ================================================
REM 1. Valores por defecto
REM ================================================
set "IMAGE=ogdivan/simple-spa"
set "NAME=simple-spa"
set "PORT=3000"
set "HTTP_PROXY="
set "HTTPS_PROXY="
set "NO_PROXY="
set "DETACH=Y"
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
) else if /i "%~1"=="NAME" (
    set "NAME=%~2"
) else if /i "%~1"=="PORT" (
    set "PORT=%~2"
) else if /i "%~1"=="HTTP_PROXY" (
    set "HTTP_PROXY=%~2"
) else if /i "%~1"=="HTTPS_PROXY" (
    set "HTTPS_PROXY=%~2"
) else if /i "%~1"=="NO_PROXY" (
    set "NO_PROXY=%~2"
) else if /i "%~1"=="DETACH" (
    set "DETACH=%~2"
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

set "VERSION=%VERSION: =%"
if "%VERSION%"=="" (
    echo ERROR: La version esta vacia.
    exit /b 1
)

REM ================================================
REM 4. Armar argumentos opcionales
REM ================================================
set "RUN_ARGS=--name %NAME% -p %PORT%:%PORT%"
set "ENV_ARGS=-e PORT=%PORT%"

set "DETACH_LOWER=%DETACH%"
set "DETACH_LOWER=%DETACH_LOWER:Y=y%"
set "DETACH_LOWER=%DETACH_LOWER:N=n%"
if "%DETACH_LOWER%"=="y" (
    set "RUN_ARGS=%RUN_ARGS% -d"
)

if not "%HTTP_PROXY%"==""  set "ENV_ARGS=%ENV_ARGS% -e HTTP_PROXY=%HTTP_PROXY%"
if not "%HTTPS_PROXY%"=="" set "ENV_ARGS=%ENV_ARGS% -e HTTPS_PROXY=%HTTPS_PROXY%"
if not "%NO_PROXY%"==""    set "ENV_ARGS=%ENV_ARGS% -e NO_PROXY=%NO_PROXY%"

echo ================================================
echo IMAGE:  %IMAGE%:%VERSION%
echo NAME:   %NAME%
echo PORT:   %PORT%
echo ================================================

echo Ejecutando: docker run %RUN_ARGS% %ENV_ARGS% %IMAGE%:%VERSION%
docker run %RUN_ARGS% %ENV_ARGS% "%IMAGE%:%VERSION%"
if not %ERRORLEVEL%==0 (
    echo ERROR: Fallo al ejecutar el contenedor.
    exit /b 1
)

echo Contenedor iniciado: %NAME%
echo Acceso: http://localhost:%PORT%/?quien=ALGUIEN
endlocal
exit /b 0
