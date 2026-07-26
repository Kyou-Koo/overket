class_name Level extends Node3D

@export_category("Level Objects")
@export var spawn_points : Array[MeshInstance3D];
@export var exit_area : MeshInstance3D;
@export var exit_bounds : Vector2 = Vector2(5.0, 7.6);
var goals : Dictionary[String, Vector3];
@export var player_scene_path : String;
var player_packed : PackedScene;
var players : Array[PlayerController];
@export var customer_scene_path : String;
var customer_packed : PackedScene;
var customers : Array[Customer];
@export var customer_parent : Node3D;
@export var delivery_points : Array[DeliveryPoint];
@export_category("UI")
@export var ui_parent : Control;
@export var level_ui : LevelUI;
@export var options_path : String;
@export var game_over : Control;
## in seconds
@export var level_duration : int = 300;
@onready var level_remain_time : float = level_duration as float;
@export var countdown_timer : Label;
@export_category("Level Config")
@export var customer_z_line : float = 4.05;
@export var customer_max : int = 20;
@export var countdown_length : float = 5.0;
var countdown_finished : bool = false;
var money : int;
var options_packed : PackedScene;
var options_scene : Options;
var requests : Array[Request]; 

@export_range(0.0, 1.0) var passerby_chance : float = 0.3;
@export_range(0, 10.0) var customer_spawn_gap : float = 1.0;
@export_range(0, 5.0) var customer_spawn_variance : float = 1.5;
@onready var time_to_customer : float = randf_range(0, customer_spawn_variance);
var next_spawn_gap : float = 0.5;

# TODO: 
# player spawning
# test code lmao
# gameover + score screen
# customer limit?
signal reassign_saikoubi(customer : Customer, prev_goal : Vector3);

# TODO: consider reassigning to customer linked list class
func _on_customer_leaving(cus : Customer) -> void:
    return;
    # TODO: move respective goals up (using customer list)

func _on_customer_reached_goal(cus : Customer) -> void:
    # for debugging
    var matched_dp : DeliveryPoint;
    for dp : DeliveryPoint in delivery_points:
        if (dp.ok_id == cus.goal_ok_id):
            dp.customers.append(cus);
            matched_dp = dp;
            break;
    Statics.debug_log("customer {0} reached {2} w/ {1} request".format([cus.name, 
        cus.request, matched_dp.ok_id]));
    var created_request : Request = level_ui.add_request(cus.request, cus);
    if (created_request != null):
        requests.append(created_request);
        created_request.failed.connect(_on_request_failed);

    # TODO: this should apply to all new customers
    # TODO: customer reaching goal should move the actual level goals

func _on_customer_reached_exit(cus : Customer) -> void:
    var i : int = customers.find(cus);
    if (i != -1):
        customers.remove_at(i);
        Statics.debug_log("cus {0} reached exit".format([cus.name]))
    cus.queue_free();

func _on_request_failed(cus : Customer) -> void:
    var outgoing_request : Request;
    for r : Request in requests:
        if (r.from_who == cus):
            outgoing_request = r;
            break;
    requests.erase(outgoing_request);
    cus.request_failed = true;

func _on_dp_request_matched(cus : Customer) -> void:
    cus.request_received = true;
    for r : Request in requests:
        if (r.from_who == cus):
            r.completed = true;
            break;
    if (randf() > 0.5):
        # reassign exit
        cus.exit = get_point_in_mesh(exit_area);

func get_point_in_mesh(mi : MeshInstance3D) -> Vector3:
    var mesh_size_half : Vector3 = (mi.mesh as BoxMesh).size / 2.0;
    var max_bound : Vector2 = Statics.vec3_to_vec2(mi.global_position) + Statics.vec3_to_vec2(mesh_size_half);
    var min_bound : Vector2 = Statics.vec3_to_vec2(mi.global_position) - Statics.vec3_to_vec2(mesh_size_half);
    return Vector3(randf_range(min_bound.x, max_bound.x), 0.0, 
        randf_range(min_bound.y, max_bound.y));

