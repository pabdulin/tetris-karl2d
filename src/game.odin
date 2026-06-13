package tetris_karl2d

import "core:math/rand"
import SDL "vendor:sdl2"

BLOCK_SIZE :: 40
GRID_WIDTH :: 10
GRID_HEIGHT :: 20

// Grid is represented as m x n matrix. Values are color indices for
// occupied cells or 0 for empty cells
grid: [GRID_WIDTH][GRID_HEIGHT]u32 = {}
// Array of rows that need to be destroyed
to_destroy: [GRID_HEIGHT]u32 = {}

game_over: bool = false
score: u32 = 0

iteration: u32 = 0
lines_cleared: u32 = 0

current_level: u32 = 0
fall_freq: u32 = 48
MAX_LEVEL_FREQ: u32 : 15
LEVEL_FREQS: [15]u32 = {48, 43, 38, 33, 28, 23, 18, 13, 8, 6, 5, 4, 3, 2, 1}
SOFT_FREQ: u32 : 3
HARD_FREQ: u32 : 1
N_COLORS: u32 : 14
// first el is an empty cell
COLORS: [14]u32 = {
	0x111111,
	0xFFC82E,
	0xFEFB34,
	0x53DA3F,
	0x01EDFA,
	0xDD0AB2,
	0xEA141C,
	0xFE4819,
	0xFF910C,
	0x39892F,
	0x0077D3,
	0x78256F,
	0x2E2E84,
	0x485DC5,
}

// Array of blocks in the current shape
// Each value pair corresponds to the shift from the shape
// position over x and y axis
current_shape: [8]i32 = {}
// Index of the color in the COLORS array
current_shape_color: u32 = 0
// Index of the current shape in the SHAPES array
current_shape_type: u32

// Current shape coordinates
current_x: i32 = 0
current_y: i32 = 0

// Represent shapes as an array of 8 ints.
// Each pair (0+1, 2+3, 4+5, 6+7) represents the shift from the shape position over x and y axis
N_SHAPES: u32 : 7
SHAPES: [7][8]i32 = {
	{0, 0, 1, 0, 0, 1, 1, 1}, // O
	{0, 0, -1, 0, 1, 0, 0, 1}, // T
	{0, 0, 0, -1, 0, 1, 1, 1}, // L
	{0, 0, 0, -1, 0, 1, -1, 1}, // J
	{0, 0, 0, -1, 0, 1, 0, 2}, // I
	{0, 0, 1, 0, 0, 1, -1, 1}, // S
	{0, 0, -1, 0, 0, 1, 1, 1}, // Z
}

FRAME_DELAY :: 16 // 1000 / 16 ~= 60fps
RESTART_DELAY :: 300
SCORE_SINGLE :: 1
SCORE_LINE :: 100

get_curr_fall_freq :: proc() -> u32 {
	if (current_level >= MAX_LEVEL_FREQ) {
		return LEVEL_FREQS[MAX_LEVEL_FREQ - 1]
	}
	return LEVEL_FREQS[current_level]
}

state_changed: bool = false

reset_fall_freq :: proc() {fall_freq = get_curr_fall_freq()}

update_fall_freq :: proc(new: u32) {
	calculated: u32 = get_curr_fall_freq()
	if (calculated < new) {
		fall_freq = calculated
	} else {
		fall_freq = new
	}
}

end_game :: proc() {
	game_over = true
	clear_screen()
}

spawn_shape :: proc() {
	state_changed = true

	current_shape_type = u32(rand.uint_max(uint(N_SHAPES)))
	current_shape_color = u32(rand.uint_max(uint(N_COLORS - 1)) + 1)

	for i: i32 = 0; i < 8; i += 1 {
		current_shape[i] = SHAPES[current_shape_type][i]
	}

	current_x = GRID_WIDTH / 2

	// Check for top collisions with existing blocks in the grid
	// If we spot any collision, we'll start with negative current_y
	x, y: i32
	for current_y = -2; current_y < 0; current_y += 1 {
		for i: i32 = 0; i < 4; i += 1 {
			x = current_shape[i * 2] + current_x
			y = current_shape[i * 2 + 1] + current_y + 1

			if (y >= 0 && grid[x][y] != 0) {
				return
			}
		}
	}
}

restart_game :: proc() {
	for i: i32 = 0; i < GRID_WIDTH; i += 1 {
		for j: i32 = 0; j < GRID_HEIGHT; j += 1 {
			grid[i][j] = 0
		}
	}

	game_over = false
	current_level = 0
	lines_cleared = 0
	score = 0

	spawn_shape()
	SDL.Delay(u32(RESTART_DELAY))
}

destroy_row :: proc(row: u32) {
	// shift grid content down 1 line
    for j: u32 = row; j > 0; j -= 1 {
		for i: u32 = 0; i < GRID_WIDTH; i += 1 {
			grid[i][j] = grid[i][j - 1]
		}
	}

    // clear topmost line
    for i: u32 = 0; i < GRID_WIDTH; i += 1 {
			grid[i][0] = 0
		}

	lines_cleared += 1
	if (lines_cleared % 10 == 0) {
		current_level += 1
	}
}

