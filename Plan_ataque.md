# Plan de ataque — TaeKwonPage

**Actualizado: 02-11-2026.** Vista de seguimiento del [informe técnico](informe_tecnico.md), no un plan nuevo que reemplace su arquitectura o alcance. Para continuar desde otro chat: **[prompt de continuación](docs/handoff/continuation-prompt.md)**, siempre contrastado contra el informe.

- `[x]` = el entregable descrito está implementado/verificado.
- `[ ]` = pendiente o parcial; el texto indica cuál de los dos.
- Tener tests correctos no significa aprobación marcial ni fase terminada. No usamos porcentajes porque las tareas tienen esfuerzos distintos.
- **Sprint 0 (repositorio) no es Fase 0 (conocimiento).** Un milestone puede abarcar varias fases.

## Dónde estamos

| Fase original | Estado real |
| --- | --- |
| 0 — Base de conocimiento | **En cierre técnico:** 90 fichas y 164 citas pendientes; extracción agotada sobre los cuatro PDFs locales (matrices de teoría, vocabulario —WEB 65 / ONT 71 filas, no idénticas; nombres de técnica extraídos salvo el doble `Jirugi`—, cuerpo y secciones). Decisiones humanas consolidadas en [docs/phase0-decisiones-pendientes.md](docs/phase0-decisiones-pendientes.md); con A1 se creó el primer currículo real `gup_10` (02-11-2026, solo teórico, `pending_human_review`) |
| 1 — Persistencia | **Base técnica funcionando:** PostgreSQL, Flyway, tablas de contenido e importación de borradores probada; no persistencia educativa completa |
| 2 — Backend | **En curso sin endpoints educativos:** ocho tipos con lectura interna (posición, teoría, vocabulario, herramientas, tuls con pasos, kick, combate y esquema de Gup) y [contrato OpenAPI](docs/openapi/taekwonpage-v1.json) verificado; contenido bloqueado por HTTP con `denyAll` intacto; la lectura de Gups ya tiene datos internos (`gup_10`, teoría) pero el HTTP sigue en 403 hasta C2 |
| 3 — Seguridad funcional | No iniciada; existe solo el bloqueo preventivo de rutas y salud mínima |
| 4 — Angular | No iniciada |
| 5 — Visualización biomecánica | No iniciada |
| 6 — Aprendizaje | Futuro, no iniciada |
| 7 — Producción | No iniciada; no hay web desplegada |

**Instrucción más reciente (29-10-2026):** el usuario declaró **cerrada la Fase 0** (extracción agotada; decisiones en [docs/phase0-decisiones-pendientes.md](docs/phase0-decisiones-pendientes.md)) y eligió avanzar con **Fase 2 sin endpoints educativos**: ampliar lecturas internas, refactorizar y documentar OpenAPI con rutas protegidas, sin tocar `denyAll`. No se marcarán completas decisiones humanas por avanzar en código; Fase 1 sigue abierta.

**Sí, adelantamos trabajo de Fases 1 y 2 sin terminar la Fase 0**, por la autorización de continuar con BD/backend. No se eliminaron sus pendientes ni se modificó la Definition of Done original. El avance técnico permite desarrollar con datos de prueba, pero no afirmar que el temario de la escuela está completo o aprobado.

## Fase 0 — Conocimiento: qué está y qué falta

Fuente: secciones 38–39 y checklist 55.4 del informe.

### Base técnica ya hecha

- [x] Inventario técnico inicial de cuatro PDFs con IDs, tamaño, hash y cobertura general (base TKD-001); no lectura completa ni validación de autoría de todas las copias.
- [x] Formato de procedencia con página PDF/folio diferenciados y vínculo a la copia exacta.
- [x] Contratos JSON iniciales para los nueve tipos previstos, catálogos y citas (base TKD-004).
- [x] Validadores de IDs, duplicados, citas y referencias por tipo (base TKD-018).
- [x] Controles de porcentajes, rotaciones y secuencias declaradas (base TKD-019).
- [x] Validación de referencias curriculares probada con fixtures sintéticos (base TKD-020).
- [x] Primeros borradores en los siete tipos de catálogo: posiciones, teoría, vocabulario, herramientas, ejercicios, patadas y combate.
- [x] Matriz documental de los seis temas teóricos observados para 10º a 9º, con siete fichas citadas y límites explícitos; añadidos desglose Tae/Kwon/Do y clasificación de instructores. No es programa escolar aprobado.

### Pendientes que impiden cerrar la fase

