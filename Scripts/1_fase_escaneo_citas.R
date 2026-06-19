# ==============================================================================
# FASE I: ESCANEO, EXTRACCIÓN Y CLASIFICACIÓN ALGORÍTMICA DE CITAS
# ==============================================================================
library(fs)
library(readr)
library(dplyr)
library(stringr)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base   <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen  <- file.path(ruta_base, "Libro1_exploracion_internet_2026") # Carpeta con tus .qmd

# 2. LEER Y CONSOLIDAR CAPÍTULOS
archivos_qmd <- dir_ls(dir_origen, regexp = "\\.qmd$", ignore.case = TRUE) [cite: 25]

if (length(archivos_qmd) == 0) {
  stop("❌ Error: No se encontraron archivos .qmd en el directorio de origen.") [cite: 25]
}

message(paste("🔍 Escaneando", length(archivos_qmd), "archivo(s) .qmd..."))
texto_completo <- paste(sapply(archivos_qmd, read_file), collapse = "\n") [cite: 25]

# 3. EXPRESIONES REGULARES (REGEX) PARA CAPTURA
# Parentética: Encuentra (Autor, Año) o (Autor, Año, p. X)
regex_parentetica <- "\\([A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\s&\\-]+,\\s*\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)" [cite: 25]

# Narrativa: Encuentra Autor (Año) o Autor et al. (Año)
regex_narrativa   <- "[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+(?:\\s+(?:y|&|et\\s+al\\.?|y\\s+cols\\.?|[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+))*\\s*\\(\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)" [cite: 25]

# Combinar ambas en un solo buscador
regex_total       <- paste0(regex_parentetica, "|", regex_narrativa) [cite: 25]

# 4. EXTRACCIÓN DE CITAS
citas_encontradas <- str_extract_all(texto_completo, regex_total) %>% unlist() [cite: 25]
citas_unicas      <- sort(unique(citas_encontradas)) [cite: 25, 26]

if (length(citas_unicas) == 0) {
  stop("⚠️ No se detectó ninguna cita. Verifica si el formato de texto plano coincide con las Regex.")
}

message(paste("✅ Se encontraron", length(citas_unicas), "citas únicas en el texto plano.")) [cite: 25, 26]

# 5. CLASIFICACIÓN ALGORÍTMICA EN DF
df_citas <- data.frame(Cita_Original = citas_unicas, stringsAsFactors = FALSE) %>% [cite: 26]
mutate(
  # Detectar el tipo por el inicio del carácter
  Tipo = ifelse(str_detect(Cita_Original, "^\\("), "Parentética", "Narrativa"), [cite: 26]
  
  # Evaluar complejidad: si tiene 'et al', 'cols', ';' o demasiadas comas
  Es_Compleja = case_when(
    str_detect(Cita_Original, "et\\s+al|cols|;") ~ TRUE, [cite: 26]
    str_count(Cita_Original, ",") > 1  ~ TRUE, [cite: 26]
    TRUE  ~ FALSE [cite: 26]
  ),
  # Asignar a revisión manual o automatizable
  Categoria = ifelse(Es_Compleja, "Revision_Manual", "Automatizable") [cite: 26]
)

# 6. SEPARACIÓN Y EXPORTACIÓN DE INVENTARIOS
df_auto_sub   <- df_citas %>% filter(Categoria == "Automatizable") [cite: 26, 27]
df_manual_sub <- df_citas %>% filter(Categoria == "Revision_Manual") [cite: 26, 27]

write_csv(df_auto_sub, file.path(ruta_base, "citas_automatizables.csv")) [cite: 24, 27]
write_csv(df_manual_sub, file.path(ruta_base, "citas_revision_manual.csv")) [cite: 24, 27]

message("\n📊 --- REPORTE DE EXTRACCIÓN ---")
message(paste("📂 Citas Simples (Automatizables):", nrow(df_auto_sub), "-> 'citas_automatizables.csv'")) [cite: 27]
message(paste("📂 Citas Complejas (Revisión Manual):", nrow(df_manual_sub), "-> 'citas_revision_manual.csv'")) [cite: 27]
message("🎯 Fase I completada con éxito.")