package tetris_karl2d

import "core:c"
import "core:fmt"
import SDL "vendor:sdl2"
import TTF "vendor:sdl2/ttf"

WIN_TITLE :: "Tetris"
FONT_PATH :: "assets/font.ttf"
SCORE_SIZE :: 7
LEVEL_SIZE :: 3
WIN_WIDTH :: (GRID_WIDTH + 5) * BLOCK_SIZE
WIN_HEIGHT :: (GRID_HEIGHT + 2) * BLOCK_SIZE

win: ^SDL.Window
rend: ^SDL.Renderer

White: SDL.Color = {0xff, 0xff, 0xff, 0xff}
Gray: SDL.Color = {0xcc, 0xcc, 0xcc, 0xff}
Font_18: ^TTF.Font
Font_32: ^TTF.Font

init_fonts :: proc() -> int {
	if (TTF.Init() != 0) {
		SDL.LogError(0, "error initializing TTF: %s\\n", TTF.GetError())
		return -1
	}

	Font_18 = TTF.OpenFont(FONT_PATH, 18)
	if (Font_18 == nil) {
		SDL.LogError(0, "error opening font 18 %s\n%s\\n", FONT_PATH, TTF.GetError())
		TTF.Quit()
		return -1
	}

	Font_32 = TTF.OpenFont(FONT_PATH, 32)
	if (Font_32 == nil) {
		SDL.LogError(0, "error opening font 32 %s\n%s\\n", FONT_PATH, TTF.GetError())
		TTF.CloseFont(Font_18)
		TTF.Quit()
		return -1
	}

	return 0
}

init_graphics :: proc() -> bool {
	if (SDL.Init(SDL.INIT_VIDEO) != 0) {
		SDL.LogError(0, "error initializing SDL: %s\\n", SDL.GetError())
		return false
	}

	win = SDL.CreateWindow(
		WIN_TITLE,
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		c.int(WIN_WIDTH),
		c.int(WIN_HEIGHT),
		{},
	)

	if (win == nil) {
		SDL.LogError(0, "error creating window: %s\n", SDL.GetError())
		SDL.Quit()
		return false
	}

	rend = SDL.CreateRenderer(win, -1, {.PRESENTVSYNC})
	if (rend == nil) {
		SDL.LogError(0, "error creating renderer: %s\n", SDL.GetError())
		SDL.DestroyWindow(win)
		SDL.Quit()
		return false
	}

	if (init_fonts() != 0) {
		SDL.DestroyWindow(win)
		SDL.Quit()
		return false
	}

	return true
}

render_right_text :: proc(text: cstring, y: int, Font: ^TTF.Font) {
	surface: ^SDL.Surface = TTF.RenderText_Solid(Font, text, Gray)
	texture: ^SDL.Texture = SDL.CreateTextureFromSurface(rend, surface)

	rect: SDL.Rect
	rect.x = (GRID_WIDTH + 3) * BLOCK_SIZE - surface.w / 2
	rect.y = c.int(y)
	rect.w = surface.w
	rect.h = surface.h

	SDL.RenderCopy(rend, texture, nil, &rect)

	SDL.FreeSurface(surface)
	SDL.DestroyTexture(texture)
}

render_score :: proc(score: u32, level: u32) {
	score_str: cstring = fmt.ctprintf("%06d", score)
	render_right_text("SCORE", BLOCK_SIZE, Font_18)
	render_right_text(score_str, BLOCK_SIZE * 2, Font_32)

	level_str: cstring = fmt.ctprintf("%02d", level)
	render_right_text("LEVEL", BLOCK_SIZE * 6, Font_18)
	render_right_text(level_str, BLOCK_SIZE * 7, Font_32)
}

render_game_over_text :: proc(text: cstring, y: int, Font: ^TTF.Font) {
	surface: ^SDL.Surface = TTF.RenderText_Solid(Font, text, White)
	texture: ^SDL.Texture = SDL.CreateTextureFromSurface(rend, surface)

	rect: SDL.Rect
	rect.x = (WIN_WIDTH - surface.w) / 2
	rect.y = c.int(y)
	rect.w = surface.w
	rect.h = surface.h

	SDL.RenderCopy(rend, texture, nil, &rect)

	SDL.FreeSurface(surface)
	SDL.DestroyTexture(texture)
}

render_game_over_message :: proc(score: u32) {
	score_str: cstring = fmt.ctprintf("%06d", score)

	render_game_over_text("GAME OVER", WIN_HEIGHT / 2 - BLOCK_SIZE * 3, Font_32)
	render_game_over_text("YOU SCORED:", WIN_HEIGHT / 2 - BLOCK_SIZE * 2, Font_32)
	render_game_over_text(score_str, WIN_HEIGHT / 2, Font_32)
	render_game_over_text("Press any key to restart...", WIN_HEIGHT / 2 + BLOCK_SIZE * 2, Font_18)
	SDL.RenderPresent(rend)
}

draw_block :: proc(x, y: u32, color: u32) {
	outer: SDL.Rect
	inner: SDL.Rect

	outer.x = c.int((x + 1) * BLOCK_SIZE)
	outer.y = c.int((y + 1) * BLOCK_SIZE)
	outer.w = BLOCK_SIZE
	outer.h = BLOCK_SIZE

	inner.x = c.int((x + 1) * BLOCK_SIZE + 1)
	inner.y = c.int((y + 1) * BLOCK_SIZE + 1)
	inner.w = BLOCK_SIZE - 2
	inner.h = BLOCK_SIZE - 2

	SDL.SetRenderDrawColor(rend, 0x0c, 0x0c, 0x0c, 0xff)
	SDL.RenderFillRect(rend, &outer)

	// Shift bits and extract 8 least significant bits for each color;
	r := u8((color >> 16) & 0xFF)
	g := u8((color >> 8) & 0xFF)
	b := u8(color & 0xFF)

	SDL.SetRenderDrawColor(rend, r, g, b, 0xff)
	SDL.RenderFillRect(rend, &inner)
}

clear_screen :: proc() {
	SDL.SetRenderDrawColor(rend, 0, 0, 0, 0xff)
	SDL.RenderClear(rend)
}

render_frame :: proc(score: u32, level: u32) {
	render_score(score, level)
	SDL.RenderPresent(rend)
}

release_resources :: proc() {
	SDL.DestroyRenderer(rend)
	SDL.DestroyWindow(win)

	TTF.CloseFont(Font_18)
	TTF.CloseFont(Font_32)
	TTF.Quit()

	SDL.Quit()
}
