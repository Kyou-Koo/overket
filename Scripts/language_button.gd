extends Button

@export var parent_control : Control;

func _ready() -> void:
    if (parent_control == null):
        # naive search
        parent_control = self.get_parent();
