class_name LevelUI extends Control

@export var debug_mode : bool = false;
@export var parent_level : Level;
@export var request_scn_path : String;
var request_scn_pack : PackedScene;
var request_scns : Array[Request];
var request_y : float = 0.0;
@export var timer_holder : NinePatchRect;
@export var money_holder : NinePatchRect;

func remove_request(r : Request) -> void:
    var order : int = request_scns.find(r);
    # TODO: for now assume it animates up
    var removed_y : float = r.position.y;
    request_scns.remove_at(order);
    r.queue_free();
    # push remaining scenes up
    if (order < request_scns.size()):
        for i : int in range(order, request_scns.size()):
            var next_y : float = request_scns[i].position.y;
            request_scns[i].update_pos(removed_y);
            removed_y = next_y;

func _input(event: InputEvent) -> void:
    if (!debug_mode):
        return;
    if (event is InputEventKey):
        if (event.keycode == KEY_Z):
            pass
            # spawn request
        if (event.keycode == KEY_X):
            pass
            # remove topmost request

func _ready() -> void:
    # safety:
    debug_mode = Statics.DEBUG_MODE;
    request_scn_pack = load(request_scn_path);