- [ ] **TKD-002 — Autoridad curricular:** **parcial (A1–A3, 01-11-2026)** — programa vigente = copias citadas (A1), revisor designado = el usuario (A3, falta nombre real para el registro); pendiente el criterio de desempate entre manuales (A2) y las filas B1–B5 del revisor. Registro en [docs/phase0-decisiones-pendientes.md](docs/phase0-decisiones-pendientes.md).
- [ ] **TKD-003 — Convenciones marciales:** romanización/alias, medidas, referencias geométricas, unidades y orientación. Los IDs técnicos ya están definidos; los ángulos del renderer no se pueden inventar.
- [ ] **TKD-004 — Contrastar contratos con el contenido completo:** los schemas actuales son iniciales, no modelos marciales definitivos.
- [ ] **TKD-005 — Completar posiciones iniciales:** cuatro fichas en revisión. **A5 resuelta (01-11-2026):** la escuela adopta `narani_junbi_sogi` con la geometría de PDF 81; siguen pendientes revisión humana y convenciones geométricas (TKD-003). `narani_junbi_sogi` documentado no hace equivalentes todas las variantes.
- [ ] **TKD-006 — Completar teoría inicial:** hay nueve fichas, incluidas las [secciones del cuerpo y la división lateral](knowledge/provenance/secciones-cuerpo-review.md), y una matriz de seis temas de los manuales; faltan revisión, profundidad requerida y adopción escolar. El bloque de puntos vitales (kupso) quedó observado sin extraer. No se considera todo el temario completo.
- [ ] **TKD-007 — Completar vocabulario inicial:** hay 44 entradas en revisión (cuatro iniciales, diecisiete de niveles/direcciones, [doce generales](knowledge/provenance/vocabulario-terminos-generales-review.md) y [once nombres de técnica](knowledge/provenance/vocabulario-nombres-tecnica-review.md)). La [matriz de cobertura](knowledge/provenance/vocabulario-tabla-completa-review.md) queda agotada salvo el doble uso de Jirugi, que depende del revisor.
- [ ] **TKD-008 — Completar herramientas:** hay 24 entradas en revisión (las 10 iniciales y las [14 partes del cuerpo](knowledge/provenance/vocabulario-cuerpo-review.md) de las tablas de vocabulario). `Dwichook` queda excluido pendiente de TKD-003 y se documenta que la tabla WEB omite seis filas de mano presentes en ONT.
- [ ] **TKD-009 — Construir y revisar 10º Gup:** **primer currículo real `gup_10` creado (02-11-2026)** en `knowledge/curricula/gups/`, solo teórico (los seis temas del temario WEB 27 / ONT 35 enlazando siete fichas) con dos citas propias, `pending_human_review`. Faltan requisitos técnicos cuando la escuela los confirme (A6 sin entregar), revisión humana y aprobación; no basta crear el JSON.
- [ ] **TKD-010 / TKD-011 — Estructurar 9º y 8º Gup:** siguen en el alcance de Fase 0, pero diferidos hasta demostrar una estructura reusable de 10º Gup. No se han cancelado.
- [ ] **TKD-012 — Completar Saju Jirugi:** siete acciones documentadas, no total global. La laguna del destino del golpe del punto 3 se intentó recuperar el 29-10-2026 con recortes ampliados (resultado negativo: tinta erosionada); requiere otra copia o revisor. Faltan alcance alterno y conteo completo con evidencia.
- [ ] **TKD-013 — Completar Saju Makgi:** ocho acciones documentadas, sin total global/alcance alterno confirmado. La preparación ya tiene enlace documental.
- [ ] **TKD-014 — Modelar Chon-Ji con evidencia:** no iniciado como ficha de catálogo; no deducir pasos de listas terminológicas.
- [ ] **TKD-015 — Confirmar catálogo de grados reconocido por la escuela.**
- [ ] **TKD-016 — Completar matriz funcional rol/grado:** separación y acceso acumulativo aprobados; falta su especificación completa. No confundirlo con implementar RBAC de Fase 3; hoy los cuatro roles existen en V7 pero ninguna ruta aplica permisos por rol.
- [ ] **TKD-017 — Cerrar modelo de verificación:** distinguir estados del alumno de estados de solicitud y sus transiciones. La identidad local base ya está implementada (login/`me`), pero **el alta de usuarios y el flujo de verificación siguen sin implementar** y dependen de este modelo.
- [ ] **TKD-018/019/020 — Validar el caso curricular real:** aplicar los controles existentes a contenido y currículos completos, no solo a fixtures/borradores.
- [ ] Completar/revisar patadas y combate: tres fichas de cada tipo. Resolver ambigüedad de `cha_jirugi`, diferencias entre copias y variante de combate aplicable; no adoptar automáticamente el «sin contacto» del JSON antiguo.
- [ ] Registrar revisión humana y derechos para el uso previsto. Actualmente **cero fichas tienen aprobación humana registrada**.

