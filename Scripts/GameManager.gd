class_name GameManager extends Node

static var _instance : GameManager = null;
#static func create_gm() -> GameManager:
    #if _instance == null:
        #_instance = GameManager.new();
    #return _instance;

var savedata : Dictionary;

enum MENU {
    MAIN,
    LEVEL,
    OPTIONS,
}

@export_group("Main Menu", "main_")
@export var main_menu_scene_path : String;
@export var main_menu_node_parent : SubViewport;
@export var main_camera : Camera3D;
@export var main_cam_origin_pos : Vector3;
@export var main_cam_origin_rot : Vector3;
var main_menu_scene : PackedScene;
var main_menu : Node;
@export_group("Level", "level")
@export var level_scene_path : String;
@export var level_node_parent : SubViewport;
@export var level_cam_pos : Vector3;
@export var level_cam_rot : Vector3;
var level_scene : PackedScene;
var level : Node;
@export_group("Options", "options")
@export var options_scene_path : String;
@export var options_node_parent : SubViewport;
@export var options_cam_pos : Vector3;
@export var options_cam_rot : Vector3;
var options_scene : PackedScene;
var options : Options;
@export var transition_time : float = 0.75;
@export var sprite : Sprite3D;

var active_menu : MENU;
var sprite_tween : Tween;
var sprite_init_pos : Vector3;
var sprite_init_rot : Vector3;

signal transition_to(who : Node);

func public_rotate_camera(to : Vector3, new_menu : MENU, rate : float = transition_time) -> void:
    active_menu = new_menu;
    var tween : Tween = get_tree().create_tween();
    tween.set_trans(Tween.TRANS_CUBIC);
    tween.set_ease(Tween.EASE_IN_OUT);
    tween.tween_property(main_camera, "rotation_degrees", to, rate)
    var next_menu : Node;
    match new_menu:
        MENU.MAIN:
            next_menu = main_menu;
        MENU.LEVEL:
            next_menu = level;
        MENU.OPTIONS:
            next_menu = options;
    transition_to.emit(next_menu);

func set_lang_from_save() -> void:
    TranslationServer.set_locale(_instance.savedata["lang"])

func _notification(what: int) -> void:
    if (what == NOTIFICATION_WM_CLOSE_REQUEST):
        SaveDataMgr.write_savedata(_instance.savedata, SaveDataMgr.savedata_filepath, SaveDataMgr.SAVEDATA.Save)

func instantiate_menus() -> void:
    if (level_scene_path != ""):
        level_scene = load(level_scene_path);
        level = level_scene.instantiate();
        level_node_parent.add_child(level);
    if (options_scene_path != ""):
        options_scene = load(options_scene_path);
        options = options_scene.instantiate();
        options_node_parent.add_child(options);
    if (main_menu_scene_path != ""):
        main_menu_scene = load(main_menu_scene_path);
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
            sprite_tween.tween_property(sprite, "position", sprite_init_pos + Vector3.UP * randf_range(0.2, 0.5), 0.2);
            sprite_tween.set_trans(Tween.TRANS_BOUNCE);
            sprite_tween.tween_property(sprite, "position", sprite_init_pos, 0.5);
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

func _init() -> void:
    pass;
    
func _ready() -> void:
    _instance = self;
    # check for existing saved keymap
    SaveDataMgr.load_keymap();
    _instance.savedata = SaveDataMgr.load_savedata();
    set_lang_from_save();

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

    #TESTINGTESTINGETESTING
