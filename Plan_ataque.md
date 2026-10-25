# Plan de ataque — TaeKwonPage

**Actualizado: 25-10-2026.** Vista de seguimiento del [informe técnico](informe_tecnico.md), no un plan nuevo que reemplace su arquitectura o alcance. Para continuar desde otro chat: **[prompt de continuación](docs/handoff/continuation-prompt.md)**, siempre contrastado contra el informe.

- `[x]` = el entregable descrito está implementado/verificado.
- `[ ]` = pendiente o parcial; el texto indica cuál de los dos.
- Tener tests correctos no significa aprobación marcial ni fase terminada. No usamos porcentajes porque las tareas tienen esfuerzos distintos.
- **Sprint 0 (repositorio) no es Fase 0 (conocimiento).** Un milestone puede abarcar varias fases.

## Dónde estamos

| Fase original | Estado real |
| --- | --- |
| 0 — Base de conocimiento | **Retomada, no cerrada:** 33 fichas y 55 citas pendientes; matriz de seis temas teóricos, sin currículo escolar confirmado |
| 1 — Persistencia | **Base técnica funcionando:** PostgreSQL, Flyway, tablas de contenido e importación de borradores probada; no persistencia educativa completa |
| 2 — Backend | **Iniciada:** Spring Boot y lectura interna de posiciones con procedencia; contenido bloqueado por HTTP |
| 3 — Seguridad funcional | No iniciada; existe solo el bloqueo preventivo de rutas y salud mínima |
| 4 — Angular | No iniciada |
| 5 — Visualización biomecánica | No iniciada |
| 6 — Aprendizaje | Futuro, no iniciada |
| 7 — Producción | No iniciada; no hay web desplegada |

**Instrucción más reciente:** el usuario confirmó retomar Fase 0 porque no hay programa/revisor confirmados, manteniendo Fase 1 explícitamente abierta. Se deja en pausa la ampliación de Fase 2. No se marcarán completas decisiones humanas por avanzar en código.

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

- [ ] **TKD-002 — Autoridad curricular:** confirmar programa vigente de Nahuel Aukan, cómo resolver discrepancias y quién revisa/aprueba. Requiere decisión de la escuela: [preguntas y registro](knowledge/provenance/curricular-authority.md).
- [ ] **TKD-003 — Convenciones marciales:** romanización/alias, medidas, referencias geométricas, unidades y orientación. Los IDs técnicos ya están definidos; los ángulos del renderer no se pueden inventar.
- [ ] **TKD-004 — Contrastar contratos con el contenido completo:** los schemas actuales son iniciales, no modelos marciales definitivos.
- [ ] **TKD-005 — Completar posiciones iniciales:** cuatro fichas en revisión. Resolver adopción escolar del Junbi y geometría pendiente; `narani_junbi_sogi` documentado no hace equivalentes todas las variantes.
- [ ] **TKD-006 — Completar teoría inicial:** hay siete fichas y una matriz de seis temas de los manuales; faltan revisión, profundidad requerida y adopción escolar. No se considera todo el temario completo.
- [ ] **TKD-007 — Completar vocabulario inicial:** hay cuatro entradas, no el catálogo completo.
- [ ] **TKD-008 — Completar herramientas:** diez fichas de trabajo, no un catálogo aprobado/completo.
- [ ] **TKD-009 — Construir y revisar 10º Gup:** cero currículos en `knowledge/curricula/gups/`. El temario observado solo enumera teoría; faltan requisitos técnicos confirmados, no solo crear un JSON.
- [ ] **TKD-010 / TKD-011 — Estructurar 9º y 8º Gup:** siguen en el alcance de Fase 0, pero diferidos hasta demostrar una estructura reusable de 10º Gup. No se han cancelado.
- [ ] **TKD-012 — Completar Saju Jirugi:** siete acciones documentadas, no total global. Resolver laguna del destino del golpe del punto 3, alcance alterno y conteo completo con evidencia.
- [ ] **TKD-013 — Completar Saju Makgi:** ocho acciones documentadas, sin total global/alcance alterno confirmado. La preparación ya tiene enlace documental.
- [ ] **TKD-014 — Modelar Chon-Ji con evidencia:** no iniciado como ficha de catálogo; no deducir pasos de listas terminológicas.
- [ ] **TKD-015 — Confirmar catálogo de grados reconocido por la escuela.**
- [ ] **TKD-016 — Completar matriz funcional rol/grado:** separación y acceso acumulativo aprobados; falta su especificación completa. No confundirlo con implementar RBAC de Fase 3.
- [ ] **TKD-017 — Cerrar modelo de verificación:** distinguir estados del alumno de estados de solicitud y sus transiciones antes de implementar identidad.
- [ ] **TKD-018/019/020 — Validar el caso curricular real:** aplicar los controles existentes a contenido y currículos completos, no solo a fixtures/borradores.
- [ ] Completar/revisar patadas y combate: tres fichas de cada tipo. Resolver ambigüedad de `cha_jirugi`, diferencias entre copias y variante de combate aplicable; no adoptar automáticamente el «sin contacto» del JSON antiguo.
- [ ] Registrar revisión humana y derechos para el uso previsto. Actualmente **cero fichas tienen aprobación humana registrada**.

**Criterio de cierre conservado:** 10º/9º/8º Gup estructurados, catálogos requeridos disponibles, ejercicios/Tul y posiciones modelados, validadores funcionando sobre datos reales, sin referencias curriculares rotas y contenido aprobado con fuente identificable. Hoy no se cumple. `validate:content` continúa fallando por ausencia de currículo, de forma esperada.

