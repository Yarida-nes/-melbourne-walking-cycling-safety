# =============================================================================
# Where and when are people walking and cycling most at risk in Melbourne?
# Author: Yarida Kaewthong
#
# Real Victorian road crash records (police and hospital data), metro Melbourne,
# 2012-2025. Focus: crashes involving pedestrians or cyclists.
#
#   1. Trend      - pedestrian and cyclist crashes per year, 2012-2025
#   2. Timing     - hour-of-day by day-of-week heat map
#   3. Severity   - chance of death or serious injury by speed zone and light
#   4. Hot spots  - Getis-Ord Gi* on a 1 km hexagon grid, 2021-2025
#
# Inputs (data_raw/):
#   victorian_road_crash_data.csv   Victoria road crash data (CC BY 4.0)
#   yearly_aadt_volume_2019.geojson Declared road network, used only as a map backdrop
#
# Data: Department of Transport and Planning, Victoria (CC BY 4.0).
# The data covers crashes where someone was injured or killed; crashes with
# property damage only are not included.
# =============================================================================

library(sf)
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)

proj_dir <- Sys.getenv("MELB_DIR", ".")   # run from the project folder, or set MELB_DIR
raw_dir  <- file.path(proj_dir, "data_raw")
out_dir  <- file.path(proj_dir, "outputs")
dir.create(out_dir, showWarnings = FALSE)

crs_mga <- 7855   # GDA2020 / MGA Zone 55, metres, correct zone for Melbourne

# Site palette
navy  <- "#10233f"; teal <- "#0e7c86"; muted <- "#5b6b80"
coral <- "#e07a5f"; light_line <- "#d5dce5"
ped_col  <- "#0e7c86"   # pedestrians
bike_col <- "#e07a5f"   # cyclists

theme_cv <- function(base = 15) {
  theme_minimal(base_size = base) +
    theme(plot.title.position = "plot", plot.caption.position = "plot",
          plot.title    = element_text(colour = navy, face = "bold", size = base + 2),
          plot.subtitle = element_text(colour = muted, margin = margin(b = 10)),
          plot.caption  = element_text(colour = muted, size = base - 5, hjust = 0),
          axis.text     = element_text(colour = muted),
          strip.text    = element_text(colour = navy, face = "bold", hjust = 0, size = base),
          panel.grid.minor = element_blank(),
          plot.margin   = margin(10, 25, 10, 10))
}
credit <- "Data: Victoria road crash data, Department of Transport and Planning (CC BY 4.0). Injury and fatal crashes only."

qlog <- tibble(step = character(), detail = character(), n = integer())
log_step <- function(step, detail, n) {
  qlog <<- add_row(qlog, step = step, detail = detail, n = as.integer(n))
  message(sprintf("[%s] %s: %s", step, detail, format(n, big.mark = ",")))
}

# ---- 1. Load and clean ------------------------------------------------------
# Base read.csv: readr's multithreaded reader crashed on this file on Windows
raw <- read.csv(file.path(raw_dir, "victorian_road_crash_data.csv"),
                stringsAsFactors = FALSE)
log_step("load", "all Victorian crash records 2012 to Jan 2026", nrow(raw))

crashes <- as_tibble(raw) |>
  mutate(date = as.Date(ACCIDENT_DATE),
         year = as.integer(format(date, "%Y")))

n0 <- nrow(crashes)
crashes <- distinct(crashes, ACCIDENT_NO, .keep_all = TRUE)
log_step("clean", "duplicate crash numbers removed", n0 - nrow(crashes))

crashes <- filter(crashes, STAT_DIV_NAME == "Metro")
log_step("clean", "metro Melbourne crashes", nrow(crashes))

n0 <- nrow(crashes)
crashes <- filter(crashes, year <= 2025)
log_step("clean", "January 2026 records dropped (partial year)", n0 - nrow(crashes))

n0 <- nrow(crashes)
crashes <- filter(crashes, SEVERITY != "Non injury accident")
log_step("clean", "non-injury records dropped (outside scope)", n0 - nrow(crashes))

