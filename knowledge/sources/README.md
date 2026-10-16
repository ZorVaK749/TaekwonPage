# Fuentes documentales locales

Los PDFs se mantienen en `knowledge/sources/pdfs/` para lectura local. `.gitignore` excluye ese directorio y cualquier archivo PDF del repositorio, incluso si se coloca por error en otra carpeta. No usar `git add -f` para eludir esta protección.

## Disponibilidad observada en Sprint 0

Se comprobaron existencia y cabecera `%PDF-` de estos cuatro archivos, no su contenido ni su autoridad documental:

- `291264914-Enciclopedia-Taekwondo.pdf`
- `TEORIA COMPLETA WEB.pdf`
- `Teoria ONT(2)(1).pdf`
- `Terminología de las formas.pdf`

La comprobación anterior corresponde al Sprint 0. En Sprint 1 se agregó [inventory.json](inventory.json), con cuatro IDs estables, hashes SHA-256, tamaños y metadatos observados, dejando explícitamente en `null` lo desconocido. Los cuatro tienen ya cobertura documental inicial; no implica lectura íntegra ni aprobación humana. La [ficha de la enciclopedia](../provenance/source_enciclopedia_taekwondo.md) detalla el alcance y su aviso de derechos reservados. Consulta el [contrato y los hallazgos de procedencia](../provenance/README.md) y los [comandos de validación](../../tools/validators/README.md).

## Uso y publicación

- La disponibilidad local no demuestra permiso de redistribución. No subir PDFs a GitHub sin autorización explícita.
- No se ha verificado la licencia de cada documento; tampoco se autoriza con este README la publicación de extractos o derivados.
- Un clon del repositorio no contiene estos archivos. Cuando se autorice trabajar con las fuentes, colocar las copias obtenidas legítimamente en `pdfs/` sin renombrar los originales innecesariamente.
- `.gitignore` no protege archivos que ya estuvieran versionados. Antes de cualquier publicación, revisar también el índice y el historial de Git. Tras el bootstrap se vinculó el remoto en una rama local; el historial inicial recuperado contiene solo la licencia, no PDFs. La situación de los cambios locales se documenta en el informe técnico.
- No extraer ni aprobar automáticamente contenido. Registrar fuente, página o sección, normalizar, contrastar, validar y someter a revisión humana antes de publicar.
- No copiar los valores ilustrativos del informe como hechos marciales.
- Las vistas previas generadas localmente permanecen en `local-previews/` (ignorado por Git) o fuera del repositorio. No son assets publicables por el hecho de haberlas generado nosotros. Véase la [herramienta de consulta local](../../tools/ingestion/README.md).

La procedencia estructurada se reservará en `knowledge/provenance/`, los esquemas en `knowledge/schemas/` y los datos aprobados en `knowledge/catalogs/` y `knowledge/curricula/gups/`. Su implementación queda fuera de Sprint 0.
