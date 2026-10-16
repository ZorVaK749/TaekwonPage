# Ramas, revisiones y versionamiento

Este flujo organiza el trabajo de ZVK Tech sin cambiar la arquitectura de [informe_tecnico.md](../../informe_tecnico.md). La instruccion actual del responsable del proyecto es **trabajar y hacer push en ramas, e integrar periodicamente checkpoints revisados en `main`, sin Pull Requests**. Sustituye la prohibicion anterior de merges; no autoriza merges ciegos por cada push, force-push, tags o deploy automatico. No se crea `develop` ni se usa `git pull` para resolver divergencias sin revisar.

## Estado de la vinculacion

- Remoto `origin`: `https://github.com/ZorVaK749/TaekwonPage.git`.
- `main` local sigue `origin/main`; ambas partieron de `4908799` (`Initial commit`, solo `LICENSE` MIT). El checkpoint acumulado se integro y publico el 16-10-2026 mediante el merge de dos padres `1ab81e7`, con SHA remoto verificado. La constancia documental posterior se guarda en `main` como cierre de la misma operacion.
- Rama del baseline: `chore/project-baseline`. Los bloques siguientes conservan esa ascendencia en ramas derivadas; su upstream debe ser la rama remota homonima, nunca `origin/main` por accidente. La rama activa y el estado se registran en la seccion 55 del informe.
- La licencia se recupero del remoto sin cambiar su contenido.
- Baseline guardado en el commit local `83eb531` (`chore(repo): establish knowledge foundation baseline`): 91 archivos nuevos, sin PDFs, capturas o `node_modules`. Los JSON previos se conservaron sin modificar ni promover a contenido aprobado.
- El 16-10-2026 se publicaron cuatro ramas homonimas en GitHub: `chore/project-baseline`, `feat/tkd-008-tools-and-exercise-drafts`, `feat/tkd-012-exercise-source-evidence` y `chore/push-only-workflow`. Sus tips actuales ya estan contenidos en `main`, conservando los commits de avance. No se borraron referencias locales/remotas ni se creo una release.
- `.gitattributes` normaliza texto en Git: LF para texto y CRLF al extraer scripts Windows, en concordancia con `.editorconfig`. Los espacios finales de Markdown se permiten por sus saltos de linea intencionales.

Una rama no es una copia de seguridad de archivos sin commit. Antes de cambiar a otra rama, revisar `git status` y guardar los cambios de forma explicita; nunca usar reset/checkout forzado, clean o descartes para resolver conflictos sin autorizacion.

## Convencion de ramas

| Tipo | Ejemplo | Uso |
|---|---|---|
| `chore/` | `chore/project-baseline` | Preparacion y mantenimiento |
| `feat/` | `feat/tkd-009-gup-10-curriculum` | Entregable funcional o de conocimiento |
| `fix/` | `fix/content-source-reference` | Correccion acotada |
| `docs/` | `docs/sprint-1-progress` | Documentacion sin cambios funcionales |

Usar nombres ASCII en minusculas y un bloque coherente por rama. Objetivo: `main` actualizado y una rama activa de trabajo, no una rama nueva por archivo o por commit. No hacer desarrollo funcional habitual directamente en `main`; el push a `main` corresponde al cierre de una integracion revisada.

## Ciclo por bloque

1. Revisar el informe completo, el checklist y el estado Git antes de editar.
2. Con el directorio limpio y el checkpoint integrado, consultar el remoto y crear la rama desde `origin/main`:

   ```powershell
   git fetch origin
   git switch --no-track -c feat/nuevo-bloque origin/main
   ```

   La primera integracion ya esta completada: los bloques nuevos deben partir del `main` actualizado y no seguir apilandose sobre ramas antiguas. Si una rama remota avanzo de forma incompatible, detenerse y revisar la divergencia sin descartar trabajo; no ejecutar pull, rebase o force-push automaticamente.

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
8. Al cerrar un bloque coherente o antes de iniciar otra rama acumulativa, integrar un checkpoint revisado en `main` siguiendo la seccion siguiente. No abrir Pull Requests. Publicar o integrar borradores tecnicos no equivale a aprobar conocimiento marcial ni desplegar una pagina.

