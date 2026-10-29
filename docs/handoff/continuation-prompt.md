# Prompt de continuación — TaeKwonPage

**Uso:** copia el contenido de este archivo tal cual en un chat nuevo para retomar el proyecto sin perder contexto. Es una vista de traspaso, no una fuente de decisiones nueva: ante cualquier discrepancia, manda [informe_tecnico.md](../../informe_tecnico.md) y después [Plan_ataque.md](../../Plan_ataque.md).

**Estado de este traspaso:** 29-10-2026, `main` en `66dcfda`, árbol limpio y publicado en `origin` (informe v1.26).

---

Eres el asistente técnico de **TaeKwonPage**, proyecto de **ZVK Tech** para la escuela de Taekwon-Do ITF **Taekwon-Do Nahuel Aukan**. Antes de tocar nada, lee en orden: `informe_tecnico.md` completo, `Plan_ataque.md`, `README.md`, y luego inspecciona el repositorio real. Reporta brevemente qué vas a modificar antes de hacer un cambio acotado.

## Decisiones ya confirmadas (no reabrir sin instrucción del usuario)

- **Arquitectura:** monolito modular Spring Boot; frontend Angular/TypeScript; API REST `/api/v1` con OpenAPI; PostgreSQL + Flyway; Docker/Compose; objetivo US$0 sin proveedor fijo. Sin microservicios.
- **Roles:** `ROLE_GUEST`, `ROLE_STUDENT`, `ROLE_ADMIN` (Busabonim de la escuela), `ROLE_DEVELOPER` (ZVK Tech). Rol y grado marcial son independientes; acceso acumulativo por grado autorizado **en backend**; alumno nuevo = `ROLE_STUDENT`, 10º Gup, `UNVERIFIED`; declarar grado crea solicitud `PENDING` que solo el admin aprueba/rechaza con historial.
- **Contenido:** la IA asiste en extracción/normalización, **nunca aprueba**. Nada de datos marciales inventados; toda ficha y cita vive con `pending_human_review` hasta revisión humana registrada. Los PDFs de terceros permanecen locales y sin commitear; la licencia MIT no cubre sus derechos.
- **Flujo de conocimiento:** PDF → extracción → normalización → JSON de trabajo → validación → revisión humana → catálogo canónico → seed/migración → PostgreSQL. Los JSON antiguos de la raíz (`Combate/`, `Gups/`, etc.) no se promueven.
- **Migraciones aplicadas (V1–V6) son inmutables** por checksums; el comportamiento se extiende con `CREATE OR REPLACE FUNCTION` en migraciones nuevas. La cadena de revisiones de borradores es global por `content_entry.draft_revision` y debe ser contigua.
- **Git:** trabajo en ramas con push, **merges periódicos revisados a `main` sin Pull Requests**; no borrar ramas, tags ni force-push sin autorización explícita; sin secretos, PDFs ni payloads operativos en Git.
- **Orden de trabajo acordado:** Fase 1 (persistencia) hasta donde es verificable → **retomar Fase 0 (conocimiento), que es el bloque activo y está en cierre** → volver a Fase 2 (backend). El usuario confirmó el 25-10-2026 retomar Fase 0 porque aún no hay programa vigente ni revisor designados; Fase 1 queda **abierta**, no cerrada. El 29-10-2026 el usuario pidió **cerrar Fase 0 limpio y rápido**: la extracción se dio por agotada y las decisiones pendientes se consolidaron en `docs/phase0-decisiones-pendientes.md`; no seguir extrayendo hasta recibir respuestas reales.

## Estado verificado al cerrar este traspaso

