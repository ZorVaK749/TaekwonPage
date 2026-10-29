# Evidencia de ejercicios en la enciclopedia — 16-10-2026

Estado: **pendiente de revisión humana**. Se amplían las [fichas parciales](../catalogs/tuls/ejercicios_iniciales_parciales.json) con acciones observadas en la copia `source_enciclopedia_taekwondo`; no se declaran ejercicios completos, requisitos escolares o contenido aprobado.

## Localización comprobada

- Página **PDF 530**, folio **impreso 528**: apartados «Puño en 4 direcciones (Saju Jirugui)» y «Defensa en 4 direcciones (Saju Makgui)».
- Se observaron **siete** y **ocho** acciones numeradas, respectivamente, además de un retorno final sin número y una nota compartida sobre ejecución alterna en los dos sentidos.
- Cada lista tiene una [cita propia](ejercicios_iniciales_parciales.json) con el SHA-256 de la copia registrada. Las citas anteriores de Terminología se conservan para los nombres y la síntesis, pero no se usan como evidencia de pasos.
- Se verificó visualmente el folio 528, no se obtuvo restando 2 a todos los números PDF. Las páginas adyacentes PDF 529/531 muestran folios 527/529 y contenido distinto; no se convierten por ello en programa de la escuela.

La búsqueda inicial consultó PDF 420, 430 y 440 en ejercicios básicos; no se reutilizan esos ejercicios distintos para completar Saju. La inspección dirigida continuó en PDF 529–531. Se renderizó PDF 530 a 2400 píxeles y se consultaron recortes locales de texto, sin OCR ni sustitución de glifos. Las imágenes y recortes quedaron fuera del repositorio.

## Qué se registró

Se resumieron quince acciones numeradas en total, conservando el orden local de cada lista, el pie que se desplaza, la posición para caminar indicada y las partes legibles de las acciones. `gunnun_sogi` referencia el catálogo existente de posición para caminar; la lateralidad descrita se conserva en cada texto, sin inventar otra geometría.

Los identificadores de dirección **A/B/C/D** pertenecen al esquema de la página. No se convierten en puntos cardinales, ángulos, coordenadas absolutas o un renderer. No se copian el esquema ni las fotografías.

Cada ficha añade `sequence_scope`, que especifica que sus pasos corresponden a la lista impresa consultada, no a un ciclo global reconstruido. El contrato incorpora ese campo textual y el validador lo exige cuando existen pasos parciales. Los borradores antiguos con pasos vacíos siguen siendo válidos sin ese campo.

## Lagunas y decisiones que no se asumen

1. **Punto 3 de Saju Jirugi:** el destino del golpe aparece omitido/ilegible en la copia. Se preservan las partes legibles y se marca la laguna; no se deduce el destino por la orientación de la posición o por simetría. El **29-10-2026** se intentó recuperar la lectura renderizando recortes ampliados de la propia línea (ancho de destino hasta 4000 px, sin OCR ni sustitución de glifos): la tinta del destino está **erosionada hasta dejar blanco**, sin trazas recuperables. El resultado del intento es negativo; la laguna se mantiene documentada y el único modo de resolverla es evidencia externa (otra copia o el revisor).
2. **Preparación:** la consulta posterior de PDF 81, folio 79, define expresamente Narani Junbi Sogui con la misma denominación de preparación de pies paralelos usada en PDF 530. Se [documentó la variante específica](posicion_preparatoria_paralela-review.md) y `initial_position_id` apunta ahora a `narani_junbi_sogi` para estos tramos. No se equipara el `junbi_sogi` genérico ni se decide la variante escolar.
3. **Conteo:** 7/8 son longitudes de las listas observadas, no un total global aprobado. `movement_count` sigue en `null`; no se sustituyen ni validan los 15/16 del borrador antiguo.
4. **Retorno y alternancia:** se reconoce que la fuente los menciona, pero no se les inventan números de paso ni se genera el sentido contrario a partir de los mismos textos.
5. **Alcance curricular:** no se determina qué variante, conteo o ejecución exigirá la escuela. `sequence_complete` sigue en `false` y ambas fichas mantienen `pending_human_review`.

No se da prioridad automática a esta edición sobre los manuales ONT. El hallazgo amplía evidencia disponible; no resuelve por sí solo diferencias de programa, romanización o conteo.

## Validación y próximo trabajo

Los tests comprueban los enlaces por paso, los localizadores, la necesidad de alcance explícito y que el reporte conserve los estados incompletos. No comprueban verdad marcial ni convierten una lista parcialmente legible en una guía lista para ejecutar.

El reporte separa `documented_steps` de los totales desconocidos y de `partial_sequences`. La foundation sigue fallando en `validate:content` porque no hay currículo. Antes de cerrar TKD-012/TKD-013 faltan revisión humana del pasaje, resolución de la laguna del punto 3, confirmación escolar de la variante inicial enlazada y del alcance completo exigido. La publicación requiere además revisar derechos; este trabajo no autoriza redistribuir el libro o sus imágenes.
