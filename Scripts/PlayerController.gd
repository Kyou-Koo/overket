class_name PlayerController extends CharacterBody3D

@export var skip_instancing : bool = false;
@export var debug_closest : MeshInstance3D;
@export var player_prefix : String;
# TODO: put in general scene controller
@onready var gravity : float = -ProjectSettings.get_setting("physics/3d/default_gravity");
@export var speed : float = 5.0;
@export var jump : float = 20.0;
@export var interaction_radius : float;
@export var ok_id : String;
@export_range(0, 3) var rand_head : int = 0;
@export_range(0, 3) var rand_face : int = 0;
@export var throw_scale : float = 12.0;
@export var throw_vertical : float = 0.1;

@export_group("Sprites", "sprite_")
@export var sprite_color : Color;
@export var sprite_container : Node3D
@export var sprite_animation_body : AnimatedSprite3D;
@export var sprite_animation_leg : AnimatedSprite3D;
@export var sprite_head_container : Node3D;
var sprite_heads : Array[Sprite3D];
@export var sprite_to_faces_container : Node3D;
var sprite_to_faces : Array[Sprite3D];
@export var sprite_right_faces_container : Node3D;
var sprite_right_faces : Array[Sprite3D];
@export var sprite_left_faces_container : Node3D;
var sprite_left_faces : Array[Sprite3D];
# Sprite animations
const S_STAND : String = "stand";
const S_RIGHT : String = "right";
const S_LEFT : String = "left";
const S_TO : String = "to_cam";
const S_FROM : String = "from_cam";
const S_HOLD : String = "_hold";

var curr_fwd : Vector2;
var new_fwd : Vector2;
var carried_object : CarryableObjectBase;
var carried_object_parent : Marker3D;
var closest_body : Node3D = null;
var interaction_area : Area3D;
var interactable_objects : Dictionary[StringName, Node3D];
var curr_state : PSTATE;

enum PSTATE {
    NEUTRAL,
    INTERACT,
    PICKUP,
    DROP,
    HOLD
}

@export var scene_obj_holder : Node3D;

func object_interact(delta : float) -> void:
    #Statics.debug_prolog("attempting to interact with {0}".format([closest_body]));
    # check in range
    if (interactable_objects.size() > 0):
        # TODO: check for bag placed on table
        if (closest_body is TimerMachineBase):
            closest_body.public_interact_object(delta);

func object_drop() -> void:
    # TODO: check for items on shelf first??
    if (interactable_objects.size() > 0):
        # attempt insert if carrying item
        if (closest_body is TimerMachineBase):
            var success : bool = closest_body.public_insert_object(carried_object, self)
            if (success): return;
        elif (closest_body is Table):
            if ((closest_body as Table).public_place_object(carried_object)):
                _reset_carried_obj();
                carried_object = null;
                return;
                # TODO: maybe place on table sound
            else:
                AudioManager._instance.play_SFX(AudioFiles.ACTION_FAIL);
    #Statics.debug_log("throwing {0}".format([carried_object.name]));
    # throw before removing from self
    _reset_carried_obj();
    carried_object.apply_central_impulse(
        Vector3(-curr_fwd.x, throw_vertical, curr_fwd.y) * throw_scale);
    var co_curr_globals : DirRot = DirRot.new(carried_object.global_position, carried_object.global_rotation);
    carried_object_parent.remove_child(carried_object);
    scene_obj_holder.add_child(carried_object);
    carried_object.global_position = co_curr_globals.direction;
    carried_object.global_rotation = co_curr_globals.rotation;
    carried_object.is_being_carried = false;
    carried_object = null;
    AudioManager._instance.play_SFX(AudioFiles.THROW);
        
