extends VBoxContainer

@export var control_type : Button;
@export var player_label : Label;
@export var save_controls : Button;
@export var waiting_for_input_container : Control;
@export var options : Options;
var keybind_row_buttons : Dictionary[String, RebindButton];
# { "Name": [Button, Label] }

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
    for key : String in keybind_row_buttons:
        var b : Button = keybind_row_buttons[key];
        # TODO: stick icon????
        b.keyboard_icon.visible = !use_gamepad;
        b.controller_button_icon.visible = use_gamepad;
        # display icons
        var new_input_event : InputEvent;
        #label.add_theme_font_size_override(active_string, font_size);
        match key:
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

func _on_rebind_pressed(btn_name : String) -> void:
    waiting_for_input_container.visible = true;

func _on_player_bind_selected(player : String) -> void:
    player_label.text = player.capitalize();
    
func _on_control_type_pressed() -> void:
    if (control_type.text == "OPTIONS_KEYBOARD"):
        control_type.text = "OPTIONS_CONTROLLER";
    else:
        control_type.text = "OPTIONS_KEYBOARD";

func _on_save_pressed() -> void:
    pass
    # TODO: call sdm/keybindmanager to dump keybind out

func _on_rebind_captured(ev : InputEvent) -> void:
    pass
    # TODO: perform remapping

func _ready() -> void:
    assert(control_type != null, "assign controltype button");
    assert(save_controls != null, "assign save button");

    for n : Node in self.get_children():
        if (n is HBoxContainer):
            if (n.get_child(0) is RebindButton):
                var btn : RebindButton = n.get_child(0);
                keybind_row_buttons[btn.name] = btn;
                btn.waiting_for_rebind.connect(_on_rebind_pressed);
                
    # sanity check
    Statics.debug_log(str(keybind_row_buttons));
    waiting_for_input_container.visible = false;
    waiting_for_input_container.input_captured.connect(_on_rebind_captured);
    options.load_player_control.connect(_on_player_bind_selected);
    control_type.pressed.connect(_on_control_type_pressed);
    save_controls.pressed.connect(_on_save_pressed);