clean_destroyed_blocks :: proc() {
	count := 0

	for j: u32 = 0; j < GRID_HEIGHT; j += 1 {
		if (to_destroy[j] != 0) {
			count += 1

			to_destroy[j] = 0
			for i: u32 = 0; i < GRID_WIDTH; i += 1 {
				grid[i][j] = 0
			}
			destroy_row(j)
		}
	}

	if (count != 0) {
		score += u32(SCORE_LINE * (1 + 2 * (count - 1)))
	}
}

row_is_full :: proc(y: i32) -> int {
    // outside of the well always false
    if (y < 0) {
        return 0
    }

	if (to_destroy[y] != 0) { 	// can be negative at the end of the game
		return 1
	}

	for i: i32 = 0; i < GRID_WIDTH; i += 1 {
		if (grid[i][y] == 0) {
			return 0
		}
	}

	to_destroy[y] = 1
	return 1
}

lock_shape :: proc() {
	x, y: i32

	local_to_destroy: bool = false

	for i: i32 = 0; i < 4; i += 1 {
		x = current_shape[i * 2] + current_x
		y = current_shape[i * 2 + 1] + current_y

		if (x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT) {
			grid[x][y] = current_shape_color
		}

        // TODO (pabdulin): this check is performed multiple times
        // and looks like it's unnecessary as we can check content of to_destroy array
		if (row_is_full(y) != 0) {
			local_to_destroy = true
		} else {
            // if one of the locked shape cells is outside of the grid
			if (y < 0) {
				end_game()
			}
		}
	}

	if (local_to_destroy) {
		clean_destroyed_blocks()
	}

	iteration = 0
	score += SCORE_SINGLE
	reset_fall_freq()
	spawn_shape()
}

detect_collision :: proc(x, y: i32) -> i32 {
	if (x < 0 || x >= GRID_WIDTH) {
		return 1
	}

	if (y >= GRID_HEIGHT) { 	// collisions at the top are OK
		return 1
	}

	if (y >= 0 && grid[x][y] != 0) {
		return 1
	}

	return 0
}

rotate_shape_ccw :: proc() {
	reset_fall_freq()

	if (current_shape_type == 0) {
		return // O-shape should not be rotated
	}

	state_changed = true

	temp: [8]i32 = {}

	x, y: i32

	for i: i32 = 0; i < 4; i += 1 {
		temp[i * 2] = current_shape[i * 2 + 1]
		temp[i * 2 + 1] = -current_shape[i * 2]

		x = temp[i * 2] + current_x
		y = temp[i * 2 + 1] + current_y

		if (detect_collision(x, y) != 0) {
			return
		}
	}

	for i: i32 = 0; i < 8; i += 1 {
		current_shape[i] = temp[i]
	}
}

move_side :: proc(direction: i32) {
	reset_fall_freq()

	x, y: i32

	for i: i32 = 0; i < 4; i += 1 {
		x = current_shape[i * 2] + current_x + direction
		y = current_shape[i * 2 + 1] + current_y

		if (detect_collision(x, y) != 0) {
			return
		}
	}

	current_x += direction
	state_changed = true
}

fall :: proc() {
	iteration += 1
	// Fall in `fall_freq` times
	if (iteration < fall_freq) {
		return
	}

	iteration = 0

	x, y: i32

	for i: i32 = 0; i < 4; i += 1 {
		x = current_shape[i * 2] + current_x
		y = current_shape[i * 2 + 1] + current_y + 1

		if (detect_collision(x, y) != 0) {
			lock_shape()
            return
		}
	}

	current_y += 1
	state_changed = true
}

handle_input_event :: proc(event: InputEvent) {
    #partial switch (event) {
	case .MOVE_LEFT:
		move_side(-1)
	case .MOVE_RIGHT:
		move_side(1)
	case .ROTATE_CCW:
		rotate_shape_ccw()
	case .HARD_DROP:
		update_fall_freq(HARD_FREQ)
	case .SOFT_DROP_BEGIN:
		update_fall_freq(SOFT_FREQ)
	case .SOFT_DROP_END:
		reset_fall_freq()
	}
}

update_frame :: proc() {
	if (game_over) {
		render_game_over_message(score); return
	}

	if (!state_changed) {
		return // no need to rerender if all blocks remain at the same positions
	}

	clear_screen()

	for i: u32 = 0; i < GRID_WIDTH; i += 1 {
		for j: u32 = 0; j < GRID_HEIGHT; j += 1 {
			draw_block(i, j, COLORS[grid[i][j]])
		}
	}

	x, y: i32

	for i: i32 = 0; i < 4; i += 1 {
		x = current_shape[i * 2] + current_x
		y = current_shape[i * 2 + 1] + current_y

		// skip overflowed
		if (y >= 0) {
			draw_block(u32(x), u32(y), COLORS[current_shape_color])
		}
	}

	render_frame(score, current_level)
	state_changed = false
}

init_game :: proc() -> bool {
	spawn_shape()

	return init_graphics()
}

game_loop :: proc() -> i32 {
	event: InputEvent = listen_for_input() // TODO: assumes only one input event at a time
	if (event == .QUIT) {
		return 1
	}

	if (game_over) {
		if (int(event) > 0) {
			restart_game()
		}
	} else {
		handle_input_event(event) // TODO: assumes only one input event at a time
		fall()
		update_frame()
	}
    SDL.Delay(FRAME_DELAY)

	return 0
}

terminate_game :: proc() -> bool {
	release_resources()
	return true
}
