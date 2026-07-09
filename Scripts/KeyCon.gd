class_name KeyCon

enum ACTTYPE {
    FWRD,
    BACK,
    LEFT,
    RGHT,
    INTR,
    PKDR,
    JUMP,
};

enum KC {
    K,
    C,
}

# selfnote: event = inputevent, action = stringname'd action
static var connected_devices : PackedInt64Array = [
    InputEvent.DEVICE_ID_EMULATION,
]

static var init_keymap : Dictionary[String, Dictionary] = {
    "p1": {},
    "p2": {},
    "p3": {},
    "p4": {},
    "general": {},
}

static var active_keymap : Dictionary[String, Dictionary];

static func dict_entry_from_input_event(es : Array[InputEvent]) -> Dictionary:
    var new_dict : Dictionary;
    for e : InputEvent in es:
        if (e is InputEventKey):
            new_dict["key"] = e;
        else:
            new_dict["con"] = e;
    return new_dict;

static func create_keymap() -> void:
    var actions : Array[StringName] = InputMap.get_actions();
    for a : StringName in actions:
        if (a.begins_with("p1")):
            init_keymap["p1"][a.substr(2, -1)] = dict_entry_from_input_event(InputMap.action_get_events(a));
        elif (a.begins_with("p2")):
            init_keymap["p2"][a.substr(2, -1)] = dict_entry_from_input_event(InputMap.action_get_events(a));
        elif (a.begins_with("p3")):
            init_keymap["p3"][a.substr(2, -1)] = dict_entry_from_input_event(InputMap.action_get_events(a));
        elif (a.begins_with("p4")):
            init_keymap["p4"][a.substr(2, -1)] = dict_entry_from_input_event(InputMap.action_get_events(a));
        else:
            init_keymap["general"][a] = dict_entry_from_input_event(InputMap.action_get_events(a));
            
    Statics.debug_log(str(init_keymap));
    active_keymap = init_keymap.duplicate(true);
    
static func update_keymap(player: String, control: ACTTYPE, new_key : InputEvent) -> void:
    var con_str : String = "";
    match control:
        ACTTYPE.FWRD:
            con_str = "fwd";
        ACTTYPE.BACK:
            con_str = "back";
        ACTTYPE.LEFT:
            con_str = "left";
        ACTTYPE.RGHT:
            con_str = "right";
        ACTTYPE.INTR:
            con_str = "interact";
        ACTTYPE.PKDR:
            con_str = "pick_drop";
        ACTTYPE.JUMP:
            con_str = "jump";
    
    if (new_key is InputEventKey):
        active_keymap[player][con_str]["key"] = new_key;
    else:
        active_keymap[player][con_str]["con"] = new_key;
    
    update_player_inputmap(active_keymap[player], player);
        
static func update_player_inputmap(player : Dictionary, pstring : String) -> void:
    for input : String in player:
        var action_name : String = pstring + input;
        InputMap.action_erase_events(action_name);
        InputMap.action_add_event(action_name, player[input]["key"]);
        InputMap.action_add_event(action_name, player[input]["con"]);

class IndividualMap:
    var action_mapping : Dictionary[String, Dictionary] = {
        "fwd": {
            "key": -1,
            "con": -1,
        },
        "back": {
            "key": -1,
            "con": -1,
        },
        "left": {
            "key": -1,
            "con": -1,
        },
        "right": {
            "key": -1,
            "con": -1,
        },
        "interact": {
            "key": -1,
            "con": -1,
        },
        "pick_drop": {
            "key": -1,
            "con": -1,
        },
    }
    var key : StringName;

    func _init(pname : StringName) -> void:
        key = pname;

    func add_mapping(action : ACTTYPE, kc : KC, input : int) -> void:
        var con_mode : String = "con";
        if (kc == KC.K):
            con_mode = "key";
        match action:
            ACTTYPE.FWRD:
                action_mapping["fwd"][con_mode] = input;
            ACTTYPE.BACK:
                action_mapping["back"][con_mode] = input;
            ACTTYPE.LEFT:
                action_mapping["left"][con_mode] = input;
            ACTTYPE.RGHT:
                action_mapping["right"][con_mode] = input;
            ACTTYPE.INTR:
                action_mapping["interact"][con_mode] = input;
            ACTTYPE.PKDR:
                action_mapping["pick_drop"][con_mode] = input;
