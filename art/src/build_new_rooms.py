# TraitDeck new rooms (timeline items 13-16 + clinic). Blender 5.2.
# Run inside Blender: exec(open(<this file>).read()); build_new_rooms()
# Layout comes from new_rooms_spec.py (Godot coords). Here Blender (x, y, z) = Godot (x, -z, y).
# New rooms put the floor top at z = 0; walls/floor collide via "-colonly" boxes.
import bpy, math, os
SRC = r"G:/IIUM Docs/Year 3/Sem 2/FYP 1/trait-deck/art/src"
exec(open(os.path.join(SRC, "build_rooms.py")).read())
exec(open(os.path.join(SRC, "new_rooms_spec.py")).read())

def g(x, z):
    """Godot (x, z) ground point -> Blender (x, y)."""
    return (x, -z)

def shell(C, floor_m, grout_m, step):
    f = FLOOR
    w, d = f["x1"] - f["x0"], f["z1"] - f["z0"]
    cx, cy = (f["x0"] + f["x1"]) / 2, -(f["z0"] + f["z1"]) / 2
    box("Floor-colonly", (w, d, 0.1), (cx, cy, -0.1), "stone", C, bevel=0)
    box("Floor", (w + 0.3, d + 0.3, 0.12), (cx, cy, -0.12), floor_m, C, bevel=0.03)
    grout(C, "Grout", f["x0"], f["x1"], -f["z1"], -f["z0"], 0.0, step=step, m=grout_m)

def back_wall(C, h, m="cream", y=9.2, cap="terracotta"):
    box("WallBack-colonly", (18.4, 0.4, h), (0, y, 0), "stone", C, bevel=0)
    box("WallBack", (18.6, 0.4, h), (0, y, 0), m, C, bevel=0.06)
    box("WallBackCap", (18.9, 0.6, 0.25), (0, y, h), cap, C, bevel=0.08)
    box("WallBackWain", (18.4, 0.06, 1.1), (0, y - 0.22, 0), "sage", C, bevel=0.02)
    box("WallBackRail", (18.4, 0.1, 0.1), (0, y - 0.24, 1.1), "warmwhite", C, bevel=0.03)

def column(C, name, x, y, h=4.5, r=0.32):
    cyl(name + "Base", r + 0.1, 0.35, (x, y, 0), "teal", C, bevel=0.05, verts=16)
    cyl(name, r, h - 0.7, (x, y, 0.35), "cream", C, bevel=0.04, verts=16)
    cyl(name + "Cap", r + 0.12, 0.35, (x, y, h - 0.35), "gold", C, bevel=0.05, verts=16)

def dome(O, x, y, r=5.0, drum_h=3.0, base=3.5):
    cyl("DomeDrum", r, drum_h, (x, y, base), "cream", O, bevel=0.2, verts=32)
    cyl("DomeRing", r + 0.3, 0.4, (x, y, base + drum_h), "gold", O, bevel=0.1, verts=32)
    ball("Dome", r * 1.02, (x, y, base + drum_h + 0.2), "copper", O, scale=(1, 1, 0.85), u=32, v=16)
    cyl("DomeFinial", 0.15, 1.6, (x, y, base + drum_h + r * 0.85), "gold", O, bevel=0.03, verts=8)
    ball("DomeFinialBall", 0.35, (x, y, base + drum_h + r * 0.85 + 1.0), "gold", O, u=12, v=8)
    for k, dx in enumerate((-r - 4.5, r + 4.5)):
        cyl(f"Minaret{k}", 0.7, 14, (x + dx, y - 2, 0), "cream", O, bevel=0.1, verts=12)
        cyl(f"MinaretBalcony{k}", 1.0, 0.4, (x + dx, y - 2, 10), "gold", O, bevel=0.08, verts=12)
        cyl(f"MinaretCap{k}", 0.85, 2.2, (x + dx, y - 2, 14), "copper", O, bevel=0.05, r2=0.05, verts=12)

def sign_board(C, name, x, y, panel="cream", frame="walnut", strips=()):
    for s in (-1, 1):
        cyl(f"{name}Post{s}", 0.06, 1.6, (x + s * 0.75, y, 0), frame, C, bevel=0.02, verts=8)
    box(f"{name}Frame", (1.7, 0.1, 1.1), (x, y, 0.6), frame, C, bevel=0.04)
    box(f"{name}Panel", (1.5, 0.06, 0.9), (x, y - 0.03, 0.7), panel, C, bevel=0.02)
    for k, c in enumerate(strips):
        box(f"{name}Strip{k}", (1.3, 0.02, 0.1), (x, y - 0.065, 1.42 - k * 0.14), c, C, bevel=0.01, chunk=False)

