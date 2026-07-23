extends MeshInstance3D

@export var materials : Array[StandardMaterial3D];

func _ready() -> void:
    self.set_surface_override_material(0, materials[randi_range(0, len(materials) - 1)]);
