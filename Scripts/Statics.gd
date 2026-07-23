class_name Statics

enum ENUM_DEBUG_PRN_PROC {
    NEVER   = 0,
    CYCLE   = 1,
    ALWAYS  = 2,
};
static var cycle : int = 1000;
static var last_printed_cycle : int = 0;

static var DEBUG_MODE : bool = true;
static var DEBUG_PRINT_WARN : bool = true;
static var DEBUG_PRINT_PROCESS : ENUM_DEBUG_PRN_PROC = ENUM_DEBUG_PRN_PROC.CYCLE;

# TODO: assign intial value in game configuration
# TODO: think about giving this to every object
static var ok_id_incr : int = 0;
static var error_log_array : Array[String];

static func create_ok_id(n3d : Node3D) -> String:
    var has_ok_id : bool = check_for_okid(n3d);
    if (!has_ok_id):
        debug_log("{0} does not have a ok_id".format([n3d.name]));
        return ""
    # TODO: real function for creating the id
    var new_ok_id : String = "{0}-{1}".format([ok_id_incr, n3d.name]);
    ok_id_incr += 1;
    return new_ok_id;
    
static func check_for_okid(n3d : Node3D) -> bool:
    var n3d_props : Array[Dictionary] = n3d.get_property_list();
    for prop : Dictionary in n3d_props:
        if (prop["name"] == "ok_id"):
            return true;
    return false;
    
static func time_sec_to_minsec(total_sec : int) -> String:
    var secs : int = total_sec % 60;
    var mins : int = (total_sec - secs) / 60;
    return "{0}:{1}".format({0:"%02d" % mins, 1:"%02d" % secs});

# once again this would be benefitted by using C# and generic types
static func rand_from_arr_v(a : Array[Variant]) -> Variant:
    return a[randi_range(0, a.size() - 1)];
    
static func rand_from_arr_o(a : Array) -> Object:
    return a[randi_range(0, a.size() - 1)];
    
static func vec3_to_vec2(v : Vector3) -> Vector2:
    return Vector2(v.x, v.z);
    
static func vec2_to_vec3(v : Vector2) -> Vector3:
    return Vector3(v.x, 0.0, v.y);
    
#region debug, warning, error logging
static func raise_warning(msg : String) -> void:
    # TODO: log somewhere
    if (DEBUG_MODE and DEBUG_PRINT_WARN):
        push_warning(msg)
    var error_msg : String = "{0} | {1}".format([
        Time.get_datetime_string_from_system(true, false),
        msg
        ])
    error_log_array.push_front(error_msg);
    
static func create_error_log_file() -> void:
    # TODO: probably write to file every x seconds?
    pass

static func debug_log(msg : String) -> void:
    if (DEBUG_MODE):
        print(msg);

static func debug_prolog(msg : String) -> void:
    if (DEBUG_PRINT_PROCESS == ENUM_DEBUG_PRN_PROC.ALWAYS):
        print(msg)
    elif (DEBUG_PRINT_PROCESS == ENUM_DEBUG_PRN_PROC.CYCLE):
        var curr_cycle : int = Time.get_ticks_msec();
        if (curr_cycle % cycle < 10 and curr_cycle != last_printed_cycle):
            print(msg);
            last_printed_cycle = curr_cycle;
#endregion
            
# DANGER: this is so hacky maybe this should all be C# to utilize generic typing
static func get_parent_of_type(child : Object, parent_class : Variant) -> Object:
    var parent : Object = child.get_parent();
    while (parent.get_script() != parent_class):
        parent = parent.get_parent();
    return parent;

static func classtype(obj : Node) -> String:
    return obj.get_script();
    
static func a_classtype(obj : Node) -> String:
    while obj.get_script() == null and obj.get_parent():
        obj = obj.get_parent();
    return obj.get_script().get_global_name();
