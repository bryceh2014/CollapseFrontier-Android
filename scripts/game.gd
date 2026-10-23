extends Node3D

const NPC_SCRIPT = preload("res://scripts/npc.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")

var player: CharacterBody3D
var ui: CanvasLayer
var slow_motion := false
var god_mode := true
var all_npcs_armed := false
var player_team := "Blue"
var player_weapons: Array[String] = ["Pistol"]
var extra_weapon_limit := 5
var npc_count := 8
var world_rng := RandomNumberGenerator.new()
var status_label: Label
var death_panel: PanelContainer

func _ready() -> void:
	world_rng.randomize()
	_build_world()
	_spawn_player()
	_build_ui()
	for i in range(npc_count):
		spawn_npc()
	_update_status()

func _build_world() -> void:
	# Original low-poly test arena; no copied game assets.
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.23, 0.29, 0.27)
	var ground_mesh := get_node_or_null("Ground/GroundMesh") as MeshInstance3D
	if ground_mesh:
		ground_mesh.material_override = ground_mat
	for i in range(10):
		var block := StaticBody3D.new()
		block.name = "CoverBlock_%02d" % i
		var x := world_rng.randf_range(-18, 18)
		var z := world_rng.randf_range(-18, 18)
		block.position = Vector3(x, 1.0, z)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(world_rng.randf_range(2, 4), 2, world_rng.randf_range(2, 4))
		shape.shape = box
		block.add_child(shape)
		var mesh := MeshInstance3D.new()
		var boxmesh := BoxMesh.new()
		boxmesh.size = box.size
		mesh.mesh = boxmesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.28, 0.32, 0.36)
		mesh.material_override = mat
		block.add_child(mesh)
		add_child(block)

func _spawn_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 1.1, 6)
	player.set("game", self)
	add_child(player)

func spawn_npc(team_override: String = "") -> void:
	var npc := CharacterBody3D.new()
	npc.name = "NPC_%03d" % get_tree().get_nodes_in_group("npcs").size()
	npc.set_script(NPC_SCRIPT)
	var team := team_override
	if team == "":
		team = "Red" if world_rng.randf() < 0.5 else "Blue"
	npc.set("team", team)
	npc.set("game", self)
	npc.position = Vector3(world_rng.randf_range(-15, 15), 1.1, world_rng.randf_range(-15, 15))
	npc.set("is_commander", world_rng.randf() < 0.07)
	add_child(npc)

func get_hostile_targets(for_team: String) -> Array:
	var targets: Array = []
	if player and is_instance_valid(player) and not player.get("dead") and not god_mode and player_team != for_team:
		targets.append(player)
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.get("alive") and npc.get("team") != for_team:
			targets.append(npc)
	return targets

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)

	var top := HBoxContainer.new()
	top.position = Vector2(16, 12)
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	status_label = Label.new()
	status_label.custom_minimum_size = Vector2(280, 32)
	top.add_child(status_label)
	_add_button(top, "SLOW-MO", _toggle_slowmo)
	_add_button(top, "GOD MODE", _toggle_god)
	_add_button(top, "TEAM: " + player_team, _cycle_team)
	_add_button(top, "ARM NPCs", _toggle_arm_all)
	_add_button(top, "SPAWN NPC", func(): spawn_npc())
	_add_button(top, "SPAWN AK", func(): _spawn_pickup("AK-47"))

	var controls := Label.new()
	controls.text = "MOVE: WASD / left stick     LOOK: mouse / right drag     FIRE: click / FIRE button     PICK UP: E"
	controls.position = Vector2(18, 680)
	controls.add_theme_font_size_override("font_size", 15)
	root.add_child(controls)

	death_panel = PanelContainer.new()
	death_panel.position = Vector2(430, 230)
	death_panel.size = Vector2(420, 210)
	death_panel.visible = false
	root.add_child(death_panel)
	var death_col := VBoxContainer.new()
	death_panel.add_child(death_col)
	var title := Label.new()
	title.text = "YOU DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	death_col.add_child(title)
	var respawn := Button.new()
	respawn.text = "RESPAWN HERE"
	respawn.pressed.connect(_respawn_player)
	death_col.add_child(respawn)

func _add_button(parent: Node, caption: String, action: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(100, 38)
	b.pressed.connect(action)
	parent.add_child(b)

func _toggle_slowmo() -> void:
	slow_motion = not slow_motion
	Engine.time_scale = 0.25 if slow_motion else 1.0
	_update_status()

func _toggle_god() -> void:
	god_mode = not god_mode
	if player:
		player.set("god_mode", god_mode)
	_update_status()

func _cycle_team() -> void:
	player_team = "Red" if player_team == "Blue" else "Blue"
	if player:
		player.set("team", player_team)
	_update_status()

func _toggle_arm_all() -> void:
	all_npcs_armed = not all_npcs_armed
	for npc in get_tree().get_nodes_in_group("npcs"):
		npc.set("armed", all_npcs_armed)
	_update_status()

func _spawn_pickup(weapon_name: String) -> void:
	var pickup := Area3D.new()
	pickup.name = "Pickup_" + weapon_name
	pickup.set_script(load("res://scripts/pickup.gd"))
	pickup.set("weapon_name", weapon_name)
	pickup.position = player.global_position + -player.global_transform.basis.z * 2.0 + Vector3(0, 0.5, 0)
	add_child(pickup)

func _respawn_player() -> void:
	if player:
		player.global_position = player.get("death_position")
		player.set("health", 100)
		player.set("dead", false)
		player.set("immunity_left", 5.0)
		player.visible = true
		player.set_physics_process(true)
	death_panel.visible = false

func player_died() -> void:
	death_panel.visible = true

func _update_status() -> void:
	if status_label:
		status_label.text = "HP sandbox | Team: %s | God: %s | Slow: %s | NPCs: %d" % [
			player_team, str(god_mode), str(slow_motion), get_tree().get_nodes_in_group("npcs").size()
		]
