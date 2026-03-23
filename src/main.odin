package tetris_karl2d

import "core:fmt"
import "core:mem"
import SDL "vendor:sdl2"

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		fmt.printfln("-------------------- [Tracking_Allocator] --------------------")
		if (len(track.allocation_map) == 0 && len(track.bad_free_array) == 0) {
			fmt.printfln("Memory is all good!")
		} else {
			fmt.printfln("Memory has some issues, see below...")
		}

		for _, entry in track.allocation_map {
			fmt.printf("%v leaked %v bytes\n", entry.location, entry.size)
		}
		for entry in track.bad_free_array {
			fmt.printf("%v bad free\n", entry.location)
		}
		mem.tracking_allocator_destroy(&track)
		fmt.printfln("-------------------- [Tracking_Allocator] --------------------")
	}

	if (init_game() != 0) {
		SDL.LogError(0, "Failed to start game\n")
		return
	}

	for {
		res: i32 = game_loop()

		if (res != 0) {
			if (res < 0) {
				SDL.LogError(0, "Unexpected error occured\n")
			}
			break
		}
	}

	if (terminate_game() != 0) {
		SDL.LogError(0, "Error while terminating game\n")
	}
}