- **Conocimiento (Fase 0, en cierre):** 4 PDFs inventariados por hash; **89 fichas y 162 citas** en 15 pares catálogo/procedencia, todas `pending_human_review`; **cero currículos** en `knowledge/curricula/`. Cobertura completa de lo observable: teoría inicial y secciones del cuerpo, vocabulario íntegro de las tablas (niveles/direcciones, cuerpo, generales y nombres de técnica; solo queda el doble `Jirugi` por decisión del revisor), herramientas, posiciones, patadas, combate y listas parciales de Saju (con laguna de legibilidad verificada como no recuperable). Bloque de puntos vitales (kupso) observado sin extraer por sensibilidad marcial. **La extracción está agotada: todo lo pendiente depende de decisiones humanas, consolidadas en `docs/phase0-decisiones-pendientes.md`.** Cero aprobaciones humanas registradas.
- **Persistencia (Fase 1):** PostgreSQL local por Compose, migraciones **V1–V6** (texto, requisitos, detalles de posiciones/vocabulario, ejercicios/Tuls y citas versionados, con historial, rollback y reserva de IDs). La BD de desarrollo tiene esquema y **cero contenido cargado**; las importaciones verificadas se hacen en BD aisladas desechables. **Sin currículo real importado, sin evidencia de revisión/publicación, sin seed aprobado.**
- **Backend (Fase 2, pausado):** Spring Boot 3.5.16 / Java 21; lectura interna de posiciones con citas; HTTP bloqueado (`denyAll`), solo salud accesible; 17 pruebas Java con Testcontainers. Sin `GET /api/v1/gups/10`, sin OpenAPI completo.
- **Tests:** 235 Node (validadores/exportadores), 22 PowerShell (inventario), 17 Java, más `Test-Database.ps1` (migraciones/recargas/rechazos SQL, conteos 97/170). **`validate:content` DEBE fallar** con «content foundation incomplete: at least one catalog and curriculum are required»: es el esperado mientras no haya currículo real.
- **No existe:** identidad/JWT-OIDC (sin decidir), Angular, CI, deploy, beta, tags o releases.

## Próximos pasos inmediatos (Fase 0 en cierre)

1. **Enviar `docs/phase0-decisiones-pendientes.md` al Busabonim/revisor** y esperar respuestas reales. La Fase 0 no avanza por más extracción: está agotada. Las preguntas A1–A3 (programa, manual, revisor) son la puerta de todo lo demás.
2. Al recibir respuestas: registrarlas en los archivos enlados de cada fila (con responsable, fecha y alcance), extraer únicamente lo que desbloquen (p. ej. kupso si A4 lo aprueba; currículo de 10º Gup si A1+A2+A3) y solo entonces construir el JSON de 10º Gup enlazando IDs existentes.
3. Concurrir con el revisor humano designado para que valide/corrija las fichas existentes; registrar identidad, alcance y fecha reales de cada revisión.
4. Si el usuario decide pasar a Fase 2 sin currículo (opción C2), hacer solo lecturas de contenido existente; los endpoints educativos nuevos siguen esperando a A1–A3.
5. Decidir identidad (JWT u OIDC, Fase 3) antes de abrir rutas autenticadas.

## Límites que no se cruzan

- No marcar un `[x]`, fase o TKD como completado por existir carpetas, DTOs o tests sintéticos; un `[x]` no es aprobación humana.
- No cerrar Fase 1 por pruebas sintéticas: faltan evidencia de revisión/publicación, currículo real y seed aprobado.
- No pasar a 9º/8º Gup hasta demostrar reusable la estructura de 10º Gup.
- No editar migraciones aplicadas, no promover JSON antiguos, no adoptar variantes de un solo manual como oficiales, no resolver discrepancias por número de páginas o cantidad de coincidencias.
- No inventar totales, secuencias alternas, angulos ni folios impresos; los `null` se conservan.
- No abrir endpoints educativos, no publicar contenido ni modificar `denyAll` sin decisión explícita del usuario.

## Comandos de validación habituales

```powershell
npm.cmd --prefix tools/validators test              # suites Node
npm.cmd --prefix tools/validators run report        # resumen reproducible de estado
node tools/validators/validate-knowledge.mjs --check-local-files   # identidad de PDFs y citas
node tools/validators/validate-knowledge.mjs --require-content     # debe FALLAR: sin currículo real
powershell -NoProfile -File tools/validators/Test-Database.ps1     # requiere Docker; BD aislada
docker compose run --rm migrate                    # migraciones en la BD local de desarrollo
cmd.exe /d /c 'mvn.cmd -B -ntp -f backend/taekwonpage-api/pom.xml verify'   # backend + Testcontainers
```

## Al cerrar cada bloque

Actualiza `informe_tecnico.md` (versión, fecha, checklist 55, evidencia, historial de versiones) y `Plan_ataque.md` en sincronía, documenta el límite de lo hecho, reporta archivos/comandos/errores/decisiones pendientes, y **no avances al siguiente milestone sin instrucción del usuario**. Rama → push → merge revisado a `main` sin PR.
