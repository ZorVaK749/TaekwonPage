# Importación local de borradores

```powershell
node tools/seeders/export-draft-sql.mjs --local-drafts
```

Produce SQL transaccional en stdout solo después de validar catálogos/citas con los contratos existentes. No importa PDFs, no publica, no aprueba ni modifica la BD. No redirigir su salida a una migración ni versionarla. Sin el argumento explícito falla sin producir SQL.

El test [Test-Database.ps1](../validators/Test-Database.ps1) consume la salida en una BD desechable. Véanse [modelo, límites y comandos](../../docs/database/README.md).

El exportador incluye currículos de trabajo con sus siete relaciones tipadas y citas propias. El contrato curricular no contiene título/descripción: la fila base usa el ID como nombre y una descripción técnica fija, no datos marciales añadidos. No existe aún un currículo real en `knowledge/`; el soporte se prueba con fixtures fuera de esa carpeta.

Reimportar exactamente los mismos datos es un no-op lógico (sin duplicados o actualizaciones). Si cambia una fila o la composición de citas, pasos o requisitos de una ficha existente, la operación falla y revierte toda la transacción. También detecta altas/bajas de relaciones, no solo cambios de texto. Puede agregar fichas nuevas sin modificar las anteriores; omitir una ficha entera no la elimina.

La importación bloquea escrituras de las tablas involucradas durante la transacción local para evitar carreras entre carga/comprobación. No usarla como herramienta de carga en caliente de producción. No hay `DELETE`, `TRUNCATE` ni `DO UPDATE` automático: la edición versionada y la publicación requieren un flujo posterior explícito. Los conflictos muestran la tabla, no valores potencialmente sensibles.
