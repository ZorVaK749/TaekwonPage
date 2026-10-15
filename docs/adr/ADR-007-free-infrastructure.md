# ADR-007 — Infraestructura portable con objetivo US$0

- Estado: Aceptado; pendiente de implementación.
- Fecha de registro: 2026-10-14.
- Fuente: informe técnico, secciones 29 a 35.

## Contexto

El presupuesto objetivo es US$0 y las condiciones de las ofertas gratuitas pueden cambiar.

## Decisión

Priorizar hosting estático gratuito para Angular, una opción gratuita viable para el backend y un tier gratuito de PostgreSQL. Utilizar GitHub Actions para CI/CD y mantener portabilidad mediante Docker y variables de entorno, sin dependencia técnica de un proveedor concreto. Utilizar Docker Compose para el entorno local cuando corresponda.

## Consecuencias

US$0 es un objetivo, no una garantía de capacidad ni disponibilidad de proveedores. Deberán evaluarse condiciones y límites antes de elegir servicios. No introducir Kubernetes ni infraestructura adicional sin necesidad real. No desplegar automáticamente a producción mientras el pipeline no sea estable ni versionar secretos.

Sprint 0 no selecciona proveedores, provisiona servicios, crea workflows ni despliega. Compose se difiere conforme al alcance específico de esta tarea; los directorios de infraestructura quedan preparados.
