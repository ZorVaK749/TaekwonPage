# Términos generales y acciones de las tablas de vocabulario — matriz para revisión

**Estado: pendiente de revisión humana y confirmación escolar.** Es una matriz de evidencia documental, **no un currículo** ni un catálogo aprobado. Fases 0 y 1 siguen abiertas.

Se extrajeron de las tablas «VOCABULARIO» observadas en **WEB PDF 11** y **ONT PDF 13–14** ([matriz general](vocabulario-tabla-completa-review.md)) los **12 términos generales y de acción** en [vocabulario_terminos_generales.json](../catalogs/vocabulario/vocabulario_terminos_generales.json), con [24 citas](vocabulario_terminos_generales.json), una por copia y fila. Todos conservan `pending_human_review`. Con esto la matriz general queda cerrada salvo los nombres de técnica.

## Filas extraídas

| ID | Nombre | Traducción observada |
| --- | --- | --- |
| `jumbi_sogi` | Jumbi Sogi | Posición inicial (A-B-C-D-etc) |
| `chagi` | Chagi | Patada |
| `twigi` | Twigi | Salto en ejercicio fundamental |
| `twimyo` | Twimyo | Salto con patada |
| `bande` | Bande | Giro |
| `sogi` | Sogi | Posición de piernas |
| `so` | So | Abreviatura de sogi |
| `makgi` | Makgi | Defensa |
| `opun` | Opun | Palma hacia abajo |
| `dwijibun` | Dwijibun | Palma hacai arriba (grafía observada) |
| `kyocha` | Kyocha | En cruz (Ej: Sogi-Makgi) |
| `jeja` | Jeja | Alumno |

Ninguno de estos IDs existía previamente (los IDs son globales). Las traducciones se transcriben literalmente; los ejemplos entre paréntesis de las propias filas (`A-B-C-D-etc`, `Sogi-Makgi`) no se expanden.

## Límites aplicados en este bloque

| Asunto | Qué se observó | Límite |
| --- | --- | --- |
| `Jumbi Sogi` vs Junbi existente | «Posición inicial (A-B-C-D-etc)»; el catálogo de posiciones ya tiene `narani_junbi_sogi` como variante documentada. | No se equiparan; la adopción del Junbi genérico sigue pendiente ([revisión de preparación](posicion_preparatoria_paralela-review.md)) |
| `Sogi`, `Makgi`, `Chagi` genéricos | Tres términos sueltos («Posición de piernas», «Defensa», «Patada»); la misma tabla lista compuestos y la enciclopedia ya tiene patadas concretas. | No se derivan posiciones, bloqueos ni patadas concretas de estas filas; `saju_makgi` existente no se fusiona con `makgi` |
| `Dwijibun` = «Palma hacai arriba» | Errata «hacai» igual en ambas copias; la compuesta `Dwijibun Sonkut` sí se extrajo en el [bloque de cuerpo](vocabulario-cuerpo-review.md). | Se transcribe sin corregir; no se fusiona con la compuesta; TKD-003 |
| `So` = «Abreviatura de sogi» | Glosa lingüística de la propia tabla. | No se aplica como alias a las posiciones existentes |
| `Jeja` = «Alumno» | Vocabulario del manual. | No se deriva ningún rol de aplicación; los roles funcionales se definen en el informe, no desde esta fila |
| `Twigi` vs `Twimyo` | «Salto en ejercicio fundamental» y «Salto con patada», filas contiguas. | Se conservan distintas |
| `Kyocha` con ejemplo | «En cruz (Ej: Sogi-Makgi)». | El ejemplo no se expande ni se modela como técnica |

## Checklist para el revisor / responsable de la escuela

- [ ] Confirmar si estos términos genéricos se exigen en el examen de 10º Gup de Nahuel Aukan y con qué profundidad.
- [ ] Decidir la relación entre `Jumbi Sogi` de la tabla y el Junbi que usa la escuela (pendiente desde la [adopción del Junbi](posicion_preparatoria_paralela-review.md)).
- [ ] Aprobar o corregir la errata «hacai» de `Dwijibun` conforme a TKD-003.
- [ ] Decidir el modelado de los nombres de técnica de la tabla (último grupo pendiente de la matriz general).
- [ ] Registrar quién revisa, con identidad y alcance reales.

**No hay persona, fecha de aprobación o programa escolar confirmados en este documento.** La matriz no autoriza a sembrar datos como aprobados, a abrir endpoints educativos ni a avanzar de fase. `validate:content` debe seguir rechazando la ausencia de currículo.
