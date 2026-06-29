class_name Bag extends CarryableObjectBase
# Object should create when bag is placed on table
@export var interaction_duration : float;
@export var interaction_gap : float;
@export var consumed_objects : Array[CarryableObjects.CarryObjEnum];
@export var output_bags_str : Array[String];
var is_on_table : bool = false;

var connected_body : PlayerController;
var current_objects : Array[CarryableObjectBase];
var progress_bar_holder : Sprite3D;
var progress_bar : TextureProgressBar;
var time_since_interact : float = 0.0;
var is_completed : bool = false;
var time_since_completion : float = 0.0;

const MAX_OBJECTS : int = 3;
var b_objects_serialized : int  = CarryableObjects.CarryObjEnum.BAG;
var b_curr_serialized : int = CarryableObjects.CarryObjEnum.BAG;

func public_insert_object(obj : CarryableObjects.CarryObjEnum) -> bool:
    if (is_on_table):
        return false;
    if (current_objects.size() >= MAX_OBJECTS):
        return false;
    # serialize, add to objects
    if (obj in consumed_objects):
        b_objects_serialized = CarryableObjects.join_carried_objects([
            b_objects_serialized as CarryableObjects.CarryObjEnum, obj]);
        current_objects.append(obj);
        return true;
    else:
        return false;

func public_interact_object(delta : float = 0.0) -> void:
    if (is_on_table):
        return;
    # only able to interact if player has object
    if (connected_body.carried_object == null):
        return;
    update_panel(delta);
    
func place_output_object() -> void:
    # swap current model with model with bag that exists
    # do we have 11 bag models...? or...
    # dont swap if matches same
    if b_objects_serialized == b_curr_serialized:
        return;
    # Bag TSCN should have all 5 objects in, toggle on/off as necessary
    var b_deserialized_objs : Array[CarryableObjects.CarryObjEnum];
    b_deserialized_objs = CarryableObjects.deserialize_objects(b_objects_serialized);
    
func update_panel(delta : float) -> void:
    pass;
    
func _on_body_enter(body : Node3D) -> void:
    if body is PlayerController and connected_body == null:
        body.is_in_range = true;
        body.interactable_object = self;
        connected_body = body;

func _on_body_exit(body: Node3D) -> void:
    if body is PlayerController and body == connected_body:
        print("disconnecting from {0}".format([connected_body.name]))
        body.is_in_range = false;
        body.interactable_object = null;
        connected_body = null;

func connect_table_area(t : Table) -> bool:
    if (t.objs_on_top.size() != 0):
        return false;
    # connect to table's area to assign
    interaction_area = t.interaction_area;
    if (interaction_area != null):
        interaction_area.body_entered.connect(_on_body_enter);
        interaction_area.body_exited.connect(_on_body_exit);
    return true;

func _process(delta: float) -> void:
    pass
    
func _ready() -> void:
    super._ready();
    # prepare bag base values
    consumed_objects.append(CarryableObjects.CarryObjEnum.BOOK);
    consumed_objects.append(CarryableObjects.CarryObjEnum.SHIKISHI);
    consumed_objects.append(CarryableObjects.CarryObjEnum.POSTCARD);
    consumed_objects.append(CarryableObjects.CarryObjEnum.ACRYLIC);
    consumed_objects.append(CarryableObjects.CarryObjEnum.KEYHOLDER);
    
func _init() -> void:
    super._init();
    
