# Primer lote de vocabulario — revisión pendiente

Estado: **pending_human_review**. [Catálogo de trabajo](../catalogs/vocabulario/vocabulario_inicial.json) con cuatro términos y [ocho citas](vocabulario_inicial.json); no hay aprobación, publicación ni asignación curricular.

## Evidencia consultada

Consulta visual local mediante `Export-PdfPreview.ps1`, contrastando ambas copias del inventario:

| Contenido | TEORIA COMPLETA WEB, página PDF | Teoria ONT, página PDF |
| --- | --- | --- |
| `dobok`, `ti`, `dojang` | 11, filas de vocabulario | 13, filas de vocabulario |
| `boo_sabum_nim` | 6, clasificación de instructores | 7, clasificación de instructores |

No se copian tablas completas ni imágenes al repositorio. Los folios impresos quedan `null`; no se deducen equivalencias con la numeración PDF. Los hashes fijan las copias observadas, sin demostrar autenticidad, derechos de publicación o independencia entre manuales.

## Normalización y límites

- Se mantiene el ID `boo_sabum_nim` del borrador y del informe. Su glosa recoge la clasificación observada, incluidos los grados enumerados; no se usa el título para conceder roles o acceso.
- `Boo Sabum Nim` y `Busabonim`, así como `Dojang` y `Do jang`, son grafías observadas y quedan representadas sin elegir una autoridad de romanización. No se incorpora `boosabumnim`, alias del JSON previo sin evidencia en las páginas de este lote.
- Solo se normaliza ortografía española en las glosas breves, como la tilde de «práctica». No se agregan pronunciaciones, hangul, etimologías o equivalencias desde conocimiento general.
- `charyot` y `kyong_ye` del borrador no se migran automáticamente. Las páginas consultadas contienen términos y contextos de posiciones/saludo, pero este lote no establece por inferencia la traducción aislada de aquellas voces de mando.
- `Vocabulario/Vocabulario_basico.json` permanece intacto. No se declara migrado ni aprobado.

La equivalencia documental entre grafías queda sujeta a revisión humana. No se resuelven con este lote las divergencias del saludo registradas en [autoridad curricular](curricular-authority.md), ni se determina el programa vigente de la escuela.

## Próxima revisión

Cotejar las cuatro glosas y los alias con sus citas; confirmar su presentación con la escuela y los derechos del uso previsto antes de publicar. El título marcial, los grados y `ROLE_ADMIN`/`ROLE_DEVELOPER` siguen siendo conceptos separados. La asignación administrativa funcional depende de las reglas del sistema, no de esta ficha de vocabulario.

El conjunto de teoría y vocabulario se valida técnicamente de forma enlazada. Sigue faltando un currículo revisado de 10º Gup: `validate:content` debe rechazar su ausencia. No se avanza a 9º Gup ni a otro milestone.
