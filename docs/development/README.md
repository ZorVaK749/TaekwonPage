# Ramas, revisiones y versionamiento

Este flujo organiza el trabajo de ZVK Tech sin cambiar la arquitectura de [informe_tecnico.md](../../informe_tecnico.md). Por instruccion del responsable del proyecto del 16-10-2026 se usan **ramas por bloque, commits y push directo a esas ramas, sin Pull Requests ni merges**. No se crea `develop`, no se integra automaticamente en `main` y no se utiliza `git pull` como mecanismo de sincronizacion.

## Estado de la vinculacion

- Remoto `origin`: `https://github.com/ZorVaK749/TaekwonPage.git`.
- `main` local sigue `origin/main`; ambas parten de `4908799` (`Initial commit`, solo `LICENSE` MIT).
- Rama del baseline: `chore/project-baseline`. Los bloques siguientes conservan esa ascendencia en ramas derivadas; su upstream debe ser la rama remota homonima, nunca `origin/main` por accidente. La rama activa y el estado se registran en la seccion 55 del informe.
- La licencia se recupero del remoto sin cambiar su contenido.
- Baseline guardado en el commit local `83eb531` (`chore(repo): establish knowledge foundation baseline`): 91 archivos nuevos, sin PDFs, capturas o `node_modules`. Los JSON previos se conservaron sin modificar ni promover a contenido aprobado.
- Se autoriza publicar las ramas de trabajo para conservar el avance y su log en GitHub. La primera publicacion esta pendiente de verificacion remota en este corte; no se asume exito por crear un commit o ejecutar un dry-run. No se hacen PR, merges, tags o releases.
- `.gitattributes` normaliza texto en Git: LF para texto y CRLF al extraer scripts Windows, en concordancia con `.editorconfig`. Los espacios finales de Markdown se permiten por sus saltos de linea intencionales.

Una rama no es una copia de seguridad de archivos sin commit. Antes de cambiar a otra rama, revisar `git status` y guardar los cambios de forma explicita; nunca usar reset/checkout forzado, clean o descartes para resolver conflictos sin autorizacion.

## Convencion de ramas

| Tipo | Ejemplo | Uso |
|---|---|---|
| `chore/` | `chore/project-baseline` | Preparacion y mantenimiento |
| `feat/` | `feat/tkd-009-gup-10-curriculum` | Entregable funcional o de conocimiento |
| `fix/` | `fix/content-source-reference` | Correccion acotada |
| `docs/` | `docs/sprint-1-progress` | Documentacion sin cambios funcionales |

Usar nombres ASCII en minusculas y un bloque coherente por rama. No hacer desarrollo habitual ni push de avances directamente a `main`.

## Ciclo por bloque

1. Revisar el informe completo, el checklist y el estado Git antes de editar.
2. Con el directorio limpio, consultar el remoto y crear la rama desde el ultimo bloque de trabajo que contenga el avance necesario:

   ```powershell
   git fetch origin
   git switch --no-track -c feat/nuevo-bloque BASE_DE_TRABAJO
   ```

   `BASE_DE_TRABAJO` es un marcador, no una rama existente: elegir una referencia verificada, por ejemplo el ultimo bloque documentado. Actualmente `main` no contiene el proyecto. No ejecutar pull, merge, rebase o force-push para resolver diferencias automaticamente. Si una rama remota avanzo de forma incompatible, detener la publicacion y revisar la divergencia sin descartar trabajo.

3. Implementar un bloque acotado, actualizar `informe_tecnico.md` y ejecutar las validaciones aplicables:

   ```powershell
   npm.cmd --prefix tools/validators test
   npm.cmd --prefix tools/validators run validate
   npm.cmd --prefix tools/validators run validate:local
   powershell -NoProfile -File tools/validators/Test-SourceInventory.Tests.ps1
   ```

   `validate:local` requiere las copias PDF legitimas locales. `validate:content` sigue fallando esperadamente mientras falte curriculum; no ocultar este resultado ni presentarlo como aceptacion funcional.

4. Revisar `git status`, diferencias y archivos a incluir. Agregar rutas explicitas, no `git add -f`. Antes del commit revisar `git diff --cached --stat`, `git diff --cached` y `git diff --cached --check`. Ningun PDF, captura, secreto o dato personal debe entrar al indice.
5. Crear commits pequenos con la convencion de la seccion 52: `tipo(ambito): descripcion`. Ejemplos: `chore(repo): establish project baseline`, `feat(knowledge): add source-backed content drafts`, `docs(plan): update sprint checklist`. No fingir una historia pasada ni alterar autoria para dividir cambios ya mezclados.
6. Al cerrar un bloque revisado, ejecutar `git push -u origin NOMBRE_DE_RAMA`, sustituyendo el marcador por la rama real. Esta publicacion de ramas esta autorizada; no usar `--all`, `--mirror`, force-push ni incluir `main` o tags de forma implicita.
7. Verificar con `git ls-remote --heads origin` que el SHA remoto de esa rama coincide con el local; registrar rama, commit y resultado del push en el informe. Si falla la autenticacion o la publicacion, informar el bloqueo y no declarar los cambios subidos.
8. **No abrir Pull Requests ni ejecutar merges.** Mantener las ramas publicadas como historial de trabajo. Publicar borradores tecnicos en Git no equivale a aprobar conocimiento marcial o desplegar una pagina.

No se configuraron protecciones de ramas en GitHub. La preservacion de `main` es una regla operativa de este flujo, no una proteccion remota ya instalada. CI/CD sigue pendiente; el pipeline futuro se disparara por push a ramas, sin requerir PR. No se despliega automaticamente ni se promete una proteccion inexistente. La plantilla de PR del bootstrap se retira del estado actual porque ya no forma parte del flujo solicitado.

## Versiones y releases

- Los commits identifican cambios; las ramas agrupan trabajo; los tags identifican releases. No son equivalentes.
- Reservar tags anotados `vMAJOR.MINOR.PATCH` para releases expresamente autorizadas sobre un commit revisado que cumpla su milestone. La autorizacion actual cubre pushes a ramas, no tags, releases o integraciones.
- Antes de 1.0 se esperan cambios de contratos; documentarlos y no alterar IDs canonicos publicados sin el procedimiento correspondiente.
- Objetivos del informe: `v0.1.0` Content Foundation (10º Gup con persistencia y API), `v0.2.0` Identity & Grade Access y `v0.3.0` Web. Ninguno esta publicado.
- No crear `v0.1.0` por terminar schemas, por tener `tools/validators` en version 0.1.0 ni por actualizar la version del informe tecnico.
- Para una beta futura, usar un identificador previo como `v0.3.0-beta.1` solo si ese es el milestone realmente evaluado y sus controles estan listos; es un ejemplo, no una fecha o release aprobada.

## Seguimiento vivo

Al cerrar cada bloque, actualizar la seccion 55 del informe: estado real, evidencia, tests y pendientes; ajustar la seccion 56 si cambia el siguiente bloque dentro del plan. Actualizar fecha/version e historial documental cuando corresponda, separandolos de la version del producto.

No marcar una tarea como terminada por generar un archivo: distinguir implementacion tecnica, cobertura real, aprobacion humana y publicacion. Las decisiones de arquitectura originales permanecen intactas salvo cambio explicado y acordado.
