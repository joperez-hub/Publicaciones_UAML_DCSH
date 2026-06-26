# ==============================================================================
# FASE IV: SUSTITUCIÓN MASIVA AUTOMATIZADA DE TEXTO PLANO A @CITEKEYS
# ==============================================================================
library(readr)
library(dplyr)
library(stringr)
library(fs)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base    <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen   <- file.path(ruta_base, "Libro2_politicas_publicas_2026/originales")
dir_destino  <- file.path(ruta_base, "Libro2_procesado") # Carpeta segura de salida
ruta_mapa    <- file.path(ruta_base, "mapa_maestro_citas_paginas.csv")

# 2. CONTROL DE SEGURIDAD Y PREPARACIÓN DE CARPETAS
if (!file_exists(ruta_mapa)) {
  stop("❌ Error: No se encuentra el 'mapa_maestro_citas_paginas.csv'.")
}

if (!dir_exists(dir_destino)) {
  dir_create(dir_destino)
  message("✅ Carpeta de destino creada de forma segura en: ", dir_destino)
}

# 3. CARGAR EL MAPA MAESTRO Y FILTRAR DICCIONARIO
df_mapa <- read_csv(ruta_mapa) %>%
  # Filtrar solo las filas donde el usuario ingresó un Citekey (no vacío y no NA)
  filter(!is.na(Citekey_Zotero) & Citekey_Zotero != "")

if (nrow(df_mapa) == 0) {
  stop("⏸️ Operación cancelada: No se encontraron Citekeys cargados en la columna 'Citekey_Zotero'.")
}

message(paste("🗂️ Diccionario construido. Se procesarán", nrow(df_mapa), "reemplazos únicos."))

# 4. IDENTIFICAR ARCHIVOS .QMD A PROCESAR
# (Siguiendo tu flujo actual, procesará el archivo que esté en la carpeta origen)
archivos_qmd <- dir_ls(dir_origen, regexp = "\\.qmd$", ignore.case = TRUE)

if (length(archivos_qmd) == 0) {
  stop("❌ Error: No se encontraron archivos .qmd en la carpeta de origen.")
}

# 5. BUCLE DE SUSTITUCIÓN AUTOMÁTICA
for (archivo in archivos_qmd) {
  nombre_archivo <- path_file(archivo)
  message(paste("⏳ Procesando archivo:", nombre_archivo))
  
  # Leer el contenido completo del archivo original
  contenido <- read_file(archivo)
  
  # Aplicar los reemplazos uno por uno basados en el CSV
  for (i in 1:nrow(df_mapa)) {
    cita_plana <- df_mapa$Cita_Original[i]
    citekey    <- df_mapa$Citekey_Zotero[i]
    
    # fixed() es fundamental aquí para que caracteres como los paréntesis ( ) 
    # se traten como texto literal y no rompan la función como operadores regex
    contenido  <- str_replace_all(contenido, fixed(cita_plana), citekey)
  }
  
  # Definir la ruta final en la carpeta espejo de destino
  ruta_salida <- file.path(dir_destino, nombre_archivo)
  
  # Guardar el archivo transformado
  write_file(contenido, ruta_salida)
  message(paste("💾 Guardado con éxito en:", ruta_salida))
}

message("\n🎯 --- FASE IV COMPLETADA CON ÉXITO ---")
message("🚀 Tus archivos transformados con los @citekeys listos están en la carpeta 'Libro2_procesado'.")