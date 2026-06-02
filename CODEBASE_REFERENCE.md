# TraitDeck — Codebase Function Reference

> Auto-generated from `map_project` on 2026-06-03.  
> **20 scripts · 6 signal connections** across the project.

---

## Table of Contents

1. [database_manager.gd](#1-database_managergd)
2. [main_scene.gd](#2-main_scenegdscenes)
3. [session_manager.gd](#3-session_managergdscenes)
4. [camera_3d.gd](#4-camera_3dgdscenes)
5. [player.gd](#5-playergdscenes)
6. [mouse_click_detector.gd](#6-mouse_click_detectorgdscenes)
7. [mahallah_room.gd (BaseRoom)](#7-mahallah_roomgd--baseroom--scenes)
8. [pause_screen.gd (PauseScreen)](#8-pause_screengd--pausescreen--scenes)
9. [title_screen.gd (TitleScreen)](#9-title_screengd--titlescreen--scenes)
10. [results_ui.gd](#10-results_uigdscenes)
11. [question_card.gd (QuestionCard)](#11-question_cardgd--questioncard--scenesui)
12. [hand.gd (Hand)](#12-handgd--hand--scenesui)
13. [card_ui.gd (CardUI)](#13-card_uigd--cardui--scenescard_ui)
14. [card_state_machine.gd (CardStateMachine)](#14-card_state_machinegd--cardstatemachine--scenescard_ui)
15. [card_state.gd (CardState)](#15-card_stategdscenes--card_uicard_states)
16. [card_base_state.gd](#16-card_base_stategdscenes--card_uicard_states)
17. [card_clicked_state.gd](#17-card_clicked_stategdscenes--card_uicard_states)
18. [card_dragging_state.gd](#18-card_dragging_stategdscenes--card_uicard_states)
19. [card_released_state.gd](#19-card_released_stategdscenes--card_uicard_states)
20. [card_selected_state.gd](#20-card_selected_stategdscenes--card_uicard_states)

---

## 1. `database_manager.gd`
**Path:** `res://database_manager.gd`  
**Extends:** `Node` (registered as Autoload singleton `DatabaseManager`)  
**Purpose:** Opens the SQLite database at `user://traitdeck_save.db` and ensures all schema tables exist on every launch.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Godot lifecycle hook. Called once when the node enters the scene tree. Immediately delegates to `initialize_database()`. |
| `initialize_database()` | `() → void` | Creates a new `SQLite` instance, sets the database path to `user://traitdeck_save.db`, opens the connection, enables foreign key enforcement via `PRAGMA foreign_keys = ON`, then calls `create_schema_tables()`. |
| `create_schema_tables()` | `() → void` | Runs five `CREATE TABLE IF NOT EXISTS` queries to build the full BFI-2 schema: **DOMAIN** (personality trait categories), **ITEM** (the 12 assessment questions), **CARD_OPTION** (the 5 Likert answer cards per item), **SESSION** (one row per playthrough with student name and timestamp), and **PLAYER_RESPONSE** (associative table linking a session to the card the player chose for each item). All tables are idempotent — safe to call on every launch. |

---

## 2. `main_scene.gd`
**Path:** `res://scenes/main_scene.gd`  
**Extends:** `Node3D`  
**Purpose:** Root script for the main game scene. Handles the global pause menu toggle.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Godot lifecycle hook. Currently a stub (`pass`) — reserved for future main-scene initialization. |
| `_process(_delta)` | `(_delta: float) → void` | Per-frame update hook. Currently a stub — reserved for future per-frame logic. |
| `_unhandled_input(event)` | `(event: InputEvent) → void` | Listens for the `ui_cancel` action (Escape key by default). If no pause screen is currently active (`_active_pause_screen == null`), calls `_open_pause_menu()` to instantiate the overlay. |
| `_open_pause_menu()` | `() → void` | Instantiates a fresh copy of `pause_screen.tscn` from the preloaded `PAUSE_SCREEN_SCENE` resource and adds it as a child of the main scene. The `PauseScreen._ready()` then takes over and sets `get_tree().paused = true`. |

---

## 3. `session_manager.gd`
**Path:** `res://scenes/session_manager.gd`  
**Extends:** `Node`  
**Purpose:** The central game loop orchestrator. Manages the two-phase loop (Explore → Assess) for all 12 BFI-2 items, writes responses to the database, and drives the dynamic lighting system.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Hides the results UI, connects the restart signal, queries the database for the most recently created SESSION row to resolve `current_student_name`, calls `_start_new_playthrough()`, connects the card answer signal from `Hand`, and kicks off the first scenario with `_load_scenario(1)`. |
| `_start_new_playthrough(student_name)` | `(student_name: String) → void` | Inserts a new SESSION row into the database for the given student name and stores the auto-incremented `session_id` in `active_session_id`. This ID is used as the foreign key for all subsequent PLAYER_RESPONSE inserts. |
| `_load_scenario(item_id)` | `(item_id: int) → void` | **Async.** The core room-loading pipeline. Steps: (A) checks if the item exists in `session_timeline`; (B) purges the old room from `CurrentRoom`; (C) locks player input; (D) loads and instances the new room scene; (E) disables the `ActiveWaypoint` Area3D before teleporting; (F) teleports the player to `SpawnPoint`; (G) syncs the camera; (H) awaits two physics frames for the PhysicsServer to settle; (I) re-enables the waypoint; (J) pre-fetches and caches the question text and card rows from the DB; (K) hides the AnswerUI and unlocks player movement; (L) updates global lighting. |
| `_on_player_reached_waypoint()` | `() → void` | Called by `BaseRoom` when the player's `CharacterBody3D` enters the `ActiveWaypoint` Area3D. Locks player movement, shows the `AnswerUI`, slides the `QuestionCard` in from the right with the cached question text, and populates the `Hand` with the cached card options. |
| `_on_card_answer_submitted(card)` | `(card: CardUI) → void` | Signal handler connected to `Hand.card_answer_submitted`. Logs the submission, calls `_save_response()` with the card's database ID, then calls `_advance_to_next_scenario()`. |
| `_advance_to_next_scenario()` | `() → void` | **Async.** Slides the `QuestionCard` off-screen to the left, awaits the `slide_out_finished` signal, increments `current_item_id`, and calls `_load_scenario()` for the next item. |
| `_save_response(played_card_id)` | `(played_card_id: int) → void` | Inserts a row into `PLAYER_RESPONSE` linking `active_session_id` to the chosen `card_id`. After saving, calls `_process_environmental_updates()` to recalculate lighting. |
| `_on_assessment_completed()` | `() → void` | Called when `_load_scenario()` receives an `item_id` beyond the timeline. Queries the final domain averages for all five BFI-2 traits, passes them to `ResultsUI.display_scores()`, hides the AnswerUI, and shows the ResultsUI. |
| `_on_restart_requested()` | `() → void` | Signal handler for `ResultsUI.restart_requested`. Hides both UIs, starts a new playthrough for the same student, resets `current_item_id` to 1, and reloads the first scenario. |
| `_get_domain_average(domain_name)` | `(domain_name: String) → float` | Executes a SQL `AVG()` query joining `PLAYER_RESPONSE`, `CARD_OPTION`, `ITEM`, and `DOMAIN` for the current session. Applies reverse-scoring (`6 - likert_value`) for items where `is_reverse = 1`. Returns `3.0` as a neutral fallback if no data exists. |
| `_process_environmental_updates()` | `() → void` | Fetches the current Extraversion domain average, maps it to a 0–1 blend factor, and lerps the `DirectionalLight3D`'s color (cool blue → warm amber) and energy (0.5 → 1.5) to reflect the player's personality profile in real time. |

---

## 4. `camera_3d.gd`
**Path:** `res://scenes/camera_3d.gd`  
**Extends:** `Camera3D`  
**Purpose:** Smooth-follow camera that snaps to a room's configured position on load and interpolates toward it every physics frame.

| Function | Signature | Description |
|---|---|---|
| `setup_camera_for_room(_mode, room_pos, room_rot)` | `(_mode: String, room_pos: Vector3, room_rot: Vector3) → void` | Called by `SessionManager._load_scenario()` after a new room is instantiated. Immediately snaps `rotation_degrees` and `global_position` to the room's configured values, and stores `room_pos` as `target_base_position` for the smooth lerp. The `_mode` parameter is reserved for future camera modes (currently forced to `"Static"`). |
| `_physics_process(delta)` | `(delta: float) → void` | Every physics tick, lerps `global_position` toward `target_base_position` using `smooth_speed * delta` as the interpolation weight, creating a smooth camera glide on room load. |

---

## 5. `player.gd`
**Path:** `res://scenes/player.gd`  
**Class:** `Player`  
**Extends:** `CharacterBody3D`  
**Purpose:** Click-to-move player character using Godot's NavigationAgent3D for pathfinding.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Connects `nav_agent.velocity_computed` to `_on_velocity_computed`. The NavigationAgent3D requires one deferred frame after the scene tree is ready before path queries are valid. |
| `set_movement_target(target_point)` | `(target_point: Vector3) → void` | Public API called by `MouseClickDetector`. Sets `nav_agent.target_position` to the 3D world point the player clicked, triggering pathfinding. |
| `teleport_to_position(target_global_pos)` | `(target_global_pos: Vector3) → void` | Called by `SessionManager` during room transitions. Instantly overrides `global_position` to the `SpawnPoint` location, bypassing navigation. |
| `_physics_process(_delta)` | `(_delta: float) → void` | Every physics tick: if the navigation agent has finished its path, zeroes velocity and calls `move_and_slide()`. Otherwise, requests the next safe velocity from the NavigationAgent3D via `nav_agent.get_next_path_position()` and applies avoidance. |
| `_on_velocity_computed(safe_velocity)` | `(safe_velocity: Vector3) → void` | Callback from `NavigationAgent3D.velocity_computed`. Receives the avoidance-corrected velocity, assigns it to `velocity`, and calls `move_and_slide()` to physically move the character. |

---

## 6. `mouse_click_detector.gd`
**Path:** `res://scenes/mouse_click_detector.gd`  
**Extends:** `Node`  
**Purpose:** Translates 2D screen left-clicks into 3D world raycasts and forwards hit positions to the Player for navigation.

| Function | Signature | Description |
|---|---|---|
| `_unhandled_input(event)` | `(event: InputEvent) → void` | Hard-gated by `input_enabled` — does nothing during the assessment phase. Filters for left mouse button press events only, then calls `_cast_ray_and_move()` with the screen position. |
| `_cast_ray_and_move(screen_pos)` | `(screen_pos: Vector2) → void` | Projects a ray from the camera through the 2D screen position into 3D space using `project_ray_origin()` and `project_ray_normal()`. Queries the 3D physics world with `PhysicsDirectSpaceState3D.intersect_ray()`, excluding the player's own collision body. If the ray hits a surface, calls `player.set_movement_target()` with the hit position. |

---

## 7. `mahallah_room.gd` — `BaseRoom` — `scenes/`
**Path:** `res://scenes/mahallah_room.gd`  
**Class:** `BaseRoom`  
**Extends:** `Node3D`  
**Purpose:** Base class for all room scenes. Provides exported camera configuration properties and the waypoint trigger callback. All room `.tscn` files use this script (or a scene that inherits it).

| Function | Signature | Description |
|---|---|---|
| `_on_area_3d_body_entered(body)` | `(body: Node3D) → void` | Connected to the `ActiveWaypoint/Area3D.body_entered` signal in each room scene. Filters for the `Player` `CharacterBody3D` by name. When the player enters the waypoint volume, reaches up the scene tree to `/root/MainScene/SessionManager` and calls `_on_player_reached_waypoint()` to begin the assessment phase. |

---

## 8. `pause_screen.gd` — `PauseScreen` — `scenes/`
**Path:** `res://scenes/pause_screen.gd`  
**Class:** `PauseScreen`  
**Extends:** `CanvasLayer`  
**Purpose:** Pause overlay. Freezes the engine on appearance and resumes it on dismissal. Requires `Process Mode = When Paused` in the Inspector.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Sets `get_tree().paused = true` immediately. Connects `ResumeButton.pressed` and `QuitButton.pressed` with double-connection guards. Calls `resume_button.grab_focus()` so keyboard/gamepad users can navigate without clicking. |
| `_unhandled_input(event)` | `(event: InputEvent) → void` | Listens for `ui_cancel` (Escape). Because `process_mode` is `WHEN_PAUSED`, this fires even while the game is frozen. Calls `_on_resume_button_pressed()` to close the menu. |
| `_on_resume_button_pressed()` | `() → void` | Plays the click sound, sets `get_tree().paused = false`, and calls `queue_free()` to remove the overlay from the scene tree. |
| `_on_quit_button_pressed()` | `() → void` | Plays the click sound, unpauses the engine (prevents shutdown hang), then calls `get_tree().quit()`. |

---

## 9. `title_screen.gd` — `TitleScreen` — `scenes/`
**Path:** `res://scenes/title_screen.gd`  
**Class:** `TitleScreen`  
**Extends:** `Control`  
**Purpose:** Entry point UI. Validates the player's name, writes a SESSION row to the database, and transitions to the main game scene.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Connects `StartButton.pressed`, `QuitButton.pressed`, and `LineEdit.text_submitted` with double-connection guards. Builds a runtime `AcceptDialog` for the empty-name warning. Calls `name_field.grab_focus()` so the player can type immediately. |
| `_on_start_button_pressed()` | `() → void` | Strips whitespace from the name field. If empty, shows the warning dialog and returns. If valid, plays the click sound, calls `_save_session_to_database()`, and transitions to `main_scene.tscn`. |
| `_on_quit_button_pressed()` | `() → void` | Plays the click sound and calls `get_tree().quit()`. |
| `_save_session_to_database(player_name)` | `(player_name: String) → void` | Escapes single quotes in the name (SQL injection prevention), then runs `INSERT INTO SESSION (student_name) VALUES (...)`. `SessionManager` will query this row on startup to resolve the active player name. |
| `_on_name_field_text_submitted(_new_text)` | `(_new_text: String) → void` | Connected to `LineEdit.text_submitted`. Ignores the passed text and delegates directly to `_on_start_button_pressed()` so pressing Enter behaves identically to clicking Start. |

---

## 10. `results_ui.gd`
**Path:** `res://scenes/results_ui.gd`  
**Extends:** `Control`  
**Purpose:** End-of-assessment screen. Displays the five BFI-2 domain scores and provides Restart / Return to Title / Quit options.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Connects `RestartButton.pressed` and `ReturnButton.pressed` with double-connection guards. |
| `display_scores(e, n, a, c, o)` | `(e: float, n: float, a: float, c: float, o: float) → void` | Public API called by `SessionManager._on_assessment_completed()`. Formats each score as `"X.XX / 5.0"` and assigns it to the corresponding Label node (E_Value, N_Value, A_Value, C_Value, O_Value). |
| `_on_restart_pressed()` | `() → void` | Plays the click sound and emits the `restart_requested` signal, which `SessionManager` listens to for resetting the game loop. |
| `_on_return_button_pressed()` | `() → void` | Plays the click sound and calls `get_tree().change_scene_to_file("res://scenes/title_screen.tscn")` to return to the title screen. |
| `_on_quit_button_pressed()` | `() → void` | Plays the click sound and calls `get_tree().quit()`. |

---

## 11. `question_card.gd` — `QuestionCard` — `scenes/ui/`
**Path:** `res://scenes/ui/question_card.gd`  
**Class:** `QuestionCard`  
**Extends:** `Control`  
**Purpose:** The large question prompt card that slides in from the right when the assessment phase begins and slides out to the left when the player submits an answer.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Snaps the card to `POS_OFF_RIGHT` (off-screen right) so the first `slide_in_from_right()` call has no visible flash. |
| `slide_in_from_right(text, question_number)` | `(text: String, question_number: int) → void` | Snaps the card to `POS_OFF_RIGHT`, updates all labels via `_update_labels()`, then tweens `position` to `POS_CENTER` using a cubic ease-out over `SLIDE_IN_DURATION` seconds. |
| `slide_out_to_left()` | `() → void` | Tweens `position` to `POS_OFF_LEFT` using a cubic ease-in. At the end of the tween, emits the `slide_out_finished` signal so `SessionManager._advance_to_next_scenario()` can `await` it before loading the next room. |
| `_update_labels(text, number)` | `(text: String, number: int) → void` | Internal helper. Sets `prompt_label.text` to the question text and both corner number labels (`q_number_top_left`, `q_number_bottom_right`) to the string form of the question number. |
| `setup_question(text, number)` | `(text: String, number: int) → void` | Legacy compatibility wrapper. Delegates directly to `slide_in_from_right()`. |

---

## 12. `hand.gd` — `Hand` — `scenes/ui/`
**Path:** `res://scenes/ui/hand.gd`  
**Class:** `Hand`  
**Extends:** `Control`  
**Purpose:** The card hand container. Deals answer cards from a pile with a staggered animation and arranges them in a fan layout. Relays the player's chosen card up to `SessionManager`.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Calls `update_fan_layout()` to initialize the layout for any cards already in the hand at scene load. |
| `populate_hand_with_choices(cards_data_array)` | `(cards_data_array: Array) → void` | Flushes all existing card children, pre-calculates fan layout targets via `_compute_fan_targets()`, then instantiates one `CardUI` per entry in the data array. Each card is configured with its `card_db_id`, `likert_value`, dialogue text, and `drop_zone` reference. Cards are dealt from `PILE_POSITION` with a staggered tween (fly + rotate + scale-up). After the animation, each card is re-attached to the Hand container and input is re-enabled. |
| `_compute_fan_targets(num_cards)` | `(num_cards: int) → Array` | Pure calculation function. Returns an Array of Dictionaries, each with `"position"` (Vector2 local to Hand) and `"rotation_rad"` (float). Uses `hand_curve` and `rotation_curve` to create a natural arc. Handles the single-card edge case (centered, flat). |
| `_on_card_reparent_requested(child)` | `(child: CardUI) → void` | Signal handler for `CardUI.reparent_requested`. Restores the card to its original sibling index in the Hand using `move_child()`, resets its pivot and rotation, then calls `update_fan_layout()` to reflow the remaining cards. |
| `_on_card_answer_submitted(card)` | `(card: CardUI) → void` | Signal handler for `CardUI.answer_submitted`. Re-emits the `card_answer_submitted` signal upward so `SessionManager` can receive it. |
| `update_fan_layout()` | `() → void` | Iterates all `CardUI` children in `DragState.IDLE` and repositions them in a fan arc using the same curve-based algorithm as `_compute_fan_targets()`. Called after a card is returned to the hand or the hand is first populated. |

---

## 13. `card_ui.gd` — `CardUI` — `scenes/card_ui/`
**Path:** `res://scenes/card_ui/card_ui.gd`  
**Class:** `CardUI`  
**Extends:** `Control`  
**Purpose:** Individual answer card. Handles drag-and-drop interaction, perspective tilt shader, shadow positioning, hover animations, and the dissolve-and-free confirmation sequence.

| Function | Signature | Description |
|---|---|---|
| `_ready()` | `() → void` | Duplicates the shader material on `CardBackground` and `Shadow` so each card has an isolated material instance. Captures the resting positions of all text labels for parallax reset. Calls `_update_likert_labels()` and sets `drag_state` to `IDLE`. |
| `_process(delta)` | `(delta: float) → void` | Calls `handle_shadow(delta)` every frame to keep the shadow position in sync. |
| `handle_shadow(_delta)` | `(_delta: float) → void` | Repositions the `Shadow` TextureRect. Horizontally: shifts away from the screen center proportionally to the card's X distance from center. Vertically: drops further when the card is scaled up (hover/drag), simulating elevation. |
| `_gui_input(event)` | `(event: InputEvent) → void` | Handles all card-specific mouse input. Left-click down on `IDLE` → `_begin_drag()`. Left-click down on `PLACED` → `_confirm_answer()`. Left-click up while `DRAGGING` → `_end_drag()`. Right-click while `DRAGGING` or `PLACED` → `_cancel_drag()`. Also computes the perspective tilt shader values and label parallax offset from mouse motion. |
| `_input(event)` | `(event: InputEvent) → void` | Global input handler. While `DRAGGING`, tracks mouse motion to update `global_position` and applies a velocity-driven wobble rotation via `DampedOscillator`. |
| `_on_mouse_entered()` | `() → void` | Hover-in animation: tweens `scale` to `Vector2(1.2, 1.2)` with an elastic ease-out. Skipped if the card is being dragged or placed. |
| `_on_mouse_exited()` | `() → void` | Hover-out animation: tweens the shader tilt parameters back to 0, returns all text labels to their resting positions, and tweens `scale` back to `Vector2.ONE`. |
| `_begin_drag()` | `() → void` | Captures `original_global_position` and `_drag_offset`. Sets `top_level = true` to escape the Hand container layout. Transitions `drag_state` to `DRAGGING`. Kills hover tweens, resets tilt and labels. Plays a squash-and-stretch pickup spring via `DampedOscillator`. |
| `_end_drag()` | `() → void` | Sets `drag_state` to `RELEASED`. Calls `_place_card()` if `_is_over_drop_zone()` returns true, otherwise calls `_cancel_drag()`. |
| `_place_card()` | `() → void` | Sets `drag_state` to `PLACED` and `top_level = false`. Snaps the card to the center of the `drop_zone` Area2D (or screen center as fallback). Resets rotation, scale, tilt, and label positions. |
| `_cancel_drag()` | `() → void` | Returns the card to `original_global_position`, sets `drag_state` to `IDLE`, resets scale and labels. Plays a snap-back bounce spring via `DampedOscillator`. Emits `reparent_requested` so `Hand` can restore the card's slot. |
| `_confirm_answer()` | `() → void` | Called on left-click while `PLACED`. Calls `animate_dissolve_and_free()` and plays the fizz sound effect. |
| `animate_dissolve_and_free()` | `() → void` | Sets `mouse_filter` to `IGNORE` to block further input. Saves `global_position` before setting `top_level = true`. Tweens the shader's `dissolve_value` from 1.0 → 0.0 over 0.6 seconds. At the end of the tween, emits `answer_submitted` and calls `queue_free()`. |
| `_is_over_drop_zone()` | `() → bool` | Checks if the card's `Rect2` intersects the `drop_zone` Area2D's `RectangleShape2D` collision bounds. Returns `false` if `drop_zone` is null or has no valid shape. |
| `_set_tilt(x_rot, y_rot)` | `(x_rot: float, y_rot: float) → void` | Sets the `x_rot` and `y_rot` shader parameters on both `CardBackground` and `Shadow` materials to create a perspective tilt effect. |
| `_reset_tilt()` | `() → void` | Convenience wrapper — calls `_set_tilt(0.0, 0.0)`. |
| `_reset_label_positions()` | `() → void` | Restores `answer_label`, `likert_top_left`, and `likert_bottom_right` to their captured resting positions from `base_label_positions`. |
| `_kill_hover_tweens()` | `() → void` | Kills `tween_hover` and `tween_rot` if they are currently running, preventing animation conflicts during drag pickup. |
| `_update_likert_labels()` | `() → void` | Updates both corner Likert value labels to display `likert_value` as a string, or an empty string if the value is negative (unset). |
| `set_dialogue_text(new_text)` | `(new_text: String) → void` | Public API called by `Hand.populate_hand_with_choices()`. Sets the `answer_label` text to the card's dialogue string from the database. |

---

## 14. `card_state_machine.gd` — `CardStateMachine` — `scenes/card_ui/`
**Path:** `res://scenes/card_ui/card_state_machine.gd`  
**Class:** `CardStateMachine`  
**Extends:** `Node`  
**Purpose:** Finite State Machine controller for `CardUI`. Manages state transitions and routes input events to the active state.

| Function | Signature | Description |
|---|---|---|
| `init(card)` | `(card: CardUI) → void` | Called by `CardUI._ready()`. Iterates all `CardState` children, registers them in the `states` dictionary keyed by their `State` enum value, connects each state's `transition_requested` signal to `_on_transition_requested()`, and assigns the `card_ui` reference. Enters the `initial_state`. |
| `on_input(event)` | `(event: InputEvent) → void` | Forwards global `_input` events to `current_state.on_input()`. |
| `on_gui_input(event)` | `(event: InputEvent) → void` | Forwards `_gui_input` events to `current_state.on_gui_input()`. |
| `_on_transition_requested(from, to)` | `(from: CardState, to: CardState.State) → void` | Signal handler. Guards against stale transitions (ignores if `from != current_state`). Calls `current_state.exit()`, then `new_state.enter()`, and updates `current_state`. |
| `on_mouse_entered()` | `() → void` | Forwards mouse-entered events to `current_state.on_mouse_entered()`. |
| `on_mouse_exited()` | `() → void` | Forwards mouse-exited events to `current_state.on_mouse_exited()`. |

---

## 15. `card_state.gd` — `scenes/card_ui/card_states/`
**Path:** `res://scenes/card_ui/card_states/card_state.gd`  
**Class:** `CardState`  
**Extends:** `Node`  
**Purpose:** Abstract base class for all card FSM states. Defines the interface every concrete state must implement and declares the `transition_requested` signal used to request state changes.

| Function | Signature | Description |
|---|---|---|
| `enter()` | `() → void` | Called by `CardStateMachine` when this state becomes active. Override in subclasses to set up state-specific visuals and behavior. |
| `exit()` | `() → void` | Called by `CardStateMachine` just before transitioning away from this state. Override to clean up. |
| `on_input(_event)` | `(_event: InputEvent) → void` | Receives forwarded global `_input` events. Override to handle keyboard/mouse input that applies globally (not just to the card's GUI area). |
| `on_gui_input(_event)` | `(_event: InputEvent) → void` | Receives forwarded `_gui_input` events (clicks/motion within the card's bounds). Override to handle card-specific interaction. |
| `on_mouse_entered()` | `() → void` | Called when the cursor enters the card's bounds. Override for hover-in effects. |
| `on_mouse_exited()` | `() → void` | Called when the cursor leaves the card's bounds. Override for hover-out effects. |

---

## 16. `card_base_state.gd` — `scenes/card_ui/card_states/`
**Path:** `res://scenes/card_ui/card_states/card_base_state.gd`  
**Extends:** `CardState`  
**Purpose:** The card's resting state. The card sits in the Hand fan layout, waiting for a left-click.

| Function | Signature | Description |
|---|---|---|
| `enter()` | `() → void` | Awaits `card_ui.ready` if the node isn't ready yet. Emits `reparent_requested` so `Hand` moves the card back to its slot. Sets debug color to green and state label to `"BASE"`. Resets `pivot_offset` to zero. Disables the `drop_point_detector` Area2D. |
| `on_gui_input(event)` | `(event: InputEvent) → void` | On `left_mouse` press: captures the card's current sibling index into `hand_index`, stores `global_position` as `original_position`, and emits `transition_requested` to move to `CLICKED`. |

---

## 17. `card_clicked_state.gd` — `scenes/card_ui/card_states/`
**Path:** `res://scenes/card_ui/card_states/card_clicked_state.gd`  
**Extends:** `CardState`  
**Purpose:** Transient state immediately after a left-click. Waits to see if the player moves the mouse (drag) or right-clicks (cancel).

| Function | Signature | Description |
|---|---|---|
| `enter()` | `() → void` | Sets debug color to orange and state label to `"CLICKED"`. Enables the `drop_point_detector` Area2D. Reparents the card to the `ui_layer` CanvasLayer group so it renders above all other UI elements. |
| `on_input(event)` | `(event: InputEvent) → void` | Any `InputEventMouseMotion` → transitions to `DRAGGING`. `right_mouse` press → transitions to `BASE` (cancel). |

---

## 18. `card_dragging_state.gd` — `scenes/card_ui/card_states/`
**Path:** `res://scenes/card_ui/card_states/card_dragging_state.gd`  
**Extends:** `CardState`  
**Purpose:** Active drag state. The card follows the cursor. A minimum drag time threshold prevents accidental releases.

| Function | Signature | Description |
|---|---|---|
| `enter()` | `() → void` | Sets debug color to navy blue and state label to `"DRAGGING"`. Sets `pivot_offset` to the card's center. Starts a `SceneTreeTimer` for `DRAG_MINIMUM_THRESHOLD` seconds; when it fires, sets `_minimum_drag_time_elapsed = true`. |
| `on_input(event)` | `(event: InputEvent) → void` | `InputEventMouseMotion` → positions the card center under the cursor. `right_mouse` press → transitions to `BASE`. Left mouse button released (after minimum threshold) → marks input as handled and transitions to `RELEASED`. |

---

## 19. `card_released_state.gd` — `scenes/card_ui/card_states/`
**Path:** `res://scenes/card_ui/card_states/card_released_state.gd`  
**Extends:** `CardState`  
**Purpose:** Momentary evaluation state after the mouse button is released. Decides whether the card landed on a valid drop zone.

| Function | Signature | Description |
|---|---|---|
| `enter()` | `() → void` | Sets debug color to dark violet and state label to `"RELEASED"`. Checks `card_ui.targets` (the list of overlapping Area2D bodies from `drop_point_detector`). If not empty → transitions to `SELECTED`. If empty → transitions to `BASE` (card returns to hand). |

---

## 20. `card_selected_state.gd` — `scenes/card_ui/card_states/`
**Path:** `res://scenes/card_ui/card_states/card_selected_state.gd`  
**Extends:** `CardState`  
**Purpose:** The card is placed on the drop zone and awaiting confirmation. A second left-click confirms; right-click cancels.

| Function | Signature | Description |
|---|---|---|
| `enter()` | `() → void` | Sets debug color to gold and state label to `"SELECTED"`. Snaps the card to the center of the drop zone. |
| `on_input(event)` | `(event: InputEvent) → void` | `right_mouse` press → transitions to `BASE`, returning the card to the hand. (Left-click confirmation is handled directly by `CardUI._gui_input()` which calls `_confirm_answer()` when `drag_state == PLACED`.) |

---

*End of reference document.*
