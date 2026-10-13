# simple-spa (Docker)

> Imagen Docker que sirve la SPA estatica (`src/index.html`) con el servidor
> HTTP de Python. Sigue el patron de imagen base `ogdivan/appmin-py`.

## 🎯 Objetivo

- Empaquetar y servir la SPA estatica en el puerto 3000 (parametrizable).
- Asistir el ciclo **build → run → backup → restore** con scripts reproducibles.
- Mantener scripts equivalentes para Windows y Linux (Debian).
- Soportar build y runtime con configuración de proxy independiente.

## 💻 Sistemas operativos soportados

| OS | Shell | Scripts |
|----|-------|---------|
| Windows 10/11 | CMD / PowerShell | `docker/build/win/*.bat` |
| Linux Debian | Bash | `docker/build/linux/*.sh` |

## 🧱 Entorno principal

| Componente | Tecnología | Versión |
|------------|-----------|---------|
| Contenedores | Docker Engine / Docker Desktop | |
| Imagen base | ogdivan/appmin-py | 1.0.0 |
| Runtime | Python (`http.server`) | incluido en la base |
| Puerto por defecto | 3000 | |

## 📁 Estructura

```
simple-spa/
├── .dockerignore               # Excluye lo innecesario del contexto de build
├── .gitattributes              # Normaliza EOL (.bat CRLF / .sh LF)
├── src/
│   └── index.html              # Contenido de la SPA
└── docker/
    ├── build/
    │   ├── linux/{build,run,backup,restore,reset}.sh
    │   └── win/{build,run,backup,restore,reset}.bat
    ├── docs/
    │   └── procedimiento.md    # Procedimiento detallado
    ├── scripts/
    │   └── entrypoint.sh       # Entry point de la imagen
    ├── version/
    │   └── VERSION.txt         # Versión de la imagen (fuente única)
    ├── .gitignore
    ├── Dockerfile
    └── README.md
```

## ✅ Requisitos previos

- Docker instalado y en ejecución (`docker --version`).
- Windows: CMD o PowerShell. Debian: Bash y permisos para usar Docker.
- Imagen base `ogdivan/appmin-py:1.0.0` disponible localmente o publicada en el registro.
- Archivo `docker/version/VERSION.txt` con la versión a construir (ej. `1.0.0`).

## 🚀 Uso rápido

### 1. Construir la imagen

La versión se lee de `docker/version/VERSION.txt` y la imagen resultante es
`ogdivan/simple-spa:<versión>` (actualmente `1.0.0`).

```powershell
# Windows
cd docker\build\win
.\build.bat
.\build.bat --help
```

```bash
# Debian
cd docker/build/linux
./build.sh
./build.sh --help
```

> Los scripts anclan las rutas a su propia ubicación, por lo que también puedes
> ejecutarlos desde cualquier carpeta.

#### Parámetros de `build` (todos opcionales, formato `CLAVE=valor`)

| Parámetro | Valor por defecto | Descripción |
|-----------|-------------------|-------------|
| `VERSION` | contenido de `docker/version/VERSION.txt` | Tag de la imagen a construir. |
| `IMAGE` | `ogdivan/simple-spa` | Nombre de la imagen. |
| `PORT` | `3000` | Puerto del runtime (se pasa como `--build-arg PORT`). |
| `HTTP_PROXY` | (vacío) | Proxy HTTP **del build** (`--build-arg`). |
| `HTTPS_PROXY` | (vacío) | Proxy HTTPS **del build** (`--build-arg`). |
| `NO_PROXY` | (vacío) | Hosts sin proxy **del build** (`--build-arg`). |

Ejemplo:

```powershell
.\build.bat PORT=8080 HTTP_PROXY=http://10.0.0.1:8080 HTTPS_PROXY=http://10.0.0.1:8080
```

### 2. Ejecutar el contenedor

```powershell
# Windows (docker\build\win)
.\run.bat                # detach en http://localhost:3000
.\run.bat PORT=8080 DETACH=N
```

```bash
# Debian
./run.sh
./run.sh PORT=8080 HTTP_PROXY=http://10.0.0.1:8080
```

Equivalente manual:

```bash
docker run -d --name simple-spa -p 3000:3000 ogdivan/simple-spa:1.0.0
```

Acceso:

```text
http://localhost:3000/?quien=ALGUIEN
```

> **Proxy de build vs runtime:** el proxy del build (`--build-arg`, en `build`)
> y el del runtime (`-e`, en `run`) son independientes y pueden tener valores
> distintos. Ver [`docs/procedimiento.md`](docs/procedimiento.md).

