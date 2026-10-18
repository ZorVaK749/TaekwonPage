# Importación local de borradores

```powershell
node tools/seeders/export-draft-sql.mjs --local-drafts
```

Produce SQL transaccional en stdout solo después de validar catálogos/citas con los contratos existentes. No importa PDFs, no publica, no aprueba ni modifica la BD. No redirigir su salida a una migración ni versionarla. Sin el argumento explícito falla sin producir SQL.

El test [Test-Database.ps1](../validators/Test-Database.ps1) consume la salida en una BD desechable. Véanse [modelo, límites y comandos](../../docs/database/README.md). Importar de nuevo no sobrescribe: los duplicados provocan rollback. El currículo todavía no se importa.
