# TraitDeck "Cozy Campus" full batch (approved hero look, 2026-11-18). Blender 5.2.
# Run inside Blender: exec(open(<this file>).read()); then call build_props(), build_characters(), build_rooms().
# Reuses helpers, palette and conventions from build_hero.py (assets face -Y, bottom-centre pivots, pal_* materials).
import bpy, math, os
exec(open(os.path.join(r"G:/IIUM Docs/Year 3/Sem 2/FYP 1/trait-deck/art/src", "build_hero.py")).read())

def _use_scene():
    sc = bpy.data.scenes.get("hero") or bpy.data.scenes.new("hero")
    bpy.context.window.scene = sc

# ================================================================ collectibles (<= 800 tris, ~0.2-0.5 m, chunky)
def c_highlighter_pen(C):
    cyl("Body", 0.045, 0.24, (-0.12, 0, 0.045), "gold", C, bevel=0.012, rot=(0, 90, 0), verts=12)
    cyl("Cap", 0.05, 0.09, (0.12, 0, 0.045), "teal", C, bevel=0.015, rot=(0, 90, 0), verts=12)
    cyl("Tip", 0.03, 0.05, (-0.17, 0, 0.045), "warmwhite", C, bevel=0.008, rot=(0, -90, 0), r2=0.012, verts=10)
    box("Clip", (0.08, 0.02, 0.02), (0.15, 0, 0.09), "teal", C, bevel=0.008)

def c_adapter_plug(C):
    box("Body", (0.18, 0.13, 0.11), (0, 0, 0), "warmwhite", C, bevel=0.03)
    for x in (-0.045, 0.045):
        box(f"Pin{x}", (0.02, 0.035, 0.06), (x, 0.08, 0.02), "ink", C, bevel=0.006)
    box("PinTop", (0.025, 0.035, 0.05), (0, 0.08, 0.065), "ink", C, bevel=0.006)
    box("Socket", (0.1, 0.01, 0.04), (0, -0.068, 0.04), "stone", C, bevel=0.005)
    ball("Led", 0.012, (0.06, -0.068, 0.085), "leaf", C, u=8, v=6)

def c_cat_treats(C):
    box("Pouch", (0.2, 0.08, 0.25), (0, 0, 0), "rose", C, bevel=0.035)
    box("Band", (0.205, 0.085, 0.05), (0, 0, 0.17), "gold", C, bevel=0.015)
    ball("Fish", 0.045, (-0.01, -0.045, 0.09), "warmwhite", C, scale=(1.3, 0.35, 0.8), u=10, v=6)
    cyl("FishTail", 0.03, 0.04, (0.06, -0.045, 0.09), "warmwhite", C, bevel=0, rot=(0, 90, 0), r2=0.0, verts=6)

def c_campus_map(C):
    for k, (x, rz, c) in enumerate([(-0.11, 12, "sage"), (0.0, -12, "warmwhite"), (0.11, 12, "denim")]):
        box(f"Panel{k}", (0.11, 0.26, 0.012), (x, 0, 0.02 if k == 1 else 0.0), c, C, bevel=0.004, rot=(0, rz, 0), chunk=False)
    box("Path", (0.02, 0.2, 0.004), (0.0, 0, 0.034), "gold", C, bevel=0, chunk=False)
    ball("Pin", 0.022, (0.02, -0.04, 0.05), "terracotta", C, u=8, v=6)

def c_pocket_notebook(C):
    box("Cover", (0.14, 0.2, 0.04), (0, 0, 0), "peach", C, bevel=0.012)
    box("Pages", (0.125, 0.19, 0.026), (0.006, 0, 0.007), "warmwhite", C, bevel=0.004, chunk=False)
    box("Elastic", (0.015, 0.205, 0.045), (0.045, 0, -0.002), "ink", C, bevel=0.005, chunk=False)
    cyl("Pencil", 0.01, 0.19, (-0.07, 0, 0.025), "gold", C, bevel=0, rot=(90, 0, 0), verts=6)

