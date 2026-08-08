class_name PauseMenu extends Options

@export var music_button : Button;
@export var sound_button : Button;
@export var close_button : Button;
@export var menu_button : Button;
@export var level : Level;

func activate() -> void:
    self.visible = true;
    self.is_active = true;
    music_button.grab_focus.call_deferred();

func _on_menu_back_pressed() -> void:
    is_active = false;
    self.visible = false;
    AudioManager._instance.fade_all_BGM();
    AudioManager._instance.stop_all_BGM();
    level.clean_up_and_return_to_menu();
    
func _on_close_pressed() -> void:
    is_active = false;
    self.visible = false;
    level.is_paused = false;
    get_viewport().get_tree().paused = false;
    
func _input(ev : InputEvent) -> void:
    if (is_active and !GameManager._instance.in_menu):
        if (ev.is_action_pressed(&"start")):
            get_viewport().set_input_as_handled();
            _on_close_pressed();

func _ready() -> void:
    assert(menu_button != null, "assign return to menu button");
    assert(level != null, "assign level to pause menu");
    if (AudioManager._instance == null): AudioManager.ins();
    is_active = false;
    self.visible = false;
    close_button.pressed.connect(_on_close_pressed);
    menu_button.pressed.connect(_on_menu_back_pressed);
