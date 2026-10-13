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
    echo   reset.bat VERSION=1.0.0 IMAGE=ogdivan/simple-spa
    echo.
    echo Elimina la imagen de simple-spa y los contenedores locales que
    echo dependen de ella ^(docker rm -f + docker rmi^).
    echo.
    echo Argumentos disponibles:
    echo   VERSION=      Version/tag a eliminar ^(por defecto: docker\version\VERSION.txt^)
    echo   IMAGE=        Nombre de la imagen ^(por defecto: ogdivan/simple-spa^)
    echo.
    echo Ejemplos:
    echo   reset.bat
    echo   reset.bat VERSION=1.0.0
    echo   reset.bat IMAGE=ogdivan/simple-spa
    exit /b 0
)

REM ================================================
REM 1. Valores por defecto
REM ================================================
set "IMAGE=ogdivan/simple-spa"
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

set "IMAGE_FULL=%IMAGE%:%VERSION%"

echo ================================================
echo IMAGE:   %IMAGE_FULL%
echo ================================================

REM ================================================
REM 4. Eliminar contenedores creados desde la imagen
REM ================================================
echo Eliminando contenedores asociados...
set "FOUND=0"
for /f "delims=" %%i in ('docker ps -a -q --filter "ancestor=%IMAGE_FULL%"') do (
    echo   - contenedor %%i
    docker rm -f %%i >nul
    set "FOUND=1"
)
if "%FOUND%"=="0" echo   ^(sin contenedores asociados^)

REM ================================================
REM 5. Eliminar la imagen
REM ================================================
docker image inspect "%IMAGE_FULL%" >nul 2>&1
if not %ERRORLEVEL%==0 (
    echo La imagen "%IMAGE_FULL%" no existe localmente. Nada que eliminar.
    endlocal
    exit /b 0
)

echo Eliminando imagen...
docker rmi "%IMAGE_FULL%"
if not %ERRORLEVEL%==0 (
    echo ERROR: Fallo al eliminar la imagen.
    exit /b 1
)

echo Reset completado.
endlocal
exit /b 0
