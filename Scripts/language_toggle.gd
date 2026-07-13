extends Control

@export var button_flow_handler : Options;
@export var ja_button : Button;
@export var en_button : Button;
@export var focus_background : Control;
var is_child_button_focused : bool = false;

func _on_mouse_entered() -> void:
    focus_background.visible = true;
    button_flow_handler.public_set_curr_hover(self);

func _on_mouse_exited() -> void:
    focus_background.visible = false;
    button_flow_handler.public_set_unhover(self);

func _on_no_hover(c : Control) -> void:
    if (c == self or c == ja_button or c == en_button):
        focus_background.visible = true;

func _ready() -> void:
    # safety catches
    var children : Array[Node] = self.get_children();
    for c in children:
        if (c is NinePatchRect):
            focus_background = c;
    
    assert(ja_button != null, "Button must exist");
    assert(en_button != null, "Lang Toggle requires 2 buttons");
    assert(focus_background != null, "Focus background required");
    
    if (button_flow_handler == null):
        var parent : Control = self.get_parent();
        while (not parent is Options):
            parent = parent.get_parent();
        button_flow_handler = parent;

    var radio_group : ButtonGroup = ButtonGroup.new();
    radio_group.allow_unpress = false;
    ja_button.toggle_mode = true;
    ja_button.button_pressed = true;
    ja_button.button_group = radio_group;
    en_button.toggle_mode = true;
    en_button.button_group = radio_group;

    self.mouse_entered.connect(_on_mouse_entered);
    self.mouse_exited.connect(_on_mouse_exited);
    button_flow_handler.hover_removed.connect(_on_no_hover);

    focus_background.visible = false;
    Statics.debug_log("where is focus bg: {0}, visible? {1}".format([focus_background.name, focus_background.visible]));
