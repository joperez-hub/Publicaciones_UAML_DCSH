# ============================================================
# Script: Extraer bibliografía por capítulo (Versión Corregida)
# Proyecto: Libro1_exploracion_internet_2026
# ============================================================

library(tidyverse)

# --- CONFIGURACIÓN ---
bib_global <- "assets/libro1_2026.bib"
directorio_capitulos <- "."  
directorio_salida <- "assets/"

# --- PRE-PROCESAMIENTO DEL BIB GLOBAL ---
message("📚 Leyendo y procesando bibliografía global...")
bib_lineas <- readLines(bib_global, warn = FALSE)
bib_texto <- paste(bib_lineas, collapse = "\n")

# Dividir el archivo en entradas individuales (separando por @ al inicio de línea)
entradas <- str_split(bib_texto, "(?m)^@")[[1]]
entradas <- entradas[nchar(str_trim(entradas)) > 0]

# Función corregida para extraer la clave de cada entrada
extraer_clave <- function(entrada) {
  # Tomar la primera línea de la entrada
  primera_linea <- str_split(entrada, "\n")[[1]][1]
  # Eliminar todo hasta la primera llave '{'
  clave <- str_replace(primera_linea, "^[^{]*\\{", "")
  # Eliminar todo desde la primera coma ',' en adelante
  clave <- str_replace(clave, ",.*$", "")
  return(str_trim(clave))
}

claves_globales <- map_chr(entradas, extraer_clave)

# --- FUNCIÓN PRINCIPAL ---
extraer_bibliografia_por_capitulo <- function() {
  
  todos_qmd <- list.files(path = directorio_capitulos, pattern = "\\.qmd$", full.names = TRUE)
  # Excluir archivos que no son capítulos principales
  capitulos <- todos_qmd[!str_detect(todos_qmd, "index|colofon|referencias|entrevista")]
  
  message("📑 Procesando ", length(capitulos), " capítulos...\n")
  
  for (cap in capitulos) {
    contenido <- readLines(cap, warn = FALSE)
    texto <- paste(contenido, collapse = "\n")
    
    # Regex robusta para capturar CUALQUIER citekey válido de Pandoc
    citekeys <- str_extract_all(texto, "(?<=@)[a-zA-Z0-9_\\-\\.\\:\\/\\#\\?\\&\\'\\+\\~\\%]+")[[1]]
    
    # Limpiar puntuación final que a veces se pega
    citekeys <- str_replace_all(citekeys, "[,;\\)\\]]+$", "") 
    citekeys <- unique(citekeys)
    
    nombre_base <- str_replace(basename(cap), "\\.qmd$", "")
    archivo_bib_cap <- file.path(directorio_salida, paste0(nombre_base, "_bib.bib"))
    
    if (length(citekeys) > 0) {
      # Filtrar entradas (comparación insensible a mayúsculas/minúsculas)
      indices <- which(tolower(claves_globales) %in% tolower(citekeys))
      entradas_filtradas <- entradas[indices]
      
      if (length(entradas_filtradas) > 0) {
        # Reconstruir el archivo .bib asegurando que cada entrada inicie con @
        texto_final <- str_c("@", entradas_filtradas, collapse = "\n\n@")
        writeLines(texto_final, archivo_bib_cap)
        message("✅ ", basename(cap), " → ", length(entradas_filtradas), " referencias extraídas")
      } else {
        message("⚠️  ", basename(cap), " → Citekeys encontrados, pero no coinciden con el .bib global")
      }
    } else {
      message("⚠️  ", basename(cap), " → Sin citas detectadas")
    }
  }
  
  message("\n========================================")
  message("🎉 Proceso completado exitosamente")
  message("========================================")
}

# --- EJECUTAR ---
extraer_bibliografia_por_capitulo()