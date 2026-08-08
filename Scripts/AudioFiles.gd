class_name AudioFiles extends Node

static var _instance : AudioFiles = null;
static func instantiate() -> AudioFiles:
    if _instance == null:
        _instance = AudioFiles.new();
    return _instance;
    
const MENU_KEY : String = "menu";
const GAME_KEY : String = "game";
const CLOSE_KEY : String = "game_close";
    
const GAME_BGM : Resource = preload("res://Resources/Audio/gameBgm.ogg");
const GAME_END_SOON : Resource = preload("res://Resources/Audio/closingBgm_12s.ogg")
const GAME_OVER_SCREEN : Resource = preload("res://Resources/Audio/home01.ogg");
const MENU_BGM : Resource = preload("res://Resources/Audio/menuBgm.ogg");
const MENU_ACTION : Resource = preload("res://Resources/Audio/ksl9.ogg");
const MENU_CONFIRM : Resource = preload("res://Resources/Audio/opn3a.ogg");
const MENU_MOVE : Resource = preload("res://Resources/Audio/ksl4a.ogg");
const COUNTDOWN_FINISH : Resource = preload("res://Resources/Audio/スターターピストル.ogg");
const ORDER_UP : Resource = preload("res://Resources/Audio/decide2.ogg");
const ORDER_FAIL : Resource = preload("res://Resources/Audio/quiz2.ogg");
const ORDER_COMPLETE : Resource = preload("res://Resources/Audio/freesound_community-money-collect-1-101476.ogg");
const ACTION_FAIL : Resource = preload("res://Resources/Audio/Quiz-Buzzer05-2(Short).ogg");
const TRASH : Resource = preload("res://Resources/Audio/paperbiri.ogg");
const PC_USE : Resource = preload("res://Resources/Audio/freesound_community-mechanical-keyboard-44701.ogg");
const PRINTER_USE : Resource = preload("res://Resources/Audio/freesound_community-printer-106935.ogg");
const ITEM_BOX : Resource = preload("res://Resources/Audio/freesound_community-pulling-object-cord-cable-from-a-cardboard-box-60414.ogg");
const THROW : Resource = preload("res://Resources/Audio/sword3.ogg");
const ITEM_COMPLETE : Resource = preload("res://Resources/Audio/decide12.ogg");
# TODO: maybe not
const GAME_END : Resource = preload("res://Resources/Audio/笛ピッピー2.ogg");
