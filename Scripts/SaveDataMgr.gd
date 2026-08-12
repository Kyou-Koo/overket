class_name SaveDataMgr

static var _instance : SaveDataMgr;
static func create_sdm() -> SaveDataMgr:
    if _instance == null:
        _instance = SaveDataMgr.new();
        load_savedata();
    return _instance;

var savedata : Dictionary;

const keybind_filepath : String = "user://keybind_save.json"
const savedata_filepath : String = "user://save.dat"
const keybind_defaults : String = "user://keybind_default.dat"
const pwd : String = "whyyesthisisAP4$$W0rdfortheGaMeWhYArEYoUR3aD1nG!!!"

# defaults
const SAVE_VERSION : int = 15;
const LANG : String = "ja";
const MUSIC_VOLUME : int = 5;
const SFX_VOLUME : int = 5;
const HIGHSCORE : Array[int] = [0, 0, 0, 0];
const IS_FULLSCREEN : bool = false;
const RESOLUTION : Resolution = Resolution.SMALL;
const RES_SMALL : Vector2i = Vector2i(1280, 720);
const RES_BIG : Vector2i = Vector2i(1920, 1080);
enum Resolution {
    SMALL,  # Vector2i(1280, 720)
    BIG     # Vector2i(1920, 1080)
}

enum SAVEDATA {
    Keybind,
    Save,
}

enum FIELD {
    LANGUAGE,
    MUSIC,
    SOUND,
    HISCORE,
}

static var blank : Dictionary = {
    "version": SAVE_VERSION,
    "lang": "",
    "music": MUSIC_VOLUME,
    "sound": SFX_VOLUME,
    "highscore": HIGHSCORE,
    "last_open_date": Time.get_datetime_string_from_system(true, false),
    "is_fs": IS_FULLSCREEN,
    "resolution": Resolution.SMALL,
}

static func get_lang() -> String:
    return _instance.savedata["lang"];
static func set_lang(lang : String) -> void:
    _instance.savedata["lang"] = lang;
    
static func get_music() -> int:
    return _instance.savedata["music"];
static func set_music(v : int) -> void:
    _instance.savedata["music"] = v;

static func get_sound() -> int:
    return _instance.savedata["sound"];
static func set_sound(v : int) -> void:
    _instance.savedata["sound"] = v;

static func get_highscores() -> Array[int]:
    var out_arr : Array[int];
    for score : Variant in _instance.savedata["highscore"]:
        out_arr.append(score as int);
    return out_arr;
static func set_highscore(score : int, lvl : int) -> void:
    Statics.debug_log("score {0} set for {1}".format([score, lvl]));
    if (lvl >= 0 and lvl < 4):
        _instance.savedata["highscore"][lvl] = score;
    else:
        Statics.raise_warning("Attempting to set score for invalid level");
    
static func get_fs_mode_is_fs() -> bool:
    return _instance.savedata["is_fs"];
static func set_fs_mode(is_fs : bool) -> void:
    _instance.savedata["is_fs"] = is_fs;
    
static func get_resolution() -> Vector2i:
    if (_instance.savedata["resolution"] == Resolution.SMALL):
        return Vector2i(1280, 720);
    else:
        return Vector2i(1920, 1080);
static func set_resolution_vec2i(res : Vector2i) -> void:
    if (res == Vector2i(1280, 720)):
        _instance.savedata["resolution"] = Resolution.SMALL;
    else:
        _instance.savedata["resolution"] = Resolution.BIG;
static func get_resolution_enum() -> Resolution:
    return _instance.savedata["resolution"];
static func set_resolution_enum(res : Resolution) -> void:
    _instance.savedata["resolution"] = res;


