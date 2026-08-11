class_name DeliveryPoint extends Table

@export var goal : Marker3D;
@export var level_ui : LevelUI;
var goal_pos : Vector3;

var dp_customers : Array[Customer];

signal request_matched(customer : Customer);

func public_place_object(obj : CarryableObjectBase) -> bool:
    var placed : bool  = super.public_place_object(obj);
    check_top_matches_request(obj);
    return placed;

func public_take_object() -> CarryableObjectBase:
    return;

func check_top_matches_request(top : CarryableObjectBase) -> void:
    var matched_idx : int = -1;
    for i : int  in range(dp_customers.size() - 1):
        if (top.item_id == dp_customers[i].request):
            Statics.debug_log("delivery {0} {1} should match customer {2} req {3}".format([
                top.name,
                top.item_id,
                dp_customers[i].name,
                dp_customers[i].request,
            ]))
            request_matched.emit(dp_customers[i]);
            matched_idx = i;
            for obj : CarryableObjectBase in objs_on_top:
                # theoretically if the array is accessed
                # while this is running it could cause an error
                # \_(シ)_/
                obj.queue_free();
            objs_on_top.clear();
            break
    if (matched_idx != -1):
        dp_customers.pop_at(matched_idx)

func _ready() -> void:
    super._ready();
    goal_pos = goal.global_position;
