# =============================================================================
# Map layouts in the style of an ArcGIS Pro export
# Author: Yarida Kaewthong
#
# Landscape page: framed map with water, land, graticule, north arrow and
# scale bar; side panel with title, legend, Victoria locator map, method note
# and credits.
#
# Run melbourne_vru_analysis.R first (it writes gis_layers/).
# Coastline: ABS ASGS Edition 3 States and Territories 2021 (CC BY 4.0).
# =============================================================================

library(sf)
library(dplyr)
library(ggplot2)
library(cowplot)

# Measure text with the same engine that draws it (the default PDF device
# cannot load system fonts such as Segoe UI)
ragg::agg_png(tempfile(fileext = ".png"), width = 1600, height = 1000, res = 100)
set_null_device("agg")

proj_dir <- Sys.getenv("MELB_DIR", ".")   # run from the project folder, or set MELB_DIR
gis_dir  <- file.path(proj_dir, "gis_layers")
out_dir  <- file.path(proj_dir, "outputs")
crs_mga  <- 7855

navy  <- "#10233f"; muted <- "#4f5d70"
water <- "#c9dbe8"; land <- "#f4f3ef"; coast <- "#9fb4c6"; road_c <- "#a7b0bd"
body_font  <- "Segoe UI"      # clean, very readable
title_font <- "Bahnschrift"   # modern title face

hex    <- st_read(file.path(gis_dir, "hotspots_hex_1km.gpkg"), quiet = TRUE)
hex500 <- st_read(file.path(gis_dir, "inner_counts_hex_500m.gpkg"), quiet = TRUE)
roads  <- st_read(file.path(gis_dir, "main_roads.gpkg"), quiet = TRUE)

states <- st_read(file.path(proj_dir, "data_raw", "ste", "STE_2021_AUST_GDA2020.shp"), quiet = TRUE) |>
  filter(!st_is_empty(geometry))
vic <- states |> filter(STE_NAME21 == "Victoria") |> st_transform(crs_mga)
aus <- states |> filter(STE_NAME21 %in% c("Victoria", "New South Wales", "South Australia",
                                          "Australian Capital Territory")) |>
  st_transform(crs_mga) |> st_simplify(dTolerance = 2000)

place <- function(lon, lat, label) {
  st_sf(label = label, geometry = st_sfc(st_point(c(lon, lat)), crs = 4326)) |>
    st_transform(crs_mga)
}
towns <- bind_rows(
  place(144.9631, -37.8136, "Melbourne CBD"), place(144.9809, -37.8676, "St Kilda"),
  place(145.1278, -37.8183, "Box Hill"),      place(145.2161, -37.9875, "Dandenong"),
  place(144.9006, -37.7600, "Essendon"),      place(144.9925, -37.6450, "Epping"),
  place(144.7340, -37.8810, "Werribee"),      place(145.1100, -38.1430, "Frankston"),
  place(144.7880, -37.7470, "Sunshine"),      place(145.0310, -37.8530, "Prahran"),
  place(144.9420, -37.7990, "North Melbourne"), place(144.9930, -37.7990, "Fitzroy")
)
towns <- cbind(towns, st_coordinates(towns))
cbd <- st_coordinates(towns[towns$label == "Melbourne CBD", ])

# ---- Cartographic furniture -------------------------------------------------
north_arrow <- function(x, y, size) {
  tri_l <- data.frame(x = c(x, x - size * 0.35, x), y = c(y + size, y, y + size * 0.25))
  tri_r <- data.frame(x = c(x, x + size * 0.35, x), y = c(y + size, y, y + size * 0.25))
  list(
    geom_polygon(data = tri_l, aes(x, y), fill = navy, colour = navy, linewidth = 0.3),
    geom_polygon(data = tri_r, aes(x, y), fill = "white", colour = navy, linewidth = 0.3),
    annotate("text", x = x, y = y + size * 1.22, label = "N", fontface = "bold",
             size = 6, colour = navy, family = body_font)
  )
}

