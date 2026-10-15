# Posiciones y simbolismo inicial — revisión pendiente

Bloque de trabajo de Sprint 1: [tres posiciones](../catalogs/posiciones/posiciones_iniciales.json) y [dos fichas de simbolismo](../catalogs/teoria/teoria_simbolismo_inicial.json), con [seis citas de posiciones](posiciones_iniciales.json) y [cuatro citas de teoría](teoria_simbolismo_inicial.json). Todo conserva `pending_human_review`.

## Evidencias y normalización

Se consultaron imágenes locales mediante `Export-PdfPreview.ps1`, sin modificar los originales ni agregar imágenes al repositorio.

| Elemento | WEB, página PDF | ONT, página PDF | Alcance |
| --- | --- | --- | --- |
| `charyot_sogi` | 24 | 31 | Nombre y síntesis cualitativa; biomecánica desconocida en el contrato actual |
| `gunnun_sogi` | 24 | 32 | Descripción y reparto equitativo normalizado a 50/50 |
| `niunja_sogi` | 24 | 32 | Descripción; reparto 30/70 obtenido solo de ONT 32 |
| `significado_dobok_blanco` | 6 | 7 | Síntesis del simbolismo, sin transcribir el párrafo completo |
| `significado_cinturon_blanco` | 15 | 20 | Síntesis del significado del blanco, no tabla completa de colores |

La página WEB 25 se consultó para comprobar si continuaba el pasaje de Niunja: comienza con otra posición y no confirma su reparto de peso. No se utiliza como cita. La extracción no rellena el contenido ausente.

Los números 50/50 son una normalización aritmética de «equitativamente» entre dos piernas, no una medición ni valores tomados del ejemplo ilustrativo del informe. Los 30/70 proceden de los porcentajes visibles en ONT 32; el final de la línea está tapado parcialmente por el gráfico. Las citas especifican qué información respalda cada copia. No se presume corroboración doble de cada campo.

Los campos `front_foot` y `rear_foot` quedan `null`: un ángulo entre pies o una indicación «hacia dentro/fuera» no fija por sí sola la referencia de rotación de un renderer. Tampoco se convierten longitudes en anchos de hombros a coordenadas absolutas. Se omiten dimensiones y valores angulares del catálogo mientras falten convenciones verificadas. La ficha de atención no infiere porcentajes ni dos rotaciones de 22,5° a partir de un ángulo conjunto.

Se mantienen los IDs existentes de posiciones y se conservan grafías observadas en los nombres. El vocabulario `dobok`/`ti` y el simbolismo se mantienen en entradas distintas porque representan conceptos diferentes; no se crean definiciones dentro de un currículo.

## Pendientes detectados, sin solución automática

- **Junbi:** los vocabularios presentan Jumbi Sogi como posición inicial con variantes, mientras la postura de pies paralelos se denomina Narani Sogui en estas páginas. No se migra la geometría del borrador `junbi_sogi` ni se lo declara sinónimo de Narani. Hace falta confirmar qué variante se documentará y consultar la fuente correspondiente.
- **Medidas y orientaciones:** confirmar puntos anatómicos de referencia, unidades relativas y sistema angular antes de ampliar el contrato. No completar desde memoria del modelo.
- **Revisión humana:** cotejar las cinco fichas y los campos normalizados con las citas. No hay aprobación escolar ni validación biomecánica oficial registrada.
- **Currículo y derechos:** confirmar programa vigente y uso autorizado antes de publicar o asignar grados. No se crea un currículo de la escuela a partir de estos borradores.

Los archivos previos en `Posiciones/`, `Teoria/` y `Gups/` se conservan intactos. No se implementan Tuls, secuencias, backend, frontend ni persistencia en este bloque.
