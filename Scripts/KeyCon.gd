class_name KeyCon

enum ACTTYPE {
    FWRD,
    BACK,
    LEFT,
    RGHT,
    INTR,
    PKDR,
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

}

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
