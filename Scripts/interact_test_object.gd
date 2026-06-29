extends TimerMachineBase

func _process(delta: float) -> void:
    super._process(delta);

func _ready() -> void:
    super._ready();
    progress_bar_holder = $Sprite3D;
    progress_bar = $SubViewport/TextureProgressBar;
    progress_bar.visible = false;

func _init() -> void:
    super._init();
