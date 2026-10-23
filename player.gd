extends CharacterBody3D

var game: Node
var team := "Blue"
var health := 100
var dead := false
var god_mode := true
var immunity_left := 0.0
var death_position := Vector3.ZERO
var speed := 7.0
var fly_mode := true
var fire_cooldown := 0.0
var weapon := "Pistol"
var ammo := 12
var extra_weapons: Array[String] = []
var look_yaw := 0.0
var look_pitch := -0.12
var camera: Camera3D

func _ready() -> void:
	add_to_group("player")
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	col.shape = capsule
	add_child(col)
	var mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.38
	body.height = 1.7
	mesh.mesh = body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.55, 1.0)
	mesh.material_override = mat
	add_child(mesh)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.55, 0)
	camera.current = true
	add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look_yaw -= event.relative.x * 0.0025
		look_pitch = clamp(look_pitch - event.relative.y * 0.0025, -1.2, 1.1)
		rotation.y = look_yaw
		camera.rotation.x = look_pitch
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_E:
			_try_pickup()
		elif event.keycode == KEY_F:
			fly_mode = not fly_mode
		elif event.keycode == KEY_SPACE:
			if fly_mode:
				velocity.y = 5.0
			elif is_on_floor():
				velocity.y = 5.0
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		fire()

func _physics_process(delta: float) -> void:
	if dead:
		return
	immunity_left = maxf(0.0, immunity_left - delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	var input_vec := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if Input.is_key_pressed(KEY_A): input_vec.x -= 1
	if Input.is_key_pressed(KEY_D): input_vec.x += 1
	if Input.is_key_pressed(KEY_W): input_vec.y -= 1
	if Input.is_key_pressed(KEY_S): input_vec.y += 1
	input_vec = input_vec.normalized()
	var direction := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if fly_mode and god_mode:
		velocity.y = (float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_SHIFT))) * speed
	else:
		if not is_on_floor():
			velocity.y -= 18.0 * delta
	move_and_slide()

func fire() -> void:
	if dead or fire_cooldown > 0:
		return
	fire_cooldown = 0.12 if weapon == "AK-47" else 0.35
	var origin := camera.global_position
	var end := origin + -camera.global_transform.basis.z * 100.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider:
		if hit.collider.is_in_group("npcs"):
			hit.collider.call("take_damage", 35 if weapon == "AK-47" else 25, "chest")
		elif hit.collider.has_method("apply_central_impulse"):
			hit.collider.apply_central_impulse(-camera.global_transform.basis.z * 8.0)

func take_damage(amount: int) -> void:
	if god_mode or immunity_left > 0 or dead:
		return
	health -= amount
	if health <= 0:
		dead = true
		death_position = global_position
		visible = false
		set_physics_process(false)
		if game:
			game.call("player_died")

func _try_pickup() -> void:
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin + -camera.global_transform.basis.z * 3.0)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider and hit.collider.is_in_group("weapon_pickups"):
		var w: String = hit.collider.get("weapon_name")
		if w == weapon or extra_weapons.size() < 5:
			if w != weapon and not extra_weapons.has(w):
				extra_weapons.append(w)
			weapon = w
			hit.collider.queue_free()
