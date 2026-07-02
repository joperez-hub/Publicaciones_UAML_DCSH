# ==============================================================================
# INSTRUCTIVO DE USO - FASE IV: 
# ==============================================================================
# 📝 DESCRIPCIÓN:
#    Este es el script final y de producción. Lee el "Mapa Maestro" (CSV) ya 
#    revisado y completado por ti. Toma cada cita en texto plano y, mediante 
#    una expresión regular dinámica inmune a saltos de línea o dobles espacios, 
#    la reemplaza por su respectiva [@citekey] dentro de los archivos .qmd.
#
# 🔒 SEGURIDAD EN EL FLUJO:
#    El script NO altera tus archivos originales. Lee los .qmd de tu carpeta de 
#    trabajo y guarda las copias completamente transformadas en una carpeta 
#    "espejo" de destino seguro.
#
# ⚙️ REQUISITOS PREVIOS:
#    - Haber completado la revisión manual de las claves en el CSV ('Citekey_Zotero').
#
# 📍 CONFIGURACIÓN DE RUTAS (Modificar antes de ejecutar):
#    - `ruta_base` y `dir_origen`: Deben coincidir con los scripts anteriores.
#    - `ruta_mapa`: La ubicación del CSV final con las claves ya cargadas.
#    - `dir_destino`: Carpeta de salida segura (ej. "Libro2_procesado"). El script 
#      la creará automáticamente si no existe. Aquí es donde se depositarán los 
#      archivos listos para volver a renderizar, ahora con citas nativas de Quarto.
#
# 💾 PRODUCTO GENERADO:
#    Un set de archivos .qmd idénticos a los originales en estructura, pero con 
#    todas las citas en texto plano convertidas exitosamente al formato [@autor2026].
# ==============================================================================
# ==============================================================================
# FASE IV: SUSTITUCIÓN MASIVA AUTOMATIZADA DE TEXTO PLANO A @CITEKEYS
# ==============================================================================
library(readr)
library(dplyr)
library(stringr)
library(fs)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base    <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen   <- file.path(ruta_base, "Libro2_politicas_publicas_2026") 
ruta_mapa    <- file.path(dir_origen, "mapa_maestro_citas_paginas.csv")
dir_destino  <- file.path(ruta_base, "Libro2_procesado") 

if (!file_exists(ruta_mapa)) stop("❌ Error: No se encuentra el 'mapa_maestro_citas_paginas.csv'.")
if (!dir_exists(dir_destino)) dir_create(dir_destino)

# 3. CARGAR EL MAPA MAESTRO
df_mapa <- read_csv(ruta_mapa) %>%
  filter(!is.na(Citekey_Zotero) & Citekey_Zotero != "")

if (nrow(df_mapa) == 0) {
  stop("⏸️ Operación cancelada: No hay Citekeys para reemplazar.")
}

# Ordenar de la cita más larga a la más corta evita que sub-citas rompan textos mayores
df_mapa <- df_mapa %>% 
  mutate(longitud = nchar(Cita_Original)) %>% 
  arrange(desc(longitud))

archivos_qmd <- dir_ls(dir_origen, regexp = "\\.qmd$", ignore.case = TRUE)

# 5. BUCLE DE SUSTITUCIÓN MEJORADO (A PRUEBA DE ESPACIOS Y SALTOS DE LÍNEA)
for (archivo in archivos_qmd) {
  nombre_archivo <- path_file(archivo)
  message(paste("⏳ Procesando archivo:", nombre_archivo))
  
  contenido <- read_file(archivo)
  
  for (i in 1:nrow(df_mapa)) {
    cita_plana <- df_mapa$Cita_Original[i]
    citekey    <- df_mapa$Citekey_Zotero[i]
    
    # Transformar la cita plana en una regex tolerante a saltos de línea y múltiples espacios
    # Escapa caracteres especiales regex como ( ) [ ] . 
    cita_escapada <- str_replace_all(cita_plana, "([\\\\\\.\\+\\*\\?\\^\\$\\(\\)\\[\\]\\{\\}\\|])", "\\\\\\1")
    # Convierte cualquier espacio en un detector de "uno o más espacios o saltos de línea"
    regex_flexible <- str_replace_all(cita_escapada, "\\s+", "\\\\s+")
    
    # Reemplazo por regex flexible
    contenido <- str_replace_all(contenido, regex_flexible, citekey)
  }
  
  ruta_salida <- file.path(dir_destino, nombre_archivo)
  write_file(contenido, ruta_salida)
  message(paste("💾 Guardado con éxito en:", ruta_salida))
}

message("\n🎯 --- FASE IV COMPLETADA CON ÉXITO ---")