### 3. Backup y restore

Exportan e importan la **imagen Docker** con `docker save` / `docker load`.

```powershell
# Windows (docker\build\win)
.\backup.bat     # Exporta a docker\backups\ogdivan_simple-spa_<versión>.tar
.\restore.bat    # Reimporta la imagen desde el .tar
```

```bash
# Debian
./backup.sh
./restore.sh
```

#### Parámetros de `backup` (opcionales, `CLAVE=valor`)

| Parámetro | Valor por defecto | Descripción |
|-----------|-------------------|-------------|
| `VERSION` | contenido de `docker/version/VERSION.txt` | Tag de la imagen a exportar. |
| `IMAGE` | `ogdivan/simple-spa` | Nombre de la imagen. |
| `BACKUP_DIR` | `docker/backups` | Carpeta destino del `.tar`. |

#### Parámetros de `restore` (opcionales, `CLAVE=valor`)

| Parámetro | Valor por defecto | Descripción |
|-----------|-------------------|-------------|
| `FILE` | — | Ruta directa al `.tar` (tiene prioridad sobre los demás). |
| `VERSION` | contenido de `docker/version/VERSION.txt` | Versión de la que se deduce el `.tar`. |
| `IMAGE` | `ogdivan/simple-spa` | Nombre de la imagen. |
| `BACKUP_DIR` | `docker/backups` | Carpeta de los `.tar`. |

### 4. Reset (limpieza local)

Elimina la imagen y sus contenedores asociados en el entorno local
(`docker rm -f` de los contenedores + `docker rmi` de la imagen).

```powershell
# Windows (docker\build\win)
.\reset.bat
```

```bash
# Debian
./reset.sh
```

#### Parámetros de `reset` (opcionales, `CLAVE=valor`)

| Parámetro | Valor por defecto | Descripción |
|-----------|-------------------|-------------|
| `VERSION` | contenido de `docker/version/VERSION.txt` | Tag de la imagen a eliminar. |
| `IMAGE` | `ogdivan/simple-spa` | Nombre de la imagen. |

## 🔌 Puerto (Dockerfile ↔ entrypoint)

`PORT` es un parámetro único del runtime y debe coincidir en toda la cadena:

| Ubicación | Uso |
|-----------|-----|
| `Dockerfile` | `ARG PORT=3000` → `ENV PORT` → `EXPOSE ${PORT}` |
| `scripts/entrypoint.sh` | `PORT="${PORT:-3000}"` |
| `run.bat` / `run.sh` | `-e PORT=... -p ${PORT}:${PORT}` |

Para cambiarlo, reconstruye con `PORT=xxxx` (afecta `EXPOSE`) y/o ejecuta con
`-e PORT=xxxx -p xxxx:xxxx`.

## 🏷️ Imagen

- Nombre: `ogdivan/simple-spa`
- Tag actual: `1.0.0` (definido en `docker/version/VERSION.txt`)
- Base: `ogdivan/appmin-py:1.0.0`

## 📚 Documentación

Ver [`docs/procedimiento.md`](docs/procedimiento.md) para el procedimiento detallado
(build, auditoría de seguridad, publicación y backup/restore).

## 🛠️ Solución de problemas

| Problema | Posible causa / solución |
|----------|--------------------------|
| `No existe el archivo de version` | Revisa `docker/version/VERSION.txt` (en Linux distingue mayúsculas). |
| `Parametro desconocido` | `build` acepta `VERSION`, `IMAGE`, `PORT`, `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`; `run` además `NAME`, `DETACH`; `backup`/`restore`/`reset` aceptan `VERSION`, `IMAGE` (y `backup`/`restore` además `BACKUP_DIR`, `restore` además `FILE`). |
| Build falla por red | Verifica los `--build-arg` de proxy o deja que la imagen base resuelva el proxy del daemon. |
| `La imagen ... no existe localmente` (backup) | Ejecuta primero el build. |
| `No existe el archivo de backup` (restore) | Ejecuta primero `backup` o indica la ruta con `FILE=...`. |
| Puerto ocupado al ejecutar | Cambia con `run.bat PORT=8080` / `run.sh PORT=8080`. |
| `docker: command not found` | Docker no está instalado o no está en el PATH. |
| `permission denied` (Debian) | Agrega el usuario al grupo `docker` o usa `sudo`. |

## 🗺️ Próximos pasos (ideas)

- [ ] `docker-compose.yml`
- [ ] Pipeline CI/CD (GitHub Actions) apoyado en `docker/build/linux/*.sh`
- [ ] Limpieza/alineación del `.devcontainer`
