# ==============================================================================
# SUBRUTINA: CONVERSIÓN LIMPIA DE DOCX A MD/QMD (PREPARACIÓN DE INSUMO)
# ==============================================================================
library(fs)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base   <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen  <- file.path(ruta_base, "Libro2_politicas_publicas_2026")
archivo_docx <- file.path(dir_origen, "BrechaDigital.docx") # Tu archivo Word original
archivo_qmd  <- file.path(dir_origen, "01_BrechaDigital.qmd")   # El destino limpio

# 2. VERIFICACIÓN DE INSUMOS
if (!file_exists(archivo_docx)) {
  stop("❌ Error: No se encuentra el archivo .docx original en la ruta especificada.")
}

message("⏳ Iniciando conversión limpia de .docx a .qmd con Pandoc...")

# 3. EJECUCIÓN DE PANDOC CON PARÁMETROS DE LIMPIEZA
# Usamos '--wrap=none' para que no rompa las líneas de texto arbitrariamente (lo que arruinaría las Regex)
# Usamos '-t markdown_strict' o 'markdown' para evitar extensiones raras de Word
comando_pandoc <- paste0(
  "pandoc \"", archivo_docx, "\" ",
  "-f docx ",
  "-t markdown+smart ", # 'smart' convierte comillas tipográficas en comillas estándar
  "--wrap=none ",        # Mantiene los párrafos en una sola línea (crucial para buscar citas)
  "-o \"", archivo_qmd, "\""
)

# Ejecutar en el sistema
resultado <- system(comando_pandoc)

# 4. CONTROL DE CALIDAD e INFORME
if (resultado == 0) {
  message("✅ ¡Conversión exitosa!")
  message("📂 Archivo generado listo para escaneo: ", archivo_qmd)
  
  # Breve limpieza post-conversión (Opcional: corregir guiones largos o espacios dobles si es necesario)
  # Aquí el insumo ya está listo para el script 2_escaneo_citas.R
} else {
  message("❌ Error: Pandoc no pudo realizar la conversión. Asegúrate de tener Quarto/Pandoc instalado en tu sistema.")
}