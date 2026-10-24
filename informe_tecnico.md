# Informe Tecnico - TaeKwonPage

**Organizacion:** ZVK Tech  
**Proyecto:** TaeKwonPage  
**Escuela:** Taekwon-Do Nahuel Aukan  
**Estado:** En desarrollo — Sprint 1 / Knowledge Foundation en curso  
**Version del documento:** 1.18  
**Fecha de creacion:** 14-10-2026  
**Ultima actualizacion:** 24-10-2026  

Esta revision actualiza el seguimiento, no las decisiones de arquitectura aprobadas. Las fases, los sprints y las versiones del producto son conceptos distintos: completar el bootstrap no completa la Fase 0 ni publica v0.1.

---

## 1. Resumen ejecutivo

TaeKwonPage es una plataforma web educativa y de gestion interna para la escuela **Taekwon-Do Nahuel Aukan**, desarrollada bajo la organizacion **ZVK Tech**.

El objetivo principal es centralizar, estructurar y enseñar el conocimiento teorico y tecnico de Taekwon-Do ITF, utilizando como fuentes documentales los PDFs disponibles para el proyecto y convirtiendo su informacion en catalogos de conocimiento estructurado.

La plataforma tendra dos areas principales:

1. **Area educativa para alumnos**
   - Acceso al contenido correspondiente a su grado.
   - Visualizacion progresiva del temario.
   - Consulta de teoria, posiciones, Tuls, vocabulario, herramientas de ataque/defensa, patadas y combate.
   - Futuro modulo de quizzes y seguimiento del aprendizaje.

2. **Area de administracion de la escuela**
   - Validacion del grado declarado por cada alumno.
   - Bandeja de solicitudes de verificacion.
   - Gestion de alumnos.
   - Gestion y publicacion de contenido.
   - Historial de cambios y auditoria.

El sistema se desarrollara inicialmente para **una sola escuela**, evitando complejidad innecesaria de multitenancy o administracion de multiples academias.

---

# 2. Decisiones de arquitectura aprobadas

| Decision | Valor aprobado |
|---|---|
| Marca / organizacion | ZVK Tech |
| Producto | TaeKwonPage |
| Escuela objetivo | Taekwon-Do Nahuel Aukan |
| Alcance inicial | Una sola escuela |
| Presupuesto de infraestructura | Prioridad US$0 |
| Frontend | Angular + TypeScript |
| Backend | Java 21 + Spring Boot |
| Persistencia | PostgreSQL |
| ORM | Spring Data JPA / Hibernate |
| Migraciones | Flyway |
| Seguridad | Spring Security + JWT/OIDC |
| Arquitectura inicial | Monolito modular orientado a evolucionar |
| Desarrollo local | Docker Compose |
| API | REST versionada |
| Documentacion API | OpenAPI / Swagger |
| Fuentes documentales | PDFs disponibles en el proyecto |
| Identidad visual | Basada en el logo de Taekwon-Do Nahuel Aukan |

---

# 3. Alcance funcional

## 3.1 Incluido en la primera etapa

- Sitio institucional de la escuela.
- Registro e inicio de sesion.
- Perfil de alumno.
- Grado actual del alumno.
- Solicitud de verificacion de grado.
- Bandeja administrativa para validar solicitudes.
- Contenido desbloqueado segun grado.
- Catalogos tecnicos de Taekwon-Do.
- Temario por Gup.
- Visualizador de Tuls.
- Teoria.
- Posiciones.
- Vocabulario.
- Herramientas de impacto.
- Patadas.
- Combate pactado.
- Panel administrativo.
- Gestion basica de contenido.
- Historial de cambios relevantes.
- API REST.

## 3.2 Fuera del alcance inicial

- Multiescuela.
- Facturacion.
- Pagos.
- Reservas.
- Comercio electronico.
- Integraciones con federaciones externas.
- Aplicacion movil nativa.
- Microservicios distribuidos independientes.
- Kubernetes.
- Alta disponibilidad multi-region.

Estos elementos pueden evaluarse en fases posteriores si el proyecto crece.

---

# 4. Modelo conceptual del sistema

```text
+------------------------------------------------------+
|                  FRONTEND ANGULAR                    |
|                                                      |
|  Web publica | Alumno | Admin | Developer            |
+--------------------------+---------------------------+
                           |
                         HTTPS
                           |
                           v
+------------------------------------------------------+
|                 SPRING BOOT BACKEND                  |
|                                                      |
| Auth | Usuarios | Grados | Contenido | Curriculum    |
| Solicitudes | Auditoria | Administracion             |
+--------------------------+---------------------------+
                           |
                    JPA / Hibernate
                           |
                           v
+------------------------------------------------------+
|                    POSTGRESQL                        |
|                                                      |
| Usuarios | Roles | Gups | Catalogos | Solicitudes    |
| Tuls | Pasos | Fuentes | Historial | Auditoria       |
+------------------------------------------------------+
```

---

# 5. Principio de arquitectura: monolito modular primero

Aunque TaeKwonPage puede evolucionar hacia microservicios, la primera version se implementara como un **monolito modular**.

Esto permite:

- reducir complejidad;
- evitar multiples despliegues;
- reducir consumo de recursos;
- facilitar debugging;
- trabajar con infraestructura gratuita;
- compartir una base transaccional;
- acelerar el desarrollo inicial;
- mantener limites de dominio claros.

Modulos internos propuestos:

```text
backend/
└── taekwonpage-api/
    └── src/main/java/.../
        ├── auth/
        ├── users/
        ├── grades/
        ├── curriculum/
        ├── content/
        ├── tuls/
        ├── biomechanics/
        ├── verification/
        ├── admin/
        ├── audit/
        └── shared/
```

En el futuro, los modulos que realmente lo necesiten podran separarse como servicios independientes.

---

# 6. Roles del sistema

El rol define **que puede hacer el usuario**.

El grado define **que contenido marcial puede estudiar**.

No se deben mezclar ambos conceptos.

## 6.1 ROLE_GUEST

Usuario sin autenticar.

Permisos:

- ver pagina publica;
- informacion de la escuela;
- historia general;
- contacto;
- ubicacion;
- contenido publico seleccionado.

## 6.2 ROLE_STUDENT

Alumno registrado.

Permisos:

- acceder al dashboard;
- consultar su grado;
- estudiar temario autorizado;
- enviar solicitud de verificacion;
- consultar historial de grados;
- realizar quizzes en fases futuras.

## 6.3 ROLE_ADMIN

Representa al Busabonim responsable de la escuela.

Permisos:

- ver alumnos;
- revisar solicitudes de grado;
- aprobar solicitudes;
- rechazar solicitudes;
- asignar grado directamente;
- consultar historial;
- gestionar contenido;
- publicar contenido;
- consultar auditoria funcional.

## 6.4 ROLE_DEVELOPER

Rol tecnico de ZVK Tech.

Responsabilidades:

- mantenimiento;
- configuracion;
- diagnostico;
- migraciones;
- integraciones;
- soporte;
- observabilidad;
- administracion tecnica.

Este rol no debe implicar acceso innecesario a informacion personal de alumnos.

---

# 7. Politica de grados y contenido

## 7.1 Grado inicial

Toda cuenta nueva de alumno comienza con:

```text
ROLE_STUDENT
verified_gup = 10
verification_status = UNVERIFIED
```

El usuario puede acceder inicialmente al contenido de **10º Gup**.

Esto evita que una persona recien registrada pueda seleccionar libremente un grado avanzado y obtener acceso inmediato.

---

## 7.2 Solicitud de grado

Si un alumno pertenece realmente a un grado superior:

1. inicia sesion;
2. abre su perfil;
3. selecciona el grado que declara poseer;
4. envia una solicitud;
5. la solicitud entra en la bandeja del Admin;
6. el Busabonim revisa al alumno;
7. aprueba o rechaza;
8. el sistema actualiza el grado verificado;
9. se registra la accion en historial y auditoria.

---

## 7.3 Acceso acumulativo

Un alumno puede consultar:

- su grado actual;
- todos los grados anteriores que ya deberia dominar.

Ejemplo:

