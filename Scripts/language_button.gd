extends Button

@export var parent_control : Control;
@export_group("Textures", "texture_")
@export var texture_underline : Control;
@export var texture_hover : Control;
@export var texture_select_left : Control;
@export var texture_select_right: Control;

@export var vertical_offset : int = -8;
@export var horizonal_offset : int = 16;
## 1:x ratio for how wide the underline should be
@export_range(0, 1.0, 0.05) var underline_width : float = 0.8;
var is_focused : bool = false;

func position_underline() -> void:
    # LMAO: im intelligent really y is definitely used for width /s
    var text_width : float = self.size.x;
    texture_underline.size = Vector2(text_width * underline_width, texture_underline.size.y);
    texture_underline.position = Vector2(text_width * ((1 - underline_width)/2), texture_underline.position.y);

func _on_focus_entered() -> void:
    if (!parent_control.button_flow_handler.is_active):
        return;
    texture_underline.visible = true;
    parent_control.focus_background.visible = true;

func _on_focus_exited() -> void:
    if (!parent_control.button_flow_handler.is_active):
        return;
    texture_underline.visible = false;

func _on_mouse_entered() -> void:
    if (!parent_control.button_flow_handler.is_active):
        return;
    # Statics.debug_log("i am hovered {0}".format([self.name]));
    texture_underline.visible = true;

func _on_mouse_exited() -> void:
    if (!parent_control.button_flow_handler.is_active):
        return;
    texture_underline.visible = false;

func _on_toggle(is_active : bool) -> void:
    if (!parent_control.button_flow_handler.is_active):
        return;
    texture_select_left.visible = is_active;
    texture_select_right.visible = is_active;
    if (is_active): parent_control.public_set_active_button(self);

func _on_child_set_active(b : Button) -> void:
    if (!parent_control.button_flow_handler.is_active):
        return;
    texture_select_left.visible = (b == self);
    texture_select_right.visible = (b == self);

func _ready() -> void:
    if (parent_control == null):
        # naive search
        parent_control = self.get_parent();

    assert(texture_underline != null, "{0} must have underline texture".format([self.name]));
    position_underline();
    texture_underline.visible = false;
    assert(texture_select_left != null, "{0} must have left texture".format([self.name]));
    texture_select_left.position = Vector2(-(texture_select_left.size.x * texture_select_left.scale.x) - horizonal_offset, vertical_icon_alignment);
    texture_select_left.visible = false;
    assert(texture_select_right != null, "{0} must have right texture".format([self.name]));
    texture_select_right.position = Vector2(self.size.x + horizonal_offset, vertical_icon_alignment);
    texture_select_right.visible = false;
    assert(texture_hover != null, "{0} must have hover texture".format([self.name]));
    #TODO: position texture

    texture_hover.visible = false;

    self.focus_entered.connect(_on_focus_entered);
    self.focus_exited.connect(_on_focus_exited);
    self.mouse_entered.connect(_on_mouse_entered);
    self.mouse_exited.connect(_on_mouse_exited);
    self.toggled.connect(_on_toggle);
    parent_control.child_set_active.connect(_on_child_set_active)
