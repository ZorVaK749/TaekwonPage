# Revisiones de requisitos curriculares — V3

Fase 1, flujo local de **borradores**. Permite reemplazar explícitamente las siete categorías de requisitos de un Gup existente. No cambia grado, ID, título técnico, citas, contenido de catálogo o estado de revisión; no aprueba ni publica un programa escolar.

## Persistencia y garantías

- `curriculum_draft_revision` guarda revisión previa/nueva, requisitos antes/después, snapshot de citas, motivo, referencia local **no verificada**, usuario de conexión y fecha.
- Cada Gup tiene una línea base **0**. V3 registra lo existente al actualizar una BD; los Gups nuevos reciben su baseline al confirmar la carga inicial. Es una observación técnica, no aprobación ni certificación de integridad marcial. Una línea base puede representar un borrador incompleto.
- `content_entry.draft_revision` se incrementa únicamente con historial coincidente. La revisión textual V2 sigue siendo exclusiva de catálogos; no se mezcla con revisiones de Gup.
- Las siete categorías son obligatorias; sus listas contienen IDs únicos, canónicos y del tipo correcto. Se permite alguna lista vacía, no las siete vacías. Los arrays se normalizan como conjuntos ordenados por ID: cambiar solo su orden no crea una revisión.
- `revise_curriculum_draft(...)` exige versión esperada, motivo y operador explícitos, además de citas del currículo ya registradas. Rechaza una versión vieja con SQLSTATE `40001`.
- Las relaciones se reemplazan en una transacción limitada al Gup solicitado, con bloqueos coordinados con el importador. Las FKs reales siguen comprobando cada subtipo; un fallo tardío también revierte relaciones e historial.
- Los cambios directos de relaciones que no coincidan con el último historial se rechazan al comprobar constraints. Historial no reescribible/borrable/truncable y prohibición de `TRUNCATE` en las relaciones curriculares. No es una barrera contra un superusuario que altere el esquema.

## Generar una propuesta local

Leer antes el Gup, sus requisitos y `draft_revision`. Preparar un JSON local con exactamente cinco campos. **Ejemplo sintético para pruebas, no currículo de Nahuel Aukan:**

```json
{
  "id": "gup_10",
  "expected_revision": 0,
  "requirements": {
    "position_ids": [],
    "theory_ids": [],
    "vocabulary_ids": [],
    "body_tool_ids": ["fixture_body_tool"],
    "kick_ids": [],
    "tul_ids": [],
    "combat_ids": []
  },
  "reason": "Synthetic requirements edit.",
  "operator_reference": "Unverified local test operator"
}
```

```powershell
node tools/seeders/export-curriculum-edit-sql.mjs --local-curriculum-edit RUTA_LOCAL.json
```

El exportador reutiliza el contrato curricular y produce SQL transaccional, sin conectar a BD ni aplicar cambios. La BD comprueba existencia/tipo de referencias, versión, citas y estado al ejecutarlo. No cambiar la versión a ciegas para vencer un conflicto: releer y reconciliar. No versionar payloads personales o SQL operativo generado.

La operación debe mantener coherencia con el JSON editorial y con la evidencia que ya está citada; cuando también cambien las citas, detenerse hasta implementar ese flujo. No hay sincronización automática BD → JSON ni revisión humana por el hecho de ejecutar SQL.

## Pruebas y límites

`Test-Database.ps1` carga datos sintéticos bajo V2, actualiza a V3 y verifica la captura del baseline. También prueba Gups nuevos, aislamiento entre currículos, reducción/restauración de las siete categorías, 30 rechazos SQL, fallo de FK después de iniciar escrituras, rollback de historial/relaciones y recarga del snapshot actualizado. El contexto Java prueba migración desde cero a V3.

La referencia del operador sigue `unverified_local_reference`; no es autenticación ni aprobación de la escuela. No se otorgan permisos generales de edición a `PUBLIC`, no se añade endpoint y la API permanece bloqueada. En desarrollo **no se carga ni modifica ningún currículo real**.

Posiciones/vocabulario ya tienen un [flujo de detalles V4](catalog-detail-revisions.md). Pendientes de Fase 1: citas y datos de ejercicios/Tuls, revisión/publicación, contraste con currículo real y seed aprobado. Se conserva el orden Fase 1 → retomar Fase 0 → Fase 2.
