@abstract class_name InteractableBase extends StaticBody3D

@export var output_object_strs : Array[String];
@export var should_output_objects : bool;
var output_object_ress : Array[Resource];
var output_obj_examples : Array[CarryableObjectBase];
#var interaction_area : Area3D;
var connected_body : PlayerController;

var ok_id : StringName = "";

@abstract func public_interact_object(delta : float = 0.0) -> void

@abstract func check_output_can_be_created(obj : CarryableObjectBase) -> bool

func create_output_object() -> CarryableObjectBase:
    # TODO: handle which output based on input
    var output_instance : CarryableObjectBase = output_object_ress[0].instantiate();
    return output_instance;

#func _on_body_enter(body : Node3D) -> void:
    #if body is PlayerController and connected_body == null:
        #body.is_in_range = true;
        #body.interactable_object = self;
        #connected_body = body;
#
#func _on_body_exit(body: Node3D) -> void:
    #if body is PlayerController and body == connected_body:
        #print("disconnecting from {0}".format([connected_body.name]))
        #body.is_in_range = false;
        #body.interactable_object = null;
        #connected_body = null;

func _to_string() -> String:
    # TODO: handle multiple outputs
    return "InterBase: {0} n: {1} out: {2}".format([
        self.ok_id,
        self.name,
        self.should_output_objects
    ])

func _test_all_output_strs() -> bool:
    for s : String in output_object_strs:
        if !s.begins_with("res://"):
            return false;
    return true;

func _ready() -> void:
    # assign refs
    ok_id = Statics.create_ok_id(self);
    #var children : Array[Node] = self.get_children();
    #for c : Node in children:
        #if c is Area3D:
            #interaction_area = c;
            #var interaction_collider : CollisionShape3D = interaction_area.get_child(0) as CollisionShape3D;
            ##unsafe
            #(interaction_collider.shape as CylinderShape3D).radius = 3.0;
    # set signals
    #interaction_area.body_entered.connect(_on_body_enter);
    #interaction_area.body_exited.connect(_on_body_exit);
    # assign access to spawn items
    if (should_output_objects):
        assert(
            output_object_strs.size() > 0 and _test_all_output_strs(), 
            "Must set scene resource for {0}".format([self.name]));
        for s : String in output_object_strs:
            output_object_ress.append(load(s));
        for oor : Resource in output_object_ress:
            output_obj_examples.append(oor.instantiate());
    
func _init() -> void:
    pass;
