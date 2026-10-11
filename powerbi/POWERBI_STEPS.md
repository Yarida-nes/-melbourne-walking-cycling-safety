# Build the Melbourne crash dashboard in Power BI: step by step

You will build one dashboard page with: 3 number cards, a trend line, an hour-by-day heat map, a speed-zone chart, a map of every crash, and filters. It takes about **1.5 to 2 hours**. Do one part at a time, and check your numbers against the ✅ boxes as you go.

**Your files** (all in `Desktop\melbourne road crash\powerbi\`):
- `melbourne_ped_cyclist_crashes.csv`: 30,469 real crashes involving a pedestrian or cyclist, metro Melbourne 2012 to 2025
- `yarida_theme.json`: your CV colours (navy and teal)

**What the columns mean**

| Column | Meaning |
|---|---|
| `year`, `month`, `weekday`, `hour` | When the crash happened |
| `road_user` | Pedestrian, Cyclist, or Both |
| `severity` | Fatal, Serious injury, Other injury |
| `serious_or_fatal` | 1 if someone was killed or seriously injured, otherwise 0 |
| `speed_zone` | 40 or less, 50, 60, 70, 80 or more, Unknown |
| `light` | Daylight, Dusk or dawn, Dark with or without street lights |
| `crash_movement` | What happened (e.g. "Vehicle Strikes Door of Parked/Stationary Vehicle" = dooring) |
| `road_name`, `council` | Where |
| `latitude`, `longitude` | Map location |
| `month_num`, `weekday_num`, `speed_zone_order` | Helper columns, used only for sorting |

---

## Part 1: Load the data (10 minutes)

1. Press the **Windows key**, type `Power BI`, and open **Power BI Desktop**. Close any sign-in pop-up; you don't need to sign in.
2. Click **Blank report**.
3. On the **Home** tab, click **Get data → Text/CSV**.
4. Go to `Desktop\melbourne road crash\powerbi`, choose `melbourne_ped_cyclist_crashes.csv`, and click **Open**.
5. A preview window opens. Click **Transform data**, *not* Load. The Power Query window opens.
6. Check each column's type. The small icon left of each column name shows it. Fix any that are wrong by clicking the icon:
   - `date` → **Date**
   - `year`, `month_num`, `weekday_num`, `hour`, `serious_or_fatal`, `speed_zone_order` → **Whole Number**
   - `latitude`, `longitude` → **Decimal Number**
   - everything else → **Text**
7. On the right, under **Query Settings → Name**, change the name to `crashes`.
8. Click **Close & Apply** (top-left).

> ✅ **Check:** on the left, click the **Table view** icon (it looks like a grid). The bottom-left should say **30,469 rows**.

## Part 2: Sort and set up columns (10 minutes)

Without this, weekdays sort alphabetically (Fri, Mon, Sat…).

9. In **Table view**, click the `weekday` column header.
10. On the ribbon: **Column tools → Sort by column → weekday_num**.
11. Click the `month` column → **Sort by column → month_num**.
12. Click the `speed_zone` column → **Sort by column → speed_zone_order**.
13. Click the `latitude` column → **Column tools → Data category → Latitude**.
14. Click the `longitude` column → **Data category → Longitude**.
15. Click `year`, then in **Column tools** set **Summarization** to **Don't summarize**. Do the same for `hour`.

## Part 3: Create three measures (10 minutes)

Measures are small formulas, written in a language called DAX.

16. Go back to **Report view** (the icon at the top of the left bar).
17. In the **Data** pane on the right, right-click `crashes` and choose **New measure**.
18. Delete what's in the formula bar, paste this, and press **Enter**:
    ```
    Total Crashes = COUNTROWS(crashes)
    ```
19. Right-click `crashes` → **New measure** again, paste, and press **Enter**:
    ```
    Serious or Fatal = SUM(crashes[serious_or_fatal])
    ```
20. One more:
    ```
    % Serious = DIVIDE([Serious or Fatal], [Total Crashes])
    ```
21. With `% Serious` selected in the Data pane: **Measure tools → Format → Percentage**, decimal places **1**.

## Part 4: Apply your colours (2 minutes)

22. Click the **View** tab → **Themes** (the arrow next to the colour boxes) → **Browse for themes**.
23. Choose `yarida_theme.json` and click **Open**. Click **OK** on the message.

## Part 5: Build the visuals (45 to 60 minutes)

Click an empty part of the page before adding each new visual, or you'll change the selected one instead.

**Title**

24. **Insert → Text box**. Type `Walking and cycling safety in Melbourne, 2012–2025`. Make it size 20, bold. Drag it to the top-left.

**Three number cards**

25. In **Visualizations**, click the **Card** icon. Drag the `Total Crashes` measure onto it. Place it top-left, under the title.
26. Make a second card with `Serious or Fatal`, and a third with `% Serious`. Line them up in a row.

> ✅ **Check:** Total Crashes = **30,469** · Serious or Fatal = **12,014** · % Serious = **39.4%**

**Trend line**

27. Click the **Line chart** icon. Drag `year` to **X-axis**, `Total Crashes` to **Y-axis**, and `road_user` to **Legend**.
28. In **Format visual → General → Title**, type `Crashes per year`.

> ✅ **Check:** hover over 2020. The total for all road users is lowest that year (**1,756**, against 2,171 in 2019): the COVID-19 lockdowns.

**Hour-by-day heat map**

29. Click the **Matrix** icon. Drag `weekday` to **Rows**, `hour` to **Columns**, and `Total Crashes` to **Values**.
30. With the matrix selected: **Format visual → Visual → Cell elements → Background color → On**. Click **fx**, choose **Gradient**, set **Lowest value** to white and **Highest value** to navy `#10233F`. Click **OK**.
31. Title: `When crashes happen (hour × day)`.

> ✅ **Check:** the darkest cell is **Wed, hour 8, with 596 crashes**, the cyclist morning commute.

**Speed zone chart**

32. Click the **Clustered column chart** icon. Drag `speed_zone` to **X-axis** and `% Serious` to **Y-axis**.
33. Drag `road_user` into **Filters on this visual**. Tick only **Pedestrian**.
34. **Format visual → Visual → Data labels → On**. Title: `Pedestrians: % killed or seriously injured, by speed zone`.
35. If the bars aren't in order 40 → 80, click the **…** on the chart → **Sort axis → speed_zone**, then **Sort ascending**.

> ✅ **Check:** 40 or less **41.3%** · 50 **45.0%** · 60 **54.3%** · 70 **63.9%** · 80 or more **65.1%**

**Crash map**

36. Click the **Azure Map** icon (a globe with a pin). If you can't see it, click **…** at the bottom of Visualizations → **Get more visuals** → search `Azure Maps` → **Add**.
37. Drag `latitude` to **Latitude**, `longitude` to **Longitude**, and `severity` to **Legend**.
38. In **Format visual**, turn **Bubble layer → Size** down to about **3**, so 30,000 dots don't become one blob.
39. Title: `Where crashes happen`.

> If Power BI says the map visual is disabled: **File → Options and settings → Options → Global → Security**, tick **Use Map and Filled Map visuals** / **Azure Maps**, click **OK** and restart Power BI.

**Filters (slicers)**

40. Click the **Slicer** icon and drag `year` into it. In **Format → Visual → Slicer settings → Style**, choose **Between**. You get a year slider.
41. Add a second slicer with `road_user`. Style: **Tile**.
42. Add a third slicer with `council`. Style: **Dropdown**.

> ✅ **Check:** pick **Melbourne** in the council slicer. Total Crashes should show **4,467**. Then clear it with the eraser icon on the slicer.

## Part 6: Make it tidy (15 minutes)

43. Line up visuals: select two or more with **Ctrl + click**, then **Format → Align → Align top** (or left).
44. Give every visual the same look: select it, then **Format visual → General → Effects → Visual border → On**, rounded corners **8**.
45. **Insert → Text box** at the bottom: `Data: Victoria road crash data, Department of Transport and Planning (CC BY 4.0). Built by Yarida Kaewthong.`
46. Click each slicer and try it. Every chart should change together.

## Part 7: Save and export (5 minutes)

47. **File → Save as** → `Desktop\melbourne road crash\powerbi\melbourne_crash_dashboard.pbix`.
48. **File → Export → Export to PDF**. Save the PDF in the same folder.
49. For a picture for your CV: press **Windows + Shift + S**, drag over the whole dashboard, then open **Snipping Tool** and save it as `powerbi\dashboard.png`.
50. Tell Claude it's done. Claude will check your numbers and add the dashboard picture to your Melbourne project page as **"Power BI dashboard, built by Yarida"**.

---

## If something goes wrong

| Problem | Fix |
|---|---|
| Numbers on a card look huge or wrong | The field is being summed. Use the measures (`Total Crashes`), not the raw columns |
| Weekdays in the wrong order | Redo step 10 (Sort by column) |
| A chart shows "Count of year" | Drag the measure `Total Crashes` into Values instead |
| The map is empty | Check steps 13 and 14 (Latitude/Longitude data category) |
| Changed the wrong visual | Press **Ctrl + Z** to undo |

## Interview talking points

- "I loaded 30,469 real crash records and checked the totals against my R analysis. They matched exactly."
- "I wrote DAX measures for crash counts and the serious-injury rate, so every chart updates when you change the filters."
- "The heat map shows cyclists are most at risk in the 8 am weekday commute, and the speed chart shows a pedestrian's chance of serious injury rises from 41% to 65% as the speed zone goes from 40 to 80+ km/h."