def c_electrolyte_sachet(C):
    box("Sachet", (0.2, 0.13, 0.035), (0, 0, 0), "denim", C, bevel=0.015)
    box("Band", (0.205, 0.04, 0.037), (0, 0.02, 0), "warmwhite", C, bevel=0.01)
    ball("Drop", 0.03, (-0.05, -0.03, 0.035), "gold", C, scale=(0.8, 0.8, 0.4), u=10, v=6)
    box("Tear", (0.02, 0.135, 0.02), (0.1, 0, 0.008), "denim", C, bevel=0.006)

def c_plastic_dish(C):
    cyl("Dish", 0.1, 0.05, (0, 0, 0), "rose", C, bevel=0.012, r2=0.14, verts=20)
    cyl("Well", 0.085, 0.01, (0, 0, 0.045), "warmwhite", C, bevel=0.003, r2=0.12, verts=20)

def c_lozenges(C):  # in-game name: Dextrose Tablets
    box("Card", (0.2, 0.13, 0.02), (0, 0, 0), "warmwhite", C, bevel=0.008)
    for i in range(3):
        for j in range(2):
            ball(f"Tab{i}{j}", 0.022, (-0.06 + i * 0.06, -0.03 + j * 0.06, 0.022), "lilac", C, scale=(1, 1, 0.55), u=10, v=6)
    box("Strip", (0.2, 0.025, 0.022), (0, 0.055, 0), "teal", C, bevel=0.006, chunk=False)

def c_umbrella(C):
    cyl("Canopy", 0.06, 0.36, (-0.18, 0, 0.06), "denim", C, bevel=0.02, rot=(0, 90, 0), r2=0.025, verts=10)
    box("Strap", (0.03, 0.13, 0.13), (0.0, 0, 0.0), "gold", C, bevel=0.012)
    cyl("Tip", 0.012, 0.05, (-0.2, 0, 0.06), "ink", C, bevel=0, rot=(0, -90, 0), verts=6)
    cyl("Shaft", 0.014, 0.1, (0.16, 0, 0.06), "stone", C, bevel=0, rot=(0, 90, 0), verts=8)
    cyl("Handle", 0.03, 0.09, (0.26, 0, 0.06), "walnut", C, bevel=0.012, rot=(0, 90, 0), verts=10)
    ball("HandleEnd", 0.04, (0.35, 0, 0.08), "walnut", C, u=10, v=8)

def c_flashlight_whistle(C):
    cyl("Torch", 0.04, 0.2, (-0.12, 0, 0.04), "teal", C, bevel=0.012, rot=(0, 90, 0), verts=12)
    cyl("Head", 0.055, 0.06, (0.08, 0, 0.04), "teal", C, bevel=0.015, rot=(0, 90, 0), r2=0.045, verts=12)
    cyl("Lens", 0.045, 0.01, (0.14, 0, 0.04), "glass", C, bevel=0, rot=(0, 90, 0), verts=12)
    cyl("Ring", 0.03, 0.008, (-0.16, 0.05, 0.0), "stone", C, bevel=0, verts=10)
    box("Whistle", (0.08, 0.04, 0.04), (-0.12, 0.1, 0.0), "gold", C, bevel=0.015)
    cyl("WhistleBall", 0.028, 0.045, (-0.09, 0.1, 0.0), "gold", C, bevel=0.01, verts=10)

def c_ors_packets(C):
    for k, (dz, rz, c) in enumerate([(0, 0, "peach"), (0.032, 14, "warmwhite"), (0.064, -9, "peach")]):
        box(f"Packet{k}", (0.17, 0.12, 0.03), (0, 0, dz), c, C, bevel=0.012, rot=(0, 0, rz))
    box("Cross", (0.05, 0.015, 0.032), (0, 0, 0.065), "rose", C, bevel=0.004, chunk=False, rot=(0, 0, -9))
    box("Cross2", (0.015, 0.05, 0.032), (0, 0, 0.065), "rose", C, bevel=0.004, chunk=False, rot=(0, 0, -9))

