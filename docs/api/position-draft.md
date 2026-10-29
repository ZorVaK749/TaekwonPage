# Posiciones con procedencia — contrato interno de trabajo

El servicio `PositionService.findById` devuelve un DTO de posición con una lista `citations`. **No es una respuesta educativa publicada:** `GET /api/v1/positions/{id}` sigue devolviendo `403` por la política global, incluso con roles autenticados. OpenAPI y la autorización funcional quedan pendientes.

Los campos anteriores de posición se conservan: ID, nombre, descripción, estado de revisión, porcentajes y rotaciones (`BigDecimal`, `null` cuando se desconocen). Se añade:

| Campo de cada cita | Significado |
| --- | --- |
| `id` | ID canónico de la cita |
| `sourceId`, `sourceSha256` | Identidad exacta de la copia registrada; no se fusionan copias por tener el mismo título |
| `sourceTitle`, `sourceOrganization`, `sourceAuthor`, `sourceEdition`, `sourceLanguage` | Metadatos observados; pueden ser `null`, no se deducen del archivo |
| `pdfPage` | Número de página PDF desde 1; puede ser `null` en una cita localizada por sección |
| `printedPage` | Folio observado como texto, independiente de la página PDF; puede ser `null` |
| `section` | Localizador de sección, o `null` si solo se registró página |
| `reviewStatus`, `sourceReviewStatus` | Estados de cita y fuente; actualmente `pending_human_review` |
| `redistributionStatus` | Estado de derechos registrado para la copia; actualmente `unknown`, nunca permiso implícito |

La consulta enlaza `content_source` con `source_document` por **ID y hash**, filtra por la ficha solicitada y ordena por ID de cita. No carga relaciones JPA en el JSON ni incluye rutas locales, PDFs, `file_reference` o notas internas. Usa los índices existentes, sin nueva migración o dependencia. El patrón se replicó a teoría, vocabulario, herramientas corporales y tuls/ejercicios; el contrato OpenAPI de todas las rutas de lectura vive en [docs/openapi/taekwonpage-v1.json](../openapi/taekwonpage-v1.json).

La lista es una copia inmutable. Una ficha sin citas devuelve `[]`: muestra la carencia, no inventa evidencia ni habilita su publicación. Si la ficha no existe, el servicio devuelve ausencia sin consultar citas; no toma datos de otra ficha como respaldo.

## Pruebas

`mvn.cmd -f backend/taekwonpage-api/pom.xml verify` incluye PostgreSQL real aislado con fixtures sintéticos: dos fuentes con igual título y hashes distintos, cita solo por sección, folio independiente, metadatos desconocidos, aislamiento entre fichas, orden estable, serialización sin información local y bloqueo HTTP de un borrador que sí existe y tiene citas.

No se importan ni aprueban datos reales en la BD de desarrollo. Antes de abrir la ruta: decidir identidad, autorización por grado y revisión/publicación; el contrato OpenAPI de lectura ya está especificado y verificado contra los controladores.