n0 <- nrow(crashes)
crashes <- filter(crashes, !is.na(LATITUDE), !is.na(LONGITUDE),
                  between(LATITUDE, -39, -37), between(LONGITUDE, 144, 146.5))
log_step("clean", "records with missing or out-of-area coordinates dropped", n0 - nrow(crashes))

crashes <- crashes |>
  mutate(
    KSI        = SEVERITY %in% c("Fatal accident", "Serious injury accident"),
    pedestrian = PEDESTRIAN > 0,
    cyclist    = BICYCLIST > 0,
    vru        = pedestrian | cyclist,
    hour       = as.integer(substr(ACCIDENT_TIME, 1, 2)),
    weekday    = factor(substr(DAY_OF_WEEK, 1, 3),
                        levels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")),
    speed_kmh  = suppressWarnings(as.numeric(sub("\\s*km/hr", "", SPEED_ZONE))),
    light      = case_when(LIGHT_CONDITION == "Day"                   ~ "Daylight",
                           LIGHT_CONDITION == "Dusk/Dawn"             ~ "Dusk or dawn",
                           LIGHT_CONDITION == "Dark Street lights on" ~ "Dark, street lights on",
                           LIGHT_CONDITION == "Dark No street lights" ~ "Dark, no street lights",
                           TRUE ~ NA_character_)
  )

log_step("scope", "crashes involving a pedestrian", sum(crashes$pedestrian))
log_step("scope", "crashes involving a cyclist", sum(crashes$cyclist))
log_step("scope", "crashes involving either (VRU)", sum(crashes$vru))

vru <- filter(crashes, vru) |>
  mutate(user = case_when(pedestrian & cyclist ~ "Both",
                          pedestrian ~ "Pedestrian", TRUE ~ "Cyclist"))

# ---- 2. Trend 2012-2025 -----------------------------------------------------
trend <- bind_rows(
  crashes |> filter(pedestrian) |> count(year, name = "crashes") |> mutate(user = "Pedestrians"),
  crashes |> filter(cyclist)    |> count(year, name = "crashes") |> mutate(user = "Cyclists")
)
ksi_trend <- bind_rows(
  crashes |> filter(pedestrian) |> group_by(year) |> summarise(ksi = sum(KSI)) |> mutate(user = "Pedestrians"),
  crashes |> filter(cyclist)    |> group_by(year) |> summarise(ksi = sum(KSI)) |> mutate(user = "Cyclists")
)
trend <- left_join(trend, ksi_trend, by = c("year", "user"))
write_csv(trend, file.path(out_dir, "trend_by_year.csv"))
print(trend, n = Inf)

p_trend <- ggplot(trend, aes(year, crashes, colour = user)) +
  annotate("rect", xmin = 2019.5, xmax = 2021.5, ymin = -Inf, ymax = Inf,
           fill = "#eef3f8") +
  annotate("text", x = 2020.5, y = max(trend$crashes) * 1.04, label = "COVID-19\nlockdowns",
           colour = muted, size = 3.8, lineheight = 0.9, vjust = 0) +
  geom_line(linewidth = 1.4) +
  geom_point(size = 2.6) +
  geom_text(data = filter(trend, year == 2025) |>
              mutate(y_lab = crashes + if_else(user == "Pedestrians", 70, -70)),
            aes(y = y_lab, label = paste0(user, " ", format(crashes, big.mark = ","))),
            hjust = -0.08, size = 4.2, fontface = "bold") +
  scale_colour_manual(values = c("Pedestrians" = ped_col, "Cyclists" = bike_col), guide = "none") +
  scale_x_continuous(breaks = seq(2012, 2025, 2), expand = expansion(add = c(0.3, 3.2))) +
  scale_y_continuous(limits = c(0, max(trend$crashes) * 1.18), labels = scales::comma) +
  labs(title = "Pedestrian and cyclist injury crashes in Melbourne, 2012 to 2025",
       subtitle = "Crashes per year where at least one pedestrian or cyclist was involved",
       x = NULL, y = NULL, caption = credit) +
  theme_cv()
ggsave(file.path(out_dir, "fig1_trend.png"), p_trend, width = 10, height = 5.5, dpi = 200, bg = "white")

# ---- 3. When: hour x weekday ------------------------------------------------
timing <- bind_rows(
  crashes |> filter(pedestrian) |> count(weekday, hour) |> mutate(user = "Pedestrians"),
  crashes |> filter(cyclist)    |> count(weekday, hour) |> mutate(user = "Cyclists")
) |>
  filter(!is.na(hour), !is.na(weekday)) |>
  complete(user, weekday, hour = 0:23, fill = list(n = 0)) |>
  group_by(user) |> mutate(share = n / max(n)) |> ungroup() |>
  mutate(user = factor(user, levels = c("Pedestrians", "Cyclists")))

peak <- timing |> group_by(user) |> slice_max(n, n = 1, with_ties = FALSE)
print(peak)

p_time <- ggplot(timing, aes(hour, weekday, fill = share)) +
  geom_tile(colour = "white", linewidth = 0.6) +
  scale_fill_gradientn(colours = c("#f3f6f9", "#a9cdd1", teal, navy),
                       breaks = c(0, 1), labels = c("Fewest", "Most"), name = NULL) +
  scale_x_continuous(breaks = c(0, 6, 9, 12, 15, 18, 21),
                     labels = c("12am", "6am", "9am", "12pm", "3pm", "6pm", "9pm"),
                     expand = c(0, 0)) +
  scale_y_discrete(limits = rev) +
  facet_wrap(~ user, ncol = 1) +
  labs(title = "Cyclists are hurt in the commute; pedestrians in the afternoon",
       subtitle = "Injury crashes by hour and day, 2012 to 2025. Darker = more crashes (scaled within each group)",
       x = NULL, y = NULL, caption = credit) +
  theme_cv() +
  theme(panel.grid = element_blank(), legend.position = "top",
        legend.justification = "left", legend.key.width = unit(2.5, "lines"))
ggsave(file.path(out_dir, "fig2_timing.png"), p_time, width = 10, height = 7.5, dpi = 200, bg = "white")

# ---- 4. How serious: speed zone and light -----------------------------------
wilson <- function(x, n, z = 1.96) {
  p <- x / n
  centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  half   <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  tibble(pct = 100 * p, lo = 100 * (centre - half), hi = 100 * (centre + half))
}

ped <- filter(crashes, pedestrian)

by_speed <- ped |>
  filter(!is.na(speed_kmh), speed_kmh >= 40) |>
  mutate(group = case_when(speed_kmh <= 40 ~ "40", speed_kmh == 50 ~ "50",
                           speed_kmh == 60 ~ "60", speed_kmh == 70 ~ "70",
                           TRUE ~ "80+")) |>
  group_by(group) |> summarise(crashes = n(), ksi = sum(KSI), .groups = "drop") |>
  mutate(wilson(ksi, crashes)) |>
  mutate(panel = "By speed zone (km/h)")

by_light <- ped |>
  filter(!is.na(light)) |>
  group_by(group = light) |> summarise(crashes = n(), ksi = sum(KSI), .groups = "drop") |>
  mutate(wilson(ksi, crashes)) |>
  mutate(group = factor(group, levels = c("Daylight", "Dusk or dawn",
                                          "Dark, street lights on", "Dark, no street lights")),
         panel = "By light")

severity <- bind_rows(by_speed, by_light |> mutate(group = as.character(group)))
write_csv(severity, file.path(out_dir, "pedestrian_severity.csv"))
print(severity)

# Chi-square trend check: does KSI share rise with speed zone?
speed_test <- prop.trend.test(by_speed$ksi, by_speed$crashes)
print(speed_test)

p_sev_speed <- ggplot(by_speed, aes(group, pct)) +
  geom_col(fill = c(rep("#a9cdd1", 4), coral)[seq_len(nrow(by_speed))], width = 0.65) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.18, colour = navy, linewidth = 0.6) +
  geom_text(aes(y = hi + 3, label = paste0(round(pct), "%")), colour = navy,
            fontface = "bold", size = 5) +
  geom_text(aes(y = 2, label = paste0("n = ", format(crashes, big.mark = ",", trim = TRUE))),
            colour = navy, size = 3.4, vjust = 0) +
  scale_y_continuous(limits = c(0, 100), labels = \(x) paste0(x, "%"), expand = c(0, 0)) +
  labs(title = "The faster the road, the worse the outcome for a pedestrian",
       subtitle = "Share of pedestrian crashes where someone was killed or seriously injured, by speed zone",
       x = "Speed zone (km/h)", y = NULL,
       caption = paste0("Lines show 95% confidence intervals. Test for trend: p < 0.001.\n", credit)) +
  theme_cv() + theme(panel.grid.major.x = element_blank())
