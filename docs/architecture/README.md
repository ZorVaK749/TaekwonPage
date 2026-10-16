# Arquitectura y decisiones pendientes

Fuente principal: [informe_tecnico.md](../../informe_tecnico.md), leído completo para el bootstrap. Los [ADR](../adr/README.md) registran las decisiones aprobadas. Este documento no modifica el informe ni resuelve decisiones pendientes.

## Límites aprobados

- Una escuela, un backend Spring Boot organizado como monolito modular y un frontend Angular.
- PostgreSQL con Spring Data JPA y Flyway; API REST versionada y OpenAPI.
- Separación entre catálogos, currículos y procedencia; JSON canónico revisado antes de su importación a PostgreSQL.
- Roles independientes del grado y autorización curricular en backend.
- Docker y variables de entorno para portabilidad; presupuesto objetivo US$0.

Los módulos internos de la sección 5 del informe son una propuesta de organización para la futura aplicación. Este sprint no crea paquetes ni fija contratos entre módulos.

## Hallazgos y decisiones pendientes

| Tema | Evidencia / situación | Tratamiento / seguimiento |
| --- | --- | --- |
| Compose | Secciones 14 y 56 lo incluyen; la tarea actual excluye aplicaciones y base de datos | Se difiere el archivo ejecutable; solo se reservan directorios de infraestructura |
| Licencia del proyecto | La sección 14 no define licencia; el remoto indicado contiene `LICENSE` MIT en `4908799` | Historia integrada mediante fetch y rama basada en `origin/main`; licencia recuperada intacta. MIT no licencia los PDFs de terceros |
| Derechos documentales | Los cuatro PDFs están disponibles localmente; no se ha confirmado autorización de redistribución | PDFs y capturas excluidos de Git; Sprint 1 incorpora borradores breves con citas, no aprobacion o publicacion |
| JSON previos | Nueve archivos en las carpetas de la raíz; tres vacíos; sin procedencia documental explícita en los demás | Se preservan sin mover, completar ni aprobar; revisión y migración requieren una tarea posterior |
| Estados de verificación | Sección 8: estados de solicitud `PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`; TKD-017: `UNVERIFIED`, `PENDING`, `VERIFIED`, `REJECTED` | No se unifican enums; falta precisar ciclo de vida del estado del alumno frente al de la solicitud |
| Cambios de grado | Secciones 6.3 y 18 contemplan asignación administrativa directa; la tarea enfatiza el flujo de solicitudes | No se implementa un atajo ni se elimina la previsión del informe; confirmar condiciones antes de desarrollar esa operación |
| Autenticación | Secciones 18 y 19 admiten JWT local u OIDC | No se selecciona estrategia ni proveedor |
| Autoridad curricular | TKD-002 exige resolver discrepancias; la escuela decide los requisitos de examen | No se elige automáticamente una fuente dominante ni se validan datos marciales |
| Infraestructura y herramientas | Proveedor y versiones de aplicaciones pendientes; herramientas de conocimiento ya usan Node 24 y Ajv fijado en lockfile | La herramienta no fija la version del futuro frontend; sin aprovisionamiento o aplicaciones generadas |
| Fases y sprints | La Fase 0 abarca mucho más que el bootstrap | Sprint 0 no completa Fase 0 ni inicia Sprint 1 |

## Trabajo previo conservado

`Combate/`, `Gups/`, `Herramientas/`, `Patadas/`, `Posiciones/`, `Teoria/`, `Tuls/` y `Vocabulario/` quedan intactos. Los JSON de combate, herramientas y patadas están vacíos: no son JSON válidos, pero son trabajo previo y no se eliminan. Los otros seis requieren contrastación con fuentes antes de considerarse canónicos. Una validación sintáctica no demuestra exactitud marcial.

En la inspección de Sprint 0 no había Git local ni se encontró un asset de logo. Posteriormente se vinculó `origin`, se recuperó la licencia del remoto y se creó el baseline `83eb531`. El checkpoint acumulado se integró y publicó en `main` con el merge `1ab81e7`, preservando la historia y sin PR. El flujo autorizado mantiene push por rama y merges periódicos revisados; no cambia la arquitectura ni aprueba el conocimiento marcial. No se generó ni sustituyó el logo. El [informe técnico](../../informe_tecnico.md) contiene el seguimiento, y el [flujo de desarrollo](../development/README.md) describe ramas y versionamiento.