def hedge_row(C, name, y, x0=-8.8, x1=8.8, flowers=True):
    box(name, (x1 - x0, 0.8, 0.8), ((x0 + x1) / 2, y, 0), "leaf", C, bevel=0.2, seg=3)
    if flowers:
        for k in range(int((x1 - x0) / 1.1)):
            ball(f"{name}Flower{k}", 0.09, (x0 + 0.5 + k * 1.1, y - 0.3, 0.78), ("rose", "gold", "warmwhite", "lilac")[k % 4], C, u=8, v=6)

# ---------------------------------------------------------------- rooms
def r_shas_foyer(C, O):
    shell(C, "warmwhite", "cream", 1.2)
    back_wall(C, 5.0)
    for k, (bx, c) in enumerate([(-4.0, "denim"), (0.0, "gold"), (4.0, "lilac")]):  # RHB / ASNB / NotebookLM booths
        x, y = g(bx, -7.7)
        box(f"Booth{k}Back", (3.0, 0.2, 2.2), (x, 8.85, 0), c, C, bevel=0.05)
        box(f"Booth{k}Counter", (2.6, 0.8, 1.0), (x, y, 0), c, C, bevel=0.06)
        box(f"Booth{k}Top", (2.8, 0.95, 0.08), (x, y, 1.0), "oak", C, bevel=0.03)
        box(f"Booth{k}Sign", (2.8, 0.15, 0.65), (x, 7.6, 2.45), "warmwhite", C, bevel=0.05)
        box(f"Booth{k}SignBand", (2.85, 0.16, 0.12), (x, 7.6, 2.45), c, C, bevel=0.03)
        for s in (-1, 1):
            cyl(f"Booth{k}Pole{s}", 0.05, 2.4, (x + s * 1.3, 7.7, 1.0), "walnut", C, bevel=0.01, verts=8)
        box(f"Booth{k}Screen", (0.5, 0.05, 0.35), (x + 0.6, y + 0.1, 1.08), "ink", C, bevel=0.02, rot=(-15, 0, 0))
    for s in (-1, 1):  # side colonnades
        for k, y in enumerate((-3.0, 1.0, 5.0, 8.4)):
            column(C, f"Col{s}{k}", s * 8.4, y, h=5.0)
    for k, z in enumerate([-6.5, -5.6, -4.7, -3.8, -2.9, -2.0]):  # queue stanchions along the RHB lane
        for xl in (-1.5, -2.9):
            x, y = g(xl, z)
            cyl(f"StanchionBase{xl}{k}", 0.16, 0.05, (x, y, 0), "copper", C, bevel=0.015, verts=12)
            cyl(f"Stanchion{xl}{k}", 0.04, 0.9, (x, y, 0.05), "copper", C, bevel=0.01, verts=8)
            ball(f"StanchionTop{xl}{k}", 0.06, (x, y, 0.97), "gold", C, u=8, v=6)
            if k:
                cyl(f"Rope{xl}{k}", 0.025, 0.9, (x, y, 0.88), "rose", C, bevel=0, verts=6, rot=(-90, 0, 0))
    x, y = g(7.6, 1.0)  # phone charging kiosk (next to the adapter plug)
    box("Kiosk", (0.7, 0.55, 1.35), (x, y, 0), "teal", C, bevel=0.06)
    box("KioskScreen", (0.5, 0.04, 0.35), (x, y - 0.29, 0.85), "glass", C, bevel=0.02)
    for k in range(3):
        box(f"KioskSlot{k}", (0.12, 0.04, 0.2), (x - 0.2 + k * 0.2, y - 0.29, 0.35), "ink", C, bevel=0.01)
    x, y = g(-7.4, 0.5)
    sign_board(C, "PrayerBoard", x, y, panel="warmwhite", frame="teal", strips=("gold", "leaf", "denim", "rose"))
    for s in (-1, 1):
        planter(C, f"Planter{s}", s * 6.9, 8.4, w=1.2, d=0.5)
    bunting(C, "Bunting", (-8.4, 1.0), (8.4, 1.0), 4.6, n=18)
    dome(O, 0, 17.5)
    surroundings(O, -9.5, 9.5, -5.5, 9.6, 13, skyline=False)

