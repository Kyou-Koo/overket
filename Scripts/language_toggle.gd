extends Control

@export var button_flow_handler : Options;
@export var ja_button : Button;
@export var en_button : Button;
@export var focus_background : Control;
var is_child_button_focused : bool = false;
var active_button : Button;

signal child_set_active(b : Button);

func public_set_active_button(b : Button) -> void:
    active_button = b;
    child_set_active.emit(b);
    # TODO: should this be handled by the game manager????
    TranslationServer.set_locale(b.name.to_lower());
    GameManager._instance.savedata = SaveDataMgr.update_savefield(
        b.name.to_lower(), 
        SaveDataMgr.FIELD.LANGUAGE, 
        GameManager._instance.savedata);

func _on_focus_entered() -> void:
    if (!button_flow_handler.is_active):
        return;
    Statics.debug_log("call check {0}".format([self.name]));
    active_button.grab_focus.call_deferred();

func _on_child_button_focus_exited() -> void:
    if (!button_flow_handler.is_active):
        return;
    if (ja_button.has_focus() or en_button.has_focus()):
        return;
    focus_background.visible = false;

func _ready() -> void:
    # safety catches
    var children : Array[Node] = self.get_children();
    for c in children:
        if (c is NinePatchRect):
            focus_background = c;
    
    assert(ja_button != null, "Button must exist");
    assert(en_button != null, "Lang Toggle requires 2 buttons");
    assert(focus_background != null, "Focus background required");
    
    if (button_flow_handler == null):
        var parent : Control = self.get_parent();
        while (not parent is Options):
            parent = parent.get_parent();
        button_flow_handler = parent;

    # defined by savedata
    var lang_str : String;
    if (GameManager._instance != null):
        GameManager._instance.set_lang_from_save();
        lang_str = GameManager._instance.savedata["lang"];
    var radio_group : ButtonGroup = ButtonGroup.new();
    radio_group.allow_unpress = false;
    ja_button.toggle_mode = true;
    ja_button.button_group = radio_group;
    en_button.toggle_mode = true;
    en_button.button_group = radio_group;
    if (lang_str == "ja"):
        active_button = ja_button;
        ja_button.button_pressed = true;
    else:
        active_button = en_button;
        en_button.button_pressed = true;
    child_set_active.emit(active_button);

    ja_button.focus_exited.connect(_on_child_button_focus_exited);
    en_button.focus_exited.connect(_on_child_button_focus_exited);
    self.focus_entered.connect(_on_focus_entered);

    focus_background.visible = false;
    Statics.debug_log("where is focus bg: {0}, visible? {1}".format([focus_background.name, focus_background.visible]));
