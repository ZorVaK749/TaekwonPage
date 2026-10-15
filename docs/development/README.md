# Ramas, revisiones y versionamiento

Este flujo organiza el trabajo de ZVK Tech sin cambiar la arquitectura de [informe_tecnico.md](../../informe_tecnico.md). Se usa un flujo ligero: `main`, ramas cortas por bloque y Pull Requests. No se crea `develop` ni una rama permanente por version sin una necesidad concreta.

## Estado de la vinculacion

- Remoto `origin`: `https://github.com/ZorVaK749/TaekwonPage.git`.
- `main` local sigue `origin/main`; ambas parten de `4908799` (`Initial commit`, solo `LICENSE` MIT).
- Rama actual de preparacion: `chore/project-baseline`, creada desde la misma historia y sin upstream para evitar confundirla con `main`.
- La licencia se recupero del remoto sin cambiar su contenido.
- No se hizo commit del baseline, staging, push, merge, tag ni PR. Los archivos existentes siguen en el directorio de trabajo y no quedan protegidos por el historial hasta que se confirme un commit.

Una rama no es una copia de seguridad de archivos sin commit. Antes de cambiar a otra rama, revisar `git status` y guardar los cambios de forma explicita; nunca usar reset/checkout forzado, clean o descartes para resolver conflictos sin autorizacion.

## Convencion de ramas

| Tipo | Ejemplo | Uso |
|---|---|---|
| `chore/` | `chore/project-baseline` | Preparacion y mantenimiento |
| `feat/` | `feat/tkd-009-gup-10-curriculum` | Entregable funcional o de conocimiento |
| `fix/` | `fix/content-source-reference` | Correccion acotada |
| `docs/` | `docs/sprint-1-progress` | Documentacion sin cambios funcionales |

Usar nombres ASCII en minusculas, un bloque coherente por rama y un objetivo por PR. No hacer desarrollo habitual directamente en `main`.

## Ciclo por bloque

1. Revisar el informe completo, el checklist y el estado Git antes de editar.
2. Con el directorio limpio, actualizar `main` sin reescribir historia y crear la rama de trabajo:

   ```powershell
   git fetch origin
   git switch main
   git pull --ff-only
   git switch -c feat/tkd-009-gup-10-curriculum
   ```

   Este ejemplo es para trabajo futuro: **no ejecutarlo sobre el baseline actual sin commit**. Si no es posible el avance rapido, detenerse y revisar la divergencia; no forzar.

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
6. Cuando se autorice publicar: `git push -u origin NOMBRE_DE_RAMA` y abrir un PR hacia `main`, usando la plantilla. No enviar cambios sin revisar ni hacer force-push por defecto.
7. Revisar y fusionar el PR con validaciones y evidencias. La revision tecnica no sustituye la aprobacion marcial de la escuela o la revision de derechos.

Las protecciones de `main` (requerir PR, checks y restringir push directo) se recomiendan, pero **no estan configuradas** en GitHub por esta tarea. CI/CD tampoco esta implementado; los tests descritos se ejecutan localmente hasta incorporar GitHub Actions. No se promete una proteccion que aun no exista.

## Versiones y releases

- Los commits identifican cambios; las ramas agrupan trabajo; los tags identifican releases. No son equivalentes.
- Usar tags anotados `vMAJOR.MINOR.PATCH` sobre un commit revisado e integrado, solo cuando se cumplan los criterios de su milestone.
- Antes de 1.0 se esperan cambios de contratos; documentarlos y no alterar IDs canonicos publicados sin el procedimiento correspondiente.
- Objetivos del informe: `v0.1.0` Content Foundation (10º Gup con persistencia y API), `v0.2.0` Identity & Grade Access y `v0.3.0` Web. Ninguno esta publicado.
- No crear `v0.1.0` por terminar schemas, por tener `tools/validators` en version 0.1.0 ni por actualizar este informe a 1.1.
- Para una beta futura, usar un identificador previo como `v0.3.0-beta.1` solo si ese es el milestone realmente evaluado y sus controles estan listos; es un ejemplo, no una fecha o release aprobada.

## Seguimiento vivo

Al cerrar cada bloque, actualizar la seccion 55 del informe: estado real, evidencia, tests y pendientes; ajustar la seccion 56 si cambia el siguiente bloque dentro del plan. Actualizar fecha/version e historial documental cuando corresponda, separandolos de la version del producto.

No marcar una tarea como terminada por generar un archivo: distinguir implementacion tecnica, cobertura real, aprobacion humana y publicacion. Las decisiones de arquitectura originales permanecen intactas salvo cambio explicado y acordado.
