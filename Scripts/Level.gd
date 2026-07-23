class_name Level extends Node3D

@export_category("Level Objects")
@export var spawn_points : Array[MeshInstance3D];
@export var exit_area : MeshInstance3D;
@export var goal_markers : Array[Marker3D];
var goals : Array[Vector3];
@export var player_scene_path : String;
var player_packed : PackedScene;
var players : Array[PlayerController];
@export var customer_scene_path : String;
var customer_packed : PackedScene;
var customers : Array[Customer];
@export var customer_parent : Node3D;
# TODO: not a table but based on a table;
@export var delivery_points : Array[Table];
@export_category("UI")
@export var ui_parent : Control;
@export var options_path : String;
@export var game_over : Control;
## in seconds
@export var level_duration : int = 300;
@onready var level_remain_time : float = level_duration as float;
@export var countdown_timer : Label;
@export_category("Level Config")
@export var countdown_length : float = 5.0;
var countdown_finished : bool = false;
var money : int;
var options_packed : PackedScene;
var options_scene : Options;
var requests : Array[CarryableObjectBase]; 
var request_panels : Array # TODO: array of request types

@export_range(0.0, 1.0) var passerby_chance : float = 0.3;
@export_range(0, 10.0) var customer_spawn_gap : float = 4.0;
@export_range(0, 5.0) var customer_spawn_variance : float = 1.5;
@onready var time_to_customer : float = randf_range(0, customer_spawn_variance);
var next_spawn_gap : float = 0.5;

# TODO: 
# player spawning
# test code lmao
# gameover + score screen
# how often to spawn customer
# customer limit?
# delay start
signal reassign_saikoubi(customer : Customer);

func _on_customer_reached_goal(cus : Customer) -> void:
    if (customers.size() > 0):
        for c : Customer in customers:
            if (c != cus):
                c.goal = cus.behind_me.position;
    Statics.debug_log("customer {0} reached w/ {1} request".format([cus.name, cus.request]));
    requests.append(cus.request);
    reassign_saikoubi.emit(cus);

func _on_customer_reached_exit(cus : Customer) -> void:
    var i : int = customers.find(cus);
    if (i != -1):
        customers.remove_at(i);
    cus.queue_free();

func check_customer_request_match() -> void:
    for dp in delivery_points:
        if (true): # if dp.customer.request matches dp.placed_item
            # dp.customer.request_recieved = true;
            if (randf() > 0.5):
                # reassign exit
                var new_exit : Vector3 = get_point_in_mesh(exit_area);
                # dp.customer.exit = new_exit
            break;

func get_point_in_mesh(mi : MeshInstance3D) -> Vector3:
    var mesh_size_half : Vector3 = (mi.mesh as BoxMesh).size / 2.0;
    var max_bound : Vector2 = Statics.vec3_to_vec2(mi.global_position) + Statics.vec3_to_vec2(mesh_size_half);
    var min_bound : Vector2 = Statics.vec3_to_vec2(mi.global_position) - Statics.vec3_to_vec2(mesh_size_half);
    return Vector3(randf_range(min_bound.x, max_bound.x), 0.0, 
        randf_range(min_bound.y, max_bound.y));

func spawn_customer() -> void:
    var spawn_mesh : MeshInstance3D = (Statics.rand_from_arr_o(spawn_points) as MeshInstance3D);
    var remaining_spawns : Array[MeshInstance3D] = spawn_points.duplicate();
    remaining_spawns.erase(spawn_mesh);
    var mesh_size_half : Vector3 = (spawn_mesh.mesh as BoxMesh).size / 2.0;
    var max_bound : Vector2 = Statics.vec3_to_vec2(spawn_mesh.global_position) + Statics.vec3_to_vec2(mesh_size_half);
    var min_bound : Vector2 = Statics.vec3_to_vec2(spawn_mesh.global_position) - Statics.vec3_to_vec2(mesh_size_half);
    var spawn_pos : Vector3 = Vector3(randf_range(min_bound.x, max_bound.x), 0.0,
        randf_range(min_bound.y, max_bound.y));
    var target_goal : Vector3 = Statics.rand_from_arr_v(goals);
    var exit_goal : Vector3 = (Statics.rand_from_arr_o(remaining_spawns) as MeshInstance3D).global_position;
    
    var new_customer : Customer = customer_packed.instantiate();
    # calc chance of being passerby
    if (randf() < passerby_chance):
        Statics.debug_log("passerby generated");
        target_goal = exit_goal;
        new_customer.is_passerby = true;
    new_customer.global_position = spawn_pos;
    new_customer.goal = target_goal;
    new_customer.exit = exit_goal;
    new_customer.level3d_parent = self;
    new_customer.goal_reached.connect(_on_customer_reached_goal);
    new_customer.exit_reached.connect(_on_customer_reached_exit);
    new_customer.initiate();
    
    customer_parent.add_child(new_customer);

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
    for gm : Marker3D in goal_markers:
        goals.append(gm.global_position);
