# TraitDeck "Cozy Campus" hero set (Room 304) builder for Blender 5.2.
# Run inside Blender (Text Editor or Blender MCP): exec(open(<this file>).read())
# Rebuilds every hero asset from scratch and exports .glb files into the Godot project.
# Conventions: 1 unit = 1 m, assets face -Y (Godot +Z, toward the camera), bottom-centre pivots,
# "-colonly" boxes become Godot collision, palette materials "pal_*" are shared by every asset.
import bpy, bmesh, math, os

PROJECT = r"G:/IIUM Docs/Year 3/Sem 2/FYP 1/trait-deck/"
CHUNK = 1.8  # global bevel multiplier: bigger = rounder, more toy-like

PAL = {"cream": "F7E3C0", "warmwhite": "FFF3DC", "oak": "E0A960", "walnut": "9A5B34", "stone": "D7C3A6",
       "tile": "F3DFBF", "grout": "C9AE8A", "terracotta": "D9643A", "copper": "C87A35", "sage": "9CCB86",
       "leaf": "5DAE4B", "grass": "8CCB5E", "denim": "5FA2DD", "navy": "34508C", "rose": "F28B95",
       "peach": "FFB58A", "lilac": "B9A3E8", "teal": "22A39A", "gold": "F5BE3A", "ink": "4A3428",
       "skin": "F2C9A0", "hair": "5A3A28", "glass": "9FDCF2"}

def srgb(h):
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]

def mat(n):
    m = bpy.data.materials.get("pal_" + n) or bpy.data.materials.new("pal_" + n)
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*srgb(PAL[n]), 1)
    b.inputs["Roughness"].default_value = 0.2 if n == "glass" else 0.8
    b.inputs["Metallic"].default_value = 0.3 if n == "copper" else 0.0
    if n == "glass":
        b.inputs["Alpha"].default_value = 0.6
        m.surface_render_method = 'BLENDED'
    return m

def coll(name):
    c = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if c.name not in bpy.context.scene.collection.children:
        bpy.context.scene.collection.children.link(c)
    for o in list(c.all_objects):
        bpy.data.objects.remove(o, do_unlink=True)
    return c

def _obj(name, bm, m, col, loc, rot, parent, bevel, seg):
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = True
    me.materials.append(mat(m))
    o = bpy.data.objects.new(name, me); col.objects.link(o)
    o.location = loc; o.rotation_euler = [math.radians(a) for a in rot]
    if parent: o.parent = parent
    if bevel:
        b = o.modifiers.new("Bevel", 'BEVEL'); b.width = bevel; b.segments = seg
        b.limit_method = 'ANGLE'; b.harden_normals = True; b.use_clamp_overlap = True
    return o

def box(name, size, loc, m, col, bevel=0.02, seg=3, rot=(0, 0, 0), parent=None, chunk=True):
    """size xyz; loc is the bottom-centre."""
    bm = bmesh.new(); bmesh.ops.create_cube(bm, size=1)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    bmesh.ops.translate(bm, vec=(0, 0, size[2] / 2), verts=bm.verts)
    w = bevel * (CHUNK if chunk else 1)
    w = min(w, min(size) / 2 - 0.001) if bevel else 0
    return _obj(name, bm, m, col, loc, rot, parent, w, seg)

def cyl(name, r, h, loc, m, col, bevel=0.01, seg=2, rot=(0, 0, 0), verts=16, r2=None, parent=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=verts, radius1=r, radius2=r if r2 is None else r2, depth=h)
    bmesh.ops.translate(bm, vec=(0, 0, h / 2), verts=bm.verts)
    w = min(bevel * CHUNK, h / 2 - 0.001, r - 0.001) if bevel else 0
    return _obj(name, bm, m, col, loc, rot, parent, w, seg)

def ball(name, r, loc, m, col, scale=(1, 1, 1), parent=None, u=16, v=10, rot=(0, 0, 0)):
    bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=u, v_segments=v, radius=r)
    bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
    return _obj(name, bm, m, col, loc, rot, parent, 0, 0)

def empty(name, col, loc=(0, 0, 0), parent=None):
    e = bpy.data.objects.new(name, None); col.objects.link(e); e.location = loc
    if parent: e.parent = parent
    return e

def tris(col):
    dg = bpy.context.evaluated_depsgraph_get()
    return sum(sum(len(p.vertices) - 2 for p in o.evaluated_get(dg).data.polygons)
               for o in col.all_objects if o.type == 'MESH')

