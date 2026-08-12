class_name GarbageCan extends Table

@export var tween_time : float = 0.5
var deletion_tween : Tween;

func public_take_object() -> CarryableObjectBase:
    return;

func public_place_object(obj : CarryableObjectBase) -> bool:
    var placed : bool = super.public_place_object(obj);
    if (placed):
        for c : Node3D in obj.get_children():
            if (c is CollisionShape3D):
                c.disabled = true;
        deletion_tween = get_tree().create_tween().set_parallel(true);
        deletion_tween.set_ease(Tween.EASE_IN);
        deletion_tween.set_trans(Tween.TRANS_QUART);
        deletion_tween.tween_property(obj, "global_position:y", obj.global_position.y - 0.7, tween_time);
        deletion_tween.tween_property(obj, "scale", Vector3(0.1, 0.1, 0.1), tween_time);
        obj.queue_free();
        AudioManager._instance.play_SFX(AudioFiles.TRASH);
        objs_on_top.clear();
    return placed;