```text
Alumno verificado: 4º Gup

Permitido:
10º Gup
9º Gup
8º Gup
7º Gup
6º Gup
5º Gup
4º Gup

Bloqueado:
3º Gup
2º Gup
1º Gup
I Dan
...
```

Como los Gups avanzan reduciendo el numero:

```text
contenido.gup >= alumno.verified_gup
```

para Gups numericos.

La regla final debe encapsularse en backend y no depender solamente de Angular.

---

# 8. Estados de una solicitud de verificacion

```text
PENDING
APPROVED
REJECTED
CANCELLED
```

Campos recomendados:

```text
id
student_id
requested_gup
status
requested_at
reviewed_at
reviewed_by
review_note
```

Reglas:

- un alumno no puede aprobar su propia solicitud;
- un alumno no debe tener dos solicitudes pendientes simultaneamente;
- una aprobacion debe generar una entrada de historial;
- cualquier cambio administrativo debe ser auditable.

---

# 9. Modelo de conocimiento

TaeKwonPage separa estrictamente:

## 9.1 Capa de contenido

Describe **que es cada elemento**.

Ejemplos:

- posicion;
- Tul;
- tecnica;
- teoria;
- vocabulario;
- herramienta;
- patada;
- combate.

## 9.2 Capa curricular

Describe **que debe saber cada grado**.

Ejemplos:

```text
10gup
9gup
8gup
...
```

Los requisitos deben referenciar elementos de los catalogos mediante IDs estables.

---

# 10. Convencion de IDs

Todos los IDs canonicos deben ser:

- minusculas;
- snake_case;
- sin tildes;
- sin ñ;
- sin espacios;
- sin simbolos innecesarios;
- semanticamente estables;
- inmutables una vez publicados.

Ejemplos:

```text
charyot_sogi
junbi_sogi
gunnun_sogi
niunja_sogi
saju_jirugi
saju_makgi
chon_ji
boo_sabum_nim
```

---

# 11. Fuentes documentales disponibles

Actualmente el proyecto cuenta con:

```text
Terminología de las formas.pdf
TEORIA COMPLETA WEB.pdf
Teoria ONT(2)(1).pdf
291264914-Enciclopedia-Taekwondo.pdf
```

Estos documentos seran tratados como **fuentes**, no como datos finales.

No se debe copiar contenido directamente a produccion sin:

1. identificar la fuente;
2. identificar pagina o seccion;
3. estructurar el dato;
4. contrastarlo;
5. validar consistencia;
6. aprobarlo;
7. publicarlo.

---

# 12. Procedencia documental

Cada dato relevante deberia poder rastrearse hasta una fuente.

Entidad conceptual:

```text
source_document
---------------
id
title
organization
author
edition
language
file_reference
notes
```

Cuando corresponda:

```text
content_source
--------------
content_id
source_id
page
section
notes
```

Esto permitira responder preguntas como:

> ¿De donde salio esta definicion?

o:

> ¿En que pagina del material utilizado esta indicada esta posicion?

---

# 13. Pipeline de ingestion de contenido

```text
PDF
 |
 v
EXTRACCION
 |
 v
NORMALIZACION
 |
 v
JSON DE TRABAJO
 |
 v
VALIDACION
 |
 v
REVISION HUMANA
 |
 v
CATALOGO CANONICO
 |
 v
SEED / MIGRACION
 |
 v
POSTGRESQL
```

La IA puede asistir en la extraccion y normalizacion, pero la aprobacion final debe ser humana.

---

# 14. Estructura propuesta del repositorio

```text
TaeKwonPage/
├── README.md
├── informe_tecnico.md
├── LICENSE
├── .gitignore
├── .editorconfig
│
├── docs/
│   ├── architecture/
│   ├── adr/
│   ├── api/
│   ├── database/
│   ├── deployment/
│   └── security/
│
├── knowledge/
│   ├── schemas/
│   ├── sources/
│   ├── catalogs/
│   │   ├── posiciones/
│   │   ├── teoria/
│   │   ├── tuls/
│   │   ├── vocabulario/
│   │   ├── herramientas/
│   │   ├── patadas/
│   │   └── combate/
│   ├── curricula/
│   │   └── gups/
│   └── provenance/
│
├── backend/
│   └── taekwonpage-api/
│
├── frontend/
│   └── taekwonpage-web/
│
├── tools/
│   ├── ingestion/
│   ├── validators/
│   └── seeders/
│
├── infrastructure/
│   ├── docker/
│   ├── local/
│   ├── staging/
│   └── production/
│
└── docker-compose.yml
```

---

# 15. Catalogos iniciales

## Posiciones

```text
posiciones_basicas.json
```

Primer conjunto:

- Charyot Sogi
- Junbi Sogi
- Gunnun Sogi
- Niunja Sogi

## Teoria

```text
teoria_basica.json
```

Temas iniciales:

- definicion;
- historia;
- principios;
- normas;
- conceptos requeridos por grados iniciales.

## Tuls y ejercicios fundamentales

```text
saju_jirugi.json
saju_makgi.json
chon_ji.json
```

## Vocabulario

```text
vocabulario_basico.json
```

## Herramientas

```text
partes_cuerpo.json
```

## Patadas

```text
patadas_basicas.json
```

## Combate

```text
combate_pactado.json
```

---

# 16. Biomecanica

Las posiciones deben almacenar informacion numerica atomica.

Ejemplo conceptual:

```json
{
  "id": "gunnun_sogi",
  "front_foot": {
    "x": 0.0,
    "y": 1.0,
    "rotation_deg": 0
  },
  "rear_foot": {
    "x": 0.5,
    "y": 0.0,
    "rotation_deg": 25
  },
  "weight": {
    "front_percent": 50,
    "rear_percent": 50
  }
}
```

Los valores anteriores son solamente ilustrativos.

Los valores oficiales deben obtenerse y validarse a partir de las fuentes del proyecto.

Restricciones:

```text
front_percent + rear_percent = 100
rotation_deg >= 0
rotation_deg < 360
```

Para magnitudes que requieran precision controlada se recomienda `BigDecimal / NUMERIC`.

---

# 17. Modelo relacional preliminar

Tablas principales:

```text
app_user
role
user_role

gup
student_grade
grade_history
grade_verification_request

position
theory_content
vocabulary
body_tool
kick
combat_type

tul
tul_step

gup_position
gup_theory
gup_vocabulary
gup_tool
gup_kick
gup_tul
gup_combat

source_document
content_source

audit_event
```

---

# 18. API REST propuesta

Base:

```text
/api/v1
```

## Publico

```text
GET /api/v1/public/school
GET /api/v1/public/content
```

## Autenticacion

Dependiendo de la estrategia seleccionada:

```text
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/refresh
```

o autenticacion delegada mediante OIDC.

## Alumno

```text
GET  /api/v1/me
GET  /api/v1/me/grade
GET  /api/v1/me/curriculum
POST /api/v1/me/grade-verification-requests
GET  /api/v1/me/grade-verification-requests
```

## Contenido

```text
GET /api/v1/gups/{id}
GET /api/v1/tuls/{id}
GET /api/v1/positions/{id}
GET /api/v1/theory/{id}
GET /api/v1/vocabulary
GET /api/v1/kicks/{id}
```

## Admin

```text
GET   /api/v1/admin/students
GET   /api/v1/admin/grade-requests
GET   /api/v1/admin/grade-requests/{id}
PATCH /api/v1/admin/grade-requests/{id}/approve
PATCH /api/v1/admin/grade-requests/{id}/reject

PATCH /api/v1/admin/students/{id}/grade
```

---

# 19. Seguridad

## Principios

- HTTPS en produccion.
- Passwords nunca almacenadas en texto plano.
- Hash fuerte si la autenticacion se implementa localmente.
- JWT/OIDC.
- Autorizacion en backend.
- RBAC.
- Validacion de input.
- DTOs.
- No exponer entidades JPA directamente.
- Politicas CORS explicitas.
- Proteccion frente a XSS.
- Proteccion frente a SQL Injection mediante queries parametrizadas/JPA.
- Rate limiting cuando sea necesario.
- Secrets mediante variables de entorno.
- Ninguna credencial en Git.

---

