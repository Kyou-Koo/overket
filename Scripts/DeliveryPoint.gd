class_name DeliveryPoint extends Table

@export var goal : Marker3D;

var customer : Customer;
var top_matches_request : bool = false;

signal request_matched(delivery_point : DeliveryPoint);

func public_place_object(obj : CarryableObjectBase) -> bool:
    var placed : bool  = super.public_place_object(obj);
    check_top_matches_request(obj);
    return placed;

func public_take_object() -> CarryableObjectBase:
    return;

func check_top_matches_request(top : CarryableObjectBase) -> void:
    if (!top_matches_request):
        if (top.item_id == customer.request):
            top_matches_request = true;
            request_matched.emit(self);
            for obj : CarryableObjectBase in objs_on_top:
                # theoretically if the array is accessed
                # while this is running it could cause an error
                # \_(シ)_/
                obj.queue_free();
            objs_on_top.clear();
