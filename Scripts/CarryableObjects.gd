class_name CarryableObjects;

enum CarryObjEnum {
    NONE =      0b00000000, # 0
    PAPER =     0b00000001,  # 1
    DATA =      0b00000010,  # 2
    BOOK =      0b00000100,  # 4
    SHIKISHI =  0b00001000,  # 8
    POSTCARD =  0b00010000,  # 16
    ACRYLIC =   0b00100000,  # 32
    KEYHOLDER = 0b01000000,  # 64
    BAG =       0b10000000,  # 128
}

static var CarryObjArray : Array[CarryObjEnum] = [
    CarryObjEnum.PAPER,
    CarryObjEnum.DATA,
    CarryObjEnum.BOOK,
    CarryObjEnum.SHIKISHI,
    CarryObjEnum.POSTCARD,
    CarryObjEnum.ACRYLIC,
    CarryObjEnum.KEYHOLDER,
]

static func join_carried_objects(obj_list : Array[CarryObjEnum]) -> int:
    var new_obj : int = CarryObjEnum.NONE;
    for o : CarryObjEnum in obj_list:
        new_obj = (new_obj | o);
    
    if (new_obj > 255):
        push_warning("Output object is out of enum bounds {0}".format([
            obj_list,
        ]));
    
    return new_obj;

static func deserialize_objects(obj : int) -> Array[CarryObjEnum]:
    var obj_array : Array[CarryObjEnum];
    for o : CarryObjEnum in CarryObjArray:
        if (o & obj):
            obj_array.append(o);

    return obj_array;
