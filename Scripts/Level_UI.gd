class_name LevelUI extends Control

@export var debug_mode : bool = false;
@export var debug_time : int = 300;
var debug_time_f : float = debug_time as float;
@export var parent_3dlevel : Level;
@export var request_scn_path : String;
var request_scn_pack : PackedScene;
var request_scns : Array[Request];
var request_x : float = 0.0;
# TODO: move to level itself?
var deletion_in_queue : bool = false;
@export var request_gap_x : float = 256.0 + 8.0;
@export var request_holder : Control;
@export var timer_holder : NinePatchRect;
@export var money_holder : NinePatchRect;
var timer_text : Label;
var money_text : Label;

# request order (display max 5 requests at once);
# 5 4 3 2 1
# think about queueing requests up in a separate array
func add_request(what : int) -> void:
    # TODO: stall new request if request removal is in queue
    var new_request : Request = request_scn_pack.instantiate();
    # bump elders right
    if (request_scns.size() > 0):
        for r : Request in request_scns:
            r.update_pos_by_amount(request_gap_x);
    request_scns.append(new_request);
    request_holder.add_child(new_request);
    new_request.position = Vector2(request_x, 200.0);
    new_request.position_request_items(what);
    new_request.parent_level = self;
    new_request.animate_in();

func remove_request(r : Request) -> void:
    var order : int = request_scns.find(r);
    var rm_x : int = request_scns[order].position.x;
    request_scns.remove_at(order);
    r.queue_free();
    # move everything older to left
    #if (order > 0):
        #for i : int in range(order-1, -1, -1):
            #Statics.debug_log("removed {3} of {4} moving {0}[{1}] from {2}".format([
                #request_scns[i].name, i, request_scns[i].position.x, order, request_scns.size()
            #]));
            #(request_scns[i] as Request).update_pos_by_amount(-request_gap_x);
    if (order > 0):
        for i : int in range(order-1, -1, -1):
            var my_x : int= request_scns[i].position.x;
            (request_scns[i] as Request).animate_x_to(rm_x);
            rm_x = my_x;
            
func update_money(m : int) -> void:
    if (money_text): money_text.text = "￥{0}".format([m]);
            
func _process(delta: float) -> void:
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
    if (event is InputEventKey and event.is_pressed()):
        if (event.keycode == KEY_Z):
            var r : int = Statics.rand_from_arr_v(CarryableObjects.customer_requests)
            add_request(r);
        if (event.keycode == KEY_X):
            var remove_req : Request = request_scns[randi_range(0, request_scns.size()-1)];
            remove_req.completed = true;

func _ready() -> void:
    # DEBUG:
    get_window().content_scale_factor = 0.67;
    get_window().position = Vector2i(100, 100);
    get_viewport().get_window().content_scale_size = Vector2i(1280,720);
    get_viewport().get_window().size = Vector2i(1280, 720);
    # safety:
    debug_mode = Statics.DEBUG_MODE;
    request_scn_pack = load(request_scn_path);
    timer_text = $TimeRemaining/Label;
    money_text = $Money/Label;
    if (!debug_mode):
        timer_text.text = Statics.time_sec_to_minsec(parent_3dlevel.level_duration);
        update_money(parent_3dlevel.money);
    else:
        timer_text.text = Statics.time_sec_to_minsec(debug_time);