# 20. Frontend Angular

## 20.1 Identidad visual

La interfaz tomara como referencia el logo oficial proporcionado de Taekwon-Do Nahuel Aukan.

Paleta inicial:

```css
--tkd-black: #0b0b0b;
--tkd-dark-green: #1b1f1a;
--tkd-olive: #6e7558;
--tkd-gold: #c9b27d;
--tkd-ivory: #e8e0cc;
--tkd-bronze: #a67c52;
```

Estos colores pueden ajustarse despues de probarlos visualmente junto al logo.

Caracter visual:

- oscuro;
- marcial;
- elegante;
- institucional;
- sobrio;
- moderno;
- inspirado en tonos del escudo.

---

# 21. Assets de branding

Ubicacion recomendada:

```text
frontend/taekwonpage-web/src/assets/branding/
```

Ejemplo:

```text
logo-nahuel-aukan.png
```

No incrustar imagenes directamente en componentes cuando puedan ser mantenidas como assets.

---

# 22. Arquitectura Angular

```text
src/app/
├── core/
│   ├── auth/
│   ├── guards/
│   ├── interceptors/
│   ├── services/
│   └── models/
│
├── shared/
│   ├── components/
│   ├── directives/
│   ├── pipes/
│   └── ui/
│
├── layouts/
│   ├── public-layout/
│   ├── student-layout/
│   └── admin-layout/
│
├── features/
│   ├── public/
│   ├── auth/
│   ├── dashboard/
│   ├── curriculum/
│   ├── tuls/
│   ├── positions/
│   ├── theory/
│   ├── vocabulary/
│   ├── profile/
│   ├── grade-verification/
│   └── admin/
│
├── app.routes.ts
└── app.config.ts
```

Se recomienda utilizar Angular standalone components salvo que exista una razon concreta para usar NgModules.

---

# 23. Rutas Angular iniciales

```text
/
 /about
 /contact

/login
/register

/student
/student/dashboard
/student/curriculum
/student/profile
/student/grade-request
/student/tuls/:id
/student/positions/:id

/admin
/admin/dashboard
/admin/students
/admin/grade-requests
/admin/content

/developer
```

---

# 24. Guards

```text
authGuard
studentGuard
adminGuard
developerGuard
gradeAccessGuard
```

Angular debe mejorar la experiencia de usuario, pero la autorizacion real siempre debe estar respaldada por el backend.

---

# 25. Vistas prioritarias

## Publicas

1. Home
2. Sobre la escuela
3. Contacto
4. Login
5. Registro

## Alumno

1. Dashboard
2. Mi grado
3. Mi temario
4. Solicitud de verificacion
5. Perfil
6. Tuls
7. Posiciones
8. Teoria

## Admin

1. Dashboard
2. Bandeja de solicitudes
3. Detalle de solicitud
4. Alumnos
5. Detalle de alumno
6. Gestion de contenido

---

# 26. Dashboard del alumno

Debe mostrar al menos:

```text
Hola, <nombre>

Grado verificado:
10º Gup

Estado:
No verificado / Verificado

Contenido disponible:
[10º Gup]

Solicitud:
[Solicitar verificacion]

Progreso:
futuro
```

---

# 27. Dashboard administrativo

Debe mostrar:

```text
Solicitudes pendientes
Alumnos registrados
Ultimas validaciones
Ultimos cambios
Alertas del sistema
```

La prioridad visual principal sera la bandeja de solicitudes.

---

# 28. Flujo de verificacion

```text
Alumno
  |
  | Solicitar grado
  v
PENDING
  |
  v
Admin / Busabonim
  |
  +------ APPROVE ------> Actualiza student_grade
  |                       Registra grade_history
  |                       Registra audit_event
  |
  +------ REJECT -------> Guarda motivo
                          Registra audit_event
```

---

# 29. Despliegue

El proyecto debe poder ejecutarse localmente con:

```text
Angular
Spring Boot
PostgreSQL
```

mediante Docker cuando corresponda.

---

# 30. Ambientes

```text
local
test
staging
production
```

Para la primera etapa pueden existir solamente:

```text
local
production/demo
```

pero el codigo debe mantenerse preparado para separar configuraciones.

---

# 31. Estrategia US$0

Objetivo:

```text
Frontend        -> hosting estatico gratuito
Backend         -> servicio gratuito mientras exista una opcion viable
PostgreSQL      -> tier gratuito
CI/CD           -> GitHub Actions
Repositorio     -> GitHub
DNS             -> opcional al inicio
```

Los servicios gratuitos pueden cambiar sus condiciones.

Por ello TaeKwonPage no debe depender tecnicamente de un proveedor concreto.

El despliegue debe ser portable mediante Docker y variables de entorno.

---

# 32. Docker Compose local

Objetivo final:

```bash
docker compose up -d
```

y disponer de:

```text
PostgreSQL
Backend
Frontend (opcional para dev)
```

Para desarrollo frontend se puede utilizar `ng serve` fuera de Docker.

---

# 33. Variables de entorno

Ejemplo:

```text
DB_HOST
DB_PORT
DB_NAME
DB_USERNAME
DB_PASSWORD

JWT_SECRET
JWT_ISSUER

CORS_ALLOWED_ORIGINS
SPRING_PROFILES_ACTIVE
```

Nunca subir valores reales de produccion al repositorio.

---

# 34. Calidad

Backend:

- JUnit 5
- Mockito
- Testcontainers
- integration tests
- repository tests
- controller tests

Frontend:

- unit tests
- component tests
- route guard tests
- service tests
- E2E en etapas posteriores

---

# 35. CI/CD

Pipeline GitHub Actions previsto (todavia no implementado), disparado por push a ramas de trabajo o `main`, sin Pull Requests o merges automaticos. Las integraciones de checkpoints se hacen con revision y pruebas, fuera del pipeline:

```text
push a rama de trabajo / main
        |
        +--> backend build
        |       |
        |       +--> tests
        |
        +--> frontend build
        |       |
        |       +--> tests
        |
        +--> validators
        |
        +--> artifact/build
```

No desplegar automaticamente a produccion mientras el pipeline no este estable.

---

# 36. Observabilidad

Backend:

- Spring Boot Actuator
- health endpoint
- logs estructurados
- metricas basicas

Futuro:

- Micrometer
- Prometheus
- Grafana
- alertas

Solo incorporar infraestructura adicional cuando exista una necesidad real.

---

# 37. Auditoria

Eventos recomendados:

```text
USER_REGISTERED
GRADE_REQUEST_CREATED
GRADE_REQUEST_APPROVED
GRADE_REQUEST_REJECTED
GRADE_CHANGED
ROLE_CHANGED
CONTENT_CREATED
CONTENT_UPDATED
CONTENT_PUBLISHED
LOGIN_FAILED
```

---

# 38. Backlog Fase 0

## Epic F0-A - Gobernanza documental

### TKD-001 - Inventariar fuentes

**Prioridad:** P0

Criterios:

- registrar los cuatro PDFs;
- crear un ID estable para cada fuente;
- registrar metadatos;
- identificar cobertura general.

---

### TKD-002 - Definir autoridad curricular

**Prioridad:** P0

Objetivo:

determinar como se resuelven discrepancias entre fuentes y programa real de la escuela.

La decision final sobre los requisitos de examen corresponde a la escuela.

---

### TKD-003 - Definir convenciones de datos

**Prioridad:** P0

Incluye:

- IDs;
- nombres;
- romanizacion;
- unidades;
- enums;
- orden;
- referencias.

---

### TKD-004 - Crear JSON Schemas

**Prioridad:** P0

Schemas para:

```text
position
theory
tul
vocabulary
body_tool
kick
combat
gup
source
```

---

## Epic F0-B - Catalogos basicos

### TKD-005 - Posiciones iniciales

**Prioridad:** P0

```text
charyot_sogi
junbi_sogi
gunnun_sogi
niunja_sogi
```

---

### TKD-006 - Teoria basica

**Prioridad:** P0

Extraer y estructurar teoria requerida inicialmente.

---

### TKD-007 - Vocabulario basico

**Prioridad:** P0

Construir catalogo canonico de terminologia.

---

