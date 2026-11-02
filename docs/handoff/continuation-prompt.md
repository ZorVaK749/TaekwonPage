# Prompt de continuación — TaeKwonPage

**Uso:** copia el contenido de este archivo tal cual en un chat nuevo para retomar el proyecto sin perder contexto. Es una vista de traspaso, no una fuente de decisiones nueva: ante cualquier discrepancia, manda [informe_tecnico.md](../../informe_tecnico.md) y después [Plan_ataque.md](../../Plan_ataque.md).

**Estado de este traspaso:** 02-11-2026, informe **v1.31**; último cierre integrado en `main` por el flujo habitual de ramas (currículo de 10º Gup en `feat/knowledge-gup-10-curriculum`, tras decisiones C1/A1–A7 en `docs/school-decision-answers`).

---

Eres el asistente técnico de **TaeKwonPage**, proyecto de **ZVK Tech** para la escuela de Taekwon-Do ITF **Taekwon-Do Nahuel Aukan**. Antes de tocar nada, lee en orden: `informe_tecnico.md` completo, `Plan_ataque.md`, `README.md`, y luego inspecciona el repositorio real. Reporta brevemente qué vas a modificar antes de hacer un cambio acotado.

## Decisiones ya confirmadas (no reabrir sin instrucción del usuario)

- **Arquitectura:** monolito modular Spring Boot; frontend Angular/TypeScript; API REST `/api/v1` con OpenAPI; PostgreSQL + Flyway; Docker/Compose; objetivo US$0 sin proveedor fijo. Sin microservicios.
- **Roles:** `ROLE_GUEST`, `ROLE_STUDENT`, `ROLE_ADMIN` (Busabonim de la escuela), `ROLE_DEVELOPER` (ZVK Tech). Rol y grado marcial son independientes; acceso acumulativo por grado autorizado **en backend**; alumno nuevo = `ROLE_STUDENT`, 10º Gup, `UNVERIFIED`; declarar grado crea solicitud `PENDING` que solo el admin aprueba/rechaza con historial.
- **Contenido:** la IA asiste en extracción/normalización, **nunca aprueba**. Nada de datos marciales inventados; toda ficha y cita vive con `pending_human_review` hasta revisión humana registrada. Los PDFs de terceros permanecen locales y sin commitear; la licencia MIT no cubre sus derechos.
- **Flujo de conocimiento:** PDF → extracción → normalización → JSON de trabajo → validación → revisión humana → catálogo canónico → seed/migración → PostgreSQL. Los JSON antiguos de la raíz (`Combate/`, `Gups/`, etc.) no se promueven.
- **Migraciones aplicadas (V1–V6) son inmutables** por checksums; el comportamiento se extiende con `CREATE OR REPLACE FUNCTION` en migraciones nuevas. La cadena de revisiones de borradores es global por `content_entry.draft_revision` y debe ser contigua.
- **Git:** trabajo en ramas con push, **merges periódicos revisados a `main` sin Pull Requests**; no borrar ramas, tags ni force-push sin autorización explícita; sin secretos, PDFs ni payloads operativos en Git.
- **Orden de trabajo acordado:** **Fase 2 sin endpoints educativos es el bloque activo** (decisión del usuario del 29-10-2026): ampliar lecturas internas, refactorizar y documentar OpenAPI con rutas protegidas, **sin tocar `denyAll`**. La **Fase 0 quedó cerrada técnicamente**: extracción agotada sobre los cuatro PDFs locales, decisiones pendientes consolidadas en `docs/phase0-decisiones-pendientes.md` (A1–A7 y C1 registradas el 01-11-2026; no seguir extrayendo hasta respuestas reales). Fase 1 sigue **abierta** por sus dependencias humanas (revisión/publicación, alcance completo del currículo).

## Estado verificado al cerrar este traspaso

