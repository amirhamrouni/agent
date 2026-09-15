# Hero asset and reference provenance

No external mesh, photograph, texture or proprietary brand artwork has been imported into the game by this recovery.

| Asset | Source | Rights / attribution | Use |
|---|---|---|---|
| Modular facade, theatre-inspired architectural shell | `source_overlay/scripts/world/hero/HeroMeshKit.gd`, original code authored for this project | Original project content; no external attribution requirements | Batched mesh surfaces, 4 facade variants |
| Curved palm and ficus mesh, near/far representations | same original generator | Original project content | Shared meshes with hard visibility LOD switching |
| Pavement/asphalt shader | `source_overlay/shaders/hero_paving.gdshader`, original project code | Original project content | World-coordinate material, no external imagery |
| Road locations and theatre footprint | Existing `data/osm/tunis_bourguiba_processed.json`; origin 36.8,10.1825 | ODbL-1.0; © OpenStreetMap contributors; retain existing provenance | Location/reference; not facade appearance |
| Promenade reference, 2025 article | https://soukra.co/top-ten-architecture-sites-tunis/ | License not established; reference viewing only; NOT imported or redistributed | Ficus rows, tiled promenade, dark iron benches/lamps |
| Municipal theatre reference | https://www.reseau-euromed.org/en/ville-membre/tunis-2/ | License not established; reference viewing only; NOT imported or redistributed | Triple arches, loggia, pale frontage and curved parapet silhouette |

Reference photographs were viewed, not used as texture sources. The theatre model is an original architectural approximation, not a measured photogrammetry reconstruction; sculptural details remain incomplete. Generic shop names are fictional. Vegetation positions and building elevations outside the OSM constraints are authored approximations and require visual review.

Texture budgets for this first geometry pass: zero external image texture bytes; procedural paving only. This is not a claim that production PBR texture requirements are complete. Near trees end at 75 m; far trees begin at 75 m and end at 260 m, with shadows disabled on far ficus. Facades share four meshes and material sets. No per-window Node3D allocation.
