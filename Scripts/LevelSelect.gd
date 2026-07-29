class_name LevelSelect extends Control

@export_category("Buttons")
@export var level1 : TextureButton;
@export var level2 : TextureButton;
@export var level3 : TextureButton;
@export var level4 : TextureButton;
var level1_labels : Array[Label];
var level2_labels : Array[Label];
var level3_labels : Array[Label];
var level4_labels : Array[Label];
@export var back_btn : Button;
@export_category("Labels")
@export var lvl_select : Label;
@export var explanation : Label;
@export_category("Customers")
@export var player1 : Control;
@export var player2 : Control;
@export var player3 : Control;
@export var player4 : Control;

var hiscores : Array[int];
var is_active : bool = false;

func init_level_select() -> void:
    if (!SaveDataMgr._instance):
        SaveDataMgr.create_sdm();
    hiscores = SaveDataMgr.get_highscores();

    display_hiscore(level1_labels[1], 0);
    display_hiscore(level2_labels[1], 1);
    display_hiscore(level3_labels[1], 2);
    display_hiscore(level4_labels[1], 3);

    level1.grab_focus.call_deferred();

func format_level_select_text(text : String, lefttoright : bool) -> String:
    var output_str : String;
    var text_split : PackedStringArray = text.split(" ");
    var longest_word : int = 0;
    for word : String in text_split:
        if (word.length() > longest_word):
            longest_word = word.length();
    if (lefttoright):
        for i : int in longest_word:
            var incoming_str : String
            for j : int in range(text_split.size()):
                var gap : String = "";
                if (j != 0):
                    gap = " "
                var new_letter : String = " ";
                if (i < text_split[j].length()):
                    new_letter = text_split[j][i];
                output_str = output_str + gap + new_letter;
                incoming_str = incoming_str + gap + new_letter;
            Statics.debug_log("test output: " + incoming_str)
            output_str = output_str + "\n";
    return output_str;

func display_hiscore(label : Label, level : int) -> void:
    var txt_prefix : String = "☆￥";
    if (hiscores.size() > 0 and hiscores[level] != 0):
        label.text = txt_prefix + SaveDataMgr._instance.savedata["highscore"][level];
    else:
        label.text = txt_prefix + "----";

func _on_back_pressed() -> void:
    if (is_active):
        GameManager._instance.public_rotate_camera(
            GameManager._instance.main_cam_origin_rot, 
            GameManager.MENU.MAIN);

func _on_menu_transition(who : Node) -> void:
    if (who == self):
        self.visible = true;
        init_level_select();
        is_active = true;
        level1.grab_focus.call_deferred();
    else:
        self.visible = true;
        is_active = false;
        
func player_assignment(ev : InputEvent) -> void:
    if (ev is InputEventKey):
        if (ev.get_physical_keycode_with_modifiers() == KEY_ESCAPE):
            GameManager._instance.active_players["p1"] = ev.device;

func _input(event: InputEvent) -> void:
    if (!is_active): return;
    if (event.is_pressed()):
        if (event.is_action(&"start")):
            get_viewport().set_input_as_handled();
            print(event.as_text());
            player_assignment(event);

func assign_labels(parent : Node, array : Array) -> void:
    for c in parent.get_children():
        array.append(c);

func _ready() -> void:
    assert(level1 != null, "level 1 button not assigned");
    assign_labels(level1, level1_labels);
    assert(level2 != null, "level 2 button not assigned");
    assign_labels(level2, level2_labels);
    assert(level3 != null, "level 3 button not assigned");
    assign_labels(level3, level3_labels);
    assert(level4 != null, "level 4 button not assigned");
    assign_labels(level4, level4_labels);
    assert(player1 != null, "p1 not assigned");
    player1.visible = false;
    assert(player2 != null, "p2 not assigned");
    player2.visible = false;
    assert(player3 != null, "p3 not assigned");
    player3.visible = false;
    assert(player4 != null, "p4 not assigned");
    player4.visible = false;
    
    GameManager._instance.transition_to.connect(_on_menu_transition);
    back_btn.pressed.connect(_on_back_pressed);
    init_level_select();
