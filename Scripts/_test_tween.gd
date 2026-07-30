extends Node3D

@export var active_sprite : Sprite3D;
var bounce_tween : Tween;
var mid_bounce : bool = false;
var dict : Dictionary[String, Vector3] = {
    "a": Vector3.ZERO,
    "b": Vector3.FORWARD,
}

func bounce_animation() -> void:
    if (mid_bounce):  return;
    mid_bounce = true;
    bounce_tween = get_tree().create_tween().set_parallel();
    bounce_tween.set_ease(Tween.EASE_OUT);
    bounce_tween.set_trans(Tween.TRANS_QUAD);
    bounce_tween.tween_property(active_sprite, "position:y", 0.5, 0.5);
    #bounce_tween = get_tree().create_tween()
    bounce_tween.chain().set_ease(Tween.EASE_IN);
    bounce_tween.chain().set_trans(Tween.TRANS_QUAD);
    bounce_tween.chain().tween_property(active_sprite, "position:y", 0.0, 0.5);
    bounce_tween.chain().tween_callback(_on_bounce_done);
    
func _process(delta: float) -> void:
    bounce_animation();
    
var _on_bounce_done : Callable = func() -> void:
    mid_bounce = false;

func _ready() -> void:
    print(dict[Statics.rand_from_arr_v(dict.keys())])
    # DEBUG:
    get_window().content_scale_factor = 0.67;
    get_window().position = Vector2i(100, 100);
    get_viewport().get_window().content_scale_size = Vector2i(1280,720);
    get_viewport().get_window().size = Vector2i(1280, 720);
