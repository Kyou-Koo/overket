class_name ToggleButton extends Control

@export_group("Textures", "texture_node_")
@export var texture_node_on : TextureRect;
@export var texture_node_off : TextureRect;
@export var texture_node_on_hover : TextureRect;
@export var texture_node_off_hover : TextureRect;
@export var button_flow_handler : Options;
@export var button : Button;
@export var slider : HSlider;
@export var focus_background : Control;
var prev_slider_val : float;
var is_curr_focused : bool = false;
var is_curr_hovered : bool = false;

# I think this could theoretically be a texture button (shrugs) (lmao)
func toggle_on(on : bool) -> void:
    texture_node_on.visible = on;
    texture_node_off.visible = !on;
    if (is_curr_hovered):
        texture_node_on_hover.visible = on;
        texture_node_off_hover.visible = !on;

func _input(ev: InputEvent) -> void:
    if (!button_flow_handler.is_active):
        return;
    if (slider != null and (button.is_hovered() or is_curr_focused)):
        var new_val : float = slider.value;
        if (ev.is_action_pressed(&"ui_left", false, true)):
            if (ev.get_action_strength(&"ui_left") > 0.5):
                new_val = maxf(slider.min_value, new_val - 1.0);
                Statics.debug_log("is left, new val {0}".format([new_val]))
        elif (ev.is_action_pressed(&"ui_right", false, true)):
            if (ev.get_action_strength(&"ui_right") > 0.5):
                new_val = minf(new_val + 1.0, slider.max_value);
                Statics.debug_log("is right, new val {0}".format([new_val]))
        else:
            return;
        slider.value = new_val;

        get_viewport().set_input_as_handled();
    
func _on_focus_entered() -> void:
    if (!button_flow_handler.is_active):
        return;
    is_curr_focused = true;
    focus_background.visible = true;
    button_flow_handler.public_set_curr_focus(button);

func _on_focus_exited() -> void:
    if (!button_flow_handler.is_active):
        return;
    is_curr_focused = false;
    focus_background.visible = false;

func _on_button_hover() -> void:
    if (!button_flow_handler.is_active):
        return;
    is_curr_hovered = true;
    if (texture_node_on_hover != null and texture_node_on.visible):
        texture_node_on_hover.visible = true;
    elif (texture_node_off_hover != null and texture_node_off.visible):
        texture_node_off_hover.visible = true;

func _on_button_unhover() -> void:
    if (!button_flow_handler.is_active):
        return;
    is_curr_hovered = false;
    if (texture_node_on_hover != null and texture_node_on.visible):
        texture_node_on_hover.visible = false;
    elif (texture_node_off_hover != null and texture_node_off.visible):
        texture_node_off_hover.visible = false;

func _on_slider_value_changed(new_val : float) -> void:
    if (!button_flow_handler.is_active):
        return;
    # TODO: consider not updating so often?
    if (is_equal_approx(new_val, 0.0)):
        toggle_on(false);
    else:
        toggle_on(true);
    
    var field : SaveDataMgr.FIELD;
    if (self.name == "music"):
        field = SaveDataMgr.FIELD.MUSIC;
    elif (self.name == "sound"):
        field = SaveDataMgr.FIELD.SOUND;
    GameManager._instance.savedata = SaveDataMgr.update_savefield(
        new_val,
        field,
        GameManager._instance.savedata);

func _on_toggled(new_state : bool) -> void:
    if (!button_flow_handler.is_active):
        return;
    Statics.debug_log("Button {0} is toggled to {1}".format([
        button.name,
        new_state,
        ]));
    if (new_state):
        slider.value = prev_slider_val;
    else:
        prev_slider_val = 1.0 if is_equal_approx(slider.value, 0.0) else slider.value;
        slider.value = 0.0;

func _ready() -> void:
    # safety catches
    var children : Array[Node] = self.get_children();
    for c in children:
        if (c is TextureRect):
            if (c.name.contains("On") and texture_node_on == null):
                texture_node_on = c as TextureRect;
            elif (c.name.contains("Off") and texture_node_off == null):
                texture_node_off = c as TextureRect;
        elif (c is Button and button == null):
            button = c as Button;
        elif (c is HSlider and slider == null):
            slider = c as HSlider;
        elif (c is NinePatchRect or c is TextureRect):
            focus_background = c;

    assert(texture_node_on != null, "TextureRect must exist for button on state");
    assert(texture_node_off != null, "TextureRect must exist for button off state");
    assert(button != null, "Button must exist");
    assert(focus_background != null, "Focus background required");
    
    if (button_flow_handler == null):
        var parent : Control = self.get_parent();
        while (not parent is Options):
            parent = parent.get_parent();
        button_flow_handler = parent;
    
    # update from save:
    var settings_value : int;
    settings_value = GameManager._instance.savedata[self.name];
    texture_node_on.visible = (settings_value != 0);
    texture_node_off.visible = (settings_value == 0);
    if (texture_node_on_hover != null): texture_node_on_hover.visible = false;
    if (texture_node_off_hover != null): texture_node_off_hover.visible = false;
    if (slider != null):
        slider.value = settings_value;
        prev_slider_val = slider.value;
        slider.focus_mode = Control.FOCUS_NONE;
        slider.value_changed.connect(_on_slider_value_changed);
    
    button.toggle_mode = true; # for safety
    button.button_pressed = (settings_value != 0);
    button.text = ""; # wipe button text to utilize the label
    button.toggled.connect(_on_toggled);
    button.focus_entered.connect(_on_focus_entered);
    button.focus_exited.connect(_on_focus_exited);
    button.mouse_entered.connect(_on_button_hover);
    button.mouse_exited.connect(_on_button_unhover);

    focus_background.visible = false;
