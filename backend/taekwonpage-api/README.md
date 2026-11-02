# TaeKwonPage API — base ejecutable

Java 21, Maven 3.9+, Spring Boot **3.5.16** (versión estable 3.x verificada en Maven Central), PostgreSQL 17.7 y Flyway 11.20.0, alineado con Compose. No es una release del producto ni una API educativa publicada.

## Ejecutar localmente

Primero preparar `.env` desde `.env.example` en la raíz y levantar PostgreSQL:

```powershell
docker compose up -d --wait postgres
```

Desde **`backend/taekwonpage-api/`**:

```powershell
mvn.cmd verify
mvn.cmd spring-boot:run "-Dspring-boot.run.arguments=--spring.config.import=file:../../.env[.properties]"
```

El segundo comando lee la configuración local, no la incorpora al JAR ni a Git. La importación es explícita; para hosting usar variables del servidor (`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`), no ese archivo. Alternativamente ejecutar el JAR generado con `java -jar target/taekwonpage-api-0.1.0-SNAPSHOT.jar`, suministrando esas variables. `DB_HOST`, `DB_PORT`, `DB_NAME`, `SERVER_PORT` y `SERVER_ADDRESS` también son configurables. Por defecto escucha **solo 127.0.0.1:8080**; no abrirlo a Internet.

Flyway valida/aplica migraciones al arrancar. Hibernate usa `ddl-auto=validate`: no crea ni modifica tablas. No ejecutar Flyway Compose y la aplicación como dos procesos de migración intencionadamente paralelos. La migración V1 existente no fue modificada.

## Alcance actual

- `content`: entidad base y **ocho tipos con lectura interna**: posición, teoría, vocabulario (`translation` + `aliases`), herramienta corporal, tul/ejercicio parcial (con pasos y citas por paso), kick, tipo de combate y Gup (esquema curricular con sus siete grupos de requisitos), cada uno con repositorio de solo lectura, servicio transaccional, DTO y controlador.
- `shared/ids`: validación única de IDs canónicos (`CanonicalIds`), con la misma forma que el dominio SQL `canonical_id`, reutilizada por servicios y controladores.
- `shared/security`: JWT local HS256 y política **deny-all para contenido**; públicos solo salud y `POST /api/v1/auth/login`; `/api/v1/me` exige Bearer.
- El DTO conserva `BigDecimal`, valores desconocidos `null` y estado de revisión; no expone entidades JPA. Incluye [citas con metadatos de la copia](../../docs/api/position-draft.md), página PDF, folio y estados, sin rutas de PDFs ni notas internas. El contrato de lectura está en [docs/openapi/taekwonpage-v1.json](../../docs/openapi/taekwonpage-v1.json), verificado contra los controladores por tests Node. La lectura de combate solo expone el borrador observado: ninguna modalidad se selecciona ni aprueba. La lectura de Gup expone el esquema curricular: con `gup_10` real en la base responde 200 (grupo de teoría y citas) y 404 para gups inexistentes; ningún grupo de requisitos se rellena desde otra ficha ni desde los JSON antiguos, y el HTTP sigue bloqueado por `denyAll` hasta C2.
- `identity`/`auth`: V7 crea usuarios/roles/asignaciones; cuatro roles, cero cuentas o credenciales por defecto. Login BCrypt y `/me`; sin registro, refresh, Basic/formulario ni sesiones. CSRF deshabilitado por API Bearer stateless, no CORS permisivo. `JWT_SECRET` obligatorio ≥32 bytes aleatorios; `JWT_ISSUER` por defecto `taekwonpage-local`, `JWT_TTL_SECONDS` entero positivo, por defecto 1800.

```text
GET /actuator/health                 -> 200 {"status":"UP"} con BD saludable
POST /api/v1/auth/login              -> 200 token / 400 entrada inválida / 401 credenciales rechazadas
GET /api/v1/me                      -> 200 identidad / 401 token ausente o inválido
GET /api/v1/positions/{canonicalId}  -> 403 (bloqueado deliberadamente)
GET /api/v1/theory/{canonicalId}     -> 403 (bloqueado deliberadamente)
GET /api/v1/vocabulary/{canonicalId} -> 403 (bloqueado deliberadamente)
GET /api/v1/body-tools/{canonicalId} -> 403 (bloqueado deliberadamente)
GET /api/v1/kicks/{canonicalId}      -> 403 (bloqueado deliberadamente)
GET /api/v1/combat-types/{canonicalId} -> 403 (bloqueado deliberadamente)
GET /api/v1/tuls/{canonicalId}       -> 403 (bloqueado deliberadamente)
GET /api/v1/gups/{1..10}             -> 403 (bloqueado deliberadamente)
```

Incluso un usuario autenticado o un rol técnico no puede saltar el bloqueo actual. No quitar `denyAll()` para probar contenido: las pruebas leen desde el servicio interno. Antes de abrir endpoints hacen falta identidad, autorización por grado y revisión/publicación. El contrato OpenAPI de lectura existe como documento versionado; no se expone Swagger ni diagnósticos internos y ninguna ruta `/v3/api-docs` es accesible.

## Pruebas

`mvn.cmd verify` exige Docker activo: Testcontainers levanta una BD aislada y aplica V1–V7 con Flyway. Si Docker no está disponible, las pruebas de integración **fallan**, no se omiten. No usa la BD de desarrollo ni importa PDFs o contenido real; las filas de prueba son sintéticas y se revierten.

Las 33 pruebas originales cubren esquema/migración, JPA → DTO, IDs/rangos, ocho lecturas, citas y aislamiento, nulos y colecciones inmutables, serialización sin información local, salud y bloqueo HTTP anónimo/autenticado. Identidad añade 21 (total 54), incluido servidor HTTP real en puerto aleatorio. Docker de pruebas fija API 1.44 por compatibilidad con Engine 29.

## Dependencias

- Web: arranque HTTP y DTO REST.
- Data JPA: ORM y repositorio sobre el esquema existente.
- Security: cerrar superficie HTTP antes de implementar identidad.
- Actuator: salud mínima, sin información interna.
- Flyway Core + módulo PostgreSQL y driver JDBC: migraciones y conexión real.
- Starter Test, Security Test y Testcontainers PostgreSQL/JUnit: pruebas unitarias, negativas y contra BD real; no se añade H2 ni Lombok.

Auditoría: 54 pruebas Java (33 originales y 21 de identidad). Regresiones de BCrypt en cuentas ausentes/deshabilitadas, límites de credenciales, JWT falsificados/expirados, claims mal tipados, roles desconocidos, JSON duplicado y cabeceras no soportadas. HTTP real conserva 400 en login inválido: se permite solo el despacho interno ERROR; `/error` directo y contenido siguen en 403, incluso con token válido en contenido.

Límites: `/me` refleja el token, no consulta el estado actual de cuenta/roles; cambios posteriores no revocan tokens existentes antes de expirar. Sin limitación de intentos ni revocación inmediata; **no exponer públicamente**. Antes de abrir contenido: decisión C2, autorización por grado, revisión/publicación y endurecimiento operativo. Alta de alumnos pendiente de TKD-016/TKD-017. Contraseñas de login no vacías, máximo **72 bytes UTF-8** por BCrypt; username ASCII `[A-Za-z0-9._-]`, 3–64 caracteres.