### TKD-008 - Herramientas

**Prioridad:** P1

Estructurar herramientas y partes corporales utilizadas.

---

## Epic F0-C - Curriculum

### TKD-009 - 10º Gup

**Prioridad:** P0

Debe quedar completamente trazable y validado.

---

### TKD-010 - 9º Gup

**Prioridad:** P0

---

### TKD-011 - 8º Gup

**Prioridad:** P0

---

## Epic F0-D - Tuls

### TKD-012 - Saju Jirugi

**Prioridad:** P0

---

### TKD-013 - Saju Makgi

**Prioridad:** P0

---

### TKD-014 - Chon-Ji

**Prioridad:** P0

---

## Epic F0-E - Acceso y grados

### TKD-015 - Catalogo de grados

**Prioridad:** P0

Definir grados reconocidos por la escuela.

---

### TKD-016 - Matriz rol/grado

**Prioridad:** P0

Separar permisos funcionales y acceso curricular.

---

### TKD-017 - Modelo de verificacion

**Prioridad:** P0

Definir:

```text
UNVERIFIED
PENDING
VERIFIED
REJECTED
```

y reglas correspondientes.

---

## Epic F0-F - Validacion automatica

### TKD-018 - Validador de referencias

Detectar:

- IDs inexistentes;
- referencias rotas;
- duplicados.

---

### TKD-019 - Validador biomecanico

Detectar:

- porcentajes invalidos;
- angulos invalidos;
- campos faltantes.

---

### TKD-020 - Validacion curricular

Garantizar que cada requisito de un Gup exista en los catalogos.

---

# 39. Definition of Done de Fase 0

La Fase 0 termina cuando:

- las fuentes estan inventariadas;
- existe un esquema de procedencia;
- los JSON tienen schemas;
- 10º, 9º y 8º Gup estan estructurados;
- los catalogos referenciados existen;
- Saju Jirugi esta modelado;
- Saju Makgi esta modelado;
- Chon-Ji esta modelado;
- las posiciones iniciales estan modeladas;
- existen validadores automaticos;
- ninguna referencia curricular esta rota;
- el contenido aprobado tiene fuente identificable.

---

# 40. Fase 1 - Persistencia

Objetivos:

- ERD;
- PostgreSQL;
- Flyway;
- tablas;
- constraints;
- indexes;
- seed inicial;
- importer JSON -> PostgreSQL.

---

# 41. Fase 2 - Backend

Objetivos:

- crear Spring Boot;
- arquitectura modular;
- entidades;
- repositories;
- services;
- DTOs;
- mappers;
- controllers;
- validacion;
- OpenAPI;
- tests.

---

# 42. Fase 3 - Seguridad

Objetivos:

- autenticacion;
- JWT/OIDC;
- RBAC;
- autorizacion por grado;
- solicitud de verificacion;
- bandeja administrativa;
- auditoria.

---

# 43. Fase 4 - Angular

Objetivos:

- proyecto Angular;
- branding;
- layouts;
- rutas;
- autenticacion;
- guards;
- dashboard alumno;
- admin dashboard;
- bandeja;
- temario;
- visualizadores.

---

# 44. Fase 5 - Visualizacion biomecanica

Objetivos:

- renderer 2D;
- pies;
- coordenadas;
- rotaciones;
- peso;
- referencias;
- leyenda.

Se prioriza Canvas/SVG en frontend para una experiencia interactiva.

Matplotlib puede permanecer como herramienta de validacion o generacion offline.

---

# 45. Fase 6 - Aprendizaje

Futuro:

- quizzes;
- progreso;
- preguntas por grado;
- resultados;
- estadisticas;
- repaso.

---

# 46. Fase 7 - Produccion

Checklist:

- dominio;
- HTTPS;
- backups;
- variables;
- CORS;
- logs;
- health check;
- DB persistente;
- migration strategy;
- rollback;
- documentacion;
- monitoreo minimo.

---

# 47. Primer milestone

## TaeKwonPage Content Foundation v0.1

Debe demostrar:

```text
PDFs
 -> catalogos
 -> curriculum
 -> validacion
 -> PostgreSQL
 -> API
```

Primer caso completo:

```text
10º Gup
```

El backend debe poder responder:

```http
GET /api/v1/gups/10
```

y devolver el temario completo utilizando referencias validas.

---

# 48. Segundo milestone

## TaeKwonPage Identity & Grade Access v0.2

Debe permitir:

```text
registro
login
10º Gup por defecto
solicitud de grado
bandeja Admin
aprobar
actualizar acceso
historial
```

---

# 49. Tercer milestone

## TaeKwonPage Web v0.3

Debe incluir:

```text
Home
Login
Registro
Dashboard alumno
Temario
Perfil
Solicitud de grado
Admin dashboard
Bandeja de solicitudes
```

con branding Nahuel Aukan.

---

# 50. Orden recomendado de implementacion

No comenzar por construir todas las paginas.

Orden:

```text
1. Repositorio y estructura
2. Knowledge base
3. JSON schemas
4. 10º Gup
5. PostgreSQL
6. Spring Boot
7. API de contenido
8. Usuarios / roles
9. Verificacion de grado
10. Angular shell
11. Login
12. Dashboard
13. Curriculum
14. Admin
15. Resto de contenido
16. Deploy
```

---

# 51. Reglas para desarrollo asistido por IA

OpenCode, ChatGPT u otros agentes deben respetar:

1. No inventar datos marciales.
2. No modificar IDs canonicos publicados sin justificacion.
3. No asumir informacion que no exista en las fuentes.
4. No introducir dependencias sin explicar por que.
5. No modificar arquitectura fuera del alcance de la tarea actual.
6. No crear microservicios innecesarios.
7. Mantener separacion backend/frontend/knowledge.
8. Crear tests cuando corresponda.
9. Documentar decisiones importantes.
10. No introducir secretos en archivos versionados.
11. No reemplazar datos extraidos por conocimiento general del modelo.
12. Ante una contradiccion documental, marcarla para revision humana.
13. Antes de cambios destructivos, explicar impacto.
14. Preferir cambios pequeños y verificables.
15. Mantener compatibilidad con presupuesto de infraestructura US$0.

---

# 52. Convencion para commits

Ejemplos:

```text
feat(content): add initial position catalog
feat(curriculum): add 10th gup requirements
feat(auth): add student registration
feat(admin): add grade verification queue
fix(content): correct broken tul reference
docs(architecture): update access model
test(curriculum): validate gup references
```

---

# 53. ADRs recomendados

Crear Architecture Decision Records para decisiones importantes:

```text
ADR-001-monolith-first.md
ADR-002-postgresql.md
ADR-003-angular.md
ADR-004-canonical-json.md
ADR-005-grade-verification.md
ADR-006-source-provenance.md
ADR-007-free-infrastructure.md
```

---

# 54. Principio central de TaeKwonPage

TaeKwonPage no debe convertirse solamente en una pagina que muestra texto.

Su valor esta en transformar conocimiento documental de Taekwon-Do en:

```text
informacion estructurada
        +
trazabilidad
        +
curriculum
        +
control de acceso
        +
herramientas educativas
```

La base de conocimiento es el nucleo del producto.

---

# 55. Estado actual y checklist de seguimiento

**Corte verificado: 24-10-2026.** Un `[x]` indica exactamente el entregable descrito, no aprobacion humana del conocimiento ni una funcionalidad de la pagina disponible. Los estados parciales se mantienen abiertos.

Vista resumida para el responsable del proyecto: **[Plan de ataque con checks por fase](Plan_ataque.md)**. Se actualizara junto con este informe; no sustituye las decisiones originales ni sus criterios de cierre.

## 55.1 Decisiones confirmadas (no equivalen a implementacion)

- [x] ZVK Tech
- [x] TaeKwonPage
- [x] Escuela unica
- [x] Nahuel Aukan
- [x] Angular
- [x] Spring Boot
- [x] PostgreSQL
- [x] Presupuesto free
- [x] PDFs disponibles
- [x] Logo declarado disponible en el plan; asset local todavia no localizado
- [x] Acceso inicial 10º Gup
- [x] Verificacion de grado por Admin
- [x] Busabonim como administrador funcional
- [x] Developer separado del rol marcial
- [x] Acceso acumulativo por grado
- [x] Arquitectura monolito modular inicialmente

