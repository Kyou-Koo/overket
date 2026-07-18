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

static var init_keymap : Dictionary = {
    "p1": {},
    "p2": {},
    "p3": {},
    "p4": {},
    "general": {},
}

static var active_keymap : Dictionary;

static func dict_entry_from_input_event(es : Array[InputEvent]) -> Dictionary:
    var new_dict : Dictionary;
    # physicalkey for key, axis + axis value for stick, btn index for button
    # { "device": device, "pkeycode": physical_keycode }
    # { "device": device, "axis": axis, "av": axis_vaue }
    # { "device": device, "button": button_index }
    for e : InputEvent in es:
        if (e is InputEventKey):
            new_dict["key"] = {
                "iam": "keyboard",
                "device": e.device,
                "pkeycode": e.physical_keycode,
            }
        elif (e is InputEventJoypadButton):
            new_dict["con"] = {
                "iam": "button",
                "device": e.device,
                "button": e.button_index
            }
        elif (e is InputEventJoypadMotion):
            new_dict["con"] = {
                "iam": "axis",
                "device": e.device,
                "axis": e.axis,
                "av": e.axis_value,
            }
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
            
    #Statics.debug_log(str(init_keymap));
    active_keymap = init_keymap.duplicate(true);
    
# player requiered to be p1/p2/p3/p4
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
    
    var input_dict : Dictionary = dict_entry_from_input_event([new_key])
    var pair_input : InputEvent = null;
    if (new_key is InputEventKey):
        active_keymap[player][con_str]["key"] = input_dict;
        pair_input = InputStatics.create_input_event_from_dict(active_keymap[player][con_str]["con"]);
    else:
        active_keymap[player][con_str]["con"] = input_dict;
        if (player == "p1" or player == "p2"):
            pair_input = InputStatics.create_input_event_from_dict(active_keymap[player][con_str]["key"]);
    
    var input_arr : Array[InputEvent] = [new_key];
    if (pair_input != null): input_arr.append(pair_input);
    update_player_inputmap(input_arr, player+con_str);
        
static func update_player_inputmap(new_inputs : Array[InputEvent], action_name : String) -> void:
    for ni : InputEvent in new_inputs:
        InputMap.action_erase_events(action_name);
        InputMap.action_add_event(action_name, ni)

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