def c_lapel_pin(C):
    cyl("Rim", 0.1, 0.03, (0, 0, 0), "gold", C, bevel=0.01, verts=16)
    cyl("Face", 0.08, 0.034, (0, 0, 0.0), "teal", C, bevel=0.008, verts=16)
    for k in range(5):
        a = math.radians(90 + k * 72)
        ball(f"Star{k}", 0.018, (0.035 * math.cos(a), 0.035 * math.sin(a), 0.034), "warmwhite", C, scale=(1, 1, 0.5), u=8, v=6)
    ball("StarCore", 0.022, (0, 0, 0.034), "warmwhite", C, scale=(1, 1, 0.5), u=8, v=6)

def c_club_handbook(C):
    box("Cover", (0.24, 0.32, 0.06), (0, 0, 0), "teal", C, bevel=0.015)
    box("Pages", (0.22, 0.3, 0.042), (0.008, 0, 0.009), "warmwhite", C, bevel=0.004, chunk=False)
    cyl("Emblem", 0.055, 0.012, (0, 0.02, 0.06), "gold", C, bevel=0.004, verts=16)
    box("Ribbon", (0.025, 0.06, 0.004), (0.06, -0.17, 0.0), "rose", C, bevel=0, chunk=False)

COLLECTIBLES = {k[2:]: v for k, v in globals().items() if k.startswith("c_")}

# ================================================================ tidy tasks (Messy + Tidy children)
def t_desk_stationery(K, mess, tidy):
    for k, (x, y, rz, c) in enumerate([(-0.25, 0.1, 30, "gold"), (0.1, -0.2, -60, "teal"), (0.3, 0.2, 80, "rose")]):
        cyl(f"MPen{k}", 0.014, 0.17, (x, y, 0.014), c, K, bevel=0, rot=(90, 0, rz), verts=8, parent=mess)
    for k in range(9):  # tangled cable
        ball(f"MCable{k}", 0.018, (-0.3 + k * 0.07, 0.12 * math.sin(k * 1.3), 0.018), "ink", K, u=8, v=6, parent=mess)
    box("MCharger", (0.07, 0.06, 0.04), (0.33, -0.05, 0), "warmwhite", K, bevel=0.012, parent=mess)
    for k, (x, y, rz, c) in enumerate([(-0.1, -0.25, 20, "gold"), (0.2, 0.3, -15, "rose"), (-0.32, -0.15, 5, "lilac")]):
        box(f"MNote{k}", (0.08, 0.08, 0.004), (x, y, 0), c, K, bevel=0.002, rot=(0, 0, rz), chunk=False, parent=mess)
    cyl("TCup", 0.05, 0.12, (-0.08, 0, 0), "lilac", K, bevel=0.015, verts=12, parent=tidy)
    for k, (dx, c) in enumerate([(-0.015, "gold"), (0.015, "teal"), (0.0, "rose")]):
        cyl(f"TPen{k}", 0.011, 0.17, (-0.08 + dx, dx, 0.03), c, K, bevel=0, rot=(6 * (k - 1), 6, 0), verts=6, parent=tidy)
    for k in range(10):  # coiled cable
        a = k / 10 * 2 * math.pi
        ball(f"TCoil{k}", 0.016, (0.1 + 0.05 * math.cos(a), 0.05 * math.sin(a), 0.016), "ink", K, u=8, v=6, parent=tidy)
    box("TCharger", (0.07, 0.06, 0.04), (0.1, 0, 0), "warmwhite", K, bevel=0.012, parent=tidy)
    box("TNotes", (0.08, 0.08, 0.02), (0.0, 0.1, 0), "gold", K, bevel=0.004, chunk=False, parent=tidy)

