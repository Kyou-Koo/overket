class_name DeliveryPoint extends Table

@export var goal : Marker3D;
var goal_pos : Vector3;

var customers : Array[Customer];

signal request_matched(customer : Customer);

func public_place_object(obj : CarryableObjectBase) -> bool:
    var placed : bool  = super.public_place_object(obj);
    check_top_matches_request(obj);
    return placed;

func public_take_object() -> CarryableObjectBase:
    return;

func check_top_matches_request(top : CarryableObjectBase) -> void:
    for c : Customer in customers:
        if (top.item_id == c.request):
            request_matched.emit(c);
            customers.erase(c);
            for obj : CarryableObjectBase in objs_on_top:
                # theoretically if the array is accessed
                # while this is running it could cause an error
                # \_(シ)_/
                obj.queue_free();
            objs_on_top.clear();

func _ready() -> void:
    super._ready();
    goal_pos = goal.global_position;
