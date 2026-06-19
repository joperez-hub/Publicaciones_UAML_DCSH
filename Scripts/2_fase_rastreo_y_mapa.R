# ==============================================================================
# FASES II Y III: RASTREO DE CITAS EN PDF Y CREACIÓN DEL MAPA MAESTRO
# ==============================================================================
library(pdftools)
library(readr)
library(dplyr)
library(stringr)
library(fs)

# 1. CONFIGURACIÓN DE RUTAS (Actualizado a Libro 2)
ruta_base        <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
ruta_pdf         <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros/Libro2_politicas_publicas_2026/_book/Políticas-Públicas-y-Etnografía.pdf"
ruta_csv_entrada <- file.path(ruta_base, "citas_automatizables.csv")
ruta_mapa_salida <- file.path(ruta_base, "mapa_maestro_citas_paginas.csv")

# 2. CONTROL DE SEGURIDAD: VERIFICAR INSUMOS
if (!file_exists(ruta_pdf)) {
  stop("❌ Error: No se encontró el archivo PDF en la ruta especificada.")
}
if (!file_exists(ruta_csv_entrada)) {
  stop("❌ Error: No se encuentra el archivo 'citas_automatizables.csv' de la Fase I.")
}

# 3. EXTRAER TEXTO DEL PDF PÁGINA POR PÁGINA
message("📄 Cargando y extrayendo texto del PDF... Esto puede tomar unos segundos.")
texto_pdf   <- pdf_text(ruta_pdf)
num_paginas <- length(texto_pdf)
message(paste("✅ PDF cargado exitosamente. Total de páginas:", num_paginas))

# 4. LEER EL INVENTARIO DE CITAS
df_citas <- read_csv(ruta_csv_entrada)

# 5. FUNCIÓN DE BÚSQUEDA QUIRÚRGICA
buscar_pagina <- function(cita, texto_pdf) {
  paginas_encontradas <- c()
  
  for (i in seq_along(texto_pdf)) {
    # fixed() ignora sintaxis regex para buscar el texto exacto de forma veloz
    if (str_detect(texto_pdf[i], fixed(cita))) {
      paginas_encontradas <- c(paginas_encontradas, i)
    }
  }
  
  if (length(paginas_encontradas) == 0) return("No encontrada")
  return(paste(paginas_encontradas, collapse = ", "))
}

# 6. EJECUTAR EL RASTREO
message("🔍 Rastreando la ubicación de cada cita en el PDF...")
df_citas$Pagina_PDF <- sapply(df_citas$Cita_Original, buscar_pagina, texto_pdf)

# 7. CONSTRUCCIÓN DEL MAPA MAESTRO (Fase III)
message("🗂️ Generando Mapa Maestro unificado...")
df_maestro <- df_citas %>%
  mutate(Citekey_Zotero = "") %>% # Columna vacía para tus llaves de Zotero
  select(Cita_Original, Tipo, Categoria, Pagina_PDF, Citekey_Zotero) %>%
  arrange(Cita_Original)

# 8. EXPORTAR RESULTADO FINAL
write_csv(df_maestro, ruta_mapa_salida)

message("\n🎯 --- PROCESO COMPLETADO ---")
message("✅ El Mapa Maestro ha sido guardado en:")
message("👉 ", ruta_mapa_salida)
message("\n💡 PRÓXIMO PASO MANUAL:")
message("1. Abre ese CSV en Excel.")
message("2. En la columna 'Citekey_Zotero', escribe o pega la clave correspondiente (ej: [@Bourdieu1999]).")
message("3. Guarda el archivo y estaremos listos para la Fase IV (Sustitución masiva).")