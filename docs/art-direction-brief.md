# TraitDeck art direction brief: "Cozy Campus"

Status: **APPROVED 2026-11-18**: hero look signed off and the full batch rolled out.
Manifest: `docs/asset-manifest.json`.

## Game frame

- Player fantasy: a nervous new freshman getting through IIUM Ta'aruf Week. Each choice quietly reveals their Big Five traits.
- Core verbs: walk (click-to-move), notice (unmarked collectibles), choose (drag cards), tidy, react (QTE).
- Engine and renderer: Godot 4.6, Forward+ on D3D12, Jolt physics. 3D rooms sit under a 2D card UI layer.
- Target platforms: Windows desktop.
- Camera/view: fixed high three-quarter perspective, looking down at about 35–55°. `icc_inside` uses an override of (0, 9, 6). Assets are seen mostly from above and slightly in front, so **tops and front faces get the detail**. Back faces and undersides stay plain.
- Native viewport: 1920×1080, stretch mode `viewport`.
- Typical on-screen size: room fills the frame. A character is about 120–180 px tall, a collectible about 25–40 px, so it needs a chunky silhouette.

## Visual system

- **Shape language:** soft and chunky, toy-like. Every hard edge is bevelled (`CHUNK` = 1.8 × base width: about 0.04 m on props and 0.07–0.09 m on furniture, 2–3 segments) and shaded with weighted normals. Proportions are slightly inflated: thick tabletops, stubby legs, oversized handles and knobs. Keep a slight lean or asymmetry, never perfect CAD boxes.
- **Silhouette priorities:** each collectible must read as itself from the top-down view in 30 px, through one exaggerated feature (umbrella canopy, whistle ring, pin disc, lozenge tin lid). Each character reads by hair shape and outfit colour block.
- **Character proportions:** about 2.5 heads tall, with a big round head, small rounded torso, and mitten hands with no fingers. Eyes are simple dark ovals with one highlight, plus small blush discs. No noses or mouths are modelled; expression comes from UI portraits or emotes. Height is matched to the existing Player capsule, measured during the hero step.
- **Value structure:** light floors and walls (high value). Furniture is mid value. Collectibles and interactables are the most saturated item in their local area. The UI is the highest-contrast layer.
- **Materials:** flat-colour Principled BSDF, roughness 0.7–0.9, metallic 0 (0.3 only on the copper dome and fixtures). No photographic textures. Optional detail is limited to a soft vertex-colour gradient (darker at the base) for grounding. **No baked lighting**, because `session_manager.gd` ITEM_MOODS relights every room at runtime (act1 / golden / storm / bright, plus trait-driven light).
- **Edge treatment:** no outlines. Bevels and the shading carry the edges.
- **Lighting assumption:** one warm key light from upper left plus sky ambient, as in main_scene's DirectionalLight3D and ProceduralSky. Assets must still read under the cool storm mood with fog density 0.04.
- **Detail density:** medium-low. A few big readable props beat many small ones. Every room gets one "cozy" anchor: a plant, rug or noticeboard.
- **Motion character:** bouncy and gentle. Every character idles on a 4.8 s loop: breathing (+3% height), a 2 degree weight shift and a slow head turn. The kitten adds an ear twitch and a tail swish. Trees and bushes sway in the wind, about 3x stronger in the storm. Idles play on a per-character AnimationPlayer (`scenes/idle_animator.gd`) driving pivot empties exported from Blender; foliage sway is a vertex shader (`shaders/foliage_sway.gdshader`).
- **Never a void:** every room ships with outside surroundings (grass ground, hedges, trees, distant campus skyline) and the shared `shaders/cozy_sky.gdshader` sky (toon clouds and sun; `overcast` is driven by the storm mood).
- **Exclusions:** realism, grime, sharp edges, pure black (#000) or pure white (#FFF) surfaces, generated text or logos on meshes, real brand marks (RHB/ASNB/NotebookLM booths use plain colour plus a code-native Label3D), and copying any specific game's characters or assets. "Animal Crossing–inspired" describes the shape and colour approach only.

### Palette (shared Blender material library `pal_*`, source of truth: `art/src/build_hero.py`)

Rev 2 (2026-11-18): more saturated after hero review.

| Role | Material | Hex |
|---|---|---|
| Wall / plaster | pal_cream | #F7E3C0 |
| Trim / warm white | pal_warmwhite | #FFF3DC |
| Light wood | pal_oak | #E0A960 |
| Dark wood | pal_walnut | #9A5B34 |
| Stone / walkway | pal_stone | #D7C3A6 |
| Floor tile | pal_tile | #F3DFBF |
| Tile grout | pal_grout | #C9AE8A |
| Roof / dome terracotta | pal_terracotta | #D9643A |
| Copper fixture | pal_copper | #C87A35 |
| Wainscot / soft foliage | pal_sage | #9CCB86 |
| Foliage | pal_leaf | #5DAE4B |
| Outdoor grass | pal_grass | #8CCB5E |
| Fabric blue | pal_denim | #5FA2DD |
| Trousers / deep blue | pal_navy | #34508C |
| Fabric rose | pal_rose | #F28B95 |
| Accent peach | pal_peach | #FFB58A |
| Accent lilac | pal_lilac | #B9A3E8 |
| IIUM teal (Ta'aruf shirt) | pal_teal | #22A39A |
| IIUM gold accent | pal_gold | #F5BE3A |
| Eyes / dark detail | pal_ink | #4A3428 |
| Skin | pal_skin | #F2C9A0 |
| Hair brown | pal_hair | #5A3A28 |
| Glass (alpha 0.6) | pal_glass | #9FDCF2 |

UI pastels: mint #BFE6D0, peach #FFD3B5, butter #FFE8A3, lilac #D7C8F0. UI text is ink #4A3B33 on warmwhite #FFF6E6.
Card types each get one accent: Dialogue = mint, Action = peach, Inventory = butter, Emotion Reflection = lilac.

## Technical contract

- **Units/axes:** 1 Blender unit = 1 m. Export glTF +Y up (Blender default). The asset faces Blender −Y, which is Godot +Z, toward the camera.
- **Transforms:** apply all transforms before export, so scale is (1,1,1) and rotation 0.
- **Pivots:** floor props and characters sit at the bottom centre on the floor plane (z=0). Wall props pivot at the back-bottom centre. Collectibles pivot at the bottom centre. Rooms pivot at world origin. **New** rooms put the floor top at **y = 0**. **Upgraded** rooms keep their old footprint and floor height (Room 304: floor top y = 0.1), so the baked navmesh and existing placements still fit.
- **Collision in glb:** `-colonly` box proxies (Godot import suffix), never the bevelled render mesh.
- **Budgets (triangles):** collectible ≤ 800, prop ≤ 2 000, character ≤ 4 000, room shell plus furniture ≤ 40 000. At most 8 materials per room.
- **Materials:** only reused `pal_*` materials, which Godot imports as StandardMaterial3D. No image textures except optional UI-portrait decals.
- **Collision:** never the render mesh. Use Godot primitive shapes in the `.tscn`, or a `-col` suffixed box hull in the glb for room walls and floors.
- **Export:** `.glb`, with modifiers applied, +Y up, and only the selected collection. Keep editable sources in `art/src/<id>.blend`.
- **Naming/folders:** `assets/rooms/<room>.glb`, `assets/props/<prop>.glb`, `assets/collectibles/<item_id>.glb` (ids exactly as in `inventory_manager.gd`), `assets/characters/<id>.glb`, `assets/ui/*.svg`. Do not overwrite the old flat `assets/*.glb` until their replacements are approved.
- **UI art:** SVG with rounded corners (radius 24 px at 1080p) and a 6 px soft drop shadow, in the same style as the existing `CardBG/CardFront.svg`. All text stays code-native (font: `art/FOT-RodinBokutoh Pro EB.otf` via `game_theme.tres`).
- **Collectible glint:** a single shared spatial shader (rim pulse plus a sparkle whose strength rises with player proximity), driven by the existing `unmarked_collectible.gd`. No waypoint arrow.

### Known placement issues to fix during room upgrades

- `icc_inside`: all markers are at y=7.94 on a mezzanine nav strip. The ExhibitionBoard is at z=3.0 with no nav underneath, and the collectible is at z=4.3, 0.05 m off the strip. This gets rebuilt with the floor at y=0.
- `mahallah_room`, `mo_office`, `sports_centre`: SpawnPoint is at y=0.205, below the y=0.5 nav plane. New rooms put both the floor and the nav at 0.

## Visual target (approval gate)

- **Hero set:** Room 304 (`mahallah_room`). It includes the room shell, beds, lockers and tables restyled, the `wet_wipes` collectible (already placed there), the `TidyDeskBooks` messy and tidy states, and the Action card frame SVG.
- Approval is judged in-engine at 1920×1080 under the `act1` and `storm` moods. Blender renders alone do not count.
- Built 2026-11-18. Source: `art/src/hero_room304.blend`. Captures: `docs/hero_review/`.
- **Approved by the project owner on 2026-11-18.** Full batch built the same day (captures: `docs/batch_review/`).
