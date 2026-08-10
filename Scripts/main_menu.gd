extends Control

@export var play_button : Button;
@export var options_button : Button;
@export var quit_button : Button;
@export var fullscreen_check : CheckButton;
@export var fullscreen_focus : NinePatchRect;
@export var resolution_label : Label;
@export var resolution_focus : NinePatchRect;
@export var resolution_disabled : NinePatchRect;
var resolution_focused : bool = false;
var resolution : SaveDataMgr.Resolution;
const RES_1280 : String = "1280x720 >";
const RES_1920 : String = "< 1920x1080";
# TODO: i dont think these are actually used
var level_select : LevelSelect;
var options_menu : Options;
var is_active : bool = true;

func _on_menu_transition(who : Node) -> void:
    if (who == self):
        is_active = true;
        play_button.grab_focus.call_deferred();
    else:
        is_active = false;

func _on_play_pressed() -> void:
    # move to level select
    if (is_active):
        GameManager._instance.public_rotate_camera(
            GameManager._instance.level_cam_rot,
            GameManager.MENU.LEVEL);
    
func _on_opt_pressed() -> void:
    # move to opt menu
    if (is_active):
        GameManager._instance.public_rotate_camera(
            GameManager._instance.options_cam_rot, 
            GameManager.MENU.OPTIONS);

func _on_quit_pressed() -> void:
    get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST);
    get_tree().quit();
    
func _on_fs_focus_entered() -> void: fullscreen_focus.visible = true;
func _on_fs_focus_exited() -> void: fullscreen_focus.visible = false;
func _on_fs_toggled(state : bool) -> void:
    AudioManager._instance.play_SFX(AudioFiles.MENU_ACTION);
    if (state):
        GameManager._instance.set_res_1920();
        get_viewport().get_window().mode = Window.MODE_FULLSCREEN;
        var screen : Vector2 = DisplayServer.screen_get_size();
        var ratio : float = 0.0;
        if (screen.x / screen.y > 16.0/9.0):
            ratio = screen.y / 1080.0;
        else:
            ratio = screen.x / 1920.0;
        get_window().content_scale_factor = ratio;
        SaveDataMgr.set_fs_mode(true);
        resolution_disabled.visible = true;
        resolution_label.focus_mode = Control.FOCUS_NONE;
    else:
        get_viewport().get_window().mode = Window.MODE_WINDOWED;
        SaveDataMgr.set_fs_mode(false);
        set_resolution_text_and_res();
        resolution_disabled.visible = false;
        resolution_label.focus_mode = Control.FOCUS_ALL;
func _on_res_focus_entered() -> void:
    resolution_focus.visible = true;
    resolution_focused = true;
func _on_res_focus_exited() -> void:
    resolution_focus.visible = false;
    resolution_focused = false;
    
func _input(ev: InputEvent) -> void:
    if (resolution_focused and is_active and
    !SaveDataMgr.get_fs_mode_is_fs()):
        if (ev.is_action_pressed(&"ui_left") and resolution == SaveDataMgr.Resolution.BIG):
            get_viewport().set_input_as_handled();
            resolution = SaveDataMgr.Resolution.SMALL;
            set_resolution_text_and_res();
            SaveDataMgr.set_resolution_enum(SaveDataMgr.Resolution.SMALL);
        elif (ev.is_action_pressed(&"ui_right") and resolution == SaveDataMgr.Resolution.SMALL):
            get_viewport().set_input_as_handled();
            resolution = SaveDataMgr.Resolution.BIG;
            set_resolution_text_and_res();
            SaveDataMgr.set_resolution_enum(SaveDataMgr.Resolution.BIG);
            
func set_resolution_text_and_res() -> void:
    if (!GameManager._instance): GameManager.create_gm();
    if (resolution == SaveDataMgr.Resolution.SMALL):
        resolution_label.text = RES_1280;
        GameManager._instance.set_res_1280();
    else:
        resolution_label.text = RES_1920;
        GameManager._instance.set_res_1920();
    get_viewport().get_window().move_to_center();

func _ready() -> void:
    assert(play_button != null, "Play button not assigned");
    assert(options_button != null, "Options button not assigned");
    assert(quit_button != null, "Quit button not assigned");
    assert(fullscreen_check != null, "FS button not assigned");
    assert(fullscreen_focus != null, "FS focus not assigned");
    assert(resolution_label != null, "Resolution label not assigned");
    assert(resolution_focus != null, "Resolution focus not assigned");
    assert(resolution_disabled != null, "Res disabled not assigned");
    
    if (!SaveDataMgr._instance):
        SaveDataMgr.create_sdm();
    fullscreen_check.button_pressed = SaveDataMgr.get_fs_mode_is_fs();
    resolution = SaveDataMgr.get_resolution_enum();
    set_resolution_text_and_res();
    
    play_button.pressed.connect(_on_play_pressed);
    options_button.pressed.connect(_on_opt_pressed);
    quit_button.pressed.connect(_on_quit_pressed);
    fullscreen_focus.visible = false;
    resolution_focus.visible = false;
    resolution_disabled.visible = false;
    fullscreen_check.focus_entered.connect(_on_fs_focus_entered);
    fullscreen_check.focus_exited.connect(_on_fs_focus_exited);
    fullscreen_check.toggled.connect(_on_fs_toggled);
    resolution_label.focus_entered.connect(_on_res_focus_entered);
    resolution_label.focus_exited.connect(_on_res_focus_exited);
    GameManager._instance.transition_to.connect(_on_menu_transition);
    
    play_button.grab_focus.call_deferred();