**Criterio de cierre conservado:** 10º/9º/8º Gup estructurados, catálogos requeridos disponibles, ejercicios/Tul y posiciones modelados, validadores funcionando sobre datos reales, sin referencias curriculares rotas y contenido aprobado con fuente identificable. Hoy no se cumple. `validate:content` **pasa desde el 02-11-2026** con el primer currículo real (`gup_10`); control de presencia/consistencia, no de aprobación ni completitud marcial.

## Fase 1 — Persistencia: cómo vamos

Fuente: sección 40 del informe; detalle y límites en [manual de BD](docs/database/README.md).

### Implementado y probado

- [x] ERD inicial del contenido, fuentes, citas, ejercicios y relaciones curriculares.
- [x] PostgreSQL 17.7 local mediante Docker Compose, acceso solo por localhost y volumen persistente.
- [x] Migraciones Flyway V1–V7 e historial/checksums: contenido, texto, requisitos, subtipos y citas documentales versionados, más identidad local (V7); aplicadas localmente sin cargar contenido.
- [x] Tablas de contenido/procedencia, posiciones, teoría, vocabulario, herramientas, patadas, combate, ejercicios/pasos y relaciones por Gup.
- [x] FKs tipadas, IDs, hashes, restricciones de peso/rotación y controles de secuencia/páginas; índices iniciales.
- [x] Exportador JSON → SQL de **borradores locales**, validado, transaccional y con consentimiento explícito `--local-drafts`.
- [x] Importación de las 33 fichas/55 citas actuales en una BD desechable de prueba; no carga educativa aprobada.
- [x] Mapeo de currículos de trabajo: siete categorías de requisitos y sus citas, probado con fixtures sintéticos (no programa escolar).
- [x] Recarga idéntica segura, sin duplicados; diferencias en filas o relaciones causan rollback. Cinco conflictos de importación probados en PostgreSQL.
- [x] Edición explícita de nombre/descripción de catálogo con versión esperada, motivo, referencia local no verificada e historial con snapshot de citas; sin cambiar estado de aprobación.
- [x] Edición explícita de las siete categorías curriculares con versión esperada, baseline observado, historial/citas y rollback. Probada solo con currículos sintéticos, incluidos 30 rechazos SQL y upgrade V2 → V3 con datos.
- [x] Edición de pesos/rotaciones y traducción/alias con revisión global, historial/citas y nulos preservados. Upgrade con datos, cadenas mixtas y 36 rechazos SQL probados con fixtures.
- [x] Edición de conteo/preparación/alcance/pasos de ejercicios/Tuls, con citas propias e historial. Secuencias sintéticas parciales/completas y 39 rechazos SQL probados; no se completaron ejercicios reales.
- [x] Edición versionada de citas: fuente/hash/localizador/notas, reservas de IDs por propietario y conservación de enlaces de pasos. Swap, rollback y 37 rechazos SQL probados con fixtures.
- [x] Prueba real: migrar desde cero, repetir sin cambios, validar Flyway y ejecutar 16 casos negativos SQL; preservación de UTF-8 comprobada.

### Falta para cerrar persistencia

- [x] Importar un **currículo real** con sus requisitos tipados y citas: `gup_10` importado y verificado (siete teorías y dos citas) en la BD de desarrollo y en una base dedicada del harness con recarga idéntica y baseline V3. Es teórico y `pending_human_review`; el alcance completo (requisitos técnicos) sigue pendiente de la escuela.
- [ ] Preparar seed de contenido aprobado cuando exista aprobación; hoy solo hay borradores de prueba, no un seed educativo de producción.
- [ ] Definir/persistir evidencia de revisión y publicación; el esquema actual solo admite `pending_human_review`.
- [ ] Aplicar revisión humana explícita al contenido/evidencia antes de aprobarlo. El versionado técnico de datos y citas está implementado; no es aprobación ni autoriza cambios silenciosos.
- [ ] Validar el recorrido completo de 10º Gup aprobado → importación → consulta desde backend.
- [ ] Completar el modelo relacional de grados del alumno, solicitudes, historial y auditoría cuando se cierre su diseño funcional. **Usuarios y roles ya existen** (V7: `role`, `app_user`, `user_role`, cuatro roles y cero cuentas); faltan grado del alumno, solicitudes e historial.

