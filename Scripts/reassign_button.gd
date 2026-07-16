extends Button

@export var keybind_menu : Control;
@export var action_type : KeyCon.ACTTYPE;
@export var keyboard_icon : TextureRect;
@export var controller_button_icon : TextureRect;
@export var controller_stick_icon : TextureRect;
@export var label : Label;
var waiting_for_input : bool = false;
var new_input : InputEvent;
var active : bool = false;

# TODO: change visual when waiting for keybind

func _input(ev: InputEvent) -> void:
    if (!active):
        return;
    # reject going left/right
    if ((ev.is_action(&"ui_left") or ev.is_action(&"ui_right")) and !waiting_for_input):
        get_viewport().set_input_as_handled();
    # specific key to cancel
    if (ev.is_action(&"start")):
        waiting_for_input = false;
        get_viewport().set_input_as_handled();
    if (!waiting_for_input):
        return;
    get_viewport().set_input_as_handled();
    new_input = ev;
    KeyCon.update_keymap(keybind_menu.active_player, action_type, new_input);
    # TODO: update control
    var input_dict : Dictionary = KeyCon.dict_entry_from_input_event([new_input]);
    

func _on_pressed() -> void:
    waiting_for_input = true;
    # pop up window?

func _on_visibility_changed() -> void:
    active = is_visible_in_tree();
    Statics.debug_log("{0} is active? {1}".format([self.name, active]));


func _ready() -> void:
    self.pressed.connect(_on_pressed);
    self.visibility_changed.connect(_on_visibility_changed);
