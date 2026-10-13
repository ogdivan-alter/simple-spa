# Procedimiento Operativo Estándar: Imagen Docker `ogdivan/simple-spa`

## 1. Propósito y Alcance

Este documento define el procedimiento técnico estándar para el ciclo de vida
de la imagen Docker de la SPA estática (`ogdivan/simple-spa`): lectura
automatizada de versión, configuración de red/proxy (build y runtime),
compilación, auditoría obligatoria de seguridad con Docker Scout, publicación
controlada en Docker Hub y respaldo/restauración offline. Sirve además como
base para la futura automatización CI/CD.

---

## 2. Prerrequisitos

- Motor de Docker (Docker Engine / Docker Desktop) instalado y en ejecución.
- CLI de Docker con el plugin Docker Scout activado (`docker scout`).
- Imagen base `ogdivan/appmin-py:1.0.0` disponible local o en el registro.
- Archivo de versión en `docker/version/VERSION.txt` (fuente única).
- Credenciales activas en Docker Hub para el repositorio `ogdivan/simple-spa`.

---

## 3. Patrón build → runtime

El `Dockerfile` está dividido en dos stages y separa responsabilidades:

| Fase | Configuración | Mecanismo |
|------|---------------|-----------|
| **build** | Proxy del build | `ARG HTTP_PROXY/HTTPS_PROXY/NO_PROXY` (no persiste) |
| **runtime** | Puerto (`PORT`/`EXPOSE`) | `ARG PORT` → `ENV PORT` → `EXPOSE ${PORT}` |
| **runtime** | Proxy del runtime | `docker run -e HTTP_PROXY=...` (independiente del build) |

**Regla clave:** el proxy del build y el del runtime son independientes y pueden
tener valores distintos. El puerto es un concepto exclusivo del runtime y su
valor por defecto (`3000`) debe coincidir entre el `Dockerfile` y
`docker/scripts/entrypoint.sh`.

---

## 4. Procedimiento Paso a Paso

### Paso 1: Verificación de la Versión

`docker/version/VERSION.txt` es la **fuente única** de la versión (formato `X.Y.Z`).

1. Para subir la versión usa el script de bump (no edites el fichero a mano):

   ```bash
   # Linux / macOS
   docker/build/linux/bump.sh patch        # 1.0.0 -> 1.0.1
   docker/build/linux/bump.sh minor        # 1.0.0 -> 1.1.0
   docker/build/linux/bump.sh VERSION=2.1.0
   ```

   ```cmd
   REM Windows
   docker\build\win\bump.bat patch
   docker\build\win\bump.bat minor
   docker\build\win\bump.bat VERSION=2.1.0
   ```

2. Verificar que contenga únicamente el número de versión deseado (ej. `1.0.0`).

El incremento acompaña al tipo de cambio entregado: `fix` → PATCH, `feat` → MINOR,
cambio incompatible → MAJOR. El detalle del flujo de release está en
`docs/CONTRIBUTING.md` (§4).

### Paso 2: Configuración de Parámetros de Red y Proxy (build)

Durante la compilación se pasan las variables de proxy del build vía
`--build-arg` (ver sección 3). Valores por defecto: vacío (sin proxy).

### Paso 3: Compilación de la Imagen

Opción A: Windows (`docker\build\win\build.bat`)

```cmd
build.bat HTTP_PROXY=http://1.1.1.1:80 HTTPS_PROXY=http://1.1.1.1:80
```

Opción B: Linux / Bash / CI (`docker/build/linux/build.sh`)

```bash
./build.sh HTTP_PROXY=http://1.1.1.1:80 HTTPS_PROXY=http://1.1.1.1:80
```

Ambos construyen con contexto en la raíz del proyecto (`-t ogdivan/simple-spa:<versión>`),
usando `-f docker/Dockerfile`.

### Paso 4: Ejecución (runtime)

```bash
./run.sh PORT=3000
# o con proxy de runtime distinto al del build:
./run.sh PORT=3000 HTTP_PROXY=http://10.0.0.1:8080
```

Acceso: `http://localhost:<PORT>/?quien=ALGUIEN`.

---

## 5. Auditoría de Seguridad Obligatoria (Docker Scout)

Antes de publicar la imagen es requisito ejecutar el escaneo de vulnerabilidades.

1. Inspección general:
   ```bash
   docker scout quickview ogdivan/simple-spa:${VERSION}
   ```
2. Críticas (criterio bloqueante):
   ```bash
   docker scout cves --only-severity critical ogdivan/simple-spa:${VERSION}
   ```
3. Recomendaciones de actualización de la imagen base:
   ```bash
   docker scout recommendations ogdivan/simple-spa:${VERSION}
   ```

**Criterio de cierre:** la imagen NO debe publicarse si contiene vulnerabilidades
`CRITICAL` (el pipeline CI lo verifica y bloquea el PR con Docker Scout,
`only-severities: critical`). Las `HIGH`/`MEDIUM`/`LOW` se revisan pero no bloquean.
En caso de `CRITICAL`, corregir dependencias o actualizar la imagen base y repetir
la compilación.

---

## 6. Publicación y Versionado (Docker Hub)

1. Autenticación:
   ```bash
   docker login
   ```
2. Publicación del tag:
   ```bash
   docker push ogdivan/simple-spa:${VERSION}
   ```

---

## 7. Backup y Restauración de la Imagen

La imagen se exporta a `.tar` (offline) con `docker save` y se reimporta con
`docker load`. Los scripts anclan las rutas a su propia ubicación.

- **Backup** (`docker/build/{win,linux}/backup.*`): exporta a
  `docker/backups/ogdivan_simple-spa_<versión>.tar`.
- **Restore** (`docker/build/{win,linux}/restore.*`): reimporta desde el `.tar`
  (ruta directa con `FILE=` o deducida de `VERSION`/`IMAGE`).
- **Reset** (`docker/build/{win,linux}/reset.*`): limpieza local; elimina los
  contenedores asociados a la imagen (`docker rm -f`) y luego la imagen
  (`docker rmi`).

```bash
./backup.sh
./restore.sh VERSION=1.0.0
./restore.sh FILE=backups/ogdivan_simple-spa_1.0.0.tar
./reset.sh
```

---

## 8. Análisis Crítico y Mejores Prácticas

1. **Separación build/runtime**: el proxy de build no persiste en la imagen; el
   proxy de runtime se inyecta con `-e` y puede diferir.
2. **Puerto parametrizable**: una sola variable `PORT`, alineada entre
   `Dockerfile`, `entrypoint.sh` y scripts `run`.
3. **Usuario no root**: el proceso corre como `appuser` (UID 10001).
4. **`HEALTHCHECK`**: verifica la disponibilidad del servidor en `PORT`.
5. **Contexto mínimo**: `.dockerignore` reduce el contexto de build.
6. **Portabilidad CI/CD**: scripts `.sh` para corredores Linux y `.bat` para
   Windows, con códigos de salida y `--help`, listos para integrarse en un
   pipeline.

---

## 9. Base para CI/CD

El flujo determinista y no interactivo de este procedimiento es la base del
pipeline previsto:

```
[bump] → [version/VERSION.txt] → build.sh → (docker scout) → push → backup.sh
```

Cada paso expone parámetros `CLAVE=valor` y códigos de salida adecuados para su
invocación desde GitHub Actions o GitLab CI.