**Resumen:** ya tenemos la infraestructura y el esquema inicial, no toda la BD de la aplicación terminada. La BD local de desarrollo tiene el esquema **y los borradores importados, incluido el currículo real `gup_10`** (pendiente de revisión humana); las demás importaciones verificadas se hicieron en bases aisladas que se eliminan al terminar. Docker local no es hosting de la web final.

## Fase 2 — Backend

- [x] Spring Boot 3.5.16 / Java 21 / Maven ejecutable.
- [x] Flyway al arranque y Hibernate en modo validación, sin recrear tablas.
- [x] Primer módulo de contenido: entidades, repositorios de lectura, servicio, mapeo a DTO y controlador de posiciones.
- [x] Procedencia de posiciones con fuente/hash, metadatos, página PDF/folio y estados; sin rutas locales/PDFs en el DTO.
- [x] Pruebas unitarias y con PostgreSQL aislado: **54 pruebas Java correctas** tras auditoría (11 JWT, 3 AuthService, 7 nuevas de integración; 33 originales). Incluye servidor HTTP real: errores 400 conservados mediante despacho interno ERROR, sin abrir `/error` directamente.
- [x] Salud mínima y bloqueo HTTP preventivo de contenido; JAR probado contra Compose.
- [x] Lectura interna (entidad, repositorio, servicio, DTO, controlador) de **cinco tipos**: posiciones, teoría, vocabulario, herramientas corporales y tuls/ejercicios (pasos con sus citas); regla única de IDs canónicos (`CanonicalIds`).
- [x] Contrato [OpenAPI 3.1](docs/openapi/taekwonpage-v1.json): ocho rutas de lectura con 200/400/403/404 sin `security`, más login (200/400/401) y `/me` (200/401) con `bearerAuth`, sin hosts públicos, verificado por tests Node contra los controladores Java, los esquemas de identidad y `denyAll`.
- [x] Ampliar lectura a kick y combate (`/api/v1/kicks/{id}`, `/api/v1/combat-types/{id}`), sin seleccionar ni aprobar modalidad alguna; contrato OpenAPI ampliado a siete rutas.
- [x] Lectura interna `GET /api/v1/gups/{gup}` del esquema curricular (siete grupos de requisitos, rango 1–10,400/404/403, contrato con `GupNumber`): con el currículo real `gup_10` la ruta tiene datos internos (teoría y citas); ningún grupo se rellena desde otra ficha ni desde los JSON antiguos.
- [ ] Temario real de 10º Gup **parcial:** `GET /api/v1/gups/10` ya tiene el currículo teórico; faltan requisitos técnicos confirmados por la escuela (A6) y la apertura HTTP (C2) para verlo desde fuera.
- [ ] Completar el flujo funcional sin exponer borradores ni saltarse la autorización de Fase 3.

## Fase 3 — Seguridad, identidad y acceso

- [x] Elegir JWT local u OIDC y documentar la estrategia: **C1 resuelta (01-11-2026)** — JWT local autoemitido (clave en `.env`, usuarios/roles en PostgreSQL); **implementada en el bloque del 02-11-2026 (informe 1.32)**.
- [x] Login local con BCrypt y hash ficticio verificado incluso para cuentas ausentes/deshabilitadas (no garantía de tiempo constante); límites de username/contraseña y JWT estricto con regresiones. Token HS256 de 1800 s; `/me` refleja id/username/roles del token. Sin registro, refresh ni usuarios sembrados; alta depende de TKD-016/TKD-017.
- [ ] Registro/alta de alumnos con `ROLE_STUDENT`, 10º Gup y `UNVERIFIED` (pendiente del modelo de grado/verificación).
- [ ] RBAC y acceso acumulativo por grado **en backend**, también al acceder directamente a contenido. Hoy el token identifica pero **no autoriza**: `denyAll` sigue respondiendo 403 en contenido.
- [ ] Solicitudes de verificación, bandeja administrativa, aprobación/rechazo e historial.
- [ ] Evitar autoaprobación y solicitudes pendientes simultáneas; auditoría transaccional.
- [ ] Completar privacidad, validación y pruebas negativas de seguridad antes de una beta.

El `denyAll()` actual es una barrera preventiva, **no** autenticación, RBAC o verificación implementados; la identidad local (C1) ya autentica pero no cambia esa barrera. La apertura de rutas de contenido depende de la decisión **C2**, todavía no tomada.