def t_luggage(K, mess, tidy):
    box("MBase", (0.7, 0.45, 0.14), (0, 0, 0), "teal", K, bevel=0.04, parent=mess)
    box("MLid", (0.7, 0.45, 0.1), (0, 0.27, 0.12), "teal", K, bevel=0.04, rot=(-70, 0, 0), parent=mess)
    for k, (x, y, c, s) in enumerate([(-0.15, -0.05, "rose", 0.14), (0.12, 0.02, "warmwhite", 0.12), (0.4, -0.3, "denim", 0.13),
                                      (-0.45, -0.25, "gold", 0.11), (0.05, -0.4, "lilac", 0.12)]):
        ball(f"MCloth{k}", s, (x, y, 0.14 if abs(x) < 0.35 and abs(y) < 0.2 else 0.04), c, K, scale=(1.4, 1.1, 0.45), u=12, v=8, parent=mess)
    box("TCase", (0.5, 0.28, 0.72), (0, 0, 0.04), "teal", K, bevel=0.05, parent=tidy)
    box("TStripe", (0.51, 0.29, 0.06), (0, 0, 0.4), "gold", K, bevel=0.02, parent=tidy)
    box("THandle", (0.16, 0.05, 0.05), (0, 0, 0.76), "ink", K, bevel=0.02, parent=tidy)
    for x in (-0.18, 0.18):
        cyl(f"TWheel{x}", 0.035, 0.04, (x, 0.1, 0.0), "ink", K, bevel=0.01, rot=(0, 90, 0), verts=10, parent=tidy)

def t_backpack(K, mess, tidy):
    box("MPack", (0.36, 0.5, 0.2), (0, 0, 0), "rose", K, bevel=0.07, rot=(0, 0, 25), parent=mess)
    box("MPocket", (0.26, 0.2, 0.06), (0.02, -0.12, 0.18), "peach", K, bevel=0.03, rot=(0, 0, 25), parent=mess)
    for k, (x, y, c) in enumerate([(-0.4, 0.2, "denim"), (0.35, -0.25, "warmwhite"), (-0.25, -0.35, "sage")]):
        ball(f"MShirt{k}", 0.16, (x, y, 0.03), c, K, scale=(1.4, 1.0, 0.3), u=12, v=8, parent=mess)
    box("TPack", (0.38, 0.22, 0.48), (-0.15, 0, 0), "rose", K, bevel=0.08, parent=tidy)
    box("TPocket", (0.28, 0.05, 0.2), (-0.15, -0.12, 0.08), "peach", K, bevel=0.03, parent=tidy)
    for s in (-1, 1):
        box(f"TStrap{s}", (0.05, 0.03, 0.36), (-0.15 + s * 0.11, 0.12, 0.08), "walnut", K, bevel=0.012, parent=tidy)
    for k, c in enumerate(("denim", "warmwhite", "sage")):
        box(f"TFold{k}", (0.3, 0.24, 0.06), (0.25, 0, k * 0.06), c, K, bevel=0.025, parent=tidy)

TIDY = {"desk_stationery": t_desk_stationery, "luggage": t_luggage, "backpack": t_backpack}

def cap_segments(col, n):
    """Small props read the same at game scale with fewer bevel segments; keeps them inside the tri budget."""
    for o in col.all_objects:
        for m in o.modifiers:
            if m.type == 'BEVEL': m.segments = min(m.segments, n)

def build_props():
    _use_scene(); out = {}
    for cid, fn in COLLECTIBLES.items():
        C = coll("EX_" + cid); fn(C); cap_segments(C, 2)
        export(C, f"assets/collectibles/{cid}.glb"); out[cid] = tris(C)
    for tid, fn in TIDY.items():
        K = coll("EX_tidy_" + tid); mess, tidy = empty("Messy", K), empty("Tidy", K); fn(K, mess, tidy); cap_segments(K, 1)
        export(K, f"assets/props/tidy_{tid}.glb"); out["tidy_" + tid] = tris(K)
    bpy.ops.wm.save_as_mainfile(filepath=PROJECT + "art/src/batch.blend")
    return out
