# ==============================================================================
# FASE I: ESCANEO Y EXTRACCIÓN - CORREGIDO (PRUEBA DE UN SOLO ARCHIVO)
# ==============================================================================
library(fs)
library(readr)
library(dplyr)
library(stringr)

# 1. CONFIGURACIÓN DE RUTAS (Apunta directo a tu archivo de prueba)
ruta_base       <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen      <- file.path(ruta_base, "Libro1_exploracion_internet_2026")

# AQUÍ defines el archivo específico con el que quieres experimentar:
archivo_prueba  <- file.path(dir_origen, "01_texto_convertido.qmd") 

# 2. LEER EL ARCHIVO ÚNICO
if (!file_exists(archivo_prueba)) {
  stop("❌ Error: No se encuentra el archivo .qmd especificado para la prueba.")
}

message(paste("🔍 Escaneando archivo de prueba:", path_file(archivo_prueba)))
texto_completo <- read_file(archivo_prueba)

# 3. EXPRESIONES REGULARES (REGEX) PARA CAPTURA
regex_parentetica <- "\\([A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\s&\\-]+,\\s*\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)"
regex_narrativa   <- "[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+(?:\\s+(?:y|&|et\\s+al\\.?|y\\s+cols\\.?|[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+))*\\s*\\(\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)"
regex_total       <- paste0(regex_parentetica, "|", regex_narrativa)

# 4. EXTRACCIÓN DE CITAS
citas_encontradas <- str_extract_all(texto_completo, regex_total) %>% unlist()
citas_unicas      <- sort(unique(citas_encontradas))

if (length(citas_unicas) == 0) {
  stop("⚠️ No se detectó ninguna cita en este archivo. Verifica si el formato de texto plano coincide con las Regex.")
}

message(paste("✅ Se encontraron", length(citas_unicas), "citas únicas en el texto plano."))

# 5. CLASIFICACIÓN ALGORÍTMICA EN DF (Corregido el error del '[')
df_citas <- data.frame(Cita_Original = citas_unicas, stringsAsFactors = FALSE) %>%
  mutate(
    Tipo = ifelse(str_detect(Cita_Original, "^\\("), "Parentética", "Narrativa"),
    Es_Compleja = case_when(
      str_detect(Cita_Original, "et\\s+al|cols|;") ~ TRUE,
      str_count(Cita_Original, ",") > 1  ~ TRUE,
      TRUE  ~ FALSE
    ),
    Categoria = ifelse(Es_Compleja, "Revision_Manual", "Automatizable")
  )

# 6. SEPARACIÓN Y EXPORTACIÓN DE INVENTARIOS
df_auto_sub   <- df_citas %>% filter(Categoria == "Automatizable")
df_manual_sub <- df_citas %>% filter(Categoria == "Revision_Manual")

write_csv(df_auto_sub, file.path(ruta_base, "citas_automatizables.csv"))
write_csv(df_manual_sub, file.path(ruta_base, "citas_revision_manual.csv"))

message("\n📊 --- REPORTE DE EXTRACCIÓN ---")
message(paste("📂 Citas Simples (Automatizables):", nrow(df_auto_sub), "-> 'citas_automatizables.csv'"))
message(paste("📂 Citas Complejas (Revisión Manual):", nrow(df_manual_sub), "-> 'citas_revision_manual.csv'"))
message("🎯 Fase I (Prueba unitaria) completada.")