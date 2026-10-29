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

- `content`: entidad base y **cinco tipos con lectura interna**: posición, teoría, vocabulario (`translation` + `aliases`), herramienta corporal y tul/ejercicio parcial (con pasos y citas por paso), cada uno con repositorio de solo lectura, servicio transaccional, DTO y controlador.
- `shared/ids`: validación única de IDs canónicos (`CanonicalIds`), con la misma forma que el dominio SQL `canonical_id`, reutilizada por servicios y controladores.
- `shared/security`: política temporal **deny-all**, salvo `GET /actuator/health`.
- El DTO conserva `BigDecimal`, valores desconocidos `null` y estado de revisión; no expone entidades JPA. Incluye [citas con metadatos de la copia](../../docs/api/position-draft.md), página PDF, folio y estados, sin rutas de PDFs ni notas internas. El contrato de lectura está en [docs/openapi/taekwonpage-v1.json](../../docs/openapi/taekwonpage-v1.json), verificado contra los controladores por tests Node. Kick, combate y currículo (gups) aún no tienen DTO/API.
- No hay usuarios, credenciales por defecto, login Basic/formulario, sesiones ni elección implícita JWT/OIDC. CSRF no se deshabilita para simular una API abierta. No se habilita CORS permisivo.

```text
GET /actuator/health                 -> 200 {"status":"UP"} con BD saludable
GET /api/v1/positions/{canonicalId}  -> 403 (bloqueado deliberadamente)
GET /api/v1/theory/{canonicalId}     -> 403 (bloqueado deliberadamente)
GET /api/v1/vocabulary/{canonicalId} -> 403 (bloqueado deliberadamente)
GET /api/v1/body-tools/{canonicalId} -> 403 (bloqueado deliberadamente)
GET /api/v1/tuls/{canonicalId}       -> 403 (bloqueado deliberadamente)
GET /api/v1/gups/10                  -> 403 por política global; controlador no implementado
```

Incluso un usuario autenticado o un rol técnico no puede saltar el bloqueo actual. No quitar `denyAll()` para probar contenido: las pruebas leen desde el servicio interno. Antes de abrir endpoints hacen falta identidad, autorización por grado y revisión/publicación. El contrato OpenAPI de lectura existe como documento versionado; no se expone Swagger ni diagnósticos internos y ninguna ruta `/v3/api-docs` es accesible.

## Pruebas

`mvn.cmd verify` exige Docker activo: Testcontainers levanta una BD aislada y aplica V1 con Flyway. Si Docker no está disponible, las pruebas de integración **fallan**, no se omiten. No usa la BD de desarrollo ni importa PDFs o contenido real; las filas de prueba son sintéticas y se revierten.

Hay 30 pruebas: esquema/migración, JPA → DTO con acentos y nulos, IDs inválidos (regla única `CanonicalIds`), ausencia de resultados en los cinco tipos, citas aisladas por ficha y copia/hash, localizadores independientes, metadatos desconocidos, colecciones inmutables (incluidos pasos y citas de tul), lectura de teoría/vocabulario/herramientas/ejercicios parciales con lagunas observadas y serialización sin información local. También salud sin detalles, bloqueo anónimo/autenticado de las cinco rutas (incluido un borrador existente), escritura y preflight no autorizado. El cliente Docker de prueba fija API 1.44 por compatibilidad con Engine 29.

## Dependencias

- Web: arranque HTTP y DTO REST.
- Data JPA: ORM y repositorio sobre el esquema existente.
- Security: cerrar superficie HTTP antes de implementar identidad.
- Actuator: salud mínima, sin información interna.
- Flyway Core + módulo PostgreSQL y driver JDBC: migraciones y conexión real.
- Starter Test, Security Test y Testcontainers PostgreSQL/JUnit: pruebas unitarias, negativas y contra BD real; no se añade H2 ni Lombok.

Siguiente bloque: completar kick/combate y `GET /api/v1/gups/10`, acordar identidad y publicación antes de cualquier apertura de rutas, y ampliar el contrato OpenAPI a esos puntos. La lectura interna de los cinco tipos ya tiene procedencia; no se crea un temario ficticio para mostrar una pantalla.
