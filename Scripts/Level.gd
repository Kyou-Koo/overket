class_name Level extends Node3D

@export_category("Level Objects")
@export var spawn_points : Array[MeshInstance3D];
@export var goal_markers : Array[Marker3D];
var goals : Array[Vector3];
@export var customer_scene_path : String;
var customer_packed : PackedScene;
var customers : Array[Customer];
@export var customer_parent : Node3D;
@export_category("UI")
@export var ui_parent : Control;
@export var options_path : String;
## in seconds
@export var level_duration : int = 300;
@onready var level_remain_time : float = level_duration as float;
var money : int;
var options_packed : PackedScene;
var options_scene : Options;
var requests : Array[CarryableObjectBase]; 
var request_panels : Array # TODO: array of request types

@export_range(0.0, 1.0) var passerby_chance : float = 0.3;

func _on_customer_reached_goal(cus : Customer) -> void:
    if (customers.size() > 0):
        for c : Customer in customers:
            if (c != cus):
                c.goal = cus.behind_me.position;
    requests.append(cus.request);

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
    # calc chance of being passerby
    if (randf() < passerby_chance):
        target_goal = exit_goal;
    
    var new_customer : Customer = customer_packed.instantiate();
    new_customer.global_position = spawn_pos;
    new_customer.goal = target_goal;
    new_customer.exit = exit_goal;
    new_customer.level_parent = self;
    new_customer.goal_reached.connect(_on_customer_reached_goal);
    
    customer_parent.add_child(new_customer);
    
func _process(delta: float) -> void:
    # update timer
    level_remain_time -= delta;
    if (level_remain_time < 0.0): level_remain_time = 0.0;
    
func _ready() -> void:
    assert(customer_parent != null, "customer parent must be assigned");
    customer_packed = load(customer_scene_path);
    options_packed = load(options_path);