def r_mosque_walkway(C, O):
    shell(C, "grass", "sage", 100.0)  # step larger than the floor: plain grass, no grout lines
    box("Walkway", (18.2, 6.2, 0.04), (0, 5.0, 0.0), "stone", C, bevel=0.02)
    grout(C, "WalkGrout", -9, 9, 2.0, 8.0, 0.04, step=1.0, m="cream")
    box("Roof", (18.6, 5.0, 0.3), (0, 5.2, 3.3), "terracotta", C, bevel=0.08)
    box("RoofFascia", (18.6, 0.2, 0.35), (0, 2.75, 3.15), "walnut", C, bevel=0.05)
    for k, x in enumerate(range(-8, 9, 3)):
        column(C, f"BackPost{k}", x + 0.5, 7.6, h=3.3, r=0.2)
    for s in (-1, 1):
        column(C, f"FrontPost{s}", s * 8.6, 2.9, h=3.3, r=0.2)
    box("CompoundWall", (18.4, 0.4, 1.2), (0, 8.4, 0), "stone", C, bevel=0.06)
    box("CompoundCap", (18.6, 0.55, 0.15), (0, 8.4, 1.2), "cream", C, bevel=0.05)
    box("WallBack-colonly", (18.4, 0.4, 1.4), (0, 8.4, 0), "stone", C, bevel=0)
    x, y = g(2.5, -4.6)  # stone bench the kitten shelters under
    box("BenchSeat", (1.7, 0.55, 0.14), (x, y, 0.4), "stone", C, bevel=0.05)
    for s in (-1, 1):
        box(f"BenchLeg{s}", (0.25, 0.45, 0.4), (x + s * 0.6, y, 0), "stone", C, bevel=0.05)
    x, y = g(-3.0, -6.6)
    sign_board(C, "WalkwaySign", x, y, panel="warmwhite", frame="walnut", strips=("teal",))
    hedge_row(C, "HedgeFront", -4.6)
    for k, (gx, gz) in enumerate([(-6.5, 1.0), (6.8, -0.5)]):
        tree(f"GardenTree{k}", *g(gx, gz), 1.1, C)
    for s in (-1, 1):
        cyl(f"LampPost{s}", 0.07, 3.0, (s * 7.6, -2.0, 0), "ink", C, bevel=0, verts=8)
        ball(f"LampGlobe{s}", 0.22, (s * 7.6, -2.0, 3.15), "warmwhite", C, u=12, v=8)
    dome(O, 2, 19)
    surroundings(O, -9.5, 9.5, -5.5, 9.0, 14, skyline=False)

def r_kulliyyah_courtyard(C, O):
    shell(C, "stone", "cream", 1.5)
    back_wall(C, 6.5, m="cream")
    for k, x in enumerate(range(-7, 8, 3)):  # ground-floor arches + upper windows on the faculty block
        box(f"Arch{k}", (1.6, 0.1, 2.2), (x, 8.95, 0), "teal", C, bevel=0.04)
        ball(f"ArchTop{k}", 0.8, (x, 8.95, 2.2), "teal", C, scale=(1, 0.12, 0.7), u=16, v=8)
        box(f"UpperWin{k}", (1.2, 0.1, 1.0), (x, 8.95, 4.2), "glass", C, bevel=0.04)
        box(f"UpperSill{k}", (1.4, 0.25, 0.1), (x, 8.9, 4.15), "warmwhite", C, bevel=0.03)
    for s in (-1, 1):  # side corridors: colonnade with a roof strip
        for k, y in enumerate((-3.5, -0.5, 2.5, 5.5, 8.3)):
            column(C, f"Col{s}{k}", s * 8.5, y, h=3.8, r=0.26)
        box(f"SideRoof{s}", (1.8, 13.0, 0.3), (s * 9.1, 2.4, 3.8), "terracotta", C, bevel=0.08)
    x, y = g(0, -7.6)
    cyl("Planter", 1.3, 0.5, (x, y, 0), "stone", C, bevel=0.06, verts=24)
    cyl("PlanterSoil", 1.15, 0.05, (x, y, 0.5), "walnut", C, bevel=0, verts=24)
    tree("CourtTree", x, y, 1.3, C)
    x, y = g(-5.5, -6.6)
    sign_board(C, "Directory", x, y, panel="warmwhite", frame="teal", strips=("teal", "gold", "rose", "denim", "lilac", "leaf"))
    x, y = g(7.6, -1.0)  # club recruitment booth
    box("ClubTable", (0.8, 1.8, 0.75), (x, y, 0), "rose", C, bevel=0.05)
    box("ClubTableTop", (0.9, 1.9, 0.06), (x, y, 0.75), "warmwhite", C, bevel=0.02)
    cyl("ClubFlagPole", 0.04, 2.4, (x, y + 0.8, 0.8), "walnut", C, bevel=0, verts=8)
    box("ClubFlag", (0.05, 0.8, 0.5), (x, y + 0.4, 2.65), "gold", C, bevel=0.02)
    for k, (dy, c) in enumerate([(-0.5, "teal"), (0.0, "peach"), (0.5, "lilac")]):
        box(f"ClubFlyer{k}", (0.22, 0.3, 0.02), (x, y + dy, 0.81), c, C, bevel=0.005, chunk=False, rot=(0, 0, 10 * k))
    for s in (-1, 1):
        x, y = g(s * 7.4, 2.8)
        box(f"Bench{s}", (0.5, 1.6, 0.12), (x, y, 0.42), "oak", C, bevel=0.04)
        for d in (-0.6, 0.6):
            box(f"BenchLeg{s}{d}", (0.4, 0.12, 0.42), (x, y + d, 0), "walnut", C, bevel=0.03)
    bunting(C, "Bunting", (-8.5, 2.5), (8.5, 2.5), 3.7, n=18)
    surroundings(O, -10, 10, -5.5, 9.6, 15)

