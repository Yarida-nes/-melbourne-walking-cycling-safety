# Make the hot-spot map yourself in QGIS (free): step by step

You will make a print-ready map like the one on your website, with blue sea, hot-spot hexagons, a title, legend, north arrow, scale bar, Victoria locator map and credits. It takes about **1.5 hours**. Do one part at a time and check the ✅ boxes as you go.

**Your files** (all in `OneDrive\Desktop\melbourne road crash\`):

| File | What it is |
|---|---|
| `gis_layers\hotspots_hex_1km.gpkg` | 4,363 hexagons (1 km), each with a hot-spot result in the column **class** |
| `gis_layers\main_roads.gpkg` | Main roads |
| `gis_layers\ped_cyclist_crashes_2021_2025.gpkg` | 10,428 crash points (optional extra layer) |
| `gis_layers\inner_counts_hex_500m.gpkg` | 500 m hexagons for the inner city (column **band**) |
| `data_raw\ste\STE_2021_AUST_GDA2020.shp` | Australian states, for the locator map |

---

## Part 1: Start a project (5 minutes)

1. Open **QGIS Desktop** from the Start menu. Close any pop-ups.
2. Click **Project → New**.
3. Set the map's coordinate system: at the **bottom-right** of the window, click the box that says **EPSG:4326**. In the search box type `7855`, click **GDA2020 / MGA zone 55**, then click **OK**. This makes distances correct in metres for Melbourne.
4. **Project → Save As** → go to the `melbourne road crash` folder → name it `melbourne_hotspots` → **Save**. Press **Ctrl + S** often from now on.

## Part 2: Add a basemap with blue sea (5 minutes)

5. On the left, find the **Browser** panel. If you can't see it: **View → Panels → Browser**.
6. In Browser, right-click **XYZ Tiles** → **New Connection…**
7. Fill in:
   - **Name:** `Light grey basemap`
   - **URL:** `https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png`
   - Click **OK**.
8. Expand **XYZ Tiles** and double-click **Light grey basemap**. A pale map of the world appears.

> ✅ **Check:** zoom in on Melbourne (scroll the mouse wheel). You see grey land and light-blue Port Phillip Bay.

## Part 3: Add your hot spots (10 minutes)

9. **Layer → Add Layer → Add Vector Layer…** (or press **Ctrl + Shift + V**).
10. Click the **…** button, go to `gis_layers`, choose `hotspots_hex_1km.gpkg`, click **Open**, then **Add**. Close the window.
11. Do the same for `main_roads.gpkg`.
12. In the **Layers** panel (bottom-left), drag the layers into this order, top to bottom:
    1. `main_roads`
    2. `hotspots_hex_1km`
    3. `Light grey basemap`
13. Right-click `hotspots_hex_1km` → **Zoom to Layer**.

> ✅ **Check:** right-click `hotspots_hex_1km` → **Open Attribute Table**. The bottom of the window says **4363** features. Close it.

## Part 4: Colour the hot spots (15 minutes)

14. Double-click `hotspots_hex_1km` in the Layers panel. The **Layer Properties** window opens.
15. Click **Symbology** on the left.
16. At the top, change **Single Symbol** to **Categorized**.
17. **Value:** choose **class**.
18. Click **Classify** at the bottom. Four categories appear.
19. Double-click each colour square and type the **HTML** colour code:
    - Hot spot, 99% confidence → `#b2182b`
    - Hot spot, 95% confidence → `#ef6548`
    - Hot spot, 90% confidence → `#fdbb84`
    - **Not significant → untick its checkbox** so it's hidden
20. Also **untick "all other values"** if it appears.
21. Make the hexagon borders white: click **Symbol** (just above the list) → **Simple Fill** → **Stroke color: white**, **Stroke width: 0.1**. Click **OK**.
22. Click **Apply**, then **OK**.

> ✅ **Check:** a large dark-red area covers the CBD, inner north and the bayside suburbs, with a smaller red patch at Dandenong. Count check: in Symbology, right-click the 99% row → **Show Feature Count**. It should say **(273)**.

**Make the roads subtle:**

23. Double-click `main_roads` → **Symbology** → **Simple Line** → **Color:** `#9aa7b8`, **Stroke width:** `0.2` → **OK**.

## Part 5: Make the print layout (40 minutes)

24. **Project → New Print Layout…** Name it `Hot spots map` → **OK**. A new window opens with a blank page.
25. Right-click the blank page → **Page Properties** → **Size: A4**, **Orientation: Portrait**.

**The map**

26. **Add Item → Add Map**. Drag a big rectangle over most of the page, leaving space at the top for the title and at the bottom for credits.
27. With the map selected, open **Item Properties** on the right. Set **Scale** to about `400000`.
28. To move the map inside its frame, use **Edit → Move Content** (or press **C**), then drag. Put the CBD in the upper middle, with the bay and Frankston below.
29. Still in Item Properties, tick **Lock layers**. This keeps this map fixed while you build the locator map.

**Title**

30. **Add Item → Add Label**. Drag a box at the top. Type `Hot spots for people walking and cycling`. Under **Font**, choose bold, size **24**, colour navy `#10233f`.
31. Add another label underneath: `Metro Melbourne · Pedestrian and cyclist injury crashes, 2021 to 2025` (size 12, grey).

**Legend**

32. **Add Item → Add Legend**. Drag a box at the bottom-right, inside the map.
33. In Item Properties:
    - Untick **Auto update**
    - Select **main_roads** and **Light grey basemap** in the list and remove them with the **red minus (–)** button
    - Double-click the `hotspots_hex_1km` name and rename it to `Crash hot spots`
    - Scroll down to **Background**, tick it, and choose white

**North arrow and scale bar**

34. **Add Item → Add North Arrow**. Drag a small box in the top-left corner of the map.
35. **Add Item → Add Scale Bar**. Drag it to the bottom-left. In Item Properties set **Units: Kilometers**, **Fixed width: 5 km**, **Segments: right 4**.

**Victoria locator map**

36. Go back to the **main QGIS window**. Add the states layer: **Layer → Add Vector Layer** → `data_raw\ste\STE_2021_AUST_GDA2020.shp`.
37. Zoom out until you can see all of Victoria.
38. Back in the **layout window**: **Add Item → Add Map**. Draw a small box in the top-right corner of the big map.
39. With the small map selected, click **Set Map Extent to Match Main Canvas Extent** in Item Properties (the button with the map icon), so it shows Victoria.
40. Scroll down in Item Properties to **Overviews** → click **+** → set **Map frame** to the big map (**Map 1**). A box appears on Victoria showing where your map is.
41. In **Overviews → Frame style**, choose **no fill** and a **red outline**, width 0.8.
42. Give the small map a frame: **Frame** → tick it, colour navy.

> If your hot spots disappeared from the big map at step 37, you missed step 29. Click the big map, untick and re-tick Lock layers, and use **Move Content** to reposition it.

**Key finding box (optional, but it makes the map easy to understand)**

43. **Add Item → Add Label**. Put it over the bay. Type:
    `KEY FINDING: Half of all pedestrian and cyclist crashes (49%) happen in the dark-red hot spots, which cover just 6% of the area.`
44. Under **Background**, tick it and choose white; under **Frame**, tick it.

**Credits**

45. **Add Item → Add Label** at the very bottom, size 8, grey:
    `Data: Victoria road crash data, Department of Transport and Planning (CC BY 4.0). Coastline: ABS ASGS 2021. Basemap © OpenStreetMap contributors © CARTO. GDA2020 / MGA Zone 55. Map: Yarida Kaewthong`

> Basemap tiles have their own credit line. Always keep "© OpenStreetMap contributors © CARTO" on the map.

## Part 6: Export (5 minutes)

46. **Layout → Export as Image…**
47. Save it in `melbourne road crash\outputs` as `qgis_hotspots_map.png`.
48. Set **Export resolution: 200 dpi** → **Save**.
49. **Project → Save** in the main window.
50. Send Claude the PNG. Claude will check it and can put it on your website as **"Map made in QGIS by Yarida"**.

---

## Bonus: the inner-city map

Repeat Parts 3–6 with `inner_counts_hex_500m.gpkg`:
- Symbology: **Categorized** on **band**, with colours `#fde0d2` (1 to 5), `#fcae91` (6 to 10), `#fb6a4a` (11 to 20), `#de2d26` (21 to 40) and `#99000d` (More than 40)
- Map scale about `80000`, centred on the CBD
- Title: `Inner Melbourne, street by street`

## If something goes wrong

| Problem | Fix |
|---|---|
| The hexagons are in the wrong place or very small | Check step 3 (project CRS is EPSG:7855) |
| The basemap is blank | You need an internet connection for the tiles |
| A button isn't where the guide says | Menus can differ slightly between QGIS versions. Send Claude a screenshot |
| Changed the wrong thing | **Ctrl + Z** undoes it |

## For your CV and interviews

- *"I built a print-ready map layout in QGIS from hexagon hot-spot results, with a locator map, legend and scale bar."*
- QGIS is free and widely used by councils and government agencies, and the HIVE project brief lists "ArcGIS or QGIS", so this skill counts.
