# Tabla de vocabulario de los manuales — matriz de cobertura para revisión

**Estado: pendiente de revisión humana y confirmación escolar.** Es una matriz de evidencia documental, **no un currículo** ni un catálogo aprobado. Fases 0 y 1 siguen abiertas.

Se observaron localmente las tablas «VOCABULARIO» completas de **WEB PDF 11–12** y **ONT PDF 13–16** (`source_teoria_completa_web` y `source_teoria_ont`, con sus SHA-256 en [inventory.json](../sources/inventory.json)). Ambas tablas terminan en «Momchau» antes de la sección «TEORÍA DEL PODER». Contienen **71 filas** con la misma lista de términos; no se presume que sean documentos independientes ni versiones ordenadas.

## Qué se extrajo en este bloque

**17 términos de niveles y direcciones** en [vocabulario_niveles_direcciones.json](../catalogs/vocabulario/vocabulario_niveles_direcciones.json), con [34 citas](vocabulario_niveles_direcciones.json), una por copia y fila: `nopunde`, `kaunde`, `najunde`, `ap`, `dollyo`, `yop`, `naeryo`, `ollyo`, `bakuro`, `anuro`, `sang_san`, `wi`, `dwi`, `yop_dwi`, `yobap`, `baro` y `bandae`. Todos conservan `pending_human_review`. Las traducciones se transcriben tal como aparenen; no se derivan zonas objetivo, trayectorias ni prefijos gramaticales.

## Filas que ya existen en otros catálogos

Los IDs canónicos son globales, por lo que estas filas **no se duplican**; su aparición en la tabla se registra aquí:

| Fila de la tabla | Ya existe como | Origen de la ficha existente |
| --- | --- | --- |
| `Dobok`, `Ti`, `Dojang` | `dobok`, `ti`, `dojang` | [vocabulario inicial](vocabulario_inicial-review.md); ONT escribe «Do jang» con espacio |
| `Charyot Sogi` | `charyot_sogi` | [posiciones](posiciones-y-simbolismo-review.md) |
| `Ap Joomuk`, `Palmok`, `Bakat palmok`, `An palmok`, `Sonkal` | `ap_joomuk`, `palmok`, `bakat_palmok`, `an_palmok`, `sonkal` | [herramientas](herramientas-y-ejercicios-review.md) |
| `Apkumchi`, `Balkal`, `Moorup` | `apkumchi`, `balkal`, `moorup` | fichas basadas en la enciclopedia, no en estas tablas |

## Filas no extraídas, pendientes de decisión

- **Términos generales/acciones:** `Jumbi Sogi`, `Chagi`, `Twigi`, `Twimyo`, `Bande`, `Sogi`, `So`, `Makgi`, `Opun`, `Dwijibun`, `Kyocha`, `Jeja`. `Jumbi Sogi` («Posición inicial (A-B-C-D-etc)») se relaciona con la [adopción del Junbi](posicion_preparatoria_paralela-review.md), aún sin resolver.
- **Partes del cuerpo sin ficha:** `Dung Joomuk`, `Sonbadak`, `Sonkal Dung`, `Sonkut`, `Opun Sonkut`, `Sun Sonkut`, `Dwijibun Sonkut`, `Bandal Son`, `Palkup`, `Dwichook`, `Baldung`, `Balkaldung`, `Balkut`, `Mori`, `Kyong Gol`. Pertenecen al catálogo de herramientas del cuerpo; extracción pendiente y sujeta a resolver las grafías de la sección siguiente.
- **Nombres de técnica/bloqueo:** `Chukyo Makgi`, `Tulgi`, `Yop Makgi`, `Ap Makgi`, `Yobap Makgi`, `Jirugi` (dos filas), `Boosigi`, `Golcho`, `Miro`, `Noollo`, `Taerigi`, `Momchau`. No se convierten en fichas de catálogo desde una fila de vocabulario; su modelado depende de la revisión de técnicas y del currículo.

## Discrepancies y observaciones para el revisor

| Asunto | Qué se observó | Límite |
| --- | --- | --- |
| `Baro`/`Bandae` según posición | Cuatro filas: en Gunnun Sogi, Baro = «con el mismo pie» y Bandae = «con el pie invertido»; en Niunja Sogi (posición en «L») el par **invierte** el significado. Aparece igual en ambas copias. | Registrado en las fichas `baro` y `bandae` con ambas glosas; no se elige una convención ni se declara cuál aplica en la escuela |
| `Jirugi` duplicado | Una fila lo traduce «Patear reteniendo (Yopcha jirugi)» y otra «Todos los golpes con puño». Misma grafía, dos alcances. | No se fusionan ni se crea una ficha `jirugi` hasta resolver el doble uso |
| `Dwichook` vs `dwihook`/`dwitkumchi` | La tabla dice «Dwichook — Parte posterior del talón»; la enciclopedia usa `dwihook` («parte de atrás del talón») y `dwitkumchi` («parte inferior del talón»). Variantes de romanización con solape semántico. | No se igualan grafías ni se crean aliases; TKD-003 pendiente |
| Errata «hacai» | La fila `Dwijibun` muestra «Palma hacai arriba» en ambas copias. | Se transcribe sin corregir; probable errata tipográfica a confirmar |
| `Bandal Son` = «Arca de la mano» | Grafía observada en ambas copias. | No se corrige a «arco» ni otra forma desde conocimiento general |
| `Naeryo` vs `Noollo` | «Descendente» y «Descendente para bloqueos». | Se conservan distintas |
| ONT PDF 13 previo a la tabla | Contenido sobre división lateral del cuerpo (líneas del plexo solar, pecho y hombro) con figura. | Fuera del alcance de vocabulario; no extraído en este bloque |

## Checklist para el revisor / responsable de la escuela

- [ ] Confirmar si estas tablas de vocabulario corresponden al programa vigente de Nahuel Aukan y a qué profundidad se exigen.
- [ ] Decidir si `baro`/`bandae` conservan la distinción dependiente de la posición o se presentan de otra forma al alumno.
- [ ] Resolver el doble significado de `Jirugi` y si debe existir como término único.
- [ ] Aprobar o corregir las grafías romanizadas (`Dwichook`, `Bandal Son`, «hacai») conforme a TKD-003.
- [ ] Decidir la extracción de las partes del cuerpo restantes y de los nombres de técnica, sin duplicar IDs existentes.
- [ ] Registrar quién revisa, con identidad y alcance reales.

**No hay persona, fecha de aprobación o programa escolar confirmados en este documento.** La matriz no autoriza a sembrar datos como aprobados, a abrir endpoints educativos ni a avanzar de fase. `validate:content` debe seguir rechazando la ausencia de currículo.
