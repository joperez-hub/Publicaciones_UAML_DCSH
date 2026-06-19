# ==============================================================================
# PIPELINE MAESTRO: CONVERSIÓN, AUTO-CRUCE CON .BIB Y MIGRACIÓN GLOBAL DE CITAS
# 📘 MANUAL DE OPERACIÓN:
# ==============================================================================
# Este script automatiza la transformación de citas en texto plano provenientes
# de un archivo Word (.docx) hacia el formato nativo de etiquetas de Quarto 
# (ej: [@Bourdieu1999]), cruzando los datos con tu biblioteca de Zotero (.bib).
#
# 🛠️ REQUISITOS PREVIOS (Antes de correr el script):
#   1. Tener instalado Quarto/Pandoc en el sistema.
#   2. Tener tu archivo Word en la carpeta de origen con el nombre exacto 
#      configurado en la sección de rutas (ej: "manuscrito_completo.docx").
#   3. Haber exportado tu biblioteca de Zotero en formato .bib dentro de la 
#      misma carpeta del libro.
#
# 🚦 FLUJO DE TRABAJO EN DOS PASOS (Cómo usar este script):
#
# ▶️ PASO 1: LA PRIMERA EJECUCIÓN (Extracción y Predicción)
#   - Abre este script en RStudio y presiona "Source" (o ejecútalo completo).
#   - El sistema hará lo siguiente de forma automática:
#       a) Convertirá tu Word a un archivo .qmd limpio sin romper párrafos.
#       b) Parcheará las notas al pie agregándoles un prefijo único por capítulo 
#          (para que no choquen ni se repitan los números al compilar el libro).
#       c) Escaneará el texto buscando todas las citas (simples y complejas).
#       d) Leerá tu archivo .bib de Zotero e intentará "adivinar" y rellenar 
#          automáticamente los @citekeys en un archivo llamado:
#          'mapa_maestro_citas_paginas.csv' (guardado en la carpeta /Libros).
#   - Al finalizar, el script se detendrá y te pondrá un mensaje en espera.
#
# 📝 PASO 2: EL CONTROL DE CALIDAD HUMANO (Tu momento de revisión)
#   - Abre el archivo 'mapa_maestro_citas_paginas.csv' (puedes usar Excel).
#   - Revisa la columna 'Citekey_Zotero':
#       * Las citas que el sistema emparejó con éxito ya tendrán su [@clave].
#       * Las citas complejas (múltiples autores, et al.) podrían estar vacías.
#   - Tu única tarea aquí es rellenar o corregir las celdas vacías con su 
#     clave correspondiente. Si una cita tiene dos fuentes, puedes escribir: 
#     [@Clave1; @Clave2].
#   - Guarda los cambios y cierra el archivo CSV.
#
# ▶️ PASO 3: LA SEGUNDA EJECUCIÓN (Sustitución Masiva Segura)
#   - Vuelve a ejecutar este script en RStudio ("Source").
#   - El script detectará que el mapa ya no está vacío, leerá tus decisiones y
#     reemplazará en un segundo todo el texto plano por los @citekeys reales.
#   - GUARDADO SEGURO: El archivo modificado final se guardará en la carpeta 
#     '/Libros/Libro2_procesado'. Tus archivos originales nunca se tocan ni corren peligro.
#
# ==============================================================================

library(fs)
library(readr)
library(dplyr)
library(stringr)
library(pdftools)

# --- 1. CONFIGURACIÓN CENTRALIZADA DE RUTAS ---
ruta_base    <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen   <- file.path(ruta_base, "Libro2_politicas_publicas_2026")
dir_destino  <- file.path(ruta_base, "Libro2_procesado")

# Insumos específicos
archivo_docx <- file.path(dir_origen, "manuscrito_completo.docx") 
nombre_qmd   <- "01_texto_convertido.qmd"
archivo_qmd  <- file.path(dir_origen, nombre_qmd)
ruta_pdf     <- file.path(dir_origen, "_book/Políticas-Públicas-y-Etnografía.pdf")
ruta_bib     <- file.path(dir_origen, "libro22026.bib") # Tu archivo Zotero

