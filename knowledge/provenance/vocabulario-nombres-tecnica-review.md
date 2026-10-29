# Nombres de técnica de la tabla de vocabulario — matriz para revisión

**Estado: pendiente de revisión humana y confirmación escolar.** Es una matriz de evidencia documental, **no un currículo** ni un catálogo aprobado. Fases 0 y 1 siguen abiertas.

Se extrajeron las **once filas de nombres de técnica** de las tablas «VOCABULARIO» (**WEB PDF 12** y **ONT PDF 15–16**) al catálogo [vocabulario_nombres_tecnica.json](../catalogs/vocabulario/vocabulario_nombres_tecnica.json) con [22 citas](vocabulario_nombres_tecnica.json), una por copia y fila. Ambas copias muestran estas filas con **traducciones idénticas**. Todas conservan `pending_human_review`.

| ID | Fila | Traducción transcrita |
| --- | --- | --- |
| `chukyo_makgi` | Chukyo Makgi | Bloqueo alto |
| `tulgi` | Tulgi | Golpe que termina en punta (Ej: sun Sonkut Tulgi, Yop Palkup Tulgi) |
| `yop_makgi` | Yop Makgi | Bloqueo lateral |
| `ap_makgi` | Ap Makgi | Bloqueo frontal |
| `yobap_makgi` | Yobap Makgi | Bloqueo frontal lateral |
| `boosigi` | Boosigi | Patear recogiendo (Apcha Boosigi) |
| `golcho` | Golcho | Bloqueo preparado para el agarre |
| `miro` | Miro | Empujando |
| `noollo` | Noollo | Descendente para bloqueos |
| `taerigi` | Taerigi | Todos los golpes con canto de mano |
| `momchau` | Momchau | Al bloquear con ambos brazos |

## Fila excluida: `Jirugi`

La tabla contiene **dos filas `Jirugi`** con alcances distintos: una se traduce «Patear reteniendo (Yopcha jirugi)» y la otra «Todos los golpes con puño». Misma grafía, dos significados. **No se crea una ficha `jirugi`** hasta que el revisor resuelva el doble uso (pendiente abierto de la [matriz general](vocabulario-tabla-completa-review.md)). Ambas filas quedan registradas aquí y en las citas de la tabla original.

## Límites aplicados

- Son **filas de vocabulario**, no fichas de técnica: no se derivan biomecánica, zona objetivo, trayectoria, requisitos de examen ni secuencias.
- Los nombres compuestos (`Yop Makgi`, `Ap Makgi`, `Yobap Makgi`) **no absorben** al término genérico `makgi` ni se equiparan al ejercicio `saju_makgi`; los componentes (`Yop`, `Ap`, `Yobap`, `Makgi`) siguen existiendo por separado.
- Los ejémplos entre paréntesis de `Tulgi` y `Boosigi` se transcriben como parte de la fila; **no se expanden** en fichas ni se enlazan tipados a `sun_sonkut`, `palkup` u otros IDs.
- `Taerigi` («Todos los golpes con canto de mano») documenta el paralelo con la segunda fila de `Jirugi` sin fusionarlo con `sonkal` ni con las herramientas de la enciclopedia.
- `Noollo` se conserva distinto de `Naeryo`; `Momchau` no se equipara a `Sang San` («Doble»); `Boosigi` usa «Patear» como la primera fila de `Jirugi`, transcrita sin armonizar.
- Las grafías romanizadas se transcriben sin corregir; TKD-003 pendiente.

## Checklist para el revisor / responsable de la escuela

- [ ] Confirmar si estos nombres de técnica se exigen en el examen de 10º Gup de Nahuel Aukan y con qué profundidad.
- [ ] Resolver el doble uso de `Jirugi` («Patear reteniendo» vs. «Todos los golpes con puño») y si debe existir como término único.
- [ ] Decidir si los nombres compuestos de bloqueo son vocabulario de examen o solo referencial.
- [ ] Aprobar o corregir las grafías romanizadas conforme a TKD-003.
- [ ] Registrar quién revisa, con identidad y alcance reales.

**No hay persona, fecha de aprobación o programa escolar confirmados en este documento.** La matriz no autoriza a sembrar datos como aprobados, a abrir endpoints educativos ni a avanzar de fase. `validate:content` debe seguir rechazando la ausencia de currículo.
