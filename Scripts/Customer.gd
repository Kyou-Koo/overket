@tool
class_name Customer extends AnimatableBody3D

#region debugvars
@export_category("Debug")
@export var DEBUG_mode : bool = false;
@export var DEBUG_can_move : bool = false;
@export var goal_mesh_holder : MeshInstance3D;
var goal_dir_mesh : ImmediateMesh;
@export var goal_line_color : Color = Color(1, 0, 0):
    set(value):
        goal_line_color = value;
@export var adj_mesh_holder : MeshInstance3D;
var adj_dir_mesh : ImmediateMesh;
@export var adj_line_color : Color = Color(0.98, 0.43, 0.84):
    set(value):
        adj_line_color = value;
@export var comb_mesh_holder : MeshInstance3D;
var comb_dir_mesh : ImmediateMesh;
@export var comb_line_color : Color = Color(0, 0, 1):
    set(value):
        comb_line_color = value;
@export var test_neighbor : Array[Customer];
#endregion
@export_category("Actual")
@export_group("Sprites", "sprite")
@export var sprite_character_holder : Node3D;
@export var sprites_character : Array[Sprite3D];
@export var sprite_request_holder : Node3D;
@export var sprites_requests : Array[Sprite3D];
var active_sprite : Sprite3D;
@export var sprite_tint : Color = Color(1.0, 1.0, 1.0):
    set(value):
        sprite_tint = value;
        apply_tint();
@export_range(0.0, 10.0) var move_speed : float = 4.0;
@export var self_collider : CollisionShape3D;
var self_coll_radius : float;
@export var navigation_boundary : Area3D;
        
var level3d_parent : Level;
@onready var ok_id : String = Statics.create_ok_id(self);
var initialized : bool = false;
@export var goal : Vector3;
@export var exit : Vector3;
var at_goal : bool = false;
var at_exit : bool = false;
var is_passerby : bool = false;
var previous_dir : Vector2 = Vector2.ZERO;
var request : int;
var request_received : bool = false;
var request_sent : bool = false;
var nearby_characters : Dictionary[String, AnimatableBody3D];
var bounce_tween : Tween;
var mid_bounce : bool = false;
@export_range(0.0, 2.0) var movement_variance_max : float = 0.5;
@onready var movement_variance : float = randf_range(0.0, movement_variance_max);
@onready var desired_dist : float = randf_range(1.0, 3.0);
# TODO: randomly place this
@export var behind_me : Marker3D;

signal goal_reached(customer : Customer);
signal exit_reached(customer : Customer);

func apply_tint() -> void:
    if (!active_sprite):
        return;
    active_sprite.modulate = sprite_tint;
    
func reached_goal(g : Vector3) -> bool:
    return self.global_position.distance_to(g) < 0.1;

#region debug
func draw_debug_lines(m : ImmediateMesh, end_v3 : Vector3) -> void:
    m.surface_set_normal(Vector3.UP);
    m.surface_set_uv(Vector2(0,0));
    m.surface_add_vertex(Vector3.ZERO);
    m.surface_set_normal(Vector3.UP);
    m.surface_set_uv(Vector2(0,1));
    m.surface_add_vertex(end_v3);
    m.surface_end();
    
func start_debug_lines(a : Vector3, b : Vector3, c: Vector3) -> void:
    # # # DEBUG
    if (DEBUG_mode):
        if (goal_dir_mesh != null and adj_dir_mesh != null and comb_dir_mesh != null):
            goal_dir_mesh.clear_surfaces();
            adj_dir_mesh.clear_surfaces();
            comb_dir_mesh.clear_surfaces();
            goal_dir_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP);
            adj_dir_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP);
            comb_dir_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP);
            goal_dir_mesh.surface_set_color(goal_line_color);
            adj_dir_mesh.surface_set_color(adj_line_color);
            draw_debug_lines(goal_dir_mesh, a);
            draw_debug_lines(adj_dir_mesh, b);
            comb_dir_mesh.surface_set_color(comb_line_color);
            draw_debug_lines(comb_dir_mesh, c);
#endregion
    
