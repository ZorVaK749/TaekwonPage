# Esquemas y convenciones — Sprint 1

JSON Schema **2020-12**. Contratos técnicos de trabajo, no aprobación de contenido ni decisiones marciales. Base: informe técnico, secciones 9–13, TKD-003/TKD-004 y ADR-004/ADR-006.

| Archivo | Contrato |
| --- | --- |
| `common.schema.json` | IDs, texto, SHA-256 y numeración PDF reutilizables |
| `source.schema.json` | Una fuente, compatible con el inventario existente |
| `source-inventory.schema.json` | Conjunto de fuentes, `format_version: 1` |
| `content-source.schema.json` | Una cita de procedencia en revisión |
| `provenance.schema.json` | Conjunto no vacío de citas, `format_version: 1` |
| `content-entry.schema.json` | Campos comunes y referencias de cita para contenido en revisión |
| `position.schema.json` | Posiciones y observaciones biomecánicas opcionales |
| `theory.schema.json`, `vocabulary.schema.json` | Teoría y vocabulario |
| `tul.schema.json` | Tuls/ejercicios con secuencias completas o parciales explícitas |
| `body-tool.schema.json`, `kick.schema.json`, `combat.schema.json` | Herramientas, patadas y combate |
| `catalog.schema.json` | Contenedor tipado de elementos de un catálogo |
| `gup.schema.json` | Currículo por Gup que referencia IDs, sin definiciones duplicadas |

Los `$id` son URNs locales versionados, no URLs que deban consultarse en Internet. El validador carga únicamente los esquemas del repositorio. No hace descargas de referencias externas ni cambia datos para hacerlos válidos.

## Convenciones implementadas

- JSON en UTF-8, dos espacios. Propiedades de estos contratos en `snake_case`; campos desconocidos se rechazan para detectar errores de escritura.
- IDs: ASCII en minúsculas, segmentos alfanuméricos separados por un solo `_`, comenzando con letra. Sin espacios, tildes o `ñ`. No modificar IDs publicados.
- `null` significa desconocido, no cadena vacía ni cero. Los textos conocidos contienen al menos un carácter distinto de espacio.
- Tamaños en bytes; hashes SHA-256 de 64 caracteres hexadecimales en minúsculas. No son prueba de autenticidad o permiso de uso.
- Páginas PDF: enteros positivos desde 1. Rangos inclusivos. El folio impreso se conserva como texto independiente y nunca se convierte sumando un desplazamiento supuesto.
- Los arrays de fuentes y citas no establecen precedencia o autoridad curricular. Los rangos de cobertura sí deben respetar inicio ≤ fin ≤ total de páginas conocido.
- Estados de trabajo actuales: fuentes y citas `pending_human_review`; derechos de redistribución de fuentes `unknown`. No se implementa un flujo de aprobación o publicación mediante estos esquemas.
- Romanización: preservar la grafía observada al extraer. No normalizar términos, unidades marciales, medidas, secuencias o requisitos por conocimiento general. Convenciones específicas de cada catálogo siguen pendientes.

## Citas de procedencia

Cada cita requiere `id`, `content_id`, `source_id`, `source_sha256`, `pdf_page`, `printed_page`, `section`, `review_status` y `notes`.

- `source_id` debe existir en el inventario y `source_sha256` coincidir con la copia registrada.
- Debe existir al menos un localizador: `pdf_page` positivo o `section` no vacía. Un folio impreso por sí solo no sustituye ese localizador.
- Si se cita una página numérica, el total de páginas de la fuente debe ser conocido y contenerla. Una sección sin número sigue siendo un borrador que exige comprobación humana.
- `content_id` identifica el contenido al que se atribuye la evidencia; un contenido puede tener varias citas y fuentes. La validación de conjuntos enlazados ya exige su existencia en los catálogos/currículos suministrados. El modo de fuentes/citas sin contenido sigue comprobando solamente su sintaxis y las referencias documentales, y lo informa explícitamente.
- IDs de cita únicos y combinaciones contenido/fuente/página/sección sin duplicados, incluso entre varios archivos.
- No se permiten campos de texto extraído o capturas dentro de la cita; `notes` es una observación de trabajo, no un lugar para transcribir libros.

No se agregan citas ficticias a `knowledge/` para aparentar cobertura. Los fixtures sintéticos viven exclusivamente en tests. Cuando existan citas reales, guardar documentos conforme a `provenance.schema.json` en `knowledge/provenance/*.json`; el CLI los descubre automáticamente. Las pruebas no aprueban su exactitud.