## Fase 1 — Persistencia: cómo vamos

Fuente: sección 40 del informe; detalle y límites en [manual de BD](docs/database/README.md).

### Implementado y probado

- [x] ERD inicial del contenido, fuentes, citas, ejercicios y relaciones curriculares.
- [x] PostgreSQL 17.7 local mediante Docker Compose, acceso solo por localhost y volumen persistente.
- [x] Migraciones Flyway V1–V6 e historial/checksums: contenido, texto, requisitos, subtipos y citas documentales versionados; aplicadas localmente sin cargar contenido.
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

- [ ] Importar un **currículo real** con sus requisitos tipados y citas. El mapeo existe; falta el documento confirmado/revisado y su contraste real.
- [ ] Preparar seed de contenido aprobado cuando exista aprobación; hoy solo hay borradores de prueba, no un seed educativo de producción.
- [ ] Definir/persistir evidencia de revisión y publicación; el esquema actual solo admite `pending_human_review`.
- [ ] Aplicar revisión humana explícita al contenido/evidencia antes de aprobarlo. El versionado técnico de datos y citas está implementado; no es aprobación ni autoriza cambios silenciosos.
- [ ] Validar el recorrido completo de 10º Gup aprobado → importación → consulta desde backend.
- [ ] Completar el modelo relacional de usuarios, roles, grados del alumno, solicitudes, historial y auditoría cuando se cierre su diseño funcional. Esas tablas del modelo preliminar aún no existen; no son parte del primer bloque de contenido.

**Resumen:** ya tenemos la infraestructura y el esquema inicial, no toda la BD de la aplicación terminada. La BD local de desarrollo tiene el esquema, **sin contenido cargado**; las importaciones verificadas se hicieron en bases aisladas que se eliminan al terminar. Docker local no es hosting de la web final.

## Fase 2 — Backend

- [x] Spring Boot 3.5.16 / Java 21 / Maven ejecutable.
- [x] Flyway al arranque y Hibernate en modo validación, sin recrear tablas.
- [x] Primer módulo de contenido: entidades, repositorios de lectura, servicio, mapeo a DTO y controlador de posiciones.
- [x] Procedencia de posiciones con fuente/hash, metadatos, página PDF/folio y estados; sin rutas locales/PDFs en el DTO.
- [x] Pruebas unitarias y con PostgreSQL aislado: **17 pruebas Java correctas** en el último bloque técnico.
- [x] Salud mínima y bloqueo HTTP preventivo de contenido; JAR probado contra Compose.
- [ ] Ampliar entidades/repositorios/servicios/DTOs/controladores al resto de contenido y currículo.
- [ ] Implementar `GET /api/v1/gups/10` con un temario real completo; hoy no existe ese controlador.
- [ ] Definir y validar contrato OpenAPI/Swagger, errores y pruebas del resto de la API.
- [ ] Completar el flujo funcional sin exponer borradores ni saltarse la autorización de Fase 3.

## Fase 3 — Seguridad, identidad y acceso

- [ ] Elegir JWT local u OIDC y documentar la estrategia.
- [ ] Registro/login/ciclo de sesión y tratamiento de credenciales según la elección.
- [ ] Alta de alumnos con `ROLE_STUDENT`, 10º Gup y `UNVERIFIED`.
- [ ] RBAC y acceso acumulativo por grado **en backend**, también al acceder directamente a contenido.
- [ ] Solicitudes de verificación, bandeja administrativa, aprobación/rechazo e historial.
- [ ] Evitar autoaprobación y solicitudes pendientes simultáneas; auditoría transaccional.
- [ ] Completar privacidad, validación y pruebas negativas de seguridad antes de una beta.

El `denyAll()` actual es una barrera preventiva, **no** autenticación, RBAC o verificación implementados.

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
- [ ] **Identity & Grade Access v0.2:** registro/login, grado inicial, solicitud, aprobación administrativa, acceso actualizado e historial.
- [ ] **Web v0.3:** web pública, alumno y administración con branding e integración funcional.

## Orden para retomar sin arrastrar pendientes invisibles

El bloque activo es **Fase 0**, por confirmación posterior del usuario; Fase 1 queda abierta por sus dependencias humanas. La lista siguiente expresa dependencias, no autorización para saltar directamente al backend ni dar por terminada la persistencia funcional.

1. Confirmar con la escuela autoridad, revisor y programa técnico de 10º Gup; no puede resolverlo un test ni la IA.
2. Continuar extracción/revisión de Fase 0 y sus lagunas, cerrar convenciones y construir el currículo de 10º Gup sin inventar requisitos.
3. Completar importación curricular/revisión/publicación y su consulta en backend; 9º/8º siguen después de demostrar 10º, como dispone el plan.
4. Desarrollar infraestructura/lecturas con fixtures en paralelo si se autoriza, sin marcar Fases 0/1 completas. Elegir identidad antes de implementarla o abrir rutas.
5. Integrar Angular cuando existan los contratos y acceso necesarios; preparar hosting al llegar a producción, no convertir el PC en servidor público.

### Mantenimiento de este checklist

Al cerrar cada bloque, actualizar **este archivo y las secciones 55–58 del informe** con entregable, evidencia, validaciones y pendientes. Si difieren, revisar la implementación y corregir ambos; no marcar un `[x]` solo porque se creó una carpeta, un DTO o una prueba sintética.