func navigate(objective : Vector3) -> Vector3:
    if (DEBUG_mode):
        if (!DEBUG_can_move):
            move_speed = 0.0;
        else:
            move_speed = 0.5;
    if (!initialized and !DEBUG_mode):
        return Vector3.ZERO;
    bounce_animation();
    # desire path
    var goal_direction : Vector3 = calc_direction_to_goal(objective);
    if (previous_dir == Vector2.ZERO):
        previous_dir = Statics.vec3_to_vec2(goal_direction);
    # adjust based on nearby others
    var direction_adjust : Vector3 = Vector3.ZERO;
    #Statics.debug_prolog("nearby {0}".format([str(nearby_characters)]));
    var other_pos_average : Vector3 = Vector3.ZERO;
    for key in nearby_characters:
        var other_pos : Vector3 = nearby_characters[key].position;
        other_pos_average += other_pos;
        var dist : float = self.position.distance_to(other_pos);
        var strength : float = maxf(desired_dist - dist, 0.0) / (desired_dist - (self_coll_radius));
        var nav_from_other : Vector3 = -self.position.direction_to(other_pos);
        var local_adjust_vector : Vector3 = goal_direction.slerp(nav_from_other, strength);
        direction_adjust += local_adjust_vector;
#region debug2
    if (test_neighbor.size() > 0 and DEBUG_mode):
        for tn : Customer in test_neighbor:
            var other_pos : Vector3 = tn.global_position;
            other_pos_average += other_pos;
            var dist : float = self.position.distance_to(other_pos);
            var strength : float = maxf(desired_dist - dist, 0.0) / (desired_dist - (self_coll_radius * 2));
            var nav_from_other : Vector3 = -self.global_position.direction_to(other_pos);
            var local_adjust_vector : Vector3 = goal_direction.slerp(nav_from_other, strength);
            direction_adjust += local_adjust_vector;
#endregion
    direction_adjust.y = 0.0;
    direction_adjust = direction_adjust.normalized();
    # vec2s
    var gd_v2 : Vector2 = Statics.vec3_to_vec2(goal_direction);
    var da_v2 : Vector2 = Statics.vec3_to_vec2(direction_adjust);
    # if summed direction adjust is attempting to drive through a crowd
    if (nearby_characters.size() > 1 and abs(gd_v2.angle_to(da_v2)) < PI/6.0):
        # utilize position average of all nearby
        var num_nearby : float = nearby_characters.size();
        other_pos_average = other_pos_average/num_nearby;
        if (self.global_position.distance_to(other_pos_average) < desired_dist):
            var dir_to_avg : Vector3 = goal_direction.direction_to(other_pos_average);
            direction_adjust = goal_direction.slerp(dir_to_avg, 1.0);
#region debug3
    if (test_neighbor.size() > 1 and abs(gd_v2.angle_to(da_v2)) < PI/6.0 and DEBUG_mode):
        # utilize position average of all nearby
        var num_nearby : float = test_neighbor.size();
        other_pos_average = other_pos_average/num_nearby;
        if (self.global_position.distance_to(other_pos_average) < desired_dist):
            var dir_to_avg : Vector3 = goal_direction.direction_to(other_pos_average);
            direction_adjust = goal_direction.slerp(dir_to_avg, 1.0);
#endregion
    # force angled movement instead of backstepping
    da_v2 = Statics.vec3_to_vec2(direction_adjust);
    var slerped : Vector2 = gd_v2.slerp(da_v2, 0.5);
    # prevent waffling
    if (abs(previous_dir.angle_to(slerped)) > PI/2.0):
        slerped = previous_dir.slerp(slerped, 0.2);
    #Statics.debug_prolog("{0} desire: {1} adjust: {2} result {3}".format([
        #self.name, goal_direction, direction_adjust, slerped]))
    if (DEBUG_mode):
        start_debug_lines(goal_direction, direction_adjust, Statics.vec2_to_vec3(slerped))
    return Statics.vec2_to_vec3(slerped);
    
func calc_direction_to_goal(objective : Vector3) -> Vector3:
    var goal_vector : Vector3 = self.global_position.direction_to(objective);
    var turn_angle : float = Statics.vec3_to_vec2(goal_vector).angle();
    turn_angle += randf_range(-PI/4.0, PI/4.0) * movement_variance;
    var out_vector : Vector3 = Statics.vec2_to_vec3(Vector2.from_angle(turn_angle));
    #Statics.debug_prolog("{0} init dir: {1}, adjusted dir: {2}".format([
        #self.name, goal_vector, out_vector]));
    return out_vector;
    
