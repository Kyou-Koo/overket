extends TimerMachineBase

func public_interact_object(delta : float = 0.0) -> bool:
    var can_update : bool = super.public_interact_object(delta);
    if (can_update and !GameManager._instance.level_level_active.game_ended):
        AudioManager._instance.play_BGM(ok_id, AudioFiles.PC_USE, AudioFiles.PC_USE);
    else:
        AudioManager._instance.stop_specific_BGM(ok_id);
    return can_update;

func _process(delta: float) -> void:
    super._process(delta);
    if (Time.get_ticks_msec() - interact_interval > last_interact_time or
    GameManager._instance.level_level_active.game_ended):
        AudioManager._instance.stop_specific_BGM(ok_id);

func _ready() -> void:
    super._ready();
    progress_bar.visible = false;

func _init() -> void:
    super._init();