## Catálogos y currículo: contratos de trabajo

Un catálogo usa `format_version: 1`, `catalog_type` y `items` no vacío. Los tipos técnicos son `position`, `theory`, `tul`, `vocabulary`, `body_tool`, `kick` y `combat`, ubicados respectivamente en `posiciones/`, `teoria/`, `tuls/`, `vocabulario/`, `herramientas/`, `patadas/` y `combate/`. Un tipo no puede guardarse en el directorio de otro. Se permite repartir un catálogo en varios archivos sin repetir IDs.

Cada elemento tiene `id`, `name`, `description`, `citation_ids` no vacío y `review_status: pending_human_review`. Los IDs de contenido son globalmente únicos; cada cita enlazada debe atribuirse al mismo contenido. Las citas sin contenido o sin enlace de vuelta se rechazan. Es trazabilidad por elemento, **no demostración automática de evidencia para cada campo**. El revisor debe comprobar cada afirmación y añadir las citas necesarias.

Los currículos usan `format_version: 1`, `id`, `gup`, `requirements`, `citation_ids` y el estado de revisión. Se conserva la convención del borrador previo `gup_10`: ID `gup_<número>` coherente con el Gup numérico 1–10. Esto no crea ni aprueba grados reconocidos por la escuela. No se admiten Dan en ese campo ni se implementa autorización mediante estos esquemas.

`requirements` contiene siete listas: `position_ids`, `theory_ids`, `tul_ids`, `vocabulary_ids`, `body_tool_ids`, `kick_ids`, `combat_ids`. Cada referencia debe existir y pertenecer al tipo correcto. Las listas individuales pueden estar vacías, pero no todo el currículo. No se ordenan automáticamente: el orden de estudio declarado se preserva, sujeto a revisión escolar. El currículo no admite textos de definiciones ni contenido embebido.

### Posiciones y Tuls

- `biomechanics` puede ser `null` si no se extrajeron datos. Cuando existe, separa `weight`, `front_foot` y `rear_foot`; cada grupo desconocido es `null`. Los porcentajes conocidos están entre 0 y 100 y suman 100 (tolerancia técnica de suma `1e-9`); las rotaciones conocidas están en grados, entre 0 inclusive y 360 exclusivo, conforme a las restricciones del informe.
- No se introducen coordenadas ni conversiones de ancho de hombros: todavía falta definir unidades, puntos de referencia y orientación. Un dato angular del PDF no se transforma automáticamente en una rotación de renderizado sin verificar esa convención.
- Los Tuls/ejercicios declaran `movement_count`, `initial_position_id`, `steps` y `sequence_complete`. El conteo y la posición inicial pueden ser `null`; una secuencia parcial debe marcarse `false`, sin completar pasos imaginados.
- `sequence_scope` es una extensión textual para declarar qué tramo/lista se documentó. Si una ficha parcial tiene pasos, el validador exige ese alcance explícito. Las fichas anteriores con pasos vacíos no necesitan inventar un alcance. Los números de paso son locales al tramo indicado; no implican un conteo global ni permiten expandir recorridos alternos automáticamente.
- Cada paso tiene `step_number`, `position_id`, `description` y citas atribuidas al mismo Tul. Las posiciones deben existir en su catálogo. Los números de paso son únicos y crecientes; cuando se conoce el total, no pueden superarlo. Una secuencia marcada completa exige posición inicial y conteo conocidos, con pasos consecutivos 1..total. La marca no es aprobación marcial.
- El vocabulario separa `translation` y `aliases` conservando la grafía observada; no se generan traducciones o alias desde conocimiento general.

Los contratos textuales de teoría, herramientas, patadas y combate son mínimos; no inventan clasificaciones o parámetros técnicos aún no extraídos. Son borradores extensibles, no un modelo marcial definitivo.

## Validación y alcance pendiente

Ejecutar los [comandos de validación y tests](../../tools/validators/README.md). JSON Schema controla formas y tipos; el código adicional comprueba duplicados, rangos entre campos y referencias de fuente. El modo local además verifica bytes y archivos PDF, sin subirlos.

TKD-003/TKD-004 disponen ya de contratos iniciales para todos los tipos listados en el informe, pero aún necesitan contrastación con la extracción real. TKD-018/TKD-019/TKD-020 tienen controles técnicos de referencias, porcentajes, ángulos y currículo probados con fixtures sintéticos; **no están validados con un currículo real de 10º Gup**. No se migran los JSON previos ni se convierten los ejemplos del informe en datos.
