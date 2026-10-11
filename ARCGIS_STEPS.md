# Make the hot-spot map in ArcGIS Pro: step by step

You need ArcGIS Pro (free for Curtin students, in the uni computer labs or from your Curtin software page). Copy the whole `melbourne road crash` folder to a USB stick or OneDrive first if you are using a lab computer.

The layers are in `gis_layers\`:

| File | What it shows |
|---|---|
| `hotspots_hex_1km.gpkg` | 1 km hexagons with the Gi* hot-spot result (`class` field) |
| `inner_counts_hex_500m.gpkg` | 500 m hexagons, inner Melbourne crash counts (`band` field) |
| `ped_cyclist_crashes_2021_2025.gpkg` | Every pedestrian and cyclist crash, 2021 to 2025 |
| `main_roads.gpkg` | Main road network |

---

## Part A: Make the map (about 15 minutes)

1. Open **ArcGIS Pro** and sign in with your Curtin account.
2. Click **Map** under *New Project → Blank Templates*. Name it `Melbourne_crash`. Click **OK**.
3. On the ribbon, click the **Map** tab, then **Basemap**, then **Light Gray Canvas**. This gives you the blue water and grey land.
4. Click **Map → Add Data**. Go to `melbourne road crash\gis_layers`, double-click `hotspots_hex_1km.gpkg`, choose the layer, and click **OK**.
5. In the **Contents** pane on the left, right-click the new layer and choose **Symbology**.
6. Set **Primary symbology** to **Unique Values**, and **Field 1** to **class**.
7. Click each colour square and set the colour by typing its hex code (**Color properties → HEX**):
   - Hot spot, 99% confidence → `#B2182B`
   - Hot spot, 95% confidence → `#EF6548`
   - Hot spot, 90% confidence → `#FDBB84`
   - Not significant → **No color**. Click the square, then choose *No Color* at the top of the palette.
8. Still in Symbology, click the **More** button, then **Symbol outline**, and set the outline to white at 0.3 pt.
9. Right-click the layer, click **Properties → General**, and set the name to `Pedestrian and cyclist hot spots (Gi*)`. Click **OK**.
10. Click **Add Data** again and add `main_roads.gpkg`. In Symbology, choose **Single Symbol**, colour grey `#9AA7B8`, width 0.4 pt. Drag it **above** the hexagons in the Contents pane.
11. Zoom so Melbourne CBD is near the top-centre and Frankston is at the bottom: scroll the mouse wheel, and drag with the wheel pressed to move the map.

## Part B: Make the layout (about 20 minutes)

12. Click **Insert → New Layout → ISO A4 Portrait**.
13. Click **Insert → Map Frame** and choose your map. Drag a large rectangle across the top two-thirds of the page.
14. Click **Insert → North Arrow** and pick **ArcGIS North 1**. Drag it into the top-right corner of the map frame.
15. Click **Insert → Scale Bar** and pick **Scale Line 1 Metric**. Drag it into the bottom-left of the map frame. In the Format pane, set **Units** to **Kilometers**.
16. Click **Insert → Legend**. Drag a box at the bottom-right. Right-click the legend, click **Properties**, and tick **Show background**: white fill, thin grey border.
17. **Locator map:** click **Insert → New Map**. Set the basemap to **Light Gray Canvas** and zoom out to show all of Victoria. Go back to the Layout tab, click **Insert → Map Frame**, choose *Map1*, and draw a small box in the top-left corner.
18. Click the small locator frame. Click **Insert → Extent Indicator** and choose the main map frame. A box appears showing where Melbourne is. Make its outline red, 1.5 pt.
19. Click **Insert → Text**. Type the title `Hot spots for people walking and cycling, Melbourne 2021–2025`, font size 18, bold.
20. Add a second **Text** box at the bottom with the credits:
    `Data: Victoria road crash data, Department of Transport and Planning (CC BY 4.0). Coordinate system: GDA2020 MGA Zone 55. Analysis: Getis-Ord Gi*, 1 km hexagons. Map: Yarida Kaewthong, October 2026.`
21. **Optional, latitude/longitude ticks:** click the main map frame. In the Format pane, go to **Grids → Add new grid → Black Vertical Label Graticule**.

## Part C: Export (2 minutes)

22. Click **Share → Export Layout**.
23. Set **File type** to **PNG**, **Resolution** to **200 dpi**, and **Name** to `melbourne_hotspots_arcgis.png`. Save it in `melbourne road crash\outputs`.
24. Click **Export**.
25. Tell Claude it's done. Claude will check it and put it on your CV page.

**Repeat for the inner-city map** with `inner_counts_hex_500m.gpkg`: Unique Values on **band**, using light-to-dark reds `#FDE0D2`, `#FCAE91`, `#FB6A4A`, `#DE2D26`, `#99000D`. Export it as `melbourne_inner_arcgis.png`.
