class_name Request extends NinePatchRect

@export var countdown_timer : TextureProgressBar;
@export var bound_good : float = 0.66;
@export var color_good : Color = Color(0.2, 0.8 , 0.3);
@export var bound_warn : float = 0.33;
@export var color_warn : Color = Color(0.8, 0.8, 0.2);
@export var color_danger : Color = Color(0.8, 0.2, 0.3);
@export var request_item_holder : Control;
@export var request_item_grid : Array[Vector2] = [
    Vector2(0.0, 0.0), Vector2(130.0, 0.0),
    Vector2(0.0, 130.0), Vector2(130.0, 130.0)
]
var full_request : int;
var request_items : Array[RequestItem];
var tint : Color = Color.WHITE;
var parent_level : LevelUI;
var tween_position : Tween;
var tween_x : Tween;
var killed : bool = false;
var completed : bool = false;
var worth : int;
var pct_remain : float;
# in seconds
@export var start_duration : float = 10.0;
@onready var remaining_time : float = start_duration;
var animate_duration : float = 0.5;
var window_width : float = 1920.0;
var window_height : float = 1080.0;
# this bum is in ms
@onready var initialized_time : int = Time.get_ticks_msec();

signal anim_x_done();
signal failed();

func position_request_items(incoming_request : int) -> void:
    full_request = incoming_request;
    var request_list : Array[CarryableObjects.CarryObjEnum] = CarryableObjects.deserialize_objects(incoming_request);
    worth = CarryableObjects.calc_value(request_list);
    Statics.debug_log("{0} is worth {1}".format([self.name, worth]));
    # display desired items
    # 1 2
    # 3 4
    var idx : int = 0;
    for r : CarryableObjects.CarryObjEnum in request_list:
        for ri : RequestItem in request_items:
            if (ri.type == r):
                ri.position = request_item_grid[idx];
                ri.visible = true;
                idx += 1;
                
func animate_in() -> void:
    tween_position = get_tree().create_tween();
    tween_position.set_ease(Tween.EASE_OUT);
    tween_position.set_trans(Tween.TRANS_BACK);
    tween_position.tween_property(self, "position:y", -self.size.y + 50.0, animate_duration);
    
func animate_out() -> void:
    if (tween_position): tween_position.kill();
    tween_position = get_tree().create_tween();
    tween_position.set_ease(Tween.EASE_IN);
    tween_position.set_trans(Tween.TRANS_BACK);
    tween_position.tween_property(self, "position:y", 0.0, animate_duration);
    tween_position.tween_callback(parent_level.remove_request.bind(self));

func animate_x_to(amount_x : float) -> void:
    if (tween_x): 
        tween_x.kill();
    tween_x = get_tree().create_tween();
    tween_x.set_ease(Tween.EASE_OUT);
    tween_x.set_trans(Tween.TRANS_CUBIC);
    tween_x.tween_property(self, "position:x", amount_x, animate_duration/2.0);
    tween_x.tween_callback(anim_x_done.emit);

func update_pos_by_amount(amount_x : float) -> void:
    if (tween_x): 
        tween_x.kill();
    tween_x = get_tree().create_tween();
    tween_x.set_ease(Tween.EASE_OUT);
    tween_x.set_trans(Tween.TRANS_CUBIC);
    tween_x.tween_property(self, "position:x", self.position.x + amount_x, animate_duration/2.0);
    tween_x.tween_callback(anim_x_done.emit);

func calc_percentage(time_left : float) -> float:
    return (time_left / start_duration);
    
func _process(delta: float) -> void:
    pct_remain = calc_percentage(remaining_time);
    if (remaining_time < 0.0 and !killed):
        animate_out();
        # TODO: call sfx manager for fail sfx
        killed = true;
    if (completed and !killed):
        animate_out();
        # TODO: call sfx manager for complete sfx
        killed = true;
    elif (Time.get_ticks_msec() - initialized_time)/1000.0 > animate_duration:
        remaining_time -= delta;
        pct_remain = calc_percentage(remaining_time);
        countdown_timer.value = (pct_remain * 78.0) + 22.0;
        Statics.debug_prolog("time left {0}".format([pct_remain]));
    if (pct_remain > bound_good):
        countdown_timer.tint_progress = color_good;
        countdown_timer.tint_under = color_good * 0.5;
    elif (pct_remain > bound_warn):
        countdown_timer.tint_progress = color_warn;
        countdown_timer.tint_under = color_warn * 0.5;
    else:
        countdown_timer.tint_progress = color_danger
        countdown_timer.tint_under = color_danger * 0.5;
    countdown_timer.tint_under.a = 1.0;
    

func _ready() -> void:
    countdown_timer.value = countdown_timer.max_value;
    countdown_timer.tint_progress = color_good;
    countdown_timer.tint_under = color_good * 0.5;
    countdown_timer.tint_under.a = 1.0;
    for c in request_item_holder.get_children():
        if (c is RequestItem):
            request_items.append(c);
            c.visible = false;
