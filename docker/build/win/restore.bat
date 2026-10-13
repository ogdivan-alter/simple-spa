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
    echo   restore.bat VERSION=1.0.0 IMAGE=ogdivan/simple-spa BACKUP_DIR=ruta
    echo   restore.bat FILE=ruta\ogdivan_simple-spa_1.0.0.tar
    echo.
    echo Reimporta una imagen Docker ^(docker load^) desde un .tar de backups.
    echo.
    echo Argumentos disponibles:
    echo   FILE=         Ruta directa al .tar ^(tiene prioridad sobre lo demas^)
    echo   VERSION=      Version/tag ^(por defecto: docker\version\VERSION.txt^)
    echo   IMAGE=        Nombre de la imagen ^(por defecto: ogdivan/simple-spa^)
    echo   BACKUP_DIR=   Carpeta de los .tar ^(por defecto: docker\backups^)
    echo.
    echo Ejemplos:
    echo   restore.bat
    echo   restore.bat VERSION=1.0.0
    echo   restore.bat FILE=backups\ogdivan_simple-spa_1.0.0.tar
    exit /b 0
)

REM ================================================
REM 1. Valores por defecto
REM ================================================
set "IMAGE=ogdivan/simple-spa"
set "BACKUP_DIR=%DOCKER_DIR%\backups"
set "FILE="
set "VERSION="

REM ================================================
REM 2. Procesar argumentos clave=valor
REM ================================================
:parse
if "%~1"=="" goto :endparse
if /i "%~1"=="FILE" (
    set "FILE=%~2"
) else if /i "%~1"=="VERSION" (
    set "VERSION=%~2"
) else if /i "%~1"=="IMAGE" (
    set "IMAGE=%~2"
) else if /i "%~1"=="BACKUP_DIR" (
    set "BACKUP_DIR=%~2"
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
REM 3. Deducir el archivo .tar si no se indico FILE
REM ================================================
if "%FILE%"=="" (
    if "%VERSION%"=="" (
        set "VERSION_FILE=%DOCKER_DIR%\version\VERSION.txt"
        if not exist "!VERSION_FILE!" (
            echo ERROR: No existe el archivo de version: !VERSION_FILE!
            exit /b 1
        )
        for /f "usebackq delims=" %%v in ("!VERSION_FILE!") do set "VERSION=%%v"
    )

    set "VERSION=!VERSION: =!"
    set "SAFE_IMAGE=!IMAGE:/=_!"
    set "SAFE_IMAGE=!SAFE_IMAGE::=_!"
    set "FILE=%BACKUP_DIR%\!SAFE_IMAGE!_!VERSION!.tar"
)

echo ================================================
echo ARCHIVO: %FILE%
echo ================================================

if not exist "%FILE%" (
    echo ERROR: No existe el archivo de backup: %FILE%
    echo        Ejecuta primero el backup ^(backup.bat^).
    exit /b 1
)

REM ================================================
REM 4. Importar la imagen
REM ================================================
echo Importando imagen...
docker load -i "%FILE%"
if not %ERRORLEVEL%==0 (
    echo ERROR: Fallo al importar la imagen.
    exit /b 1
)

echo Restore completado.
endlocal
exit /b 0
