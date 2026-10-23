# Importación local de borradores

```powershell
node tools/seeders/export-draft-sql.mjs --local-drafts
```

Produce SQL transaccional en stdout solo después de validar catálogos/citas con los contratos existentes. No importa PDFs, no publica, no aprueba ni modifica la BD. No redirigir su salida a una migración ni versionarla. Sin el argumento explícito falla sin producir SQL.

El test [Test-Database.ps1](../validators/Test-Database.ps1) consume la salida en una BD desechable. Véanse [modelo, límites y comandos](../../docs/database/README.md).

El exportador incluye currículos de trabajo con sus siete relaciones tipadas y citas propias. El contrato curricular no contiene título/descripción: la fila base usa el ID como nombre y una descripción técnica fija, no datos marciales añadidos. No existe aún un currículo real en `knowledge/`; el soporte se prueba con fixtures fuera de esa carpeta.

Reimportar exactamente los mismos datos es un no-op lógico (sin duplicados o actualizaciones). Si cambia una fila o la composición de citas, pasos o requisitos de una ficha existente, la operación falla y revierte toda la transacción. También detecta altas/bajas de relaciones, no solo cambios de texto. Puede agregar fichas nuevas sin modificar las anteriores; omitir una ficha entera no la elimina.

La importación bloquea escrituras de las tablas involucradas durante la transacción local para evitar carreras entre carga/comprobación. No usarla como herramienta de carga en caliente de producción. No hay `DELETE`, `TRUNCATE` ni `DO UPDATE` automático. Los conflictos muestran la tabla, no valores potencialmente sensibles.

Para una edición explícita de nombre/descripción de catálogo, existe [export-draft-edit-sql.mjs](export-draft-edit-sql.mjs), separado del importador. Requiere `--local-draft-edit RUTA_LOCAL.json`, versión esperada, motivo y referencia local no verificada del operador. Véanse [alcance e historial V2](../../docs/database/draft-revisions.md); no sirve para aprobar, publicar ni cambiar datos de subtipos o currículos.

Para requisitos de un Gup existente: [export-curriculum-edit-sql.mjs](export-curriculum-edit-sql.mjs) con `--local-curriculum-edit RUTA_LOCAL.json`. Reutiliza el contrato de siete categorías y genera una llamada transaccional al [flujo V3](../../docs/database/curriculum-revisions.md), con versión esperada e historial. No crea un programa escolar, no cambia citas ni aplica el SQL automáticamente.

Para posiciones, vocabulario o ejercicios/Tuls: [export-detail-edit-sql.mjs](export-detail-edit-sql.mjs) con `--local-detail-edit RUTA_LOCAL.json`. El [flujo V4](../../docs/database/catalog-detail-revisions.md) conserva nulos y campos escalares; el [flujo V5](../../docs/database/tul-revisions.md) incluye conteo/preparación/alcance/pasos y sus citas propias. Comparten revisión global y no sustituyen revisión marcial ni infieren secuencias.
