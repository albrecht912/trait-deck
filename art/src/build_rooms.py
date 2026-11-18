# TraitDeck room upgrades + new rooms, "Cozy Campus" style. Blender 5.2.
# Run inside Blender: exec(open(<this file>).read()); build_upgrades(); build_new_rooms()
# Upgrades re-import the original glb and KEEP every "-col" object's geometry, so baked navmeshes and
# placements in the .tscn files stay valid; they are only repainted/bevelled, then themed detail and
# outdoor surroundings are added outside or above the walkable area.
import bpy, math, os, random
exec(open(os.path.join(r"G:/IIUM Docs/Year 3/Sem 2/FYP 1/trait-deck/art/src", "build_characters.py")).read())

def import_old(C, glb):
    lc = bpy.context.view_layer.layer_collection.children[C.name]
    bpy.context.view_layer.active_layer_collection = lc
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=PROJECT + "assets/" + glb)
    return [o for o in bpy.data.objects if o not in before]

def restyle(objs, matmap, bevel=0.05, skip_bevel=("floor", "grass", "track", "field")):
    """matmap: list of (name-substring, palette name); first match wins."""
    for o in objs:
        if o.type != 'MESH': continue
        n = o.name.lower()
        m = next((p for key, p in matmap if key in n), "cream")
        o.data.materials.clear(); o.data.materials.append(mat(m))
        for p in o.data.polygons: p.use_smooth = True
        if not any(k in n for k in skip_bevel):
            b = o.modifiers.new("Bevel", 'BEVEL'); b.width = bevel * CHUNK; b.segments = 2
            b.limit_method = 'ANGLE'; b.harden_normals = True; b.use_clamp_overlap = True

def bunting(C, name, p0, p1, z, n=14, sag=0.35):
    """Pennant string sagging between two wall points; one string segment per flag so it follows the sag."""
    colours = ("rose", "gold", "teal", "denim", "peach", "lilac")
    ang = math.atan2(p1[1] - p0[1], p1[0] - p0[0])
    pts = []
    for k in range(n + 1):
        t = k / n
        pts.append((p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t, z - sag * math.sin(math.pi * t)))
    for k in range(n):
        a, b = pts[k], pts[k + 1]
        mid = [(a[i] + b[i]) / 2 for i in range(3)]
        cyl(f"{name}Flag{k}", 0.16, 0.32, (mid[0], mid[1], mid[2]), colours[k % 6], C, bevel=0, r2=0.0, verts=3,
            rot=(180, 0, math.degrees(ang)))
        seg = math.dist(a, b); pitch = math.degrees(math.atan2(b[2] - a[2], math.dist(a[:2], b[:2])))
        cyl(f"{name}String{k}", 0.012, seg, (a[0], a[1], a[2]), "ink", C, bevel=0, verts=4,
            rot=(0, 90 - pitch, math.degrees(ang)))

def band(C, src, name, zlo, zhi, outset, m):
    """Copy a wall mesh, squash it into the [zlo, zhi] height band and push it out along normals:
    a wainscot/rail/baseboard that follows any imported wall shape."""
    me = src.data.copy(); me.transform(src.matrix_world)
    zs = [v.co.z for v in me.vertices]; z0, z1 = min(zs), max(zs)
    for v in me.vertices:
        v.co.z = zlo + (v.co.z - z0) / max(z1 - z0, 1e-6) * (zhi - zlo)
    o = bpy.data.objects.new(name, me); C.objects.link(o)
    me.materials.clear(); me.materials.append(mat(m))
    d = o.modifiers.new("Out", 'DISPLACE'); d.strength = outset; d.mid_level = 0.0; d.direction = 'NORMAL'
    return o

def wall_bands(C, walls, floor_z):
    for w in walls:
        band(C, w, w.name + "Wain", floor_z, floor_z + 1.1, 0.025, "sage")
        band(C, w, w.name + "Rail", floor_z + 1.1, floor_z + 1.2, 0.05, "warmwhite")
        band(C, w, w.name + "Base", floor_z, floor_z + 0.18, 0.045, "warmwhite")

def grout(C, name, xmin, xmax, ymin, ymax, z, step=1.0, m="grout"):
    nx, ny = int((xmax - xmin) / step), int((ymax - ymin) / step)
    for i in range(1, nx):
        box(f"{name}X{i}", (0.035, ymax - ymin, 0.005), (xmin + i * step, (ymin + ymax) / 2, z), m, C, bevel=0, chunk=False)
    for j in range(1, ny):
        box(f"{name}Y{j}", (xmax - xmin, 0.035, 0.005), ((xmin + xmax) / 2, ymin + j * step, z), m, C, bevel=0, chunk=False)

