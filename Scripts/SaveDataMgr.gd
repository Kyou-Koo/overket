class_name SaveDataMgr

const keybind_filepath : String = "user://keybind.save_json"
const savedata_filepath : String = "user://save.dat"
const keybind_defaults : String = "user://keybind_default.dat"
const pwd : String = "whyyesthisisAP4$$W0rdfortheGaMeWhYArEYoUR3aD1nG!!!"

# defaults
const SAVE_VERSION : int = 2;
const LANG : String = "ja";
const MUSIC_VOLUME : int = 5;
const SFX_VOLUME : int = 5;

enum SAVEDATA {
    Keybind,
    Save,
}

static func create_new_savedata() -> Dictionary:
    var lang : String = OS.get_locale_language();
    Statics.debug_log("detected language: {0}".format([lang]));
    if not lang in ["en", "ja"]:
        lang = LANG;
    return {
        "version": SAVE_VERSION,
        "lang": lang,
        "music": MUSIC_VOLUME,
        "sound": SFX_VOLUME,
        "highscore": [],
        "last_open_date": Time.get_datetime_string_from_system(true, false),
    }

static func write_savedata(data : Variant, path : String, type : SAVEDATA) -> void:
    if (not path.begins_with("user://")):
        Statics.raise_warning("Attempting to output to an invalid path: {0}".format([path]));
        return;
    
    var out_file : FileAccess;
    match type:
        SAVEDATA.Keybind:
            out_file = FileAccess.open(path, FileAccess.WRITE);
        SAVEDATA.Save:
            out_file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, pwd);
    data["version"] = SAVE_VERSION; # HACK just shove this in here at all times
    var out_jstr : String = JSON.stringify(data);
    var succ: bool = out_file.store_line(out_jstr);
    if (!succ): 
        Statics.raise_warning("Failed to store to file {0} | {1}".format([
            path, 
            out_jstr.substr(0, 40),
            ]));
    out_file.close();
    
static func load_savedata() -> Dictionary:
    if (FileAccess.file_exists(savedata_filepath)):
        var savefile : FileAccess = FileAccess.open_encrypted_with_pass(
            savedata_filepath, 
            FileAccess.READ, 
            pwd);
        var savefile_content : String = savefile.get_as_text();
        # TODO: rather than close early, pass file to write and have func deal with if open already
        savefile.close();
        var savefile_json : JSON = JSON.new();
        var validity : Error = savefile_json.parse(savefile_content);
        if (validity == OK and savefile_json.data["version"] == SAVE_VERSION):
            return savefile_json.data;;
        else:
            var new_savedata : Dictionary = create_new_savedata();
            write_savedata(new_savedata, savedata_filepath, SAVEDATA.Save);
            return new_savedata;
    # if does not exist
    else:
        var new_savedata : Dictionary = create_new_savedata();
        write_savedata(new_savedata, savedata_filepath, SAVEDATA.Save);
        return new_savedata;

static func pull_keymap_from_file() -> void:
    if (FileAccess.file_exists(keybind_filepath)):
        var keybind_file : FileAccess = FileAccess.open(keybind_filepath, FileAccess.READ);
        var keybind_content : String = keybind_file.get_as_text();
        var keybind_json : JSON = JSON.new();
        var validity : Error = keybind_json.parse(keybind_content);
        if (validity == OK and keybind_json.data["version"] == SAVE_VERSION):
            KeyCon.active_keymap = keybind_json.data;
            return;
        else:
            Statics.raise_warning("Keybind file possibly corrupted.")
    
    KeyCon.create_keymap();
    write_savedata(KeyCon.init_keymap, keybind_defaults, SAVEDATA.Save);
    write_savedata(KeyCon.init_keymap, keybind_filepath, SAVEDATA.Keybind);
