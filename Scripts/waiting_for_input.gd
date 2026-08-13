extends Control

@export var line_one : Label;
@export var line_two : Label;
@export var line_three : Label;

func set_bind_name(bind_name : String) -> void:
    line_one.text = "OPTIONS_REASSIGN";
