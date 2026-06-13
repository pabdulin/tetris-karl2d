package tetris_karl2d

import SDL "vendor:sdl2"

InputEvent :: enum {
	QUIT      = -1,
	NO_INPUT  = 0,
	ANY_INPUT = 99,

    MOVE_LEFT,
	MOVE_RIGHT,
	ROTATE_CW, // TODO
    ROTATE_CCW,
	SOFT_DROP_BEGIN,
    SOFT_DROP_END,
	HARD_DROP,
    HOLD, // TODO
    PAUSE, // TODO
}

handle_key_down :: proc(key_code: SDL.Keycode, key_mod: SDL.Keymod) -> InputEvent {
	#partial switch (key_code) {
	case .ESCAPE:
		return .QUIT

	case .LEFT:
		fallthrough
    case .KP_4:
		return .MOVE_LEFT

	case .RIGHT:
		fallthrough
    case .KP_6:
		return .MOVE_RIGHT

	case .UP:
		fallthrough
	case .KP_1:
		fallthrough
	case .KP_5:
		fallthrough
	case .KP_9:
		fallthrough
	case .X:
		return .ROTATE_CW

    case .Z:
        fallthrough
    case .KP_3:
        fallthrough
	case .KP_7:
		return .ROTATE_CCW

	case .DOWN:
		fallthrough
    case .KP_2:
		return .SOFT_DROP_BEGIN

    case .KP_8:
		fallthrough
	case .SPACE:
		return .HARD_DROP
	}

    if key_mod & SDL.KMOD_CTRL != SDL.KMOD_NONE {
        return .ROTATE_CCW
    }

	return .ANY_INPUT
}

handle_key_up :: proc(key_code: SDL.Keycode) -> InputEvent {
	#partial switch (key_code) {
        case .DOWN:
            fallthrough
        case .KP_2:
            fallthrough
        case .s:
            return .SOFT_DROP_END
    }

    return .NO_INPUT
}

listen_for_input :: proc() -> InputEvent {
	event: SDL.Event

	for SDL.PollEvent(&event) {
		if (event.type == .QUIT) {
			return .QUIT
		}
		if (event.type == .KEYDOWN) {
			return handle_key_down(event.key.keysym.sym, SDL.GetModState())
		}
        if (event.type == .KEYUP) {
            return handle_key_up(event.key.keysym.sym)
        }
	}

	return .NO_INPUT
}
