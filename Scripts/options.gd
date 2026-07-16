class_name Options extends Control

@export_group("Controls")
@export var player1 : Control;
@export var player2 : Control;
@export var player3 : Control;
@export var player4 : Control;
@export var keybind_holder : Control;
@export var keybind_box : Control;
@export var save_button : Button;
@export var back_button : Button;
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

var curr_settings : Dictionary = SaveDataMgr.blank.duplicate(true);
var curr_keybinds : Dictionary;
var is_active : bool = false;

signal load_player_control(player : String);

func public_update_curr_settings() -> void:
    pass;

func public_set_activated_button(b : Button) -> void:
    match b:
        player1:
            load_player_control.emit("p1");
        player2:
            load_player_control.emit("p2");
        player3:
            load_player_control.emit("p3");
        player4:
            load_player_control.emit("p4");
        _:
            Statics.raise_warning("Non-keybind button activated this function.")
    keybind_holder.visible = true;
    
func public_set_curr_focus(c : Control) -> void:
    curr_focused_control = c;
    Statics.debug_log("curr focused: {0}".format([c.name]));
    
# only for determing where in the p1/p2/p3/p4 config box to determine where
# to navigate when pressing down from SFX
func public_set_last_focused(c : Control) -> void:
    if (c.name.begins_with("ButtonP")):
        last_focused_player_control = c;

func _on_player_controls_box_focused() -> void:
    if (!is_active):
        return;
    Statics.debug_log("box focused on");
    if (last_focused_player_control != null):
        curr_focused_control = last_focused_player_control;
    else:
        curr_focused_control = $"NinePatchRect/Box/HBoxContainer/Controls P1/Button/ButtonP1";
    curr_focused_control.grab_focus();

func _on_save_pressed() -> void:
    if (!is_active):
        return;
    GameManager._instance.savedata = SaveDataMgr.update_savedata(curr_settings, GameManager._instance.savedata);

func _on_back_pressed() -> void:
    if (!is_active):
        return;
    GameManager._instance.public_rotate_camera(
        GameManager._instance.main_cam_origin_rot,
        GameManager.MENU.MAIN);

func _on_menu_transition(who : Node) -> void:
    if (who == self):
        is_active = true;
        get_node("NinePatchRect/Language Control/{0}".format([GameManager._instance.savedata["lang"].capitalize()])).grab_focus.call_deferred();
    else:
        is_active = false;

func _input(ev: InputEvent) -> void:
    if (!is_active):
        return;
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
    #print(str(SaveDataMgr.load_savedata()))
    
    # test remapping:
    #var new_eventkey : InputEventKey = InputEventKey.new();
    #new_eventkey.keycode = KEY_Z;
    #KeyCon.update_keymap("p1", KeyCon.ACTTYPE.FWRD, new_eventkey);
    #Statics.debug_log(str(KeyCon.init_keymap));
    #Statics.debug_log("below is modded keymap ----");
    #Statics.debug_log(str(InputMap.action_get_events("p1fwd")));
    # ---------------------
    var lang_str : String = OS.get_locale_language();
    if (GameManager._instance != null):
        GameManager._instance.set_lang_from_save();
        lang_str = GameManager._instance.savedata["lang"];
        GameManager._instance.transition_to.connect(_on_menu_transition);
    Statics.debug_log("NinePatchRect/Language Control/{0}".format([lang_str.capitalize()]))
    get_node("NinePatchRect/Language Control/{0}".format([lang_str.capitalize()])).grab_focus.call_deferred();
    player_controls_all = $NinePatchRect/Box;
    player_controls_all.focus_entered.connect(_on_player_controls_box_focused);

    assert(keybind_holder != null, "keybind holder must be assigned");
    assert(keybind_box != null, "keybind box must be assigned");
    keybind_holder.visible = false;
    for c : Control in keybind_box.get_children():
        if (c is Button):
            keybind_box_nodes.append(c);

    assert(save_button != null, "save must be assigned");
    assert(back_button != null, "back button must be assigned");
    save_button.pressed.connect(_on_save_pressed);
    back_button.pressed.connect(_on_back_pressed);