def r_rain_corridor(C, O):
    shell(C, "stone", "grout", 1.2)
    box("WallBack-colonly", (18.4, 0.4, 7), (0, 9.2, 0), "stone", C, bevel=0)
    box("WallBack", (18.6, 0.4, 7), (0, 9.2, 0), "stone", C, bevel=0.06)
    box("WallBackCap", (18.9, 0.6, 0.25), (0, 9.2, 7), "walnut", C, bevel=0.08)
    for k, x in enumerate(range(-7, 8, 3)):
        if k % 2:
            box(f"Door{k}", (1.2, 0.12, 2.3), (x, 8.98, 0), "walnut", C, bevel=0.04)
            ball(f"DoorKnob{k}", 0.05, (x + 0.4, 8.9, 1.1), "copper", C, u=8, v=6)
        else:
            box(f"Win{k}", (1.4, 0.12, 1.2), (x, 8.98, 1.1), "glass", C, bevel=0.03)
            box(f"WinFrame{k}", (1.6, 0.14, 0.12), (x, 8.96, 1.05), "walnut", C, bevel=0.03)
        box(f"UpperWin{k}", (1.2, 0.12, 1.0), (x, 8.98, 4.6), "glass", C, bevel=0.03)
    box("Overhang", (18.6, 3.4, 0.3), (0, 7.5, 3.4), "walnut", C, bevel=0.08)
    box("OverhangFascia", (18.6, 0.2, 0.4), (0, 5.85, 3.25), "stone", C, bevel=0.05)
    box("Sluice", (18.2, 0.45, 0.08), (0, 5.8, -0.06), "ink", C, bevel=0.02)
    box("SluiceLip", (18.2, 0.08, 0.1), (0, 5.55, -0.02), "stone", C, bevel=0.02)
    for s in (-1, 1):
        cyl(f"Downpipe{s}", 0.09, 3.4, (s * 6.0, 5.9, 0), "stone", C, bevel=0.02, verts=10)
    for k, (gx, gz, r) in enumerate([(-2.0, 1.0, 0.7), (3.0, -1.5, 0.5), (-4.5, -2.5, 0.45), (5.0, 2.2, 0.6), (0.5, 2.8, 0.4)]):
        cyl(f"Puddle{k}", r, 0.012, (*g(gx, gz), 0.0), "glass", C, bevel=0, verts=20)
    x, y = g(-4.0, -6.6)
    sign_board(C, "OldNotice", x, y, panel="stone", frame="walnut", strips=("cream", "cream"))
    for k, (gx, gz) in enumerate([(7.6, -5.0), (-7.6, 2.0)]):
        cyl(f"Bin{k}", 0.3, 0.8, (*g(gx, gz), 0), "sage", C, bevel=0.05, verts=14)
    surroundings(O, -10, 10, -5.5, 9.6, 16)