# TODO_LATER: probably depreciated (minus hiscore)
static func update_savefield(new_data : Variant, field : FIELD, curr_data : Dictionary) -> Dictionary:
    var new_data_dict : Dictionary;
    # TODO_LATER: maybe typecheck new data
    match field:
        FIELD.LANGUAGE:
            new_data_dict["lang"] = new_data;
        FIELD.MUSIC:
            new_data_dict["music"] = new_data;
        FIELD.SOUND:
            new_data_dict["sound"] = new_data;
        FIELD.HISCORE:
            # TODO_LATER: some array merging?
            new_data_dict["highscore"] = new_data;
    curr_data.merge(new_data_dict, true);
    Statics.debug_log("updated save from field: {0}".format([str(curr_data)]));
    return curr_data;

static func update_savedata(new_data : Dictionary, curr_data : Dictionary) -> Dictionary:
    curr_data.merge(new_data, true);
    Statics.debug_log("updated save from merge: {0}".format([str(curr_data)]));
    return curr_data;

static func create_new_savedata() -> Dictionary:
    var lang : String = OS.get_locale_language();
    Statics.debug_log("detected language: {0}".format([lang]));
    if not lang in ["en", "ja"]:
        lang = LANG;
    return blank;

static func write_savedata(data : Variant, path : String, type : SAVEDATA) -> void:
    Statics.debug_log("writing savedata to {0}".format([path]));
    if (not path.begins_with("user://")):
        Statics.raise_warning("Attempting to output to an invalid path: {0}".format([path]));
        return;
    
    var out_file : FileAccess;
    #Statics.debug_log("outgoing data {0}".format([str(data)]));
    match type:
        SAVEDATA.Keybind:
            out_file = FileAccess.open(path, FileAccess.WRITE);
        SAVEDATA.Save:
            out_file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, pwd);
            #data["version"] = SAVE_VERSION; # HACK just shove this in here at all times
    var out_jstr : String = JSON.stringify(data);
    #Statics.debug_log("outgoing save: {0}".format([out_jstr]));
    var succ: bool = out_file.store_line(out_jstr);
    if (!succ): 
        Statics.raise_warning("Failed to store to file {0} | {1}".format([
            path, 
            out_jstr.substr(0, 40),
            ]));
    out_file.close();
    
static func load_savedata() -> void:
    if (FileAccess.file_exists(savedata_filepath)):
        var savefile : FileAccess = FileAccess.open_encrypted_with_pass(
            savedata_filepath, 
            FileAccess.READ, 
            pwd);
        var savefile_content : String = savefile.get_as_text();
        Statics.debug_log("savesstring: {0}".format([savefile_content]));
        # TODO_LATER: rather than close early, pass file to write and have func deal with if open already
        savefile.close();
        var savefile_json : JSON = JSON.new();
        var validity : Error = savefile_json.parse(savefile_content);
        if (validity == OK and savefile_json.data["version"] == SAVE_VERSION):
            Statics.debug_log("accessed save: {0}".format([savefile_json.data]))
            _instance.savedata = savefile_json.data;
            return;
    # savedata does not exist/version mismatch
    var new_savedata : Dictionary = create_new_savedata();
    write_savedata(new_savedata, savedata_filepath, SAVEDATA.Save);
    Statics.debug_log("creating new save: {0}".format([new_savedata]))
    _instance.savedata = new_savedata;

static func load_keymap() -> void:
    if (FileAccess.file_exists(keybind_filepath)):
        var keybind_file : FileAccess = FileAccess.open(keybind_filepath, FileAccess.READ);
        var keybind_content : String = keybind_file.get_as_text();
        var keybind_json : JSON = JSON.new();
        var validity : Error = keybind_json.parse(keybind_content);
        # DANGER: we are not version checking keybinds its fine
        # I should probably remove the super-strict version checking for keybind data format
        if (validity == OK): #  and keybind_json.data["version"] == SAVE_VERSION
            KeyCon.active_keymap = keybind_json.data;
            KeyCon.write_keymap_to_engine();
            return;
        else:
            Statics.raise_warning("Keybind file possibly corrupted.")
    
    KeyCon.create_keymap();
    write_savedata(KeyCon.init_keymap, keybind_defaults, SAVEDATA.Save);
    write_savedata(KeyCon.init_keymap, keybind_filepath, SAVEDATA.Keybind);
