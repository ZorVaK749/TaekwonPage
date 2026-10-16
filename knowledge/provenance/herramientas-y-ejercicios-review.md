# Herramientas y ejercicios iniciales — revisión pendiente

Bloque de Sprint 1, TKD-008/TKD-012/TKD-013: [cinco herramientas](../catalogs/herramientas/herramientas_iniciales.json) y [dos fichas parciales de ejercicios](../catalogs/tuls/ejercicios_iniciales_parciales.json), con [nueve citas de herramientas](herramientas_iniciales.json) y [dos citas de ejercicios](ejercicios_iniciales_parciales.json). Todo queda `pending_human_review`; no hay programa de examen ni contenido aprobado.

## Evidencia consultada

Se renderizaron y observaron localmente páginas PDF de las copias registradas, sin extraer ni publicar páginas completas o imágenes:

| Elemento | Copia / página PDF | Alcance de la evidencia |
| --- | --- | --- |
| `ap_joomuk` | WEB 11 y ONT 14 | Equivalencia de vocabulario con puño frontal |
| `palmok`, `bakat_palmok`, `an_palmok` | WEB 12 y ONT 15 | Antebrazo y sus entradas externa/interna |
| `sonkal` | ONT 14 | Equivalencia con canto de mano; una sola copia citada |
| `saju_jirugi`, `saju_makgi` | Terminología de las formas, 1 | Encabezados y expresiones técnicas asociadas, no una secuencia |

Las herramientas se registran en su catálogo conceptual, sin duplicarlas como vocabulario ni inferir superficies anatómicas, nudillos específicos, medidas, posicionamiento o mecánica de impacto. Las glosas están acotadas a las filas observadas. Una equivalencia léxica no prueba que la herramienta o el ejercicio sean requisitos de 10º Gup en la escuela.

## Distinción crítica: terminología no es secuencia

El documento de terminología se presenta como nombres y traducciones de movimientos fundamentales. Sus apartados numerados bajo cada ejercicio no establecen un recorrido completo de ejecución. Por eso se conservan:

- `movement_count: null`;
- `initial_position_id: null`;
- `sequence_complete: false`;
- `steps: []`.

No se copian los conteos 15/16, la posición inicial `junbi_sogi`, la lateralidad o los giros de los JSON antiguos. `Tuls/saju_jirugi.json` y `Tuls/saju_makgi.json` permanecen intactos, sin promoción a canónicos ni eliminación. Un campo desconocido es distinto de cero movimientos.

El contrato `tul` y la carpeta `tuls/` ya estaban previstos para Tuls **y ejercicios fundamentales**. Guardar estas fichas allí no clasifica a Saju Jirugi o Saju Makgi como Tuls oficiales. El lote no asigna una categoría marcial oficial ni interpreta que existan solo dos movimientos. La relación técnica con herramientas y posiciones se expresa aquí únicamente como síntesis documental: todavía no hay enlaces tipados por técnica/paso.

## Revisión necesaria

1. Cotejar nombres y glosas de herramientas; ampliar únicamente con evidencia documental identificada.
2. Localizar una fuente que permita verificar la secuencia completa de cada ejercicio antes de escribir pasos, conteos o posiciones iniciales.
3. Confirmar la variante de Junbi y las convenciones geométricas pendientes; no deducirlas de las posiciones citadas en expresiones técnicas.
4. Registrar revisión humana y autoridad curricular antes de asignar requisitos, publicar o producir seeds.
5. Revisar derechos para el uso previsto; no presumir permiso de redistribución por haber creado estos JSON.

La validación técnica y el reporte deben mostrar los dos ejercicios como secuencias parciales, no como TKD-012/TKD-013 terminados. La falta de currículo sigue siendo un fallo esperado de `validate:content`. No se inicia otro sprint ni el backend con este bloque.
