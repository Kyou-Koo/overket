extends Control

@export var play_button : Button;
@export var options_button : Button;
@export var quit_button : Button;
@export var level_select : Node; #TODO: write
@export var options_menu : Options;
# should probably tri
var is_active : bool = true;

func _on_menu_transition(who : Node) -> void:
    if (who == self):
        is_active = true;
    else:
        is_active = false;

func _on_play_pressed() -> void:
    # move to level select
    if (is_active):
        pass
    
func _on_opt_pressed() -> void:
    # move to opt menu
    if (is_active):
        GameManager._instance.public_rotate_camera(
            GameManager._instance.options_cam_rot, 
            GameManager.MENU.OPTIONS);
        

func _on_quit_pressed() -> void:
    get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST);
    get_tree().quit();

func _ready() -> void:
    assert(play_button != null, "Play button not assigned");
    assert(options_button != null, "Options button not assigned");
    assert(quit_button != null, "Quit button not assigned");
    
    play_button.pressed.connect(_on_play_pressed);
    options_button.pressed.connect(_on_opt_pressed);
    quit_button.pressed.connect(_on_quit_pressed);

    GameManager._instance.transition_to.connect(_on_menu_transition);
    
    play_button.grab_focus.call_deferred();
