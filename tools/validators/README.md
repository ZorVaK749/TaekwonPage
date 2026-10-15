# Validación del conocimiento

## JSON Schemas y procedencia (portable)

Requiere Node **24.x** para estas herramientas; no fija todavía versiones del futuro frontend. Dependencia directa de desarrollo: **Ajv 8.20.0**, necesaria para ejecutar JSON Schema 2020-12 con referencias locales. Tests con `node:test`, sin librería adicional. `package-lock.json` fija también las dependencias transitivas.

Desde la raíz (en Windows usar `npm.cmd` si PowerShell bloquea `npm.ps1`):

```powershell
npm.cmd --prefix tools/validators ci --ignore-scripts
npm.cmd --prefix tools/validators test
npm.cmd --prefix tools/validators run validate
npm.cmd --prefix tools/validators run validate:local
npm.cmd --prefix tools/validators run report
```

- `validate`: valida el inventario real y todos los `knowledge/provenance/*.json`, sin necesitar PDFs. Descubre recursivamente los JSON de `knowledge/catalogs/` y `knowledge/curricula/gups/`; si hay contenido, valida el conjunto enlazado y su procedencia.
- `validate:local`: además exige los PDFs locales, verifica tamaño, cabecera y SHA-256 por streaming, y detecta PDFs no inventariados.
- Una salida con cero citas o sin catálogos/currículos lo informa explícitamente: no significa que exista una foundation funcional.
- El CLI devuelve código 1 ante errores de entrada, esquemas, integridad o referencias. No modifica archivos ni publica datos.

Se pueden agregar conjuntos de citas de trabajo mediante argumentos repetibles:

```powershell
node tools/validators/validate-knowledge.mjs --provenance RUTA_LOCAL.json
node tools/validators/validate-knowledge.mjs --inventory INVENTARIO_LOCAL.json --provenance CITAS_LOCALES.json
node tools/validators/validate-knowledge.mjs --catalog CATALOGO_LOCAL.json --curriculum CURRICULO_LOCAL.json --provenance CITAS_LOCALES.json
npm.cmd --prefix tools/validators run validate:content
```

Las rutas explícitas se resuelven desde el directorio actual; rutas predeterminadas y esquemas, desde el script. `--inventory` cambia el documento validado, no la ubicación raíz de los PDFs del proyecto en modo local. Los documentos descubiertos se validan también cuando se pasan rutas adicionales. `--catalog`, `--curriculum` y `--provenance` son repetibles.

`validate:content` activa `--require-content`: exige al menos un catálogo y un currículo no vacíos, además de sus referencias/citas válidas. **Actualmente debe fallar**: existen catálogos reales de teoría, vocabulario y posiciones en revisión, pero todavía no hay currículo. Es un control de presencia y consistencia de borradores, no de completitud curricular o aprobación. Un archivo de Tul con `sequence_complete: false` sigue siendo un borrador parcial aunque pase validación técnica.

`--knowledge-root RUTA` permite validar otra carpeta documental con subdirectorios `sources/`, `provenance/`, `catalogs/`, `curricula/gups/` (deben existir). Los esquemas siguen siendo los del proyecto. Esa opción no cambia los PDFs del modo `--check-local-files`, que siempre comprueba la carpeta local del proyecto; es útil para tests y borradores aislados sin copiar PDFs.

Consultar [contratos y convenciones](../../knowledge/schemas/README.md). Los controles semánticos detectan referencias de fuente inexistentes, hashes cambiados, citas duplicadas y páginas fuera de rango. Cuando se suministra contenido, comprueban también IDs globales, referencias por tipo, citas de vuelta, porcentajes, ángulos y secuencias de pasos. **No validan precisión marcial, cada afirmación contra la página, completitud curricular, derechos ni aprobación humana.** Los lotes reales de [teoría](../../knowledge/provenance/teoria_inicial-review.md) y [vocabulario](../../knowledge/provenance/vocabulario_inicial-review.md) tienen tests de integración de trazabilidad, no de verdad marcial, y se comprueba su combinación. Las pruebas de casos inválidos usan fixtures sintéticos y los tests de CLI aíslan esos datos del contenido real.

## Resumen para revisión

`report` activa `--report-json`, valida primero y muestra un resumen JSON versionado con conteos, IDs pendientes, uso de fuentes y observaciones aún incompletas. No incluye descripciones marciales ni cambia archivos. `validation.status: passed` significa exclusivamente que pasó la validación técnica; `not_checked` enumera las comprobaciones humanas/jurídicas/curriculares que no realiza.

Para obtener solo JSON en stdout, sin el encabezado de npm:

```powershell
node tools/validators/validate-knowledge.mjs --report-json
node tools/validators/validate-knowledge.mjs --report-json --check-local-files
```

El modo sin PDFs informa `local_pdf_identities_checked: false`. Si se combina con `--require-content`, rechaza la ausencia de currículo y no emite un informe de éxito. Los registros de datos incompletos son indicadores para el revisor, no datos completados automáticamente. Este resumen no comprueba cobertura documental campo por campo ni convierte borradores en contenido canónico.

## Control PowerShell existente (sin dependencias)

Requiere PowerShell 5.1 o posterior y APIs integradas de .NET; no añade librerías al proyecto. Funciona sin cambiar el directorio actual.

Desde la raíz, validar registros sin necesitar los PDFs (por ejemplo, en un clon):

```powershell
powershell -NoProfile -File tools/validators/Test-SourceInventory.ps1
```

Comprobar también presencia, tamaño, cabecera y SHA-256 de todos los PDFs locales, y detectar PDFs sin registrar:

```powershell
powershell -NoProfile -File tools/validators/Test-SourceInventory.ps1 -CheckLocalFiles
```

Ejecutar pruebas con casos válidos e inválidos, sin tocar los PDFs reales:

```powershell
powershell -NoProfile -File tools/validators/Test-SourceInventory.Tests.ps1
```

El script lanza un error terminante ante incumplimientos; ejecutado con `-File` devuelve código distinto de cero al fallar. El modo sin `-CheckLocalFiles` **no comprueba integridad de PDFs**. Ningún modo valida sus páginas, autoría, derechos, exactitud marcial ni aprobación humana. La cabecera `%PDF-` no demuestra que el archivo sea un PDF íntegro o seguro.

Este control se conserva como comprobación independiente del inventario inicial, no como motor JSON Schema ni sustituto del CLI portable. Los contratos nuevos y sus campos adicionales se validan con Node/Ajv. TKD-004 sigue parcial y los validadores curriculares pendientes. Los parámetros `-RepositoryRoot` y `-InventoryPath` permiten pruebas aisladas. Los tests crean archivos sintéticos en un directorio temporal único y eliminan solo esos fixtures.
