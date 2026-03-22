package tetris_karl2d

import SDL "vendor:sdl2"

InputEvent::enum {
  QUIT = -1,
  NO_INPUT = 0,
  ANY_INPUT = 99,
  LEFT = 2,
  RIGHT = 3,
  DOWN = 4,
  ROTATE = 5,
  SOFT_DROP = 6,
  HARD_DROP = 7,
};

handle_key_down::proc(key_code:SDL.Keycode)->InputEvent {
  #partial switch (key_code) {
  case SDLK_ESCAPE:
    return QUIT;
  case SDLK_LEFT:
  case SDLK_a:
    return LEFT;
  case SDLK_RIGHT:
  case SDLK_d:
    return RIGHT;
  case SDLK_UP:
  case SDLK_w:
    return ROTATE;
  case SDLK_DOWN:
  case SDLK_s:
    return SOFT_DROP;
  case SDLK_SPACE:
    return HARD_DROP;
  }
  return ANY_INPUT;
}

listen_for_input::proc(game_over:int)->InputEvent {
  SDL.Event event;

  for SDL.PollEvent(&event) {
    if (event.type == SDL.QUIT) {
      return QUIT;
    }
    if (event.type == SDL.KEYDOWN) {
      return handle_key_down(event.key.keysym.sym);
    }
  }

  return NO_INPUT;
}
