# Procedencia — inicio de Sprint 1

Fuente principal: [informe_tecnico.md](../../informe_tecnico.md), secciones 11–13 y TKD-001/TKD-002.

## Inventario inicial, no contenido aprobado

[inventory.json](../sources/inventory.json) identifica cuatro copias locales mediante ID estable, referencia relativa, tamaño y SHA-256. Los IDs identifican las fuentes registradas, no las fechas ni el orden de autoridad. No renombrarlos al corregir un título. Si cambia el hash, detener la extracción y revisar qué copia o edición cambió antes de reemplazar el registro; no sobrescribir silenciosamente la identidad utilizada en citas anteriores.

Contrato inicial `format_version = 1`:

- `sources`: lista no vacía, con IDs, referencias y hashes únicos.
- `id`: identificador canónico según el informe.
- `file_reference`: ruta relativa desde la raíz, dentro de `knowledge/sources/pdfs/`, sin carpetas intermedias ni rutas absolutas.
- `size_bytes`, `sha256`: identidad de la copia observada; no demuestran origen legítimo ni veracidad.
- `title`, `organization`, `author`, `edition`, `language`, `pdf_pages`: metadatos observados; `null` significa no comprobado. No equivale a inexistente.
- `metadata_evidence`: ubicación y método de observación, o `null` si no se comprobó ningún metadato.
- `coverage`: índice orientativo de temas y rangos de páginas PDF inclusivos, numerados desde 1. No confundir con folios impresos, pasos de ejercicios o requisitos de examen. Lista vacía significa cobertura pendiente.
- `review_status = pending_human_review`: no hay aprobación humana registrada.
- `redistribution_status = unknown`: no hay autorización documental registrada; los PDFs siguen locales. Cambiar estados requiere ampliar el formato con evidencia y revisión explícitas, no cambiar una palabra para publicar.
- `notes`: limitaciones relevantes.

La inspección inicial se realizó con el lector PDF disponible en el entorno; las huellas con `Get-FileHash -Algorithm SHA256`. Las atribuciones quedan sujetas a revisión humana. No se almacenan extractos completos ni valores técnicos marciales en este inventario.

## Cobertura y pendientes

Los cuatro PDFs cuentan ya con identificación por bytes e inspección documental inicial de metadatos y cobertura general. La [ficha de la enciclopedia](source_enciclopedia_taekwondo.md) registra la consulta visual de páginas PDF 1–8 y su índice, no una lectura íntegra de sus 764 páginas. **TKD-001: inventario técnico inicial completado, pendiente de revisión humana**; los campos bibliográficos desconocidos de los otros documentos siguen en `null` y los derechos de uso concreto no están aprobados.

**TKD-002 continúa pendiente**: véase [autoridad curricular](curricular-authority.md). Esta tarea no elige automáticamente una fuente dominante.

Antes de modelar el currículo de 10º Gup:

1. Revisar el inventario inicial, completar los metadatos desconocidos cuando exista evidencia y confirmar los derechos aplicables al uso previsto.
2. Resolver con la escuela la autoridad curricular (TKD-002), sin asumir que el manual con más páginas sea más reciente o prevalezca.
3. Contrastar con la extracción real los [contratos técnicos de fuentes, citas, catálogos y currículo](../schemas/README.md) ya implementados (TKD-003/TKD-004). Los contratos no aprueban requisitos marciales.
4. Registrar cada dato extraído con ID de fuente, página PDF o sección y revisión humana antes de considerarlo canónico. Los lotes de [teoría](teoria_inicial-review.md) (tres fichas, seis citas), [vocabulario](vocabulario_inicial-review.md) (cuatro términos, ocho citas), [posiciones y simbolismo](posiciones-y-simbolismo-review.md) (cinco fichas, diez citas), [herramientas/ejercicios parciales](herramientas-y-ejercicios-review.md) (doce fichas, dieciocho citas), [preparación paralela](posicion_preparatoria_paralela-review.md) (una ficha, una cita) y [combate y patadas](combate-y-patadas-review.md) (seis fichas, ocho citas) están pendientes de revisión humana. No hay contenido aprobado ni currículo asignado.

## Hallazgos que requieren revisión humana

- Los dos manuales se titulan `MANUAL DE EXAMEN`, pero tienen 29 y 38 páginas y hashes diferentes. No deben fusionarse ni tratarse como duplicados exactos. No se infieren edición o cronología.
- La sección «El saludo» difiere entre `source_teoria_completa_web`, página PDF 7, y `source_teoria_ont`, página PDF 8. Se registra la divergencia, sin seleccionar una formulación como válida para la escuela.
- La página PDF 17 de `source_teoria_ont` contiene una nota editorial de contenido incompleto. Esa sección no debe pasar directamente a catálogo.
- El temario teórico para el examen 10º a 9º aparece en las páginas PDF 27 y 35 respectivamente. No basta para afirmar que el JSON previo `Gups/10gup.json` sea el programa oficial completo, ni para deducir requisitos técnicos ausentes.
- Las variantes de romanización observadas no autorizan renombrar IDs existentes o publicados sin revisión.
- `junbi_sogi` genérico no se equipara automáticamente a Narani Sogui. PDF 81 define la variante específica `narani_junbi_sogi`, enlazada a la preparación de los tramos de PDF 530; las convenciones geométricas y la adopción escolar siguen pendientes. Véase [revisión de preparación](posicion_preparatoria_paralela-review.md).
- La fuente de terminología enumera expresiones de Saju Jirugi y Saju Makgi, no una secuencia completa. La enciclopedia añade listas de 7/8 acciones con alcance explícito y una laguna de legibilidad; los conteos globales siguen desconocidos y no se heredan ni se reconstruyen por simetría.
- El combate pactado diverge entre copias: solo el manual ONT presenta `ibo_matsokgi` («combate a dos pasos»). No se elige una copia como autoridad ni se adopta la variante `sambo_matsogi_sin_contacto` del archivo antiguo, ausente en las fuentes. Véase [combate y patadas](combate-y-patadas-review.md).
- El «TEMARIO PARA CADA EXAMEN» de WEB 27 y ONT 35 para 10º a 9º enumera solo temas de teoría, sin requisitos técnicos de posiciones, Tuls, patadas o combate. No basta para construir un currículo de 10º Gup ni para confirmar el archivo antiguo `Gups/10gup.json` como programa oficial.

Estos hallazgos no se resuelven usando conocimiento general del modelo. Ningún JSON marcial previo fue corregido, migrado o aprobado en esta tarea.
