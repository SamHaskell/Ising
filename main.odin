package ising

import fmt "core:fmt"
import rand "core:math/rand"
import ray "vendor:raylib"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

Grid :: struct {
    rows : i32,
    cols : i32,
    configuration : []i32
}

Rect :: struct {
    x,
    y,
    w,
    h : i32
}

AppState :: struct {
    is_running : bool,
    is_paused : bool,
    window_width : i32,
    window_height : i32
}

main :: proc() {

    app_state : AppState = {
        is_running = true,
        is_paused = false,
        window_width = WINDOW_WIDTH,
        window_height = WINDOW_HEIGHT
    }

    ray_flags : ray.ConfigFlags = {.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI}
    ray.SetConfigFlags(ray_flags)
    ray.InitWindow(app_state.window_width, app_state.window_height, "Ising Model Visualiser")
    ray.SetWindowMinSize(320, 320)
    ray.SetTargetFPS(60)

    pause_icon := ray.LoadTexture("assets/pause.png"); defer ray.UnloadTexture(pause_icon)
    ray.SetTextureFilter(pause_icon, ray.TextureFilter.POINT)


    grid := grid_create(32, 32); defer grid_destroy(grid)

    font := ray.GetFontDefault()
    ray.SetTextureFilter(font.texture, ray.TextureFilter.POINT)

    for app_state.is_running {

        // Handle Events
        app_state.is_running = !ray.WindowShouldClose()

        if ray.IsWindowResized() {
            app_state.window_width = ray.GetScreenWidth()
            app_state.window_height = ray.GetScreenHeight()
        }

        if ray.IsKeyPressed(ray.KeyboardKey.SPACE) {
            app_state.is_paused = !app_state.is_paused
        }

        if !app_state.is_paused {
            grid_update(grid)
        }

        grid_rect : Rect = {
            x = 0,
            y = 0,
            w = app_state.window_width,
            h = app_state.window_height
        }            

        ray.BeginDrawing()
        ray.ClearBackground(ray.RAYWHITE)
        grid_draw(grid, grid_rect, 60)

        if app_state.is_paused {
            ray.DrawTexture(pause_icon, (grid_rect.x + grid_rect.w - pause_icon.width)/2, (grid_rect.y + grid_rect.h - pause_icon.height)/2, {255, 255, 255, 150})
        }

        ray.DrawFPS(5, 5)
        ray.EndDrawing()
        
    }
}

grid_create :: proc(c, r: i32) -> (grid: Grid) {
    using grid
    rows = r
    cols = c
    configuration = make([]i32, r * c)
    for i in 0..=cols-1 {
        for j in 0..=rows-1 {
            configuration[i*rows + j] = rand.choice([]i32{0, 1})
        }
    }
    return grid
}

grid_destroy :: proc(grid: Grid) {
    delete(grid.configuration)
}

grid_draw :: proc(using grid: Grid, target_rect: Rect, padding: i32) {
    // Draws centered on target rect while maintaining square cells
    cell_width := (target_rect.w - padding) / rows
    cell_height := (target_rect.h - padding) / cols
    cell_size := min(cell_width, cell_height)

    grid_width := cell_size * cols
    grid_height := cell_size * rows

    x_offset := (target_rect.w - grid_width) / 2
    y_offset := (target_rect.h - grid_height) / 2

    col : ray.Color
    ray.DrawRectangle(target_rect.x, target_rect.y, target_rect.w, target_rect.h, ray.RAYWHITE)
    for i in 0..=cols-1 {
        for j in 0..=rows-1 {
            col = configuration[i*rows + j] == 1 ? ray.RED : ray.DARKBLUE
            ray.DrawRectangle(x_offset + cell_size*i, y_offset + cell_size*j, cell_size, cell_size, col)
        }
    }
}

grid_update :: proc(grid: Grid) {
    using grid
    for i in 0..=cols-1 {
        for j in 0..=rows-1 {
            configuration[i*rows + j] = rand.choice([]i32{0, 1})
        }
    }
}