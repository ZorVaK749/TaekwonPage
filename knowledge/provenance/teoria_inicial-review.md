# Primer lote de teoría — revisión pendiente

Estado: **pending_human_review**. Es un JSON de trabajo ubicado en el directorio previsto para el catálogo, no contenido canónico aprobado, temario oficial ni material publicado.

- [Catálogo de trabajo](../catalogs/teoria/teoria_inicial.json): tres elementos.
- [Citas de procedencia](teoria_inicial.json): seis referencias a dos copias del inventario.
- Método: consulta visual local de páginas PDF 2 y 6 de ambos manuales ONT mediante `Export-PdfPreview.ps1`; normalización breve y contraste de los puntos citados. Los hashes vinculan cada cita con la copia exacta observada.

## Alcance extraído

| ID | Evidencia por cada manual | Límite |
| --- | --- | --- |
| `def_taekwondo` | Página PDF 2, primer párrafo de la definición | Síntesis introductoria, no definición completa ni desglose etimológico |
| `fundador_taekwondo` | Página PDF 2, encabezado e inicio de la sección sobre Choi Hong Hi | Solo atribución de fundador, sin fechas ni biografía |
| `principios_taekwondo` | Página PDF 6, lista de principios | Nombres y orden, sin definiciones o romanización |

La síntesis recoge puntos comunes a ambas copias, sin elegir cuál prevalece. No se considera que los dos manuales sean testimonios independientes ni se resuelven divergencias de otras secciones. No se utilizó conocimiento general del modelo para completar datos.

Se preserva `def_taekwondo`, ya presente en el borrador previo. Se crean IDs específicos para fundador y principios, sin reutilizar los IDs más amplios `historia_choi_hong_hi_basica` y `reglas_dojang`, que abarcan datos distintos. Los archivos de la raíz permanecen intactos y no se consideran aprobados o migrados.

## Antes de publicar o asignar un grado

1. El revisor marcial debe cotejar cada frase con sus citas y aceptar, corregir o rechazar el lote. No hay aprobación humana registrada.
2. Confirmar con la escuela si corresponde incluir estos elementos en su currículo de 10º Gup. No se creó `gup_10` ni se asignaron requisitos automáticamente.
3. Revisar derechos para el uso y distribución previstos. Esta extracción breve no declara que los documentos o sus derivados estén autorizados para cualquier publicación.

Los folios impresos permanecen `null`: se usan páginas PDF desde 1, sin inventar equivalencias. No se almacenaron capturas ni PDFs en archivos versionables, ni se copiaron páginas completas.

## Punto de continuación

El validador comprueba este lote real sin publicar PDFs. `validate:content` sigue rechazando la ausencia de currículo. La [matriz teórica posterior](temario_teorico_10gup-review.md) añade etimología y clasificación en otro archivo, conservando estas tres fichas intactas. La infraestructura/backend avanzaron por autorización posterior, sin aprobar conocimiento; el bloque actual vuelve a Fase 0, no a 9º Gup.
