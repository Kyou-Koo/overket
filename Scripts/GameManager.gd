class_name GameManager extends Node

static var _instance : GameManager = null;
static func create_gm() -> GameManager:
    if _instance == null:
        _instance = GameManager.new();
    return _instance;

var savedata : Dictionary;

func set_lang_from_save() -> void:
    TranslationServer.set_locale(savedata["lang"])

func _init() -> void:
    pass;
    
func _ready() -> void:
    # check for existing saved keymap
    savedata = SaveDataMgr.load_savedata();
    set_lang_from_save();
    
