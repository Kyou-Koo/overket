class_name DeliveryPoint extends Table

var customer : Customer;
var top_matches_request : bool = false;

func public_place_object(obj : CarryableObjectBase) -> bool:
    var placed : bool  = super.public_place_object(obj);
    check_top_matches_request(obj);
    return placed;

func check_top_matches_request(top : CarryableObjectBase) -> void:
    if (!top_matches_request):
        if (top.item_id == customer.request):
            top_matches_request = true;
