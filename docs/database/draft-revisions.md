# Edición textual versionada de borradores

Alcance de Fase 1: **solo `name` y `description` de fichas de catálogo ya citadas**. No cambia IDs, tipos, geometría, traducciones/alias, pasos, citas, requisitos curriculares ni estados. Los currículos (`gup`) se rechazan porque su nombre/descripción son etiquetas técnicas derivadas del contrato, no campos editoriales.

La [migración V2](../../backend/taekwonpage-api/src/main/resources/db/migration/V2__versioned_draft_text_edits.sql) añade:

- `content_entry.draft_revision`, inicialmente 0.
- `content_draft_revision`: revisión anterior/nueva, texto antes/después, motivo, referencia local del operador, usuario de conexión, fecha y snapshot de citas (incluido hash de copia).
- `revise_content_draft(...)`: bloquea la fila, comprueba versión esperada, escribe historial y actualiza el texto en una operación atómica.
- Barreras ante cambios textuales sin historial coincidente, historial reescrito/borrado/truncado, revisión inicial distinta de cero e historial sin aplicar. La edición sigue funcionando si el llamador tenía constraints en modo inmediato.

Una segunda edición sobre una versión vieja falla con SQLSTATE `40001`; hay que releer y reconciliar, **no reintentar a ciegas cambiando el número**. Un no-op, campos vacíos o falta de motivo/operador también se rechazan. Un rollback del llamador revierte texto, contador e historial juntos.

## Operación local explícita

No hay endpoint de edición. Para preparar SQL, leer primero el borrador y su `draft_revision` desde la BD local. Crear un JSON local con exactamente estos campos; este ejemplo es **sintético**, no una corrección marcial:

```json
{
  "id": "fixture_position",
  "expected_revision": 0,
  "name": "Edited synthetic draft",
  "description": "Synthetic text edit; not martial content.",
  "reason": "Synthetic pipeline test.",
  "operator_reference": "Unverified local test operator"
}
```

```powershell
node tools/seeders/export-draft-edit-sql.mjs --local-draft-edit RUTA_LOCAL.json
```

El comando valida el payload y produce una transacción SQL en stdout, **sin conectarse ni modificar nada**. Su aplicación requiere una sesión local autorizada y V2 aplicada; no guardar payloads operativos con datos personales ni SQL generado en Git. El test [Test-Database.ps1](../../tools/validators/Test-Database.ps1) ejecuta este recorrido en una BD desechable con fixtures.

Si se realiza una edición editorial real, mantener los JSON de trabajo y las citas coherentes en el mismo bloque, validar y solicitar revisión. Este mecanismo solo sirve cuando las citas actuales respaldan el texto: si también cambia la evidencia o un subtipo, detenerse hasta implementar su flujo, no usarlo como atajo. No hay sincronización automática BD → JSON.

## Identidad y publicación: límites importantes

`operator_reference` es una etiqueta local **no verificada**, no un usuario autenticado ni aprobación de la escuela. Se guarda expresamente `operator_verification = unverified_local_reference`, además del usuario real de conexión. No atribuir una acción a un revisor por ese campo.

Las funciones operan con permisos del llamador (`SECURITY INVOKER`), y no se otorgan permisos generales sobre historial ni ejecución a `PUBLIC`. El propietario/bootstrap local puede ejecutarlas; la asignación de permisos mínimos de aplicación pertenece al diseño de identidad pendiente. Los triggers previenen errores operativos, **no ofrecen protección contra un superusuario que los deshabilite o altere el esquema**.

Todo sigue `pending_human_review`, sin evidencia de aprobación/publicación implementada. La API continúa bloqueada. No se modifica ningún contenido real como demostración.

## Convivencia con el importador

- La carga inicial permanece en revisión 0; la recarga idéntica no incrementa revisiones.
- Tras una edición explícita, el snapshot viejo es rechazado por el importador.
- Un snapshot JSON actualizado que coincide se recarga sin borrar ni duplicar historial.
- No hay rollback editorial destructivo: una corrección posterior debe ser otra revisión explícita; el rollback transaccional solo anula cambios aún no confirmados.

Los requisitos curriculares tienen un [flujo V3 separado](curriculum-revisions.md). **Pendiente:** edición versionada de subtipos/citas, evidencia de revisión humana y derechos, publicación y permisos funcionales. Ninguno de estos mecanismos cierra por sí solo la Fase 1.
