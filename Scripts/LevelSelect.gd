class_name LevelSelect extends Control

func _input(event: InputEvent) -> void:
    if (event.is_pressed()):
        if (event.is_action(&"start")):
            print(event.as_text());
