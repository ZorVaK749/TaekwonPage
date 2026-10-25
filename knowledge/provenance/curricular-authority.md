# TKD-002 — Autoridad curricular por confirmar

**Estado: pendiente de decisión de la escuela.** No es un ADR aceptado ni un programa de examen aprobado. Fuente de arquitectura: [informe_tecnico.md](../../informe_tecnico.md), TKD-002 y secciones 9–13.

## Regla ya aprobada

La escuela decide los requisitos de examen. La IA asiste en extracción y normalización, pero no aprueba contenido. Ningún número de páginas, fecha editorial, nombre de archivo o cantidad de coincidencias entre PDFs resuelve automáticamente una discrepancia.

## Confirmaciones necesarias del Busabonim

1. ¿Cuál es el programa vigente de Nahuel Aukan para 10º Gup y su examen? Identificar documento/versión o confirmación explícita de la escuela.
2. ¿Qué manual ONT se utiliza, si alguno, y con qué alcance? Si se utilizan ambos, indicar cómo resolver sus diferencias.
3. ¿Qué función tendrá la copia `source_enciclopedia_taekwondo`: referencia técnica, histórica u otra? Su edición observada no la convierte automáticamente en programa vigente.
4. ¿Quién revisará y aprobará los datos extraídos, y cómo se registrará esa aprobación?

No se interpreta una autorización genérica para continuar programando como aprobación de estas decisiones marciales.

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

Completar este registro con responsable funcional, fecha real de confirmación, evidencia verificable, programa aplicable, fuentes y alcance, resoluciones de discrepancias y versión del currículo revisado. **No hay todavía persona, fecha ni aprobación registrada.** No asignar automáticamente al usuario el papel de revisor marcial.

Mientras tanto se puede preparar la estructura técnica de esquemas y citas como borrador. No promover los JSON anteriores a catálogos canónicos, publicar requisitos definitivos, rellenar lagunas desde conocimiento general ni avanzar a 9º Gup como si 10º estuviese validado.
