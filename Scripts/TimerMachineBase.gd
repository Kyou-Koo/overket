@abstract class_name TimerMachineBase extends InteractableBase

@export var interaction_duration : float;
@export var interaction_gap : float;
@export var consumed_objects : Array[CarryableObjects.CarryObjEnum];
@export var needs_all_objects : bool = true;
@export var num_required_objects : int = 1;
@export var is_automatic : bool;

var completed_obj_global_loc : Vector3;
var current_objects : Array[CarryableObjectBase];
var has_necessary_objects : bool = false;
var auto_can_start : bool = false;
var progress_bar_holder : Sprite3D;
var progress_bar : TextureProgressBar;
var time_since_interact : float = 0.0;
var is_completed : bool = false;
var time_since_completion : float = 0.0;

var scene_obj_holder : Node3D;

func public_insert_object(obj : CarryableObjects.CarryObjEnum) -> bool:
    # reject undesired object
    if (obj in consumed_objects):
        current_objects.append(connected_body.carried_object);
        connected_body.carried_object = null;
        has_necessary_objects = check_meets_requirements();
        return true;
    return false;

# TODO: should all interacts emit a message on fail?
func public_interact_object(delta : float = 0.0) -> void:
    # TODO: unfinished, handle automatic also
    has_necessary_objects = check_meets_requirements();
    if (!has_necessary_objects):
        return;
    elif (!is_automatic):
        update_panel(delta);
    else:
        auto_can_start = true;
        
func check_output_can_be_created(obj : CarryableObjectBase) -> bool:
    if obj == null:
        return false
    if !obj.can_stack:
        return false;
    else:
        return true;
        
func check_meets_requirements() -> bool:
    if (needs_all_objects and current_objects.size() != consumed_objects.size()):
        return false;
    for c_o in current_objects:
        # weird state where an undesired object has entered the machine
        # TODO: what do here (probably clean up undesired)
        if !consumed_objects.has(c_o):
            return false;
    if (num_required_objects == 0):
        return true;
    # TODO: handle only needing 1 object
    return true;

func update_panel(delta : float) -> void:
    Statics.debug_prolog("updating panel for {0}".format([self.to_string()]));
    if is_completed:
        return;
    if progress_bar.value < progress_bar.max_value:
        time_since_interact += delta;
        var curr_progress : float = roundf((time_since_interact*progress_bar.max_value)/interaction_duration);
        Statics.debug_prolog("new update for {0} : {1}".format([self.name, curr_progress]));
        if curr_progress >= progress_bar.max_value:
            # TODO: handle arrays multiple
            if (should_output_objects):
                if (check_output_can_be_created(output_obj_examples[0])):
                    progress_bar.visible = true;
                    progress_bar.value = curr_progress;
                else:
                    # TODO: error
                    pass
        progress_bar.visible = true;
        progress_bar.value = curr_progress;
    else:
        time_since_interact = 0.0;
        progress_bar.value = 0.0;
        progress_bar.visible = false;
        is_completed = true;
        auto_can_start = true;
        has_necessary_objects = false;
        if (should_output_objects): place_output_object();
    
func place_output_object() -> void:
    var output_instance : CarryableObjectBase = create_output_object();
    if (output_instance == null): return;
    # consume consumed_objects
    current_objects.clear();
    output_instance.global_position = completed_obj_global_loc + Vector3(0, output_instance.obj_height/2.0, 0);
    # TODO is this the final location for it?
    scene_obj_holder.add_child(output_instance);

func _process(delta: float) -> void:
    if (is_automatic and has_necessary_objects and auto_can_start):
        update_panel(delta);
    if (is_completed):
        time_since_completion += delta;
    if (time_since_completion >= interaction_gap):
        is_completed = false;
        time_since_completion = 0.0;

func _ready() -> void:
    super._ready();
    # assign refs
    var children : Array[Node] = self.get_children();
    for c : Node in children:
        if (c is Marker3D and  c.name.contains("Output")):
            completed_obj_global_loc = c.global_position;
        if (c is SubViewport):
            progress_bar = c.get_child(0);
            
    scene_obj_holder = self.get_owner().find_child("CarryableObjects") as Node3D;
    if (consumed_objects.size() == 0):
        num_required_objects = 0;
    if (needs_all_objects):
        num_required_objects = consumed_objects.size();

func _init() -> void:
    super._init();
    pass
