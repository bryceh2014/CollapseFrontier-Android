extends CharacterBody3D

var game: Node
var team := "Red"
var alive := true
var health := 100
var armed := false
var weapon := "Pistol"
var is_commander := false
var fire_timer := 1.0
var commander_timer := 20.0
var reload_timer := 0.0
var ammo := 12
var downed := false
var bleed_timer := 0.0
var move_timer := 0.0
var target: Node3D
var cover_target := Vector3.ZERO
var speed := 3.2
var body_mesh: MeshInstance3D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	add_to_group("npcs")
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.6
	col.shape = capsule
	add_child(col)
	body_mesh = MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.36
	mesh.height = 1.6
	body_mesh.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.18, 0.16) if team == "Red" else Color(0.15, 0.35, 0.9)
	body_mesh.material_override = mat
	add_child(body_mesh)
	if is_commander:
		health = 160
		speed = 2.7
		weapon = "AK-47"
		armed = true
		add_to_group("commanders")

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if bleed_timer > 0:
		bleed_timer -= delta
		if bleed_timer <= 0:
			_die()
	if downed:
		velocity.x = move_toward(velocity.x, 0, 4 * delta)
		velocity.z = move_toward(velocity.z, 0, 4 * delta)
		move_and_slide()
		return
	fire_timer -= delta
	reload_timer = maxf(0.0, reload_timer - delta)
	commander_timer -= delta
	_find_target()
	if target and is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance > 9.0 or rng.randf() < 0.02:
			# Tactical movement and occasional cover seeking.
			var away := (global_position - target.global_position).normalized()
			cover_target = global_position + away * rng.randf_range(3, 7)
		var desired := target.global_position
		if distance < 7.0:
			desired = cover_target
		var dir := desired - global_position
		dir.y = 0
		if dir.length() > 1.4:
			dir = dir.normalized()
			velocity.x = dir.x * speed
			velocity.z = dir.z * speed
			look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))
		else:
			velocity.x = move_toward(velocity.x, 0, 5 * delta)
			velocity.z = move_toward(velocity.z, 0, 5 * delta)
		if armed and distance < 25 and fire_timer <= 0 and reload_timer <= 0:
			_shoot_at_target()
		if is_commander and commander_timer <= 0:
			_call_reinforcements()
			commander_timer = rng.randf_range(15, 30)
	else:
		velocity.x = move_toward(velocity.x, 0, 3 * delta)
		velocity.z = move_toward(velocity.z, 0, 3 * delta)
	if not is_on_floor():
		velocity.y -= 18 * delta
	move_and_slide()

func _find_target() -> void:
	target = null
	if not game:
		return
	var candidates: Array = game.call("get_hostile_targets", team)
	var best := INF
	for candidate in candidates:
		if not is_instance_valid(candidate):
			continue
		var d := global_position.distance_squared_to(candidate.global_position)
		if d < best:
			best = d
			target = candidate

func _shoot_at_target() -> void:
	if not target or not is_instance_valid(target):
		return
	# Non-rapid-fire weapons use ~1 second between shots; AK is faster.
	fire_timer = 0.16 if weapon == "AK-47" else 1.0
	ammo -= 1
	if ammo <= 0:
		reload_timer = 1.8
		ammo = 30 if weapon == "AK-47" else 12
		return
	if global_position.distance_to(target.global_position) < 18 and rng.randf() < 0.58:
		if target.has_method("take_damage"):
			target.call("take_damage", 8 if weapon == "AK-47" else 12)
		elif target.has_method("get") and target.get("health") != null:
			target.set("health", int(target.get("health")) - 10)

func take_damage(amount: int, body_part: String = "chest") -> void:
	if not alive:
		return
	if body_part == "head":
		_die()
		return
	health -= amount
	if rng.randf() < 0.18:
		bleed_timer = 15.0
		downed = true
	if health <= 0:
		_die()

func _die() -> void:
	if not alive:
		return
	alive = false
	# Simple ragdoll-like collapse placeholder; full articulated ragdoll needs a skeletal rig.
	rotation.z = PI * 0.48
	velocity = Vector3.ZERO
	if armed and rng.randf() < 0.7:
		if game:
			game.call("_spawn_pickup", weapon)
		await get_tree().create_timer(12.0).timeout
	if is_instance_valid(self):
		queue_free()

func _call_reinforcements() -> void:
	if not game:
		return
	var amount := rng.randi_range(2, 4)
	for i in range(amount):
		game.call_deferred("spawn_npc", team)
	# Occasional heavy support: vehicles are a future expansion hook.
	if rng.randf() < 0.08:
		game.call_deferred("_spawn_pickup", "Vehicle Support Flare")
