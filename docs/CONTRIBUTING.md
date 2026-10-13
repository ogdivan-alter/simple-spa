# Guía de contribución — `simple-spa`

Convenciones de **ramas** y **commits** de este repositorio. El objetivo es
mantener un historial legible y habilitar la automatización del CI/CD
(changelog y versionado semántico).

---

## 1. Ramas

| Rama | Propósito | Entorno |
|---|---|---|
| `main` | Línea estable | — (base) |
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

## 4. Referencias

- Conventional Commits: <https://www.conventionalcommits.org/>
- Semantic Versioning: <https://semver.org/>
