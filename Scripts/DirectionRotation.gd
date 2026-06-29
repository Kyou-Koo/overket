class_name DirRot

var direction : Vector3:
    get:
        return direction;
    set(val):
        direction = val;
        
var rotation : Vector3:
    get:
        return rotation;
    set(val):
        rotation = val;

func _init(dir : Vector3 = Vector3.ZERO, rot : Vector3 = Vector3.ZERO) -> void:
    direction = dir;
    rotation = rot;

func normalize() -> void:
    direction = direction.normalized();
    
func _to_string() -> String:
    return "d: {0} r: {1}".format([direction, rotation]);
    
