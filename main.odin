package ising

import fmt "core:fmt"
import math "core:math"
import rand "core:math/rand"
import strings "core:strings"

import ray "vendor:raylib"
import mu "vendor:microui"

WINDOW_WIDTH :: 1280
WINDOW_HEIGHT :: 720

Grid :: struct {
    rows : i32,
    cols : i32,
    config : []i32
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

    n_cols : i32 = 256
    n_rows : i32 = 128

    app_state : AppState = {
        is_running = true,
        is_paused = true,
        window_width = WINDOW_WIDTH,
        window_height = WINDOW_HEIGHT
    }

    ray_flags : ray.ConfigFlags = {.VSYNC_HINT, .WINDOW_RESIZABLE, .WINDOW_HIGHDPI}
    ray.SetConfigFlags(ray_flags)
    ray.InitWindow(app_state.window_width, app_state.window_height, "Ising Model Visualiser")
    ray.SetWindowMinSize(600, 600)
    ray.SetTargetFPS(30)

    pause_icon := ray.LoadTexture("assets/pause.png"); defer ray.UnloadTexture(pause_icon)
    ray.SetTextureFilter(pause_icon, ray.TextureFilter.POINT)

    font := ray.GetFontDefault()
    ray.SetTextureFilter(font.texture, ray.TextureFilter.POINT)

    grid := grid_create(n_cols, n_rows); defer grid_destroy(grid)

    inv_temperature : f32 = 1

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

        // Update Logic

        if !app_state.is_paused {
            grid_update_metropolis(grid, inv_temperature) // T=2.269 is Critical temperature? hotter means more activity
        }

        grid_rect : Rect = {
            x = 0,
            y = 0,
            w = app_state.window_width,
            h = app_state.window_height
        }            

        // Rendering

        ray.BeginDrawing()
        ray.ClearBackground(ray.RAYWHITE)
        grid_draw(grid, grid_rect, 60)

        if app_state.is_paused {
            ray.DrawTexture(pause_icon, (grid_rect.x + grid_rect.w - pause_icon.width)/2, (grid_rect.y + grid_rect.h - pause_icon.height)/2, {255, 255, 255, 150})
        }

        draw_state_info(app_state, grid, inv_temperature)
        draw_grid_dims(app_state, grid)

        ray.DrawFPS(5, 5)
        ray.EndDrawing()
    }
}

grid_create :: proc(c, r: i32) -> (grid: Grid) {
    using grid
    rows, cols = r, c
    s: i32
    config = make([]i32, r * c)
    for i in 0..=cols-1 {
        for j in 0..=rows-1 {
            s = rand.choice([]i32{-1, 1})
            config[i*rows + j] = s
        }
    }
    return grid
}

grid_destroy :: proc(grid: Grid) {
    delete(grid.config)
}

grid_draw :: proc(using grid: Grid, target_rect: Rect, padding: i32) {
    // Draws centered on target rect while maintaining square cells
    cell_width := (target_rect.w - padding) / cols
    cell_height := (target_rect.h - padding) / rows
    cell_size := min(cell_width, cell_height)

    grid_width := cell_size * cols
    grid_height := cell_size * rows

    x_offset := target_rect.x + (target_rect.w - grid_width) / 2
    y_offset := target_rect.y + (target_rect.h - grid_height) / 2

    col : ray.Color
    ray.DrawRectangle(target_rect.x, target_rect.y, target_rect.w, target_rect.h, ray.RAYWHITE)
    for i in 0..=cols-1 {
        for j in 0..=rows-1 {
            col = config[i*rows + j] > 0 ? ray.RED : ray.DARKBLUE
            ray.DrawRectangle(x_offset + cell_size*i, y_offset + cell_size*j, cell_size, cell_size, col)
        }
    }
}

grid_update_metropolis :: proc(grid: Grid, inv_temperature: f32) {
    /*
        A single update consists of performing N random spin-flips, where N is the number of spins in the system
    */
    using grid
    p, q : i32
    i, j : i32
    spin, neighbour_sum, cost : i32
    for _ in 1..=len(config)-1 {
        p = i32(rand.float32() * f32(cols))
        q = i32(rand.float32() * f32(rows))  
        i = p + cols
        j = q + rows      
        spin = config[(p%cols) * rows + (q%rows)]
        neighbour_sum = config[(i%cols) * rows + (j-1)%rows] + config[(i%cols) * rows + (j+1)%rows] + config[((i-1)%cols) * rows + j%rows] + config[((i+1)%cols) * rows + j%rows]
        cost = 2*spin*neighbour_sum
        if (cost < 0) {
            config[(p%cols) * rows + (q%rows)] *= -1
        }
        else if rand.float32() < math.exp(f32(-cost)*inv_temperature){
            config[(p%cols) * rows + (q%rows)] *= -1
        }
    }
}

get_grid_dims_string :: proc(grid: Grid) -> (s: string) {
    builder := strings.builder_make()
    strings.write_string(&builder, "Grid Dimensions: (")
    strings.write_i64(&builder, i64(grid.cols))
    strings.write_string(&builder, ",")
    strings.write_i64(&builder, i64(grid.rows))
    strings.write_string(&builder, ")")
    s = strings.to_string(builder)
    return s
}

draw_grid_dims :: proc(state: AppState, grid: Grid) {
    dims_str : cstring = strings.clone_to_cstring(get_grid_dims_string(grid)); defer delete(dims_str)
    offset_x : i32 = ray.MeasureText(dims_str, 24)/2
    ray.DrawText(dims_str, (state.window_width)/2 - offset_x, state.window_height - 48, 24, ray.BLACK)
}

draw_state_info :: proc(state: AppState, grid: Grid, inv_temperature: f32) {

}