extends VBoxContainer

@export var control_type : Button;
@export var save_controls : Button;
@export var options : Options;
var keybind_row_buttons : Array[Button];
var active_player : String;

func input_event_from_dict_wrapper(pkey : String, key : String, act_string : String) -> InputEvent:
    if (not KeyCon.active_keymap.has(pkey)):
        print("running keymap generation")
        KeyCon.create_keymap();
    return InputStatics.create_input_event_from_dict(KeyCon.active_keymap[pkey][key][act_string]);

func display_player_control(pkey : String) -> void:
    var active_string : String = "key";
    # need to overrride specifically for p3 and p4
    var use_gamepad : bool = options.is_gamepad_last_used;
    if (options.is_gamepad_last_used or (pkey == "p3" or pkey == "p4")):
        active_string = "con";
        use_gamepad = true;
    for b : Button in keybind_row_buttons:
        # TODO: stick icon????
        b.keyboard_icon.visible = !use_gamepad;
        b.controller_button_icon.visible = use_gamepad;
        # display icons
        var new_input_event : InputEvent;
        #label.add_theme_font_size_override(active_string, font_size);
        match b.name:
            "Forward":
                new_input_event = input_event_from_dict_wrapper(pkey, "fwd", active_string);
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Back":
                new_input_event = input_event_from_dict_wrapper(pkey, "back", active_string);
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Left":
                new_input_event = input_event_from_dict_wrapper(pkey, "left", active_string);
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Right":
                new_input_event = input_event_from_dict_wrapper(pkey, "right", active_string);
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Jump":
                new_input_event = input_event_from_dict_wrapper(pkey, "jump", active_string);
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Interact":
                new_input_event = input_event_from_dict_wrapper(pkey, "interact", active_string);
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "PickDrop":
                new_input_event = input_event_from_dict_wrapper(pkey, "pick_drop", active_string);
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);;

func _on_player_bind_selected(player : String) -> void:
    active_player = player;

func _ready() -> void:
    assert(control_type != null, "assign controltype button");
    assert(save_controls != null, "assign save button");

    for n : Node in self.get_children():
        if (n is HBoxContainer):
            if (n.get_child(0) is Button):
                keybind_row_buttons.append(n.get_child(0));
    # sanity check
    Statics.debug_log(str(keybind_row_buttons));
    
    options.load_player_control.connect(_on_player_bind_selected);
