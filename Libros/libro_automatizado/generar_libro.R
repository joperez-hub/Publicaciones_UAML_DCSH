# ==============================================================================
# SCRIPT DE AUTOMATIZACIÓN - CAPÍTULOS Y ARCHIVO MAESTRO AUTOMÁTICO
# ==============================================================================

# 1. CONTROL DE RUTAS: Forzar a R a trabajar dentro de 'libro_automatizado'
if (!require("rstudioapi")) install.packages("rstudioapi")
library(rstudioapi)

ruta_script <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(ruta_script)

cat("Directorio de trabajo fijado en:\n", getwd(), "\n\n")

# 2. Cargar librerías de procesamiento
if (!require("tidyverse")) install.packages("tidyverse")
library(tidyverse)

# 3. Leer archivos y comprobar plantillas académicas
if (!file.exists("metadatos.csv")) {
  stop("Error: No encuentro 'metadatos.csv' en la carpeta actual.")
}
if (!file.exists("templates/plantilla_base.qmd")) {
  stop("Error: No encuentro 'templates/plantilla_base.qmd'.")
}
if (!file.exists("templates/plantilla_quarto.yml")) {
  stop("Error: No encuentro 'templates/plantilla_quarto.yml'.")
}

datos_capitulos <- read_csv("metadatos.csv", show_col_types = FALSE) %>% 
  mutate(across(everything(), ~ replace_na(as.character(.x), "")))

plantilla_capitulo <- readLines("templates/plantilla_base.qmd", warn = FALSE)
plantilla_quarto   <- readLines("templates/plantilla_quarto.yml", warn = FALSE)

# Vector para ir guardando los nombres de los archivos creados en orden
archivos_creados <- c()

# 4. Generar los capítulos .qmd individuales
cat("Generando capítulos con soporte de coautoría y metadatos extendidos...\n")
for (i in 1:nrow(datos_capitulos)) {
  fila <- datos_capitulos[i, ]
  
  # Registrar el nombre del archivo para el archivo maestro
  archivos_creados <- c(archivos_creados, fila$archivo_qmd)
  
  # --- BLOQUE 1: Procesar Coautores ---
  autores_yaml <- c()
  autores_indice <- c()
  autores_portadilla <- c()
  
  # Evaluamos al Autor 1
  if (fila$autor_1 != "") {
    autores_yaml <- c(autores_yaml, paste0("  - name: \"", fila$autor_1, "\"\n    affiliation: \"", fila$afiliacion_1, "\"\n    orcid: \"", fila$orcid_1, "\"\n    email: \"", fila$email_1, "\""))
    autores_indice <- c(autores_indice, fila$autor_1)
    
    texto_correo <- if(fila$email_1 != "") paste0(" Contacto: \\\\href{mailto:", fila$email_1, "}{", fila$email_1, "}") else ""
    autores_portadilla <- c(autores_portadilla, paste0("\\\\Large ", fila$autor_1, " \\\\footnote{", fila$semblanza_1, texto_correo, "}"))
  }
  
  # Evaluamos al Autor 2
  if ("autor_2" %in% names(fila) && fila$autor_2 != "") {
    autores_yaml <- c(autores_yaml, paste0("  - name: \"", fila$autor_2, "\"\n    affiliation: \"", fila$afiliacion_2, "\"\n    orcid: \"", fila$orcid_2, "\"\n    email: \"", fila$email_2, "\""))
    autores_indice <- c(autores_indice, fila$autor_2)
    
    texto_correo <- if(fila$email_2 != "") paste0(" Contacto: \\\\href{mailto:", fila$email_2, "}{", fila$email_2, "}") else ""
    autores_portadilla <- c(autores_portadilla, paste0("\\\\Large ", fila$autor_2, " \\\\footnote{", fila$semblanza_2, texto_correo, "}"))
  }
  
  # Evaluamos al Autor 3
  if ("autor_3" %in% names(fila) && fila$autor_3 != "") {
    autores_yaml <- c(autores_yaml, paste0("  - name: \"", fila$autor_3, "\"\n    affiliation: \"", fila$afiliacion_3, "\"\n    orcid: \"", fila$orcid_3, "\"\n    email: \"", fila$email_3, "\""))
    autores_indice <- c(autores_indice, fila$autor_3)
    
    texto_correo <- if(fila$email_3 != "") paste0(" Contacto: \\\\href{mailto:", fila$email_3, "}{", fila$email_3, "}") else ""
    autores_portadilla <- c(autores_portadilla, paste0("\\\\Large ", fila$autor_3, " \\\\footnote{", fila$semblanza_3, texto_correo, "}"))
  }
  
  texto_autores_yaml       <- paste(autores_yaml, collapse = "\n")
  texto_autores_indice     <- paste(autores_indice, collapse = " e ") 
  texto_autores_portadilla <- paste(autores_portadilla, collapse = " \\\\\\\\\n")
  
  # --- BLOQUE 2: Procesar Nuevos Metadatos Académicos ---
  lista_keywords <- str_split(fila$palabras_clave, ",")[[1]] %>% stringr::str_trim()
  lista_keywords <- lista_keywords[lista_keywords != ""] 
  texto_keywords_yaml <- paste0("  - \"", lista_keywords, "\"", collapse = "\n")
  
  texto_resumen_yaml <- stringr::str_replace_all(fila$resumen, "\n", "\n  ")
  
  # --- BLOQUE 3: Sustitución en la Plantilla del Capítulo ---
  contenido_final <- plantilla_capitulo %>%
    str_replace_all("__TITULO__", fila$titulo) %>%
    str_replace_all("__BLOQUE_AUTORES_YAML__", texto_autores_yaml) %>%
    str_replace_all("__AUTORES_INDICE__", texto_autores_indice) %>%
    str_replace_all("__BLOQUE_AUTORES_PORTADILLA__", texto_autores_portadilla) %>%
    str_replace_all("__CAPITULO_NUM__", fila$capitulo_num) %>%
    str_replace_all("__PAGINAS__", fila$paginas) %>%
    str_replace_all("__DOI__", fila$doi) %>%
    str_replace_all("__RESUMEN__", texto_resumen_yaml) %>%
    str_replace_all("__PALABRAS_CLAVE_YAML__", texto_keywords_yaml)
  
  writeLines(contenido_final, fila$archivo_qmd)
  cat("  -> Creado con éxito:", fila$archivo_qmd, "\n")
}

# ==============================================================================
# 5. CONFIGURACIÓN E INYECCIÓN AUTOMÁTICA DEL ARCHIVO MAESTRO (_quarto.yml)
# ==============================================================================
cat("\nActualizando el archivo maestro _quarto.yml de forma dinámica...\n")

# Construimos las líneas de capítulos con formato y sangría exacta de 8 espacios
# Ejemplo resultante: "        - capitulo_01.qmd"
lineas_capitulos_yaml <- paste0("        - ", archivos_creados, collapse = "\n")

# Reemplazamos la etiqueta en la plantilla de Quarto
quarto_final <- plantilla_quarto %>%
  str_replace_all("__LISTA_CAPITULOS_DINAMICA__", lineas_capitulos_yaml)

# Guardamos el archivo final directamente en la raíz
writeLines(quarto_final, "_quarto.yml")
cat("  -> ¡'_quarto.yml' reescrito y ordenado con éxito!\n")

cat("\n¡Todo listo! Capítulos creados e indexados automáticamente en el libro.\n")