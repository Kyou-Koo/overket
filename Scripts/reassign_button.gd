class_name RebindButton extends Button

@export var keybind_menu : Control;
@export var action_type : KeyCon.ACTTYPE;
@export var keyboard_icon : TextureRect;
@export var controller_button_icon : TextureRect;
@export var controller_stick_icon : TextureRect;
@export var label : Label;
var waiting_for_input : bool = false;
var new_input : InputEvent;
var active : bool = false;
var is_focused : bool = false;

signal waiting_for_rebind(button_name : String);
signal rebind_finished();

func _input(ev: InputEvent) -> void:
    if (!active):
        return;
    # reject going left/right
    if ((ev.is_action(&"ui_left") or ev.is_action(&"ui_right")) and !waiting_for_input and is_focused):
        get_viewport().set_input_as_handled();

    if (!waiting_for_input):
        return;
    get_viewport().set_input_as_handled();
    # specific key to cancel
    if (ev.is_pressed() and ev.is_action(&"start")):
        waiting_for_input = false;
        rebind_finished.emit();
    elif (ev.is_pressed()):
        if (ev is InputEventKey):
            keyboard_icon.visible = true;
            controller_button_icon.visible = false;
            controller_stick_icon.visible = false;
            label.text = InputStatics.input_text_string_to_short_txt(ev, false);
        elif (ev is InputEventJoypadButton):
            keyboard_icon.visible = false;
            controller_button_icon.visible = true;
            controller_stick_icon.visible = false;
            label.text = InputStatics.input_text_string_to_short_txt(ev, true);
        elif (ev is InputEventJoypadMotion):
            if (ev.axis_value > 0.0):
                ev.axis_value = 1.0;
            else:
                ev.axis_value = -1.0;
            keyboard_icon.visible = false;
            controller_button_icon.visible = false;
            controller_stick_icon.visible = true;
            label.text = InputStatics.input_text_string_to_short_txt(ev, true);
        AudioManager._instance.play_SFX(AudioFiles.MENU_ACTION)
        KeyCon.update_keymap(keybind_menu.active_player, action_type, ev);
        waiting_for_input = false;
        rebind_finished.emit();

func _on_pressed() -> void:
    waiting_for_input = true;
    waiting_for_rebind.emit(self.name);

func _on_visibility_changed() -> void:
    active = is_visible_in_tree();
    # Statics.debug_log("{0} is active? {1}".format([self.name, active]));

func _on_focus_entered() -> void:
    is_focused = true;
    # Statics.debug_log("focused: {0}".format([self.name]));
    
func _on_focus_exited() -> void:
    is_focused = false;

func _ready() -> void:
    self.pressed.connect(_on_pressed);
    self.focus_entered.connect(_on_focus_entered);
    self.focus_exited.connect(_on_focus_exited);
    self.visibility_changed.connect(_on_visibility_changed);
