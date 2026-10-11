# Walking and Cycling Safety in Melbourne: Findings Note

**Yarida Kaewthong · October 2026**

## Data and method

Real Victorian road crash records for metro Melbourne, 2012 to 2025 (142,875 injury crashes; 14,378 involving a pedestrian, 16,357 a cyclist), analysed in R. The methods are a trend over time, an hour-by-weekday heat map, severity rates with 95% confidence intervals, and Getis-Ord Gi* hot-spot detection on a hexagon grid.

## Findings

1. **Half of all crashes happen in 6% of the map.** In 2021 to 2025, 49% of pedestrian and cyclist crashes fell inside statistically significant (99%) hot spots covering 273 of 4,363 one-kilometre hexagons. These were concentrated in the City of Melbourne (1,397 crashes), Yarra (717) and Port Phillip (591), with a separate cluster in Dandenong. The single worst 500 m cells were on Elizabeth St in the CBD (71 crashes) and Chapel St (51).
2. **Faster roads, worse injuries for pedestrians.** The share of pedestrian crashes that killed or seriously injured someone rose from 41% in 40 km/h zones to 54% at 60 km/h and 65% at 80 km/h and above (chi-square test for trend, χ² = 274.9, p < 0.001).
3. **Darkness makes it worse.** 46% of daylight pedestrian crashes were serious, against 56% in the dark with street lights and 63% without them.
4. **Timing differs by user.** Cyclist crashes peak in the weekday morning commute (busiest hour: Wednesday 8 am). Pedestrian crashes peak at 3 pm on weekdays, around school pick-up time.
5. **Dooring is common.** Hitting the door of a parked car was the second most common cyclist crash movement: 1,822 crashes, 11% of all cyclist crashes.
6. **COVID showed what fewer people on foot looks like.** Pedestrian crashes fell 34% from 2019 to 2020 (1,061 to 696), while cyclist crashes barely changed (1,126 to 1,072).

## What it suggests

- **Lower speeds where people walk:** extend 40 km/h zones across the inner-city hot spots, where the step from 40 to 60 km/h adds 13 percentage points of serious injuries.
- **Separated bike lanes and door-zone design** on commuter routes into the CBD, Yarra and Port Phillip.
- **Lighting** at pedestrian crash locations without street lights, and school-time crossing measures around the 3 pm peak.

## Limits

Injury crashes only, and no measure of how many people walk or cycle in each area, so hot spots partly reflect where people walk and cycle most. Gi* results are not adjusted for multiple testing.
