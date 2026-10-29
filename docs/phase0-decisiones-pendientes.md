# Fase 0 — decisiones pendientes consolidadas

**Propósito:** un único punto de respuesta para cerrar la base de conocimiento. La extracción documental de la Fase 0 está **agotada**: con los cuatro PDFs locales se hizo todo lo que se puede hacer sin decidir. Cada fila de abajo es una decisión que **solo la escuela o el revisor marcial pueden tomar**; hasta entonces todo sigue en `pending_human_review` y `validate:content` sigue fallando a propósito.

**Uso:** entregar este documento al Busabonim/escuela y al revisor designado. Cada respuesta debe quedar registrada con **nombre real, fecha y alcance** en los archivos enlazados; una respuesta genérica de «sigan» no aprueba contenido marcial.

## A. Para la escuela (Busabonim de Nahuel Aukan)

| # | Pregunta | Qué desbloquea | Dónde registrar la respuesta |
| --- | --- | --- | --- |
| A1 | ¿Cuál es el **programa vigente de 10º Gup** y su examen? (documento/versión o confirmación explícita) | TKD-009: primer currículo real; cierre de la fundación de `validate:content` | [curricular-authority.md](../knowledge/provenance/curricular-authority.md) |
| A2 | ¿Qué **manual(es)** aplican (WEB, ONT, enciclopedia) y cómo resolver sus diferencias? | TKD-002: autoridad curricular; prioridad entre copias divergentes | [curricular-authority.md](../knowledge/provenance/curricular-authority.md) |
| A3 | ¿**Quién revisa y aprueba** el contenido marcial, y cómo se registra esa aprobación? | Todas las fichas: pasar de `pending_human_review` a aprobadas con evidencia | [curricular-authority.md](../knowledge/provenance/curricular-authority.md) |
| A4 | ¿Se exige el bloque de **puntos vitales (kupso)** en 10º Gup, y con qué alcance? | Extracción del único bloque observable aún sin extraer (alto sensibilidad marcial) | [secciones-cuerpo-review.md](../knowledge/provenance/secciones-cuerpo-review.md) |
| A5 | ¿Qué **variante de Junbi** usa la escuela (Narani Junbi Sogi u otra) y con qué geometría? | TKD-005: adopción de la posición inicial de los ejercicios | [posicion_preparatoria_paralela-review.md](../knowledge/provenance/posicion_preparatoria_paralela-review.md) |
| A6 | ¿Cuál es el **conteo total y la ejecución alterna** de Saju Jirugi / Saju Makgi en su programa? | TKD-012/TKD-013: `movement_count`, `sequence_complete` | [ejercicios-enciclopedia-review.md](../knowledge/provenance/ejercicios-enciclopedia-review.md) |
| A7 | ¿Qué **modalidad de combate pactado** aplica (y si existe la forma «sin contacto» del archivo antiguo)? | Catálogo de combate; resolución de `ibo_matsokgi` vs variantes | [combate-y-patadas-review.md](../knowledge/provenance/combate-y-patadas-review.md) |

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
| C1 | Identidad: **JWT u OIDC** (y proveedor) | Fase 3; hoy todo va con `denyAll` y roles en memoria |
| C2 | Momento de abrir el primer endpoint de lectura de contenido (tras A1–A3) | Fase 2 educativa |

## Reglas que no cambian al responder

- Una respuesta aprueba **solo lo que pregunta esa fila**; no autoriza a sembrar datos ni a publicar.
- Las migraciones V1–V6 siguen inmutables; los JSON antiguos de la raíz no se promueven.
- El contenido sigue local: los PDFs de terceros no se redistribuyen.
- Sin currículo real (A1), `validate:content` debe seguir fallando.

**Estado de este documento:** creado el 29-10-2026 sin respuestas registradas. Actualizar cada fila al recibir respuesta real, con responsable y fecha.
