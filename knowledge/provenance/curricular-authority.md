# TKD-002 — Autoridad curricular confirmada (criterio de desempate pendiente)

**Estado: decisión escolar parcialmente registrada el 01-11-2026.** El programa vigente y los manuales aplicables quedaron confirmados por la escuela; el criterio de desempate entre copias y el nombre real del aprobador siguen pendientes. Fuente de arquitectura: [informe_tecnico.md](../../informe_tecnico.md), TKD-002 y secciones 9–13.

## Registro de decisiones — 01-11-2026

Respuestas del representante de la escuela (usuario de ZVK Tech, developer y creador del proyecto, y mano derecha de la escuela), recogidas mediante el [consolidado de decisiones](../../docs/phase0-decisiones-pendientes.md):

| Fila | Decisión registrada | Alcance | Pendiente |
| --- | --- | --- | --- |
| A1 | El **programa vigente de 10º Gup es el de las copias ya citadas** (`source_teoria_completa_web`, `source_teoria_ont`, `source_enciclopedia_taekwondo`), confirmado explícitamente. | TKD-009: permite construir el primer currículo real **solo con lo que esas copias enuncian** para 10º Gup (hoy: los seis temas del temario teórico WEB 27 / ONT 35). Requisitos técnicos que las copias no enuncian siguen sin existir y no se completan por costumbre marcial. | — |
| A2 | **Aplican las tres copias** (WEB, ONT y enciclopedia); ninguna manda automáticamente sobre otra. | TKD-002: las tres son material del programa escolar. | **Criterio de desempate sin especificar**: hasta que llegue, las discrepancias se conservan documentadas y sin resolver. |
| A3 | **Revisor y aprobador designado: el propio usuario**, en su rol de mano derecha de la escuela (designación explícita, no asignada por la IA). | Habilita aprobación humana real cuando el esquema la soporte: hoy `review_status` solo admite `pending_human_review`, así que el flujo de revisión/publicación está sin implementar. | **Nombre real para el registro** y mecanismo de aprobación con evidencia. |

Estas respuestas registran **autoridad**, no aprobación marcial de ninguna ficha.

## Regla ya aprobada

La escuela decide los requisitos de examen. La IA asiste en extracción y normalización, pero no aprueba contenido. Ningún número de páginas, fecha editorial, nombre de archivo o cantidad de coincidencias entre PDFs resuelve automáticamente una discrepancia.

## Confirmaciones necesarias del Busabonim

1. ~~¿Cuál es el programa vigente?~~ **Resuelta (A1, 01-11-2026):** el programa vigente es el de las copias citadas; ver registro arriba.
2. ~~¿Qué manual ONT se utiliza~~ **Parcialmente resuelta (A2):** aplican las tres copias; falta el criterio de desempate entre sus diferencias.
3. ¿Qué función tendrá la copia `source_enciclopedia_taekwondo`: referencia técnica, histórica u otra? **Parcial (A2):** es una de las tres copias aplicables; su función específica no se detalló.
4. ~~¿Quién revisará y aprobará?~~ **Parcialmente resuelta (A3):** designado el usuario (mano derecha de la escuela); falta nombre real y mecanismo de registro de aprobación.

No se interpreta una autorización genérica para continuar programando como aprobación de decisiones marciales puntuales.

## Registro de asuntos abiertos

| Asunto | Evidencia | Falta decidir / comprobar |
| --- | --- | --- |
| Variantes del saludo | `source_teoria_completa_web`, página PDF 7; `source_teoria_ont`, página PDF 8 | Redacción aplicable a la escuela; no se elige una por defecto |
| Nota editorial incompleta | `source_teoria_ont`, página PDF 17 | Revisar la sección antes de normalizarla |
| Cobertura de 10º Gup | Temario de examen 10º a 9º en páginas PDF 27 (WEB) y 35 (ONT); enumera solo temas de teoría, sin posiciones, Tuls, patadas ni combate | Requisitos técnicos completos y correspondencia con el programa vigente |
| Profundidad teórica y clasificación | [Matriz de seis temas y siete fichas de trabajo](temario_teorico_10gup-review.md); clasificación en WEB 6 / ONT 7 con romanizaciones divergentes | Validar contenido/profundidad, resolver grafías y confirmar aplicabilidad escolar; no implica aprobación ni cierre de TKD-015 |
| Modalidades de combate pactado | `sambo_matsokgi` e `ilbo_matsokgi` en ambas copias; `ibo_matsokgi` solo en ONT 10 | Validez y variante aplicable; el archivo antiguo menciona una forma «sin contacto» ausente en las fuentes |
| Borrador previo | `Gups/10gup.json` y sus catálogos en la raíz, sin citas explícitas | Revisar cada requisito; el archivo no demuestra aprobación curricular |
| Romanización | Variantes documentales ya observadas | Convención de presentación y alias sin alterar IDs publicados |
| Variante inicial Junbi/Jumbi | Vocabulario WEB 11 y ONT 13; definición específica de Narani Junbi Sogui en enciclopedia PDF 81 y preparación de los tramos en PDF 530 | El enlace documental de esa copia ya referencia `narani_junbi_sogi`; falta confirmar adopción escolar, sin convertir todo Junbi en sinónimo o heredar geometrías del borrador |
| Referencias geométricas | Posiciones en WEB 24 y ONT 31–32 | Definir unidades, puntos de referencia y convención angular antes de convertir a coordenadas/rotaciones |
| Referencia bibliográfica | Enciclopedia, páginas PDF 3–5 | Su autoridad y aplicabilidad curricular, no suprimir discrepancias por autoría o fecha |

## Cómo registrar la decisión cuando exista

Completar este registro con responsable funcional, fecha real de confirmación, evidencia verificable, programa aplicable, fuentes y alcance, resoluciones de discrepancias y versión del currículo revisado. **Designación hecha el 01-11-2026 por el usuario como representante de la escuela (no asignada por la IA); quedan pendientes su nombre real, el criterio de desempate y la aprobación de cualquier ficha concreta.**

Mientras tanto se puede preparar la estructura técnica de esquemas y citas como borrador. No promover los JSON anteriores a catálogos canónicos, publicar requisitos definitivos, rellenar lagunas desde conocimiento general ni avanzar a 9º Gup como si 10º estuviese validado.