# TODO: player handles assigning and reassigning of generated object parents when picked up
func object_pick() -> void:
    if (interactable_objects.size() > 0):
        if (closest_body is Table and closest_body is not GarbageCan):
            object_hold((closest_body as Table).public_take_object());
            return;
        elif (closest_body is CarryableObjectBase):
            object_hold(closest_body as CarryableObjectBase)
            return;
        elif (closest_body is ItemBox):
            var new_obj : CarryableObjectBase = (closest_body as ItemBox).public_take_object(self);
            object_hold(new_obj);
            return;
        elif (closest_body is TimerMachineBase):
            var new_obj : CarryableObjectBase = (closest_body as TimerMachineBase).public_take_object(self);
            closest_body.out_obj = null;
            object_hold(new_obj);

func object_hold(obj : CarryableObjectBase) -> void:
    if (obj == null): return;
    if (obj.get_parent_node_3d() != null):
        scene_obj_holder.remove_child(obj);
    carried_object_parent.add_child(obj);
    #Statics.debug_log("attempting to hold & remove: {0}".format([obj.name]));
    # TODO: use bool to handle audio cues
    var confirm : bool = remove_from_interact_list(obj);
    carried_object = obj;
    obj.freeze = true;
    obj.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;
    obj.add_collision_exception_with(self);
    obj.position = Vector3.ZERO;
    obj.gravity_scale = 0.0;
    obj.linear_velocity = Vector3.ZERO;
    obj.orientate_self();
    obj.is_being_carried = true;
    #Statics.debug_log("chk: {0}, o gp: {1}, op gp: {2}".format([confirm, obj.global_position, carried_object_parent.global_position]));

func _reset_carried_obj() -> void:
    carried_object.gravity_scale = 1.0;
    carried_object.freeze = false;
    carried_object.remove_collision_exception_with(self);

func handle_movement() -> DirRot:
    var new_dirrot : DirRot = DirRot.new();
    if (!Input.is_anything_pressed()):
        return new_dirrot;
    var direction : Vector3 = Vector3.ZERO;
    direction.z = Input.get_axis( player_prefix + "fwd", player_prefix + "back");
    direction.x = Input.get_axis(player_prefix + "left", player_prefix + "right");
    new_dirrot.direction = direction;
    
    # rotate character
    if (direction.length() != 0):
        new_fwd = Vector2(-direction.x, direction.z);
    if (new_fwd != curr_fwd):
        new_dirrot.rotation = Vector3(0.0, curr_fwd.angle_to(new_fwd), 0.0);
        #Statics.debug_prolog("angle: {0} to new fwd: {1}".format([rad_to_deg(new_dirrot.rotation.y), new_fwd]));
    
    new_dirrot.normalize();
    return new_dirrot;
    
func test_pushing(delta : float) -> void:
    var collision : KinematicCollision3D = self.move_and_collide(self.velocity * delta);
    if (collision):
        if (collision.get_collider().get_class() == "RigidBody3D"):
            var collided_body : RigidBody3D = collision.get_collider() as RigidBody3D;
            if (collided_body.mass < 5.0):
                collided_body.apply_central_force(self.velocity);

func check_closest_body() -> Node3D:
    if (interactable_objects.is_empty()):
        return null;
    var shortest_dist : float = INF;
    var curr_shortest : StringName = "";
    #Statics.debug_prolog(str(interactable_objects.keys()));
    for io : StringName in interactable_objects.keys():
        if (interactable_objects[io] == carried_object):
            # does not should not include carried object
            continue;
        var test_dist : float = self.global_position.distance_to(interactable_objects[io].global_position);
        if (test_dist < shortest_dist):
            if (interactable_objects[io] is CarryableObjectBase):
                var cob : CarryableObjectBase = interactable_objects[io] as CarryableObjectBase;
                if (cob.is_being_carried):
                    continue;
            shortest_dist = test_dist;
            curr_shortest = io;
    if (curr_shortest != ""):
        debug_closest.global_position = interactable_objects[curr_shortest].global_position + Vector3.UP;
        return interactable_objects[curr_shortest];
    return null;
    
