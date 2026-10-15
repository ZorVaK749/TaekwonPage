# Consulta local de PDFs grandes

`Export-PdfPreview.ps1` permite inspeccionar páginas de un PDF que exceda el límite del lector del entorno. Usa `Windows.Data.Pdf`, integrado en Windows, sin instalar paquetes. No cambia el stack del producto ni es una dependencia de backend/frontend.

Requisitos: Windows con APIs PDF y Windows PowerShell 5.1. No es una herramienta portable de CI. Renderiza imágenes; no extrae texto, no hace OCR, no valida la integridad completa del documento ni aprueba contenido.

Desde PowerShell, en la raíz:

```powershell
& ./tools/ingestion/Export-PdfPreview.ps1 `
  -PdfPath './knowledge/sources/pdfs/291264914-Enciclopedia-Taekwondo.pdf' `
  -Pages @(3, 4, 5)
```

La salida informa el total de páginas y el directorio de imágenes. Por defecto crea una carpeta única bajo `knowledge/sources/local-previews/`, excluida de Git. Se puede indicar `-OutputDirectory` para usar una ruta local fuera del repositorio. El directorio no debe existir: nunca se sobrescriben vistas previas anteriores. Se validan todas las páginas antes de crear archivos, se eliminan duplicados y se permiten hasta 20 páginas por invocación. `-Width` controla el ancho entre 400 y 2400 píxeles.

Los números son **páginas PDF desde 1**, no folios impresos. Si se interrumpe una exportación pueden quedar imágenes parciales; no se elimina automáticamente el directorio.

Las imágenes derivadas conservan las restricciones documentales del original. No subirlas, publicarlas ni pasarlas a assets. La exclusión de Git no permite su redistribución ni protege una ruta alternativa elegida por el usuario: mantener cualquier salida dentro del directorio ignorado o fuera del repositorio. La herramienta no sustituye una revisión jurídica de derechos.