ggsave(file.path(out_dir, "fig3_severity_speed.png"), p_sev_speed, width = 10, height = 6, dpi = 200, bg = "white")

p_sev_light <- ggplot(by_light, aes(pct, group)) +
  geom_col(fill = c("#c9e0e3", "#7fb6bd", teal, navy), width = 0.6) +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0.18, colour = muted, orientation = "y") +
  geom_text(aes(x = hi + 2, label = paste0(round(pct), "%")), hjust = 0,
            colour = navy, fontface = "bold", size = 5) +
  scale_x_continuous(limits = c(0, 100), labels = \(x) paste0(x, "%"), expand = c(0, 0)) +
  scale_y_discrete(limits = rev) +
  labs(title = "Being hit in the dark is more dangerous, especially without street lights",
       subtitle = "Share of pedestrian crashes where someone was killed or seriously injured, by light",
       x = NULL, y = NULL, caption = paste0("Lines show 95% confidence intervals.\n", credit)) +
  theme_cv() + theme(panel.grid.major.y = element_blank(),
                     axis.text.y = element_text(colour = navy, size = 13))
ggsave(file.path(out_dir, "fig4_severity_light.png"), p_sev_light, width = 10, height = 5, dpi = 200, bg = "white")

# ---- 5. Where: Getis-Ord Gi* hot spots on a 1 km hexagon grid ---------------
recent <- vru |> filter(year >= 2021) |>
  st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) |>
  st_transform(crs_mga)
