class_name Printer extends TimerMachineBase

@export var output_icon_holder : Sprite3D;
@export var output_wide_holder : Sprite3D;
@export var paper_req : Control;
@export var book_data_req : Control;
@export var shikishi_data_req : Control;
@export var data_req : Control;
@export var paper_book_data_req : Control;
@export var paper_shiki_data_req : Control;
@export var book_notif : Control;
@export var shikishi_notif : Control;
@export var can_output_book : bool = false;
@export var can_output_shikishi : bool = false;
# hacks
var obj_array : Array[String];
var book_req_arr : Array[String] = ["DataBook", "Paper"];
var shikishi_req_arr : Array[String] = ["DataShikishi", "Paper"];
var has_paper : bool = false;
var has_data : bool = false;

func curr_objects_contains_data(new_obj : CarryableObjectBase) -> bool:
    if (new_obj.item_type != CarryableObjects.CarryObjEnum.DATA): return false;
    for obj : CarryableObjects.CarryObjEnum in current_objects:
        if obj == CarryableObjects.CarryObjEnum.DATA:
            return true;
    return false;
    
func update_notif_display() -> void:
    var show_data : bool = true;
    var show_paper : bool = true;
    for co : CarryableObjects.CarryObjEnum in current_objects:
        if (co == CarryableObjects.CarryObjEnum.DATA):
            show_data = false;
        elif (co == CarryableObjects.CarryObjEnum.PAPER):
            show_paper = false;
    # hide everything
    data_req.visible = false;
    book_data_req.visible = false;
    shikishi_data_req.visible = false;
    paper_req.visible = false;
    paper_book_data_req.visible = false;
    paper_shiki_data_req.visible = false;
    # prioritize showing paper req
    if (show_paper and show_data):
        if (can_output_book):
            paper_book_data_req.visible = true;
        else:
            paper_shiki_data_req.visible = true;
    elif (show_paper):
        paper_req.visible = true;
    elif (show_data):
        if (can_output_book and can_output_shikishi):
            data_req.visible = true;
        elif (can_output_book):
            book_data_req.visible = true;
        else:
            shikishi_data_req.visible = true;
    
func public_insert_object(obj : CarryableObjectBase, p : PlayerController = null) -> bool:
    # reject undesired object
    if (obj.item_type in consumed_objects and (!has_data or !has_paper)):
        if (obj.item_type == CarryableObjects.CarryObjEnum.DATA and !has_data):
            has_data = true;
        elif (obj.item_type == CarryableObjects.CarryObjEnum.PAPER and !has_paper):
            has_paper = true;
        else:
            return false;
        Statics.debug_log("inserted {0} into {1}".format([obj.obj_name, self.name]));
        obj_array.append(obj.obj_name);
        current_objects.append(obj.item_type);
        obj.queue_free();
        if (p != null): p.carried_object = null;
        has_necessary_objects = check_meets_requirements();
        update_notif_display();
        return true;
    return false;

func public_interact_object(delta : float = 0.0) -> bool:
    return false;

func public_take_object(pc : PlayerController) -> CarryableObjectBase:
    return super.public_take_object(pc);

func check_output_can_be_created(obj : CarryableObjectBase) -> bool:
    if obj == null:
        return false
    if !obj.can_stack:
        return false;
    else:
        return true;
        
func matches_req_array(in_arr : Array[String]) -> bool:
    for obj : String in obj_array:
        if (obj in in_arr):
            in_arr.erase(obj);
            
    return in_arr.size() == 0;
        
func check_meets_requirements() -> bool:
    var clear_current_objects : bool = false;
    for c_o in current_objects:
        # weird state where an undesired object has entered the machine
        # TODO: what do here (probably clean up undesired)
        if !consumed_objects.has(c_o):
            Statics.debug_log("rejecting start")
            clear_current_objects = true;
            return false;
    if (clear_current_objects):
        current_objects.clear();
    if (num_required_objects == 0):
        return true;
    elif (has_data and has_paper):
        return true;
    return false;
    
func update_panel(delta : float) -> void:
    Statics.debug_prolog("updating panel for {0}".format([self.to_string()]));
    if is_completed:
        return;
    if progress_bar.value < progress_bar.max_value:
        progress_bar.visible = true;
        time_since_interact += delta;
        var curr_progress : float = roundf((time_since_interact*progress_bar.max_value)/interaction_duration);
        Statics.debug_prolog("new update for {0} : {1}".format([self.name, curr_progress]));
        if curr_progress >= progress_bar.max_value:
            # TODO: handle arrays multiple
            if (should_output_objects):
                for output_obj : CarryableObjectBase in output_obj_examples:
                    if (check_output_can_be_created(output_obj)):
                        progress_bar.visible = true;
                        progress_bar.value = curr_progress;
                    else:
                        # TODO: error
                        pass
        progress_bar.value = curr_progress;
    else:
        time_since_interact = 0.0;
        progress_bar.value = 0.0;
        progress_bar.visible = false;
        is_completed = true;
        auto_can_start = true;
        has_necessary_objects = false;
        has_paper = false;
        has_data = false;
        if (should_output_objects): place_output_object();
    
func place_output_object() -> void:
    var output_instance : CarryableObjectBase;
    if (matches_req_array(book_req_arr.duplicate())):
        output_instance = output_object_ress[0].instantiate();
    elif (matches_req_array(shikishi_req_arr.duplicate())):
        output_instance = output_object_ress[1].instantiate();
    if (output_instance == null): return;
    # consume consumed_objects
    current_objects.clear();
    obj_array.clear();
    output_instance.global_position = completed_obj_global_loc + Vector3(0, output_instance.obj_height/2.0, 0);
    scene_obj_holder.add_child(output_instance);
    out_obj = output_instance;

func _process(delta: float) -> void:
    if (is_automatic and has_necessary_objects and auto_can_start):
        update_panel(delta);
    if (is_completed):
        time_since_completion += delta;
    if (time_since_completion >= interaction_gap):
        is_completed = false;
        time_since_completion = 0.0;
    update_notif_display();

func _ready() -> void:
    super._ready();
    auto_can_start = true;
    progress_bar.visible = false;
    book_notif.visible = false;
    shikishi_notif.visible = false;
    paper_req.visible = true;
    book_data_req.visible = false;
    shikishi_data_req.visible = false;
    paper_book_data_req.visible = false;
    paper_shiki_data_req.visible = false;
    progress_bar_holder.global_rotation_degrees = Vector3(-40, 0, 0);
    output_icon_holder.global_rotation_degrees = Vector3(-40, 0, 0);
    output_wide_holder.global_rotation_degrees = Vector3(-40, 0, 0);

func _init() -> void:
    super._init();
