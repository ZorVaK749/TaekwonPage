# TaeKwonPage

Plataforma educativa y de gestión interna para **Taekwon-Do Nahuel Aukan**, desarrollada por **ZVK Tech** para una única escuela de Taekwon-Do ITF.

## Estado y alcance

**Sprint 1 — Knowledge Foundation, en curso.** Bootstrap completado; primer bloque de inventario y procedencia incorporado. Todavía no hay aplicaciones ejecutables, autenticación, base de datos, contenedores ni CI/CD implementados.

La fuente principal de decisiones es [informe_tecnico.md](informe_tecnico.md). Los [ADR](docs/adr/README.md) registran decisiones ya aprobadas, no implementaciones terminadas. Este avance no completa la Fase 0 de conocimiento ni el milestone Content Foundation v0.1.

## Arquitectura aprobada

Monolito modular: un backend con límites internos de dominio, preparado para extraer servicios solo si existe una necesidad real. No se crearán microservicios en esta etapa.

| Área | Tecnología aprobada |
| --- | --- |
| Frontend | Angular, TypeScript |
| Backend | Java 21, Spring Boot, Spring Data JPA, Spring Security |
| API | REST versionada `/api/v1`, OpenAPI |
| Persistencia | PostgreSQL, Flyway |
| Infraestructura | Docker, Docker Compose, GitHub Actions |
| Presupuesto | Objetivo US$0, sin dependencia de un proveedor concreto |

Las versiones concretas de las herramientas y las dependencias se definirán al inicializar cada aplicación. No es necesario instalarlas para revisar este esqueleto.

## Organización del repositorio

| Ruta | Responsabilidad |
| --- | --- |
| `docs/architecture/` | Arquitectura y límites de dominio |
| `docs/adr/` | Registro de decisiones de arquitectura |
| `docs/api/` | Documentación y futuros contratos de API |
| `docs/database/` | Modelo de datos y documentación de migraciones |
| `docs/deployment/` | Despliegue y configuración de ambientes |
| `docs/security/` | Políticas y documentación de seguridad |
| `knowledge/schemas/` | JSON Schemas de fuentes, citas, catálogos y currículo en revisión |
| `knowledge/sources/` | Política de fuentes; PDFs solo locales en `pdfs/` |
| `knowledge/catalogs/` | Catálogos: posiciones, teoría, tuls, vocabulario, herramientas, patadas y combate |
| `knowledge/curricula/gups/` | Currículos que referencian IDs de los catálogos |
| `knowledge/provenance/` | Futuros registros de procedencia documental |
| `backend/taekwonpage-api/` | Futura aplicación Spring Boot modular |
| `frontend/taekwonpage-web/` | Futura aplicación Angular |
| `tools/ingestion/` | Futuras herramientas de extracción y normalización |
| `tools/validators/` | Validadores y tests de fuentes, procedencia, referencias y consistencia curricular |
| `tools/seeders/` | Futuras herramientas de importación de datos aprobados |
| `infrastructure/` | Directorios `docker/`, `local/`, `staging/` y `production/` |

Las carpetas reservadas usan `.gitkeep` únicamente cuando no tienen contenido. Los JSON previos de `Combate/`, `Gups/`, `Herramientas/`, `Patadas/`, `Posiciones/`, `Teoria/`, `Tuls/` y `Vocabulario/` se conservan en su ubicación original: no son catálogos canónicos aprobados por este sprint. Su migración y revisión quedan pendientes.

## Reglas funcionales que deben preservarse

- Roles: `ROLE_GUEST`, `ROLE_STUDENT`, `ROLE_ADMIN` y `ROLE_DEVELOPER`. Rol y grado marcial son independientes.
- `ROLE_ADMIN` representa al Busabonim responsable de la escuela; `ROLE_DEVELOPER`, al mantenimiento técnico de ZVK Tech, sin acceso innecesario a datos personales.
- Todo alumno nuevo comienza con `ROLE_STUDENT`, 10º Gup y estado `UNVERIFIED`, con acceso inicial a 10º Gup.
- Declarar otro grado crea una solicitud `PENDING`; no concede acceso. El administrador la aprueba o rechaza. Solo la aprobación actualiza el grado verificado, con historial y auditoría.
- El acceso es acumulativo y se autoriza en backend. Por ejemplo, un alumno de 4º Gup accede de 10º a 4º, no a 3º ni grados superiores. Ocultar elementos en Angular no es autorización.

## Conocimiento y fuentes

Los catálogos describen contenido; los currículos por Gup referencian únicamente IDs existentes. Los IDs canónicos serán estables, en `snake_case`, minúsculas, sin tildes, `ñ` ni espacios, e inmutables una vez publicados.

No se deben inventar datos marciales ni convertir ejemplos del informe en datos oficiales. El flujo aprobado es: PDF → extracción → normalización → JSON de trabajo → validación → revisión humana → catálogo canónico → seed/migración → PostgreSQL.