log_step("hotspot", "pedestrian and cyclist crashes 2021-2025", nrow(recent))

all_pts <- crashes |> filter(year >= 2021) |>
  st_as_sf(coords = c("LONGITUDE", "LATITUDE"), crs = 4326) |>
  st_transform(crs_mga)

cell <- 1000
hex <- st_make_grid(all_pts, cellsize = cell, square = FALSE) |>
  st_sf(geometry = _) |> mutate(hex_id = row_number())

# Study area = hexes with at least one crash of any kind (a proxy for the road network)
hex$any_crash <- lengths(st_intersects(hex, all_pts))
hex <- filter(hex, any_crash > 0)
hex$vru   <- lengths(st_intersects(hex, recent))
hex$vru_ksi <- lengths(st_intersects(hex, filter(recent, KSI)))
log_step("hotspot", "hexagons in study area", nrow(hex))

# Gi* with binary weights: each hexagon plus every hexagon whose centre is
# within 2 km (two rings of neighbours), self included
cent <- st_centroid(st_geometry(hex))
nb   <- st_is_within_distance(cent, cent, dist = 2 * cell + 1)
x    <- hex$vru
n    <- length(x); xbar <- mean(x); s <- sqrt(sum(x^2) / n - xbar^2)
gi <- vapply(seq_len(n), function(i) {
  j  <- nb[[i]]; w <- length(j)
  (sum(x[j]) - xbar * w) / (s * sqrt((n * w - w^2) / (n - 1)))
}, numeric(1))

