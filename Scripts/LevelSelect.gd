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

var hiscores : Array[int];

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
    pass;

func _input(event: InputEvent) -> void:
    if (event.is_pressed()):
        if (event.is_action(&"start")):
            print(event.as_text());

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
    
    back_btn.pressed.connect(_on_back_pressed);
    init_level_select();
