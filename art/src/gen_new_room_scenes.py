"""Generate scenes/<room>.tscn for the five new rooms from new_rooms_spec.py.
Run with plain Python from the project root:  python -I art/src/gen_new_room_scenes.py
Re-running overwrites those five .tscn files (they are generated; edit the spec instead).
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.normpath(os.path.join(HERE, "..", ".."))
spec = {}
exec(open(os.path.join(HERE, "new_rooms_spec.py"), encoding="utf-8").read(), spec)
FLOOR, WALK, ROOMS = spec["FLOOR"], spec["WALK"], spec["ROOMS"]

def v3(p): return f"{p[0]}, {p[1]}, {p[2]}"
def xf(p, basis="1, 0, 0, 0, 1, 0, 0, 0, 1"): return f"transform = Transform3D({basis}, {v3(p)})"
def esc(s): return s.replace("\\", "\\\\").replace('"', '\\"')

LYING = "1, 0, 0, 0, 0, -1, 0, 1, 0"  # model rotated -90 deg about X: lies on its back, head toward -Z

def navmesh(w):
    # one convex quad, winding matches Godot-baked polygons (positive cross product in x/z)
    x0, x1, z0, z1 = w["x0"], w["x1"], w["z0"], w["z1"]
    verts = [(x1, 0, z1), (x0, 0, z1), (x0, 0, z0), (x1, 0, z0)]
    return ("vertices = PackedVector3Array(" + ", ".join(v3(v) for v in verts) + ")\n"
            "polygons = [PackedInt32Array(0, 1, 2, 3)]")

def scene(name, r):
    ext, nodes = [], []
    def res(typ, path, rid):
        line = f'[ext_resource type="{typ}" path="{path}" id="{rid}"]'
        if line not in ext: ext.append(line)
        return rid
    res("Script", "res://scenes/mahallah_room.gd", "room_gd")
    res("PackedScene", f"res://assets/rooms/{name}.glb", "visual")
    res("PackedScene", "res://assets/arrow.glb", "arrow")
    res("Script", "res://scenes/floor_snap.gd", "snap_fs")

    nodes.append(f'[node name="{r["title"]}" type="Node3D"]\nscript = ExtResource("room_gd")')
    nodes.append(f'[node name="SpawnPoint" type="Marker3D" parent="."]\n{xf(r["spawn"])}')
    nodes.append('[node name="NavigationRegion3D" type="NavigationRegion3D" parent="."]\nnavigation_mesh = SubResource("nav")')
    nodes.append('[node name="VisualMap" parent="NavigationRegion3D" instance=ExtResource("visual")]')
    nodes.append(f'[node name="ActiveWaypoint" type="Node3D" parent="."]\n{xf(r["waypoint"])}')
    nodes.append('[node name="Area3D" type="Area3D" parent="ActiveWaypoint"]\ncollision_layer = 2')
    nodes.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="ActiveWaypoint/Area3D"]\nshape = SubResource("wp_shape")')
    nodes.append('[node name="arrow" parent="ActiveWaypoint" instance=ExtResource("arrow")]\n'
                 'transform = Transform3D(0.275, 0, 0, 0, 0.275, 0, 0, 0, 0.275, 0, 0.722363, 0)')
    if r["collectibles"]:
        res("PackedScene", "res://scenes/unmarked_collectible.tscn", "coll")
    for k, (item, p) in enumerate(r["collectibles"].items()):
        nodes.append(f'[node name="Collectible_{item}" parent="." instance=ExtResource("coll")]\n{xf(p)}\nitem_id = "{item}"')
    if r["npcs"] or r["pois"]:
        res("PackedScene", "res://scenes/optional_interactable.tscn", "opt")
    for n in r["npcs"] + [dict(p, kind="poi") for p in r["pois"]]:
        body = f'[node name="{n["name"]}" parent="." instance=ExtResource("opt")]\n{xf(n["pos"])}\nkind = "{n["kind"]}"\n' \
               f'interact_id = "{n["id"]}"\nline = "{esc(n["line"])}"'
        if n.get("character"):
            body += f'\ncharacter = "{n["character"]}"'
        nodes.append(body)
    if r["crowd"]:
        nodes.append(f'[node name="Crowd" type="Marker3D" parent="." groups=["crowd"]]\n{xf(r["crowd"])}')
        if r["crowd_visual"]:
            res("PackedScene", "res://assets/characters/crowd_cluster.glb", "crowd_cc")
            nodes.append('[node name="CrowdVisual" parent="Crowd" instance=ExtResource("crowd_cc")]\nscript = ExtResource("snap_fs")')
    for k, (char, p, pose) in enumerate(r["decor"]):
        rid = res("PackedScene", f"res://assets/characters/{char}.glb", "chr_" + char)
        if pose == "lying":  # lying on the floor: no floor snap (it would stand the pivot on the floor)
            nodes.append(f'[node name="Decor{k}" parent="." instance=ExtResource("{rid}")]\n'
                         f'transform = Transform3D({LYING}, {p[0]}, 0.33, {p[2]})')
        else:
            nodes.append(f'[node name="Decor{k}" parent="." instance=ExtResource("{rid}")]\n{xf(p)}\nscript = ExtResource("snap_fs")')
    for k, (text, p) in enumerate(r["labels"]):
        nodes.append(f'[node name="Label{k}" type="Label3D" parent="."]\n{xf(p)}\npixel_size = 0.006\ntext = "{esc(text)}"\n'
                     'font_size = 72\noutline_size = 16\nmodulate = Color(0.29, 0.231, 0.2, 1)\noutline_modulate = Color(1, 0.953, 0.863, 1)')
    if r.get("rain"):
        nodes.append('[node name="Rain" type="GPUParticles3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 9, -1)\n'
                     'amount = 1800\nlifetime = 0.9\npreprocess = 1.0\nvisibility_aabb = AABB(-11, -11, -8, 22, 12, 16)\n'
                     'process_material = SubResource("rain_pm")\ndraw_pass_1 = SubResource("rain_mesh")')

    subs = [f'[sub_resource type="NavigationMesh" id="nav"]\n{navmesh(WALK)}', '[sub_resource type="BoxShape3D" id="wp_shape"]']
    if r.get("rain"):
        subs += ['[sub_resource type="ParticleProcessMaterial" id="rain_pm"]\nemission_shape = 3\nemission_box_extents = Vector3(10, 0.5, 7)\n'
                 'direction = Vector3(0.08, -1, 0)\nspread = 2.0\ninitial_velocity_min = 13.0\ninitial_velocity_max = 16.0\ngravity = Vector3(0, -9.8, 0)',
                 '[sub_resource type="StandardMaterial3D" id="rain_mat"]\ntransparency = 1\nshading_mode = 0\n'
                 'albedo_color = Color(0.78, 0.88, 1, 0.45)\nbillboard_mode = 2\nbillboard_keep_scale = true',
                 '[sub_resource type="QuadMesh" id="rain_mesh"]\nmaterial = SubResource("rain_mat")\nsize = Vector2(0.025, 0.55)']
    conn = '[connection signal="body_entered" from="ActiveWaypoint/Area3D" to="." method="_on_area_3d_body_entered"]'
    return "[gd_scene format=3]\n\n" + "\n".join(ext) + "\n\n" + "\n\n".join(subs) + "\n\n" + "\n\n".join(nodes) + "\n\n" + conn + "\n"

for name, r in ROOMS.items():
    path = os.path.join(PROJECT, "scenes", name + ".tscn")
    open(path, "w", encoding="utf-8", newline="\n").write(scene(name, r))
    print("wrote", os.path.relpath(path, PROJECT))
