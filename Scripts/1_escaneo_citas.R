# ==============================================================================
# FASE I: ESCANEO, EXTRACCIÓN Y CLASIFICACIÓN ALGORÍTMICA DE CITAS
# ==============================================================================
library(fs)
library(readr)
library(dplyr)
library(stringr)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base   <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen  <- file.path(ruta_base, "Libro2_politicas_publicas_2026/originales") # Carpeta con tus .qmd

# 🔄 MODIFICACIÓN: Definición limpia para guardar el reporte junto a tus .qmd
ruta_mapa   <- file.path(dir_origen, "mapa_maestro_citas_paginas.csv")

# 2. LEER Y CONSOLIDAR CAPÍTULOS
archivos_qmd <- dir_ls(dir_origen, regexp = "\\.qmd$", ignore.case = TRUE)

if (length(archivos_qmd) == 0) {
  stop("❌ Error: No se encontraron archivos .qmd en el directorio de origen.")
}

message(paste("🔍 Escaneando", length(archivos_qmd), "archivo(s) .qmd..."))
texto_completo <- paste(sapply(archivos_qmd, read_file), collapse = "\n")

# 3. EXPRESIONES REGULARES (REGEX) PARA CAPTURA
regex_parentetica <- "\\([A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\s&\\-]+,\\s*\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)"
regex_narrativa   <- "[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+(?:\\s+(?:y|&|et\\s+al\\.?|y\\s+cols\\.?|[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+))*\\s*\\(\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)"
regex_total       <- paste0(regex_parentetica, "|", regex_narrativa)

# 4. EXTRACCIÓN DE CITAS
citas_encontradas <- str_extract_all(texto_completo, regex_total) %>% unlist()
citas_unicas      <- sort(unique(citas_encontradas))

if (length(citas_unicas) == 0) {
  stop("⚠️ No se detectó ninguna cita. Verifica si el formato de texto plano coincide con las Regex.")
}

message(paste("✅ Se encontraron", length(citas_unicas), "citas únicas en el texto plano."))

# 5. CLASIFICACIÓN ALGORÍTMICA EN DF
df_citas <- data.frame(Cita_Original = citas_unicas, stringsAsFactors = FALSE) %>%
  mutate(
    # Detectar el tipo por el inicio del carácter
    Tipo = ifelse(str_detect(Cita_Original, "^\\("), "Parentética", "Narrativa"),
    
    # Evaluar complejidad: si tiene 'et al', 'cols', ';' o demasiadas comas
    Es_Compleja = case_when(
      str_detect(Cita_Original, "et\\s+al|cols|;") ~ TRUE,
      str_count(Cita_Original, ",") > 1  ~ TRUE,
      TRUE  ~ FALSE
    ),
    # Asignar a revisión manual o automatizable
    Categoria = ifelse(Es_Compleja, "Revision_Manual", "Automatizable"),
    
    # ➕ NUEVO: Columna comodín lista para que la use el Script 2
    Pagina_PDF = "No rastreado aún",
    
    # ➕ NUEVO: Columna vacía para tus claves (o para que las auto-rellene Zotero si usas esa función)
    Citekey_Zotero = "" 
  )

# 6. EXPORTACIÓN DEL MAPA MAESTRO UNIFICADO
# 🔄 MODIFICACIÓN: Seleccionamos el orden final de las columnas y guardamos un solo archivo
df_maestro <- df_citas %>% 
  select(Cita_Original, Tipo, Categoria, Pagina_PDF, Citekey_Zotero)

write_csv(df_maestro, ruta_mapa)

# 7. INFORME FINAL EN CONSOLA
message("\n📊 --- REPORTE DE EXTRACCIÓN ---")
message(paste("📂 Total de citas procesadas:", nrow(df_maestro)))
message(paste("📂 Automatizables (Simples):", sum(df_maestro$Categoria == "Automatizable")))
message(paste("📂 Revisión Manual (Complejas):", sum(df_maestro$Categoria == "Revision_Manual")))
message(paste("🎯 ¡Mapa Maestro generado con éxito en:", ruta_mapa))