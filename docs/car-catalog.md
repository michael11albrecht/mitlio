# Car catalog (P9-T09, issue #131)

The vehicle form suggests cars while you type ("Golf", "Tesla Model 3") and fills name, fuel type and consumption from a
bundled list. The list is built **offline by a developer** from the EEA CO2 monitoring data and shipped as one asset. The
app never downloads anything for this, and nothing you type leaves the device.

## Source and licence

- **Dataset:** European Environment Agency (EEA), "Monitoring of CO2 emissions from passenger cars, Regulation (EU)
  2019/631", via the EEA Discodata SQL endpoint `https://discodata.eea.europa.eu/sql`
  (dataset page: `https://www.eea.europa.eu/en/datahub/datahubitem-view/fa8b1229-3db6-495d-b18e-9c9b3267c02b`).
- **Tables used** (`[CO2Emission].[latest].*`):

  | Year | Table | Status | Distinct variants read |
  |---|---|---|---|
  | 2021 | `co2cars` (filtered `Year = 2021`, file version v24) | final | 73 319 |
  | 2022 | `co2cars_2022Fv26` | final | 44 499 |
  | 2023 | `co2cars_2023Fv28` | final | 60 394 |
  | 2024 | `co2cars_2024Fv30` | final | 50 349 |
  | 2025 | `co2cars_2025Pv31` | **provisional** | 59 780 |

  Counts are from the run that produced the committed asset (2026-11-15). Pre-2021 data is NEDC based and not used.
- **Licence:** EEA content is CC BY 4.0 (https://www.eea.europa.eu/en/legal-notice): free reuse, EEA must be
  acknowledged, the meaning must not be distorted. mitlio shows "Daten: EEA, CC BY 4.0" in the vehicle form (under the
  suggestions and under the consumption field after a pick) and a fuller statement under Settings, "Quellen und
  Lizenzen". The values are shown as what they are: manufacturer figures (WLTP).

## Rebuilding the asset

```sh
# downloads (one request per table, a few minutes) and writes the asset:
dart run packages/tooling/bin/build_car_catalog.dart \
  --output app/assets/car_catalog/catalog_v1.json.gz --save-csv build/eea_variants.csv
# or from an EEA-shaped CSV (columns Mk,Cn,Ft,Fm,Ec (cm3),Ep (KW),Fc,Z (Wh/km),Year[,R]):
dart run packages/tooling/bin/build_car_catalog.dart --input eea.csv --output app/assets/car_catalog/catalog_v1.json.gz
```

`make car-catalog` runs the first form. The script is developer-run only, never part of the app or CI. The output is
deterministic: the same input gives the same bytes (checked in `packages/tooling/test/car_catalog_test.dart`).
Refresh once a year: add the new table to `kDiscodataTables` in `packages/tooling/lib/src/car_catalog_cli.dart`, rerun,
commit the asset and update the table above.

Committed asset `app/assets/car_catalog/catalog_v1.json.gz`: SHA-256
`5d4d091f82917081f0ffc9274e1c753abee7d996a624631f905dffa953acfc3c` (53 826 bytes, 11 204 cars, 54 makes, years 2021 to
2025).

## What the script does

1. Reads distinct variants (make, commercial name, fuel type, fuel mode, engine capacity, power, WLTP fuel consumption
   `Fc` in l/100 km, electric energy consumption `Z` in Wh/km, year). The Discodata gateway refuses `GROUP BY` and
   `ORDER BY`, so registration counts cannot be summed server-side: **every distinct variant weighs 1**. An official
   CSV with the per-row `R` column is weighted by it.
2. Keeps only makes on an allow-list (`kMakeAliases`, 54 consumer brands with their EEA spellings: "VOLKSWAGEN" and "VW"
   become "VW", "MERCEDES BENZ" becomes "Mercedes-Benz"). The EEA data also holds motorhome conversions, one-off builds
   and typos; they are dropped.
3. Cleans the model name (`displayModel`): quotes, the make in front, anything after the first `/`, engine sizes and
   power figures ("GOLF / 1.5 / TSI" and "GOLF 1.5 TSI" become "Golf", "ID.3 PRO 150 KW" becomes "ID.3 Pro").
4. Drops plug-in hybrids (WLTP values far too optimistic), LPG, CNG, E85, hydrogen, rows without consumption, rows
   outside plausible limits (2 to 25 l/100 km, 80 to 400 Wh/km) and groups with less than weight 2.
5. Groups by (make, model, fuel, engine in 100 cm3, power in 5 kW) and stores the **weighted median** consumption (robust
   against single mis-reported rows) in hundredths of l or kWh per 100 km.
6. Writes gzipped JSON: `{"v":1,"source","licence","years","makes":[...],"cars":[[make,model,fuel,cc/100,kW/5,hundredths]]}`
   with fuel codes 0 petrol, 1 diesel, 2 electric, 3 petrol hybrid, 4 diesel hybrid.

## Known limits (honest)

- **Final data for 2021 to 2024, provisional for 2025.** The EEA publishes provisional data first; final values can
  differ slightly.
- **Unweighted**: popular and rare variants count the same. The median keeps outliers out, but a very common engine is
  not favoured over an exotic one.
- **Names come from national registrations** and are messy. After cleaning, some local spellings remain ("Classe A",
  "Serie 3", "Sportage 1,6"). Search is prefix based on make and model, so "golf", "vw golf", "id3" and "model 3" work;
  "3er" does not find "Serie 3". Not every car is listed; the manual path always works.
- **New cars only** (registered 2021 to 2025, EU plus Norway and Iceland). Older cars: manual entry.
- **Manufacturer values.** WLTP understates everyday consumption; see the realistic value in
  `docs/domain-rules.md`, "Car catalog". No cost-per-km defaults (wear, km rate) come from the catalog.

## App side

`CarCatalogRepository` (`app/lib/features/rides/data/repositories/car_catalog_repository.dart`) loads the asset once,
lazily, and decodes it in a separate isolate. `CarCatalog` (domain) does the prefix search. `VehicleFormViewModel`
has `searchCatalog`, `applyCatalogEntry` and `useRealisticConsumption`; DebugDrive calls the same view model through
`ext.mitlio.vehicles.catalogSearch` and `ext.mitlio.vehicles.catalogPick` (`docs/drive-protocol.md`). If the asset
cannot be loaded the form says so in plain words and keeps working by hand.