func add_to_interact_list(obj : Node3D) -> bool:
    # ignore non-script objects
    if (!Statics.check_for_okid(obj)):
        return false;
    # dont let carrried object enter interactable objects
    if (obj == carried_object):
        return false;
    interactable_objects.set(obj.ok_id, obj);
    #Statics.debug_log("{0} in interactable obj".format([interactable_objects.size()]));
    return true;

func remove_from_interact_list(obj : Node3D) -> bool:
    # ignore non-script objects
    if (!Statics.check_for_okid(obj)):
        return false;
    if (interactable_objects.erase(obj.ok_id)):
        if (interactable_objects.is_empty()):
            closest_body = null;
        elif (obj == closest_body):
            closest_body = check_closest_body();
        return true;
    return false;

func set_up_sprite_arrays(container : Node3D, array : Array) -> void:
    for s3d : Sprite3D in container.get_children():
        array.append(s3d);
        s3d.visible = false;
        
func pick_face_head(face : int, head : int) -> void:
    disable_faces();
    for h : Sprite3D in sprite_heads:
        h.visible = false;
    sprite_heads[head].visible = true;
    sprite_to_faces[face].visible = true;
    
func disable_faces() -> void:
    for f : Sprite3D in sprite_to_faces:
        f.visible = false;
    for f : Sprite3D in sprite_right_faces:
        f.visible = false;
    for f : Sprite3D in sprite_left_faces:
        f.visible = false;
        
func color_sprite() -> void:
    for h : Sprite3D in sprite_heads:
        h.modulate = sprite_color;
    sprite_animation_body.modulate = sprite_color;
    sprite_animation_leg.modulate = sprite_color;
    var new_mat : StandardMaterial3D = StandardMaterial3D.new();
    new_mat.albedo_color = sprite_color;
    $PositionCircle.material_override = new_mat;
    debug_closest.material_override = new_mat;

func set_up(face : int, head: int, color : Color) -> void:
    skip_instancing = false;
    disable_faces();
    pick_face_head(face, head);
    sprite_color = color;
    color_sprite();

func _on_body_enter(body : Node3D) -> void:
    # ignore non-script objects
    if (!Statics.check_for_okid(body)):
        return;
    #Statics.debug_log("entr bodyp {0} is: {1}".format([body.name, Statics.a_classtype(body)]))
    var confirm : bool = add_to_interact_list(body);

func _on_body_exit(body: Node3D) -> void:
    # ignore non-script objects
    if (!Statics.check_for_okid(body)):
        return;
    #Statics.debug_log("exit bodyp {0} is: {1}".format([body.name, Statics.a_classtype(body)]))
    var confirm : bool = remove_from_interact_list(body);
    
func _process(delta: float) -> void:
    # TODO: hacky idk
    #if (skip_instancing): return;
    sprite_container.global_rotation = Vector3(-PI/4, 0, 0);

