# ==============================================================================
# SUBRUTINA: CONVERSIÓN MASIVA AUTOMÁTICA DE .DOCX A .QMD (FORMATO LIMPIO Y NOTAS)
# ==============================================================================
library(fs)
library(stringr)
library(readr)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base  <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen <- file.path(ruta_base, "Libro3_estancias_2026/originales")

# 2. DETECTAR TODOS LOS ARCHIVOS WORD EN LA CARPETA
archivos_docx <- dir_ls(dir_origen, regexp = "\\.docx$", ignore.case = TRUE)

if (length(archivos_docx) == 0) {
  stop("❌ Error: No se encontraron archivos .docx en la carpeta /originales")
}

message(paste("🔍 Se encontraron", length(archivos_docx), "archivos Word para convertir.\n"))

# 3. BUCLE DE CONVERSIÓN EN CADENA
for (archivo in archivos_docx) {
  # Obtener el nombre del archivo sin la extensión .docx (ej: "capitulo1")
  nombre_base <- str_remove(path_file(archivo), "\\.docx$")
  
  # Definir el nombre del nuevo archivo .qmd de salida
  archivo_qmd <- file.path(dir_origen, paste0(nombre_base, ".qmd"))
  
  message("⏳ Convirtiendo: ", path_file(archivo), " ──► ", paste0(nombre_base, ".qmd"))
  
  # Ejecutar el comando de Pandoc con parámetros de limpieza total
  comando_pandoc <- paste0(
    "pandoc \"", archivo, "\" ",
    "-f docx ",
    "-t markdown+smart ", # Convierte comillas y guiones tipográficos
    "--wrap=none ",        # Mantiene los párrafos en una sola línea para las Regex
    "-o \"", archivo_qmd, "\""
  )
  
  resultado <- system(comando_pandoc)
  
  # 📝 SUBRUTINA: Si Pandoc tuvo éxito, parchamos las notas al pie de ESTE capítulo
  if (resultado == 0) {
    texto_contenido <- read_file(archivo_qmd)
    
    # Busca todos los [^1] y los transforma en [^nombre_base_1] (ej: [^capitulo1_1])
    texto_contenido <- str_replace_all(texto_contenido, "\\[\\^(\\d+)\\]", paste0("[^", nombre_base, "_\\1]"))
    write_file(texto_contenido, archivo_qmd)
    
  } else {
    message("⚠️ Advertencia: Pandoc falló al procesar el archivo: ", path_file(archivo))
  }
}

message("\n🎉 ¡Conversión masiva completada con éxito!")
message("📂 Todos tus archivos tienen párrafos continuos, comillas limpias y notas al pie blindadas.")