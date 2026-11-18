# TraitDeck characters (~2.5 heads, static meshes, face -Y, feet at z=0). Blender 5.2.
# Run inside Blender: exec(open(<this file>).read()); build_characters()
import bpy, math, os, re
exec(open(os.path.join(r"G:/IIUM Docs/Year 3/Sem 2/FYP 1/trait-deck/art/src", "build_batch.py")).read())

CHARACTERS = {
    # shirt, legs ("skirt_<colour>" for a long skirt), hair style, hair/tudung colour, extras
    "haris":                 dict(shirt="denim", legs="navy", hair="spiky", hc="hair", extras=["glasses", "lanyard"]),
    "facilitator_m":         dict(shirt="rose", legs="navy", hair="short", hc="ink", extras=["lanyard", "cap"]),
    "facilitator_f":         dict(shirt="rose", legs="skirt_navy", hair="tudung", hc="lilac", extras=["lanyard"]),
    "pakcik_stall":          dict(shirt="warmwhite", legs="walnut", hair="kopiah", hc="stone", extras=["apron", "moustache"], belly=1.15),
    "lost_freshman":         dict(shirt="teal", legs="skirt_denim", hair="tudung", hc="peach", extras=["lanyard", "map"]),
    "international_student": dict(shirt="leaf", legs="navy", hair="curly", hc="ink", skin="walnut", extras=["backpack", "lanyard"]),
    "crowd_student_a":       dict(shirt="teal", legs="navy", hair="short", hc="hair", extras=["lanyard"]),
    "crowd_student_b":       dict(shirt="teal", legs="skirt_navy", hair="tudung", hc="sage", extras=["lanyard"]),
    "crowd_student_c":       dict(shirt="teal", legs="navy", hair="spiky", hc="ink", extras=["lanyard", "glasses"]),
}