def planter(C, name, x, y, w=1.4, d=0.6):
    box(name, (w, d, 0.45), (x, y, 0), "terracotta", C, bevel=0.05)
    for k in range(3):
        ball(f"{name}Bush{k}", 0.28, (x - w / 3 + k * w / 3, y, 0.55), "leaf" if k % 2 == 0 else "sage", C, u=12, v=8)

def surroundings(O, xmin, xmax, ymin, ymax, seed, margin=2.5, skyline=True, open_side=None):
    """Grass, a ring of trees just outside the playable bounds, and a far campus skyline."""
    rnd = random.Random(seed)
    cx, cy = (xmin + xmax) / 2, (ymin + ymax) / 2
    box("Grass", (xmax - xmin + 160, ymax - ymin + 160, 0.05), (cx, cy, -0.06), "grass", O, bevel=0, chunk=False)
    k = 0
    for side in ("n", "s", "e", "w"):
        if side == open_side: continue
        length = (xmax - xmin) if side in "ns" else (ymax - ymin)
        for i in range(max(2, int(length // 6))):
            t = (i + 0.5) / max(2, int(length // 6))
            if side == "n": x, y = xmin + t * (xmax - xmin), ymax + margin + rnd.uniform(0, 3)
            elif side == "s": x, y = xmin + t * (xmax - xmin), ymin - margin - rnd.uniform(0, 3)
            elif side == "e": x, y = xmax + margin + rnd.uniform(0, 3), ymin + t * (ymax - ymin)
            else: x, y = xmin - margin - rnd.uniform(0, 3), ymin + t * (ymax - ymin)
            tree(f"Tree{k}", x, y, rnd.uniform(1.3, 1.9), O); k += 1
    if skyline:
        far = ymax + 22
        for j, (dx, w, h) in enumerate([(-18, 9, 6), (-5, 10, 7.5), (8, 9, 6.5), (20, 8, 5.5)]):
            x = cx + dx
            box(f"Block{j}", (w, 5, h), (x, far, 0), "cream", O, bevel=0.15)
            box(f"Block{j}Roof", (w + 0.8, 5.8, 0.6), (x, far, h), "terracotta", O, bevel=0.2)
            for i in range(int(w // 1.6)):
                box(f"Block{j}Win{i}", (0.7, 0.1, 0.9), (x - w / 2 + 1.0 + i * 1.6, far - 2.52, h * 0.55), "glass", O, bevel=0.05)

def finish(name, C, O):
    for o in O.all_objects: C.objects.link(o)
    export(C, f"assets/rooms/{name}.glb")
    t = tris(C)
    for o in list(O.objects): C.objects.unlink(o)
    return t

# ---------------------------------------------------------------- upgrades (Blender axes: Godot z = -Blender y)
def up_mo_office():
    C, O = coll("EX_mo_office"), coll("EX_mo_office_outside")
    objs = import_old(C, "mo_office.glb")
    restyle(objs, [("floor", "tile"), ("wall", "cream"), ("door", "walnut"), ("blackboard", "leaf")])
    wall_bands(C, [o for o in objs if "wall" in o.name.lower()], 0.1)
    grout(C, "Grout", -10, 10, -10, 10, 0.1, step=1.0)
    for y in (2.0, 5.5, 8.5):
        bunting(C, f"Bunting{y}", (-9.8, y), (9.8, y), 4.6)
    for k, x in enumerate((-9.2, 9.2)):
        planter(C, f"Planter{k}", x, 9.5, w=1.0, d=0.5)
    surroundings(O, -10, 10, -10, 10, 1)
    return finish("mo_office", C, O)

def up_cafe():
    C, O = coll("EX_cafe"), coll("EX_cafe_outside")
    objs = import_old(C, "cafe.glb")
    restyle(objs, [("floor", "tile"), ("table", "oak")])
    for k, (x, y) in enumerate([(-10, -10), (10, -10), (-10, 10), (10, 10)]):
        cyl(f"Post{k}", 0.15, 4.2, (x, y, 0), "walnut", C, bevel=0.03, verts=12)
    for y in (-9.9, 9.9):
        bunting(C, f"BuntingEW{y}", (-10, y), (10, y), 4.1, n=18)
    for x in (-9.9, 9.9):
        bunting(C, f"BuntingNS{x}", (x, -10), (x, 10), 4.1, n=18)
    for k, (x, y) in enumerate([(-6, -10.8), (0, -10.8), (6, -10.8), (-6, 10.8), (0, 10.8), (6, 10.8)]):
        planter(C, f"Planter{k}", x, y)
    for k, (x, y) in enumerate([(-10.8, -5), (-10.8, 5), (10.8, -5), (10.8, 5)]):
        planter(C, f"PlanterSide{k}", x, y, w=0.6, d=1.4)
    surroundings(O, -11.5, 11.5, -11.5, 11.5, 2)
    return finish("cafe", C, O)

def up_icc_inside():
    C, O = coll("EX_icc_inside"), coll("EX_icc_inside_outside")
    objs = import_old(C, "ICC_inside.glb")
    restyle(objs, [("floorbase", "tile"), ("floortop", "oak"), ("railing", "walnut"), ("seatbase", "stone"), ("chairs", "rose")])
    for s, n in ((-1, "L"), (1, "R")):
        box(f"HallWall{n}", (0.3, 30, 14), (s * 10.15, 0, 0), "cream", C, bevel=0.06)
        box(f"HallWain{n}", (0.06, 30, 1.2), (s * 9.98, 0, 7.1), "sage", C, bevel=0.02)
        for k, y in enumerate((-8, -2, 4, 10)):
            box(f"Banner{n}{k}", (0.06, 1.2, 3.2), (s * 9.95, y, 9.0), ("teal", "gold", "rose", "denim")[k], C, bevel=0.02)
            cyl(f"BannerRod{n}{k}", 0.04, 1.5, (s * 9.92, y, 12.3), "walnut", C, bevel=0, rot=(90, 0, 0), verts=8)
    box("HallBack", (20.6, 0.3, 14), (0, 15.15, 0), "cream", C, bevel=0.06)
    box("Stage", (12, 4, 1.0), (0, -12.5, 0), "walnut", C, bevel=0.06)
    box("StageTop", (12.2, 4.2, 0.1), (0, -12.5, 1.0), "oak", C, bevel=0.03)
    box("StageBackdrop", (12, 0.2, 6), (0, -14.7, 1.0), "teal", C, bevel=0.05)
    box("StageBackdropTrim", (12.4, 0.25, 0.4), (0, -14.7, 7.0), "gold", C, bevel=0.05)
    cyl("Podium", 0.4, 1.1, (3.5, -11.5, 1.1), "walnut", C, bevel=0.05, verts=12)
    for y in (-6, 0, 6, 12):
        bunting(C, f"Bunting{y}", (-10, y), (10, y), 13.0, n=16, sag=0.6)
    surroundings(O, -10.5, 10.5, -15.5, 15.5, 3)
    return finish("icc_inside", C, O)

def up_icc_outside():
    C, O = coll("EX_icc_outside"), coll("EX_icc_outside_outside")
    objs = import_old(C, "ICC_outside.glb")
    restyle(objs, [("floor", "stone"), ("pillars", "cream"), ("door", "glass"), ("wall", "cream")])
    grout(C, "Pavers", -25, 16, -10, 10, 0.02, step=1.5, m="cream")
    for o in objs:
        if o.name.lower().startswith("pillars"):
            band(C, o, "PillarBase", 0.0, 0.6, 0.06, "terracotta")
    box("FacadeTrim", (0.8, 20.4, 0.5), (16, 0, 10.4), "terracotta", C, bevel=0.08)
    box("FacadeBand", (0.6, 20.2, 0.3), (15.95, 0, 5.5), "teal", C, bevel=0.05)
    box("ColonnadeRoof", (33, 2.6, 0.5), (-5, 9, 11), "terracotta", C, bevel=0.1)
    bunting(C, "BuntingCol", (-21, 8.2), (11, 8.2), 6.5, n=24, sag=0.8)
    for k, x in enumerate((-18, -10, -2, 6)):
        planter(C, f"Planter{k}", x, -10.8)
    for k, x in enumerate((-12, 0)):
        cyl(f"LampPost{k}", 0.08, 3.6, (x, -9.2, 0), "ink", C, bevel=0, verts=8)
        ball(f"LampGlobe{k}", 0.25, (x, -9.2, 3.75), "warmwhite", C, u=12, v=8)
    surroundings(O, -25.5, 16.5, -10.5, 10.5, 4, open_side="e")
    return finish("icc_outside", C, O)

def up_musolla():
    C, O = coll("EX_musolla"), coll("EX_musolla_outside")
    objs = import_old(C, "musolla.glb")
    restyle(objs, [("floor", "stone"), ("pillar", "warmwhite"), ("saf", "teal"), ("sejadah", "rose"), ("wall", "cream")])
    wall_bands(C, [o for o in objs if "wall" in o.name.lower()], 0.1)
    for o in objs:
        if o.name.lower().startswith("pillar"):
            band(C, o, "PillarBase", 0.1, 0.7, 0.05, "teal")
            band(C, o, "PillarCap", 4.4, 5.0, 0.06, "gold")
    grout(C, "Grout", -10, 10, -10, 10, 0.1, step=1.25, m="cream")
    # mihrab niche on the back (qibla) wall beside the imam's sejadah (x 5..9), clear of the centre pillar
    mx, wy = 7.0, 9.85
    box("MihrabFrame", (2.4, 0.3, 3.4), (mx, wy, 0.1), "teal", C, bevel=0.08)
    box("MihrabNiche", (1.7, 0.34, 2.6), (mx, wy - 0.03, 0.1), "warmwhite", C, bevel=0.06)
    ball("MihrabArchFrame", 1.2, (mx, wy + 0.05, 3.3), "gold", C, scale=(1, 0.15, 0.6), u=20, v=10)
    ball("MihrabArch", 0.85, (mx, wy - 0.05, 2.7), "warmwhite", C, scale=(1, 0.22, 0.75), u=20, v=10)
    for s in (-1, 1):
        box(f"Shelf{s}", (0.3, 1.6, 0.06), (s * 9.8, 3, 1.5), "walnut", C, bevel=0.02)
        for k in range(4):
            box(f"Mushaf{s}{k}", (0.2, 0.08, 0.28), (s * 9.8, 2.5 + k * 0.2, 1.56), ("teal", "leaf", "gold", "rose")[k], C, bevel=0.012)
        for k, y in enumerate((-6, 0, 6)):
            box(f"WallLamp{s}{k}", (0.15, 0.3, 0.5), (s * 9.9, y, 3.0), "gold", C, bevel=0.05)
    surroundings(O, -10.5, 10.5, -10.5, 10.5, 5)
    return finish("musolla", C, O)

def up_sports_centre():
    C, O = coll("EX_sports_centre"), coll("EX_sports_centre_outside")
    objs = import_old(C, "sports_centre.glb")
    old_trees = [o for o in objs if o.type == 'MESH' and o.name.lower().startswith("tree")]
    objs = [o for o in objs if o not in old_trees]
    for k, o in enumerate(old_trees):  # swap the old cone trees for palette trees at the same spots
        bb = [o.matrix_world @ mathutils.Vector(c) for c in o.bound_box]
        tree(f"SCTree{k}", sum(v.x for v in bb) / 8, sum(v.y for v in bb) / 8, 2.8, C)
        bpy.data.objects.remove(o, do_unlink=True)
    restyle(objs, [("grass", "grass"), ("track", "terracotta"), ("soccer", "leaf"), ("stands", "denim")], bevel=0.1)
    for s in (-1, 1):  # goals at the field ends
        x = s * 34.5
        for y in (-3.6, 3.6):
            cyl(f"GoalPost{s}{y}", 0.12, 2.4, (x, y, 0.1), "warmwhite", C, bevel=0.03, verts=10)
        cyl(f"GoalBar{s}", 0.12, 7.4, (x, 0, 2.5), "warmwhite", C, bevel=0.03, rot=(90, 0, 0), verts=10)
    for k, x in enumerate(range(-36, 37, 8)):  # flags along the stands
        cyl(f"FlagPole{k}", 0.06, 4.0, (x, -36.6, 14.5), "ink", C, bevel=0, verts=6)
        box(f"Flag{k}", (1.2, 0.05, 0.7), (x + 0.6, -36.6, 17.6), ("teal", "gold", "rose", "denim", "peach")[k % 5], C, bevel=0.02)
    for k, (x, y, r) in enumerate([(-40, 70, 22), (5, 78, 28), (45, 68, 20)]):  # rolling hills behind the camera side
        ball(f"Hill{k}", r, (x, y, -r * 0.55), "sage" if k % 2 else "leaf", O, scale=(1.6, 1, 1), u=24, v=12)
    surroundings(O, -63.5, 61.5, -58, 42, 6, margin=3, skyline=False)
    return finish("sports_centre", C, O)

UPGRADES = {"mo_office": up_mo_office, "cafe": up_cafe, "icc_inside": up_icc_inside, "icc_outside": up_icc_outside,
            "musolla": up_musolla, "sports_centre": up_sports_centre}

def build_upgrades(only=None):
    _use_scene(); out = {}
    for name, fn in UPGRADES.items():
        if only and name not in only: continue
        out[name] = fn()
    bpy.ops.wm.save_as_mainfile(filepath=PROJECT + "art/src/batch.blend")
    return out