scale_bar <- function(x, y, km_steps, h) {
  m <- km_steps * 1000
  segs <- data.frame(x0 = head(m, -1), x1 = m[-1]) |>
    mutate(fill = rep(c(navy, "white"), length.out = n()))
  list(
    geom_rect(data = segs, aes(xmin = x + x0, xmax = x + x1, ymin = y, ymax = y + h),
              fill = segs$fill, colour = navy, linewidth = 0.3, inherit.aes = FALSE),
    annotate("text", x = x + m, y = y + h * 2.3, label = km_steps, size = 4.2, colour = navy, family = body_font),
    annotate("text", x = x + max(m) + h * 1.6, y = y + h * 2.3, label = "km",
             size = 4.2, colour = navy, hjust = 0, family = body_font)
  )
}

map_frame_theme <- function() {
  theme_minimal(base_size = 12, base_family = body_font) +
    theme(panel.background = element_rect(fill = water, colour = NA),
          panel.border = element_rect(fill = NA, colour = navy, linewidth = 0.9),
          panel.grid = element_line(colour = "#ffffff", linewidth = 0.25, linetype = "dashed"),
          axis.text = element_text(colour = muted, size = 10),
          axis.ticks = element_line(colour = navy, linewidth = 0.3),
          axis.ticks.length = unit(-0.12, "cm"),
          axis.title = element_blank(),
          legend.position = "none",
          plot.margin = margin(4, 26, 4, 4))
}

locator <- function(xlim, ylim) {
  box <- st_as_sfc(st_bbox(c(xmin = xlim[1], xmax = xlim[2], ymin = ylim[1], ymax = ylim[2]),
                           crs = crs_mga))
  vb <- st_bbox(vic)
  ggplot() +
    geom_sf(data = aus, fill = "#e3e3df", colour = "white", linewidth = 0.3) +
    geom_sf(data = vic, fill = "#c3cbd4", colour = navy, linewidth = 0.3) +
    geom_sf(data = box, fill = NA, colour = "#c0392b", linewidth = 1) +
    annotate("text", x = mean(c(vb["xmin"], vb["xmax"])) - 60000, y = vb["ymax"] - 230000,
             label = "VICTORIA", size = 3.6, colour = navy, fontface = "bold", family = body_font) +
    coord_sf(xlim = c(vb["xmin"] - 20000, vb["xmax"] + 20000),
             ylim = c(vb["ymin"] - 20000, vb["ymax"] + 20000), expand = FALSE, datum = NA) +
    theme_void() +
    theme(panel.background = element_rect(fill = water, colour = navy, linewidth = 0.6))
}

text_grob <- function(txt, size, face = "plain", colour = navy, lineheight = 1.2, family = body_font) {
  ggdraw() + draw_label(txt, x = 0, hjust = 0, vjust = 1, y = 1, size = size,
                        fontface = face, colour = colour, lineheight = lineheight,
                        fontfamily = family)
}

credits <- paste0("Data: Victoria road crash data, Department of Transport and Planning (CC BY 4.0). Coastline: ABS ASGS 2021 (CC BY 4.0).
",
                  "Coordinate system: GDA2020 / MGA Zone 55.   Map: Yarida Kaewthong, October 2026")

