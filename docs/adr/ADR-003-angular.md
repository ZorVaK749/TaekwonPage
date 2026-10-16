# ADR-003 — Angular y TypeScript

- Estado: Aceptado; pendiente de implementación.
- Fecha de registro: 2026-10-14.
- Fuente: informe técnico, secciones 2 y 20 a 24.

## Contexto

La plataforma tendrá áreas pública, de alumno y administrativa, con identidad visual institucional y consumo de la API del backend.

## Decisión

Utilizar Angular con TypeScript. Seguir la organización propuesta de `core`, `shared`, `layouts` y `features` cuando se inicialice la aplicación. El informe recomienda componentes standalone salvo justificación concreta para usar NgModules.

## Consecuencias

Los guards mejorarán la experiencia, pero no sustituirán la autorización del backend. El grado no se concederá por modificar rutas o estado del frontend. El branding se basará en el logo oficial cuando el asset esté disponible.

Sprint 0 solo reserva `frontend/taekwonpage-web/`; no elige versiones, genera componentes, instala paquetes ni diseña interfaces finales.
