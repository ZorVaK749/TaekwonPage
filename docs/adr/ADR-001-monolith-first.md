# ADR-001 — Monolito modular primero

- Estado: Aceptado; pendiente de implementación.
- Fecha de registro: 2026-10-14.
- Fuente: informe técnico, secciones 2, 5 y 50.

## Contexto

TaeKwonPage sirve a una sola escuela, con presupuesto limitado y necesidad de mantener límites de dominio claros sin complejidad distribuida.

## Decisión

Implementar inicialmente un único backend Java 21 con Spring Boot, organizado como monolito modular. No crear múltiples microservicios. Mantener separados los dominios para permitir extraer módulos en el futuro solo si existe una necesidad real.

## Consecuencias

Se reducen despliegues, consumo de recursos y dificultad de diagnóstico; se comparte una base transaccional. La organización interna debe evitar acoplamientos que impidan evolucionar los módulos. Las fronteras concretas se desarrollarán en tareas posteriores siguiendo la propuesta del informe.

Sprint 0 solo reserva `backend/taekwonpage-api/`; no genera una aplicación ni implementa módulos.
