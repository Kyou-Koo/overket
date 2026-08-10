class_name KeybindMenu extends NinePatchRect

@export var control_type : Label;
@export var player_label : Label;
@export var save_controls : Button;
@export var waiting_for_input_container : Control;
@export var options : Options;
var keybind_row_buttons : Dictionary[String, RebindButton];
var active_player : String;
var is_gamepad : bool = true;

signal keybind_menu_closed(keybind_menu : KeybindMenu);

func input_event_from_dict_wrapper(pkey : String, key : String, act_string : String) -> InputEvent:
    if (not KeyCon.active_keymap.has(pkey)):
        Statics.debug_log("running keymap generation")
        KeyCon.create_keymap();
    return InputStatics.create_input_event_from_dict(KeyCon.active_keymap[pkey][key][act_string]);

func display_player_control(pkey : String) -> void:
    self.focus_mode = Control.FOCUS_ALL;
    self.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED;
    Statics.recursively_set_child_focus(self, Control.FOCUS_ALL);
    var active_string : String = "key";
    control_type.text = "OPTIONS_KEYBOARD";
    active_player = pkey;
    # need to overrride specifically for p3 and p4
    var use_gamepad : bool = options.is_gamepad_last_used;
    is_gamepad = use_gamepad;
    if (options.is_gamepad_last_used or (pkey == "p3" or pkey == "p4")):
        active_string = "con";
        use_gamepad = true;
        control_type.text = "OPTIONS_CONTROLLER"
    for key : String in keybind_row_buttons:
        var b : Button = keybind_row_buttons[key];
        b.focus_mode = Control.FOCUS_ALL;
        var new_input_event : InputEvent;
        #label.add_theme_font_size_override(active_string, font_size);
        # set text
        match key:
            "Forward":
                b.grab_focus.call_deferred();
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
                b.label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
        # display icons
        if (use_gamepad):
            b.keyboard_icon.visible = false;
            is_gamepad = true;
            if (new_input_event is InputEventJoypadButton):
                b.controller_stick_icon.visible = false;
                b.controller_button_icon.visible = true;
            else:
                b.controller_stick_icon.visible = true;
                b.controller_button_icon.visible = false;
        else:
            is_gamepad = false;
            b.keyboard_icon.visible = true;
            b.controller_stick_icon.visible = false;
            b.controller_button_icon.visible = false;

func _on_rebind_pressed(btn_name : String) -> void:
    AudioManager._instance.play_SFX(AudioFiles.MENU_ACTION);
    waiting_for_input_container.visible = true;
    waiting_for_input_container.set_bind_name(btn_name);
    options.is_rebind_mode = true;

func _on_rebind_finished() -> void:
    waiting_for_input_container.visible = false;
    options.is_rebind_mode = false;

func _on_player_bind_selected(player : String) -> void:
    player_label.text = player.capitalize();
    display_player_control(player);

func _on_save_pressed() -> void:
    self.visible = false;
    keybind_menu_closed.emit(self);
    AudioManager._instance.play_SFX(AudioFiles.MENU_CONFIRM);
    SaveDataMgr.write_savedata(KeyCon.active_keymap, SaveDataMgr.keybind_filepath, SaveDataMgr.SAVEDATA.Keybind);
    
func _input(ev: InputEvent) -> void:
    if (!options.is_rebind_mode and self.visible):
        # reject going left/right
        if (ev.is_action(&"ui_left") or ev.is_action(&"ui_right")):
            get_viewport().set_input_as_handled();

func _ready() -> void:
    assert(control_type != null, "assign controltype button");
    assert(save_controls != null, "assign save button");
    
    self.focus_mode = Control.FOCUS_NONE;
    #self.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED;
    for n : Node in self.get_child(0).get_children():
        if (n is HBoxContainer):
            if (n.get_child(0) is RebindButton):
                var btn : RebindButton = n.get_child(0);
                keybind_row_buttons[btn.name] = btn;
                btn.keybind_menu = self;
                btn.waiting_for_rebind.connect(_on_rebind_pressed);
                btn.rebind_finished.connect(_on_rebind_finished);
                
    # sanity check
    # Statics.debug_log(str(keybind_row_buttons));
    waiting_for_input_container.visible = false;
    # waiting_for_input_container.input_captured.connect(_on_rebind_captured);
    options.load_player_control.connect(_on_player_bind_selected);
    save_controls.pressed.connect(_on_save_pressed);