func bounce_animation() -> void:
    if (mid_bounce):  return;
    mid_bounce = true;
    bounce_tween = get_tree().create_tween().set_parallel();
    bounce_tween.set_ease(Tween.EASE_OUT);
    bounce_tween.set_trans(Tween.TRANS_QUAD);
    bounce_tween.tween_property(active_sprite, "position:y", 0.35, 0.25);
    bounce_tween.chain().set_ease(Tween.EASE_IN);
    bounce_tween.chain().set_trans(Tween.TRANS_QUAD);
    bounce_tween.chain().tween_property(active_sprite, "position:y", 0.0, 0.25);
    bounce_tween.chain().tween_callback(_on_bounce_done);
    
var _on_bounce_done : Callable = func() -> void:
    mid_bounce = false;
    #Statics.debug_log("finished bounce {0}".format([self.name]))
    
func assign_request() -> void:
    if (!initialized): return;
    request = Statics.rand_from_arr_v(CarryableObjects.customer_requests);
    var request_arr : Array[CarryableObjects.CarryObjEnum] = CarryableObjects.deserialize_objects(request);
    # TODO: select sprite based on request
    
func _on_body_entered(body : Node3D) -> void:
    if (body == self):
        return;
    if (body is AnimatableBody3D and Statics.check_for_okid(body)):
        nearby_characters.set(body.ok_id, body);
    
func _on_body_exited(body : Node3D) -> void:
    if (body is AnimatableBody3D and Statics.check_for_okid(body)):
        nearby_characters.erase(body.ok_id);
    
func _physics_process(delta: float) -> void:
    if (!reached_goal(goal) and !at_goal and !is_passerby):
        move_and_collide(navigate(goal) * delta * move_speed);
        at_goal = reached_goal(goal);
    if (DEBUG_mode): return;
    if (at_goal):
        var at_front : bool = false;
        for g : Vector3 in level3d_parent.goals:
            if (g.is_equal_approx(goal)):
                # TODO: display request popup
                at_front = true;
                break;
            else:
                # reset to continue moving fwd in line
                # TODO: maybe do this smarter by checking when it's possible to move up
                at_goal = false;
        if (!request_sent and at_front):
            request_sent = true;
            goal_reached.emit(self);
    if ((request_sent and request_received) or is_passerby):
        if (!reached_goal(exit)):
            move_and_collide(navigate(exit) * delta * move_speed);
        else:
            exit_reached.emit(self);
        
func initiate() -> void:
    initialized = true;
    assign_request();
    sprite_tint = Color(randf(), randf(), randf());
    behind_me.global_position = self.global_position + Vector3(randf_range(-1.0, 1.0), 0.0, 0.75);

func _ready() -> void:
    if (sprite_character_holder and sprites_character.size() == 0):
        for c : Node in sprite_character_holder.get_children():
            if (c is Sprite3D):
                sprites_character.append(c);
                c.visible = false;
    if (sprites_character.size() > 0):
        sprites_character[0].visible = true;
        active_sprite = sprites_character[0];
    
    if (sprite_request_holder and sprites_requests.size() == 0):
        for c : Node in sprite_request_holder.get_children():
            if (c is Sprite3D):
                sprites_requests.append(c);
                c.visible = false;
                
    self_coll_radius = (self_collider.shape as CapsuleShape3D).radius;
    navigation_boundary.body_entered.connect(_on_body_entered);
    navigation_boundary.body_exited.connect(_on_body_exited);
    #Statics.debug_log("i {0} want to be {1} distance from people".format([self.name, desired_dist]));

    goal_dir_mesh = goal_mesh_holder.mesh;
    adj_dir_mesh = adj_mesh_holder.mesh;
    comb_dir_mesh = comb_mesh_holder.mesh;
    if (false):
        goal_mesh_holder.visible = false;
        adj_mesh_holder.visible = false;
        comb_mesh_holder.visible = false;
