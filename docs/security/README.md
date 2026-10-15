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

Desde ahora: no versionar secretos ni PDFs sin autorización. No se añadieron proveedores de identidad, dependencias o mecanismos de autenticación en este bloque.
