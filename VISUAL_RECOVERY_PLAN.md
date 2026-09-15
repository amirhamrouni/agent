# Habib Bourguiba visual recovery

Baseline: main 55d7121359d4b7e6dd95ad7ad16d6d0d866b5006, recovered 2026-09-15.
Owner physical test: functional prototype PASS; visual slice, realism and physical visual acceptance FAIL.
No screenshot attachments were available in this turn. The owner's written observations are accepted as failure evidence; pixel-level inspection of those original images is not claimed.

## Source of truth
Android active workflow: `.github/workflows/hayat-tounes-android-xz.yml`.
Reconstruction order: `raw_source_packs` → `source_overlay_packs` → `source_overlay`.
`project.godot` loads `main_production.tscn`, which attaches `scripts/core/ProductionWorld.gd`.
Modify loose overlay files only; keep packed historical sources for rollback.

## Evidence audit
- Android run 34962197258: reported success by GitHub Actions API, not physical acceptance.
- Visual run 34962197266: reported success, but capture instantiates ONLY two art passes in a separate scene with its own ground and lights. It does not verify production composition.
- Identity run 34962197211 failed at job 104358157921: real log says expected 96 runtime files, actual 97; expected digest is stale. Source-artifact run also failed. These failures must be repaired, not suppressed.
- Existing state explicitly records real_player_asset=false, real_vehicle_count=0, visual_milestone_pass=false.
- Issues #1–#7 cover the existing slice. No new gameplay work authorized by this recovery.

## Visible failure → actual source
| Element | Source | Recovery |
|---|---|---|
| Plain extrusions | `scripts/world/osm/OsmWorldLoader.gd::_build_building` | Retain geographic data and outside context; replace hero visuals with modular facade assets |
| Box facades | `scripts/world/art/TunisFacadePass.gd::_build_facade_row` | Correct buried/back-facing frontage; recessed openings, cornices, real railings |
| Ground slab | `scripts/core/ProductionWorld.gd::_build_real_map_support_layer` | Dark asphalt, paving material, aligned promenade |
| Narrow 2.6 m median | `TunisPublicRealmPass.gd::_build_center_median` | Rebuild against actual divided OSM carriageways |
| Rectangular palm fronds | `ProductionWorld.gd::_make_palm`, `TunisPublicRealmPass.gd::_build_palms` | Original curved leaf/frond mesh with shared materials and LOD |
| Primitive player | `scripts/player/visuals/PlayerVisualFactory.gd::_fallback` | Proper human mesh and animation; not accepted until rendered |
| Primitive traffic | `scripts/world/PopulationSpawner.gd`, `scripts/vehicles/visuals/VehicleVisualFactory.gd` | Keep movement logic; swap visual resource |
| Washed out daylight | `BourguibaLightingProfile.gd`, `DayNightManager.gd` | One coherent daylight intensity; time manager currently overwrites quality lighting |
| High camera | `ProductionWorld.gd::_build_player` | Audit 1.25 m pivot + 3.8 m camera rise and 7.5 m distance |
| False visual confidence | `tools/tests/bourguiba_visual_capture.gd` | Capture production scene, six fixed cameras, report capture success separately from art acceptance |

## Locked hero area
240 m segment around the Municipal Theatre, bounded in the existing local OSM projection by approximately x=-250 to -10 m. Centre (-130, 30), longitudinal direction (1, -0.12). Exact local scene transform: origin (-130,0,30), Y rotation atan(0.12); 240 m along local X. Existing OSM origin 36.8 N, 10.1825 E. Theatre footprint ID 95130030, north carriageway 577010717, south carriageway 100081140. Use the road geometry as spatial constraints; do not label invented architecture a survey reconstruction. Preserve navigation graphs, traffic coordination, economy, saves and mission logic.

## Sequence and acceptance
1. Repair source identity evidence and capture the actual production baseline.
2. Produce original modular facade/paving/vegetation assets with provenance; remove overlapping prototype hero visuals.
3. Render fixed six-camera views and inspect before further scope.
4. Correct vehicles/player, scale and daylight; rerender.
5. Measure rendering statistics and texture budgets; implement distance/quality policies.
6. Exact Godot 4.7.2 import/runtime/deterministic tests; Android CI; signing and zipalign evidence.
7. Deliver APK only after runtime/build verification. Physical-device acceptance remains PENDING OWNER TEST; realism remains FAIL until images support acceptance.

Required views: 01_avenue_long_view, 02_sidewalk_view, 03_facade_close_view, 04_intersection_view, 05_player_street_view, 06_taxi_view.
Reference comparison dimensions: composition, human/road/building scale, facade identity, materials, shadows/exposure, vegetation, cars, people, Tunis identity. Luminance and node counts are capture sanity checks only.

Rollback: revert recovery commits; packed baseline is untouched. Do not restore an older save schema or alter mission identifiers.