hex <- hex |>
  mutate(gi_z = gi,
         class = case_when(gi_z >= 2.58 ~ "Hot spot, 99% confidence",
                           gi_z >= 1.96 ~ "Hot spot, 95% confidence",
                           gi_z >= 1.65 ~ "Hot spot, 90% confidence",
                           TRUE         ~ "Not significant"),
         class = factor(class, levels = c("Hot spot, 99% confidence", "Hot spot, 95% confidence",
                                          "Hot spot, 90% confidence", "Not significant")))
print(count(st_drop_geometry(hex), class))

# Name the hot spots by the council area most of their crashes fall in
hot99 <- filter(hex, class == "Hot spot, 99% confidence")
hot_lga <- st_join(recent |> select(LGA_NAME), hot99 |> select(hex_id), left = FALSE) |>
  st_drop_geometry() |>
  count(LGA_NAME, sort = TRUE, name = "crashes")
write_csv(hot_lga, file.path(out_dir, "hotspot_council_areas.csv"))
print(head(hot_lga, 10))
log_step("hotspot", "share of 2021-25 pedestrian/cyclist crashes inside 99% hot spots (%)",
         round(100 * sum(hot99$vru) / nrow(recent)))
log_step("hotspot", "hexagons in 99% hot spots", nrow(hot99))
log_step("hotspot", "share of study-area hexagons that are 99% hot spots (%)",
         round(100 * nrow(hot99) / nrow(hex)))

# Backdrop: declared main roads
roads <- st_read(file.path(raw_dir, "yearly_aadt_volume_2019.geojson"), quiet = TRUE) |>
  st_transform(crs_mga)
roads <- roads[st_intersects(roads, st_union(st_buffer(st_as_sfc(st_bbox(hex)), 0)), sparse = FALSE)[, 1], ]

place <- function(lon, lat, label) {
  st_sf(label = label, geometry = st_sfc(st_point(c(lon, lat)), crs = 4326)) |>
    st_transform(crs_mga)
}
towns <- bind_rows(
  place(144.9631, -37.8136, "MELBOURNE CBD"), place(144.9809, -37.8676, "ST KILDA"),
  place(145.1278, -37.8183, "BOX HILL"),     place(145.2161, -37.9875, "DANDENONG"),
  place(144.9006, -37.7600, "ESSENDON"),      place(144.9925, -37.6450, "EPPING"),
  place(144.7340, -37.8810, "WERRIBEE"),      place(145.1390, -38.1430, "FRANKSTON"),
  place(144.7880, -37.7470, "SUNSHINE")
)
towns <- cbind(towns, st_coordinates(towns))

hot_cols <- c("Hot spot, 99% confidence" = "#b2182b", "Hot spot, 95% confidence" = "#ef6548",
              "Hot spot, 90% confidence" = "#fdbb84", "Not significant" = "#f1f3f6")

map_theme <- function() {
  theme_void(base_size = 12) +
    theme(plot.background = element_rect(fill = "white", colour = NA),
          plot.title.position = "plot", plot.caption.position = "plot",
          plot.title = element_text(colour = navy, face = "bold", size = 20, margin = margin(b = 4)),
          plot.subtitle = element_text(colour = muted, size = 12, margin = margin(b = 12)),
          plot.caption = element_text(colour = muted, size = 8.5, hjust = 0, margin = margin(t = 8)),
          legend.title = element_text(colour = navy, face = "bold", size = 10),
          legend.text = element_text(colour = navy, size = 9.5),
          plot.margin = margin(20, 20, 15, 20))
}

cbd <- st_coordinates(towns[towns$label == "MELBOURNE CBD", ])

# Metro map: Gi* classes, framed on the built-up area, reading box over the bay
metro_xlim <- cbd[1] + c(-38000, 42000)
metro_ylim <- cbd[2] + c(-48000, 26000)