# Full-frame layout: title above, everything else (legend, locator, key finding,
# north arrow, scale bar) placed inside the map's empty areas, credits below
finish_map <- function(map, title, subtitle, legend_title, legend_pos) {
  map +
    labs(title = title, subtitle = subtitle, caption = credits, fill = legend_title) +
    guides(fill = guide_legend(override.aes = list(colour = NA))) +
    theme(plot.title = element_text(family = title_font, face = "bold", size = 28, colour = navy,
                                    margin = margin(b = 4)),
          plot.subtitle = element_text(size = 15, colour = muted, margin = margin(b = 12)),
          plot.caption = element_text(size = 9.5, colour = muted, hjust = 0, margin = margin(t = 10)),
          plot.title.position = "plot", plot.caption.position = "plot",
          legend.position = "inside", legend.position.inside = legend_pos,
          legend.title = element_text(face = "bold", colour = navy, size = 13),
          legend.text = element_text(colour = navy, size = 12),
          legend.key.size = unit(1.3, "lines"),
          legend.background = element_rect(fill = alpha("white", 0.95), colour = "#9aa7b8", linewidth = 0.4),
          legend.margin = margin(10, 12, 10, 12),
          plot.margin = margin(22, 26, 16, 18))
}

callout <- function(x, y, text, hjust = 0, vjust = 1) {
  annotate("label", x = x, y = y, label = text, hjust = hjust, vjust = vjust, family = body_font,
           size = 4.7, colour = navy, fill = alpha("white", 0.95), linewidth = 0.4,
           label.r = unit(0.25, "lines"), label.padding = unit(0.75, "lines"), lineheight = 1.2)
}

save_page <- function(page, file, w, h, card_file = NULL) {
  page <- ggdraw(page) + theme(plot.background = element_rect(fill = "white", colour = navy, linewidth = 1.4),
                               plot.margin = margin(12, 12, 12, 12))
  ggsave(file.path(out_dir, file), page, width = w, height = h, dpi = 220, device = ragg::agg_png, bg = "white")
  if (!is.null(card_file)) ggsave(file.path(out_dir, card_file), page, width = w, height = h,
                                  dpi = 110, device = ragg::agg_png, bg = "white")
}

clip_to <- function(x, xlim, ylim, pad = 5000) {
  st_crop(x, xmin = xlim[1] - pad, xmax = xlim[2] + pad, ymin = ylim[1] - pad, ymax = ylim[2] + pad)
}

# ---- Layout 1: metro hot spots ----------------------------------------------
xlim1 <- cbd[1] + c(-36000, 40000)
ylim1 <- cbd[2] + c(-46000, 24000)

hot_cols <- c("Hot spot, 99% confidence" = "#b2182b", "Hot spot, 95% confidence" = "#ef6548",
              "Hot spot, 90% confidence" = "#fdbb84")
hot <- filter(hex, class != "Not significant") |>
  mutate(class = factor(class, levels = names(hot_cols)))
hot <- suppressWarnings(st_intersection(hot, st_geometry(st_union(vic))))   # clip to the coastline
vic1 <- suppressWarnings(clip_to(vic, xlim1, ylim1))
roads1 <- suppressWarnings(clip_to(roads, xlim1, ylim1))
lab1 <- filter(towns, label %in% c("Melbourne CBD", "St Kilda", "Box Hill", "Dandenong", "Essendon",
                                    "Epping", "Werribee", "Frankston", "Sunshine"))

map1 <- ggplot() +
  geom_sf(data = vic1, fill = land, colour = coast, linewidth = 0.4) +
  geom_sf(data = roads1, colour = road_c, linewidth = 0.22) +
  geom_sf(data = hot, aes(fill = class), colour = "white", linewidth = 0.12, alpha = 0.92) +
  geom_label(data = lab1, aes(X, Y, label = label), size = 4.2, family = body_font, colour = navy, fill = "white",
             linewidth = 0, label.padding = unit(0.14, "lines"), alpha = 0.88, fontface = "bold") +
  annotate("text", x = cbd[1] - 1000, y = cbd[2] - 37500, label = "Port Phillip Bay",
           fontface = "italic", colour = "#5f7f99", size = 5.2, family = body_font) +
  callout(xlim1[1] + 0.27 * diff(xlim1), ylim1[1] + 0.31 * diff(ylim1),
          "KEY FINDING\nHalf of all pedestrian and\ncyclist crashes (49%) happen\nin the dark-red hot spots,\nwhich cover just 6% of the area.",
          hjust = 0.5, vjust = 0.5) +
  north_arrow(xlim1[1] + 5000, ylim1[2] - 11500, 6500) +
  scale_bar(xlim1[1] + 3500, ylim1[1] + 3500, c(0, 5, 10, 20), 900) +
  scale_fill_manual(values = hot_cols) +
  coord_sf(xlim = xlim1, ylim = ylim1, expand = FALSE, crs = crs_mga, default_crs = crs_mga, datum = 4326) +
  map_frame_theme()