## 55.2 Paso a paso respecto de la seccion 50

**Bloque del 18-10-2026:** el usuario solicita continuar hacia BD/backend/frontend. Se habilita infraestructura local y pruebas de borradores en paralelo a las decisiones humanas pendientes, sin cerrar Sprint 1 ni alterar sus requisitos. PostgreSQL queda activo solo en localhost; la BD de desarrollo tiene esquema V1 sin contenido. El test importa los borradores en una BD aleatoria y la elimina al terminar. No hay credenciales versionadas, nuevas dependencias npm ni seeds aprobados.

**Cierre nocturno — backend:** Spring Boot 3.5.16 / Java 21 / Maven, Flyway 11.20.0 al arranque y validacion JPA del esquema existente. Primer modulo de contenido con entidad/repositorio de lectura de posiciones, servicio transaccional, DTO y controlador preventivamente bloqueado por Spring Security. Solo GET de salud accesible sin detalles, escucha local por defecto. 11 pruebas Java correctas con Testcontainers/PostgreSQL; JAR probado contra Compose, salud UP y contenido 403, proceso de prueba detenido. Angular, identidad, OpenAPI definitivo, curriculum y publicacion no implementados en este bloque.

**Bloque posterior — procedencia:** la lectura interna de posiciones incorpora citas de su ficha con metadatos de fuente, identidad ID/SHA-256, pagina PDF y folio independientes, estados de revision y derechos. Proyeccion de solo lectura ordenada, lista inmutable, sin rutas locales ni notas internas. 17 pruebas Java correctas contra PostgreSQL aislado; sin abrir rutas, cambiar migraciones, dependencias o contenido marcial.

**Bloque activo — Fase 1:** por nueva instruccion, completar persistencia antes de retomar Fase 0 y luego Fase 2. Se implemento importacion de curriculos de trabajo (siete relaciones tipadas/citas) y recarga identica comprobada, sin sobreescrituras. Filas/relaciones diferentes provocan rollback; se verifica tambien la reversion de inserciones previas al conflicto. Pruebas con curriculum sintetico fuera de `knowledge/`, sin crear programa escolar. Permanecen pendientes curriculum real, seed aprobado, evidencia de revision/publicacion, edicion versionada y el modelo funcional de identidad. No se declara Fase 1 cerrada ni se amplia el backend en este bloque.

**Continuacion de Fase 1 — revisiones:** V2 incorpora contador de revision, historial append-only de nombre/descripcion y snapshot de citas, con funcion SQL de version esperada y exportador local explicito. Referencia del operador marcada no verificada, no identidad o aprobacion humana. Pruebas sinteticas comprueban ediciones, rechazos de version vieja/cambios sin historial, rollback de texto/historial y recarga del snapshot actualizado. V2 aplicada en desarrollo, con cero fichas y cero revisiones cargadas; V1 intacta. No se editan fichas reales, citas, subtipos, curriculos o estados. Faltan esos flujos y la evidencia de revision/publicacion; no se declara Fase 1 completa.

**Bloque del 21-10-2026 — requisitos curriculares:** V3 incorpora baseline observado e historial de las siete categorias, con version esperada, referencias tipadas, snapshot de citas y operador local no verificado. Reemplazo atomico por Gup, rechazos de cambios sin historial, rollback de relaciones/historial y recarga del snapshot actualizado. Se prueban alta inicial y upgrade V2 → V3 con datos sinteticos, 30 rechazos SQL e aislamiento entre curriculos; no se crea un programa real. V3 aplicada localmente, con cero fichas e historial curricular cargados; V1/V2 intactas, sin nuevas dependencias o endpoints. Fase 1 sigue abierta por citas/subtipos, revision/publicacion y contraste/seed reales.

**Continuacion — posiciones/vocabulario:** V4 incorpora historial de pesos/rotaciones y traduccion/alias, con baseline observado y cadena global compartida con texto/requisitos. Valores desconocidos siguen null, porcentajes usan NUMERIC y las reglas se contrastan en SQL. Exportador explicito sin aplicar cambios por si solo; 188 tests Node, 17 Java y 36 rechazos de detalles SQL, ademas de pruebas de nulos/decimales, cadenas mixtas, rollback y recarga actualizada. V4 aplicada localmente con cero fichas e historial de detalles; V1–V3 intactas. Solo fixtures aislados, sin endpoints/dependencias nuevos o cambios marciales reales. Citas y ejercicios/Tuls siguen pendientes, junto con revision/publicacion y contenido aprobado.

**Continuacion — ejercicios/Tuls:** V5 extiende el historial de detalles a conteo, preparacion, alcance y pasos con sus posiciones/citas propias. Mantiene totales desconocidos y secuencias parciales; una declaracion completa exige todos sus datos y pasos consecutivos. Se prueban upgrade con datos, secuencias sinteticas parciales/completas/vacias, cadenas mixtas, 39 rechazos SQL, errores tardios de FK y rollback de pasos/enlaces/historial. 192 tests Node y 17 Java correctos; V5 aplicada localmente con cero fichas e historial. Sin cambios marciales reales, citas documentales, dependencias o endpoints; V1–V4 intactas. Saju permanece parcial y no se infiere el punto 3 ilegible. Fase 1 sigue abierta por citas, revision/publicacion y contenido curricular aprobado.

**Continuacion — citas documentales:** V6 incorpora baseline e historial antes/despues de citas, con fuente/hash/localizadores/notas, revision global y reserva de IDs por propietario. Reemplazo atomico compatible con enlaces de pasos; una cita usada no se puede retirar y un ID retirado no pasa a otra ficha. Se prueban swap, seccion sin pagina, versiones mixtas con texto/requisitos, 37 rechazos SQL y rollback de citas/reservas/historial, incluida FK diferida en el editor de ejercicios. 198 tests Node y 17 Java correctos; V6 aplicada localmente con cero fichas, revisiones de citas y reservas de IDs cargadas. V1–V5 intactas, sin corregir las 51 citas reales ni cambiar fuentes/derechos/estados. Versionado tecnico implementado; revision/publicacion, curriculum real y seed aprobado siguen pendientes. No se declara Fase 1 cerrada.

**Contenido: entre los pasos 3 y 4; infraestructura: pasos 5 y 6 iniciados y lectura parcial del 7.** Adelantamos partes de Fases 1 y 2 sin cerrar Fase 0, por autorizacion del usuario; no se eliminaron pendientes ni se declaro cumplida su Definition of Done. La Fase 0 sigue abierta por gobernanza/convenciones, catalogos y ejercicios incompletos, curriculos 10º/9º/8º y revision humana. Fase 1 tiene esquema, mapeo, recarga y versionado tecnico de datos/citas probados; faltan contraste curricular real, seed aprobado, evidencia de revision/publicacion y los modelos funcionales pendientes. No se asigna un porcentaje global porque los pasos no tienen el mismo esfuerzo y quedan decisiones humanas pendientes.

Bloque cerrado: variante preparatoria implementada en `feat/tkd-005-preparatory-position` (`b6b5b99`), integrada y publicada en `main` mediante `6fc2ab1`, con SHA remotos verificados. Se localizo Narani Junbi Sogui en PDF 81 / folio 79 y se enlazo con la preparacion de los tramos de PDF 530.

Bloque actual (17-10-2026): se completaron los tipos de contenido que quedaban vacios en los catalogos canonicos, correspondientes a los archivos semilla escritos antes en la raiz. Se añadieron **combate pactado** (PDF 8-9 de un manual y 10-11 del otro), **patadas** (enciclopedia PDF 256-257) y **cinco herramientas del pie** (enciclopedia PDF 102-103), con citas y revisión pendiente. Tambien se confirmo que el «TEMARIO PARA CADA EXAMEN» de 10º a 9º solo enumera temas de teoria, por lo que no se construyo ningun curriculo. Implementacion `9716929` en `feat/tkd-008-combat-and-kicks`, integrada y publicada en `main` mediante `462ea13`, con SHA remotos verificados y 166 + 22 tests correctos antes y despues del merge. Sin contenido marcial aprobado.

