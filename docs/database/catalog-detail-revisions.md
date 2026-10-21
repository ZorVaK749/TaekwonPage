# Detalles versionados de posiciones y vocabulario — V4

Flujo local de Fase 1 para **borradores ya citados**. Permite editar los campos numéricos actuales de una posición o traducción/alias de vocabulario. No cambia IDs, tipo, nombre/descripción, citas, requisitos, pasos, estados o derechos. No añade coordenadas, medidas ni reglas marciales.

## Persistencia

- `content_detail_revision` guarda antes/después, snapshot de citas, motivo, operador local **no verificado**, usuario de conexión y fecha. El historial no se reescribe, borra ni trunca por el flujo ordinario.
- V4 captura una línea base observada para subtipos existentes; los nuevos la capturan al finalizar su construcción inicial. Puede tener revisión distinta de cero si ya hubo cambios textuales. No equivale a aprobación ni se cuenta como una edición.
- Texto, requisitos y detalles comparten `content_entry.draft_revision`. La cadena de ediciones debe ser contigua y sin revisiones duplicadas; una versión anterior se rechaza con `40001`.
- `revise_catalog_details(...)` comprueba tipo/estado, versión, campos y citas; actualiza datos, contador e historial atómicamente. Un rollback del llamador revierte todo.
- El cambio de detalles no puede alterar texto genérico. El editor textual sigue funcionando antes o después de una revisión técnica, sin perder historial.

## Generar una propuesta local

Leer la revisión actual y preparar un JSON local con exactamente seis campos. **Ejemplo sintético, no dato oficial de una posición:**

```json
{
  "id": "fixture_position",
  "expected_revision": 1,
  "content_type": "position",
  "details": {
    "front_percent": null,
    "rear_percent": null,
    "front_rotation_deg": null,
    "rear_rotation_deg": null
  },
  "reason": "Synthetic unknown-value test.",
  "operator_reference": "Unverified local test operator"
}
```

Para vocabulario, `content_type` es `vocabulary` y `details` contiene exactamente `translation` y `aliases`, por ejemplo `{"translation":"Synthetic translation","aliases":[]}`. El ID debe identificar una ficha de ese tipo en la BD.

```powershell
node tools/seeders/export-detail-edit-sql.mjs --local-detail-edit RUTA_LOCAL.json
```

El comando valida y genera SQL; **no conecta ni aplica cambios**. Reutiliza los contratos existentes, sin dependencias nuevas. La BD comprueba de nuevo el estado/versión y las reglas al ejecutarlo. No reintentar un conflicto cambiando el contador a ciegas, ni versionar payloads personales o SQL operativo generado.

### Valores permitidos

- Posición: los cuatro campos son obligatorios y numéricos o `null`. Los dos porcentajes son ambos desconocidos o ambos conocidos, entre 0 y 100 y con suma exacta 100 en PostgreSQL. Cada rotación conocida está en `[0, 360)`.
- `null` nunca se convierte en cero; no se completa una rotación a partir de otra. PostgreSQL conserva `NUMERIC`, sin reemplazarlo por flotantes de renderer. La tolerancia del validador JavaScript no sustituye la comprobación exacta SQL.
- Vocabulario: traducción no vacía y array de alias únicos/no vacíos. Se permite vaciar los alias explícitamente; su orden se conserva. No se inventan alias ni se asignan roles de aplicación desde términos marciales.

El formato de edición es una proyección de las columnas persistidas, no un nuevo catálogo marcial. Se mantiene el límite previo: la BD no distingue `biomechanics: null` de un objeto con todos sus componentes desconocidos; los JSON editoriales siguen conservando esa distinción.

## Recarga, pruebas y límites

Tras una edición explícita hay que mantener el JSON de trabajo coherente y respaldado por las citas actuales. La recarga antigua se rechaza; la actualizada conserva contador e historial. No hay sincronización automática BD → JSON ni aprobación humana por ejecutar SQL.

`Test-Database.ps1` verifica upgrade con datos V2 → V3 → V4, baselines, mezcla de revisiones textuales/técnicas, 36 rechazos SQL, decimales/UTF-8/nulos, rollback completo y recarga actualizada. El contexto Java también migra desde cero. Todos los cambios de demostración usan fixtures aislados, no contenido marcial real.

No se añade endpoint ni se abre la API. Los permisos generales de escritura siguen sin otorgarse a `PUBLIC`; este mecanismo local no reemplaza autenticación, permisos mínimos ni revisión de la escuela, ni protege contra un superusuario que altere triggers/esquema.

**Pendiente:** edición versionada de citas y de los datos propios de ejercicios/Tuls, evidencia de revisión/publicación, currículo real y seed aprobado. Fase 1 sigue abierta.
