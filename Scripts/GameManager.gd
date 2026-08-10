class_name GameManager extends Node

static var _instance : GameManager = null;
static func create_gm() -> void:
    if _instance == null:
        _instance = GameManager.new();

enum MENU {
    MAIN,
    LEVEL,
    OPTIONS,
}

@export_group("Main Menu", "main_")
@export var main_menu_node_parent : SubViewport;
@export var main_camera : Camera3D;
@export var main_cam_origin_pos : Vector3;
@export var main_cam_origin_rot : Vector3;
var main_menu_scene : PackedScene;
var main_menu : Control;
@export_group("Level", "level")
@export var level_node_parent : SubViewport;
@export var level_cam_pos : Vector3;
@export var level_cam_rot : Vector3;
var level_scene : PackedScene;
var level : LevelSelect;
var level_level_res : Array[PackedScene];
var level_level_active : Level;
@export_group("Options", "options")
@export var options_node_parent : SubViewport;
@export var options_cam_pos : Vector3;
@export var options_cam_rot : Vector3;
var options_scene : PackedScene;
var options : Options;
@export var transition_time : float = 0.75;
@export var sprite : Sprite3D;

# TODO: how are we assigning this
var num_players : int;
var active_players : Array[bool] = [false, false, false, false]
var player_colors : Array[Color] = [Color.BLACK, Color.BLACK, Color.BLACK, Color.BLACK];
var player_head_face_base : Array[Array] = [[-1, -1],[-1, -1],[-1, -1],[-1, -1]]
var player_head_face : Array[Array] = [[-1, -1],[-1, -1],[-1, -1],[-1, -1]]

var in_menu : bool = true;
var bgm_started : bool = false;
var active_menu : MENU;
var sprite_tween : Tween;
var sprite_init_pos : Vector3;
var sprite_init_rot : Vector3;

signal transition_to(who : Node);

func public_rotate_camera(to : Vector3, new_menu : MENU, rate : float = transition_time, ignore_audio : bool = false) -> void:
    active_menu = new_menu;
    var tween : Tween = get_tree().create_tween();
    tween.set_trans(Tween.TRANS_CUBIC);
    tween.set_ease(Tween.EASE_IN_OUT);
    tween.tween_property(main_camera, "rotation_degrees", to, rate)
    var next_menu : Control;
    match new_menu:
        MENU.MAIN:
            next_menu = main_menu;
        MENU.LEVEL:
            next_menu = level;
        MENU.OPTIONS:
            next_menu = options;
    transition_to.emit(next_menu);
    if (ignore_audio): AudioManager._instance.play_SFX(AudioFiles.MENU_CONFIRM);
    
func start_level(lv_idx : int) -> void:
    if (is_instance_valid(level_level_active)):
        Statics.raise_warning("attempting to load a level while in a level dont do this");
        return;
    in_menu = false;
    main_camera.current = false;
    # idk just hide everything lmao
    $"MainAreaContents".visible = false;
    level_level_active = level_level_res[lv_idx].instantiate();
    self.add_child(level_level_active);
    level_level_active.set_up();
    level_level_active.position = Vector3.ZERO;

func reset_players() -> void:
    for i in range(3):
        level.unassign_head_face_color(i);
        level.player_portraits[i].visible = false;
    player_head_face = player_head_face_base.duplicate();
    
func end_level() -> void:
    main_camera.make_current();
    level_level_active.camera.current = false;
    $"MainAreaContents".visible = true;
    public_rotate_camera(level_cam_rot, MENU.LEVEL, 0.01, true);
    level_level_active.queue_free();
    reset_players();
    level.init_level_select();
    AudioManager._instance.play_BGM(AudioFiles.MENU_KEY, AudioFiles.MENU_BGM, AudioFiles.MENU_BGM);
    in_menu = true;

func set_lang_from_save() -> void:
    TranslationServer.set_locale(SaveDataMgr.get_lang());

func _notification(what: int) -> void:
    if (what == NOTIFICATION_WM_CLOSE_REQUEST):
        SaveDataMgr.write_savedata(SaveDataMgr._instance.savedata, SaveDataMgr.savedata_filepath, SaveDataMgr.SAVEDATA.Save)

func instantiate_menus() -> void:
    level_scene = preload("res://Resources/LevelSelect.tscn");
    level = level_scene.instantiate();
    level_node_parent.add_child(level);
    options_scene = preload("res://Resources/Options.tscn");
    options = options_scene.instantiate();
    options_node_parent.add_child(options);
    main_menu_scene = preload("res://Resources/MainMenu.tscn");
    main_menu = main_menu_scene.instantiate();
    main_menu.level_select = level;
    main_menu.options_menu = options;
    main_menu_node_parent.add_child(main_menu);

