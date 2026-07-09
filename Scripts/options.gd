class_name Options extends Control

@export var player1 : Control;
@export var player2 : Control;
@export var player3 : Control;
@export var player4 : Control;
@export var keybind_box : Control;
var keybind_box_nodes : Array[Button];

var player_controls_all : Control;
var curr_focused_control : Control;
var last_focused_player_control : Control;
var activated_button : Button;
var is_gamepad_last_used : bool = false;

# TODO: implement control switching
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
    
func public_set_last_focused(c : Control) -> void:
    if (c.name.begins_with("ButtonP")):
        last_focused_player_control = c;

func display_player_control(key : String) -> void:
    var icon_active : String = "KeyboardIcon";
    var icon_unact : String = "ControllerIcon";
    var font_size : int = 24;
    if (is_gamepad_last_used):
        icon_active = "ControllerIcon";
        icon_unact = "KeyboardIcon";
        font_size = 32;
    for b : Button in keybind_box_nodes:
        b.find_child(icon_active).visible = true;
        b.find_child(icon_unact).visible = false;
        # display icons
        if (b.name == "Forward"):
            pass;
        elif (b.name == "Back"):
            pass
        elif (b.name == "Left"):
            pass
        elif (b.name == "Right"):
            pass
        elif (b.name == "Interact"):
            pass
        elif (b.name == "PickDrop"):
            pass
    
    keybind_box.visible = true;

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
    #KeyCon.create_keymap();
    
    # test remapping:
    #var new_eventkey : InputEventKey = InputEventKey.new();
    #new_eventkey.keycode = KEY_Z;
    #KeyCon.update_keymap("p1", KeyCon.ACTTYPE.FWRD, new_eventkey);
    #Statics.debug_log(str(KeyCon.init_keymap));
    #Statics.debug_log("below is modded keymap ----");
    #Statics.debug_log(str(InputMap.action_get_events("p1fwd")));
    
    $"NinePatchRect/Music Control/Button Music".grab_focus.call_deferred();
    player_controls_all = $NinePatchRect/Box;
    player_controls_all.focus_entered.connect(_on_player_controls_box_focused);

    assert(keybind_box != null, "keybind box must be assigned");

    for c : Control in keybind_box.get_children():
        if (c is Button):
            keybind_box_nodes.append(c);
