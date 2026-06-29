class_name Options extends Control

var player_controls_all : Control;
var curr_focused_control : Control;
var last_focused_player_control : Control;

func public_set_curr_focus(c : Control) -> void:
    curr_focused_control = c;
    Statics.debug_log("curr focused: {0}".format([c.name]));
    
func public_set_last_focused(c : Control) -> void:
    if (c.name.begins_with("ButtonP")):
        last_focused_player_control = c;
    
func _on_player_controls_box_focused() -> void:
    Statics.debug_log("box focused on");
    if (last_focused_player_control != null):
        curr_focused_control = last_focused_player_control;
    else:
        curr_focused_control = $"NinePatchRect/Box/Controls P1/Button/ButtonP1"
    curr_focused_control.grab_focus();

#func _process(delta: float) -> void:
    #if (curr_focused_control.name.begins_with("ButtonP")):
        #last_focused_player_control = curr_focused_control;

func _ready() -> void:
    $"NinePatchRect/Music Control/Button Music".grab_focus.call_deferred();
    player_controls_all = $NinePatchRect/Box;
    player_controls_all.focus_entered.connect(_on_player_controls_box_focused);
