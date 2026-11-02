# Fase 0 — decisiones pendientes consolidadas

**Propósito:** un único punto de respuesta para cerrar la base de conocimiento. La extracción documental de la Fase 0 está **agotada**: con los cuatro PDFs locales se hizo todo lo que se puede hacer sin decidir. Cada fila de abajo es una decisión que **solo la escuela o el revisor marcial pueden tomar**; hasta entonces todo sigue en `pending_human_review`, y `validate:content` pasa desde el 02-11-2026 solo porque existe un currículo teórico, sin significar aprobación.

**Uso:** entregar este documento al Busabonim/escuela y al revisor designado. Cada respuesta debe quedar registrada con **nombre real, fecha y alcance** en los archivos enlazados; una respuesta genérica de «sigan» no aprueba contenido marcial.

## A. Para la escuela (Busabonim de Nahuel Aukan)

| # | Pregunta | Qué desbloquea | Dónde registrar la respuesta |
| --- | --- | --- | --- |
| A1 | ~~¿Cuál es el **programa vigente de 10º Gup** y su examen?~~ **Resuelta 01-11-2026:** el programa vigente es el de las copias ya citadas (WEB/ONT/enciclopedia), confirmado por el representante de la escuela. | TKD-009: primer currículo real (solo con lo que las copias enuncian); cierre de la fundación de `validate:content` — **hecho 02-11-2026:** `gup_10` teórico, `pending_human_review` | [curricular-authority.md](../knowledge/provenance/curricular-authority.md) |
| A2 | ~~¿Qué **manual(es)** aplican (WEB, ONT, enciclopedia) y cómo resolver sus diferencias?~~ **Parcial 01-11-2026:** aplican las tres copias; **criterio de desempate aún sin especificar** (las divergencias siguen documentadas sin resolver). | TKD-002: autoridad curricular; prioridad entre copias divergentes | [curricular-authority.md](../knowledge/provenance/curricular-authority.md) |
| A3 | ~~¿**Quién revisa y aprueba** el contenido marcial, y cómo se registra esa aprobación?~~ **Parcial 01-11-2026:** designado el usuario (mano derecha de la escuela); **falta nombre real** y mecanismo de aprobación (el esquema aún solo admite `pending_human_review`). | Todas las fichas: pasar de `pending_human_review` a aprobadas con evidencia | [curricular-authority.md](../knowledge/provenance/curricular-authority.md) |
| A4 | ~~¿Se exige el bloque de **puntos vitales (kupso)** en 10º Gup, y con qué alcance?~~ **Resuelta 01-11-2026:** **no** forma parte de 10º Gup; fuera de alcance y sin extraer. | Cierre de la única pregunta que mantenía observado el bloque kupso | [secciones-cuerpo-review.md](../knowledge/provenance/secciones-cuerpo-review.md) |
| A5 | ~~¿Qué **variante de Junbi** usa la escuela (Narani Junbi Sogi u otra) y con qué geometría?~~ **Resuelta 01-11-2026:** la escuela adopta `narani_junbi_sogi` con la geometría de PDF 81 (la de la fuente); sin heredar nada del borrador antiguo. | TKD-005: adopción de la posición inicial de los ejercicios | [posicion_preparatoria_paralela-review.md](../knowledge/provenance/posicion_preparatoria_paralela-review.md) |
| A6 | ~~¿Cuál es el **conteo total y la ejecución alterna** de Saju Jirugi / Saju Makgi en su programa?~~ **Parcial 01-11-2026:** la escuela confirmó que lo aportará; **los números aún no se entregaron** (`movement_count` sigue `null`). | TKD-012/TKD-013: `movement_count`, `sequence_complete` | [ejercicios-enciclopedia-review.md](../knowledge/provenance/ejercicios-enciclopedia-review.md) |
| A7 | ~~¿Qué **modalidad de combate pactado** aplica (y si existe la forma «sin contacto» del archivo antiguo)?~~ **Parcial 01-11-2026:** aplica su propia modalidad de **contacto pactado**; «sin contacto» **no** se adopta; falta la descripción textual («un paso»/«dos pasos»). | Catálogo de combate; resolución de `ibo_matsokgi` vs variantes | [combate-y-patadas-review.md](../knowledge/provenance/combate-y-patadas-review.md) |

## B. Para el revisor marcial designado

