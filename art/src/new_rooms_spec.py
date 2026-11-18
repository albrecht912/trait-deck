# Shared layout for the five new rooms, in GODOT coordinates (x, y, z); floor top at y = 0.
# Read by build_new_rooms.py (Blender geometry) and gen_new_room_scenes.py (.tscn files),
# so walkable area, gameplay markers and the geometry that frames them cannot drift apart.
# Default camera (0, 3, 6) looking -Z: the playable floor spans x -9..9, z -9..5.

FLOOR = dict(x0=-9.0, x1=9.0, z0=-9.0, z1=5.0)
WALK = dict(x0=-6.5, x1=6.5, z0=-6.0, z1=3.5)  # navmesh rectangle; decor that blocks sight stays outside it

ROOMS = {
    "shas_foyer": dict(
        title="ShasFoyer", spawn=(4.0, 0, 3.0), waypoint=(-2.2, 0.5, -2.2),
        collectibles={"adapter_plug": (6.0, 0, 1.0), "lapel_pin": (-6.0, 0, -3.0)},
        npcs=[dict(name="FoyerFacilitator", kind="npc", id="foyer_facilitator", character="facilitator_f", pos=(5.0, 0, -2.0),
                   line="Assalamualaikum! RHB card activation on the left, ASNB in the middle, NotebookLM workshop sign-up on the right.")],
        pois=[dict(name="PrayerTimesBoard", id="prayer_times_board", pos=(-6.3, 0, 0.5),
                   line="Today's prayer times, plus the Ta'aruf Week schedule for the SHAS Mosque.")],
        crowd=(-2.2, 0, -4.5), crowd_visual=False,
        decor=[("crowd_student_a", (-2.2, 0, -6.0), 0), ("crowd_student_b", (-2.2, 0, -5.1), 0), ("crowd_student_c", (-2.2, 0, -4.2), 0),
               ("crowd_student_b", (-2.2, 0, -3.3), 0)],
        labels=[("RHB", (-4.0, 2.75, -7.3)), ("ASNB", (0.0, 2.75, -7.3)), ("NotebookLM", (4.0, 2.75, -7.3))],
    ),
    "mosque_walkway": dict(
        title="MosqueWalkway", spawn=(-5.0, 0, 2.5), waypoint=(1.2, 0.5, -3.2),
        collectibles={"umbrella": (-6.0, 0, -5.0), "lozenges": (5.5, 0, 2.0)},
        npcs=[dict(name="StrayKitten", kind="npc", id="stray_kitten", character="stray_kitten", pos=(2.5, 0, -3.9),
                   line="Mew... (the kitten is shivering, and it looks hungry)")],
        pois=[dict(name="WalkwaySign", id="walkway_sign", pos=(-3.0, 0, -5.6),
                   line="A small sign: 'Please keep the walkway clean. Remove shoes beyond this line.'")],
        crowd=(-1.0, 0, -5.4), crowd_visual=True, decor=[], labels=[],
    ),
    "kulliyyah_courtyard": dict(
        title="KulliyyahCourtyard", spawn=(-4.0, 0, 3.0), waypoint=(1.5, 0.5, -1.5),
        collectibles={"pocket_notebook": (5.5, 0, -5.0), "club_handbook": (-6.0, 0, 1.5), "flashlight_whistle": (6.0, 0, 2.5)},
        npcs=[dict(name="LostFreshman", kind="npc", id="lost_freshman", character="lost_freshman", pos=(2.5, 0, -2.5),
                   line="Um... do you know where the Insan Madani session is? This map makes no sense...")],
        pois=[dict(name="KulliyyahDirectory", id="kulliyyah_directory", pos=(-5.5, 0, -5.4),
                   line="Directory: KICT, KENMS, AIKOL, KIRKHS, KOE, KAED. Insan Madani session: Main Auditorium.")],
        crowd=(-2.0, 0, -4.8), crowd_visual=True, decor=[], labels=[],
    ),
    "rain_corridor": dict(
        title="RainCorridor", spawn=(-5.0, 0, 2.5), waypoint=(0.6, 0.5, -3.4),
        collectibles={"ors_packets": (-6.0, 0, -5.0)},
        npcs=[], pois=[dict(name="OldNoticeboard", id="old_noticeboard", pos=(-4.0, 0, -5.6),
                             line="Faded notices: 'Wing under renovation. Use the main corridor.'")],
        crowd=None, crowd_visual=False,
        decor=[("crowd_student_b", (1.5, 0, -4.6), "lying"), ("crowd_student_a", (2.5, 0, -4.0), 0)],
        labels=[], rain=True,
    ),
    "iium_clinic": dict(
        title="IiumClinic", spawn=(-4.0, 0, 3.0), waypoint=(0.0, 0.5, -4.8),
        collectibles={}, npcs=[],
        pois=[dict(name="QueueScreen", id="clinic_queue_screen", pos=(3.5, 0, -5.4),
                   line="Now serving: 042. Please take a number and wait to be called.")],
        crowd=None, crowd_visual=False, decor=[], labels=[("Triage", (0.0, 2.9, -7.6))],
    ),
}
