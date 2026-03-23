package tetris_karl2d

import SDL "vendor:sdl2"

InputEvent :: enum {
	QUIT      = -1,
	NO_INPUT  = 0,
	ANY_INPUT = 99,
	LEFT      = 2,
	RIGHT     = 3,
	DOWN      = 4,
	ROTATE    = 5,
	SOFT_DROP = 6,
	HARD_DROP = 7,
}

handle_key_down :: proc(key_code: SDL.Keycode) -> InputEvent {
	#partial switch (key_code) {
	case .ESCAPE:
		return .QUIT

	case .LEFT:
		fallthrough
	case .a:
		return .LEFT

	case .RIGHT:
		fallthrough
	case .d:
		return .RIGHT

	case .UP:
		fallthrough
	case .w:
		return .ROTATE

	case .DOWN:
		fallthrough
	case .s:
		return .SOFT_DROP

	case .SPACE:
		return .HARD_DROP
	}

	return .ANY_INPUT
}

listen_for_input :: proc() -> InputEvent {
	event: SDL.Event

	for SDL.PollEvent(&event) {
		if (event.type == .QUIT) {
			return .QUIT
		}
		if (event.type == .KEYDOWN) {
			return handle_key_down(event.key.keysym.sym)
		}
	}

	return .NO_INPUT
}
