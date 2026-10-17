# Inspección inicial — source_enciclopedia_taekwondo

Identidad de la copia: [inventory.json](../sources/inventory.json). Se conservan ID, ruta, tamaño y SHA-256 del registro inicial. No se sustituyó el archivo.

## Método y alcance

El lector general rechazó el PDF por exceder 20 MB. Se abrió localmente con `Windows.Data.Pdf`, que informó **764 páginas**, y se renderizaron las páginas PDF **1 a 8** para observación visual. La [herramienta de consulta](../../tools/ingestion/README.md) permite repetir la inspección sin instalar dependencias.

No se hizo OCR, lectura completa, autenticación de la copia ni validación marcial. Los datos bibliográficos se registran como aparecen en el documento, no como verificación externa de la edición.

## Evidencias bibliográficas

| Página PDF | Observación |
| --- | --- |
| 3 | Título `TAEKWON-DO`, subtítulo `El arte coreano de la defensa personal`, atribución al General Choi Hong Hi; folio impreso 1 |
| 4 | Atribución de autor, primera edición en castellano de 1996 y entidad editora International Taekwon-Do Federation; aviso de derechos reservados |
| 5 | Índice general; folio impreso 3 |

El idioma observado es español; existen inscripciones y términos en otras lenguas. El nombre de archivo «Enciclopedia» no se utiliza como sustituto del título visible.

## Cobertura orientativa

El índice de la **página PDF 5** anuncia teoría e historia, posiciones, herramientas, técnicas, ejercicios, formas, enfrentamiento, defensa personal y aspectos de rango/examen/competencia. Sirve para localizar candidatos, no para deducir el programa de Nahuel Aukan.

Puntos de entrada según **folios impresos anunciados por el índice**, todavía sin confirmar su ubicación PDF:

| Área de consulta futura | Folio impreso anunciado |
| --- | --- |
| Posiciones | 65 |
| Herramientas | 84 |
| Técnicas de pie | 251 |
| Ejercicios básicos | 414 |
| Formas | 524 |
| Sistema de enfrentamiento | 598 |
| Examen | 728 |

No sumar automáticamente 2 a esos números: los dos pares de folios observados no prueban que el desplazamiento sea constante en las 764 páginas. Cada cita futura deberá confirmar su página PDF y, cuando sea legible, registrar por separado el folio impreso. En el inventario el rango `5–5` corresponde a la evidencia del índice, no a las páginas reales de todos esos capítulos.

## Derechos y estado

Hay un aviso expreso de derechos reservados en la página PDF 4. No se dispone de un permiso de redistribución registrado: se conserva `redistribution_status = unknown` en el formato actual, sin interpretarlo como permiso ni ausencia de copyright. No se publican el PDF, capturas o transcripciones extensas. La licencia MIT del repositorio no se aplica a este material de terceros.

La inspección inicial de inventario está completada; la revisión humana, los derechos para el uso concreto y cualquier aprobación de contenido siguen pendientes. Este registro no declara a la fuente superior a los manuales ONT ni le atribuye el currículo de la escuela.

## Consulta dirigida posterior — 16-10-2026

Se consultaron adicionalmente PDF 420, 430, 440 y 529–531, sin leer íntegramente los capítulos. **PDF 530 / folio impreso 528** contiene las listas numeradas de Saju Jirugui y Saju Makgui y una nota de alternancia. Se registraron [alcance y lagunas](ejercicios-enciclopedia-review.md), con dos citas nuevas y quince acciones resumidas; las secuencias permanecen parciales.

Las correspondencias PDF/folio se observaron en las páginas concretas, no se generalizan al resto del documento. El inventario añade solo el rango de cobertura realmente utilizado como evidencia de ejercicios; el hash y el archivo original no cambian.

La consulta posterior de PDF 67–70 y 80–85 localizó la definición de **Narani Junbi Sogui en PDF 81 / folio 79**. Se usa únicamente ese pasaje para la [ficha preparatoria y el enlace contextual con PDF 530](posicion_preparatoria_paralela-review.md), sin copiar otras variantes, fotografías o medidas.
