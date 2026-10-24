# Citas documentales versionadas — V6

Edición local de Fase 1 para el conjunto de citas de una ficha o currículo **pendiente de revisión**. No cambia contenido marcial, requisitos, pasos, fuentes registradas, derechos o estados de aprobación. Una corrección documental no es aprobación de la escuela.

## Garantías

- `content_citation_revision` conserva conjunto anterior/nuevo, motivo, referencia local no verificada, usuario de conexión y fecha. Su baseline es una observación técnica, no revisión humana.
- Comparte `content_entry.draft_revision` con texto, requisitos y detalles. Cambiar evidencia vuelve obsoletas las versiones leídas antes; la siguiente operación debe releer y reconciliar, no incrementar el número a ciegas.
- `citation_identity` reserva para siempre cada ID observado a su ficha, incluso si se retira la cita. No se puede transferir o reaprovechar en otro contenido. Los IDs nuevos deben ser explícitos; no hay renombrado automático.
- Se valida el contrato de nueve campos, identidad/hash de fuente registrada, límites de página PDF, localizador por página o sección y unicidad. El folio impreso es independiente; `null` no se completa por cálculo.
- La operación reemplaza solo las citas del propietario solicitado, en una transacción. Permite intercambiar localizaciones ocupadas sin errores transitorios de unicidad. Un fallo revierte citas, reservas nuevas, contador e historial.
- La FK de citas de pasos mantiene las mismas columnas y propiedad, pero puede diferirse durante el reemplazo. Se valida antes de devolver: retirar una cita todavía enlazada a un paso falla. Para sustituirla: añadir la nueva conservando la vieja, revisar los enlaces de pasos con el editor de ejercicios y retirar después la no utilizada, en revisiones explícitas.
- Se bloquean las escrituras relevantes y el registro de fuentes durante la comprobación para evitar carreras con importaciones o cambios del total de páginas.

## Generar propuesta local

```powershell
node tools/seeders/export-citation-edit-sql.mjs --local-citation-edit RUTA_LOCAL.json
```

El JSON debe tener exactamente cinco campos. **Ejemplo sintético de prueba, no una cita real ni una corrección autorizada:**

```json
{
  "id": "fixture_tul",
  "expected_revision": 1,
  "citations": [
    {
      "id": "citation_import_tul",
      "content_id": "fixture_tul",
      "source_id": "source_import_fixture",
      "source_sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "pdf_page": 2,
      "printed_page": "Observed folio X",
      "section": null,
      "notes": "Synthetic correction only.",
      "review_status": "pending_human_review"
    }
  ],
  "reason": "Synthetic evidence pipeline test.",
  "operator_reference": "Unverified local test operator"
}
```

La CLI real usa `knowledge/sources/inventory.json`: el ejemplo sintético solo se usa en el harness de pruebas con su inventario aislado. Para una propuesta real, usar los IDs/hashes registrados y la versión actual. El comando valida y genera SQL, **sin conectar ni aplicar cambios**. La BD vuelve a comprobar referencias/límites al ejecutarlo. No guardar payloads personales ni SQL operativo generado en Git.

El conjunto nuevo no puede quedar vacío. Todas las citas deben pertenecer a la ficha solicitada y conservar `pending_human_review`. No se permite incluir rutas de archivos o campos bibliográficos: estos siguen en el registro de fuentes, fuera del alcance del editor.

## Pruebas y pendientes

`Test-Database.ps1` cubre upgrade V5 → V6 con borradores previos, baseline, swap de páginas, sección sin página, reserva de IDs retirados, enlaces de pasos, coexistencia con texto/requisitos y 37 rechazos SQL. Comprueba también la propiedad de citas en el editor de ejercicios aunque el llamador haya diferido la FK. Verifica recarga sin perder historial y rollback de evidencia/contador/reservas. Las demostraciones son sintéticas; no se corrigen las 51 citas reales.

Los snapshots históricos de citas usados por revisiones anteriores se conservan, no se reescriben al corregir evidencia. Hay que mantener el JSON editorial coherente; no hay sincronización automática BD → JSON ni revisión por el hecho de ejecutar SQL.

La referencia del operador sigue no verificada, sin identidad/RBAC funcionales. No se otorga edición general a `PUBLIC` ni se abre un endpoint. Los triggers son protección operativa, no defensa contra un superusuario que altere el esquema.

**Fase 1 sigue abierta:** evidencia de revisión/publicación, currículo real y seed aprobado, además de los modelos funcionales pendientes. El versionado de datos y citas ya está implementado; no sustituye los pendientes de Fase 0.
