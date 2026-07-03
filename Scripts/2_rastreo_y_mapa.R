# ==============================================================================
# INSTRUCTIVO DE USO - FASES II Y III:
# ==============================================================================
# 📝 DESCRIPCIÓN:
#    Este script toma el "Mapa Maestro" (CSV) generado en la Fase I y realiza 
#    dos tareas inteligentes:
#    1. Escanea el archivo PDF ya renderizado del libro para buscar en qué 
#       páginas exactas aparece cada cita y registrarlo en el CSV.
#    2. Lee tu base de datos de Zotero exportada en formato BibTeX (.bib) y, 
#       mediante un algoritmo tolerante a acentos y mayúsculas, empareja el 
#       apellido del autor y el año de la cita para pre-llenar de forma 
#       automática la columna 'Citekey_Zotero' con el formato Quarto [@clave].
#
# ⚙️ REQUISITOS PREVIOS:
#    - Haber ejecutado con éxito la Fase I.
#    - Haber compilado/renderizado previamente el libro en PDF (sin citekeys aún).
#    - Exportar tus referencias desde Zotero en formato BibTeX (.bib) y guardarlo
#      en la carpeta del libro.
#    - Tener instalada la librería: pdftools (además de readr, dplyr, stringr, fs).
#
# 📍 CONFIGURACIÓN DE RUTAS (Modificar antes de ejecutar):
#    - `ruta_base` y `dir_origen`: Deben coincidir exactamente con el Script 1.
#    - `ruta_pdf`: La ruta absoluta hacia el archivo PDF renderizado de tu libro.
#      Por defecto apunta a la carpeta oculta de compilación '_book/'.
#    - `ruta_mapa`: La ubicación del CSV generado en la Fase I.
#    - `ruta_bib`: La ruta absoluta y nombre de tu archivo de referencias .bib.
#
# 💾 PRODUCTO GENERADO:
#    El mismo archivo 'mapa_maestro_citas_paginas.csv' es actualizado y enriquecido 
#    con los números de página del PDF y las propuestas de @citekeys de Zotero.
#
# 💡 PASO MANUAL CRÍTICO POST-EJECUCIÓN:
#    Antes de pasar al Script 3, debes abrir el CSV (en Excel o similar), revisar 
#    las sugerencias de 'Citekey_Zotero', rellenar manualmente las que hayan 
#    quedado vacías, guardar y cerrar el archivo.
# ==============================================================================

# ==============================================================================
# FASES II Y III: RASTREO DE CITAS EN PDF Y CREACIÓN DEL MAPA MAESTRO
# ==============================================================================
library(pdftools)
library(readr)
library(dplyr)
library(stringr)
library(fs)

# 1. CONFIGURACIÓN DE RUTAS
ruta_base        <- "/Users/omarperezbanos/Publicaciones_UAML_DCSH/Libros"
dir_origen       <- file.path(ruta_base, "Libro3_estancias_2026")
ruta_pdf         <- file.path(dir_origen, "_book/Título-de-la-obra.pdf")
ruta_mapa        <- file.path(dir_origen, "mapa_maestro_citas_paginas.csv")
ruta_bib         <- file.path(dir_origen, "Libro.bib")

if (!file_exists(ruta_pdf)) stop("❌ Error: No se encontró el archivo PDF.")
if (!file_exists(ruta_mapa)) stop("❌ Error: No se encuentra el CSV de la Fase I.")

# 3. EXTRAER TEXTO DEL PDF
message("📄 Cargando y extrayendo texto del PDF...")
texto_pdf   <- pdf_text(ruta_pdf)
texto_pdf_limpio <- str_squish(texto_pdf) # Limpieza para mejorar match
num_paginas <- length(texto_pdf)

# 4. LEER EL INVENTARIO DE CITAS
df_citas <- read_csv(ruta_mapa)

# 5. FUNCIÓN DE BÚSQUEDA EN PDF
buscar_pagina <- function(cita, texto_pdf) {
  paginas_encontradas <- c()
  cita_limpia <- str_squish(cita)
  for (i in seq_along(texto_pdf)) {
    if (str_detect(texto_pdf[i], fixed(cita_limpia))) {
      paginas_encontradas <- c(paginas_encontradas, i)
    }
  }
  if (length(paginas_encontradas) == 0) return("No encontrada")
  return(paste(paginas_encontradas, collapse = ", "))
}

message("🔍 Rastreando la ubicación de cada cita en el PDF...")
df_citas$Pagina_PDF <- sapply(df_citas$Cita_Original, buscar_pagina, texto_pdf_limpio)

# 7. CRUCE INTELIGENTE CON ZOTERO (CORREGIDO)
message("🗂️ Leyendo biblioteca de Zotero (.bib)...")

# Función auxiliar para remover acentos y simplificar comparación
quitar_acentos <- function(texto) {
  iconv(texto, to = "ASCII//TRANSLIT")
}

if (file_exists(ruta_bib)) {
  contenido_bib <- read_file(ruta_bib)
  
  # Regex mejorada para capturar llaves bibtex reales
  llaves_bib <- str_extract_all(contenido_bib, "@[a-zA-Z0-9_:\\-]+(?=\\s*\\{)") %>% 
    unlist() %>% 
    str_remove("@")
  
  emparejar_con_bib <- function(cita_plana, lista_llaves) {
    autor <- str_extract(cita_plana, "[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+")
    anio  <- str_extract(cita_plana, "\\d{4}")
    
    if (is.na(autor) || is.na(anio)) return("")
    
    # Normalizar para evitar fallos por acentos o mayúsculas
    autor_norm <- tolower(quitar_acentos(autor))
    llaves_norm <- tolower(quitar_acentos(lista_llaves))
    
    # Buscar coincidencia de autor Y año
    coincidencia <- lista_llaves[str_detect(llaves_norm, autor_norm) & str_detect(lista_llaves, anio)]
    
    if (length(coincidencia) > 0) {
      return(paste0("[@", coincidencia[1], "]")) 
    }
    return("") 
  }
  
  df_maestro <- df_citas %>%
    rowwise() %>%
    mutate(Citekey_Zotero = emparejar_con_bib(Cita_Original, llaves_bib)) %>%
    ungroup() %>%
    select(Cita_Original, Tipo, Categoria, Pagina_PDF, Citekey_Zotero) %>%
    arrange(Cita_Original)
  
  message("✅ Auto-relleno inteligente completado.")
} else {
  message("⚠️ Advertencia: No se encontró el archivo .bib.")
  df_maestro <- df_citas %>% mutate(Citekey_Zotero = "")
}

write_csv(df_maestro, ruta_mapa)
message("🎯 Proceso completado. Revisa tu CSV.")