# Reportes y Mapas
ruta_mapa    <- file.path(ruta_base, "mapa_maestro_citas_paginas.csv")

message("🚀 Iniciando Pipeline Maestro Inteligente de Citas...\n")

# --- 2. FASE 0: CONVERSIÓN LIMPIA Y PARCHE DE NOTAS AL PIE ---
if (file_exists(archivo_docx)) {
  message("⏳ [FASE 0] Convirtiendo .docx a .qmd de forma limpia con Pandoc...")
  comando_pandoc <- paste0("pandoc \"", archivo_docx, "\" -f docx -t markdown+smart --wrap=none -o \"", archivo_qmd, "\"")
  system(comando_pandoc)
  
  if (file_exists(archivo_qmd)) {
    message("📝 [FASE 0] Aplicando prefijos únicos a las notas al pie...")
    prefijo <- str_remove(nombre_qmd, "\\.qmd$")
    texto_notas <- read_file(archivo_qmd)
    texto_notas <- str_replace_all(texto_notas, "\\[\\^(\\d+)\\]", paste0("[^", prefijo, "_\\1]"))
    write_file(texto_notas, archivo_qmd)
    message("✅ Conversión y aislamiento de notas completado.")
  }
} else {
  message("ℹ️ [FASE 0] No se detectó archivo .docx nuevo. Se utilizará el .qmd existente.")
}

# --- 3. FASE I: ESCANEO Y EXTRACTOR DE CITAS ---
message("\n📋 [FASE 1] Escaneando archivo .qmd en búsqueda de citas...")
if (!file_exists(archivo_qmd)) {
  stop("❌ Error: No existe el archivo .qmd para analizar.")
}

texto_completo <- read_file(archivo_qmd)

regex_parentetica <- "\\([A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\s&\\-]+,\\s*\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)"
regex_narrativa   <- "[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+(?:\\s+(?:y|&|et\\s+al\\.?|y\\s+cols\\.?|[A-ZÁÉÍÓÚÑ][A-Za-záéíóúñ\\-]+))*\\s*\\(\\d{4}[a-z]?(?:,\\s*(?:p\\.|pp\\.)?\\s*\\d+(?:-\\d+)?)?\\)"
regex_total       <- paste0(regex_parentetica, "|", regex_narrativa)

citas_encontradas <- str_extract_all(texto_completo, regex_total) %>% unlist()
citas_unicas      <- sort(unique(citas_encontradas))

if (length(citas_unicas) == 0) {
  stop("⚠️ No se encontraron citas en el texto fuente.")
}

df_citas <- data.frame(Cita_Original = citas_unicas, stringsAsFactors = FALSE) %>%
  mutate(
    Tipo = ifelse(str_detect(Cita_Original, "^\\("), "Parentética", "Narrativa"),
    Es_Compleja = case_when(
      str_detect(Cita_Original, "et\\s+al|cols|;") ~ TRUE,
      str_count(Cita_Original, ",") > 1 ~ TRUE,
      TRUE ~ FALSE
    ),
    Categoria = ifelse(Es_Compleja, "Revision_Manual", "Automatizable")
  )

# --- 4. FASE II Y III: RASTREO EN PDF Y BASE DEL MAPA MAESTRO ---
if (file_exists(ruta_pdf)) {
  message("📄 [FASE 2] PDF detectado. Rastreando números de página...")
  texto_pdf <- pdf_text(ruta_pdf)
  
  buscar_pagina <- function(cita, texto_pdf) {
    paginas <- which(str_detect(texto_pdf, fixed(cita)))
    if (length(paginas) == 0) return("No encontrada")
    return(paste(paginas, collapse = ", "))
  }
  df_citas$Pagina_PDF <- sapply(df_citas$Cita_Original, buscar_pagina, texto_pdf)
} else {
  message("⚠️ [FASE 2] No se encontró el PDF. Se continuará sin mapeo de páginas.")
  df_citas$Pagina_PDF <- "PDF no compilado"
}

