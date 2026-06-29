extends Node2D

@onready var text_display : Label = self.get_child(0);

func _input(event : InputEvent) -> void:
    if Input.is_anything_pressed():
        if (event.is_action("back") or event.is_action("fwd") or event.is_action("left") or event.is_action("right")):
            return;
        #if (event is InputEventJoypadMotion):
            #print(event.as_text().substr(22, 1))
            #print(event.as_text());
            #if (event.as_text().substr(22, 1).to_int() < 4):
                #return;
        text_display.text = "Device {0} pressed {1}".format([
            event.device,
            event.as_text(),
        ])

func _ready() -> void:
    print(InputMap.get_actions());
    for act : StringName in InputMap.get_actions():
        print("{0} | {1}".format([act, str(InputMap.action_get_events(act))]));
