extends TimerMachineBase

func public_interact_object(delta : float = 0.0) -> bool:
    var can_update : bool = super.public_interact_object(delta);
    if (can_update):
        AudioManager._instance.play_BGM(ok_id, AudioFiles.PC_USE, AudioFiles.PC_USE);
    else:
        AudioManager._instance.stop_specific_BGM(ok_id);
    return can_update;

func _process(delta: float) -> void:
    super._process(delta);
    # TODO: confirm process doesn't kill the game
    if (Time.get_ticks_msec() - interact_interval > last_interact_time):
        AudioManager._instance.stop_specific_BGM(ok_id);

func _ready() -> void:
    super._ready();
    progress_bar.visible = false;

func _init() -> void:
    super._init();
