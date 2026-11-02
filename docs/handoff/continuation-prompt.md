# Prompt de continuación — TaeKwonPage

**Uso:** copia el contenido de este archivo tal cual en un chat nuevo para retomar el proyecto sin perder contexto. Es una vista de traspaso, no una fuente de decisiones nueva: ante cualquier discrepancia, manda [informe_tecnico.md](../../informe_tecnico.md) y después [Plan_ataque.md](../../Plan_ataque.md).

**Estado de este traspaso:** 02-11-2026, informe **v1.32**; bloque de identidad auditado en `feat/backend-local-jwt-identity`, por el flujo habitual de push e integración revisada a `main`. Base anterior: currículo en `a6ec4c9`. Verificar `git status` y log antes de continuar; este documento no sustituye evidencia Git.

---

Eres el asistente técnico de **TaeKwonPage**, proyecto de **ZVK Tech** para la escuela de Taekwon-Do ITF **Taekwon-Do Nahuel Aukan**. Antes de tocar nada, lee en orden: `informe_tecnico.md` completo, `Plan_ataque.md`, `README.md`, y luego inspecciona el repositorio real. Reporta brevemente qué vas a modificar antes de hacer un cambio acotado.

## Decisiones ya confirmadas (no reabrir sin instrucción del usuario)

- **Arquitectura:** monolito modular Spring Boot; frontend Angular/TypeScript; API REST `/api/v1` con OpenAPI; PostgreSQL + Flyway; Docker/Compose; objetivo US$0 sin proveedor fijo. Sin microservicios.
- **Roles:** `ROLE_GUEST`, `ROLE_STUDENT`, `ROLE_ADMIN` (Busabonim de la escuela), `ROLE_DEVELOPER` (ZVK Tech). Rol y grado marcial son independientes; acceso acumulativo por grado autorizado **en backend**; alumno nuevo = `ROLE_STUDENT`, 10º Gup, `UNVERIFIED`; declarar grado crea solicitud `PENDING` que solo el admin aprueba/rechaza con historial.
- **Contenido:** la IA asiste en extracción/normalización, **nunca aprueba**. Nada de datos marciales inventados; toda ficha y cita vive con `pending_human_review` hasta revisión humana registrada. Los PDFs de terceros permanecen locales y sin commitear; la licencia MIT no cubre sus derechos.
- **Flujo de conocimiento:** PDF → extracción → normalización → JSON de trabajo → validación → revisión humana → catálogo canónico → seed/migración → PostgreSQL. Los JSON antiguos de la raíz (`Combate/`, `Gups/`, etc.) no se promueven.
- **Migraciones aplicadas (V1–V7) son inmutables** por checksums; el comportamiento se extiende con `CREATE OR REPLACE FUNCTION` en migraciones nuevas. La cadena de revisiones de borradores es global por `content_entry.draft_revision` y debe ser contigua.
- **Git:** trabajo en ramas con push, **merges periódicos revisados a `main` sin Pull Requests**; no borrar ramas, tags ni force-push sin autorización explícita; sin secretos, PDFs ni payloads operativos en Git.
- **Orden de trabajo acordado:** bloque actual **Fase 3: identidad local C1**, autorizado tras el currículo de 10º Gup y auditado por petición del usuario. **Sin abrir contenido ni quitar `denyAll`**; C2 sigue pendiente. La extracción de Fase 0 está agotada sobre los cuatro PDFs locales; sus decisiones humanas siguen abiertas en `docs/phase0-decisiones-pendientes.md`. Fase 1 sigue abierta por revisión/publicación y alcance completo del currículo.

## Estado verificado al cerrar este traspaso

