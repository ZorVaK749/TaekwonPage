# ADR-006 — Procedencia documental y revisión humana

- Estado: Aceptado; pendiente de implementación.
- Fecha de registro: 2026-10-14.
- Fuente: informe técnico, secciones 11 a 13, TKD-001 y TKD-002; instrucción de Sprint 0 sobre PDFs locales.

## Contexto

La información marcial debe poder rastrearse a los PDFs del proyecto. La disponibilidad de un archivo no garantiza exactitud, autoridad curricular ni derechos de publicación.

## Decisión

Identificar la fuente y la página o sección de cada dato relevante; extraer, normalizar, contrastar y validar antes de la aprobación humana y publicación. Mantener la procedencia separada y vinculada al contenido. La IA puede asistir, pero no sustituye las fuentes ni la aprobación humana.

No inventar información marcial ni tratar ejemplos del informe como hechos oficiales. Las discrepancias requieren revisión humana; la escuela decide los requisitos de examen.

Los PDFs permanecen locales y excluidos de Git mientras no exista autorización de redistribución. No se asume una licencia por su disponibilidad.

## Consecuencias

Será necesario inventariar fuentes, verificar metadatos y diseñar el esquema de procedencia. No se atribuyen autoría, edición o carácter oficial a partir de nombres de archivo. Los extractos y derivados también requieren revisar los derechos aplicables antes de publicarse.

Sprint 0 solo documenta la política y la presencia local de los cuatro PDFs; no extrae ni publica contenido. Véase [fuentes](../../knowledge/sources/README.md).
