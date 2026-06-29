@tool
## A button used for cycling between textures on button press.
##
## Useful for things like mute/unmute switches, etc.
class_name StateToggleButton extends BaseButton

@export_group("Editor Options (EDITOR ONLY)", "editor_")
@export var editor_view_drawmode : DrawMode = DrawMode.DRAW_NORMAL:
    set(value):
        editor_view_drawmode = value;
        queue_redraw();
@export var editor_view_state : int = 0:
    set(value):
        if (value < 0):
            value = 0;
        editor_view_state = value;
        queue_redraw();
@export var editor_outine_color : Color = Color(0.627, 0.337, 0.588):
    set(value):
        editor_outine_color = value;
        queue_redraw();

## Number of states to cycle through on click 
## (this is different from Normal/Pressed/Hover/Disabled/Focused)
##
## NOTE: the number of textures in each texture array should match this value
@export var button_state_count : int = 2;
@export var texture_click_map : BitMap;
# TODO: eventually this should be ExpandMode? maybe????
# TODO: should probably have individual true/false flags for all textures of every button
# i.e. 
#   {
#       "state1": {
#           "normal": false,
#           "pressed": false,
#           "hover": false,
#           "disabled": false,
#           "focused": false,
#       },
#     ...etc
#   }
@export var ignore_texture_sizes : Array[bool] = [false, false];

## supply Custom transforms on each texture used in the button
@export_group("Texture Transforms", "t_transforms_")
@export var t_transforms_size : Array[Vector2];
@export var t_transforms_position : Array[Vector2]; 
@export_range(-180, 180, 0.1, "degrees") var t_transforms_rotation_degrees : Array[float];
# TODO: override move, rotate, scale gizmo for each individual texture
@export var t_transforms_scale : Array[Vector2] = [Vector2(1.0, 1.0)];
# TODO: calculate and set based on above ⇑
@onready var textures_sizes : Array[Transform2D];

@export_group("Textures", "textures_")
@export var textures_normal : Array[Texture2D]:
    set(values):
        textures_normal = values;
        queue_redraw();
@export var textures_pressed : Array[Texture2D]:
    set(values):
        textures_pressed = values;
        queue_redraw();
@export var textures_hover : Array[Texture2D]:
    set(values):
        textures_hover = values;
        queue_redraw();
@export var textures_disabled : Array[Texture2D]:
    set(values):
        textures_disabled = values;
        queue_redraw();
@export var textures_focused : Array[Texture2D]:
    set(values):
        textures_focused = values;
        queue_redraw();

# TODO: these are probably unused
var active_disable_texture : Texture2D;
var active_focused_texture : Texture2D;
var active_hover_texture : Texture2D;
var active_normal_texture : Texture2D;
var active_pressed_texture : Texture2D;

var game_draw_mode : DrawMode;
# NOTE: serves the same purpose as editor_view_state but for code usage
var button_curr_state : int = 0;

var _validate_texture_arrays := func() -> void:
    assert(ignore_texture_sizes.size() == button_state_count, "Ignore texture sizes array mismatch");
    if (textures_normal.size() > 0):
        assert(textures_normal.size() == button_state_count, "Normal texture array mismatch");
    if (textures_disabled.size() > 0):
        assert(textures_disabled.size() == button_state_count, "Disable texture array mismatch");
    if (textures_focused.size() > 0):
        assert(textures_focused.size() == button_state_count, "Focused texture array mismatch");
    if (textures_hover.size() > 0):
        assert(textures_hover.size() == button_state_count, "Hover textures array mismatch");
    if (textures_pressed.size() > 0):
        assert(textures_pressed.size() == button_state_count, "Pressed texture array mismatch");

#region Button texture drawing
# TODO: this is unnecessary at this point
func _draw_bounding_rect(t : Texture2D) -> void:
    var t_size : Vector2 = t.get_size();
    var t_rect : Rect2 = Rect2(Vector2.ZERO, t_size);
    draw_rect(t_rect, editor_outine_color, false, 1.0, false);

func _draw() -> void:
    if (Engine.is_editor_hint()):
        if (editor_view_state > button_state_count - 1): editor_view_state = button_state_count - 1;
        var curr_texture : Texture2D;
        match editor_view_drawmode:
            DrawMode.DRAW_NORMAL:
                draw_texture(textures_normal[editor_view_state], Vector2());
                curr_texture = textures_normal[editor_view_state];
            DrawMode.DRAW_PRESSED:
                draw_texture(textures_pressed[editor_view_state], Vector2());
                curr_texture = textures_pressed[editor_view_state];
            DrawMode.DRAW_HOVER:
                draw_texture(textures_hover[editor_view_state], Vector2());
                curr_texture = textures_hover[editor_view_state];
            DrawMode.DRAW_DISABLED:
                draw_texture(textures_disabled[editor_view_state], Vector2());
                curr_texture = textures_disabled[editor_view_state];
            _:
                # I dont like this but draw mode doesn't have draw focused for some reason ????
                # HACK: what.... is hover_pressed supposed to be anyways?
                draw_texture(textures_focused[editor_view_state], Vector2());
                curr_texture = textures_focused[editor_view_state];
        _draw_bounding_rect(curr_texture);
        # adjust size here to redraw bounds based on image size
        if (!ignore_texture_sizes[0]):
            self.size = curr_texture.get_size();
    else:
        # TODO: runtime code.
        pass;
#endregion

func _on_button_down() -> void:
    pass;

func _on_button_up() -> void:
    pass;

func _on_pressed() -> void:
    pass;

func _on_toggled(toggled_on : bool) -> void:
    if (!self.toggle_mode):
        return;

func _init() -> void:
    _validate_texture_arrays.call();

    self.button_down.connect(_on_button_down);
    self.button_up.connect(_on_button_up);
    self.pressed.connect(_on_pressed);
    self.toggled.connect(_on_toggled);
