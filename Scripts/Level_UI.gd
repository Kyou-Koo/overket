class_name LevelUI extends Control

@export var debug_mode : bool = false;
@export var debug_time : int = 300;
var debug_money : int = 0;
var debug_time_f : float = debug_time as float;
@export var parent_3dlevel : Level;
var request_scn_pack : PackedScene;
var request_scns : Array[Request];
var request_scns_max : int = 6;
var request_x_start : float = 0.0;
# stores requests that need to be inserted
# !! please pop them off
var request_queue : Array[Request];
@export var queue_delay : float = 0.25;
var queue_last_used : float = 0;
# TODO: move to level itself?
var x_move_in_queue : bool = false;
@export var request_gap_x : float = (256.0 * 0.9) + 8.0;
var request_x_poses : Array[float];
@export var request_holder : Control;
@export var timer_holder : NinePatchRect;
@export var money_holder : NinePatchRect;
var timer_text : Label;
var money_text : Label;

# request order (display max 5 requests at once);
# 5 4 3 2 1
func add_request(what : int, who : Customer) -> Request:
    # Statics.debug_log("num requests up: {0}".format([request_scns.size()]));
    var new_request : Request = request_scn_pack.instantiate();
    new_request.visible = false;
    request_holder.add_child(new_request);
    new_request.position_request_items(what);
    # Statics.debug_log("what is request: {0}".format([what]));
    new_request.from_who = who;
    # queue request if too many
    if (x_move_in_queue or request_scns.size() >= request_scns_max):
        # Statics.debug_log("queueing because busy: {0}".format([x_move_in_queue]));
        request_queue.append(new_request);
        return new_request;
    # bump elders right
    move_ancestor_requests_right();
    request_scns.append(new_request);
    new_request.allow_start();
    new_request.visible = true;
    new_request.position = Vector2(request_x_start, 200.0);
    new_request.parent_level = self;
    new_request.anim_x_done.connect(_on_anim_x_done);
    new_request.animate_in();
    AudioManager._instance.play_SFX(AudioFiles.ORDER_UP);
    return new_request;

func add_queued_request(r : Request) -> void:
    move_ancestor_requests_right();
    request_scns.append(r);
    r.visible = true;
    r.allow_start();
    r.position = Vector2(request_x_start, 200.0);
    r.parent_level = self;
    r.anim_x_done.connect(_on_anim_x_done);
    r.animate_in();

func remove_request(r : Request) -> void:
    var order : int = request_scns.find(r);
    if (order == -1):
        return;
    var rm_x : float = request_scns[order].position.x;
    request_scns.remove_at(order);
    if (r.remaining_time > 0.0):
        var gain : int = r.worth;
        if (r.pct_remain < r.bound_good):
            gain = roundi(r.worth * r.pct_remain);
        if (debug_mode):
            debug_money += gain;
            update_money(debug_money);
        else:
            parent_3dlevel.money += gain;
            update_money(parent_3dlevel.money);
    r.queue_free();
    # move everything older to left
    if (order > 0):
        x_move_in_queue = true;
        for i : int in range(order-1, -1, -1):
            var my_x : float = request_scns[i].position.x;
            (request_scns[i] as Request).animate_x_to(rm_x);
            rm_x = my_x;

func move_ancestor_requests_right() -> void:
    # bump elders right
    var c_size : int = request_scns.size();
    if (c_size > 0):
        x_move_in_queue = true;
        for i : int in range(c_size):
            request_scns[i].animate_x_to(request_x_poses[i + request_scns_max - c_size - 1]);
            
func update_money(m : int) -> void:
    if (money_text): money_text.text = "￥{0}".format([m]);
    money_holder.size = Vector2(money_text.size.x + (money_holder.size.y / 2), money_holder.size.y);

func _on_anim_x_done() -> void:
    x_move_in_queue = false;
            
func _process(delta: float) -> void:
    queue_last_used += delta;
    if (!x_move_in_queue and request_queue.size() > 0 and 
    request_scns.size() < request_scns_max and queue_last_used > queue_delay):
        var queue_item : Request = request_queue.pop_front();
        add_queued_request(queue_item);
        queue_last_used = 0.0;
    # safety
    if (request_scns.size() == 0 and request_queue.size() == 0):
        #Statics.debug_prolog("!!!!!! serving {0} of {1}".format([request_scns.size(), request_queue.size()]))
        x_move_in_queue = false;
    # update timer
    if (debug_mode):
        debug_time_f -= delta;
        debug_time = roundi(debug_time_f);
        if (debug_time < 0): debug_time = 0;
        timer_text.text = Statics.time_sec_to_minsec(debug_time);
    else:
        timer_text.text = Statics.time_sec_to_minsec(roundi(parent_3dlevel.level_remain_time));

func _input(event: InputEvent) -> void:
    if (!debug_mode):
        return;
    # if (event is InputEventKey and event.is_pressed()):
    #     if (event.keycode == KEY_Z):
    #         var r : int = Statics.rand_from_arr_v(CarryableObjects.customer_requests)
    #         var c : Customer = Customer.new();
    #         c.ok_id = Statics.create_ok_id(c);
    #         add_request(r, c);
    #     if (event.keycode == KEY_X):
    #         if (request_scns.size() > 0):
    #             var remove_req : Request = request_scns[randi_range(0, request_scns.size()-1)];
    #             remove_req.completed = true;

func _ready() -> void:
    # safety:
    #debug_mode = Statics.DEBUG_MODE;
    for i : int in range(request_scns_max):
        request_x_poses.push_front(i * request_gap_x);
    request_scn_pack = preload("res://Resources/Request.tscn");
    timer_text = $TimeRemaining/Label;
    money_text = $Money/Label;
    if (!debug_mode):
        timer_text.text = Statics.time_sec_to_minsec(parent_3dlevel.level_duration);
        update_money(parent_3dlevel.money);
    else:
        update_money(debug_money);
        timer_text.text = Statics.time_sec_to_minsec(debug_time);
