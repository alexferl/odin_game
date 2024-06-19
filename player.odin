package game

import rl "vendor:raylib"

Player :: struct {
    pos: rl.Vector2, // player position
    vel: rl.Vector2, // player velocity
    is_grounded: bool, // if player is on the ground
    is_flipped: bool, // if player is looking back
    run_width: f32,
    run_height: f32,
    cur_anim: Animation,
    feet_collider: rl.Rectangle,
}
