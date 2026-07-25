extends NinePatchRect

signal input_captured(event : InputEvent);

func _input(event: InputEvent) -> void:
    if (!self.visible):
        return;
    if (event.is_action(&"start")):
        self.visible = false;
        return;
    get_viewport().set_input_as_handled();
    input_captured.emit(event);
