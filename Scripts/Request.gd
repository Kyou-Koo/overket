class_name Request extends NinePatchRect

@export var countdown_timer : TextureProgressBar;
@export var request_item_holder : Control;
@export var request_item_spacing : float = 120.0;
var request_items : Array[RequestItem];
var tint : Color = Color.WHITE;
var parent_level : LevelUI; # TODO: levelUI
var tween_position : Tween;
var tween_opacity : Tween;
# in seconds
var start_duration : float = 10.0;
@onready var remaining_time : float = start_duration;
var animate_duration : float = 1.0;
var window_width : float = 1920.0;
var window_height : float = 1080.0;
# this bum is in ms
@onready var initialized_time : int = Time.get_ticks_msec();

func position_request_items(full_request : int) -> void:
    var request_list : Array[CarryableObjects.CarryObjEnum] = CarryableObjects.deserialize_objects(full_request);
    # display desired items
    var start_x : float = 0.0;
    for r : CarryableObjects.CarryObjEnum in request_list:
        for ri : RequestItem in request_items:
            if (ri.type == r):
                ri.position = Vector2(start_x, ri.y_adjust);
                ri.visible = true;
                start_x += request_item_spacing;
                
func animate_in() -> void:
    tween_position = get_tree().create_tween();
    tween_position.set_ease(Tween.EASE_OUT);
    tween_position.set_trans(Tween.TRANS_BACK);
    tween_position.tween_property(self, "position:x", window_width - self.size.x, animate_duration);
    
func animate_out() -> void:
    pass

func update_pos(new_y : float) -> void:
    tween_position = get_tree().create_tween();
    tween_position.set_ease(Tween.EASE_OUT);
    tween_position.set_trans(Tween.TRANS_CUBIC);
    tween_position.tween_property(self, "position:y", new_y, animate_duration/2.0);

func _process(delta: float) -> void:
    if (remaining_time < 0.0):
        animate_out();
        parent_level.remove_request(self);
    if (Time.get_ticks_msec() - initialized_time)/1000.0 > animate_duration:
        remaining_time -= delta;

func _ready() -> void:
    self.modulate.a = 0.0;
    self.position = Vector2(window_width, parent_level.request_y);
    for c in request_item_holder.get_children():
        if (c is RequestItem):
            request_items.append(c);
            c.visible = false;