map1 <- finish_map(map1, "Hot spots for people walking and cycling",
                   "Metro Melbourne  ·  Pedestrian and cyclist injury crashes, 2021 to 2025  ·  Getis-Ord Gi*, 1 km hexagons",
                   "Crash hot spots", c(0.86, 0.12))

page1 <- ggdraw(map1) + draw_plot(locator(xlim1, ylim1), x = 0.735, y = 0.655, width = 0.215, height = 0.2)
save_page(page1, "layout_hotspots_metro.png", 11, 11, card_file = "card_layout_metro.png")

# ---- Layout 2: inner Melbourne counts ---------------------------------------
xlim2 <- cbd[1] + c(-7000, 7000)
ylim2 <- cbd[2] + c(-8000, 6000)
count_cols <- c("1 to 5" = "#fde0d2", "6 to 10" = "#fcae91", "11 to 20" = "#fb6a4a",
                "21 to 40" = "#de2d26", "More than 40" = "#99000d")
hex500 <- mutate(hex500, band = factor(band, levels = names(count_cols)))
vic2 <- suppressWarnings(clip_to(vic, xlim2, ylim2, 2000))
roads2 <- suppressWarnings(clip_to(roads, xlim2, ylim2, 2000))
hex500 <- suppressWarnings(st_intersection(hex500, st_geometry(st_union(vic2))))   # clip to the coastline
lab2 <- filter(towns, label %in% c("Melbourne CBD", "St Kilda", "Prahran", "North Melbourne", "Fitzroy"))

map2 <- ggplot() +
  geom_sf(data = vic2, fill = land, colour = coast, linewidth = 0.4) +
  geom_sf(data = hex500, aes(fill = band), colour = "white", linewidth = 0.25, alpha = 0.9) +
  geom_sf(data = roads2, colour = "#6f7b8c", linewidth = 0.35) +
  geom_label(data = lab2, aes(X, Y, label = label), size = 4.4, family = body_font, colour = navy, fill = "white",
             linewidth = 0, label.padding = unit(0.14, "lines"), alpha = 0.9, fontface = "bold") +
  callout(xlim2[1] + 0.02 * diff(xlim2), ylim2[2] - 0.02 * diff(ylim2),
          "WORST 500 m HEXAGONS\nElizabeth St, CBD: 71, 56, 47 crashes\nChapel St, Prahran: 51, 46 crashes") +
  north_arrow(xlim2[1] + 0.69 * diff(xlim2), ylim2[2] - 1900, 1150) +
  scale_bar(xlim2[1] + 0.335 * diff(xlim2), ylim2[1] + 500, c(0, 1, 2), 150) +
  scale_fill_manual(values = count_cols) +
  coord_sf(xlim = xlim2, ylim = ylim2, expand = FALSE, crs = crs_mga, default_crs = crs_mga, datum = 4326) +
  map_frame_theme()

map2 <- finish_map(map2, "Inner Melbourne, street by street",
                   "Within 7 km of the CBD  ·  Pedestrian and cyclist injury crashes, 2021 to 2025  ·  500 m hexagons",
                   "Crashes per hexagon", c(0.15, 0.17))

page2 <- ggdraw(map2) + draw_plot(locator(xlim2, ylim2), x = 0.735, y = 0.655, width = 0.215, height = 0.2)
save_page(page2, "layout_inner_melbourne.png", 11, 11)

message("Done. Layouts in: ", out_dir)
