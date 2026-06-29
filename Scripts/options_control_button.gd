extends Button

var button_flow_handler : Options;

func _on_focus_entered() -> void:
    button_flow_handler.public_set_curr_focus(self);

func _on_focus_exited() -> void:
    button_flow_handler.public_set_last_focused(self);

func _ready() -> void:
    if (button_flow_handler == null):
        var parent : Control = self.get_parent();
        while (not parent is Options):
            parent = parent.get_parent();
        button_flow_handler = parent;
    
    self.focus_entered.connect(_on_focus_entered);
    self.focus_exited.connect(_on_focus_exited);
