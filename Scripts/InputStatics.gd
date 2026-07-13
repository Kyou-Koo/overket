class_name InputStatics

static func regex_match_ps(in_str : String) -> bool:
    var regex : RegEx = RegEx.create_from_string("[Pp][Ss][X12345]|playstation");
    if (regex.search(in_str.to_lower()) != null):
        return true;
    return false;
    
static func regex_match_nin(in_str : String) -> bool:
    # TODO: there's gotta be a better way for grabbing all the randomly named nintendo-layout controllers
    # thanks8bitdo
    var regex : RegEx = RegEx.create_from_string(" nintendo| gamecube| n64| nes|((?<!one)( sn\\d))| sf\\d|ultimate [^c|^2]");
    if (regex.search(in_str.to_lower()) != null):
        return true;
    return false;

static func _kb_txt_short(input: String) -> String:
    # TODO: localize?? (is RMB/etc normal in japanese?)
    if (input.contains("Physical")):
        input = input.left(-11);
    match input:
        "Right Mouse Button":
            return "RMB";
        "Left Mouse Button":
            return "LMB";
        "Shift":
            return "Sft";
        "Enter":
            return "↵";
        "Backspace":
            return "BS";
        "Delete":
            return "Del";
        "QuoteLeft":
            return "`";
        "Escape":
            return "Esc";
        "Minus":
            return "-";
        "Equal":
            return "=";
        "BracketLeft":
            return "[";
        "BracketRight":
            return "]";
        "BackSlash":
            return "\\";
        "CapsLock":
            return "Cap";
        "Semicolon":
            return ";";
        "Apostrophe":
            return "'";
        "Slash":
            return "/";
        "Period":
            return ".";
        "Comma":
            return ",";
        "Up":
            return "↑";
        "Down":
            return "↓";
        "Left":
            return "←";
        "Right":
            return "→";
        _:
            return input;
    
static func create_input_event_from_dict(dict : Dictionary) -> InputEvent:
    match dict["iam"]:
        "keyboard":
            var input_event : InputEventKey = InputEventKey.new();
            input_event.device = dict["device"];
            input_event.physical_keycode = dict["pkeycode"];
            return input_event;
        "button":
            var input_event : InputEventJoypadButton = InputEventJoypadButton.new();
            input_event = (input_event as InputEventJoypadButton);
            input_event.button_index = dict["button"];
            return input_event;
        "axis":
            var input_event : InputEventJoypadMotion = InputEventJoypadMotion.new();
            input_event = (input_event as InputEventJoypadMotion);
            input_event.axis = dict["axis"];
            input_event.axis_value = dict["av"];
            return input_event;
        _:
            return null;

# TODO: create input txt to short using dictionary as input
static func input_text_string_to_short_txt(ev : InputEvent, is_pad : bool) -> String:
    var input : String = ev.as_text();
    if (!is_pad): return _kb_txt_short(input);
    # TODO: determine joy index
    var is_ps : bool = regex_match_ps(Input.get_joy_name(ev.device));
    var is_nin : bool = regex_match_nin(Input.get_joy_name(ev.device));
    # match buttons
    if (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_A):
        if (is_ps):
            return "✖"
        elif (is_nin):
            return "B"
        else:
            return "A"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_B):
        if (is_ps):
            return "〇"
        elif (is_nin):
            return "A"
        else:
            return "B"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_X):
        if (is_ps):
            return "□"
        elif (is_nin):
            return "Y"
        else:
            return "X"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_Y):
        if (is_ps):
            return "△"
        elif (is_nin):
            return "X"
        else:
            return "Y"
    # TODO: probably should change button shapes here down
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_BACK):
        return "Sel"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_LEFT_STICK):
        return "LS↓"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_RIGHT_STICK):
        return "RS↓"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_LEFT_SHOULDER):
        if (is_ps):
            return "L1";
        else:
            return "L"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_RIGHT_SHOULDER):
        if (is_ps):
            return "R1"
        else:
            return "R"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_DPAD_UP):
        return "↑"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_DPAD_DOWN):
        return "↓"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_DPAD_LEFT):
        return "←"
    elif (ev is InputEventJoypadButton and ev.button_index == JoyButton.JOY_BUTTON_DPAD_RIGHT):
        return "→"
    # match triggers/stick motion
    # left stick
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_LEFT_Y and ev.axis_value > 0.1):
        return "L↑"
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_LEFT_Y and ev.axis_value < -0.1):
        return "L↓"
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_LEFT_X and ev.axis_value > 0.1):
        return "L→"
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_LEFT_X and ev.axis_value < -0.1):
        return "L←"
    # right stick
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_RIGHT_Y and ev.axis_value > 0.1):
        return "R↑"
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_RIGHT_Y and ev.axis_value < -0.1):
        return "R↓"
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_RIGHT_X and ev.axis_value > 0.1):
        return "R→"
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_RIGHT_X and ev.axis_value < -0.1):
        return "R←"
    #sticks
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_TRIGGER_LEFT and ev.axis_value > 0.1):
        if (is_ps):
            return "L2"
        else:
            return "LT"
    elif (ev is InputEventJoypadMotion and ev.axis == JoyAxis.JOY_AXIS_TRIGGER_RIGHT and ev.axis_value > 0.1):
        if (is_ps):
            return "R2"
        else:
            return "RT"
    return ""
