extends Area3D

var weapon_name := "AK-47"

func _ready() -> void:
	add_to_group("weapon_pickups")
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.45
	collision.shape = shape
	add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.18, 0.12)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.16)
	mesh.material_override = mat
	add_child(mesh)