## Fase 4 — Angular / web

- [ ] Inicializar Angular/TypeScript y estructura modular/standalone.
- [ ] Incorporar logo real y verificar branding/paleta.
- [ ] Sitio público: inicio, escuela y contacto.
- [ ] Layouts/rutas de alumno y administración.
- [ ] Login/registro e integración con la API y estrategia de identidad.
- [ ] Dashboard, perfil, grado y solicitud de verificación.
- [ ] Temario y consultas educativas autorizadas.
- [ ] Dashboard administrativo, alumnos y bandeja de solicitudes.
- [ ] Guards, manejo de errores y pruebas de componentes/servicios/rutas.

## Fase 5 — Visualización biomecánica

- [ ] Convenciones geométricas y datos fuente revisados (dependencia de Fase 0).
- [ ] Renderer 2D Canvas/SVG: pies, coordenadas, rotación, peso, referencias y leyenda.
- [ ] Pruebas de representación, sin rellenar datos desconocidos.

## Fase 6 — Aprendizaje (futuro)

- [ ] Quizzes, preguntas por grado y resultados.
- [ ] Progreso, estadísticas y repaso.

No es un prerrequisito para la primera web del milestone v0.3.

## Fase 7 — Producción

- [ ] Elegir hosting frontend/backend/BD compatible con el objetivo US$0 y revisar límites vigentes; sin depender del PC personal.
- [ ] Empaquetado/configuración de despliegue y CI/CD por push con pruebas.
- [ ] URL pública/dominio cuando corresponda, HTTPS, secretos y CORS explícito.
- [ ] PostgreSQL alojado, migraciones, backups/restauración y estrategia de rollback.
- [ ] Salud, logs/monitoreo y documentación operativa del entorno alojado.
- [ ] Revisión de seguridad, privacidad y derechos del contenido antes de exponer una beta.

Un volumen persistente local y `/actuator/health` local no completan estos puntos de producción. No hay tags, release ni despliegue público.

## Milestones: no confundirlos con las fases

- [ ] **Content Foundation v0.1:** PDF → catálogo → currículo validado → PostgreSQL → API; primer caso completo 10º Gup. Aún no se demuestra el flujo completo.
- [ ] **Identity & Grade Access v0.2:** registro/login, grado inicial, solicitud, aprobación administrativa, acceso actualizado e historial. **Parcial:** login local (`POST /api/v1/auth/login`) implementado el 02-11-2026; falta registro, grado, solicitud e historial.
- [ ] **Web v0.3:** web pública, alumno y administración con branding e integración funcional.

## Orden para retomar sin arrastrar pendientes invisibles

El bloque activo es **Fase 3: identidad local (C1)** — implementada en el bloque del 02-11-2026 sin abrir contenido; Fase 1 queda abierta por sus dependencias humanas y Fase 0 por decisiones de la escuela. Las respuestas A1–A7 están registradas. La lista siguiente expresa dependencias, no autorización para saltar directamente a la apertura de rutas ni dar por terminada la persistencia funcional.

1. **Hecho (parcial):** registrar autoridad, revisor y programa técnico de 10º Gup con la escuela — A1–A7 registrados el 01-11-2026; siguen abiertos el nombre real del aprobador (A3), el criterio de desempate (A2), los números de Saju (A6), la descripción del contacto pactado (A7) y las filas B1–B5 del revisor. No puede resolverlo un test ni la IA.
2. Con respuestas desbloqueadas: completar el currículo de 10º Gup sin inventar requisitos (ya existe la base teórica `gup_10`; faltan requisitos técnicos y revisión humana).
3. Completar revisión/publicación y su consulta en backend; 9º/8º siguen después de demostrar 10º, como dispone el plan.
4. Backend de lectura completo para los ocho tipos (`GET /api/v1/gups/10` ya tiene datos internos). `denyAll` intacto; la identidad local ya está implementada (C1), falta decidir **C2** (apertura de contenido), el alta de usuarios (TKD-016/TKD-017) y el RBAC por grado antes de exponer rutas.
5. Integrar Angular cuando existan los contratos y acceso necesarios; preparar hosting al llegar a producción, no convertir el PC en servidor público.

### Mantenimiento de este checklist

Al cerrar cada bloque, actualizar **este archivo y las secciones 55–58 del informe** con entregable, evidencia, validaciones y pendientes. Si difieren, revisar la implementación y corregir ambos; no marcar un `[x]` solo porque se creó una carpeta, un DTO o una prueba sintética.
