# ==========================================================
# SCRIPT: Crear nuevo proyecto de libro desde plantilla
# ==========================================================

# 1. Validar plantilla
plantilla_dir <- "pruebaintroduccion"
if(!dir.exists(plantilla_dir)) {
  stop("❌ No se encuentra la carpeta plantilla: ", plantilla_dir)
}

# 2. Solicitar nombre
message("\n📋 NOMENCLATURA: use guiones bajos o medios (ej. dossier_tecnologia_2026)")
nueva_carpeta <- readline(prompt = "📁 Nombre de la carpeta: ")

while(nchar(nueva_carpeta) < 3 || grepl("\\s", nueva_carpeta)) {
  message("⚠️  Mínimo 3 caracteres y sin espacios. Intente de nuevo.")
  nueva_carpeta <- readline(prompt = "📁 Nombre de la carpeta: ")
}

if(dir.exists(nueva_carpeta)) {
  stop("⚠️  Ya existe una carpeta con ese nombre.")
}

# 3. Copiar estructura (usando file.copy recursivo)
message("\n🔄 Duplicando estructura desde '", plantilla_dir, "'...")
dir.create(nueva_carpeta, showWarnings = FALSE, recursive = TRUE)

# Copiar todos los archivos y subcarpetas
archivos <- list.files(plantilla_dir, full.names = TRUE, recursive = TRUE, all.files = TRUE)
destinos <- gsub(plantilla_dir, nueva_carpeta, archivos, fixed = TRUE)

# Crear directorios de destino necesarios
dirs_destino <- unique(dirname(destinos))
for(d in dirs_destino) {
  if(!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# Copiar archivos
file.copy(archivos, destinos, overwrite = TRUE, copy.mode = TRUE)
message("✅ Estructura copiada")

# 4. Limpiar archivos/carpetas no deseados
excluir <- c("_book", ".git", ".gitignore")
for(item in excluir) {
  ruta <- file.path(nueva_carpeta, item)
  if(dir.exists(ruta)) {
    unlink(ruta, recursive = TRUE)
    message("🗑️  Eliminado: ", item)
  }
  if(file.exists(ruta) && item != "_book") {
    file.remove(ruta)
    message("🗑️  Eliminado: ", item)
  }
}

# Limpiar temporales de LaTeX
temps <- list.files(nueva_carpeta, pattern = "\\.(log|aux|toc|out|bbl|blg|fls|fdb_latexmk)$", full.names = TRUE)
if(length(temps) > 0) {
  file.remove(temps)
  message("🗑️  Eliminados archivos temporales de compilación")
}

# 5. Actualizar _quarto.yml (opcional)
personalizar <- readline(prompt = "\n✏️  ¿Actualizar título/coordinador en _quarto.yml? (s/n): ")
if(tolower(personalizar) == "s") {
  yml_file <- file.path(nueva_carpeta, "_quarto.yml")
  if(file.exists(yml_file)) {
    lineas <- readLines(yml_file, warn = FALSE)
    
    titulo_nuevo <- readline(prompt = "📖 Título del libro: ")
    lineas <- gsub('title: ".*"', paste0('title: "', titulo_nuevo, '"'), lineas)
    
    coordinador_nuevo <- readline(prompt = "👤 Coordinador: ")
    lineas <- gsub('editor: ".*"', paste0('editor: "', coordinador_nuevo, '"'), lineas)
    
    writeLines(lineas, yml_file)
    message("✅ _quarto.yml actualizado")
  }
}

# 6. Resumen final
message("\n", strrep("=", 60))
message("🎉 PROYECTO CREADO EXITOSAMENTE")
message("📁 Ubicación: ", normalizePath(nueva_carpeta))
message("📝 Siguiente paso: Abra esta carpeta en RStudio")
message(strrep("=", 60))

# Opcional: Abrir en Finder
abrir <- readline(prompt = "\n📂 ¿Abrir carpeta en el explorador? (s/n): ")
if(tolower(abrir) == "s") {
  if(Sys.info()["sysname"] == "Darwin") {
    system(paste("open", shQuote(normalizePath(nueva_carpeta))))
  } else if(Sys.info()["sysname"] == "Windows") {
    system(paste("explorer", shQuote(normalizePath(nueva_carpeta))))
  }
}