p_metro <- ggplot() +
  geom_sf(data = hex, aes(fill = class), colour = "white", linewidth = 0.15) +
  geom_sf(data = roads, colour = "#9aa7b8", linewidth = 0.25, alpha = 0.7) +
  geom_label(data = towns, aes(X, Y, label = label), colour = navy, fill = "white",
             linewidth = 0, label.padding = unit(0.18, "lines"), size = 3.3,
             fontface = "bold", alpha = 0.85) +
  annotate("label", x = metro_xlim[1] + 0.02 * diff(metro_xlim),
           y = metro_ylim[1] + 0.03 * diff(metro_ylim),
           label = sprintf("HOW TO READ THIS MAP\n\nEach hexagon is 1 km across.\nRed = a statistically significant\ncluster of crashes involving people\nwalking or cycling, more than\nchance would give.\n\n%d%% of these crashes happened in\nthe darkest-red areas, which cover\nonly %d%% of the map.",
                           round(100 * sum(hot99$vru) / nrow(recent)), round(100 * nrow(hot99) / nrow(hex))),
           hjust = 0, vjust = 0, colour = navy, fill = "#eef3f8",
           linewidth = 0, label.padding = unit(0.7, "lines"), size = 3.7, lineheight = 1.15) +
  scale_fill_manual(values = hot_cols, name = "Getis-Ord Gi*") +
  coord_sf(xlim = metro_xlim, ylim = metro_ylim, expand = FALSE, datum = NA) +
  labs(title = "Hot spots for people walking and cycling",
       subtitle = "Metro Melbourne, pedestrian and cyclist injury crashes 2021 to 2025",
       caption = credit) +
  map_theme() + theme(legend.position = c(0.86, 0.12))
ggsave(file.path(out_dir, "fig5_hotspots_metro.png"), p_metro,
       width = 10, height = 9.6, dpi = 200, device = ragg::agg_png)

# Inner close-up: plain crash counts on a finer 500 m grid, worst cells named
inner_xlim <- cbd[1] + c(-7000, 7000)
inner_ylim <- cbd[2] + c(-8000, 6000)
inner_box  <- st_as_sfc(st_bbox(c(xmin = inner_xlim[1], xmax = inner_xlim[2],
                                  ymin = inner_ylim[1], ymax = inner_ylim[2]), crs = crs_mga))
inner_pts <- recent[st_intersects(recent, inner_box, sparse = FALSE)[, 1], ]

hex500 <- st_make_grid(inner_box, cellsize = 500, square = FALSE) |>
  st_sf(geometry = _) |> mutate(cell_id = row_number())
hex500$n <- lengths(st_intersects(hex500, inner_pts))
hex500 <- filter(hex500, n > 0) |>
  mutate(band = cut(n, breaks = c(0, 5, 10, 20, 40, Inf),
                    labels = c("1 to 5", "6 to 10", "11 to 20", "21 to 40", "More than 40")))
print(table(hex500$band))

# Name the five busiest cells by their most common road
top_cells <- hex500 |> slice_max(n, n = 5, with_ties = FALSE)
top_names <- st_join(inner_pts |> select(ROAD_NAME, ROAD_TYPE),
                     top_cells |> select(cell_id, n), left = FALSE) |>
  st_drop_geometry() |>
  mutate(road = paste(tools::toTitleCase(tolower(ROAD_NAME)),
                      c(STREET = "St", ROAD = "Rd", PARADE = "Pde", AVENUE = "Ave",
                        HIGHWAY = "Hwy", BOULEVARD = "Blvd")[ROAD_TYPE] |> coalesce(""))) |>
  count(cell_id, road, sort = TRUE) |>
  group_by(cell_id) |> slice_head(n = 1) |> ungroup()
top_lbl <- top_cells |> left_join(top_names |> select(cell_id, road), by = "cell_id") |>
  arrange(desc(n)) |> mutate(rank = row_number(), road = trimws(road))