func _physics_process(delta : float) -> void:
    #if (skip_instancing): return;
    var motion_direction : DirRot = handle_movement();
    motion_direction.direction *= speed;
    if (Input.is_action_just_pressed(player_prefix + "jump") and is_on_floor()):
        motion_direction.direction += Vector3(0, jump, 0);
    if (!is_on_floor()):
        motion_direction.direction -= Vector3(0, gravity * gravity * delta, 0);
    self.set_velocity(motion_direction.direction);
    move_and_slide();
    # this is all sprite animation stuff-------------------------
    if (is_zero_approx(motion_direction.length())):
        disable_faces();
        sprite_to_faces[rand_face].visible = true;
        sprite_animation_leg.play(S_STAND);
        if (curr_state == PSTATE.NEUTRAL):
            sprite_animation_body.play(S_STAND);
        else:
            sprite_animation_body.play(S_TO + S_HOLD);
    else:
        if (motion_direction.direction.x == 0):
            disable_faces();
            if (motion_direction.direction.z < 0.0):
                sprite_animation_leg.play(S_FROM);
                if (carried_object == null):
                    sprite_animation_body.play(S_FROM);
                else:
                    sprite_animation_body.play(S_FROM + S_HOLD);
            else:
                sprite_animation_leg.play(S_TO);
                sprite_to_faces[rand_face].visible = true;
                if (carried_object == null):
                    sprite_animation_body.play(S_TO);
                else:
                    sprite_animation_body.play(S_TO + S_HOLD);
        elif (motion_direction.direction.x > 0.0):
            disable_faces();
            sprite_right_faces[rand_face].visible = true;
            sprite_animation_leg.play(S_RIGHT);
            if (carried_object == null):
                sprite_animation_body.play(S_RIGHT);
            else:
                sprite_animation_body.play(S_RIGHT + S_HOLD);
        else:
            disable_faces();
            sprite_left_faces[rand_face].visible = true;
            sprite_animation_leg.play(S_LEFT);
            if (carried_object == null):
                sprite_animation_body.play(S_LEFT);
            else:
                sprite_animation_body.play(S_LEFT + S_HOLD);
    # ------------------------------- sprite animation end
    # TODO: why is this here lmao
    # self.velocity.y += gravity * delta;
    if (new_fwd != curr_fwd and motion_direction.rotation.y != 0.0):
        self.rotate_y(motion_direction.rotation.y);
        curr_fwd = new_fwd;
    # TODO: remove?
    # test_pushing(delta);
    # regular checks TODO: should this be only on interact instead?
    closest_body = check_closest_body();
    # interaction
    if (Input.is_action_pressed(player_prefix + "interact") and
    (curr_state == PSTATE.NEUTRAL or curr_state == PSTATE.INTERACT)):
        curr_state = PSTATE.INTERACT;
        object_interact(delta);
        curr_state = PSTATE.NEUTRAL;
    if (Input.is_action_just_pressed(player_prefix + "pick_drop") and curr_state == PSTATE.NEUTRAL):
        if (carried_object == null):
            curr_state = PSTATE.PICKUP;
            object_pick();
            curr_state = PSTATE.NEUTRAL;
        else:
            curr_state = PSTATE.DROP;
            object_drop();
            curr_state = PSTATE.NEUTRAL;
    
            
func _input(event: InputEvent) -> void:
    return
    if (event.is_pressed()): 
        #Statics.debug_log(event.as_text());
        Statics.debug_log("obj in scene: {0}".format([str(scene_obj_holder.get_children())]))
            
func _ready() -> void:
    self.ok_id = Statics.create_ok_id(self);
    assert(player_prefix in ["p1", "p2", "p3", "p4"], "invalid prefix {0} for {1}".format([
        self.name, player_prefix
    ]));
    self.apply_floor_snap();
    var children : Array[Node] = self.get_children();
    for c in children:
        if c is Marker3D:
            carried_object_parent = c;
            Statics.debug_log("Carry position for {0} assigned at {1}".format([
                self.name,
                carried_object_parent.position,
            ]))
        if c is Area3D:
            interaction_area = c;
            var interaction_collider : CollisionShape3D = interaction_area.get_child(0) as CollisionShape3D;
            assert(interaction_collider.shape is CylinderShape3D, "Must set player interaction shape to Cylinder3D");
            (interaction_collider.shape as CylinderShape3D).radius = interaction_radius;
            # set signals
            interaction_area.body_entered.connect(_on_body_enter);
            interaction_area.body_exited.connect(_on_body_exit);
            
    curr_state = PSTATE.NEUTRAL;

    set_up_sprite_arrays(sprite_head_container, sprite_heads);
    set_up_sprite_arrays(sprite_to_faces_container, sprite_to_faces);
    set_up_sprite_arrays(sprite_left_faces_container, sprite_left_faces);
    set_up_sprite_arrays(sprite_right_faces_container, sprite_right_faces);
    if (skip_instancing):
        pick_face_head(rand_face, rand_head);
        #sprite_color = Color(randf(), randf(), randf());
        color_sprite();

func _init() -> void:
    curr_fwd = Vector2.UP;