- **Conocimiento (Fase 0, cerrada técnicamente):** 4 PDFs inventariados por hash; **90 fichas y 164 citas** en 16 pares catálogo/procedencia, todas `pending_human_review`; **un currículo real: `knowledge/curricula/gups/gup_10.json`** (02-11-2026, solo teórico —los seis temas del temario WEB 27 / ONT 35 enlazando siete fichas— con dos citas propias en `knowledge/provenance/gup_10.json`, demás grupos vacíos por no enunciar las copias requisitos técnicos). Cobertura completa de lo observable: teoría inicial y secciones del cuerpo, vocabulario íntegro de las tablas (niveles/direcciones, cuerpo, generales y nombres de técnica; solo queda el doble `Jirugi` por decisión del revisor), herramientas, posiciones, patadas, combate y listas parciales de Saju (con laguna de legibilidad verificada como no recuperable). Bloque de puntos vitales (kupso) observado sin extraer por sensibilidad marcial. **La extracción está agotada: todo lo pendiente depende de decisiones humanas, consolidadas en `docs/phase0-decisiones-pendientes.md`.** Cero aprobaciones humanas registradas.
- **Persistencia (Fase 1):** PostgreSQL local por Compose, migraciones **V1–V6** (texto, requisitos, detalles de posiciones/vocabulario, ejercicios/Tuls y citas versionados, con historial, rollback y reserva de IDs). La BD de desarrollo tiene esquema y **los borradores importados, incluido el currículo real `gup_10`** (verificado: 7 requisitos de teoría y 2 citas); el resto de importaciones verificadas se hace en BD aisladas desechables (el harness gana una base dedicada que recarga el dataset real dos veces y comprueba el baseline V3 de `gup_10`; la base del fixture carga borradores con `--skip-curricula`). **Sin evidencia de revisión/publicación, sin seed aprobado.**
- **Backend (Fase 2, activa sin endpoints educativos):** Spring Boot 3.5.16 / Java 21; lectura interna de **los ocho tipos** —posición, teoría, vocabulario (`translation`+`aliases`), herramientas corporales, tuls (pasos con sus citas por paso), kick, tipo de combate y **Gup** (esquema curricular con sus siete grupos de requisitos, `GET /api/v1/gups/{1..10}`, rango validado 1–10)— con DTOs inmutables y validación única de IDs (`shared/ids/CanonicalIds`); contrato [OpenAPI 3.1](../../docs/openapi/taekwonpage-v1.json) verificado por tests Node contra los controladores y contra `denyAll`. HTTP bloqueado (`denyAll` intacto), solo salud accesible; 33 pruebas Java con Testcontainers. La lectura de combate no selecciona ni aprueba modalidad alguna; con el currículo real `gup_10` en la base, `GET /api/v1/gups/10` tiene datos internos (teoría y citas) y sigue sin crear ni rellenar currículo. **Sin identidad implementada (C1 ya decidida: JWT local).**
- **Tests:** 241 Node (validadores/exportadores, incluido el contrato OpenAPI), 22 PowerShell (inventario), 33 Java, más `Test-Database.ps1` (migraciones/recargas/rechazos SQL, conteos 97/170 + 37 de citas/propiedad, y la base dedicada de currículo real). **`validate:content` pasa desde el 02-11-2026** (164 citas, 1 currículo): es control de presencia/consistencia, no de aprobación ni completitud.
- **No existe:** identidad/JWT implementada (C1 decidida el 01-11-2026, falta implementar), Angular, CI, deploy, beta, tags o releases.

## Próximos pasos inmediatos (Fase 2 activa)

1. La **lectura de backend está completa para los ocho tipos**; `GET /api/v1/gups/10` ya tiene el currículo teórico real en la base. Pendientes de la escuela: requisitos técnicos (A6 sin entregar), criterio de desempate (A2), nombre real del aprobador (A3) y descripción del contacto pactado (A7). Al recibirlos, actualizar `docs/openapi/taekwonpage-v1.json` y su test Node si el contrato cambia.
2. **Completar `docs/phase0-decisiones-pendientes.md` con el revisor**: filas B1–B5 sin responder y detalle de A2/A3/A6/A7; la puerta de cualquier endpoint educativo es C2 (decisión explícita del usuario tras el bloque A).
3. Con respuestas: registrarlas en los archivos enlados de cada fila (con responsable, fecha y alcance), extraer únicamente lo que desbloquen y ampliar el JSON de 10º Gup enlazando IDs existentes; concurrir con el revisor humano para validar/corregir fichas.
4. Decidir e implementar identidad (C1 ya elegida: JWT local, Fase 3) **antes** de abrir cualquier ruta autenticada; hoy todo `/api/v1` devuelve 403 por diseño.

## Límites que no se cruzan

- No marcar un `[x]`, fase o TKD como completado por existir carpetas, DTOs o tests sintéticos; un `[x]` no es aprobación humana.
- No cerrar Fase 1 por pruebas sintéticas: faltan evidencia de revisión/publicación, alcance completo del currículo real y seed aprobado.
- No pasar a 9º/8º Gup hasta demostrar reusable la estructura de 10º Gup.
- No editar migraciones aplicadas, no promover JSON antiguos, no adoptar variantes de un solo manual como oficiales, no resolver discrepancias por número de páginas o cantidad de coincidencias.
- No inventar totales, secuencias alternas, angulos ni folios impresos; los `null` se conservan.
- No abrir endpoints educativos, no publicar contenido ni modificar `denyAll` sin decisión explícita del usuario.

## Comandos de validación habituales

```powershell
npm.cmd --prefix tools/validators test              # suites Node
npm.cmd --prefix tools/validators run report        # resumen reproducible de estado
node tools/validators/validate-knowledge.mjs --check-local-files   # identidad de PDFs y citas
node tools/validators/validate-knowledge.mjs --require-content     # pasa desde 02-11-2026 (gup_10)
powershell -NoProfile -File tools/validators/Test-Database.ps1     # requiere Docker; BD aislada
docker compose run --rm migrate                    # migraciones en la BD local de desarrollo
cmd.exe /d /c 'mvn.cmd -B -ntp -f backend/taekwonpage-api/pom.xml verify'   # backend + Testcontainers
```

## Al cerrar cada bloque

Actualiza `informe_tecnico.md` (versión, fecha, checklist 55, evidencia, historial de versiones) y `Plan_ataque.md` en sincronía, documenta el límite de lo hecho, reporta archivos/comandos/errores/decisiones pendientes, y **no avances al siguiente milestone sin instrucción del usuario**. Rama → push → merge revisado a `main` sin PR.
