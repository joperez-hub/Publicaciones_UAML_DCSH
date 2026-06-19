---
title: "Instructivo"
format: html
---

## Control de Ubicación de Tablas en Quarto

**Problema habitual:** LaTeX corta las tablas largas entre páginas o las desplaza lejos de su mención textual.

**Solución:** Uso de *divs* con el parámetro `tbl-location="H"`.

### La Sintaxis Base

Envuelve tu tabla Markdown (formato Grid o Pipes) dentro de un bloque de tres puntos `:::` con los siguientes atributos:

``` markdown
::: {#lbl-identificador tbl-cap="Título descriptivo de la tabla" tbl-location="H"}
| Columna A | Columna B |
| :---      | :---      |
| Dato 1    | Dato 2    |
:::
```

### Desglose de Parámetros

- **`#lbl-identificador`**: Define el ID único para referencias cruzadas (ej. `#tbl-visibilidad`).
- **`tbl-cap="..."`**: El pie de tabla (Caption). Quarto lo numerará automáticamente.
- **`tbl-location="H"`**: **(Clave)**
  - La **H mayúscula** proviene del paquete `float` de LaTeX.
  - Significa **"Strictly Here"**.
  - **Efecto:** Prohíbe a LaTeX mover la tabla a la siguiente página o al final del capítulo *si no es necesario*. Lo más importante: **evita que la tabla se corte a la mitad**.
  - *Nota:* Si la tabla no cabe en la página actual, `H` forzará a que la tabla *entera* salte a la página siguiente, dejando un espacio en blanco en la anterior. Esto es preferible a una tabla cortada.

### Referencia Cruzada en el Texto

Para llamar a la tabla dentro de tus párrafos, usa la sintaxis de arroba seguida del ID:

> Como se observa en los datos @tbl-visibilidad, la exposición marginal...

- *No escribas "(ver Tabla 1)". Escribe simplemente "@tbl-visibilidad". Quarto renderizará el número y el paréntesis según el estilo.*

### Recordatorio de Buenas Prácticas

- **Nunca** uses `\newpage` manual antes de una tabla si puedes usar `tbl-location="H"`. Deja que el algoritmo decida si necesita la nueva página.
- **Tamaño:** Si una tabla es excesivamente larga (más de una página entera), `tbl-location="H"` podría dar un error. En esos casos específicos, elimina la "H" y permite el flujo estándar, o divide la tabla en "Tabla 1a" y "Tabla 1b".

------------------------------------------------------------------------

## Actualizar repositorios

### Subir cambios (push)

- Ubicarte en el directorio del repositorio

`cd ruta/hacia/tu/repositorio/Publicaciones_UAML_DCSH`

- Verificar que estás en la rama principal

`git branch` Debe mostrar "\* main"

- Sincronizar con los cambios más recientes de GitHub (IMPORTANTE)

`git pull origin main`

- Realizar tus modificaciones en los archivos del repositorio

(editar archivos en tu editor de texto preferido)

- Ver qué archivos fueron modificados

`git status`

- Preparar los cambios para el commit (añadir al staging area)

`git add .` o específicamente `git add nombre_archivo.md`

- Registrar los cambios con un mensaje descriptivo

`git commit -m "docs: descripción breve del cambio realizado"`

- Subir los cambios a GitHub

`git push origin main`

- Ver el historial de commits recientes

`git log --oneline -5`

- Verificar que no hay cambios pendientes

`git status`

### Descargar cambios (pull)

### Incorporar cambios de un branch

## Cómo encontrar términos en terminal (bash)

Si el libro es muy largo y no quieres buscar página por página visualmente, aprovecha que estás en macOS y que Biber ya generó el archivo de bitácora.

Abre la terminal en la raíz de tu proyecto y ejecuta este comando para saber exactamente en qué archivo .qmd o línea falló:

\`grep -in "término" \*.qmd\`
