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
    echo   backup.bat VERSION=1.0.0 IMAGE=ogdivan/simple-spa BACKUP_DIR=ruta
    echo.
    echo Exporta una imagen Docker ^(docker save^) a un archivo .tar en backups.
    echo.
    echo Argumentos disponibles:
    echo   VERSION=      Version/tag a respaldar ^(por defecto: docker\version\VERSION.txt^)
    echo   IMAGE=        Nombre de la imagen ^(por defecto: ogdivan/simple-spa^)
    echo   BACKUP_DIR=   Carpeta destino del .tar ^(por defecto: docker\backups^)
    echo.
    echo Ejemplos:
    echo   backup.bat
    echo   backup.bat VERSION=1.0.0
    echo   backup.bat BACKUP_DIR=D:\respaldos
    exit /b 0
)

REM ================================================
REM 1. Valores por defecto
REM ================================================
set "IMAGE=ogdivan/simple-spa"
set "BACKUP_DIR=%DOCKER_DIR%\backups"
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

REM ================================================
REM 4. Preparar carpeta y nombre del archivo destino
REM ================================================
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1

set "IMAGE_FULL=%IMAGE%:%VERSION%"

REM Convertir "usuario/imagen" en un nombre de archivo seguro
set "SAFE_IMAGE=%IMAGE:/=_%"
set "SAFE_IMAGE=%SAFE_IMAGE::=_%"
set "BACKUP_FILE=%BACKUP_DIR%\%SAFE_IMAGE%_%VERSION%.tar"

echo ================================================
echo IMAGE:      %IMAGE_FULL%
echo VERSION:    %VERSION%
echo BACKUP_DIR: %BACKUP_DIR%
echo ARCHIVO:    %BACKUP_FILE%
echo ================================================

REM ================================================
REM 5. Verificar que la imagen existe localmente
REM ================================================
docker image inspect "%IMAGE_FULL%" >nul 2>&1
if not %ERRORLEVEL%==0 (
    echo ERROR: La imagen "%IMAGE_FULL%" no existe localmente.
    echo        Ejecuta primero el build ^(build.bat^).
    exit /b 1
)

REM ================================================
REM 6. Exportar la imagen
REM ================================================
echo Exportando imagen...
docker save -o "%BACKUP_FILE%" "%IMAGE_FULL%"
if not %ERRORLEVEL%==0 (
    echo ERROR: Fallo al exportar la imagen.
    exit /b 1
)

echo Backup completado: %BACKUP_FILE%
endlocal
exit /b 0
