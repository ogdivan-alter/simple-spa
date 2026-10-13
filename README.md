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

Muestra una página sencilla con un saludo personalizado: si se indica un nombre,
la página lo saluda como *"Bienvenido \<nombre\>"*. No requiere base de datos ni
servicios externos.

---

## Entornos

| Entorno | Descripción |
|---|---|
| **Desarrollo** | Se ejecuta en la máquina local; ideal para trabajar y ver los cambios al instante. |
| **Staging** (pre-producción) | Réplica previa a producción, para validar antes de publicar. |
| **Producción** | Versión estable disponible para los usuarios. |

---

## Flujo de trabajo

Los cambios llegan a producción de forma controlada y revisada:

```text
feature → develop → main → production
```

- Cada funcionalidad se desarrolla en su **propia rama**.
- Se integra mediante **Pull Request** (revisión + validación automática).
- La promoción entre entornos también se hace por **Pull Request**;
  el paso a **producción requiere aprobación**.

---

## Estado del proyecto

- [x] Aplicación creada y contenedorizada.
- [x] Entorno de desarrollo reproducible en local.
- [ ] Integración continua (automatización al proponer un cambio).
- [ ] Despliegue en la nube por entornos.
- [ ] Validación del ciclo completo (cambio → Pull Request → nube).

---

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) | Convenciones de ramas y commits. |
| [`docker/README.md`](docker/README.md) | Guía técnica de uso y procedimientos. |

---

## Autor

Orlando Gómez Divantoque
