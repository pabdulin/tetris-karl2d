package tetris_karl2d

import "core:fmt"
import SDL "vendor:sdl2"
import TTF "vendor:sdl2/ttf"

WIN_TITLE ::"Tetris"

// #ifdef __ENSCRIPTEN__
// #define FONT_PATH "font.ttf"
// #else
FONT_PATH:: "assets/font.ttf"
// #endif

SCORE_SIZE:: 7
LEVEL_SIZE:: 3

WIN_WIDTH :int: (GRID_WIDTH + 5) * BLOCK_SIZE;
WIN_HEIGHT :int: (GRID_HEIGHT + 2) * BLOCK_SIZE;

win:^SDL.Window;
rend:^SDL.Renderer;

 White:SDL.Color = {0xff, 0xff, 0xff};
 Gray:SDL.Color = {0xcc, 0xcc, 0xcc};
 Font_18:^TTF.Font;
 Font_32:^TTF.Font;

init_fonts::proc()->int {
  if (TTF.Init() != 0) {
    SDL.LogError(0, "error initializing TTF: %s\\n", TTF.GetError());
    return -1;
  };

  Font_18 = TTF.OpenFont(FONT_PATH, 18);
  if (!Font_18) {
    SDL.LogError(0, "error opening font 18 %s\n%s\\n", FONT_PATH,
                 TTF.GetError());
    TTF.Quit();
    return -1;
  }

  Font_32 = TTF.OpenFont(FONT_PATH, 32);
  if (!Font_32) {
    SDL.LogError(0, "error opening font 32 %s\n%s\\n", FONT_PATH,
                 TTF.GetError());
    TTF.CloseFont(Font_18);
    TTF.Quit();
    return -1;
  }

  return 0;
}

init_graphics::proc()->int {
  if (SDL.Init(SDL.INIT_VIDEO) != 0) {
    SDL.LogError(0, "error initializing SDL: %s\\n", SDL.GetError());
    return -1;
  }

  win = SDL.CreateWindow(WIN_TITLE, SDL.WINDOWPOS_CENTERED,
                         SDL.WINDOWPOS_CENTERED, WIN_WIDTH, WIN_HEIGHT, 0);

  if (!win) {
    SDL.LogError(0, "error creating window: %s\n", SDL.GetError());
    SDL.Quit();
    return -1;
  }

  rend = SDL.CreateRenderer(win, -1, SDL.RENDERER_PRESENTVSYNC);
  if (!rend) {
    SDL.LogError(0, "error creating renderer: %s\n", SDL.GetError());
    SDL.DestroyWindow(win);
    SDL.Quit();
    return -1;
  }

  SDL.CreateRGBSurface(0, WIN_WIDTH, WIN_HEIGHT, 32, 0, 0, 0, 0);

  if (init_fonts() != 0) {
    SDL.DestroyWindow(win);
    SDL.Quit();
    return -1;
  };

  return 0;
}

render_right_text::proc(text:cstring, y:int, Font:^TTF.Font) {
  surface :^SDL.Surface= TTF.RenderText_Solid(Font, text, Gray);
  texture :^SDL.Texture= SDL.CreateTextureFromSurface(rend, surface);

  rect:SDL.Rect;
  rect.x = (GRID_WIDTH + 3) * BLOCK_SIZE - surface->w / 2;
  rect.y = y;
  rect.w = surface->w;
  rect.h = surface->h;

  SDL.RenderCopy(rend, texture, NULL, &rect);

  SDL.FreeSurface(surface);
  SDL.DestroyTexture(texture);
};

render_score::proc(score:int, level:int) {
  score_str:cstring//[SCORE_SIZE];
  snprintf(score_str, SCORE_SIZE, "%0*d", SCORE_SIZE - 1, score);

  render_right_text("SCORE", BLOCK_SIZE, Font_18);
  render_right_text(score_str, BLOCK_SIZE * 2, Font_32);

  level_str:cstring//[3];
  snprintf(level_str, 3, "%0*d", LEVEL_SIZE - 1, level);

  render_right_text("LEVEL", BLOCK_SIZE * 6, Font_18);
  render_right_text(level_str, BLOCK_SIZE * 7, Font_32);
}

render_game_over_text::proc(text:cstring, y:int, Font:^TTF.Font) {
  SDL.Surface *surface = TTF.RenderText_Solid(Font, text, White);
  SDL.Texture *texture = SDL.CreateTextureFromSurface(rend, surface);

  rect:SDL.Rect;
  rect.x = (WIN_WIDTH - surface->w) / 2;
  rect.y = y;
  rect.w = surface->w;
  rect.h = surface->h;

  SDL.RenderCopy(rend, texture, NULL, &rect);

  SDL.FreeSurface(surface);
  SDL.DestroyTexture(texture);
}

render_game_over_message::proc(score:int) {
  score_str:cstring//[SCORE_SIZE];
  snprintf(score_str, SCORE_SIZE, "%i", score);

  render_game_over_text("GAME OVER", WIN_HEIGHT / 2 - BLOCK_SIZE * 3, Font_32);
  render_game_over_text("YOU SCORED:", WIN_HEIGHT / 2 - BLOCK_SIZE * 2,
                        Font_32);
  render_game_over_text(score_str, WIN_HEIGHT / 2, Font_32);
  render_game_over_text("Press any key to restart...",
                        WIN_HEIGHT / 2 + BLOCK_SIZE * 2, Font_18);
  SDL.RenderPresent(rend);
}

draw_block::proc( x:int,  y:int,  color:u32) {
  outer:SDL.Rect;
  inner:SDL.Rect;

  outer.x = (x + 1) * BLOCK_SIZE;
  outer.y = (y + 1) * BLOCK_SIZE;
  outer.w = BLOCK_SIZE;
  outer.h = BLOCK_SIZE;

  inner.x = (x + 1) * BLOCK_SIZE + 1;
  inner.y = (y + 1) * BLOCK_SIZE + 1;
  inner.w = BLOCK_SIZE - 2;
  inner.h = BLOCK_SIZE - 2;

  SDL.SetRenderDrawColor(rend, 0x0c, 0x0c, 0x0c, 0xff);
  SDL.RenderFillRect(rend, &outer);

  r, g, b:u32;

  // Shift bits and extract 8 least significant bits for each color;
  r = (color >> 16) & 0xFF;
  g = (color >> 8) & 0xFF;
  b = color & 0xFF;

  SDL.SetRenderDrawColor(rend, r, g, b, 0xff);
  SDL.RenderFillRect(rend, &inner);
}

clear_screen::proc() {
  SDL.SetRenderDrawColor(rend, 0, 0, 0, 0);
  SDL.RenderClear(rend);
}

render_frame::proc(score:int, level:int) {
  render_score(score, level);
  SDL.RenderPresent(rend);
}

release_resources::proc() {
  SDL.DestroyRenderer(rend);
  SDL.DestroyWindow(win);

  TTF.CloseFont(Font_18);
  TTF.CloseFont(Font_32);
  TTF.Quit();

  SDL.Quit();
}
