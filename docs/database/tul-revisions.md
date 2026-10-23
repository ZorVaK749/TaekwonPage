# Ejercicios/Tuls versionados — V5

Fase 1, edición local de **borradores**. El tipo `tul` incluye ejercicios fundamentales; esta herramienta no los reclasifica como Tuls oficiales ni completa secuencias por conocimiento general.

## Alcance

- Edita conjuntamente conteo, preparación, estado de secuencia, alcance y lista de pasos/citas.
- Reutiliza `content_detail_revision`, su snapshot de citas, baseline observado y revisión global de la ficha. Puede alternarse con una edición textual sin perder historial.
- V5 añade el baseline de ejercicios existentes sin cambiar sus datos; los nuevos capturan el estado inicial al finalizar su construcción.
- No cambia IDs, título/descripción, posiciones de catálogo, citas documentales, currículo, derechos o estado de revisión. Las citas de pasos deben existir y pertenecer al mismo ejercicio.

## Generar SQL explícito

Usar `export-detail-edit-sql.mjs --local-detail-edit RUTA_LOCAL.json`, con los seis campos habituales y `content_type: "tul"`. **Ejemplo enteramente sintético, no una ejecución marcial:**

```json
{
  "id": "fixture_tul",
  "expected_revision": 0,
  "content_type": "tul",
  "details": {
    "movement_count": null,
    "initial_position_id": null,
    "sequence_complete": false,
    "sequence_scope": "Synthetic documented partial list.",
    "steps": [
      {
        "step_number": 1,
        "position_id": "fixture_position",
        "description": "Synthetic action only.",
        "citation_ids": ["citation_import_tul"]
      }
    ]
  },
  "reason": "Synthetic pipeline test.",
  "operator_reference": "Unverified local test operator"
}
```

El exportador valida y devuelve una transacción que llama a `revise_tul_draft(...)`; no conecta ni aplica cambios. Comprobar antes el estado real y la revisión, mantener el JSON editorial coherente y no guardar SQL/payloads operativos o personales en Git.

## Controles

- `movement_count` e `initial_position_id` pueden permanecer `null`; no se deduce el total del número de pasos ni se asigna una preparación por similitud.
- Una lista parcial no vacía exige `sequence_scope` explícito. Los números deben ser positivos, únicos y crecientes; los huecos solo pueden representar una lista parcial documentada.
- Una secuencia declarada completa exige conteo/preparación conocidos y todos los pasos consecutivos desde 1 hasta el total.
- Cada paso exige posición y descripción, y al menos una cita propia del ejercicio. La BD aplica las FKs tipadas; no toma citas de otra ficha como respaldo.
- El formato de edición requiere los cinco campos de `details`; el alcance desconocido se expresa con `null` cuando sea permitido. Los enteros están limitados al rango real de PostgreSQL.
- La operación reemplaza únicamente pasos y enlaces del ejercicio solicitado, dentro de una transacción. Difiere las comprobaciones mientras construye el nuevo estado y las verifica antes de devolver; un fallo tardío revierte datos, contador e historial.
- Cambios directos sin historial, truncados y versiones viejas se rechazan. El historial conserva también el alcance, la preparación y las citas asociadas a cada paso.

## Evidencia y pendientes

`Test-Database.ps1` comprueba upgrade con datos V4 → V5, secuencias sintéticas parciales/completas/vacías, mezcla de revisiones textuales/técnicas, 39 rechazos SQL, referencias de otro tipo/propietario, rollback y recarga actualizada. No modifica Saju Jirugi/Makgi reales: sus totales siguen desconocidos y las secuencias parciales.

La referencia del operador continúa no verificada; no equivale a revisión de la escuela. No se añade endpoint ni permiso general a `PUBLIC`. Las protecciones operativas no son defensa contra un superusuario que altere el esquema.

Falta edición de citas, evidencia de revisión/publicación, currículo real y seed aprobado. La herramienta no resuelve la laguna documental del punto 3 de Jirugi, los conteos o la ejecución alterna. Fase 0 y Fase 1 siguen abiertas.