No se configuraron protecciones de ramas en GitHub. CI/CD sigue pendiente; el pipeline futuro se disparara por push a ramas o `main`, sin requerir PR. No se despliega automaticamente ni se promete una proteccion inexistente. La plantilla de PR permanece retirada.

## Integracion periodica en main

No esperar a tener veinte ramas o a completar toda la aplicacion: cerrar checkpoints tecnicos coherentes, con tests aplicables correctos y pendientes claramente documentados. Un Sprint 1 parcial puede integrarse como borrador revisado sin presentarlo como v0.1 terminada. El fallo esperado de `validate:content` por curriculum ausente debe seguir visible; no se oculta para simular aceptacion funcional.

1. Revisar el diff y el historial saliente, exclusiones de documentos/secretos, tests y estado limpio. Confirmar que `main` local coincide con `origin/main` tras `git fetch origin`; si no coincide, revisar antes de operar.
2. Reutilizar la rama del bloque y su historia; no crear una rama adicional solo para ejecutar el merge.
3. Integrar con commit de merge visible, conservando los commits de avance:

   ```powershell
   git switch main
   git merge --no-ff RAMA_REVISADA -m "merge(repo): integrate validated checkpoint"
   ```

   `RAMA_REVISADA` es un marcador. Si hay conflictos, detenerse y resolverlos con evidencia; no preferir automaticamente un lado ni descartar trabajo.
4. Ejecutar validaciones sobre el resultado integrado. Sin errores inesperados, hacer `git push origin main` y comprobar el SHA remoto. Sin PR, squash, reescritura de historia, tags o deploy.
5. Registrar la integracion y los resultados en el informe. Un commit documental breve de constancia posterior puede cerrarse en `main` como parte de la misma operacion; no usar esta excepcion para desarrollar funcionalidades directamente ahi.
6. En el siguiente bloque, partir del `main` actualizado en lugar de apilar mas ramas sobre avances sin integrar.

**Limpieza:** un merge no borra ramas. Tras comprobar que sus tips estan contenidos en `main`, las ramas se consideran cerradas. Su eliminacion local o remota requiere autorizacion explicita y nunca se hace con borrados forzados. Hasta autorizar la limpieza, se conservan las referencias existentes; no confundir numero de ramas historicas con trabajo sin integrar.

## Versiones y releases

- Los commits identifican cambios; las ramas agrupan trabajo; los tags identifican releases. No son equivalentes.
- Reservar tags anotados `vMAJOR.MINOR.PATCH` para releases expresamente autorizadas sobre un commit revisado que cumpla su milestone. La autorizacion actual cubre pushes e integraciones periodicas de checkpoints, no tags, releases o despliegues.
- Antes de 1.0 se esperan cambios de contratos; documentarlos y no alterar IDs canonicos publicados sin el procedimiento correspondiente.
- Objetivos del informe: `v0.1.0` Content Foundation (10º Gup con persistencia y API), `v0.2.0` Identity & Grade Access y `v0.3.0` Web. Ninguno esta publicado.
- No crear `v0.1.0` por terminar schemas, por tener `tools/validators` en version 0.1.0 ni por actualizar la version del informe tecnico.
- Para una beta futura, usar un identificador previo como `v0.3.0-beta.1` solo si ese es el milestone realmente evaluado y sus controles estan listos; es un ejemplo, no una fecha o release aprobada.

## Seguimiento vivo

Al cerrar cada bloque, actualizar la seccion 55 del informe: estado real, evidencia, tests y pendientes; ajustar la seccion 56 si cambia el siguiente bloque dentro del plan. Actualizar fecha/version e historial documental cuando corresponda, separandolos de la version del producto.

No marcar una tarea como terminada por generar un archivo: distinguir implementacion tecnica, cobertura real, aprobacion humana y publicacion. Las decisiones de arquitectura originales permanecen intactas salvo cambio explicado y acordado.
