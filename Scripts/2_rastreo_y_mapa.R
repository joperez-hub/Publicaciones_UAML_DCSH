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
dir_origen       <- file.path(ruta_base, "Libro2_politicas_publicas_2026/originales") # ◄— NUEVA RUTA DE INSUMOS
ruta_pdf         <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros/Libro2_politicas_publicas_2026/_book/Políticas-Públicas-y-Etnografía.pdf"
ruta_mapa        <- file.path(dir_origen, "mapa_maestro_citas_paginas.csv")
ruta_bib         <- file.path(dir_origen, "libro22026.bib")

# 2. CONTROL DE SEGURIDAD: VERIFICAR INSUMOS
if (!file_exists(ruta_pdf)) {
  stop("❌ Error: No se encontró el archivo PDF en la ruta especificada.")
}
if (!file_exists(ruta_mapa)) {
  stop("❌ Error: No se encuentra el archivo 'mapa_maestro_citas_paginas.csv' de la Fase I.")
}

# 3. EXTRAER TEXTO DEL PDF PÁGINA POR PÁGINA
message("📄 Cargando y extrayendo texto del PDF... Esto puede tomar unos segundos.")
texto_pdf   <- pdf_text(ruta_pdf)
num_paginas <- length(texto_pdf)
message(paste("✅ PDF cargado exitosamente. Total de páginas:", num_paginas))

# 4. LEER EL INVENTARIO DE CITAS
df_citas <- read_csv(ruta_mapa)

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

# 7. CONSTRUCCIÓN DEL MAPA MAESTRO + CRUCE INTELIGENTE CON ZOTERO (.BIB)
message("🗂️ Leyendo biblioteca de Zotero (.bib) para auto-rellenar claves...")

if (file_exists(ruta_bib)) {
  # Leer el archivo .bib como texto llano
  contenido_bib <- read_file(ruta_bib)
  
  # Extraer todas las llaves reales de Zotero (ej: @Perez2026)
  llaves_bib <- str_extract_all(contenido_bib, "@[a-zA-Z0-9_:\\-]+(?=\\{)") %>% 
    unlist() %>% 
    str_remove("@")
  
  # Función interna para emparejar una cita plana con una llave del .bib
  emparejar_con_bib <- function(cita_plana, lista_llaves) {
    # Extraer el apellido principal (primera palabra en mayúscula/acentos)
    autor <- str_extract(cita_plana, "[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+")
    # Extraer el año (4 dígitos continuos)
    anio  <- str_extract(cita_plana, "\\d{4}")
    
    if (is.na(autor) || is.na(anio)) return("")
    
    # Buscar una llave en Zotero que contenga el apellido Y el año (ignora mayúsculas)
    coincidencia <- lista_llaves[str_detect(tolower(lista_llaves), tolower(autor)) & 
                                   str_detect(lista_llaves, anio)]
    
    if (length(coincidencia) > 0) {
      return(paste0("[@", coincidencia[1], "]")) # Retorna el formato Quarto [@autor2026]
    }
    return("") # Si no encuentra, lo deja vacío para tu revisión manual
  }
  
  # Ejecutar el auto-relleno algorítmico
  df_maestro <- df_citas %>%
    rowwise() %>%
    mutate(Citekey_Zotero = emparejar_con_bib(Cita_Original, llaves_bib)) %>%
    ungroup() %>%
    select(Cita_Original, Tipo, Categoria, Pagina_PDF, Citekey_Zotero) %>%
    arrange(Cita_Original)
  
  message("✅ Auto-relleno completado usando el archivo .bib.")
  
} else {
  # Si por alguna razón no se encuentra el .bib, el script no se rompe, solo lo deja vacío
  message("⚠️ Advertencia: No se encontró el archivo .bib. La columna 'Citekey_Zotero' se creará vacía.")
  df_maestro <- df_citas %>%
    mutate(Citekey_Zotero = "") %>%
    select(Cita_Original, Tipo, Categoria, Pagina_PDF, Citekey_Zotero) %>%
    arrange(Cita_Original)
}

# 8. EXPORTAR RESULTADO FINAL
write_csv(df_maestro, ruta_mapa)

message("\n🎯 --- PROCESO COMPLETADO ---")
message("✅ El Mapa Maestro ha sido actualizado con páginas en:")
message("👉 ", ruta_mapa)
message("\n💡 PRÓXIMO PASO MANUAL:")
message("1. Abre ese CSV en Excel.")
message("2. En la columna 'Citekey_Zotero', escribe o pega la clave correspondiente (ej: [@Bourdieu1999]).")
message("3. Guarda el archivo y estaremos listos para la Fase IV (Sustitución masiva).")