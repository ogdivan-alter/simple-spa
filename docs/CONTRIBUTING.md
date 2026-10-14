# Guía de contribución — `simple-spa`

Convenciones de **ramas** y **commits** de este repositorio. El objetivo es
mantener un historial legible y habilitar la automatización del CI/CD
(changelog y versionado semántico).

---

## 1. Ramas

| Rama | Propósito | Entorno |
|---|---|---|
| `main` | Línea estable (integración previa a producción) | staging |
| `develop` | Integración | development (local) |
| `production` | Código desplegado en producción | production |
| `feature/<tema>` | Nueva funcionalidad o trabajo | — |
| `fix/<tema>` | Corrección de errores | — |
| `hotfix/<tema>` | Corrección urgente sobre producción | — |
| `release/<version>` | Preparación de una entrega | — |

Flujo de promoción mediante **Pull Requests**:

```text
feature/* ──PR──▶ develop ──PR──▶ main ──PR──▶ production
```

Reglas:

- Nombra las ramas en minúsculas y separa palabras con guiones: `feature/paso1-compose`.
- Una rama = un tema. Evita mezclar cambios no relacionados.
- El deploy a `staging`/`production` ocurre **al mergear el PR**, nunca por push directo.

---

## 2. Commits (Conventional Commits)

Formato:

```text
<tipo>(<alcance>): <descripción>

[cuerpo opcional]

[footer opcional]
```

- **tipo**: palabra clave en inglés (ver tabla).
- **alcance**: opcional; módulo afectado (`compose`, `ci`, `dockerfile`, `spa`, ...).
- **descripción**: en español, en imperativo, minúscula inicial y sin punto final.

### Tipos

| Tipo | Uso | ¿Genera release? |
|---|---|---|
| `feat` | Nueva funcionalidad | Sí (MINOR) |
| `fix` | Corrección de un error | Sí (PATCH) |
| `docs` | Solo documentación | No |
| `chore` | Mantenimiento (config, tooling, dependencias) | No |
| `refactor` | Reestructurar sin cambiar comportamiento | No |
| `test` | Añadir o ajustar pruebas | No |
| `ci` | Cambios en el pipeline de CI/CD | No |
| `build` | Build o dependencias de empaquetado | No |
| `perf` | Mejora de rendimiento | No |
| `style` | Formato o espacios (sin cambio de lógica) | No |

### Breaking changes

Marca los cambios incompatibles con `!` tras el tipo/alcance y descríbelos en el footer:

```text
feat(api)!: cambia el formato de respuesta

BREAKING CHANGE: el endpoint /saludo ahora devuelve JSON.
```

### Ejemplos

```text
feat(compose): Docker Compose para desarrollo local y smoke tests
fix(entrypoint): usa PORT por defecto si la variable está vacía
docs(readme): documenta el uso de compose
chore(gitattributes): fuerza LF en YAML y archivos .env
ci: añade workflow de build en pull_request
```

---

## 3. Por qué estas convenciones

- **Historial legible y filtrable** (`git log --grep="^feat"`).
- **Automatización**: permite generar el changelog y calcular versiones semánticas
  en el pipeline (`semantic-release` / `release-please`).
- **Distinción semántica**: `feat`/`fix` cambian el comportamiento del producto;
  `chore`/`docs`/`ci` no.

---

## 4. Versionado y flujo de release

La versión vive en un único sitio: **`docker/version/VERSION.txt`** (formato
`X.Y.Z`, SemVer). Es la fuente que usan los builds locales y el pipeline para
etiquetar la imagen (`:<version>` en producción).

Para subirla usa el script de bump (no edites el fichero a mano):

```bash
# Linux / macOS
docker/build/linux/bump.sh patch        # 1.0.0 -> 1.0.1
docker/build/linux/bump.sh minor        # 1.0.0 -> 1.1.0
docker/build/linux/bump.sh major        # 1.0.0 -> 2.0.0
docker/build/linux/bump.sh VERSION=2.1.0
```

```bat
REM Windows
docker\build\win\bump.bat patch
docker\build\win\bump.bat minor
docker\build\win\bump.bat major
docker\build\win\bump.bat VERSION=2.1.0
```

El script **solo actualiza `VERSION.txt`** (no hace commit). El incremento debe
acompañar al tipo de cambio que se entrega: `fix` → PATCH, `feat` → MINOR,
cambio incompatible → MAJOR (ver §2).

Flujo de release (promoción desde `release/<version>`):

```text
release/<version> ──PR──▶ main ──PR──▶ production
```

1. Crea la rama desde `develop`: `git switch -c release/1.1.0 develop`.
2. Ejecuta el bump (`bump.sh minor`) y comprueba `VERSION.txt`.
3. Commit siguiendo §2: `chore(release): 1.1.0`.
4. PR `release/1.1.0 → main`; al mergear, `cd.yml` publica `:staging`.
5. PR `main → production`; al mergear y aprobar el Environment `production`,
   `cd.yml` publica `:1.1.0` / `:latest` y despliega producción.

> El bump se mantiene **fuera del pipeline** a propósito: la versión se decide y
> revisa en el PR de release, no se auto-incrementa en cada merge.

---

## 5. Referencias

- Conventional Commits: <https://www.conventionalcommits.org/>
- Semantic Versioning: <https://semver.org/>
