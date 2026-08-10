class_name Level extends Node3D

@export_category("Level Objects")
@export var camera : Camera3D;
@export var spawn_points : Array[MeshInstance3D];
@export var exit_area : MeshInstance3D;
@export var exit_bounds : Vector2 = Vector2(5.0, 7.6);
var goals : Dictionary[String, Vector3];
var player_packed : PackedScene;
var players : Array[PlayerController];
@export var player_spawn_parent : Node3D;
var player_spawn_points : Array[Marker3D];
@export var player_parent : Node3D;
var customer_packed : PackedScene;
var customers : Array[Customer];
@export var customer_parent : Node3D;
@export var delivery_points : Array[DeliveryPoint];
@export var misc_object_parent : Node3D;
@export_category("UI")
@export var ui_parent : Control;
@export var level_ui : LevelUI;
@export var pause_parent : CanvasLayer;
@export var pause_menu : PauseMenu;
@export var game_over : GameOver;
## in seconds
@export var level_duration : int = 300;
@onready var level_remain_time : float = level_duration as float;
@export var countdown_timer : Label;
@export_category("Level Config")
@export var customer_z_line : float = 4.05;
@export var customer_max : int = 20;
@export var countdown_length : float = 5.0;
var countdown_finished : bool = false;
var money : int = 0;
var requests : Array[Request]; 
var is_paused : bool = false;
var should_spawn_customers : bool = true;
var triggered_game_end_soon_music : bool = false;
var game_ended : bool = false;

@export_range(0.0, 1.0) var passerby_chance : float = 0.3;
@export_range(0, 10.0) var customer_spawn_gap : float = 1.0;
@export_range(0, 5.0) var customer_spawn_variance : float = 1.5;
@onready var time_to_customer : float = randf_range(0, customer_spawn_variance);
var next_spawn_gap : float = 0.5;

# TODO: 
# test code lmao
# gameover + score screen
signal reassign_saikoubi(customer : Customer, prev_goal : Vector3);

func set_up() -> void:
    camera.make_current();
    for p_idx : int in range(4):
        if (GameManager._instance.active_players[p_idx]):
            var new_p : PlayerController = player_packed.instantiate();
            new_p.player_prefix = "p{0}".format([p_idx+1]);
            new_p.scene_obj_holder = misc_object_parent;
            player_parent.add_child(new_p);
            new_p.set_up(
                GameManager._instance.player_head_face[p_idx][0],
                GameManager._instance.player_head_face[p_idx][1],
                GameManager._instance.player_colors[p_idx]);
            new_p.global_position = player_spawn_points[p_idx].global_position;
    AudioManager._instance.fade_specific_BGM(AudioFiles.MENU_KEY, true);
    AudioManager._instance.stop_specific_BGM(AudioFiles.MENU_KEY);
    AudioManager._instance.play_BGM(AudioFiles.GAME_KEY, AudioFiles.GAME_BGM, AudioFiles.GAME_BGM);

func clean_up_and_return_to_menu() -> void:
    should_spawn_customers = false;
    # queuefreeing everything pre-returning to menu does something funny
    # don't do that!!
    get_viewport().get_tree().paused = false;
    AudioManager._instance.stop_all_SFX();
    AudioManager._instance.stop_all_BGM();
    #TODO: push score to save file
    GameManager._instance.end_level();

# TODO: consider reassigning to customer linked list class
# push this off to later
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
    # Statics.debug_log("customer {0} reached {2} w/ {1} request".format([cus.name, 
        # cus.request, matched_dp.ok_id]));
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
    if (!should_spawn_customers): return;
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
    if (!GameManager._instance.in_menu and event.is_action_pressed(&"start") and !is_paused):
        pause_menu.activate();
        is_paused = true;
        get_tree().paused = true;
    #if ((is_paused and pause_parent != null) or
    #(level_remain_time <= 0.0 and game_ended)):
        #pause_parent.push_input(event);
    # TODO: remove debug key
    if (event.as_text() == "Z" and !event.is_echo()):
        game_over.activate(money);
    
func _process(delta: float) -> void:
    if (countdown_finished):
        # update timer
        level_remain_time -= delta;
        if (level_remain_time <= 12.0 and !triggered_game_end_soon_music):
            AudioManager._instance.fade_all_BGM();
            AudioManager._instance.play_SFX(AudioFiles.GAME_END_SOON);
            AudioManager._instance.stop_all_BGM();
            triggered_game_end_soon_music = true;
        if (level_remain_time <= 0.0 and !game_ended): 
            level_remain_time = 0.0;
            get_tree().paused = true;
            game_over.activate(money);
            game_ended = true;
            level_ui.visible = false;
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
    assert(player_spawn_parent != null, "assign spawn parent");
    for psp : Marker3D in player_spawn_parent.get_children():
        player_spawn_points.append(psp);
    assert(pause_parent != null, "pause needs a unique canvaslayer");
    assert(pause_menu != null, "assign pause menu");
    pause_menu.visible = false;
    assert(game_over != null, "assign game over");
    game_over.visible = false;
    assert(player_parent != null, "player parent must be assigned");
    assert(customer_parent != null, "customer parent must be assigned");
    player_packed = preload("res://Resources/player.tscn");
    customer_packed = preload("res://Resources/customer.tscn");
    for dp : DeliveryPoint in delivery_points:
        goals[dp.ok_id] = dp.goal.global_position;
        dp.request_matched.connect(_on_dp_request_matched);
    assert(misc_object_parent != null, "must assign parent for carryable objects");
    #set_up();
