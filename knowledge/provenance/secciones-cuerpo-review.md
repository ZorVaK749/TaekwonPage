# Secciones y división lateral del cuerpo — matriz para revisión

**Estado: pendiente de revisión humana y confirmación escolar.** Es una matriz de evidencia documental, **no un currículo** ni un catálogo aprobado. Fases 0 y 1 siguen abiertas.

Se observaron localmente las páginas previas a las tablas de vocabulario en ambas copias: **WEB PDF 9–10** y **ONT PDF 12–13**. De esas páginas se extrajeron dos fichas teóricas a [teoria_secciones_cuerpo.json](../catalogs/teoria/teoria_secciones_cuerpo.json) con [4 citas](teoria_secciones_cuerpo.json):

| ID | Ficha | Citas |
| --- | --- | --- |
| `secciones_cuerpo_altura` | División en tres partes: alta o Nopunde, media o Kaunde, baja o Najunde | ONT 12 + WEB 10 |
| `division_lateral_cuerpo` | División lateral en tres líneas: A plexo solar, B pecho, C hombro | WEB 10 + ONT 13 |

Ambas conservan `pending_human_review`.

## Divergencia entre copias observada en este bloque

| Asunto | Qué se observó | Límite |
| --- | --- | --- |
| Rangos de las secciones por altura | **ONT 12** enlaza las secciones con rangos: «Alta o Nopunde (encima del cuello)», «Media o Kaunde (entre los hombros y el ombligo)», «Baja o Najunde (bajo el ombligo)». **WEB 10** muestra solo la figura rotulada `Seccion alta (Nopunde)` / `Seccion media (Kaunde)` / `Seccion baja (Najunde)`, sin ese enunciado. | La ficha registra ambos hechos; no se completa WEB desde ONT ni se declara una copia más autoritativa (TKD-002) |
| Orden de la sección | En ONT el bloque de «puntos vitales» (5 secciones) precede a «SECCIONES DEL CUERPO»; en WEB, «PUNTOS VITALES (kupso)» está en WEB 9 y las secciones en WEB 10. | Se documenta la ubicación observada; no se reordena ni se fusiona el contenido |

## Relación con fichas existentes (no fusionadas)

- `nopunde`, `kaunde`, `najunde` ya existen como [vocabulario](vocabulario-tabla-completa-review.md), traducidos como «Alto», «Medio», «Bajo». Las fichas nuevas hablan de secciones del cuerpo, no de alturas de ataque: **no se equiparan ni se crean aliases**.
- El bloque de **puntos vitales (kupso)** de WEB 9 / ONT 12 enumera cinco secciones (Cabeza, Cuello, Tórax y abdomen, Genitales, Extremidades) con una definición de punto vital. **No se extrajo en este bloque**: se trata de material de alta sensibilidad marcial y de zonas objetivo, cuya extracción queda sujeta a decisión del revisor y al alcance que la escuela confirme. Queda registrado aquí como observado y pendiente.

## Límites aplicados

- Las líneas laterales (plexo solar, pecho, hombro) **no se convierten** en zonas de ataque, puntos vitales ni requisitos de examen.
- Las figuras se describen por su rotulación observable; no se interpretan medidas ni límites anatómicos ausentes del texto.
- No se añade formación anatómica ni mecánica de impacto inferida desde conocimiento general.

## Checklist para el revisor / responsable de la escuela

- [ ] Confirmar si las secciones del cuerpo (alta/media/baja y las tres líneas laterales) se exigen en el examen de 10º Gup de Nahuel Aukan y con qué profundidad.
- [ ] Decidir si WEB 10 debe considerarse incompleta respecto de ONT 12 en los rangos, o si son formulaciones distintas legítimas.
- [ ] Decidir si el bloque de **puntos vitales (kupso)** se extrae, con qué alcance y bajo qué criterio de seguridad marcial.
- [ ] Resolver la relación terminológica entre las secciones por altura y los términos `Nopunde`/`Kaunde`/`Najunde` del vocabulario.
- [ ] Registrar quién revisa, con identidad y alcance reales.

**No hay persona, fecha de aprobación o programa escolar confirmados en este documento.** La matriz no autoriza a sembrar datos como aprobados, a abrir endpoints educativos ni a avanzar de fase. `validate:content` debe seguir rechazando la ausencia de currículo.
