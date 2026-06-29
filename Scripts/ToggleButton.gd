class_name ToggleButton extends Control

@export_group("Textures", "texture_node_")
@export var texture_node_on : TextureRect;
@export var texture_node_off : TextureRect;
@export var texture_node_on_hover : TextureRect;
@export var texture_node_off_hover : TextureRect;
# TODO: state textures for hover?
@export var button_flow_handler : Options;
@export var button : Button;
@export var slider : HSlider;
var prev_slider_val : float;
var is_curr_focused : bool = false;

func toggle_on(on : bool) -> void:
    texture_node_on.visible = on;
    texture_node_off.visible = !on;

func _process(delta: float) -> void:
    # TODO: controller handling
    if (button.is_hovered() or is_curr_focused):
        if (Input.is_anything_pressed()):
            if (slider != null):
                var new_val : float = slider.value;
                if (Input.is_action_pressed(&"right")):
                    new_val = minf(slider.min_value, new_val - 1.0);
                elif (Input.is_action_pressed(&"left")):
                    new_val -= maxf(new_val + 1.0, slider.max_value);
                slider.value = new_val;
            if (Input.is_action_just_pressed(&"ui_accept")):
                button.button_pressed = !button.button_pressed;
    
func _on_focus_entered() -> void:
    is_curr_focused = true;
    button_flow_handler.public_set_curr_focus(button);

func _on_focus_exited() -> void:
    is_curr_focused = false;
    
func _on_mouse_entered() -> void:
    if (texture_node_on_hover != null and texture_node_on.visible):
        texture_node_on_hover.visible = true;
    elif (texture_node_off_hover != null and texture_node_off.visible):
        texture_node_off_hover.visible = true;

func _on_mouse_exited() -> void:
    if (texture_node_on_hover != null and texture_node_on.visible):
        texture_node_on_hover.visible = false;
    elif (texture_node_off_hover != null and texture_node_off.visible):
        texture_node_off_hover.visible = false;

func _on_slider_value_changed(new_val : float) -> void:
    # TODO: consider not updating so often?
    if (is_equal_approx(new_val, 0.0)):
        toggle_on(false);
    else:
        toggle_on(true);

func _on_toggled(new_state : bool) -> void:
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
            
    assert(texture_node_on != null, "TextureRect must exist for button on state");
    assert(texture_node_off != null, "TextureRect must exist for button off state");
    assert(button != null, "Button must exist");
    
    if (button_flow_handler == null):
        var parent : Control = self.get_parent();
        while (not parent is Options):
            parent = parent.get_parent();
        button_flow_handler = parent;
    
    texture_node_on.visible = true;
    texture_node_off.visible = false;
    if (texture_node_on_hover != null): texture_node_on_hover.visible = false;
    if (texture_node_off_hover != null): texture_node_off_hover.visible = false;
    if (slider != null):
        prev_slider_val = slider.value;
        slider.focus_mode = Control.FOCUS_NONE;
        slider.value_changed.connect(_on_slider_value_changed);
    
    button.button_pressed = true;
    button.toggled.connect(_on_toggled);
    button.focus_entered.connect(_on_focus_entered);
    button.focus_exited.connect(_on_focus_exited);
    button.mouse_entered.connect(_on_mouse_entered);
    button.mouse_exited.connect(_on_mouse_exited);
