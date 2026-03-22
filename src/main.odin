package tetris_karl2d

import SDL "vendor:sdl2"

// #ifdef __EMSCRIPTEN__
// void run_loop() { game_loop(); }
// #endif

main::proc() {
// #ifndef __EMSCRIPTEN__
  srand(time(NULL)); // seed the random number generator
// #endif

  if (init_game() != 0) {
    SDL.LogError(0, "Failed to start game\n");
    return 1;
  };

// #ifdef __EMSCRIPTEN__
//   emscripten_set_main_loop(run_loop, 0, 1);
// #else
  for ;; {
    int res = game_loop();

    if (res != 0) {
      if (res < 0) {
        SDL.LogError(0, "Unexpected error occured\n");
      }
      break;
    }
  }
// #endif

  if (terminate_game() != 0) {
    SDL.LogError(0, "Error while terminating game\n");
  };

  return 0;
}
