# Seguridad — identidad local y límites pendientes

Estado (02-11-2026): **C1 implementada y auditada**, no seguridad completa ni autorización de beta. JWT local HS256; sin proveedor externo ni dependencia nueva. Ver [backend](../../backend/taekwonpage-api/README.md).

Se conserva la etapa de seguridad del [informe técnico](../../informe_tecnico.md), secciones 19, 33, 42 y 46. Antes de una beta expuesta con cuentas o contenido restringido será necesario revisar e implementar los controles aplicables; el orden de milestones no autoriza exponer una API sin protección.

Asuntos para esa planificación:

- C1 eligió JWT local. Faltan alta/recuperación de cuentas, limitación de intentos y política de revocación/cambio de roles.
- Roles separados de grados y autorización acumulativa en backend, también en accesos directos a contenido.
- Verificación administrativa, prevención de autoaprobación e historial/auditoría.
- Privacidad de alumnos y acceso técnico mínimo de ZVK Tech.
- Validación, CORS explícito, HTTPS, gestión de secretos y pruebas negativas de acceso.
- Configuración de despliegue, registros, copias de seguridad y revisión de dependencias.

## Implementado

- Públicos solo `GET /actuator/health` sin detalles y `POST /api/v1/auth/login`. `/api/v1/me` exige Bearer; sin token válido responde 401. Todo contenido sigue en 403, incluso con roles/token válidos (`denyAll`, C2 pendiente).
- Se permite el despacho interno `DispatcherType.ERROR` para conservar errores MVC (400/415), no una ruta pública adicional. `/error` directo sigue 403. Un smoke del JAR detectó que antes el login inválido terminaba en 403; regresión con HTTP real además de MockMvc.
- BCrypt; ante cuenta inexistente/deshabilitada también se ejecuta una verificación sobre hash ficticio. Esto reduce filtraciones por tiempo, **no garantiza tiempos iguales** de BD ni con hashes de costes distintos.
- Username ASCII permitido de 3–64 caracteres; contraseña no vacía, máximo 72 bytes UTF-8 (sin truncarla). JWT de 1800 s por defecto, secreto obligatorio ≥32 bytes generado con CSPRNG. Nunca imprimirlo ni expandir `.env` en logs.
- Parser local restringido: HS256/JWT, firma HMAC con comparación resistente a timing, issuer, tipos y coherencia temporal, roles conocidos, IDs válidos, límite 8192 caracteres; rechaza JSON duplicado/trailing, cabeceras no soportadas y `nbf` (no forma parte del perfil local).
- Sin sesiones/cookies de autenticación; CSRF **se deshabilitó en este bloque** por Bearer stateless. Basic/form/logout/caché de peticiones deshabilitados y sin CORS permisivo. Ninguna cuenta ni contraseña sembrada.

## Auditoría de la implementación anterior

Se corrigió el cortocircuito que omitía BCrypt para cuentas desconocidas/deshabilitadas, la ausencia de límites de credenciales y la validación laxa de claims JWT. Las pruebas anteriores solo comparaban respuestas, no la ejecución del hash: ahora hay regresiones unitarias específicas y negativas HTTP. Roles del principal/claims son copias inmutables. Se corrigieron documentos que aún anunciaban identidad inexistente o CSRF intacto.

La implementación JWT usa primitivas criptográficas estándar del JDK, pero su protocolo/parser es propio: **no equivale a una biblioteca JOSE auditada**. Antes de exposición pública, revisar si sustituirlo por soporte JWT mantenido de Spring y justificar la dependencia; no declarar seguridad exhaustiva por tests verdes.

Tokens son snapshots hasta expirar; deshabilitar una cuenta/cambiar roles no invalida los ya emitidos. `/me` refleja claims, no datos actuales de BD. Sin revocación inmediata, refresh ni limitación de intentos. Son bloqueos para apertura pública, no funcionalidades implementadas.

Incidente local de la sesión anterior: se mostró `.env` en salida de herramientas. El secreto JWT local fue regenerado con `RandomNumberGenerator` sin mostrarlo; la contraseña de PostgreSQL también apareció y requiere rotación coordinada con el rol existente (cambiar solo `.env` no cambia el volumen). No se versionaron esos valores. No publicar logs operativos ni PDFs; no confundir esta base con seguridad funcional terminada.
