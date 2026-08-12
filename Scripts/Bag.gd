class_name Bag extends CarryableObjectBase
# Object should create when bag is placed on table
@export var inside_asset_holder : Node3D;
var inside_assets : Array[BagInsides];
@export var interaction_duration : float;
@export var interaction_gap : float;
@export var collider : CollisionShape3D;
var consumed_objects : Array[CarryableObjects.CarryObjEnum];
# @export var consumed_object_objs : Array[CarryableObjectBase];
# @export var output_bags_str : Array[String];
var is_on_table : bool = false;

var connected_body : PlayerController;
var items_in_bag : int = 0;
var progress_bar_holder : Sprite3D;
var progress_bar : TextureProgressBar;
var time_since_interact : float = 0.0;
var is_completed : bool = false;
var time_since_completion : float = 0.0;

const MAX_OBJECTS : int = 3;
var b_objects_serialized : int  = CarryableObjects.CarryObjEnum.BAG;
var b_curr_serialized : int = CarryableObjects.CarryObjEnum.BAG;

func public_insert_object(obj : CarryableObjectBase) -> bool:
    if (!is_on_table):
        return false;
    if (items_in_bag >= MAX_OBJECTS):
        return false;
    # already in bag
    if (obj.item_type & b_curr_serialized):
        return false;
    # serialize, add to objects
    if (obj.item_type in consumed_objects):
        b_objects_serialized = CarryableObjects.join_carried_objects([
            b_objects_serialized as CarryableObjects.CarryObjEnum, obj.item_type]);
        item_id = b_objects_serialized;
        items_in_bag += 1;
        display_inserted_objects();
        obj.queue_free.call_deferred();
        return true;
    else:
        return false;

# for now bag stuffing is instant so ignore this code
# func public_interact_object(delta : float = 0.0) -> void:
#     # can player interact if its on a table? or force ground usage?
#     if (!is_on_table):
#         return;
#     # only able to interact if player has object
#     if (connected_body.carried_object == null):
#         return;
#     update_panel(delta);
    
func display_inserted_objects() -> void:
    if b_objects_serialized == b_curr_serialized:
        return;
    var deseralized_arr : Array[CarryableObjects.CarryObjEnum] = CarryableObjects.deserialize_objects(b_objects_serialized);
    for bag_inside : BagInsides in inside_assets:
        if (bag_inside.item_type in deseralized_arr):
            bag_inside.visible = true;
    b_curr_serialized = b_objects_serialized;

func update_panel(delta : float) -> void:
    pass;
    
# func _on_body_enter(body : Node3D) -> void:
#     if body is PlayerController and connected_body == null:
#         body.is_in_range = true;
#         body.interactable_object = self;
#         connected_body = body;

# func _on_body_exit(body: Node3D) -> void:
#     if body is PlayerController and body == connected_body:
#         # Statics.debug_log("disconnecting from {0}".format([connected_body.name]))
#         body.is_in_range = false;
#         body.interactable_object = null;
#         connected_body = null;

func lock_position(lock : bool) -> void:
    collider.disabled = lock;
    self.lock_rotation = lock;
    self.axis_lock_linear_x = lock;
    self.axis_lock_linear_y = lock;
    self.axis_lock_linear_z = lock;

func connect_table_area(t : Table) -> bool:
    if (t.objs_on_top.size() != 0):
        return false;
    # connect to table's area to assign
    Statics.debug_log("connecting to table {0}".format([t.name]));
    is_on_table = true;
    lock_position(true);
    return true;

func disconnect_table_area(t : Table) -> bool:
    if (t == null):
        return false;
    Statics.debug_log("{0} goodbye {1}".format([self.name, t.name]));
    is_on_table = false;
    lock_position(false);
    return true;

func _process(delta: float) -> void:
    pass
    
func _ready() -> void:
    super._ready();
    # prepare bag base values
    consumed_objects.append(CarryableObjects.CarryObjEnum.BOOK);
    consumed_objects.append(CarryableObjects.CarryObjEnum.SHIKISHI);
    consumed_objects.append(CarryableObjects.CarryObjEnum.ACRYLIC);
    consumed_objects.append(CarryableObjects.CarryObjEnum.KEYHOLDER);
    
    for c : Node3D in inside_asset_holder.get_children():
        if (c is BagInsides):
            inside_assets.append(c);
            c.visible = false;
