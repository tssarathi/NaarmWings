################################################################################
# Server components for the dashboard                                          #
################################################################################
library(dplyr)
library(shiny)
library(leaflet)
library(jsonlite)

# Helper utilities ------------------------------------------------------------

#' Resolve a media path to an actual file (handles directory inputs)
#' @param path character path from the data set
#' @param pattern optional regex pattern for files of interest
#' @return character path to the resolved file or NULL if not found
resolve_media_path <- function(path, pattern = NULL) {
  if (is.null(path) || length(path) == 0) {
    return(NULL)
  }

  path <- as.character(path[1])
  if (is.na(path)) {
    return(NULL)
  }

  if (!nzchar(path) || tolower(path) %in% c("no audio data", "no image data")) {
    return(NULL)
  }

  # Path might be a directory in the CSV so try to pick the first matching file
  if (dir.exists(path)) {
    files <- list.files(path, pattern = pattern, ignore.case = TRUE, full.names = TRUE)
    if (length(files) == 0) {
      return(NULL)
    }
    return(files[1])
  }

  if (file.exists(path)) {
    return(path)
  }

  return(NULL)
}

#' Convert a filesystem media path to the exposed Shiny resource path
#' @param path filesystem path under Data/
#' @return web-accessible path using the bird-data resource prefix
to_web_media_path <- function(path) {
  sub("^Data/", "bird-data/", path)
}


