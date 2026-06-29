class_name PlayerController extends CharacterBody3D

# TODO: put in general scene controller
@onready var gravity : float = -ProjectSettings.get_setting("physics/3d/default_gravity");
@export var speed : float = 10.0;
@export var interaction_radius : float;
@export var playerId : String;
@export var throw_scale : float = 5.0;
@export var throw_vertical : float = 1.0;

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

var scene_obj_holder : Node3D;

func object_interact(delta : float) -> void:
    Statics.debug_prolog("attempting to interact with {0}".format([closest_body.name]));
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
            var success : bool = closest_body.public_insert_object(carried_object.item_type)
            if (!success):
                pass
                # TODO: some indication to player they can't insert
        elif (closest_body is Table):
            if ((closest_body as Table).public_place_object(carried_object)):
                _reset_carried_obj();
                carried_object = null;
                # TODO: some success state here
            else:
                # TODO: handle failure state
                pass;
    # TODO: throw values
    else:
        Statics.debug_log("throwing {0}".format([carried_object.name]));
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
        
# TODO: player handles assigning and reassigning of generated object parents when picked up
func object_pick() -> void:
    if (interactable_objects.size() > 0):
        # TODO: handle item on any surface first
        if (closest_body is Table):
            object_hold((closest_body as Table).public_take_object());
            return;
        elif (closest_body is CarryableObjectBase):
            object_hold(closest_body as CarryableObjectBase)
            return;
        elif (closest_body is ItemBox):
            var new_obj : CarryableObjectBase = (closest_body as ItemBox).public_take_object(self);
            object_hold(new_obj);
            return;

func object_hold(obj : CarryableObjectBase) -> void:
    if (obj.get_parent_node_3d() != null):
        scene_obj_holder.remove_child(obj);
    carried_object_parent.add_child(obj);
    Statics.debug_log("attempting to hold & remove: {0}".format([obj.name]));
    # TODO: use bool to handle audio cues
    var confirm : bool = remove_from_interact_list(obj);
    carried_object = obj;
    obj.freeze = true;
    obj.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;
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
    direction.z = Input.get_axis(&"fwd", &"back");
    direction.x = Input.get_axis(&"left", &"right");
    new_dirrot.direction = direction;
    
    # rotate character
    if (direction.length() != 0):
        new_fwd = Vector2(-direction.x, direction.z);
    if (new_fwd != curr_fwd):
        new_dirrot.rotation = Vector3(0.0, curr_fwd.angle_to(new_fwd), 0.0);
        Statics.debug_prolog("angle: {0} to new fwd: {1}".format([rad_to_deg(new_dirrot.rotation.y), new_fwd]));
    
    new_dirrot.normalize();
    Statics.debug_prolog("----- dirrot: {0}".format([new_dirrot.to_string()]))
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
    Statics.debug_prolog(str(interactable_objects.keys()));
    for io : StringName in interactable_objects.keys():
        if (interactable_objects[io] == carried_object):
            # does not should not include carried object
            continue;
        if (self.position.distance_to(interactable_objects[io].position) < shortest_dist):
            if (interactable_objects[io] is CarryableObjectBase):
                var cob : CarryableObjectBase = interactable_objects[io] as CarryableObjectBase;
                if (cob.is_being_carried):
                    continue;
            curr_shortest = io;
    
    if (curr_shortest != ""):
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

func _physics_process(delta : float) -> void:
    # TODO: player state processing
    var motion_direction : DirRot = handle_movement();
    self.set_velocity(motion_direction.direction * speed);
    self.velocity.y += gravity * delta;
    if (new_fwd != curr_fwd and motion_direction.rotation.y != 0.0):
        self.rotate_y(motion_direction.rotation.y);
        curr_fwd = new_fwd;
    #print("player rot: {0}".format([self.rotation]))
    test_pushing(delta);
    # regular checks TODO: should this be only on interact instead?
    closest_body = check_closest_body();
    # interaction
    if (Input.is_action_pressed(&"interact") and
    (curr_state == PSTATE.NEUTRAL or curr_state == PSTATE.INTERACT)):
        curr_state = PSTATE.INTERACT;
        object_interact(delta);
        curr_state = PSTATE.NEUTRAL;
    if (Input.is_action_just_pressed(&"pick_drop") and curr_state == PSTATE.NEUTRAL):
        if (carried_object == null):
            curr_state = PSTATE.PICKUP;
            object_pick();
            curr_state = PSTATE.NEUTRAL;
        else:
            curr_state = PSTATE.DROP;
            object_drop();
            curr_state = PSTATE.NEUTRAL;
            
func _ready() -> void:    
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
            
    scene_obj_holder = self.get_owner().find_child("CarryableObjects");
    curr_state = PSTATE.NEUTRAL;

func _init() -> void:
    curr_fwd = Vector2.UP;
