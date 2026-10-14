# simple-spa

Aplicación web estática mínima que sirve una página de **saludo personalizado**.
Es la base de un proyecto de formación cuyo objetivo es recorrer un ciclo
**CI/CD** completo: desarrollar en local, integrar los cambios mediante Pull
Requests, validar en un entorno de pruebas y desplegar en producción en la nube.

---

## Propósito

Demostrar, de forma sencilla y comprensible, el recorrido de una aplicación
contenedorizada desde el código hasta la nube, aplicando buenas prácticas:

- Control de versiones con **ramas por entorno** y promoción mediante Pull Request.
- **Construcción y verificación automáticas** al proponer cambios (CI).
- **Despliegue automatizado** por entornos (CD).
- **Versionado** y convenciones de commits.

---

## ¿Qué hace la aplicación?

Muestra una página sencilla con un saludo personalizado: con `?quien=<nombre>`
muestra «`<nombre>` está por aquí»; sin parámetro, «Alguien está por aquí?».
No requiere base de datos ni servicios externos.

Ejemplo: <https://simple-spa-r9bt.onrender.com/?quien=Orlando>

---

## Entornos

| Entorno | Descripción | URL |
|---|---|---|
| **Desarrollo** | Se ejecuta en la máquina local (Docker Compose); ideal para trabajar y ver los cambios al instante. | `http://localhost:3000` |
| **Staging** (pre-producción) | Réplica previa a producción, para validar antes de publicar. | <https://simple-spa-staging.onrender.com> |
| **Producción** | Versión estable disponible para los usuarios. | <https://simple-spa-r9bt.onrender.com> |

---

## Flujo de trabajo

Los cambios llegan a producción de forma controlada y revisada:

```text
feature → develop → main → production
```

- Cada funcionalidad se desarrolla en su **propia rama**.
- Se integra mediante **Pull Request** (revisión + validación automática).
- La promoción entre entornos también se hace por **Pull Request**; el paso a
  **producción requiere aprobación** (Environment `production` de GitHub).
- Convenciones de ramas y commits en [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).

---

## Pipeline CI/CD

| Workflow | Disparador | Qué hace |
|---|---|---|
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | Pull Request hacia `develop`, `main` o `production` | Valida el flujo de ramas, construye la imagen con Docker Compose, ejecuta un *smoke test* (HTTP 200) y un escaneo **Docker Scout** que bloquea si hay vulnerabilidades **`CRITICAL`**. |
| [`.github/workflows/cd.yml`](.github/workflows/cd.yml) | push a `main` o `production` | Construye y publica la imagen en **Docker Hub** y dispara el *deploy hook* de **Render**. |

Imagen publicada: `ogdivan/simple-spa` con tags `:staging`, `:<versión>`, `:latest` y `:sha-<commit>`.

---

## Estado del proyecto

- [x] Aplicación creada y contenedorizada.
- [x] Entorno de desarrollo reproducible en local (Docker Compose).
- [x] Integración continua (build + smoke test + Docker Scout en cada PR).
- [x] Despliegue en la nube por entornos (Docker Hub → Render).
- [x] Validación del ciclo completo (cambio → Pull Request → nube).

---

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) | Convenciones de ramas, commits, versionado y flujo de release. |
| [`docker/README.md`](docker/README.md) | Guía técnica de uso (scripts `build`, `run`, `backup`, `restore`, `reset`, `bump`). |
| [`docker/docs/procedimiento.md`](docker/docs/procedimiento.md) | Procedimiento operativo detallado de la imagen. |

---

## Autor

Orlando Gómez Divantoque
