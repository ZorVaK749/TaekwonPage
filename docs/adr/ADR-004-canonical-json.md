# ADR-004 — JSON canónico y separación curricular

- Estado: Aceptado; pendiente de implementación.
- Fecha de registro: 2026-10-14.
- Fuente: informe técnico, secciones 9, 10, 13 y 38.

## Contexto

El conocimiento documental debe poder normalizarse, validarse y reutilizarse sin duplicar definiciones entre grados.

## Decisión

Mantener catálogos de contenido separados de los currículos por Gup. Los Gups referencian IDs existentes en los catálogos. Utilizar JSON canónico tras validación y revisión humana, con futuros JSON Schemas y validadores de referencias y consistencia.

Los IDs canónicos serán `snake_case`, en minúsculas, sin tildes, `ñ` ni espacios, estables e inmutables una vez publicados. El pipeline termina en importación a PostgreSQL; JSON no sustituye la persistencia aprobada.

## Consecuencias

Se requiere validar referencias y evitar duplicados antes de publicar. No se inventan campos marciales, medidas, requisitos ni secuencias para llenar archivos. El detalle de los esquemas y las convenciones aún pendientes se resolverá en tareas de conocimiento.

Los JSON preexistentes se conservan sin promoverlos a canónicos. Sprint 0 crea directorios, no catálogos ni schemas.