| Paso | Entregable | Estado real |
|---|---|---|
| 1 | Repositorio y estructura | Baseline y bloques integrados y publicados en `main` mediante `1ab81e7`; historial conservado, sin PR |
| 2 | Knowledge base | Inventario inicial de cuatro PDFs; 31 fichas y 51 citas en revision, con los siete tipos de contenido cubiertos: posiciones, teoria, tuls, vocabulario, herramientas, patadas y combate; no secuencias globales completas ni curriculo |
| 3 | JSON schemas | Contratos iniciales para los nueve tipos del informe y sus contenedores; requieren contraste con la extraccion completa |
| 4 | 10º Gup | En curso; falta programa confirmado, curriculum enlazado y contenido completo/revisado |
| 5 | PostgreSQL | Compose, ERD, V1–V6, mapeo/recarga y versionado de texto/requisitos/subtipos/citas probados; curriculum real/seed aprobado y evidencia de revision/publicacion pendientes |
| 6 | Spring Boot modular | Base ejecutable Java 21 con Flyway, JPA, Security y Actuator; primer modulo de lectura de posiciones probado, ampliacion pendiente |
| 7 | API de contenido | Posiciones con DTO y citas/metadatos de copia, bloqueadas por politica HTTP; sin API educativa accesible ni controlador `GET /api/v1/gups/10` |
| 8 | Usuarios y roles | Reglas documentadas; implementacion no iniciada |
| 9 | Verificacion de grado | Flujo documentado; implementacion no iniciada |
| 10 | Angular shell | No iniciado |
| 11 | Login | No iniciado; JWT local/OIDC por decidir |
| 12 | Dashboard | No iniciado |
| 13 | Curriculum en la web | No iniciado |
| 14 | Administracion | No iniciada |
| 15 | Resto de contenido | No iniciado como ampliacion; no se ha avanzado a curriculos de 9º/8º Gup |
| 16 | Deploy | No iniciado; sin proveedor, beta publica ni CI/CD configurado |

## 55.3 Sprint 0 — bootstrap

- [x] Crear estructura profesional y directorios reservados.
- [x] Crear README, `.gitignore`, `.editorconfig` y siete ADR de decisiones aprobadas.
- [x] Excluir PDFs y vistas previas locales de Git; conservar originales.
- [x] Conectar Git local con `https://github.com/ZorVaK749/TaekwonPage.git`, preservando su historia inicial.
- [x] Recuperar `LICENSE` MIT del remoto, sin modificarla ni aplicarla a PDFs de terceros.
- [x] Crear `main` local siguiendo `origin/main` y rama `chore/project-baseline` basada en esa historia.
- [x] Revisar candidatos y guardar baseline en commit local `83eb531` (`chore(repo): establish knowledge foundation baseline`), preservando el commit inicial remoto.
- [x] Definir normalizacion de texto con `.gitattributes`, consistente con `.editorconfig`, sin quitar los saltos Markdown intencionales.
- [x] Publicar y verificar en GitHub `chore/project-baseline`, `feat/tkd-008-tools-and-exercise-drafts`, `feat/tkd-012-exercise-source-evidence` y `chore/push-only-workflow`, mediante refspecs explicitos y sin PR o merge.
- [x] Integrar y verificar el checkpoint acumulado en `main` mediante merge `1ab81e7`, sin PR; resultado integrado validado con 153 + 22 tests. No implica cierre de Sprint 1 ni una release.
- [x] Crear Docker Compose funcional para PostgreSQL y Flyway; comprobado con motor Docker activo el 18-10-2026. Backend/frontend se incorporaran al existir aplicaciones ejecutables.

La estructura y el entregable Compose de Sprint 0 estan implementados. No equivale a completar Knowledge Foundation o disponer de aplicaciones.

## 55.4 Sprint 1 — Knowledge Foundation

- [x] Inventariar tecnicamente cuatro PDFs con IDs estables, tamano y SHA-256 (TKD-001); metadatos desconocidos permanecen explicitos.
- [x] Inspeccionar cobertura general de las cuatro copias; en la enciclopedia se consultaron paginas iniciales/indice y una busqueda dirigida de ejercicios, no sus 764 paginas completas.
- [ ] Confirmar autoridad curricular y revisor marcial con la escuela (TKD-002).
- [ ] Completar convenciones marciales de romanizacion, medidas, referencias y unidades (TKD-003); las convenciones tecnicas de IDs/citas ya estan implementadas.
- [x] Implementar contratos JSON iniciales de `source`, `position`, `theory`, `tul`, `vocabulary`, `body_tool`, `kick`, `combat` y `gup`, con contratos comunes y contenedores (base tecnica de TKD-004).
- [ ] Contrastar y ajustar esos contratos con la extraccion real completa; no equivalen a modelos marciales definitivos.
- [ ] Completar posiciones iniciales (TKD-005): cuatro fichas en revision, incluida `narani_junbi_sogi` como variante documentada; la adopcion escolar del Junbi generico y las convenciones geometricas siguen pendientes.
- [ ] Completar teoria inicial (TKD-006): hay cinco fichas en revision, no todo el temario.
- [ ] Completar vocabulario inicial (TKD-007): hay cuatro terminos en revision.
- [ ] Completar herramientas (TKD-008): diez fichas iniciales con catorce citas en revisión, cinco de mano y cinco del pie; no incluyen formación anatómica o mecánica de impacto inferidas.
- [ ] Completar patadas: tres fichas iniciales con tres citas en revisión, tomadas del capítulo de ataque de pie de la enciclopedia; el capítulo es en buena parte fotográfico y no se leyó íntegro.
- [ ] Completar combate pactado: tres modalidades iniciales con cinco citas en revisión (`sambo_matsokgi`, `ibo_matsokgi`, `ilbo_matsokgi`); falta confirmar validez de la variante y resolver la divergencia entre copias.
- [ ] Construir y revisar curriculum de 10º Gup (TKD-009); cero archivos curriculares en la ubicacion nueva.
- [ ] Modelar Saju Jirugi y Saju Makgi completos con evidencia de secuencia (TKD-012/TKD-013): listas impresas de 7/8 acciones con alcance explicito y preparacion enlazada a `narani_junbi_sogi` de la misma copia; total global desconocido, ejecucion alterna no reconstruida y punto 3 de Jirugi con laguna de legibilidad. Los JSON previos no se promovieron a canonicos.
- [ ] Modelar Chon-Ji con evidencia (TKD-014), cuando corresponda al alcance acordado.
- [ ] Confirmar catalogo de grados, matriz funcional y ciclos de estados (TKD-015/TKD-016/TKD-017); reglas aprobadas documentadas, implementacion pendiente.
- [x] Implementar controles tecnicos de IDs, duplicados, citas, hashes, paginas y referencias por tipo (base de TKD-018).
- [x] Implementar controles tecnicos de porcentajes, angulos y secuencias declaradas (base de TKD-019).
- [x] Implementar validacion tecnica de referencias curriculares (base de TKD-020), probada con fixtures sinteticos.
- [ ] Validar esos controles sobre un curriculum real y completo de 10º Gup; los tests no reemplazan revision humana.
- [ ] Obtener aprobacion humana del contenido y revisar los derechos aplicables antes de publicar.

TKD-010/TKD-011 (9º y 8º Gup) siguen pendientes y fuera de la ejecucion del Sprint 1 actual hasta demostrar la estructura de 10º, segun la seccion 56. La Definition of Done de Fase 0 de la seccion 39 no se modifica.

## 55.5 Evidencia actual y validaciones