- **Conocimiento (Fase 0, cerrada técnicamente):** 4 PDFs inventariados por hash; **90 fichas y 164 citas** en 16 pares catálogo/procedencia, todas `pending_human_review`; **un currículo real: `knowledge/curricula/gups/gup_10.json`** (02-11-2026, solo teórico —los seis temas del temario WEB 27 / ONT 35 enlazando siete fichas— con dos citas propias en `knowledge/provenance/gup_10.json`, demás grupos vacíos por no enunciar las copias requisitos técnicos). Cobertura completa de lo observable: teoría inicial y secciones del cuerpo, vocabulario íntegro de las tablas (niveles/direcciones, cuerpo, generales y nombres de técnica; solo queda el doble `Jirugi` por decisión del revisor), herramientas, posiciones, patadas, combate y listas parciales de Saju (con laguna de legibilidad verificada como no recuperable). Bloque de puntos vitales (kupso) observado sin extraer por sensibilidad marcial. **La extracción está agotada: todo lo pendiente depende de decisiones humanas, consolidadas en `docs/phase0-decisiones-pendientes.md`.** Cero aprobaciones humanas registradas.
- **Persistencia (Fase 1):** PostgreSQL local por Compose, migraciones **V1–V7** (texto, requisitos, detalles de posiciones/vocabulario, ejercicios/Tuls, citas versionados e identidad local, con historial, rollback y reserva de IDs). La BD de desarrollo tiene esquema y **los borradores importados, incluido el currículo real `gup_10`** (verificado: 7 requisitos de teoría y 2 citas); el resto de importaciones verificadas se hace en BD aisladas desechables (el harness gana una base dedicada que recarga el dataset real dos veces y comprueba el baseline V3 de `gup_10`; la base del fixture carga borradores con `--skip-curricula`). **Sin evidencia de revisión/publicación, sin seed aprobado.**
- **Backend:** ocho tipos con lectura interna, DTOs inmutables, citas y validación `CanonicalIds`; contenido HTTP bloqueado incluso con token válido. `gup_10` tiene siete teorías y dos citas; combate no selecciona ni aprueba modalidad. [OpenAPI 3.1](../openapi/taekwonpage-v1.json) documenta ocho lecturas bloqueadas más login y `/me`, con test anti-drift por método y ruta.
- **Identidad C1:** V7 crea `role`/`app_user`/`user_role`, cuatro roles y cero cuentas/asignaciones. JWT local HS256 (JDK), `JWT_SECRET` obligatorio ≥32 bytes, issuer y TTL configurable (1800 s por defecto). `POST /api/v1/auth/login` público con BCrypt; `GET /api/v1/me` exige Bearer y devuelve id/username/roles. Sin registro ni refresh. CSRF deshabilitado por API stateless sin cookies. Auditoría corrigió cortocircuito que evitaba BCrypt en cuentas ausentes/deshabilitadas; ahora se verifica siempre un hash. Credenciales acotadas (username 3–64 ASCII permitido, contraseña ≤72 bytes UTF-8); parser JWT estricto en tipos, tiempos, roles conocidos, duplicados, cabeceras y tamaño. Tokens son snapshots: deshabilitar una cuenta/cambiar roles no revoca los ya emitidos; falta resolverlo antes de abrir contenido, junto con rate limiting.
- **Tests:** 242 Node, 22 PowerShell, 54 Java (incluido HTTP real en puerto aleatorio: 400 conservado en login inválido mediante despacho interno ERROR, `/error` directo sigue 403); `Test-Database.ps1` con upgrades hasta V7, 11 rechazos nuevos de identidad y base dedicada del currículo real. `--check-local-files` y `--require-content` pasan (164 citas, 1 currículo); no prueban aprobación/completitud marcial.
- **No existe:** registro/alta operativa, grado del alumno, RBAC por grado, revocación inmediata, refresh, rate limiting, Angular, CI, deploy, beta, tags o releases.

## Próximos pasos inmediatos

1. La **lectura de backend está completa para los ocho tipos**; `GET /api/v1/gups/10` ya tiene el currículo teórico real en la base. Pendientes de la escuela: requisitos técnicos (A6 sin entregar), criterio de desempate (A2), nombre real del aprobador (A3) y descripción del contacto pactado (A7). Al recibirlos, actualizar `docs/openapi/taekwonpage-v1.json` y su test Node si el contrato cambia.
2. **Completar `docs/phase0-decisiones-pendientes.md` con el revisor**: filas B1–B5 sin responder y detalle de A2/A3/A6/A7; la puerta de cualquier endpoint educativo es C2 (decisión explícita del usuario tras el bloque A).
3. Con respuestas: registrarlas en los archivos enlados de cada fila (con responsable, fecha y alcance), extraer únicamente lo que desbloquen y ampliar el JSON de 10º Gup enlazando IDs existentes; concurrir con el revisor humano para validar/corregir fichas.
4. Identidad C1 implementada; falta cerrar TKD-016/TKD-017 para alta/grado/verificación, RBAC y política de revocación. C2 debe autorizar explícitamente cualquier apertura de contenido. No iniciar Angular ni otro milestone automáticamente.

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