#' The server function to pass to the shiny dashboard
server <- function(input, output, session) {
  #' State -------------------------------------------------------------------

  #' Reactive states and settable defaults
  state <- reactiveValues()

  #' @param ui_colors {list} List of colors used in the app.
  state$ui_colors <- list(
    "background" = "#FFFFFF",
    "lightgray" = "#E9E9EA",
    "gray" = "#A8A8B5",
    "darkgray" = "#949598",
    "foreground" = "#52525F",
    "accent" = "#2D8B57",      # Forest green for bird/nature theme
    "highlight" = "#7CB342"    # Light green for highlights
  )

  #' @param fonts {list} List of fonts used in the app.
  state$fonts <- list(
    "primary" = "'brandon-grotesque', 'Helvetica', 'Arial', sans-serif"
  )

  #' @param center_lat {numeric} The center latitude for the map
  state$center_lat <- -37.8136

  #' @param center_lng {numeric} The center longitude for the map
  state$center_lng <- 144.9631

  #' @param zoom_level {numeric} The initial zoom level
  state$zoom_level <- 12

  #' @param filter_species {character} Filter for bird species
  state$filter_species <- "All"

  #' @param filter_order {character} Filter for bird taxonomic order
  state$filter_order <- "All"

  #' @param filter_rarity {vector} Rarity categories to show
  state$filter_rarity <- c("Common", "Fairly Common", "Uncommon", "Rare", "Vagrant")

  #' @param filter_year_range {c(min, max)} Filter for observation years
  state$filter_year_range <- c(2015, 2019)

  #' @param filter_radius {c(min, max)} Distance range from center location in km
  state$filter_radius <- c(0, 10)

  #' Event handlers ----------------------------------------------------------

  # Handle incoming messages from Javascript (GPS location)
  observeEvent(input$js_set_loc, {
    print("Set incoming location from JS client")
    lat <- as.numeric(input$js_set_loc$lat)
    lon <- as.numeric(input$js_set_loc$lon)
    state$center_lat <- lat
    state$center_lng <- lon
    state$zoom_level <- 14
  })

  # Filter by species
  observeEvent(input$filter_species, {
    state$filter_species <- input$filter_species
  })

  # Filter by order
  observeEvent(input$filter_order, {
    state$filter_order <- input$filter_order
  })

  # Filter by rarity checkboxes
  observe({
    rarity_categories <- c()
    if (isTRUE(input$filter_common)) rarity_categories <- c(rarity_categories, "Common")
    if (isTRUE(input$filter_fairly_common)) rarity_categories <- c(rarity_categories, "Fairly Common")
    if (isTRUE(input$filter_uncommon)) rarity_categories <- c(rarity_categories, "Uncommon")
    if (isTRUE(input$filter_rare)) rarity_categories <- c(rarity_categories, "Rare")
    if (isTRUE(input$filter_vagrant)) rarity_categories <- c(rarity_categories, "Vagrant")
    state$filter_rarity <- rarity_categories
  })

  # Filter by year range
  observeEvent(input$filter_year_range, {
    state$filter_year_range <- input$filter_year_range
  })

  # Filter by radius
  observeEvent(input$filter_radius, {
    state$filter_radius <- input$filter_radius
  })

  #' Master data --------------------------------------------------------------

  # Load the bird sighting data
  bird_data <- load_bird_data()
  year_range <- range(bird_data$year, na.rm = TRUE)
  state$filter_year_range <- year_range

  # Update filter dropdowns with actual data
  observe({
    species_list <- c("All", get_species_list(bird_data))
    order_list <- c("All", get_order_list(bird_data))
    year_range <- range(bird_data$year, na.rm = TRUE)

    updateSelectInput(session, "filter_species", choices = species_list)
    updateSelectInput(session, "filter_order", choices = order_list)
    updateSliderInput(
      session,
      "filter_year_range",
      min = year_range[1],
      max = year_range[2],
      value = state$filter_year_range
    )
  })

  #' Filtered dataset reacting to user controls
  filtered_data <- reactive({
    filter_bird_data(
      bird_data,
      species = state$filter_species,
      order = state$filter_order,
      year_range = state$filter_year_range,
      radius_range = state$filter_radius,
      center_location = c(state$center_lat, state$center_lng),
      rarity_filters = state$filter_rarity
    )
  })

  #' Mapping -----------------------------------------------------------------

  #' Render the world map in a leaflet widget
  output$leaflet_map <- renderLeaflet({
    map_renderer(filtered_data(), state)
  })

  #' Observe map zoom and update map markers dynamically
  observe({
    data <- filtered_data()

    if (nrow(data) == 0) {
      leafletProxy("leaflet_map") %>%
        clearMarkers() %>%
        clearMarkerClusters() %>%
        leaflet::addMarkers(
          lat = state$center_lat,
          lng = state$center_lng,
          icon = map_symbol("location"),
          options = markerOptions(clickable = FALSE)
        ) %>%
        leaflet::setView(
          lng = state$center_lng,
          lat = state$center_lat,
          zoom = state$zoom_level
        )
      return()
    }

    marker_orders <- ifelse(is.na(data$order), "default", data$order)
    unique_orders <- unique(marker_orders)
    icon_lookup <- setNames(lapply(unique_orders, map_symbol), unique_orders)
    marker_icons <- unname(icon_lookup[marker_orders])

    leafletProxy("leaflet_map", data = data) %>%
      clearMarkers() %>%
      clearMarkerClusters() %>%
      # Bird Sighting Markers
      leaflet::addMarkers(
        ~ longitude, ~ latitude,
        icon = marker_icons,
        clusterOptions = leaflet::markerClusterOptions(
          disableClusteringAtZoom = 15,
          spiderfyOnMaxZoom = TRUE,
          removeOutsideVisibleBounds = TRUE,
          maxClusterRadius = 80
        ),
        clusterId = "bird_clusters",
        popup = ~ paste0(
          "<div class='bird-popup'>",
          "<h3>", commonName, "</h3>",
          "<p><em>", scientificName, "</em></p>",
          "<p><strong>Order:</strong> ", order, "</p>",
          "<p><strong>Family:</strong> ", family, "</p>",
          "<p><strong>Count:</strong> ", count, "</p>",
          "<p><strong>Date:</strong> ", date, "</p>",
          "<p><strong>Rarity:</strong> ", rarityCategory, "</p>",
          "</div>"
        )
      ) %>%
      leaflet::setView(
        lng = state$center_lng,
        lat = state$center_lat,
        zoom = state$zoom_level
      )
  })

  #' Handle marker clicks to show detailed information
  observeEvent(input$leaflet_map_marker_click, {
    clicked <- input$leaflet_map_marker_click
    req(clicked$lng, clicked$lat)

    data <- filtered_data()

    selected_bird <- data %>%
      filter(
        abs(longitude - clicked$lng) < 1e-5,
        abs(latitude - clicked$lat) < 1e-5
      ) %>%
      slice(1)

    if (nrow(selected_bird) > 0) {
      # Resolve media paths
      image_file <- resolve_media_path(
        selected_bird$imagePath,
        pattern = "\\.(png|jpg|jpeg|gif)$"
      )
      audio_file <- resolve_media_path(
        selected_bird$audioPath,
        pattern = "\\.(mp3|wav|ogg|m4a)$"
      )
      credits_file <- resolve_media_path(
        selected_bird$creditsPath,
        pattern = "\\.(json)$"
      )

      modal_children <- list(class = "bird-detail-modal")

      if (!is.null(image_file)) {
        modal_children <- c(
          modal_children,
          list(
            tags$div(
              class = "bird-image",
              tags$img(
                src = to_web_media_path(image_file),
                alt = selected_bird$commonName,
                style = "max-width: 100%; border-radius: 10px; margin-bottom: 15px;"
              )
            )
          )
        )
      }

      modal_children <- c(
        modal_children,
        list(
          tags$p(tags$em(selected_bird$scientificName)),
          tags$hr(),
          tags$p(tags$strong("Order: "), selected_bird$order),
          tags$p(tags$strong("Family: "), selected_bird$family),
          tags$p(tags$strong("Genus: "), selected_bird$genus),
          tags$p(tags$strong("Count: "), selected_bird$count),
          tags$p(tags$strong("Date: "), selected_bird$date),
          tags$p(tags$strong("Rarity: "), selected_bird$rarityCategory)
        )
      )

      if (!is.na(selected_bird$description) && nzchar(selected_bird$description)) {
        modal_children <- c(
          modal_children,
          list(
            tags$div(
              tags$hr(),
              tags$p(selected_bird$description)
            )
          )
        )
      }

      if (!is.null(audio_file)) {
        audio_children <- list(
          class = "bird-audio",
          tags$hr(),
          tags$h4("Bird Call"),
          tags$audio(
            controls = "controls",
            style = "width: 100%; margin: 10px 0;",
            tags$source(
              src = to_web_media_path(audio_file),
              type = "audio/mpeg"
            )
          )
        )

        if (!is.null(credits_file)) {
          credits <- jsonlite::fromJSON(credits_file)
          info <- credits$citation_info
          audio_children <- c(
            audio_children,
            list(
              tags$p(
                class = "audio-credits",
                style = "font-size: 12px; color: #666;",
                tags$a(
                  href = info$recording_url,
                  target = "_blank",
                  "Recording"
                ),
                " by ", info$recorder, " | ",
                tags$a(
                  href = info$license_url,
                  target = "_blank",
                  info$license_type
                )
              )
            )
          )
        }

        modal_children <- c(
          modal_children,
          list(do.call(tags$div, audio_children))
        )
      }

      modal_content <- do.call(tags$div, modal_children)

      showModal(modalDialog(
        title = selected_bird$commonName,
        modal_content,
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
    }
  })
}
