class_name PauseMenu extends Options

@export var music_button : Button;
@export var sound_button : Button;
@export var close_button : Button;
@export var menu_button : Button;

func activate() -> void:
    self.visible = true;
    is_active = true;
    # center
    var screen_size : Vector2i;
    if (SaveDataMgr.get_fs_mode_is_fs()):
        screen_size = DisplayServer.screen_get_size();
    else:
        screen_size = SaveDataMgr.get_resolution();
    var x_pos : int = (screen_size.x - self.size.x) / 2;
    var y_pos : int = (screen_size.y - self.size.y) / 2; # maybe shove it down a bit
    self.position = Vector2i(x_pos, y_pos);
    music_button.grab_focus.call_deferred();

func _on_menu_back_pressed() -> void:
    is_active = false;
    self.visible = false;
    # TODO: more
    
func _on_close_pressed() -> void:
    is_active = false;
    self.visible = false;
    # TODO: more
    
func _input(ev : InputEvent) -> void:
    if (is_active): #and !GameManager._instance.in_menu):
        if (ev.is_action_pressed(&"start")):
            get_viewport().set_input_as_handled();
            _on_close_pressed();

func _ready() -> void:
    assert(menu_button != null, "assign return to menu button");
    if (AudioManager._instance == null): AudioManager.ins();
    is_active = false;
    
    close_button.pressed.connect(_on_close_pressed);
    menu_button.pressed.connect(_on_menu_back_pressed);
    activate()
