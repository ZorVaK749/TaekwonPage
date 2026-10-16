# ADR-002 — PostgreSQL como persistencia

- Estado: Aceptado; pendiente de implementación.
- Fecha de registro: 2026-10-14.
- Fuente: informe técnico, secciones 2, 17 y 40.

## Contexto

Usuarios, grados, solicitudes, catálogos, currículos, procedencia e historial requieren relaciones e integridad de datos.

## Decisión

Utilizar PostgreSQL, Spring Data JPA / Hibernate y Flyway para las migraciones del esquema. Los JSON canónicos aprobados se importarán mediante seed/migración conforme al pipeline documental.

## Consecuencias

El esquema deberá evolucionar de forma versionada, con restricciones y pruebas apropiadas. El modelo relacional del informe es preliminar, no una migración ya aprobada en detalle. No se sustituye PostgreSQL por otra base de datos para el entorno definitivo.

Sprint 0 no crea tablas, migraciones, seeds, instancias ni credenciales; la versión concreta de PostgreSQL queda por definir.