| Area | Cantidad / resultado |
|---|---|
| PDFs locales inventariados | 4; nunca publicados por estas tareas |
| Archivos de catalogo nuevos | 9, todos con contenido en revision |
| Fichas | 31: 5 de teoria, 4 de vocabulario, 4 de posiciones, 10 herramientas (5 de mano, 5 de pie), 2 ejercicios parciales, 3 patadas y 3 de combate |
| Citas de procedencia | 51 en 9 archivos; vinculadas a copias exactas por SHA-256; cuatro copias documentales utilizadas, sin declarar independencia entre ellas |
| Acciones documentadas | 15 registros, correspondientes a listas impresas 1–7 y 1–8; no representan totales globales ni ejercicios completos |
| Curriculos nuevos | 0 |
| Contenido con aprobacion humana registrada | 0 |
| Tests Node | 198 correctos |
| Tests PowerShell | 22 correctos |
| Tests backend | 17 correctos, sin omitidos: unitarios y PostgreSQL Testcontainers; migracion, DTO con citas/identidad/localizadores, serializacion sin datos locales y casos negativos HTTP |
| Arranque backend | JAR ejecutado contra Compose con importacion explicita de .env local; salud UP sin detalles, posiciones HTTP 403; proceso detenido al finalizar |
| Persistencia | PostgreSQL/Flyway V1–V6: creacion/upgrades con datos; 16 rechazos de constraints, cinco conflictos de importacion, 18 textuales, 30 curriculares, 36 escalares, 39 de ejercicios y 37 de citas/propiedad; historial y rollback |
| Verificacion local de PDFs | Correcta: presencia, tamano, cabecera y SHA-256; no prueba de verdad marcial |
| `validate:content` | Debe fallar por falta de curriculum; fallo esperado, no milestone completado |
| GitHub | Ejercicios integrados en `77a3fec`; citas en `feat/versioned-citation-edits`, con push e integracion revisada segun el flujo habitual. Sin borrado de referencias, PR, tags/releases o deploy |

Fuentes del seguimiento: [politica de fuentes](knowledge/sources/README.md), [procedencia](knowledge/provenance/README.md), [contratos](knowledge/schemas/README.md) y [validadores](tools/validators/README.md). El reporte reproducible se obtiene con:

```powershell
npm.cmd --prefix tools/validators run report
node tools/validators/validate-knowledge.mjs --report-json --check-local-files
```

## 55.6 Decisiones y bloqueos abiertos

1. Programa vigente y autoridad curricular de la escuela; designacion de quien revisa/aprueba.
2. Adopcion escolar del `junbi_sogi` generico: la fuente ya permite registrar y enlazar `narani_junbi_sogi` para sus tramos, pero no convertir todas las preparaciones en esa variante ni heredar la geometria del borrador previo.
3. Sistema de medidas y orientaciones; no convertir angulos textuales a rotaciones de renderer sin referencias verificadas.
4. Resolucion humana de divergencias entre manuales; no escoger uno por cantidad de paginas o fecha supuesta.
5. Estrategia JWT local/OIDC y distincion entre estados del alumno y de su solicitud, antes de su implementacion.
6. Derechos para el uso previsto y datos personales; un repo MIT no licencia fuentes de terceros.
7. Flujo GitHub: primera integracion completada. Trabajar desde el `main` actualizado, hacer push de la rama e integrar checkpoints periodicamente sin PR. Las cuatro ramas anteriores ya estan integradas; eliminarlas local/remotamente requiere autorizacion separada. No confundir integracion tecnica con aprobacion marcial, release o deploy.
8. Saju Jirugi/Saju Makgi: falta resolver la laguna del destino del golpe del punto 3 de Jirugi y confirmar el alcance completo/alterno. La preparacion de PDF 530 se enlazo a la definicion especifica de PDF 81; no sumar, espejar o heredar conteos de los JSON antiguos. `sequence_complete` permanece en `false`.
9. Combate pactado: confirmar la validez y la variante de `sambo_matsokgi`, `ibo_matsokgi` e `ilbo_matsokgi`. La copia ONT incluye un apartado «a dos pasos» ausente en la otra; no se elige autoridad por numero de paginas, y la forma «sin contacto» del archivo antiguo no aparece en las fuentes.
10. Patadas y herramientas del pie: el capitulo de ataque de pie de la enciclopedia es en buena parte fotografico; `cha_jirugi` tiene una redaccion ambigua. Ampliar solo con evidencia documental legible.
11. Curriculo de 10º Gup: el «TEMARIO PARA CADA EXAMEN» de 10º a 9º solo enumera temas de teoria; no aporta requisitos tecnicos. Se necesita el programa tecnico confirmado por la escuela antes de construir cualquier curriculo.

El plan de seguridad detallado sigue pendiente, sin posponer las reglas ya aprobadas ni permitir exponer una beta sin los controles aplicables.

## 55.7 Versiones del producto

| Milestone | Tag previsto | Estado |
|---|---|---|
| Content Foundation v0.1 | `v0.1.0` | En curso; faltan curriculum, persistencia y API |
| Identity & Grade Access v0.2 | `v0.2.0` | No iniciado |
| Web v0.3 | `v0.3.0` | No iniciado |

No se crearon tags, releases ni una beta. `1.18` es la version de este informe; las versiones de herramientas/JAR no equivalen a una release de la plataforma.

---

# 56. Plan por sprints y proximo bloque

Se conserva la secuencia aprobada; el estado de ejecucion se registra en la seccion 55.

## Sprint 0 - Bootstrap del repositorio

Estructura implementada; Compose PostgreSQL/Flyway implementado y probado el 18-10-2026. Baseline guardado en `83eb531` y publicado en rama; integraciones revisadas a `main` autorizadas, sin PR.

Entregables:

```text
estructura de carpetas
README
informe_tecnico.md
.gitignore
.editorconfig
docker-compose
knowledge/
backend/
frontend/
docs/
```

Despues:

## Sprint 1 - Knowledge Foundation

**Sprint de contenido en curso.** Existen contratos y lotes de trabajo, no un curriculum aprobado. La infraestructura y el arranque backend avanzan por autorizacion expresa del usuario, sin aprobar contenido ni cerrar el milestone educativo.

Primer objetivo funcional:

```text
10º Gup
```

No avanzar a 9º Gup hasta que la estructura de 10º Gup haya demostrado ser reusable.

### Proximo bloque de trabajo

**Prioridad vigente por instruccion del usuario:** Fase 1 primero; al terminar sus entregables verificables, retomar una parte de Fase 0 y despues regresar a Fase 2. Los puntos de contenido siguientes siguen como dependencias, no como orden para ampliar backend inmediatamente. No cerrar Fase 1 por pruebas sinteticas si faltan evidencia real o decisiones humanas.

1. Checkpoint acumulado integrado y publicado en `main` con historial preservado. En bloques futuros, partir de `origin/main` actualizado, trabajar y hacer push en una rama e integrar checkpoints coherentes periodicamente. Sin PR, force-push, tags o limpieza de ramas no autorizada.
2. Contrastar y revisar los tramos encontrados en PDF 530 de la enciclopedia, resolver su legibilidad y alcance antes de completar secuencias; continuar consultas dirigidas para las lagunas de posiciones/herramientas. No convertir expresiones terminologicas en pasos ni generar el recorrido alterno por simetria.
3. Resolver con la escuela los asuntos que impiden aprobar requisitos, posiciones o secuencias; registrar responsable, evidencia y fecha reales, sin aprobaciones ficticias.
4. Construir curriculum enlazado y validarlo con contenido real antes de declarar completo el caso de 10º Gup.
5. Por instruccion del usuario del 18-10-2026 se habilitaron persistencia local y arranque Spring Boot sin declarar completado el contenido: [ERD y limites](docs/database/README.md) y [backend ejecutable](backend/taekwonpage-api/README.md). Siguiente bloque: ampliar lectura/procedencia, acordar identidad y publicacion antes de abrir rutas, definir OpenAPI y completar importacion curricular real. Angular y despliegue no se inician en este cierre nocturno.

La forma de trabajar con ramas, commits, push, integraciones y versiones queda documentada en [flujo de desarrollo](docs/development/README.md). La ultima instruccion permite merges periodicos revisados a `main`, sin crear PR, y sustituye la prohibicion anterior de merges. Esto no cambia el monolito modular ni introduce microservicios.

---

# 57. Criterio general para OpenCode

Cuando OpenCode reciba una tarea:

1. leer `informe_tecnico.md`;
2. inspeccionar el repositorio;
3. explicar brevemente que va a modificar;
4. realizar un cambio acotado;
5. ejecutar validaciones/tests aplicables;
6. reportar archivos modificados;
7. indicar errores o decisiones pendientes;
8. no continuar con el siguiente milestone sin instruccion.
9. actualizar este informe al cerrar cada bloque con entregables verificables, checklist, validaciones y decisiones pendientes; cambiar la arquitectura requiere explicacion previa, no una edicion silenciosa del seguimiento.
    Mantener tambien [Plan_ataque.md](Plan_ataque.md) sincronizado con el estado por fases y sus checks, sin confundir avance tecnico con aprobacion o cierre.
10. publicar avances revisados mediante push a su rama e integrar checkpoints coherentes periodicamente en `main`, con tests, commit de merge y verificacion remota; no crear Pull Requests, forzar historia, publicar tags/despliegues o borrar ramas sin autorizacion.

---

# 58. Historial del informe

| Version | Fecha | Cambio |
|---|---|---|
| 1.0 | 14-10-2026 | Plan maestro inicial y decisiones de arquitectura aprobadas |
| 1.1 | 15-10-2026 | Seguimiento real de Sprint 0/1, checklist por paso/TKD, evidencias de tests, decisiones abiertas y flujo Git local con baseline pendiente de commit/PR; sin modificar decisiones de arquitectura |
| 1.2 | 15-10-2026 | Baseline guardado en commit local `83eb531`; 91 archivos nuevos versionados sin PDFs/capturas/dependencias; politica `.gitattributes`, revision de patrones comunes de credenciales y 138 + 22 tests correctos. Sin push, tags o avance de milestone |
| 1.3 | 15-10-2026 | Rama de bloque derivada del baseline; cinco herramientas y dos ejercicios terminologicos parciales, 11 citas nuevas. Total 19 fichas/35 citas; 145 + 22 tests correctos, sin declarar secuencias completas, aprobacion humana o curriculum. Sin nuevas dependencias ni cambios de arquitectura |
| 1.4 | 16-10-2026 | Consulta dirigida de enciclopedia: PDF 530 / folio 528, 15 acciones resumidas y dos citas nuevas; alcance `sequence_scope`, control de tramos parciales y reporte de lagunas. Total 19 fichas/37 citas; 153 + 22 tests correctos. Secuencias incompletas y laguna de legibilidad explicitas, sin aprobacion, curriculum, nuevas dependencias o cambios de arquitectura |
| 1.5 | 16-10-2026 | Por instruccion del usuario, flujo de commits y push a ramas sin PR ni merges; retirada de plantilla de PR y plan de CI por push. Cuatro ramas publicadas con SHA remotos verificados tras revisar cinco commits salientes y 110 versiones unicas de archivos; sin PDF/capturas o patrones comunes de credenciales detectados. 153 + 22 tests correctos; `main`, contenido y arquitectura de aplicacion sin cambios |
| 1.6 | 16-10-2026 | Nueva instruccion: push por rama y merges periodicos revisados a `main`, sin PR. Primera integracion publicada y verificada mediante `1ab81e7`; 153 + 22 tests correctos sobre el resultado, cuatro ramas contenidas en main sin eliminarlas. Sin release, deploy, aprobacion curricular, nuevas dependencias o cambios en datos/arquitectura de aplicacion |
| 1.7 | 16-10-2026 | Variante Narani Junbi Sogui extraida de PDF 81 / folio 79, una ficha/cita nueva y preparacion de los dos ejercicios enlazada con evidencia contextual de PDF 530. Total 20 fichas/38 citas; 159 + 22 tests correctos antes y despues del merge. Implementacion `b6b5b99`, integracion `6fc2ab1` publicadas y verificadas. Sin alias generico, geometria heredada, curriculum, nuevas dependencias o secuencias declaradas completas |
| 1.8 | 17-10-2026 | Completados los tipos de contenido vacios: combate pactado (3 fichas/5 citas), patadas (3 fichas/3 citas) y cinco herramientas del pie (citas nuevas). Total 31 fichas/51 citas en 9 archivos de catalogo y 9 de procedencia; 166 + 22 tests correctos. Confirmado que el temario 10º-9º solo cubre teoria, por lo que no se creo curriculo. Sin aprobacion humana, nuevas dependencias, cambios de arquitectura ni promocion de los JSON antiguos |
| 1.9 | 18-10-2026 | Primer bloque de persistencia autorizado: ERD, Compose PostgreSQL/Flyway, migracion V1 y exportador SQL transaccional de borradores. 169 tests Node, 22 PowerShell y prueba real de migracion/importacion/16 rechazos SQL. Esquema aplicado localmente, sin contenido aprobado o curriculum ficticio; Spring Boot/Angular pendientes |
| 1.10 | 18-10-2026 | Arranque Spring Boot 3.5.16 Java 21/Maven con Flyway, JPA y primer servicio/DTO de posiciones. Spring Security deny-all salvo salud minima. 11 pruebas Java con PostgreSQL Testcontainers y prueba del JAR contra Compose correctas; migracion V1 intacta. Sin Angular, login, publicacion, temario ficticio o deploy |
| 1.11 | 18-10-2026 | Citas y metadatos de fuentes en DTO interno de posiciones, vinculados por ID/hash, ordenados y sin rutas/notas internas; 17 pruebas Java correctas. Sin migraciones o dependencias nuevas, cambios marciales, apertura HTTP o implementacion de identidad |
| 1.12 | 18-10-2026 | Plan_ataque.md con checklist por Fases 0–7 y milestones, pendientes TKD de Fase 0 y alcance real/parcial de Fase 1. Se explicita el adelanto autorizado de persistencia/backend sin cierre de conocimiento. Solo documentacion; enlaces y consistencia de conteos revisados, sin nuevos tests de aplicacion o cambios funcionales |
| 1.13 | 18-10-2026 | Fase 1: importacion curricular tipada/citada y recarga identica sin duplicados; diferencias en filas/relaciones provocan rollback. 172 tests Node y prueba PostgreSQL con siete categorias sinteticas/cinco conflictos. Orden confirmado Fase 1 → retomar Fase 0 → Fase 2; sin cambios de migraciones/backend, curriculum real o aprobacion inventada |
| 1.14 | 18-10-2026 | Fase 1: V2 para revisiones textuales con control de version e historial/citas; exportador explicito, operador local no verificado. 177 tests Node, 17 Java y pruebas SQL de 18 rechazos editoriales/rollback. V1 intacta; sin correcciones marciales reales, apertura HTTP, aprobacion o cierre de fase |
| 1.15 | 21-10-2026 | Fase 1: V3 para requisitos curriculares versionados con baseline observado, siete grupos, historial/citas y guardas de integridad. 182 tests Node, 17 Java y 30 rechazos curriculares SQL; upgrade con datos, aislamiento, fallo tardio y rollback. Sin curriculum escolar inventado, cambios de citas/subtipos, aprobacion, dependencias nuevas o apertura HTTP |
| 1.16 | 21-10-2026 | Fase 1: V4 para detalles de posiciones/vocabulario con historial/citas y cadena compartida de revisiones. 188 tests Node, 17 Java y 36 rechazos de detalles SQL; nulos/decimales/alias, cadenas mixtas y rollback probados. Sin modificar migraciones anteriores, contenido marcial real, dependencias o acceso HTTP |
| 1.17 | 23-10-2026 | Fase 1: V5 para conteos/preparacion/alcance/pasos de ejercicios con citas propias e historial. 192 tests Node, 17 Java y 39 rechazos SQL de ejercicios; secuencias sinteticas, fallos tardios y rollback probados. Saju real sigue parcial; sin cambios de citas documentales, dependencias, publicacion o acceso HTTP |
| 1.18 | 24-10-2026 | Fase 1: V6 para citas versionadas con copia/localizadores, reserva de IDs, propiedad de pasos y cadena global. 198 tests Node, 17 Java y 37 rechazos de citas/propiedad SQL; swap, FK diferida, coexistencia y rollback probados. Sin corregir evidencia real, cambiar derechos, aprobar contenido o abrir HTTP |

---

## Fin del documento

**TaeKwonPage**  
**ZVK Tech**  
**Taekwon-Do Nahuel Aukan**

Documento base para desarrollo asistido con OpenCode.