| # | Pregunta | Qué desbloquea | Dónde registrar la respuesta |
| --- | --- | --- | --- |
| B1 | **Doble `Jirugi`:** «Patear reteniendo (Yopcha jirugi)» vs «Todos los golpes con puño». ¿Es un término único, dos, o una errata? | Última fila sin resolver de la matriz de vocabulario (TKD-007) | [vocabulario-nombres-tecnica-review.md](../knowledge/provenance/vocabulario-nombres-tecnica-review.md) |
| B2 | **Romanización (TKD-003):** convención para `Dwichook`/`dwihook`/`dwitkumchi`, `Bandal Son` («Arca de la mano»), errata «hacai», variantes Sajionim/Sajium Nim. ¿Convención oficial y si se crean alias? | TKD-003; `Dwichook` (parte del cuerpo) y normalización general de grafías | [vocabulario-tabla-completa-review.md](../knowledge/provenance/vocabulario-tabla-completa-review.md) |
| B3 | **Laguna Saju Jirugi punto 3:** el destino del golpe está ilegible en la única copia disponible (verificado por recortes ampliados, tinta erosionada). ¿Se aporta otra copia del manual o se confirma el dato desde criterio del revisor? | TKD-012: paso 3 completo | [ejercicios-enciclopedia-review.md](../knowledge/provenance/ejercicios-enciclopedia-review.md) |
| B4 | **`Baro`/`Bandae`:** el par invierte significado según posición (Gunnun Sogi vs Niunja Sogi). ¿Se conserva la distinción dependiente de la posición o se presenta de otra forma al alumno? | Formación del vocabulario (matriz de niveles/direcciones) | [vocabulario-tabla-completa-review.md](../knowledge/provenance/vocabulario-tabla-completa-review.md) |
| B5 | **Divergencia ONT/WEB en secciones del cuerpo:** ONT 12 añade rangos («encima del cuello», etc.) que WEB 10 no enuncia. ¿Es WEB incompleta o formulaciones distintas legítimas? | Cierre de la ficha `secciones_cuerpo_altura` | [secciones-cuerpo-review.md](../knowledge/provenance/secciones-cuerpo-review.md) |

## C. Decisiones técnicas del proyecto (usuario de ZVK Tech, no bloquean Fase 0)

| # | Pregunta | Qué desbloquea |
| --- | --- | --- |
| C1 | ~~Identidad~~ **Resuelta 01-11-2026:** **JWT local autoemitido** (clave de firma en `.env` local, usuarios y roles en PostgreSQL, sin proveedor externo, US$0). Decide: usuario de ZVK Tech (developer y creador del proyecto). Alcance: autoriza la implementación de Fase 3; **no abre ninguna ruta de contenido** | Fase 3: migración V7 de usuarios, login JWT y roles persistidos; `denyAll` sobre contenido intacto hasta C2 |
| C2 | Momento de abrir el primer endpoint de lectura de contenido (tras A1–A3) | Fase 2 educativa |

## Reglas que no cambian al responder

**Implementación C1 (02-11-2026):** V7, login JWT y `/me` implementados y auditados; sin registro ni refresh, sin cuentas sembradas y sin apertura de contenido. C2 permanece sin responder.

- Una respuesta aprueba **solo lo que pregunta esa fila**; no autoriza a sembrar datos ni a publicar.
- Las migraciones V1–V7 siguen inmutables; los JSON antiguos de la raíz no se promueven.
- El contenido sigue local: los PDFs de terceros no se redistribuyen.
- Con A1 respondida ya existe currículo real (`gup_10`, teórico): `validate:content` pasa, pero **no aprueba contenido** ni cierra la fundación mientras falte revisión humana.

**Estado de este documento:** creado el 29-10-2026; **C1 resuelta el 01-11-2026** (JWT local, decidida por el usuario de ZVK Tech) y **bloque A respondido el 01-11-2026** por el representante de la escuela (mismo usuario): A1, A4 y A5 **resueltas**; A2, A3, A6 y A7 **parciales** (detalle pendiente: criterio de desempate, nombre real, números de Saju y descripción de combate). **02-11-2026:** con A1 se creó el primer currículo real `gup_10` (teórico, `pending_human_review`). Bloque B sin respuestas; C2 pendiente. Actualizar cada fila al recibir el detalle, con responsable y fecha.