# --- 5. SUBRUTINA DE PARSEO INTELIGENTE DEL ARCHIVO .BIB ---
df_bib <- data.frame(Author = character(), Year = character(), Citekey = character(), stringsAsFactors = FALSE)

if (file_exists(ruta_bib)) {
  message("📚 [BIB SUBROUTINE] Leyendo archivo .bib de Zotero...")
  lineas_bib <- read_lines(ruta_bib)
  
  bib_texto <- paste(lineas_bib, collapse = "\n")
  entradas  <- str_split(bib_texto, "@[A-Za-z]+") %>% unlist()
  
  lista_autores <- c()
  lista_anios   <- c()
  lista_keys    <- c()
  
  for (e in entradas) {
    if (!str_detect(e, "^\\s*\\{")) next
    
    # Extraer el Citekey
    ckey <- str_extract(e, "^\\s*\\{\\s*[^,\\s\\}]+") %>% str_remove_all("[\\{\\s]")
    
    # Extraer campos year y author
    year   <- str_extract(e, "(?i)year\\s*=\\s*\\{?\\s*(\\d{4})") %>% str_extract("\\d{4}")
    author <- str_extract(e, "(?i)author\\s*=\\s*\\{\\s*([^\\}]+)\\}") %>% 
      str_remove_all("(?i)author\\s*=\\s*\\{\\s*|\\s*\\}")
    
    # Obtener el primer apellido limpio (antes de la primera coma o espacio)
    primer_apellido <- str_split(author, ",")[[1]][1] %>% str_trim()
    if (is.na(primer_apellido) || primer_apellido == "") {
      primer_apellido <- str_split(author, "\\s")[[1]][1] %>% str_trim()
    }
    primer_apellido <- str_remove_all(primer_apellido, "[\\{\\}'`^~\"’]") # Limpieza tipográfica
    
    if (!is.na(ckey) && !is.na(primer_apellido) && !is.na(year)) {
      lista_keys    <- c(lista_keys, ckey)
      lista_autores <- c(lista_autores, primer_apellido)
      lista_anios   <- c(lista_anios, year)
    }
  }
  df_bib <- data.frame(Author = lista_autores, Year = lista_anios, Citekey = lista_keys, stringsAsFactors = FALSE) %>% distinct()
  message(paste("✅ Catálogo de referencias cargado:", nrow(df_bib), "entradas válidas procesadas."))
} else {
  message("⚠️ No se encontró archivo .bib en la ruta. El mapeo automatizado de llaves no se realizará.")
}

# --- 6. CRUCE ALGORÍTMICO Y CONSOLIDACIÓN DEL MAPA MAESTRO ---
message("🗂️ [FASE 3] Consolidando Mapa Maestro unificado...")

# Función para intentar adivinar el Citekey de forma segura
adivinar_citekey <- function(cita_original) {
  # Extraer el año de la cita plana
  anio_cita <- str_extract(cita_original, "\\d{4}")
  if (is.na(anio_cita) || nrow(df_bib) == 0) return("")
  
  # Filtrar el .bib por el mismo año
  candidatos <- df_bib %>% filter(Year == anio_cita)
  if (nrow(candidatos) == 0) return("")
  
  # Buscar cuál apellido del .bib vive dentro de la cadena del texto plano
  for (j in 1:nrow(candidatos)) {
    apellido <- candidatos$Author[j]
    # Usamos coincidencia exacta ignorando mayúsculas/minúsculas
    if (str_detect(tolower(cita_original), tolower(apellido))) {
      return(paste0("[@", candidatos$Citekey[j], "]"))
    }