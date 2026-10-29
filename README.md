# TaeKwonPage

Plataforma educativa y de gestión interna para **Taekwon-Do Nahuel Aukan**, desarrollada por **ZVK Tech** para una única escuela de Taekwon-Do ITF.

## Estado y alcance

**Knowledge Foundation en curso; base de persistencia y arranque Spring Boot implementados.** Hay PostgreSQL local, Flyway, exportador de borradores y lectura interna de posiciones con citas documentales. El backend bloquea contenido por HTTP; solo expone salud sin detalles. Angular, autenticación funcional y CI/CD siguen pendientes, al igual que el currículo y la aprobación marcial.

La fuente principal de decisiones es [informe_tecnico.md](informe_tecnico.md). Los [ADR](docs/adr/README.md) registran decisiones ya aprobadas, no implementaciones terminadas. Este avance no completa la Fase 0 de conocimiento ni el milestone Content Foundation v0.1.

Para ver el avance con checks por fase y los pendientes de Fases 0/1: **[Plan de ataque](Plan_ataque.md)**.

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
| `backend/taekwonpage-api/` | Spring Boot Java 21, Flyway y primera lectura interna de posiciones |
| `frontend/taekwonpage-web/` | Futura aplicación Angular |
| `tools/ingestion/` | Futuras herramientas de extracción y normalización |
| `tools/validators/` | Validadores y tests de fuentes, procedencia, referencias y consistencia curricular |
| `tools/seeders/` | Exportador transaccional de borradores locales, no seed aprobado |
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

El [backend](backend/taekwonpage-api/README.md) se construye y prueba con Maven y Testcontainers/PostgreSQL. Fuentes y citas cuentan con [JSON Schemas, validadores y pruebas reproducibles](tools/validators/README.md): Node 24 y Ajv para los contratos portables, más el control PowerShell independiente sin dependencias. No validan conocimiento marcial ni equivalen a aprobación humana.

## Pendientes y límites de este sprint

Consulta [pendientes de arquitectura](docs/architecture/README.md). No se eligieron proveedor de hosting ni estrategia JWT local/OIDC. El [plan de seguridad](docs/security/README.md) queda pendiente para su etapa, sin posponer los controles necesarios para exponer una beta.

Repositorio: https://github.com/ZorVaK749/TaekwonPage, configurado como `origin`. El primer checkpoint del baseline **`83eb531`** y sus bloques posteriores se publicó en `main` mediante **`1ab81e7`**, conservando su historial. El flujo actual es **trabajo y push en ramas, con merges periódicos de checkpoints revisados a `main`, sin Pull Requests**. La licencia MIT no concede derechos sobre PDFs de terceros. Véase el [flujo de ramas y versiones](docs/development/README.md).

Bloque actual: **Fase 0**, [laguna de legibilidad de Saju Jirugi](knowledge/provenance/ejercicios-enciclopedia-review.md) verificada con recortes ampliados (resultado negativo: tinta erosionada, laguna conservada), con 78 fichas y 140 citas en revisión, más matrices de cobertura de teoría, vocabulario y cuerpo para el revisor. Las tablas de vocabulario **no son idénticas** (ONT 71 filas, WEB 65) y su matriz queda agotada salvo nombres de técnica; el bloque de puntos vitales (kupso) quedó observado sin extraer. El usuario confirmó continuar la verificación documental sin programa/revisor designados. Fase 1 queda abierta; no se amplía backend/frontend ni se publica contenido. Para retomar el proyecto desde otro chat existe un [prompt de continuación](docs/handoff/continuation-prompt.md) con decisiones, estado y límites; el informe técnico prevalece ante discrepancias.

El [checkpoint publicado](https://github.com/ZorVaK749/TaekwonPage/tree/main) ya está disponible en la vista predeterminada de `main`. Los bloques nuevos partirán de ese estado, sin crear ramas acumulativas innecesarias.

Para la BD local: copiar `.env.example` a `.env`, completar contraseña y ejecutar `docker compose up -d --wait postgres`. Flyway puede ejecutarse con `docker compose run --rm migrate` o al arrancar Spring Boot. El [manual del backend](backend/taekwonpage-api/README.md) incluye comandos de ejecución. Compose incluye PostgreSQL/Flyway; el backend corre con Maven/JAR y Angular aún no existe.

**Avance de Sprint 1:** inventario técnico inicial de los cuatro PDFs completado, incluida la consulta bibliográfica e índice de la enciclopedia; no equivale a revisión íntegra ni aprobación humana. Hay una [herramienta local de vistas previas](tools/ingestion/README.md) sin dependencias adicionales.

**Avance técnico:** implementados los [contratos iniciales de fuentes, citas, siete catálogos y currículo](knowledge/schemas/README.md), con controles de referencias por tipo, trazabilidad, biomecánica y secuencias. Hay **78 fichas y 140 citas reales en revisión**, incluidas la [ampliación teórica y su matriz](knowledge/provenance/temario_teorico_10gup-review.md), la [matriz de cobertura del vocabulario](knowledge/provenance/vocabulario-tabla-completa-review.md), las [partes del cuerpo con su matriz](knowledge/provenance/vocabulario-cuerpo-review.md), los [términos generales con su matriz](knowledge/provenance/vocabulario-terminos-generales-review.md) y las [secciones/división lateral del cuerpo](knowledge/provenance/secciones-cuerpo-review.md). La [preparación paralela](knowledge/provenance/posicion_preparatoria_paralela-review.md) tiene variante específica enlazada a los ejercicios. Se conservan los lotes de [teoría](knowledge/provenance/teoria_inicial-review.md), [vocabulario](knowledge/provenance/vocabulario_inicial-review.md), [posiciones y simbolismo](knowledge/provenance/posiciones-y-simbolismo-review.md), [herramientas](knowledge/provenance/herramientas-y-ejercicios-review.md) y [combate/patadas](knowledge/provenance/combate-y-patadas-review.md). Las quince acciones de ejercicios tienen alcance explícito y **no son secuencias globales completas**; conteos, alternancia y legibilidad siguen pendientes. No hay aprobación humana registrada.

Para consultar el estado técnico sin repetir la extracción: `npm.cmd --prefix tools/validators run report`. Genera un resumen de conteos, citas por fuente, contenido pendiente y observaciones incompletas; no autoriza publicar.

El seguimiento principal está en las [secciones 55–58 del informe técnico](informe_tecnico.md#55-estado-actual-y-checklist-de-seguimiento): checklist por paso/TKD, validaciones, pendientes y versiones. Se actualizará al cerrar cada bloque sin modificar silenciosamente las decisiones de arquitectura.

**Punto de continuación:** revisión humana de los enlaces, del punto 3 de Saju Jirugi y de la variante de combate («un paso» frente a «dos pasos»), y confirmación de la [autoridad curricular](knowledge/provenance/curricular-authority.md). El temario observado para 10º a 9º solo cubre teoría, así que el currículo sigue ausente y `validate:content` debe rechazarlo. No se rellenan lagunas desde los JSON antiguos ni se pasa a 9º Gup o al siguiente milestone.
