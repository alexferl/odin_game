package game

import rl "vendor:raylib"

Level :: struct {
    platforms: [dynamic]rl.Vector2,
}

platform_collider :: proc(pos: rl.Vector2) -> rl.Rectangle {
    return {
        pos.x, pos.y, 96, 16
    }
}