func modify_customer_goal(in_vec : Vector3) -> Vector3:
    var mod : Vector3 = Vector3(randf_range(0, 0.4), 0, randf_range(0, 0.4));
    return mod + in_vec;

func spawn_customer() -> void:
    if (customers.size() >= customer_max): return;
    var spawn_mesh : MeshInstance3D = (Statics.rand_from_arr_o(spawn_points) as MeshInstance3D);
    var remaining_spawns : Array[MeshInstance3D] = spawn_points.duplicate();
    remaining_spawns.erase(spawn_mesh);
    var mesh_size_half : Vector3 = (spawn_mesh.mesh as BoxMesh).size / 2.0;
    var max_bound : Vector2 = Statics.vec3_to_vec2(spawn_mesh.global_position) + Statics.vec3_to_vec2(mesh_size_half);
    var min_bound : Vector2 = Statics.vec3_to_vec2(spawn_mesh.global_position) - Statics.vec3_to_vec2(mesh_size_half);
    var spawn_pos : Vector3 = Vector3(randf_range(min_bound.x, max_bound.x), 0.0,
        randf_range(min_bound.y, max_bound.y));
    var goal_ok_id : StringName = Statics.rand_from_arr_v(goals.keys());
    var target_goal : Vector3 = goals[goal_ok_id];
    var exit_goal : Vector3 = (Statics.rand_from_arr_o(remaining_spawns) as MeshInstance3D).global_position;
    
    var new_customer : Customer = customer_packed.instantiate();
    # calc chance of being passerby
    if (randf() < passerby_chance):
        Statics.debug_log("passerby generated");
        target_goal = exit_goal;
        new_customer.is_passerby = true;
    else: 
        # only have customers going to purchase show up in the customer array
        customers.append(new_customer);
    new_customer.goal = modify_customer_goal(target_goal);
    new_customer.goal_ok_id = goal_ok_id;
    new_customer.exit = exit_goal;
    new_customer.level3d_parent = self;
    customer_parent.add_child(new_customer);
    new_customer.global_position = spawn_pos;
    new_customer.goal_reached.connect(_on_customer_reached_goal);
    new_customer.exit_reached.connect(_on_customer_reached_exit);
    new_customer.leaving_goal.connect(_on_customer_leaving);
    new_customer.initiate();

func _input(event: InputEvent) -> void:
    if (event.is_action_pressed(&"start")):
        # TODO: OK now what
        var opt : Options = options_packed.instantiate();
        # TODO: create a slightly different options scene
        ui_parent.add_child(opt);
        get_tree().paused = true;
    
func _process(delta: float) -> void:
    if (countdown_finished):
        # update timer
        level_remain_time -= delta;
        if (level_remain_time < 0.0): 
            level_remain_time = 0.0;
            # TODO: hook up and spawn game over screen;
            get_tree().paused = true;
        # customer spawn timing
        time_to_customer -= delta;
        if (time_to_customer <= 0.0):
            spawn_customer();
            time_to_customer = customer_spawn_gap + randf_range(-customer_spawn_variance, customer_spawn_variance);
    else:
        countdown_timer.text = str(ceili(countdown_length));
        countdown_length -= delta;
        if (countdown_length < 0.0):
            countdown_timer.visible = false;
            countdown_finished = true;
    
func _ready() -> void:
    #get_window().content_scale_factor = 0.67;
    #get_window().position = Vector2i(100, 100);
    #get_viewport().get_window().content_scale_size = Vector2i(1280,720);
    #get_viewport().get_window().size = Vector2i(1280, 720);
    assert(customer_parent != null, "customer parent must be assigned");
    player_packed = load(player_scene_path);
    customer_packed = load(customer_scene_path);
    options_packed = load(options_path);
    for dp : DeliveryPoint in delivery_points:
        goals[dp.ok_id] = dp.goal.global_position;
        dp.request_matched.connect(_on_dp_request_matched);
