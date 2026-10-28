# Partes del cuerpo de las tablas de vocabulario — matriz para revisión

**Estado: pendiente de revisión humana y confirmación escolar.** Es una matriz de evidencia documental, **no un currículo** ni un catálogo aprobado. Fases 0 y 1 siguen abiertas.

Se extrajeron de las tablas «VOCABULARIO» observadas en **WEB PDF 11–12** y **ONT PDF 13–16** ([matriz general](vocabulario-tabla-completa-review.md)) las **14 filas de partes del cuerpo** sin conflicto abierto de grafía, en [herramientas_cuerpo.json](../catalogs/herramientas/herramientas_cuerpo.json) (catálogo `body_tool`) con [23 citas](herramientas_cuerpo.json). Todas conservan `pending_human_review`.

## Hallazgo de este bloque: las dos tablas no son idénticas

Al observar las páginas completas se comprobó que **la tabla ONT tiene 71 filas y la WEB 65**. Faltan en WEB seis filas de mano, entre «Ap Joomuk» (WEB 11) y «Sun Sonkut» (WEB 12): `Dung Joomuk`, `Sonbadak`, `Sonkal`, `Sonkal Dung`, `Sonkut` y `Opun Sonkut`. Esto explica que la ficha `sonkal` existente solo tuviera cita ONT. No se infiere causa (errata de escaneo, edición distinta u omisión deliberada); queda registrado para el revisor y corrige la afirmación previa de «71 filas idénticas» de la matriz general.

## Filas extraídas

| ID | Nombre | Traducción observada | Copias |
| --- | --- | --- | --- |
| `dung_joomuk` | Dung Joomuk | Revés de puño | solo ONT 14 |
| `sonbadak` | Sonbadak | Palma de mano | solo ONT 14 |
| `sonkal_dung` | Sonkal Dung | Revés del canto de la mano | solo ONT 14 |
| `sonkut` | Sonkut | Punta de dedos de la mano | solo ONT 14 |
| `opun_sonkut` | Opun Sonkut | Punta de dedos de la mano (palma hacia abajo) | solo ONT 14 |
| `sun_sonkut` | Sun Sonkut | Punta de dedos de la mano (con la palma hacia adentro) | WEB 12 / ONT 14 |
| `dwijibun_sonkut` | Dwijibun Sonkut | Punta de los dedos de la mano (con la palma hacia arriba) | WEB 12 / ONT 15 |
| `bandal_son` | Bandal Son | Arca de la mano (grafía observada) | WEB 12 / ONT 15 |
| `palkup` | Palkup | Codo | WEB 12 / ONT 15 |
| `baldung` | Baldung | Empeine | WEB 12 / ONT 15 |
| `balkaldung` | Balkaldung | Parte interna del pie | WEB 12 / ONT 15 |
| `balkut` | Balkut | Punta de los dedos del pie | WEB 12 / ONT 15 |
| `mori` | Mori | Cabeza | WEB 12 / ONT 15 |
| `kyong_gol` | Kyong Gol | Tibia | WEB 12 / ONT 15 |

Ninguno de estos IDs existía previamente (los IDs son globales); las traducciones se transcriben literalmente de las filas.

## Fila excluida del alcance

- **`Dwichook` — «Parte posterior del talón»**: excluida. La tabla la grafía `Dwichook`; las fichas existentes de la enciclopedia usan `dwihook` («parte de atrás del talón») y `dwitkumchi` («parte inferior del talón»). Sin resolver la equivalencia (TKD-003), una tercera ficha consolidaría tres grafías para zonas solapadas sin decisión humana.

## Filas que ya existen en otros catálogos (no duplicadas)

| Fila de la tabla | Ya existe como | Origen |
| --- | --- | --- |
| `Ap Joomuk` | `ap_joomuk` | vocabularios WEB/ONT |
| `Sonkal` («Canto de mano», solo ONT) | `sonkal` | vocabulario ONT |
| `Palmok`, `Bakat palmok`, `An palmok` | `palmok`, `bakat_palmok`, `an_palmok` | vocabularios WEB/ONT |
| `Apkumchi`, `Balkal`, `Moorup` | `apkumchi`, `balkal`, `moorup` | enciclopedia |

## Discrepancias y observaciones para el revisor

| Asunto | Qué se observó | Límite |
| --- | --- | --- |
| Tablas no idénticas | ONT incluye seis filas de mano ausentes en WEB. | Se extraen con fuente ONT; no se infiere cuál copia es correcta ni se rellena WEB desde ONT |
| `Bandal Son` = «Arca de la mano» | Grafía igual en ambas copias (posible errata por «arco»). | Transcrita sin corregir; TKD-003 |
| `Sonkal` vs `Sonkal Dung` | «Canto de mano» y «Revés del canto de la mano»; la segunda solo en ONT. | No se fusionan ni se crean aliases |
| `Sonkut` vs compuestas | `Sonkut` genérico solo en ONT; `Opun`/`Sun`/`Dwijibun Sonkut` añaden orientación de palma. | Cada fila se transcribe por separado |
| `Baldung` («Empeine») vs `balkal` existente | La ficha enciclopédica de `balkal` menciona el empeine como zona asociada. | No se declara equivalencia entre términos |
| `Balkut` («Punta de los dedos del pie») vs `apkumchi` («Metatarso») | Filas distintas de la misma tabla. | No se equiparan |
| `Kyong Gol` = «Tibia» | Traducción observada; no designa explícitamente una zona objetivo. | No se deriven zonas de ataque |

## Checklist para el revisor / responsable de la escuela

- [ ] Confirmar si el vocabulario de partes del cuerpo se exige en el examen de 10º Gup de Nahuel Aukan y con qué profundidad.
- [ ] Decidir qué significa que la tabla WEB omita seis filas de mano presentes en ONT (errata, edición u omisión) y si la escuela usa una de las dos copias.
- [ ] Resolver `Dwichook` (TKD-003): ¿`dwihook`, `dwitkumchi`, ambas o ninguna cubren «parte posterior del talón»?
- [ ] Decidir si `sonkal_dung` convive con `sonkal` o se presenta de otra forma al alumno.
- [ ] Aprobar o corregir la grafía `Bandal Son`.
- [ ] Registrar quién revisa, con identidad y alcance reales.

**No hay persona, fecha de aprobación o programa escolar confirmados en este documento.** La matriz no autoriza a sembrar datos como aprobados, a abrir endpoints educativos ni a avanzar de fase. `validate:content` debe seguir rechazando la ausencia de currículo.