def export(col, rel):
    os.makedirs(os.path.dirname(PROJECT + rel), exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in col.all_objects: o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=PROJECT + rel, export_format='GLB', use_selection=True,
                              export_apply=True, export_yup=True)

def tree(n, x, y, s, C):
    cyl(f"{n}Trunk", 0.18 * s, 1.6 * s, (x, y, 0), "walnut", C, bevel=0.03, r2=0.13 * s, verts=10)
    for k, (dx, dy, dz, r) in enumerate([(0, 0, 2.3, 1.0), (-0.5, 0.2, 1.9, 0.7), (0.55, -0.1, 2.0, 0.75), (0.1, 0.1, 2.9, 0.7)]):
        ball(f"{n}Leaf{k}", r * s, (x + dx * s, y + dy * s, dz * s), "leaf" if k % 2 == 0 else "sage", C, u=12, v=8)

# ---------------------------------------------------------------- Room 304 (shell + clutter + outside)
def build_room():
    C = coll("EX_mahallah_room")
    # collision proxies match the old room.glb footprint (floor top y = 0.1)
    box("Floor-colonly", (10, 6, 0.1), (0, -1, 0), "stone", C, bevel=0)
    box("WallBack-colonly", (10.2, 0.2, 3), (0, 2.1, 0), "stone", C, bevel=0)
    box("WallL-colonly", (0.2, 6.2, 3), (-5.1, -0.9, 0), "stone", C, bevel=0)
    box("WallR-colonly", (0.2, 6.2, 3), (5.1, -0.9, 0), "stone", C, bevel=0)
    # floor tiles
    box("Floor", (10.3, 6.25, 0.1), (0, -0.93, 0), "tile", C, bevel=0.03)
    for i in range(1, 17):
        box(f"GroutX{i}", (0.03, 6, 0.004), (-5 + i * 0.6, -1, 0.1), "grout", C, bevel=0)
    for j in range(1, 10):
        box(f"GroutY{j}", (10, 0.03, 0.004), (0, -4 + j * 0.6, 0.1), "grout", C, bevel=0)
    # walls
    for n, (sz, lc) in {"Back": ((10.4, 0.2, 3), (0, 2.1, 0)), "L": ((0.2, 6.2, 3), (-5.1, -0.9, 0)),
                        "R": ((0.2, 6.2, 3), (5.1, -0.9, 0))}.items():
        box("Wall" + n, sz, lc, "cream", C, bevel=0.05)
    for n, sz, lc in [("Back", (10, 0.06, 1.0), (0, 1.98, 0.1)), ("L", (0.06, 6, 1.0), (-4.98, -1, 0.1)), ("R", (0.06, 6, 1.0), (4.98, -1, 0.1))]:
        box("Wain" + n, sz, lc, "sage", C, bevel=0.02)
    for n, sz, lc in [("Back", (10, 0.1, 0.1), (0, 1.95, 1.08)), ("L", (0.1, 6, 0.1), (-4.95, -1, 1.08)), ("R", (0.1, 6, 0.1), (4.95, -1, 1.08))]:
        box("Rail" + n, sz, lc, "warmwhite", C, bevel=0.03)
    for n, sz, lc in [("Back", (10, 0.12, 0.16), (0, 1.94, 0.1)), ("L", (0.12, 6, 0.16), (-4.94, -1, 0.1)), ("R", (0.12, 6, 0.16), (4.94, -1, 0.1))]:
        box("Base" + n, sz, lc, "warmwhite", C, bevel=0.03)
    for n, sz, lc in [("Back", (10.5, 0.3, 0.12), (0, 2.1, 3)), ("L", (0.3, 6.3, 0.12), (-5.1, -0.9, 3)), ("R", (0.3, 6.3, 0.12), (5.1, -0.9, 3))]:
        box("WallCap" + n, sz, lc, "warmwhite", C, bevel=0.04)
    # window
    box("WinGlass", (1.6, 0.04, 1.1), (0, 1.99, 1.4), "glass", C, bevel=0)
    box("WinFrameT", (1.8, 0.16, 0.14), (0, 1.95, 2.5), "warmwhite", C, bevel=0.04)
    box("WinFrameB", (1.95, 0.26, 0.14), (0, 1.9, 1.28), "warmwhite", C, bevel=0.04)
    box("WinFrameL", (0.14, 0.16, 1.2), (-0.86, 1.95, 1.36), "warmwhite", C, bevel=0.04)
    box("WinFrameR", (0.14, 0.16, 1.2), (0.86, 1.95, 1.36), "warmwhite", C, bevel=0.04)
    box("WinMullV", (0.07, 0.1, 1.1), (0, 1.97, 1.4), "warmwhite", C, bevel=0.02)
    box("WinMullH", (1.6, 0.1, 0.07), (0, 1.97, 1.92), "warmwhite", C, bevel=0.02)
    box("CurtainRod", (2.6, 0.07, 0.07), (0, 1.9, 2.66), "walnut", C, bevel=0.025)
    for s, n in ((-1, "L"), (1, "R")):
        box("Curtain" + n, (0.46, 0.14, 1.5), (s * 1.12, 1.87, 1.12), "denim", C, bevel=0.05, seg=4)
        box("CurtainTie" + n, (0.5, 0.17, 0.07), (s * 1.12, 1.87, 1.6), "gold", C, bevel=0.025)
    cyl("SillPot", 0.07, 0.1, (0.55, 1.86, 1.42), "terracotta", C, bevel=0.02, r2=0.085, verts=12)
    ball("SillCactus", 0.07, (0.55, 1.86, 1.58), "leaf", C, scale=(1, 1, 1.4), u=10, v=8)
    # noticeboard + clock
    box("NoticeFrame", (1.3, 0.08, 0.85), (-2.6, 1.95, 1.45), "walnut", C, bevel=0.03)
    box("NoticeCork", (1.15, 0.04, 0.7), (-2.6, 1.92, 1.525), "oak", C, bevel=0.01)
    for k, (x, z, c, r) in enumerate([(-2.95, 1.85, "warmwhite", -6), (-2.55, 1.95, "rose", 4), (-2.2, 1.7, "gold", -3),
                                      (-2.75, 1.6, "denim", 8), (-2.3, 1.55, "sage", 0)]):
        box(f"NotePaper{k}", (0.24, 0.012, 0.28), (x, 1.895, z), c, C, bevel=0.004, rot=(0, r, 0), chunk=False)
        ball(f"NotePin{k}", 0.025, (x, 1.88, z + 0.25), "terracotta", C, u=8, v=6)
    cyl("ClockRim", 0.25, 0.08, (2.6, 1.98, 2.1), "walnut", C, bevel=0.02, rot=(90, 0, 0), verts=24)
    cyl("ClockFace", 0.2, 0.03, (2.6, 1.91, 2.1), "warmwhite", C, bevel=0.008, rot=(90, 0, 0), verts=24)
    box("ClockHandH", (0.035, 0.01, 0.12), (2.6, 1.88, 2.09), "ink", C, bevel=0.005, rot=(0, 35, 0))
    box("ClockHandM", (0.025, 0.01, 0.17), (2.6, 1.875, 2.09), "ink", C, bevel=0.005, rot=(0, -80, 0))
    # posters (simple shapes, no text): sunny hills and a crescent
    for n, x, bg, fg in (("PosterL", -3.9, "peach", "teal"), ("PosterR", 3.9, "lilac", "gold")):
        box(n + "Frame", (0.7, 0.05, 0.9), (x, 1.96, 1.45), "warmwhite", C, bevel=0.025)
        box(n + "Art", (0.58, 0.02, 0.78), (x, 1.93, 1.51), bg, C, bevel=0.008, chunk=False)
    ball("PosterLSun", 0.11, (-3.75, 1.915, 1.98), "gold", C, scale=(1, 0.15, 1), u=12, v=8)
    ball("PosterLHill", 0.3, (-3.95, 1.915, 1.52), "teal", C, scale=(1, 0.15, 0.6), u=12, v=8)
    ball("PosterRMoon", 0.17, (3.9, 1.915, 1.92), "gold", C, scale=(1, 0.15, 1), u=12, v=8)
    ball("PosterRMoonCut", 0.15, (3.98, 1.91, 1.96), "lilac", C, scale=(1, 0.15, 1), u=12, v=8)
    for k, (dx, dz) in enumerate([(-0.18, 1.65), (0.15, 1.6), (0.0, 1.75)]):
        ball(f"PosterRStar{k}", 0.03, (3.9 + dx, 1.912, dz), "warmwhite", C, scale=(1, 0.2, 1), u=8, v=6)
    # fairy lights sagging along the back wall
    for k in range(29):
        x = -4.2 + k * 0.3
        z = 2.78 - 0.12 * math.sin(math.pi * ((x + 4.2) % 2.1) / 2.1)
        ball(f"Fairy{k}", 0.055, (x, 1.93, z), ("gold", "rose", "warmwhite", "teal")[k % 4], C, u=8, v=6)
    # side-wall shelves with books / jars
    for s, n in ((-1, "L"), (1, "R")):
        x = s * 4.86
        box(f"Shelf{n}", (0.24, 1.2, 0.06), (x, -1.6, 1.85), "walnut", C, bevel=0.02)
        for b in (-0.45, 0.45):
            box(f"Shelf{n}Bracket{b}", (0.2, 0.05, 0.14), (x, -1.6 + b, 1.71), "walnut", C, bevel=0.015)
    for k, (dy, h, c) in enumerate([(-0.45, 0.28, "rose"), (-0.36, 0.24, "denim"), (-0.27, 0.3, "gold"), (-0.18, 0.22, "teal"), (-0.06, 0.26, "lilac")]):
        box(f"ShelfBook{k}", (0.18, 0.08, h), (-4.86, -1.6 + dy, 1.91), c, C, bevel=0.012, rot=(0, 0, 0) if k != 4 else (-14, 0, 0))
    cyl("ShelfPotL", 0.08, 0.13, (-4.86, -1.15, 1.91), "terracotta", C, bevel=0.02, r2=0.095, verts=12)
    ball("ShelfPlantL", 0.12, (-4.86, -1.15, 2.12), "leaf", C, u=10, v=8)
    cyl("ShelfJarR", 0.08, 0.2, (4.86, -2.0, 1.91), "glass", C, bevel=0.02, verts=12)
    cyl("ShelfJarLidR", 0.085, 0.04, (4.86, -2.0, 2.11), "rose", C, bevel=0.012, verts=12)
    cyl("ShelfPotR", 0.08, 0.13, (4.86, -1.55, 1.91), "teal", C, bevel=0.02, r2=0.095, verts=12)
    for k in range(3):
        ball(f"ShelfVineR{k}", 0.06, (4.86, -1.55 + 0.04 * k, 2.02 - 0.12 * k), "leaf", C, u=8, v=6)
    box("ShelfBoxR", (0.18, 0.3, 0.14), (4.86, -1.1, 1.91), "peach", C, bevel=0.02)
    # back-strip floor clutter (outside the navmesh, y > 1.4)
    cyl("PlantPot", 0.26, 0.42, (4.5, 1.55, 0.1), "terracotta", C, bevel=0.04, r2=0.32, verts=20)
    cyl("PlantSoil", 0.29, 0.02, (4.5, 1.55, 0.5), "walnut", C, bevel=0, verts=20)
    for k, (dx, dy, dz, r) in enumerate([(0, 0, 0.9, 0.34), (-0.16, -0.1, 0.72, 0.26), (0.18, 0.08, 0.7, 0.24), (0.05, -0.18, 1.12, 0.22)]):
        ball(f"PlantLeaf{k}", r, (4.5 + dx, 1.55 + dy, dz), "leaf" if k % 2 == 0 else "sage", C)
    cyl("Basket", 0.26, 0.45, (-4.45, 1.55, 0.1), "oak", C, bevel=0.03, r2=0.3, verts=16)
    cyl("BasketRim", 0.31, 0.05, (-4.45, 1.55, 0.53), "walnut", C, bevel=0.02, verts=16)
    ball("BasketCloth", 0.2, (-4.4, 1.5, 0.58), "rose", C, scale=(1.2, 1, 0.5), u=12, v=8)
    ball("BasketCloth2", 0.16, (-4.55, 1.6, 0.6), "denim", C, scale=(1.1, 1, 0.5), u=12, v=8)
    box("ShoeRack", (0.7, 0.32, 0.36), (1.3, 1.7, 0.1), "oak", C, bevel=0.03)
    box("ShoeRackShelf", (0.66, 0.3, 0.03), (1.3, 1.68, 0.27), "walnut", C, bevel=0.01)
    for k, (dx, c) in enumerate([(-0.18, "rose"), (0.0, "teal"), (0.18, "navy")]):
        box(f"Shoe{k}", (0.13, 0.25, 0.08), (1.3 + dx, 1.66, 0.46), c, C, bevel=0.035)
    box("PrayerMat", (0.55, 0.32, 0.12), (-1.3, 1.7, 0.1), "teal", C, bevel=0.05)
    box("PrayerMatBand", (0.57, 0.34, 0.03), (-1.3, 1.7, 0.16), "gold", C, bevel=0.012)
    # desk clutter on the room's fixed desks (world positions from mahallah_room.tscn, desk top z = 0.88)
    cyl("LampBase", 0.09, 0.04, (-0.46, 1.6, 0.88), "teal", C, bevel=0.015, verts=14)
    cyl("LampStem", 0.018, 0.32, (-0.46, 1.6, 0.92), "warmwhite", C, bevel=0, verts=8, rot=(-12, 0, 0))
    cyl("LampShade", 0.07, 0.14, (-0.46, 1.53, 1.18), "gold", C, bevel=0.015, r2=0.13, verts=14, rot=(160, 0, 0))
    cyl("Mug", 0.055, 0.11, (3.45, -1.35, 0.88), "rose", C, bevel=0.015, verts=14)
    cyl("PencilCup", 0.05, 0.13, (3.65, -1.6, 0.88), "lilac", C, bevel=0.015, verts=12)
    for k, (dx, c) in enumerate([(-0.015, "gold"), (0.02, "teal"), (0.0, "rose")]):
        cyl(f"Pencil{k}", 0.009, 0.2, (3.65 + dx, -1.6 + dx, 0.92), c, C, bevel=0, verts=6, rot=(8 * (k - 1), 6, 0))
    cyl("CactusPot", 0.06, 0.08, (4.15, -1.4, 0.88), "terracotta", C, bevel=0.015, r2=0.07, verts=12)
    ball("Cactus", 0.06, (4.15, -1.4, 1.02), "leaf", C, scale=(1, 1, 1.3), u=10, v=8)
    cyl("Mug2", 0.055, 0.11, (0.6, 0.55, 0.88), "denim", C, bevel=0.015, verts=14)
    box("Notebook2", (0.2, 0.27, 0.025), (0.35, 0.8, 0.88), "peach", C, bevel=0.008, rot=(0, 0, 12))
    # round rug + floor cushions
    cyl("RugOuter", 1.0, 0.02, (0, -1.5, 0.1), "rose", C, bevel=0.008, verts=32)
    cyl("RugInner", 0.78, 0.025, (0, -1.5, 0.1), "warmwhite", C, bevel=0.008, verts=32)
    cyl("RugDot", 0.35, 0.03, (0, -1.5, 0.1), "peach", C, bevel=0.008, verts=24)
    # outside: grass ground, hedges, trees and distant campus blocks so the room never floats in a void
    O = coll("EX_mahallah_room_outside")
    box("Grass", (90, 90, 0.05), (0, 0, -0.05), "grass", O, bevel=0, chunk=False)
    box("Path", (2.2, 30, 0.02), (0, -19, 0.0), "stone", O, bevel=0.01)
    for k, x in enumerate((-6.2, 6.2)):
        box(f"Hedge{k}", (0.9, 7.5, 0.9), (x, -1.0, 0), "leaf", O, bevel=0.2, seg=3)
    box("HedgeBack", (13.5, 0.9, 0.9), (0, 3.2, 0), "sage", O, bevel=0.2, seg=3)
    for k, (x, y, s) in enumerate([(-8.5, 4.5, 1.4), (-4.0, 6.5, 1.7), (1.5, 7.0, 1.5), (6.5, 5.5, 1.8), (9.5, 1.0, 1.3),
                                   (-9.5, -1.5, 1.5), (-12, 9, 1.6), (12, 8, 1.4), (-7.5, -6, 1.2), (8.5, -6.5, 1.3)]):
        tree(f"Tree{k}", x, y, s, O)
    for k, (x, y, w, h) in enumerate([(-14, 16, 8, 5), (-3, 19, 9, 6.5), (9, 17, 8, 5.5)]):
        box(f"Block{k}", (w, 5, h), (x, y, 0), "cream", O, bevel=0.15)
        box(f"Block{k}Roof", (w + 0.8, 5.8, 0.6), (x, y, h), "terracotta", O, bevel=0.2)
        for i in range(int(w // 1.6)):
            box(f"Block{k}Win{i}", (0.7, 0.1, 0.9), (x - w / 2 + 1.0 + i * 1.6, y - 2.52, h * 0.55), "glass", O, bevel=0.05)
    # SHAS-style dome in the distance (palette shapes only)
    cyl("DomeDrum", 3.0, 6.0, (-1, 32, 0), "cream", O, bevel=0.2, verts=24)
    ball("Dome", 3.1, (-1, 32, 6.0), "terracotta", O, scale=(1, 1, 0.9), u=24, v=12)
    for k, x in enumerate((-6.5, 4.5)):
        cyl(f"Minaret{k}", 0.6, 11, (x, 31, 0), "cream", O, bevel=0.1, verts=12)
        cyl(f"MinaretCap{k}", 0.75, 1.4, (x, 31, 11), "terracotta", O, bevel=0.05, r2=0.05, verts=12)
    return C, O

# ---------------------------------------------------------------- furniture (footprints match old glbs)
def build_bed():
    B = coll("EX_bed")
    box("Bed-colonly", (1, 2, 0.62), (0, 0, 0), "walnut", B, bevel=0)
    for x in (-0.4, 0.4):
        for y in (-0.9, 0.9):
            cyl(f"Leg{x}{y}", 0.075, 0.14, (x, y, 0), "walnut", B, bevel=0.02, verts=12)
    box("Frame", (1, 2, 0.24), (0, 0, 0.1), "walnut", B, bevel=0.05, seg=3)
    box("Mattress", (0.94, 1.9, 0.24), (0, -0.02, 0.3), "warmwhite", B, bevel=0.06, seg=3)
    box("Blanket", (1.0, 1.25, 0.1), (0, -0.36, 0.48), "denim", B, bevel=0.04, seg=3)
    for k, y in enumerate((-0.8, -0.45, -0.1)):
        box(f"BlanketStripe{k}", (1.01, 0.08, 0.102), (0, y, 0.48), "warmwhite", B, bevel=0.02, seg=2)
    box("BlanketFold", (1.0, 0.24, 0.12), (0, 0.33, 0.5), "warmwhite", B, bevel=0.05, seg=3)
    ball("Pillow", 0.32, (0, 0.72, 0.62), "warmwhite", B, scale=(1.0, 0.55, 0.28), u=16, v=10)
    box("Headboard", (1.06, 0.12, 0.95), (0, 0.96, 0), "walnut", B, bevel=0.05, seg=3)
    box("HeadPanel", (0.8, 0.04, 0.38), (0, 0.89, 0.5), "oak", B, bevel=0.02, seg=2)
    box("Footboard", (1.06, 0.12, 0.58), (0, -0.96, 0), "walnut", B, bevel=0.05, seg=3)
    ball("Plush", 0.09, (0.3, 0.55, 0.66), "peach", B, u=10, v=8)
    for s in (-1, 1):
        ball(f"PlushEar{s}", 0.035, (0.3 + s * 0.06, 0.57, 0.74), "peach", B, u=8, v=6)
    return B

def build_locker():
    L = coll("EX_locker")
    box("Locker-colonly", (1, 0.7, 2.25), (0, 0, 0), "walnut", L, bevel=0)
    box("Plinth", (0.96, 0.64, 0.1), (0, 0.01, 0), "walnut", L, bevel=0.02, seg=2)
    box("Body", (1, 0.66, 2.05), (0, 0.02, 0.1), "oak", L, bevel=0.05, seg=3)
    box("Crown", (1.08, 0.74, 0.12), (0, 0.01, 2.13), "walnut", L, bevel=0.04, seg=3)
    for s in (-1, 1):
        box(f"Door{s}", (0.44, 0.05, 1.85), (s * 0.235, -0.31, 0.2), "cream", L, bevel=0.03, seg=2)
        box(f"DoorInset{s}", (0.32, 0.02, 0.6), (s * 0.235, -0.335, 1.25), "oak", L, bevel=0.015, seg=2)
        box(f"DoorInsetLo{s}", (0.32, 0.02, 0.6), (s * 0.235, -0.335, 0.45), "oak", L, bevel=0.015, seg=2)
        ball(f"Knob{s}", 0.05, (s * 0.06, -0.37, 1.05), "gold", L, u=12, v=8)
        box(f"SidePanelHi{s}", (0.02, 0.5, 0.85), (s * 0.505, 0.02, 1.15), "cream", L, bevel=0.01, seg=2)
        box(f"SidePanelLo{s}", (0.02, 0.5, 0.75), (s * 0.505, 0.02, 0.3), "cream", L, bevel=0.01, seg=2)
    box("NameTag", (0.22, 0.015, 0.08), (0, -0.345, 1.95), "warmwhite", L, bevel=0.01, seg=2)
    box("TopBox", (0.5, 0.4, 0.22), (0.1, 0.05, 2.25), "peach", L, bevel=0.03, seg=2, rot=(0, 0, 8))
    return L

def build_table():
    T = coll("EX_table")
    box("Top", (1.5, 0.7, 0.09), (0, 0, 0.69), "oak", T, bevel=0.03, seg=3)
    for x in (-0.65, 0.65):
        for y in (-0.26, 0.26):
            cyl(f"Leg{x}{y}", 0.055, 0.69, (x, y, 0), "walnut", T, bevel=0.02, verts=12, r2=0.045)
    box("Apron", (1.3, 0.06, 0.1), (0, 0.3, 0.59), "walnut", T, bevel=0.02, seg=2)
    box("Drawer", (0.5, 0.6, 0.15), (0.4, 0.0, 0.55), "oak", T, bevel=0.025, seg=2)
    box("DrawerFace", (0.46, 0.03, 0.12), (0.4, -0.31, 0.565), "cream", T, bevel=0.012, seg=2)
    ball("DrawerKnob", 0.032, (0.4, -0.34, 0.625), "gold", T, u=10, v=6)
    return T

# ---------------------------------------------------------------- collectible + tidy task
def build_wet_wipes():
    W = coll("EX_wet_wipes")
    box("Pack", (0.3, 0.2, 0.1), (0, 0, 0), "teal", W, bevel=0.03, seg=3)
    box("Lid", (0.17, 0.11, 0.028), (0, 0, 0.095), "warmwhite", W, bevel=0.01, seg=2)
    box("Wipe", (0.08, 0.04, 0.05), (0, -0.01, 0.11), "warmwhite", W, bevel=0.012, seg=2, rot=(15, 0, 8))
    ball("Dot", 0.028, (0.1, -0.098, 0.05), "gold", W, scale=(1, 0.35, 1), u=10, v=6)
    return W

def build_tidy_books():
    K = coll("EX_tidy_desk_books")
    mess, tidy = empty("Messy", K), empty("Tidy", K)
    def book(n, loc, rot, c, par, sz=(0.26, 0.19, 0.055)):
        b = box(n, sz, loc, c, K, bevel=0.01, seg=2, rot=rot, parent=par)
        box(n + "Pages", (sz[0] - 0.02, sz[1] - 0.025, sz[2] - 0.018), (0.006, 0, 0.009), "warmwhite", K, bevel=0.003, seg=1, parent=b, chunk=False)
    for k, (x, y, rz, c) in enumerate([(-0.32, 0.12, 25, "rose"), (0.05, -0.2, -40, "denim"), (0.3, 0.18, 70, "gold"), (-0.05, 0.3, -10, "teal")]):
        book(f"MBook{k}", (x, y, 0), (0, 0, rz), c, mess)
    book("MBookTilted", (0.05, -0.2, 0.055), (0, 8, 15), "lilac", mess)
    for k, (x, y, rz) in enumerate([(0.35, -0.15, 30), (-0.3, -0.25, -20), (0.15, 0.4, 5)]):
        box(f"MPaper{k}", (0.21, 0.29, 0.006), (x, y, 0), "warmwhite", K, bevel=0.002, seg=1, rot=(0, 0, rz), parent=mess, chunk=False)
    z = 0
    for k, (c, rz) in enumerate([("teal", 0), ("rose", 4), ("denim", -3), ("gold", 6), ("lilac", -2)]):
        book(f"TBook{k}", (0, 0, z), (0, 0, rz), c, tidy); z += 0.055
    box("TPapers", (0.21, 0.29, 0.02), (0.3, 0, 0), "warmwhite", K, bevel=0.004, seg=1, parent=tidy, chunk=False)
    return K

# ---------------------------------------------------------------- protagonist (~2.5 heads, static, faces -Y)
def build_protagonist():
    P = coll("EX_protagonist")
    root = empty("Model", P)
    for s in (-1, 1):
        box(f"Shoe{s}", (0.17, 0.27, 0.1), (s * 0.12, -0.03, 0), "walnut", P, bevel=0.045, parent=root)
        cyl(f"Leg{s}", 0.075, 0.26, (s * 0.11, 0, 0.07), "navy", P, bevel=0.02, verts=12, parent=root)
    box("Torso", (0.46, 0.32, 0.44), (0, 0, 0.3), "teal", P, bevel=0.1, seg=4, chunk=False, parent=root)
    for s in (-1, 1):
        cyl(f"Sleeve{s}", 0.085, 0.14, (s * 0.25, 0, 0.6), "teal", P, bevel=0.03, verts=12, rot=(0, s * 155, 0), parent=root)
        cyl(f"Arm{s}", 0.06, 0.26, (s * 0.29, 0, 0.56), "skin", P, bevel=0.02, verts=10, rot=(0, s * 165, 0), parent=root)
        ball(f"Hand{s}", 0.075, (s * 0.355, 0, 0.3), "skin", P, u=12, v=8, parent=root)
    # lanyard + blank name card (Ta'aruf tag; no text)
    for s in (-1, 1):
        box(f"Strap{s}", (0.025, 0.012, 0.24), (s * 0.06, -0.163, 0.5), "gold", P, bevel=0.005, chunk=False, rot=(0, s * -18, 0), parent=root)
    box("NameCard", (0.1, 0.02, 0.075), (0, -0.168, 0.44), "warmwhite", P, bevel=0.01, chunk=False, parent=root)
    hz = 1.06  # head centre
    ball("Head", 0.36, (0, 0, hz), "skin", P, scale=(1.05, 0.98, 0.95), u=24, v=16, parent=root)
    for s in (-1, 1):
        ball(f"Ear{s}", 0.07, (s * 0.37, 0.02, hz - 0.02), "skin", P, scale=(0.6, 1, 1), u=10, v=8, parent=root)
        ball(f"Eye{s}", 0.055, (s * 0.13, -0.325, hz - 0.03), "ink", P, scale=(0.8, 0.5, 1.15), u=12, v=8, parent=root)
        ball(f"EyeShine{s}", 0.017, (s * 0.13 + 0.015, -0.355, hz + 0.0), "warmwhite", P, u=8, v=6, parent=root)
        ball(f"Blush{s}", 0.05, (s * 0.22, -0.29, hz - 0.12), "rose", P, scale=(1.2, 0.35, 0.7), u=10, v=6, parent=root)
    ball("Hair", 0.39, (0, 0.06, hz + 0.08), "hair", P, scale=(1.06, 1.0, 0.92), u=32, v=20, parent=root)
    # bangs: flattened caps hugging the forehead (head front is at y = -0.35)
    ball("Fringe", 0.3, (0, -0.17, hz + 0.19), "hair", P, scale=(1.2, 0.6, 0.45), u=24, v=12, parent=root)
    for s in (-1, 1):
        ball(f"FringeSide{s}", 0.13, (s * 0.24, -0.2, hz + 0.1), "hair", P, scale=(0.8, 0.7, 1.0), u=12, v=8, parent=root)
    ball("Tuft", 0.07, (0.08, -0.05, hz + 0.4), "hair", P, scale=(1, 1, 1.4), u=10, v=8, rot=(0, 25, 0), parent=root)
    return P

def build_all():
    sc = bpy.data.scenes.get("hero") or bpy.data.scenes.new("hero")
    bpy.context.window.scene = sc
    bpy.data.orphans_purge(do_recursive=True)  # keeps mesh names free of .001 suffixes on rebuilds
    out = {}
    room, outside = build_room()
    jobs = [("assets/props/bed.glb", build_bed()), ("assets/props/locker.glb", build_locker()),
            ("assets/props/table.glb", build_table()), ("assets/collectibles/wet_wipes.glb", build_wet_wipes()),
            ("assets/props/tidy_desk_books.glb", build_tidy_books()), ("assets/characters/protagonist.glb", build_protagonist())]
    # the room glb carries the shell and its outside surroundings
    for o in outside.all_objects:
        room.objects.link(o)
    jobs.insert(0, ("assets/rooms/mahallah_room.glb", room))
    for rel, col in jobs:
        export(col, rel); out[rel] = tris(col)
    for o in list(outside.objects):
        room.objects.unlink(o)
    bpy.ops.wm.save_as_mainfile(filepath=PROJECT + "art/src/hero_room304.blend")
    return out