def build_character(P, spec, root):
    sk = spec.get("skin", "skin"); hc = spec["hc"]; belly = spec.get("belly", 1.0); legs = spec["legs"]
    for s in (-1, 1):
        box(f"Shoe{s}", (0.17, 0.27, 0.1), (s * 0.12, -0.03, 0), "ink" if sk == "walnut" else "walnut", P, bevel=0.045, parent=root)
    if legs.startswith("skirt_"):
        cyl("Skirt", 0.2, 0.36, (0, 0, 0.06), legs[6:], P, bevel=0.04, r2=0.17, verts=16, parent=root)
    else:
        for s in (-1, 1):
            cyl(f"Leg{s}", 0.075, 0.26, (s * 0.11, 0, 0.07), legs, P, bevel=0.02, verts=12, parent=root)
    box("Torso", (0.46 * belly, 0.32 * belly, 0.44), (0, 0, 0.3), spec["shirt"], P, bevel=0.1, seg=4, chunk=False, parent=root)
    for s in (-1, 1):
        cyl(f"Sleeve{s}", 0.085, 0.14, (s * 0.25 * belly, 0, 0.6), spec["shirt"], P, bevel=0.03, verts=12, rot=(0, s * 155, 0), parent=root)
        cyl(f"Arm{s}", 0.06, 0.26, (s * 0.29 * belly, 0, 0.56), sk, P, bevel=0.02, verts=10, rot=(0, s * 165, 0), parent=root)
        ball(f"Hand{s}", 0.075, (s * 0.355 * belly, 0, 0.3), sk, P, u=12, v=8, parent=root)
    hz = 1.06
    h = spec["hair"]
    ball("Head", 0.36, (0, 0, hz), sk, P, scale=(1.05, 0.98, 0.95), u=24, v=16, parent=root)
    for s in (-1, 1):
        if h != "tudung":
            ball(f"Ear{s}", 0.07, (s * 0.37, 0.02, hz - 0.02), sk, P, scale=(0.6, 1, 1), u=10, v=8, parent=root)
        ball(f"Eye{s}", 0.055, (s * 0.13, -0.325, hz - 0.03), "ink", P, scale=(0.8, 0.5, 1.15), u=12, v=8, parent=root)
        ball(f"EyeShine{s}", 0.017, (s * 0.13 + 0.015, -0.355, hz), "warmwhite", P, u=8, v=6, parent=root)
        ball(f"Blush{s}", 0.048, (s * 0.22, -0.29, hz - 0.12), "rose", P, scale=(1.2, 0.35, 0.7), u=10, v=6, parent=root)
    if h in ("short", "spiky"):
        ball("Hair", 0.39, (0, 0.06, hz + 0.08), hc, P, scale=(1.06, 1.0, 0.92), u=32, v=20, parent=root)
        ball("Fringe", 0.3, (0, -0.17, hz + 0.19), hc, P, scale=(1.2, 0.6, 0.45), u=24, v=12, parent=root)
        for s in (-1, 1):
            ball(f"FringeSide{s}", 0.13, (s * 0.24, -0.2, hz + 0.1), hc, P, scale=(0.8, 0.7, 1.0), u=12, v=8, parent=root)
        if h == "spiky":
            for k, (x, y) in enumerate([(-0.15, -0.05), (0.0, -0.1), (0.15, -0.05), (0.05, 0.12)]):
                cyl(f"Spike{k}", 0.09, 0.18, (x, y, hz + 0.33), hc, P, bevel=0, r2=0.0, verts=8, rot=(0, x * 80, 0), parent=root)
        else:
            ball("Tuft", 0.07, (0.08, -0.05, hz + 0.4), hc, P, scale=(1, 1, 1.4), u=10, v=8, rot=(0, 25, 0), parent=root)
    elif h == "curly":
        for k in range(9):
            a = k / 9 * 2 * math.pi
            ball(f"Curl{k}", 0.15, (0.28 * math.cos(a), 0.05 + 0.24 * math.sin(a), hz + 0.22), hc, P, u=12, v=8, parent=root)
        ball("CurlTop", 0.28, (0, 0.05, hz + 0.27), hc, P, scale=(1, 1, 0.7), u=16, v=10, parent=root)
    elif h == "tudung":  # hijab: a hood set back from the head, so the face shows through a ~0.3 m round opening
        ball("Tudung", 0.42, (0, 0.12, hz + 0.05), hc, P, scale=(1.08, 1.0, 1.04), u=32, v=20, parent=root)
        cyl("TudungDrape", 0.34, 0.3, (0, 0.05, 0.56), hc, P, bevel=0.06, r2=0.26, verts=20, parent=root)
    elif h == "kopiah":
        ball("Hair", 0.375, (0, 0.06, hz + 0.02), hc, P, scale=(1.05, 1.0, 0.9), u=24, v=16, parent=root)
        cyl("Kopiah", 0.3, 0.16, (0, 0.03, hz + 0.25), "warmwhite", P, bevel=0.04, verts=20, parent=root)
    ex = spec.get("extras", [])
    if "lanyard" in ex:
        for s in (-1, 1):
            box(f"Strap{s}", (0.025, 0.012, 0.24), (s * 0.06, -0.163 * belly, 0.5), "gold", P, bevel=0.005, chunk=False, rot=(0, s * -18, 0), parent=root)
        box("NameCard", (0.1, 0.02, 0.075), (0, -0.168 * belly, 0.44), "warmwhite", P, bevel=0.01, chunk=False, parent=root)
    if "glasses" in ex:
        for s in (-1, 1):
            cyl(f"Lens{s}", 0.075, 0.015, (s * 0.13, -0.345, hz - 0.03), "ink", P, bevel=0, rot=(90, 0, 0), verts=14, parent=root)
            cyl(f"LensIn{s}", 0.06, 0.02, (s * 0.13, -0.342, hz - 0.03), "glass", P, bevel=0, rot=(90, 0, 0), verts=14, parent=root)
        box("Bridge", (0.1, 0.015, 0.015), (0, -0.35, hz - 0.03), "ink", P, bevel=0, chunk=False, parent=root)
    if "cap" in ex:
        ball("CapCrown", 0.43, (0, 0.05, hz + 0.16), "rose", P, scale=(1.04, 1.04, 0.62), u=24, v=12, parent=root)
        box("CapBrim", (0.44, 0.28, 0.035), (0, -0.36, hz + 0.17), "rose", P, bevel=0.012, chunk=False, rot=(-8, 0, 0), parent=root)
    if "apron" in ex:
        box("Apron", (0.4, 0.04, 0.5), (0, -0.17 * belly, 0.24), "peach", P, bevel=0.02, chunk=False, parent=root)
        box("ApronPocket", (0.2, 0.02, 0.09), (0, -0.19 * belly, 0.34), "terracotta", P, bevel=0.01, chunk=False, parent=root)
    if "moustache" in ex:
        ball("Moustache", 0.07, (0, -0.33, hz - 0.13), "stone", P, scale=(1.6, 0.6, 0.5), u=12, v=8, parent=root)
    if "backpack" in ex:
        box("Backpack", (0.36, 0.18, 0.4), (0, 0.24, 0.32), "gold", P, bevel=0.07, chunk=False, parent=root)
    if "map" in ex:
        box("HeldMap", (0.22, 0.02, 0.16), (0.24, -0.2, 0.36), "sage", P, bevel=0.005, chunk=False, rot=(-20, 0, -15), parent=root)