top_lbl <- cbind(top_lbl, st_coordinates(st_centroid(st_geometry(top_lbl))))
write_csv(st_drop_geometry(top_lbl) |> select(rank, road, n), file.path(out_dir, "inner_top_cells.csv"))
print(st_drop_geometry(top_lbl) |> select(rank, road, n))

top_list <- paste(sprintf("%d   %s, %d crashes", top_lbl$rank, top_lbl$road, top_lbl$n), collapse = "\n")

count_cols <- c("1 to 5" = "#fde0d2", "6 to 10" = "#fcae91", "11 to 20" = "#fb6a4a",
                "21 to 40" = "#de2d26", "More than 40" = "#99000d")

p_inner <- ggplot() +
  geom_sf(data = hex500, aes(fill = band), colour = "white", linewidth = 0.3) +
  geom_sf(data = roads, colour = "#7d8a9c", linewidth = 0.3, alpha = 0.8) +
  geom_point(data = top_lbl, aes(X, Y), shape = 21, size = 7.5, fill = navy,
             colour = "white", stroke = 1.2) +
  geom_text(data = top_lbl, aes(X, Y, label = rank), colour = "white",
            fontface = "bold", size = 4) +
  annotate("label", x = inner_xlim[1] + 0.02 * diff(inner_xlim), y = inner_ylim[2] - 0.02 * diff(inner_ylim),
           label = paste0("HOW TO READ THIS MAP\n\nEach hexagon is 500 m across.\nDarker red = more crashes\ninvolving people walking or cycling.\n\nTHE FIVE WORST HEXAGONS\n", top_list),
           hjust = 0, vjust = 1, colour = navy, fill = "#eef3f8",
           linewidth = 0, label.padding = unit(0.7, "lines"), size = 3.7, lineheight = 1.15) +
  scale_fill_manual(values = count_cols, name = "Crashes, 2021-2025") +
  coord_sf(xlim = inner_xlim, ylim = inner_ylim, expand = FALSE, datum = NA) +
  labs(title = "Inner Melbourne, street by street",
       subtitle = sprintf("%s pedestrian and cyclist injury crashes within 7 km of the CBD, 2021 to 2025",
                          format(nrow(inner_pts), big.mark = ",")),
       caption = credit) +
  map_theme() + theme(legend.position = c(0.86, 0.13))
ggsave(file.path(out_dir, "fig6_hotspots_inner.png"), p_inner,
       width = 9.5, height = 10, dpi = 200, device = ragg::agg_png)


# ---- 6. Cyclists: the most common crash movements ---------------------------
bike_dca <- crashes |> filter(cyclist) |>
  count(DCA_CODE_DESCRIPTION, sort = TRUE) |>
  mutate(pct = round(100 * n / sum(n), 1)) |> head(8)
write_csv(bike_dca, file.path(out_dir, "cyclist_top_crash_movements.csv"))
print(bike_dca)

write_csv(qlog, file.path(out_dir, "data_quality_log.csv"))
message("Done. Outputs in: ", out_dir)

# ---- 7. Export layers for ArcGIS Pro / QGIS ---------------------------------
gis_dir <- file.path(proj_dir, "gis_layers")
dir.create(gis_dir, showWarnings = FALSE)
st_write(hex |> select(hex_id, vru, vru_ksi, gi_z, class) |> mutate(class = as.character(class)),
         file.path(gis_dir, "hotspots_hex_1km.gpkg"), delete_dsn = TRUE, quiet = TRUE)
st_write(hex500 |> mutate(band = as.character(band)),
         file.path(gis_dir, "inner_counts_hex_500m.gpkg"), delete_dsn = TRUE, quiet = TRUE)
st_write(recent |> select(ACCIDENT_NO, date, year, hour, user, SEVERITY, KSI, SPEED_ZONE,
                          LIGHT_CONDITION, DCA_CODE_DESCRIPTION, ROAD_NAME, LGA_NAME),
         file.path(gis_dir, "ped_cyclist_crashes_2021_2025.gpkg"), delete_dsn = TRUE, quiet = TRUE)
