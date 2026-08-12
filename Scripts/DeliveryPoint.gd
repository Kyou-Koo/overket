class_name DeliveryPoint extends Table

@export var goal : Marker3D;
@export var level_ui : LevelUI;
var goal_pos : Vector3;

var dp_customers : Array[Customer];

signal request_matched(customer : Customer);

func public_place_object(obj : CarryableObjectBase) -> bool:
    # just overwrite
    # placing
    if (check_obj_matches_request(obj)):
        if (obj is Bag):
            if (obj.connect_table_area(self)):
                obj.freeze = true;
                obj_on_top_is_bag = true;
        objs_on_top.append(obj);
        #if (obj.get_parent() != scene_obj_holder):
        obj.get_parent().remove_child.call_deferred(obj);
        scene_obj_holder.add_child(obj);
        obj.freeze = true;
        obj.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;
        obj.global_position = placement_marker.global_position;
        obj.orientate_self();
        obj.linear_velocity = Vector3.ZERO;
        obj.angular_velocity= Vector3.ZERO;
        # Statics.debug_log("suc place {0} : at {1} goal: {2} parent {3}".format([
        #     obj.name, obj.global_position, placement_marker.global_position, str(obj.get_parent())]));
        check_top_matches_request(obj);
        return true;
    Statics.debug_log("{0} dp does not have matching customer request {1}{2}".format([
        self.name,
        obj.item_id,
        obj.name
    ]))
    return false;

func check_obj_matches_request(obj: CarryableObjectBase) -> bool:
    for dp_c : Customer in dp_customers:
        if (obj.item_id == dp_c.request):
            return true;
    return false;

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
