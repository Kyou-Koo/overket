class_name Options extends Control

@export_group("Controls")
@export var player1 : Control;
@export var player2 : Control;
@export var player3 : Control;
@export var player4 : Control;
@export var keybind_holder : Control;
@export var keybind_box : Control;
var keybind_box_nodes : Array[Button];

var player_controls_all : Control;
var curr_focused_control : Control;
var last_focused_player_control : Control;
var curr_hovered_control : Control;
## In ms
const hover_delay_ms : int = 500;
var time_since_last_hovered : int = -1;
var activated_button : Button;
var is_gamepad_last_used : bool = false;

signal hover_new(new_hover : Control);
signal hover_removed(focused_control : Control);

func public_set_activated_button(b : Button) -> void:
    match b:
        player1:
            display_player_control("p1");
        player2:
            display_player_control("p2");
        player3:
            display_player_control("p3");
        player4:
            display_player_control("p4");
        _:
            Statics.raise_warning("Non-keybind button activated this function.")
    
func public_set_curr_focus(c : Control) -> void:
    curr_focused_control = c;
    Statics.debug_log("curr focused: {0}".format([c.name]));

func public_set_curr_hover(c : Control) -> void:
    curr_hovered_control = c;
    hover_new.emit(c);

func public_set_unhover(c : Control) -> void:
    if (c == curr_hovered_control):
        time_since_last_hovered = Time.get_ticks_msec();
        curr_hovered_control = null;
    await get_tree().create_timer(hover_delay_ms / 1000.0).timeout;
    if (curr_hovered_control == null):
        hover_removed.emit(curr_focused_control);
    
func public_set_last_focused(c : Control) -> void:
    if (c.name.begins_with("ButtonP")):
        last_focused_player_control = c;
        
func input_event_from_dict_wrapper(pkey : String, key : String, act_string : String) -> InputEvent:
    if (not KeyCon.active_keymap.has(pkey)):
        print("running keymap generation")
        KeyCon.create_keymap();
    return InputStatics.create_input_event_from_dict(KeyCon.active_keymap[pkey][key][act_string]);

func display_player_control(pkey : String) -> void:
    var icon_active : String = "KeyboardIcon";
    var icon_unact : String = "ControllerIcon";
    var active_string : String = "key";
    # need to overrride specifically for p3 and p4
    var use_gamepad : bool = is_gamepad_last_used;
    if (is_gamepad_last_used or (pkey == "p3" or pkey == "p4")):
        icon_active = "ControllerIcon";
        icon_unact = "KeyboardIcon";
        active_string = "con";
        use_gamepad = true;
    for b : Button in keybind_box_nodes:
        b.find_child(icon_active).visible = true;
        b.find_child(icon_unact).visible = false;
        # display icons
        var new_input_event : InputEvent;
        var label : Label = b.find_child("Label");
        #label.add_theme_font_size_override(active_string, font_size);
        match b.name:
            "Forward":
                new_input_event = input_event_from_dict_wrapper(pkey, "fwd", active_string);
                label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Back":
                new_input_event = input_event_from_dict_wrapper(pkey, "back", active_string);
                label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Left":
                new_input_event = input_event_from_dict_wrapper(pkey, "left", active_string);
                label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Right":
                new_input_event = input_event_from_dict_wrapper(pkey, "right", active_string);
                label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Jump":
                new_input_event = input_event_from_dict_wrapper(pkey, "jump", active_string);
                label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "Interact":
                new_input_event = input_event_from_dict_wrapper(pkey, "interact", active_string);
                label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);
            "PickDrop":
                new_input_event = input_event_from_dict_wrapper(pkey, "pick_drop", active_string);
                label.text = InputStatics.input_text_string_to_short_txt(new_input_event, use_gamepad);;
    
    keybind_holder.visible = true;

func _on_player_controls_box_focused() -> void:
    Statics.debug_log("box focused on");
    if (last_focused_player_control != null):
        curr_focused_control = last_focused_player_control;
    else:
        curr_focused_control = $"NinePatchRect/Box/Controls P1/Button/ButtonP1"
    curr_focused_control.grab_focus();

func _input(ev: InputEvent) -> void:
    if (Input.get_connected_joypads().size() == 0 or 
    ev.get_class() == "InputEventKey" or
    ev.get_class() == "InputEventMouseButton"):
        is_gamepad_last_used = false;
    else:
        if (ev.get_class() == "InputEventJoypadMotion" and absf(ev.axis_value) < 0.2):
            return;
        is_gamepad_last_used = true;
        
    # TODO: delete laters
    #if (ev.get_class() != "InputEventJoypadMotion"):
        #print(ev.as_text());
        #print(ev.to_string());
    if (ev.is_pressed()):
        print(InputStatics.input_text_string_to_short_txt(ev, is_gamepad_last_used)) # pass as text to mapping
        

func _ready() -> void:
    # TESTING---------------------
    #KeyCon.create_keymap();
    print(str(SaveDataMgr.load_savedata()))
    
    # test remapping:
    #var new_eventkey : InputEventKey = InputEventKey.new();
    #new_eventkey.keycode = KEY_Z;
    #KeyCon.update_keymap("p1", KeyCon.ACTTYPE.FWRD, new_eventkey);
    #Statics.debug_log(str(KeyCon.init_keymap));
    #Statics.debug_log("below is modded keymap ----");
    #Statics.debug_log(str(InputMap.action_get_events("p1fwd")));
    # ---------------------
    
    $"NinePatchRect/Music Control/Button Music".grab_focus.call_deferred();
    player_controls_all = $NinePatchRect/Box;
    player_controls_all.focus_entered.connect(_on_player_controls_box_focused);

    assert(keybind_holder != null, "keybind holder must be assigned");
    assert(keybind_box != null, "keybind box must be assigned");

    keybind_holder.visible = false;
    for c : Control in keybind_box.get_children():
        if (c is Button):
            keybind_box_nodes.append(c);