Consulta la [política de fuentes locales](knowledge/sources/README.md). Los PDFs están excluidos de Git; no deben publicarse sin autorización de redistribución. Una copia nueva del repositorio no los incluirá.

## Trabajo y validación

1. Leer completo el informe técnico e inspeccionar el trabajo existente.
2. Acordar un cambio acotado por sprint y comunicar contradicciones antes de resolverlas.
3. Mantener separados backend, frontend y conocimiento; justificar cualquier dependencia nueva.
4. Ejecutar las validaciones aplicables y reportar resultados y archivos afectados.
5. No incorporar secretos ni avanzar al siguiente sprint sin indicación.

Convención de commits según el informe: `tipo(ámbito): descripción`, por ejemplo `docs(architecture): document modular monolith`.

No hay builds ni tests de aplicación aún. Fuentes y citas cuentan con [JSON Schemas, validadores y pruebas reproducibles](tools/validators/README.md): Node 24 y Ajv para los contratos portables, más el control PowerShell independiente sin dependencias. No validan conocimiento marcial ni equivalen a aprobación humana.

## Pendientes y límites de este sprint

Consulta [pendientes de arquitectura](docs/architecture/README.md). No se eligieron proveedor de hosting ni estrategia JWT local/OIDC. El [plan de seguridad](docs/security/README.md) queda pendiente para su etapa, sin posponer los controles necesarios para exponer una beta.

Repositorio: https://github.com/ZorVaK749/TaekwonPage, configurado como `origin`. `main` local sigue `origin/main` en `4908799` (commit inicial con licencia MIT, copyright 2026 ZorVaK). El baseline **`83eb531`** y sus bloques posteriores ya están publicados en cuatro ramas de trabajo, con SHA remotos verificados el 16-10-2026. Por instrucción del usuario se hace **push a las ramas, sin Pull Requests ni merges**, preservando `main`. La licencia MIT no concede derechos sobre PDFs de terceros. Véase el [flujo de ramas y versiones](docs/development/README.md).

Rama del bloque actual: `chore/push-only-workflow`, derivada de `ea1037f`. Las ramas son acumulativas sobre el baseline, no parten de un `main` que todavía carece del proyecto. No se crean PR, merges, tags ni releases con esta publicación de avances.

El [estado publicado más reciente](https://github.com/ZorVaK749/TaekwonPage/tree/chore/push-only-workflow) está en esa rama, no en la vista predeterminada de `main`.

El informe incluye Docker Compose entre los entregables de Sprint 0; la instrucción de esta tarea limita el trabajo al esqueleto, sin aplicaciones ni base de datos. Por ello no se incluye un Compose vacío o no funcional: se preparará al habilitar el entorno ejecutable.

**Avance de Sprint 1:** inventario técnico inicial de los cuatro PDFs completado, incluida la consulta bibliográfica e índice de la enciclopedia; no equivale a revisión íntegra ni aprobación humana. Hay una [herramienta local de vistas previas](tools/ingestion/README.md) sin dependencias adicionales.

**Avance técnico:** implementados los [contratos iniciales de fuentes, citas, siete catálogos y currículo](knowledge/schemas/README.md), con controles de referencias por tipo, trazabilidad, biomecánica y secuencias. Hay **19 fichas y 37 citas reales en revisión**, distribuidas en [teoría introductoria](knowledge/provenance/teoria_inicial-review.md), [vocabulario](knowledge/provenance/vocabulario_inicial-review.md), [posiciones y simbolismo](knowledge/provenance/posiciones-y-simbolismo-review.md) y [herramientas/ejercicios parciales](knowledge/provenance/herramientas-y-ejercicios-review.md). La [consulta dirigida de la enciclopedia](knowledge/provenance/ejercicios-enciclopedia-review.md) añadió quince acciones resumidas con alcance explícito; **no son secuencias globales completas**. Cada revisión distingue fuentes y lagunas. La ubicación en el directorio del catálogo no implica aprobación ni publicación.

Para consultar el estado técnico sin repetir la extracción: `npm.cmd --prefix tools/validators run report`. Genera un resumen de conteos, citas por fuente, contenido pendiente y observaciones incompletas; no autoriza publicar.

El seguimiento principal está en las [secciones 55–58 del informe técnico](informe_tecnico.md#55-estado-actual-y-checklist-de-seguimiento): checklist por paso/TKD, validaciones, pendientes y versiones. Se actualizará al cerrar cada bloque sin modificar silenciosamente las decisiones de arquitectura.

**Punto de continuación:** revisar los tramos de ejercicios encontrados, la laguna de legibilidad del punto 3 de Saju Jirugi y el alcance de la ejecución alterna; resolver la variante de `junbi_sogi`, las convenciones de medición y la [autoridad curricular](knowledge/provenance/curricular-authority.md) antes de aprobar requisitos. Todavía no se creó un currículo: `validate:content` debe seguir rechazando esa ausencia. No se rellenan lagunas desde los JSON antiguos ni se pasa a 9º Gup o al siguiente milestone.
