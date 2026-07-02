# ==============================================================================
# INSTRUCTIVO DE USO - FASE I
# ==============================================================================
# 📝 DESCRIPCIÓN:
#    Este script escanea el contenido de texto plano de todos los archivos con 
#    extensión .qmd en un directorio específico. Utiliza Expresiones Regulares 
#    (Regex) para identificar citas parentéticas y narrativas, y genera un 
#    inventario inicial llamado "Mapa Maestro" en formato CSV.
#
# ⚙️ REQUISITOS PREVIOS:
#    - Tener instaladas las librerías: fs, readr, dplyr, stringr.
#    - Que los archivos .qmd existan en la ruta de origen.
#
# 📍 CONFIGURACIÓN DE RUTAS (Modificar antes de ejecutar):
#    - `ruta_base`: El directorio principal en tu computadora donde guardas tus 
#      proyectos editoriales (ej. "/Users/tu_usuario/Proyectos/Libros").
#    - `dir_origen`: La carpeta específica del libro actual que contiene los 
#      capítulos .qmd. Se construye automáticamente uniendo `ruta_base` con el 
#      nombre de la carpeta de tu libro.
#    - `ruta_mapa`: (Automático) Define dónde se guardará el archivo de salida
#      'mapa_maestro_citas_paginas.csv' (por defecto, dentro de `dir_origen`).
#
# 💾 PRODUCTO GENERADO:
#    Un archivo CSV con las citas únicas encontradas, clasificadas por tipo y 
#    por complejidad (Automatizable vs. Revisión Manual).
# ==============================================================================

# ==============================================================================
# FASE I: ESCANEO, EXTRACCIÓN Y CLASIFICACIÓN ALGORÍTMICA DE CITAS
# ==============================================================================
library(fs)
library(readr)
library(dplyr)
library(stringr)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base   <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen  <- file.path(ruta_base, "Libro3_estancias_2026")

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

# 🔥 MEJORA: Normalizar espacios y saltos de línea internos antes de obtener las únicas
citas_limpias      <- str_squish(citas_encontradas)
citas_unicas       <- sort(unique(citas_limpias))

if (length(citas_unicas) == 0) {
  stop("⚠️ No se detectó ninguna cita. Verifica si el formato de texto plano coincide con las Regex.")
}

message(paste("✅ Se encontraron", length(citas_unicas), "citas únicas limpias."))

# 5. CLASIFICACIÓN ALGORÍTMICA EN DF
df_citas <- data.frame(Cita_Original = citas_unicas, stringsAsFactors = FALSE) %>%
  mutate(
    Tipo = ifelse(str_detect(Cita_Original, "^\\("), "Parentética", "Narrativa"),
    Es_Compleja = case_when(
      str_detect(Cita_Original, "et\\s+al|cols|;") ~ TRUE,
      str_count(Cita_Original, ",") > 1  ~ TRUE,
      TRUE  ~ FALSE
    ),
    Categoria = ifelse(Es_Compleja, "Revision_Manual", "Automatizable"),
    Pagina_PDF = "No rastreado aún",
    Citekey_Zotero = "" 
  )

# 6. EXPORTACIÓN DEL MAPA MAESTRO UNIFICADO
df_maestro <- df_citas %>% 
  select(Cita_Original, Tipo, Categoria, Pagina_PDF, Citekey_Zotero)

write_csv(df_maestro, ruta_mapa)

message("\n📊 --- REPORTE DE EXTRACCIÓN ---")
message(paste("📂 Total de citas procesadas:", nrow(df_maestro)))
message(paste("📂 Automatizables (Simples):", sum(df_maestro$Categoria == "Automatizable")))
message(paste("📂 Revisión Manual (Complejas):", sum(df_maestro$Categoria == "Revision_Manual")))
message(paste("🎯 ¡Mapa Maestro generado con éxito en:", ruta_mapa))