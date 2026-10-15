# ADR-005 — Verificación de grado y acceso acumulativo

- Estado: Aceptado; pendiente de implementación.
- Fecha de registro: 2026-10-14.
- Fuente: informe técnico, secciones 6 a 8, 24, 28 y TKD-017.

## Contexto

El rol define capacidades funcionales y el grado define acceso curricular. Un alumno no debe desbloquear contenido avanzado mediante una declaración propia.

## Decisión

- Mantener `ROLE_GUEST`, `ROLE_STUDENT`, `ROLE_ADMIN` y `ROLE_DEVELOPER` separados del grado.
- Todo alumno nuevo comienza con `ROLE_STUDENT`, `verified_gup = 10` y `verification_status = UNVERIFIED`, con acceso a 10º Gup.
- Declarar otro grado genera una solicitud `PENDING` para el administrador funcional, el Busabonim. Solo su aprobación cambia el grado verificado mediante este flujo; un rechazo no lo eleva.
- No permitir autoaprobación ni dos solicitudes pendientes simultáneas por alumno. Registrar historial de cambios de grado y auditoría de las acciones administrativas.
- Aplicar acceso acumulativo en backend: para Gups numéricos, `contenido.gup >= alumno.verified_gup`. No extrapolar esta comparación a Dan.
- El rol técnico de ZVK Tech no implica acceso innecesario a datos personales.

## Consecuencias y pendientes

Angular no es la barrera de seguridad. Cambiar un grado declarado no cambia la autorización efectiva.

La sección 8 define estados de solicitud (`PENDING`, `APPROVED`, `REJECTED`, `CANCELLED`); TKD-017 contempla estados de verificación del alumno. Falta precisar su relación; no se unifican automáticamente. El informe también prevé asignación administrativa directa: sus condiciones deben confirmarse antes de implementarla, sin crear un atajo en este sprint.

Sprint 0 no implementa autenticación, permisos, solicitudes ni enums.
