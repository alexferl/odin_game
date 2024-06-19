package game

import rl "vendor:raylib"

AnimationName :: enum {
    Idle,
    Run,
}

Animation :: struct {
    name: AnimationName,
    texture: rl.Texture2D,
    num_frames: int,
    frame_timer: f32,
    current_frame: int,
    frame_length: f32,
}

update_anim :: proc(a: ^Animation) {
    a.frame_timer += rl.GetFrameTime()

    if a.frame_timer > a.frame_length {
        a.current_frame += 1
        a.frame_timer = 0

        if a.current_frame == a.num_frames {
            a.current_frame = 0
        }
    }
}

draw_anim :: proc(a: Animation, pos: rl.Vector2, is_flipped: bool) {
    width := f32(a.texture.width)
    height := f32(a.texture.height)

    source := rl.Rectangle {
        x = f32(a.current_frame) * width / f32(a.num_frames),
        y = 0,
        width = width / f32(a.num_frames),
        height = height,
    }

    if is_flipped {
        source.width = -source.width
    }

    dest := rl.Rectangle {
        x = pos.x,
        y = pos.y,
        width = width / f32(a.num_frames),
        height = height,
    }

    rl.DrawTexturePro(a.texture, source, dest, {dest.width/2, dest.height}, 0, rl.WHITE)
}