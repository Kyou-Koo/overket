class_name CarryableObjects;

enum CarryObjEnum {
    #             12345678
    NONE =      0b00000000, # 0
    PAPER =     0b00000001,  # 1
    DATA =      0b00000010,  # 2
    BOOK =      0b00000100,  # 4    1000
    SHIKISHI =  0b00001000,  # 8    800
    POSTCARD =  0b00010000,  # 16   
    ACRYLIC =   0b00100000,  # 32   600
    KEYHOLDER = 0b01000000,  # 64   500
    BAG =       0b10000000,  # 128  500
    #             12345678
}

static var prices : Dictionary[CarryObjEnum, int] = {
    CarryObjEnum.BOOK: 1000,
    CarryObjEnum.SHIKISHI: 800,
    CarryObjEnum.ACRYLIC: 600,
    CarryObjEnum.KEYHOLDER: 500,
    CarryObjEnum.BAG: 300,
}

# at the moment postcard is dropped
static var customer_requests : Array[int] = [
    # 12345678
    0b00000100, # book
    0b00001000, # shikishi
    0b00100000, # acrylic
    0b01000000, # keyholder
    # below has bag
    0b10000100, # book
    0b10001100, # book, shikishi
    0b10101100, # book, shikishi, acryl
    0b11001100, # book, shikishi, key
    0b10100100, # book, acryl
    0b11100100, # book, acryl, key
    0b11000100, # book, key
]

static var carry_obj_array : Array[CarryObjEnum] = [
    CarryObjEnum.PAPER,
    CarryObjEnum.DATA,
    CarryObjEnum.BOOK,
    CarryObjEnum.SHIKISHI,
    CarryObjEnum.POSTCARD,
    CarryObjEnum.ACRYLIC,
    CarryObjEnum.KEYHOLDER,
    CarryObjEnum.BAG,
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
    for o : CarryObjEnum in carry_obj_array:
        if (o & obj):
            obj_array.append(o);

    return obj_array;
    
static func calc_value(items : Array[CarryObjEnum]) -> int:
    var value : int = 0;
    for item in items:
        value += prices[item];
    return value;
