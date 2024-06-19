package game

import rl "vendor:raylib"
import "core:fmt"
import "core:encoding/json"
import "core:mem"
import "core:os"

PIXEL_WINDOW_HEIGHT :: 180

Game :: struct {
    debug: bool,
    target_fps: i32,
    window: struct {
        init_x: i32,
        init_y: i32,
        title: cstring,
    }
}

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer {
        for _, entry in track.allocation_map {
            fmt.eprint("%v leaked %v bytes\n", entry.location, entry.size)
        }
        for entry in track.bad_free_array {
            fmt.eprint("%v bad free\n", entry.location)
        }
        mem.tracking_allocator_destroy(&track)
    }

    game: Game
    // game.debug = true
    game.target_fps = 60
    game.window.init_x = 1280
    game.window.init_y = 720
    game.window.title = "Cat Game"

    rl.InitWindow(game.window.init_x, game.window.init_y, game.window.title)
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.SetTargetFPS(game.target_fps)

    player: Player

    player_run := Animation {
        name = .Run,
        texture = rl.LoadTexture("assets/cat_run.png"),
        num_frames = 4,
        frame_length = 0.1,
    }

    player_idle := Animation {
        name = .Idle,
        texture = rl.LoadTexture("assets/cat_idle.png"),
        num_frames = 2,
        frame_length = 0.5,
    }

    player.cur_anim = player_idle

    level: Level

    if data, ok := os.read_entire_file("levels/level.json", context.temp_allocator); ok {
        if json.unmarshal(data, &level) != nil {
            append(&level.platforms, rl.Vector2{-20, 20})
        }
    } else {
        append(&level.platforms, rl.Vector2{-20, 20})
    }

    platform_texture := rl.LoadTexture("assets/platform.png")
    editing := false

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground({110, 184, 168, 255})

        if rl.IsKeyDown(.LEFT) {
            player.vel.x = -100
            player.is_flipped = true

            if player.cur_anim.name != .Run {
                player.cur_anim = player_run
            }
        } else if rl.IsKeyDown(.RIGHT) {
            player.vel.x = 100
            player.is_flipped = false

            if player.cur_anim.name != .Run {
                player.cur_anim = player_run
            }
        } else {
            player.vel.x = 0

            if player.cur_anim.name != .Idle {
                player.cur_anim = player_idle
            }
        }

        player.vel.y += 1000 * rl.GetFrameTime()

        if player.is_grounded && rl.IsKeyPressed(.SPACE) {
            player.vel.y = -300
        }

        player.pos += player.vel * rl.GetFrameTime()

        player.feet_collider = rl.Rectangle {
            player.pos.x - 4,
            player.pos.y - 4,
            8,
            4,
        }

        player.is_grounded = false

        for platform in level.platforms {
            if rl.CheckCollisionRecs(player.feet_collider, platform_collider(platform)) && player.vel.y > 0 {
                player.vel.y = 0
                player.pos.y = platform.y
                player.is_grounded = true
            }
        }

        update_anim(&player.cur_anim)

        screen_height := f32(rl.GetScreenHeight())

        camera := rl.Camera2D {
            zoom = screen_height/PIXEL_WINDOW_HEIGHT,
            offset = {f32(rl.GetScreenWidth()/2), screen_height/2},
            target = player.pos
        }

        rl.BeginMode2D(camera)
        draw_anim(player.cur_anim, player.pos, player.is_flipped)

        for platform in level.platforms {
            rl.DrawTextureV(platform_texture, platform, rl.WHITE)
        }

        if game.debug {
            rl.DrawRectangleRec(player.feet_collider, {0, 255, 0, 100})
        }

        if rl.IsKeyPressed(.F2) {
            editing = !editing
        }

        if editing {
            mp := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

            rl.DrawTextureV(platform_texture, mp, rl.WHITE)

            if rl.IsMouseButtonPressed(.LEFT) {
                append(&level.platforms, mp)
            }

            if rl.IsMouseButtonPressed(.RIGHT) {
                for p, idx in level.platforms {
                    if rl.CheckCollisionPointRec(mp, platform_collider(p)) {
                        unordered_remove(&level.platforms, idx)
                        break
                    }
                }
            }
        }

        rl.EndMode2D()
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    rl.CloseWindow()

    if data, err := json.marshal(level, allocator = context.temp_allocator); err == nil {
        os.write_entire_file("levels/level.json", data)
    }

    free_all(context.temp_allocator)

    delete(level.platforms)
}