def r_iium_clinic(C, O):
    shell(C, "warmwhite", "cream", 1.0)
    back_wall(C, 4.0, m="cream", cap="warmwhite")
    for s in (-1, 1):
        box(f"WallSide{s}-colonly", (0.4, 14.4, 4.0), (s * 9.2, 2.0, 0), "stone", C, bevel=0)
        box(f"WallSide{s}", (0.4, 14.4, 4.0), (s * 9.2, 2.0, 0), "cream", C, bevel=0.06)
        box(f"WallSideWain{s}", (0.06, 14.2, 1.1), (s * 8.98, 2.0, 0), "sage", C, bevel=0.02)
        for k in range(5):  # waiting chairs along the walls, facing the room
            y = -2.0 + k * 1.0
            box(f"Seat{s}{k}", (0.55, 0.55, 0.1), (s * 7.8, y, 0.42), "denim", C, bevel=0.04)
            box(f"SeatBack{s}{k}", (0.1, 0.55, 0.5), (s * 8.1, y, 0.5), "denim", C, bevel=0.04)
        box(f"SeatRail{s}", (0.5, 5.2, 0.08), (s * 7.85, 0.0, 0.34), "walnut", C, bevel=0.02)
    x, y = g(0, -7.7)
    box("Counter", (4.2, 0.9, 1.1), (x, y, 0), "warmwhite", C, bevel=0.06)
    box("CounterBand", (4.25, 0.92, 0.18), (x, y, 0.75), "teal", C, bevel=0.03)
    box("CounterTop", (4.4, 1.0, 0.08), (x, y, 1.1), "oak", C, bevel=0.03)
    box("WallScreenFrame", (1.9, 0.12, 1.1), (0, 8.92, 2.2), "ink", C, bevel=0.04)
    box("WallScreen", (1.7, 0.06, 0.9), (0, 8.86, 2.3), "glass", C, bevel=0.02)
    x, _ = g(3.5, 0)
    box("QueueScreen", (0.8, 0.1, 0.45), (x, 8.92, 2.4), "ink", C, bevel=0.03)
    box("QueueScreenGlow", (0.66, 0.05, 0.3), (x, 8.86, 2.48), "leaf", C, bevel=0.01)
    for k, x in enumerate((-5.5, 5.8)):  # simple health posters: heart + cross
        box(f"Poster{k}", (1.0, 0.05, 1.3), (x, 8.96, 1.6), "warmwhite", C, bevel=0.03)
        ball(f"PosterHeart{k}a", 0.16, (x - 0.1, 8.92, 2.4), "rose", C, scale=(1, 0.2, 1), u=10, v=6)
        ball(f"PosterHeart{k}b", 0.16, (x + 0.1, 8.92, 2.4), "rose", C, scale=(1, 0.2, 1), u=10, v=6)
        cyl(f"PosterHeart{k}c", 0.2, 0.25, (x, 8.92, 2.05), "rose", C, bevel=0, r2=0.0, verts=4, rot=(180, 0, 45))
        box(f"PosterCross{k}", (0.35, 0.03, 0.1), (x, 8.92, 1.75), "teal", C, bevel=0.01, chunk=False)
        box(f"PosterCross{k}v", (0.1, 0.03, 0.35), (x, 8.92, 1.63), "teal", C, bevel=0.01, chunk=False)
    x, y = g(-7.8, -7.8)
    box("Cooler", (0.5, 0.5, 1.0), (x, y, 0), "warmwhite", C, bevel=0.05)
    cyl("CoolerBottle", 0.2, 0.45, (x, y, 1.0), "glass", C, bevel=0.05, verts=14)
    planter(C, "PlanterL", -6.5, 8.5, w=1.0, d=0.5); planter(C, "PlanterR", 6.5, 8.5, w=1.0, d=0.5)
    surroundings(O, -10, 10, -5.5, 9.6, 17)

NEW = {"shas_foyer": r_shas_foyer, "mosque_walkway": r_mosque_walkway, "kulliyyah_courtyard": r_kulliyyah_courtyard,
       "rain_corridor": r_rain_corridor, "iium_clinic": r_iium_clinic}

def build_new_rooms(only=None):
    _use_scene(); out = {}
    for name, fn in NEW.items():
        if only and name not in only: continue
        C, O = coll("EX_" + name), coll("EX_" + name + "_outside")
        fn(C, O)
        out[name] = finish(name, C, O)
    bpy.ops.wm.save_as_mainfile(filepath=PROJECT + "art/src/batch.blend")
    return out