func sprite_actions() -> void:
    var rand_int : int = randi_range(0, 5);
    #Statics.debug_log("sprite action firing {0}".format([rand_int]));
    if (sprite_tween and sprite_tween.is_running()):
        return;
    match rand_int:
        # bounce
        0:
            sprite_tween = get_tree().create_tween();
            sprite_tween.set_ease(Tween.EASE_OUT);
            sprite_tween.set_trans(Tween.TRANS_QUAD);
            sprite_tween.tween_property(sprite, "position:y", sprite_init_pos.y + randf_range(0.2, 0.5), 0.2);
            sprite_tween.set_trans(Tween.TRANS_BOUNCE);
            sprite_tween.tween_property(sprite, "position:y", sprite_init_pos.y, 0.5);
        # wiggle Y axis
        1:
            sprite_tween = get_tree().create_tween();
            sprite_tween.set_ease(Tween.EASE_OUT);
            sprite_tween.set_trans(Tween.TRANS_BOUNCE);
            var new_rot : Vector3 = Vector3(0.0, randf_range(-30, 30), 0.0);
            sprite_tween.tween_property(sprite, "rotation_degrees", sprite_init_rot + new_rot, 0.2);
            sprite_tween.set_trans(Tween.TRANS_BOUNCE);
            sprite_tween.tween_property(sprite, "rotation_degrees", sprite_init_rot, 0.5);
        # wiggle Z axis
        2:
            sprite_tween = get_tree().create_tween();
            sprite_tween.set_ease(Tween.EASE_OUT);
            sprite_tween.set_trans(Tween.TRANS_BOUNCE);
            var new_rot : Vector3 = Vector3(0.0, 0.0, randf_range(-30, 30));
            sprite_tween.tween_property(sprite, "rotation_degrees", sprite_init_rot + new_rot, 0.2);
            sprite_tween.set_trans(Tween.TRANS_BOUNCE);
            sprite_tween.tween_property(sprite, "rotation_degrees", sprite_init_rot, 0.5);
        _:
            pass;
            
func set_res_1280() -> void:
    get_window().content_scale_factor = 0.67;
    get_viewport().get_window().content_scale_size = SaveDataMgr.RES_SMALL;
    get_viewport().get_window().size = SaveDataMgr.RES_SMALL;
    
func set_res_1920() -> void:
    get_window().content_scale_factor = 1.0;
    get_viewport().get_window().content_scale_size = SaveDataMgr.RES_BIG;
    get_viewport().get_window().size = SaveDataMgr.RES_BIG;

func _input(ev: InputEvent) -> void:
    match active_menu:
        MENU.MAIN:
            if (ev.is_pressed()):
                sprite_actions();
            main_menu_node_parent.push_input(ev);
        MENU.LEVEL:
            level_node_parent.push_input(ev);
        MENU.OPTIONS:
            options_node_parent.push_input(ev);
    if (in_menu):
        if (ev.is_pressed() and (ev.is_action(&"ui_left") or 
        ev.is_action(&"ui_right") or ev.is_action(&"ui_up") or ev.is_action(&"ui_down"))):
            AudioManager._instance.play_SFX(AudioFiles.MENU_MOVE);
            
func _process(delta: float) -> void:
    if (Time.get_ticks_msec() > 100 and !bgm_started):
        bgm_started = true;
        AudioManager._instance.play_BGM(AudioFiles.MENU_KEY, AudioFiles.MENU_BGM, AudioFiles.MENU_BGM);

func _init() -> void:
    SaveDataMgr.create_sdm();
    AudioFiles.instantiate();
    
func _ready() -> void:
    _instance = self;
    AudioManager.ins().addNodeToTree(get_tree());
    # check for existing saved keymap
    SaveDataMgr.load_keymap();
    SaveDataMgr.load_savedata();
    var player_regex : RegEx = RegEx.create_from_string("p[1-4]");
    for inp in InputMap.get_actions():
        if player_regex.search(inp):
            Statics.debug_log("act: {0} event: {1}".format([
                inp,
                str(InputMap.action_get_events(inp))
                ]));
    set_lang_from_save();
    get_viewport().get_window().move_to_center();
    var window_size_enum : SaveDataMgr.Resolution = SaveDataMgr.get_resolution_enum();
    if (window_size_enum == SaveDataMgr.Resolution.SMALL):
        set_res_1280();
    else:
        set_res_1920();

    if (main_camera == null):
        var children : Array[Node] = get_children();
        for c : Node in children:
            if (c is Camera3D):
                main_camera = c;
    assert(main_camera != null, "Camera must exist in scene");
    main_camera.position = main_cam_origin_pos;
    main_camera.rotation = main_cam_origin_rot;
    instantiate_menus();

    active_menu = MENU.MAIN;
    if (sprite != null):
        sprite_init_pos = sprite.position;
        sprite_init_rot = sprite.rotation_degrees;

    level_level_res.append(preload("res://Resources/Level1.tscn"));
    level_level_res.append(preload("res://Resources/Level2.tscn"));
    level_level_res.append(preload("res://Resources/Level3.tscn"));
    level_level_res.append(preload("res://Resources/Level4.tscn"));
    #TESTINGTESTINGETESTING
    for d_idx in Input.get_connected_joypads():
        # print("ahhhh stop idiot")
        Input.stop_joy_vibration(d_idx);
