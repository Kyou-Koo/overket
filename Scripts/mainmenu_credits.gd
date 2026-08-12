extends Label

@onready var start_y : float = 0.0;
@onready var height : float = size.y;
var scroll_rate : float = 0.3;

func _process(delta: float) -> void:
    if (GameManager._instance and GameManager._instance.in_menu and 
    GameManager._instance.active_menu == GameManager.MENU.OPTIONS):
        position = position + Vector2(0, -scroll_rate);
        if (abs(position.y) > height):
            position = Vector2(0, start_y);
