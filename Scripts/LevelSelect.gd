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
@export var player_portraits : Array[PlayerIcon];

var hiscores : Array[int];
var is_active : bool = false;

var head_array_base : Array[int] = [0, 1, 2, 3];
var head_array_remain : Array[int] = [0, 1, 2, 3];
var face_array_base : Array[int] = [0, 1, 2, 3];
var face_array_remain : Array[int] = [0, 1, 2, 3];
var color_array_base : Array[Color] = [Color("b27ce6"), Color("8abceb"), Color("ddaa8e"), 
Color("9acc8d"), Color("c86d80"), Color("7e8ab7")];
var color_array_remain : Array[Color] = [Color("b27ce6"), Color("8abceb"), Color("ddaa8e"), 
Color("9acc8d"), Color("c86d80"), Color("7e8ab7")];

func init_level_select() -> void:
    if (!SaveDataMgr._instance):
        SaveDataMgr.create_sdm();
    hiscores = SaveDataMgr.get_highscores();

    head_array_remain = head_array_base.duplicate();
    face_array_remain = face_array_base.duplicate();
    color_array_remain = color_array_base.duplicate();
    
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
        GameManager._instance.reset_players();

func _on_menu_transition(who : Node) -> void:
    if (who == self):
        self.visible = true;
        init_level_select();
        is_active = true;
        level1.grab_focus.call_deferred();
    else:
        self.visible = true;
        is_active = false;
        
func assign_head_face_color(p_idx : int) -> Color:
    var color : Color = color_array_remain.pop_at(randi_range(0, color_array_remain.size()-1));
    var r_head : int = Statics.rand_from_arr_v(head_array_remain);
    head_array_remain.erase(r_head);
    var r_face : int = Statics.rand_from_arr_v(face_array_remain);
    face_array_remain.erase(r_face);
    GameManager._instance.player_head_face[p_idx] = [r_head, r_face];
    player_portraits[p_idx].instance(r_head, r_face, color);
    return color
    
func unassign_head_face_color(p_idx : int) -> void:
    if (GameManager._instance.player_head_face[p_idx][0] != -1 and 
    GameManager._instance.player_head_face[p_idx][1] != -1):
        head_array_remain.append(GameManager._instance.player_head_face[p_idx][0]);
        face_array_remain.append(GameManager._instance.player_head_face[p_idx][1]);
    GameManager._instance.player_head_face[p_idx] = [-1, -1];
    #Statics.debug_log("reverting p {0} and inserting color {1}".format([p_idx, GameManager._instance.player_colors[p_idx]]));
    if (GameManager._instance.player_colors[p_idx] != Color.BLACK):
        color_array_remain.append(GameManager._instance.player_colors[p_idx]);
    GameManager._instance.player_colors[p_idx] = Color.BLACK;
        
func player_assignment(ev : InputEvent) -> void:
    if (ev is InputEventKey):
        if (ev.get_physical_keycode_with_modifiers() == KEY_ESCAPE):
            player_portraits[0].visible = !player_portraits[0].visible;
            GameManager._instance.active_players[0] = player_portraits[0].visible;
            if (player_portraits[0].visible):
                GameManager._instance.player_colors[0] = assign_head_face_color(0);
            else: 
                unassign_head_face_color(0);
        elif (ev.get_physical_keycode_with_modifiers() == KEY_DELETE):
            player_portraits[1].visible = !player_portraits[1].visible;
            GameManager._instance.active_players[1] = player_portraits[1].visible;
            if (player_portraits[1].visible):
                GameManager._instance.player_colors[1] = assign_head_face_color(1);
            else: 
                unassign_head_face_color(1);
    if (ev is InputEventJoypadButton and ev.device < 4):
        Statics.debug_log("connected pads {0}".format([str(Input.get_connected_joypads())]))
        player_portraits[ev.device].visible = !player_portraits[ev.device].visible;
        GameManager._instance.active_players[ev.device] = !GameManager._instance.active_players[ev.device];
        if (GameManager._instance.active_players[ev.device]):
            GameManager._instance.player_colors[ev.device] = assign_head_face_color(ev.device);
        else:
            unassign_head_face_color(ev.device);

func _input(event: InputEvent) -> void:
    if (!is_active): return;
    if (event.is_pressed()):
        if (event.is_action(&"start")):
            get_viewport().set_input_as_handled();
            #print(event.as_text());
            player_assignment(event);

func assign_labels(parent : Node, array : Array) -> void:
    for c in parent.get_children():
        array.append(c);
        
func _on_lvl_pressed(lv_idx : int) -> void:
    if (GameManager._instance.active_players.count(true) == 0):
        return;
    GameManager._instance.start_level(lv_idx);
    self.is_active = false;

func _ready() -> void:
    assert(level1 != null, "level 1 button not assigned");
    assign_labels(level1, level1_labels);
    assert(level2 != null, "level 2 button not assigned");
    assign_labels(level2, level2_labels);
    assert(level3 != null, "level 3 button not assigned");
    assign_labels(level3, level3_labels);
    assert(level4 != null, "level 4 button not assigned");
    assign_labels(level4, level4_labels);
    assert(player_portraits and player_portraits.size() ==4, "player portraits not assigned");
    for pp : PlayerIcon in player_portraits:
        pp.visible = false;
    
    GameManager._instance.transition_to.connect(_on_menu_transition);
    back_btn.pressed.connect(_on_back_pressed);
    level1.pressed.connect(_on_lvl_pressed.bind(0));
    level2.pressed.connect(_on_lvl_pressed.bind(1));
    level3.pressed.connect(_on_lvl_pressed.bind(2));
    level4.pressed.connect(_on_lvl_pressed.bind(3));
    init_level_select();
