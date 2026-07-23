class_name Table extends StaticBody3D

var objs_on_top : Array[CarryableObjectBase];
var obj_top_global_position : Vector3;
@export var scene_obj_holder : Node3D;

var ok_id : StringName = "";

func public_take_object() -> CarryableObjectBase:
    # TODO: stacking??
    # TODO: handle taking a bag specifically
    var num_items_on_top : int = objs_on_top.size();
    if (num_items_on_top > 0):
        Statics.debug_log("tabletop: {0}".format([objs_on_top.size()]));
        var table_obj : CarryableObjectBase = objs_on_top.pop_back()
        Statics.debug_log("tabletop aftr: {0}".format([objs_on_top.size()]));
        return table_obj;
    else:
        return null;

func public_place_object(obj : CarryableObjectBase) -> bool:
    Statics.debug_log("atmpt place {0}".format([obj.name]))
    var num_items_on_top : int = objs_on_top.size();
    # placing
    if (num_items_on_top == 0):
        objs_on_top.append(obj);
        if (obj.get_parent() != scene_obj_holder):
            obj.get_parent().remove_child(obj);
            scene_obj_holder.add_child(obj);
        obj.global_position = obj_top_global_position + Vector3(0, obj.obj_height/2.0, 0);
        obj.orientate_self();
        obj.linear_velocity = Vector3.ZERO;
        obj.angular_velocity= Vector3.ZERO;
        Statics.debug_log("suc place {0} : size {1}".format([obj.name, objs_on_top.size()]));
        return true;
    # TODO: handle multiple items
    # TODO: for now just ignore this and disallow stacking
    # elif (objs_on_top[0].item_type == obj.item_type):
    #     if (objs_on_top[0].can_stack and objs_on_top[0].max_stack < num_items_on_top):
    #         objs_on_top.append(obj);
    #         if (obj.get_parent() != scene_obj_holder):
    #             obj.get_parent().remove_child(obj);
    #             scene_obj_holder.add_child(obj);
    #         # TODO: check height calculation
    #         var new_height : float = (obj.obj_height/2.0) + (obj.obj_height * objs_on_top.size());
    #         obj.global_position = obj_top_global_position + Vector3(0, new_height, 0);
    #         obj.orientate_self();
    #         obj.linear_velocity = Vector3.ZERO;
    #         obj.angular_velocity= Vector3.ZERO;
            
    var failure_state : String;
    if (num_items_on_top > 0 and !obj.can_stack):
        failure_state = "item on top + cannot stack size: {0}".format([num_items_on_top]);
    if (objs_on_top[0].item_type != obj.item_type):
        failure_state = "mismatch item type {0} : {1}".format([objs_on_top[0].item_type, obj.item_type]);
    Statics.debug_log("!!!!!failure state b/c: {0}".format([failure_state]));
    return false;

func _ready() -> void:
    objs_on_top.clear();
    # assign refs
    ok_id = Statics.create_ok_id(self);
    var children : Array[Node] = self.get_children();
    for c : Node in children:
        if c is Marker3D and c.name.contains("Placement"):
            obj_top_global_position = c.global_position;
    # TODO: recalculate
    # scene_obj_holder = self.get_owner().find_child("CarryableObjects") as Node3D;
