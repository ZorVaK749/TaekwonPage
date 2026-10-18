# Seguridad — planificación pendiente

Estado: **pendiente**, según lo acordado con el responsable del proyecto. Este documento es un recordatorio, no un plan de seguridad terminado ni una declaración de protección implementada.

Se conserva la etapa de seguridad del [informe técnico](../../informe_tecnico.md), secciones 19, 33, 42 y 46. Antes de una beta expuesta con cuentas o contenido restringido será necesario revisar e implementar los controles aplicables; el orden de milestones no autoriza exponer una API sin protección.

Asuntos para esa planificación:

- Estrategia JWT local frente a OIDC, credenciales y ciclo de sesión.
- Roles separados de grados y autorización acumulativa en backend, también en accesos directos a contenido.
- Verificación administrativa, prevención de autoaprobación e historial/auditoría.
- Privacidad de alumnos y acceso técnico mínimo de ZVK Tech.
- Validación, CORS explícito, HTTPS, gestión de secretos y pruebas negativas de acceso.
- Configuración de despliegue, registros, copias de seguridad y revisión de dependencias.

Base técnica del backend: Spring Security bloquea todas las rutas salvo `GET /actuator/health`, que no muestra componentes ni detalles. Basic, formulario, logout y caché de peticiones están deshabilitados; no se crea un usuario ni contraseña por defecto. La API no habilita CORS permisivo y conserva CSRF. Esta política de arranque no implementa identidad ni autorización por grado, y no habilita una beta.

Desde ahora: no versionar secretos ni PDFs sin autorización. JWT local/OIDC y el ciclo de sesiones siguen pendientes; no confundir el bloqueo preventivo con el módulo de seguridad funcional terminado. Véase [arranque y límites del backend](../../backend/taekwonpage-api/README.md).