def build_kitten(P, root):
    ball("Body", 0.13, (0, 0.05, 0.12), "peach", P, scale=(0.85, 1.25, 0.8), u=16, v=10, parent=root)
    ball("Head", 0.11, (0, -0.13, 0.22), "peach", P, u=16, v=10, parent=root)
    for s in (-1, 1):
        cyl(f"Ear{s}", 0.045, 0.07, (s * 0.06, -0.13, 0.3), "peach", P, bevel=0, r2=0.0, verts=6, rot=(0, s * 15, 0), parent=root)
        ball(f"Eye{s}", 0.022, (s * 0.045, -0.225, 0.235), "ink", P, scale=(0.9, 0.5, 1.2), u=8, v=6, parent=root)
        ball(f"Paw{s}", 0.035, (s * 0.06, -0.1, 0.03), "warmwhite", P, u=8, v=6, parent=root)
    ball("Muzzle", 0.04, (0, -0.215, 0.2), "warmwhite", P, scale=(1.2, 0.6, 0.8), u=10, v=6, parent=root)
    ball("Nose", 0.012, (0, -0.24, 0.215), "rose", P, u=6, v=4, parent=root)
    for k in range(3):
        box(f"Stripe{k}", (0.16, 0.04, 0.02), (0, k * 0.08, 0.215), "copper", P, bevel=0.01, chunk=False, parent=root)
    cyl("Tail", 0.025, 0.24, (0.02, 0.2, 0.1), "peach", P, bevel=0.01, verts=8, rot=(-40, 0, 10), parent=root)

# Idle-animation pivots (scenes/idle_animator.gd turns these): head parts hang off a neck pivot,
# kitten ears/tail off their base. Matched by the object's base name (Blender adds .001 / digits).
HEAD_PARTS = {"Head", "Ear", "Eye", "EyeShine", "Blush", "Hair", "Fringe", "FringeSide", "Spike", "Tuft", "Curl",
              "CurlTop", "Tudung", "Kopiah", "Lens", "LensIn", "Bridge", "CapCrown", "CapBrim", "Moustache",
              "Muzzle", "Nose"}

def _base(o):
    return re.match(r"[A-Za-z]+", o.name).group()

def _reparent(objs, pivot):
    bpy.context.view_layer.update()
    for o in objs:
        mw = o.matrix_world.copy(); o.parent = pivot; o.matrix_world = mw

def add_pivots(P, root, kitten=False):
    bpy.context.view_layer.update()
    kids = list(root.children)
    if kitten:
        hp = empty("HeadPivot", P, loc=(0, -0.05, 0.2), parent=root)
        for s in (-1, 1):
            ep = empty(f"EarPivot{'L' if s < 0 else 'R'}", P, loc=(s * 0.06, -0.13, 0.3), parent=root)
            _reparent([o for o in kids if _base(o) == "Ear" and o.location.x * s > 0], ep)
            _reparent([ep], hp)
        tp = empty("TailPivot", P, loc=(0.02, 0.2, 0.1), parent=root)
        _reparent([o for o in kids if _base(o) == "Tail"], tp)
        _reparent([o for o in kids if _base(o) in HEAD_PARTS and _base(o) != "Ear"], hp)
    else:
        hp = empty("HeadPivot", P, loc=(0, 0, 0.74), parent=root)
        _reparent([o for o in kids if _base(o) in HEAD_PARTS], hp)
        # walk-cycle pivots: legs/shoes swing from the hips, sleeves/arms/hands from the shoulders
        for s, side in ((-1, "L"), (1, "R")):
            hip = empty(f"HipPivot{side}", P, loc=(s * 0.11, 0, 0.33), parent=root)
            _reparent([o for o in kids if _base(o) in ("Leg", "Shoe") and o.location.x * s > 0], hip)
            sh = empty(f"ShoulderPivot{side}", P, loc=(s * 0.25, 0, 0.62), parent=root)
            _reparent([o for o in kids if _base(o) in ("Sleeve", "Arm", "Hand") and o.location.x * s > 0], sh)

def build_characters():
    _use_scene(); out = {}
    for cid, spec in CHARACTERS.items():
        P = coll("EX_" + cid); root = empty("Model", P); build_character(P, spec, root); add_pivots(P, root)
        export(P, f"assets/characters/{cid}.glb"); out[cid] = tris(P)
    P = coll("EX_stray_kitten"); root = empty("Model", P); build_kitten(P, root); add_pivots(P, root, kitten=True)
    export(P, "assets/characters/stray_kitten.glb"); out["stray_kitten"] = tris(P)
    P = build_protagonist(); add_pivots(P, next(o for o in P.objects if o.name.startswith("Model")))
    export(P, "assets/characters/protagonist.glb"); out["protagonist"] = tris(P)
    # crowd cluster: 5 students in a loose ring facing the centre; origin = marker point on the floor
    G = coll("EX_crowd_cluster")
    for k, (cid, ang) in enumerate([("crowd_student_a", 0), ("crowd_student_b", 72), ("crowd_student_c", 144),
                                    ("crowd_student_b", 216), ("crowd_student_a", 288)]):
        a = math.radians(ang)
        r = empty(f"Student{k}", G, loc=(0.85 * math.sin(a), 0.85 * math.cos(a), 0))
        r.rotation_euler = (0, 0, -a)  # local -Y (the face) points at the centre
        build_character(G, CHARACTERS[cid], r); add_pivots(G, r)
    export(G, "assets/characters/crowd_cluster.glb"); out["crowd_cluster"] = tris(G)
    bpy.ops.wm.save_as_mainfile(filepath=PROJECT + "art/src/batch.blend")
    return out
