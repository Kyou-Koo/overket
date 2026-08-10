class_name GameOver extends Control

@export var score : Label;
@export var end_button : Button;
@export var level : Level

func activate(money : int) -> void:
    score.text = "￥{0}".format([money]);
    self.visible = true;
    end_button.grab_focus.call_deferred();
    AudioManager._instance.stop_all_BGM();
    AudioManager._instance.play_SFX(AudioFiles.GAME_OVER_SCREEN);

func _on_end_pressed() -> void:
    self.visible = false;
    level.clean_up_and_return_to_menu();

func _ready() -> void:
    assert(score != null, "assign score label");
    assert(end_button != null, "assign end button");
    end_button.pressed.connect(_on_end_pressed);
    assert(level != null, "assign level");
