@abstract class_name CarryableObjectBase extends RigidBody3D

@export var obj_name : String;
@export var can_stack : bool;
@export var max_stack : int = 1;
@export var carry_orientation : Vector3;
@export var item_type : CarryableObjects.CarryObjEnum;
@onready var item_id : int = item_type as int;
@export var obj_height : float;
var interaction_area : Area3D;
# used to reject interactions for carried/on table state
var is_being_carried : bool = false;

var ok_id : StringName = "";

func orientate_self() -> void:
    self.rotation = carry_orientation;
    
func _on_body_entered(body : Node3D) -> void:
    if (!Statics.check_for_okid(body) or is_being_carried):
        return;
    # should auto-place self on table when thrown in range
    if (body is Table and !is_being_carried):
        body.public_place_object(self);
        is_being_carried = true;

func _ready() -> void:
    ok_id = Statics.create_ok_id(self);
    var col_shape : Shape3D;
    for c in self.get_children():
        if (c is CollisionShape3D):
            col_shape = c.shape;
            if col_shape is BoxShape3D:
                obj_height = col_shape.size.y;
            elif col_shape is CylinderShape3D:
                obj_height = col_shape.height;
        if (c is Area3D):
            interaction_area = c;
            interaction_area.body_entered.connect(_on_body_entered);
    # safeties
    if obj_name == "":
        obj_name = self.name;
    assert(item_type != CarryableObjects.CarryObjEnum.NONE, "Must assign type for item");

func _init() -> void:
    pass
