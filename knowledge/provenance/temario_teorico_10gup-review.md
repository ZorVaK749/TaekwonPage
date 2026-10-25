# Cobertura teórica documental 10º a 9º Gup — para revisión

**Estado: pendiente de revisión humana y confirmación escolar.** Esto es una matriz de evidencia, **no un currículo** ni un programa aprobado. Fases 0 y 1 siguen abiertas.

Se observaron localmente los apartados de examen en **WEB PDF 27** y **ONT PDF 35**: ambos enumeran seis temas bajo «TEORÍA» para 10º a 9º Gup. Sus identidades exactas están en [inventory.json](../sources/inventory.json): `source_teoria_completa_web` y `source_teoria_ont`, con sus respectivos SHA-256. No se presume que sean documentos independientes o versiones cronológicamente ordenadas.

## Matriz de fichas de trabajo

Todas conservan `pending_human_review`. «Presente» significa que hay una síntesis con citas, **no dominio marcial completo, examen validado o autorización de publicación**.

| Tema observado en ambos apartados | IDs y archivo de catálogo | Evidencia del contenido (página PDF) | Cobertura / límite |
| --- | --- | --- | --- |
| Significado de Taekwon-Do | `def_taekwondo` en [teoría inicial](../catalogs/teoria/teoria_inicial.json); `etimologia_taekwondo` en [ampliación](../catalogs/teoria/teoria_temario_inicial.json) | WEB 2 / ONT 2 | Introducción previa y nuevo desglose de las glosas Tae/Kwon/Do; no traducción lingüística universal |
| Nombre del fundador | `fundador_taekwondo` en [teoría inicial](../catalogs/teoria/teoria_inicial.json) | WEB 2 / ONT 2 | Atribución a Choi Hong Hi, sin ampliar biografía o fechas |
| Cinco principios | `principios_taekwondo` en [teoría inicial](../catalogs/teoria/teoria_inicial.json) | WEB 6 / ONT 6 | Nombres y orden; no definiciones desarrolladas o romanización |
| Significado del Dobok blanco | `significado_dobok_blanco` en [simbolismo](../catalogs/teoria/teoria_simbolismo_inicial.json) | WEB 6 / ONT 7 | Síntesis del simbolismo; no reglas completas del uniforme |
| Significado del cinturón blanco | `significado_cinturon_blanco` en [simbolismo](../catalogs/teoria/teoria_simbolismo_inicial.json) | WEB 15 / ONT 20 | Significado del blanco; no catálogo de grados/colores de la escuela |
| Clasificación de instructores | `clasificacion_instructores` en [ampliación](../catalogs/teoria/teoria_temario_inicial.json) | WEB 6 / ONT 7 | Cuatro grupos y glosas españolas; romanizaciones divergentes pendientes |

Las citas de las fichas están en [teoría inicial](teoria_inicial.json), [simbolismo](teoria_simbolismo_inicial.json) y [ampliación](teoria_temario_inicial.json). El temario de examen se localiza aquí documentalmente, sin crear citas de un `gup_10` que todavía no existe.

## Nuevos datos y discrepancias

Este bloque añade **dos fichas y cuatro citas**: etimología documental y clasificación. No cambia las cinco fichas teóricas previas ni promueve el JSON antiguo de la raíz. El término de vocabulario `boo_sabum_nim` no cubría por sí solo la clasificación completa; tampoco se duplica ahora como otro rol o grado de aplicación.

| Grupo descrito | WEB 6: grafía observada | ONT 7: grafía observada |
| --- | --- | --- |
| I, II, III Dan | Busabonim | Boo Sabum Nim |
| IV, V, VI Dan | Sabonim | Sabum Nim o Sabonim |
| VII, VIII Dan | Sajionim | Sajium Nim |
| IX Dan | Sasonim | Sason Nim |

No se elige una grafía «correcta» por conocimiento general. La ficha resume los puntos coincidentes en español; las variantes siguen como asunto de revisión y no generan IDs/aliases nuevos ni permisos. Esto **no cierra TKD-015** (grados reconocidos por la escuela).

La consulta visual dirigida incluyó WEB **2, 6, 15, 27** y ONT **2, 6, 7, 20, 35**. No es lectura íntegra de los manuales. Los folios impresos de las citas nuevas quedan `null`: no se deduce un desplazamiento ni se inventa una correspondencia. PDFs y vistas previas permanecen locales; no se redistribuyen imágenes o páginas completas.

## Checklist para el revisor / responsable de la escuela

- [ ] Designar quién revisa y registrar identidad/alcance reales, sin asignar ese papel automáticamente al desarrollador.
- [ ] Confirmar si estos dos manuales y sus seis temas corresponden al programa vigente de Nahuel Aukan.
- [ ] Cotejar las siete fichas y decidir correcciones, especialmente glosas/romanizaciones de instructores.
- [ ] Determinar la profundidad requerida: nombres solamente o explicaciones adicionales de principios, simbolismo y clasificación.
- [ ] Aportar requisitos técnicos de posiciones, ejercicios, patadas, vocabulario y combate, si son exigidos. No aparecen en estos apartados de teoría.
- [ ] Resolver las lagunas técnicas existentes (incluidos Saju y convenciones geométricas) con evidencia, no a partir de esta matriz.
- [ ] Revisar derechos para el uso previsto antes de publicar.
- [ ] Registrar decisiones verificables y después construir/validar el currículo enlazado correspondiente.

**No hay persona, fecha de aprobación o programa escolar confirmados en este documento.** La ausencia de categorías técnicas en estos apartados no significa que no se exijan en la escuela. La matriz no autoriza sembrar datos como aprobados, abrir endpoints educativos o avanzar a 9º/8º Gup. `validate:content` debe seguir rechazando la ausencia de currículo.
