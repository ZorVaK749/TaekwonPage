# Combate y patadas iniciales — revisión pendiente

Bloque de Sprint 1 que completa los tipos de contenido que quedaban vacíos en los catálogos canónicos: [tres modalidades de combate pactado](../catalogs/combate/combate_inicial.json), [tres patadas](../catalogs/patadas/patadas_iniciales.json) y [cinco herramientas del pie](herramientas-y-ejercicios-review.md). Todo queda `pending_human_review`; no hay programa de examen ni contenido aprobado. La ubicación en un directorio de catálogo no implica aprobación ni publicación.

## Evidencia consultada

Se renderizaron y observaron localmente páginas PDF de las copias registradas, sin extraer ni publicar páginas completas o imágenes:

| Elemento | Copia / página PDF | Alcance de la evidencia |
| --- | --- | --- |
| Combate a tres pasos (`sambo_matsokgi`) | WEB 8 y ONT 10 | Modalidad, público y métodos de práctica |
| Combate a dos pasos (`ibo_matsokgi`) | ONT 10 | Modalidad y objetivo; ausente en la otra copia |
| Combate a un paso (`ilbo_matsokgi`) | WEB 9 y ONT 11 | Modalidad, público y propósito |
| `yopcha_jirugi`, `cha_jirugi` | Enciclopedia 256 (folio 254) | Nombres y síntesis del capítulo de ataque de pie |
| `i_jung_yopcha_jirugi` | Enciclopedia 257 (folio 255) | Etiqueta observada junto a una serie fotográfica |

## Distinciones registradas, no resueltas

- **Combatir «en un paso» frente a «en dos pasos».** Ambas copias describen `sambo_matsokgi` y `ilbo_matsokgi`; solo la copia ONT presenta `ibo_matsokgi` («dos pasos»). La divergencia se registra y no se elige una copia por cantidad de páginas. La variante `sambo_matsogi_sin_contacto` del archivo antiguo `Combate/Combate_pactado.json` **no** aparece en las fuentes consultadas y no se creó como ficha.
- **El capítulo de patadas es sobre todo fotográfico.** Solo se aprovechó el texto de encabezado de folio 254 y la etiqueta de folio 255. No se derivan conteos, ángulos, clasificaciones completas ni descripciones de ejecución de las imágenes, y `cha_jirugi` se marca como redacción ambigua.
- **Secciones del cuerpo y puntos vitales.** Las mismas páginas describen la división alta/media/baja (Nopunde/Kaunde/Najunde), las líneas lateral A/B/C y los puntos vitales (kupso). Se observaron como contexto, pero **no** se modelaron aquí como pasos de combate ni se convirtieron en requisitos; su tratamiento queda pendiente de una tarea propia.
- **El temario de examen no aporta requisitos técnicos.** En WEB 27 y ONT 35, el «TEMARIO PARA CADA EXAMEN» para 10º a 9º enumera únicamente temas de **TEORÍA** (significado de Taekwon-Do, fundador, cinco principios, significado del Dobok y del cinturón blanco, clasificación de instructores). No lista posiciones, Tuls, patadas, combate ni vocabulario exigidos. Por eso **no** se construyó un currículo de 10º Gup a partir de las fuentes: faltarían sus requisitos técnicos.

## Revisión necesaria

1. Confirmar con la escuela la validez y la variante de cada modalidad de combate, en especial «un paso» frente a «dos pasos».
2. Cotejar los nombres y glosas de las patadas y herramientas del pie; resolver la ambigüedad de `cha_jirugi`.
3. Decidir con la escuela cómo se tratan las secciones del cuerpo y los puntos vitales.
4. Obtener un programa técnico de 10º Gup confirmado por la escuela antes de crear cualquier currículo; el temario observado solo cubre teoría.
5. Registrar revisión humana y derechos aplicables antes de publicar.

La falta de currículo sigue siendo un fallo esperado de `validate:content`. No se modifica ningún JSON antiguo de la raíz y no se inicia otro sprint con este bloque.
