class_name ItemBox extends InteractableBase
# NOTE: should only ever be 1 item that comes out here

func public_interact_object(delta : float = 0.0) -> bool:
    return false;

# TODO: handle how player can take a stack if they are able
# no, do this later later
func public_take_object(p : PlayerController) -> CarryableObjectBase:
    if (!AudioManager._instance): AudioManager.ins();
    connected_body = p;
    if (!check_output_can_be_created(output_obj_examples[0])):
        # TODO: warn/error message for debug
        return;
    var output_instance : CarryableObjectBase = create_output_object();
    AudioManager._instance.play_SFX(AudioFiles.ITEM_BOX);
    return output_instance;
    
# TODO is this necessary?
func check_output_can_be_created(obj : CarryableObjectBase) -> bool:
    if (connected_body.carried_object == null):
        return true;
    else:
        if (connected_body.carried_object.item_type == obj.item_type and 
        obj.can_stack):
            return true;
    return false;
    
func _ready() -> void:
    super._ready();
    # special for item box
    assert(output_object_strs.size() == 1, "{0} has too many outputs".format([self.name]));
    
func _init() -> void:
    super._init();