st_write(roads |> select(any_of(c("ROAD_NAME", "ROAD_NBR", "ALLVEHS_AADT"))),
         file.path(gis_dir, "main_roads.gpkg"), delete_dsn = TRUE, quiet = TRUE)
message("GIS layers written to: ", gis_dir)

# ---- 8. Card image for the CV site (wide crop of the hot-spot map) ----------
card_xlim <- cbd[1] + c(-30000, 34000)
card_ylim <- cbd[2] + c(-27000, 13000)
p_card <- ggplot() +
  geom_sf(data = hex, aes(fill = class), colour = "white", linewidth = 0.12) +
  geom_sf(data = roads, colour = "#9aa7b8", linewidth = 0.22, alpha = 0.7) +
  geom_label(data = filter(towns, label %in% c("MELBOURNE CBD", "ST KILDA", "DANDENONG", "SUNSHINE", "BOX HILL")),
             aes(X, Y, label = label), colour = navy, fill = "white", linewidth = 0,
             label.padding = unit(0.15, "lines"), size = 2.6, fontface = "bold", alpha = 0.85) +
  annotate("label", x = card_xlim[1] + 0.025 * diff(card_xlim), y = card_ylim[2] - 0.04 * diff(card_ylim),
           label = "PEDESTRIAN AND CYCLIST HOT SPOTS\nMelbourne, 2021-2025  |  Getis-Ord Gi*",
           hjust = 0, vjust = 1, colour = navy, fill = "white", linewidth = 0,
           label.padding = unit(0.45, "lines"), size = 3, lineheight = 1.2, fontface = "bold") +
  scale_fill_manual(values = hot_cols, guide = "none") +
  coord_sf(xlim = card_xlim, ylim = card_ylim, expand = FALSE, datum = NA) +
  theme_void() + theme(plot.background = element_rect(fill = "white", colour = NA),
                       plot.margin = margin(0, 0, 0, 0))
ggsave(file.path(out_dir, "card_hotspots.png"), p_card, width = 6.4, height = 4, dpi = 200,
       device = ragg::agg_png)

# ---- 9. Clean table for Power BI --------------------------------------------
# One row per crash involving a pedestrian or cyclist, metro Melbourne 2012-2025
pbi_dir <- file.path(proj_dir, "powerbi")
dir.create(pbi_dir, showWarnings = FALSE)
pbi <- vru |>
  transmute(
    crash_id      = ACCIDENT_NO,
    date          = date,
    year          = year,
    month         = format(date, "%b"),
    month_num     = as.integer(format(date, "%m")),
    weekday_num   = as.integer(weekday),
    weekday       = as.character(weekday),
    hour          = hour,
    road_user     = user,
    severity      = sub(" accident$", "", SEVERITY),
    serious_or_fatal = if_else(KSI, 1L, 0L),
    speed_zone    = case_when(speed_kmh <= 40 ~ "40 or less", speed_kmh == 50 ~ "50",
                              speed_kmh == 60 ~ "60", speed_kmh == 70 ~ "70",
                              speed_kmh >= 80 ~ "80 or more", TRUE ~ "Unknown"),
    speed_zone_order = case_when(speed_kmh <= 40 ~ 1L, speed_kmh == 50 ~ 2L, speed_kmh == 60 ~ 3L,
                                 speed_kmh == 70 ~ 4L, speed_kmh >= 80 ~ 5L, TRUE ~ 6L),
    light         = coalesce(light, "Unknown"),
    crash_movement = tools::toTitleCase(tolower(DCA_CODE_DESCRIPTION)),
    road_name     = tools::toTitleCase(tolower(trimws(paste(ROAD_NAME, ROAD_TYPE)))),
    council       = tools::toTitleCase(tolower(LGA_NAME)),
    latitude      = LATITUDE,
    longitude     = LONGITUDE
  )
write_csv(pbi, file.path(pbi_dir, "melbourne_ped_cyclist_crashes.csv"), na = "")
message("Power BI table: ", nrow(pbi), " rows")
