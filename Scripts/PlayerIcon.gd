class_name PlayerIcon extends Control

@export var sprite_color : Color;
@export var sprite_head_container : Control;
var sprite_heads : Array[TextureRect];
@export var sprite_to_faces_container : Control;
var sprite_to_faces : Array[TextureRect];
@export var sprite_body : TextureRect;

func set_up_sprite_arrays(container : Control, array : Array) -> void:
    for s3d : TextureRect in container.get_children():
        array.append(s3d);
        s3d.visible = false;

func instance(face : int, head: int, color : Color) -> void:
    sprite_heads[head].visible = true;
    sprite_to_faces[face].visible = true;
    sprite_color = color;
    for f : TextureRect in sprite_to_faces:
        f.visible = false;
    for f : TextureRect in sprite_heads:
        f.modulate = sprite_color;
    sprite_body.modulate = sprite_color;

func _ready() -> void:
    set_up_sprite_arrays(sprite_head_container, sprite_heads);
    set_up_sprite_arrays(sprite_to_faces_container, sprite_to_faces);
