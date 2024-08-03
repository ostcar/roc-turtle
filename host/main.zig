const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL_image.h");
});
const ArrayList = std.ArrayList;
const math = std.math;

const color_back = c.SDL_Color{
    .r = 0,
    .g = 0,
    .b = 0,
    .a = 255,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const screen_w = 800;
    const screen_h = 400;

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow(
        "Roc Turtle",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        screen_w,
        screen_h,
        c.SDL_WINDOW_OPENGL,
    ) orelse
        {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    var turtle = try Turtle.init(renderer, .{ .x = screen_w / 2, .y = screen_h / 2 }, 0);
    defer turtle.deinit();

    var lines = ArrayList(Line).init(allocator);

    var timer_last = c.SDL_GetPerformanceCounter();

    while (true) {
        // Timer
        const timer_current = c.SDL_GetPerformanceCounter();
        const time_elapsed = @as(f64, @floatFromInt(timer_current - timer_last)) / @as(f64, @floatFromInt(c.SDL_GetPerformanceFrequency()));
        timer_last = timer_current;
        //std.debug.print("FPS {d:0.3}\n", .{1 / time_elapsed});

        // Events
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    return;
                },
                else => {},
            }
        }

        // Move Turtle
        const curPos = turtle.position();
        turtle.forward(100 * time_elapsed);
        turtle.right(90 * time_elapsed);
        try lines.append(.{ .start = curPos, .end = turtle.position(), .color = color_back });

        // Draw
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        _ = c.SDL_RenderClear(renderer);
        turtle.draw(renderer);
        for (lines.items) |line| {
            line.draw(renderer);
        }

        c.SDL_RenderPresent(renderer);

        // Wait
        c.SDL_Delay(@intFromFloat(16.666 - time_elapsed / 1000));
    }
}

const Point = struct {
    x: c_int,
    y: c_int,
};

const Turtle = struct {
    const roc_image = @embedFile("roc.svg");
    x: f64,
    y: f64,
    angle: f64,
    image_texture: ?*c.SDL_Texture,

    fn init(renderer: ?*c.SDL_Renderer, pos: Point, angle: f64) !Turtle {
        const rw = c.SDL_RWFromConstMem(roc_image, roc_image.len) orelse {
            c.SDL_Log("Unable to get RWFromConstMem: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        const image_surface = c.IMG_Load_RW(rw, 1) orelse {
            c.SDL_Log("Unable to load bmp: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        defer c.SDL_FreeSurface(image_surface);

        const image_texture = c.SDL_CreateTextureFromSurface(renderer, image_surface) orelse {
            c.SDL_Log("Unable to create texture from surface: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };

        return .{
            .x = @floatFromInt(pos.x),
            .y = @floatFromInt(pos.y),
            .angle = angle,
            .image_texture = image_texture,
        };
    }

    fn deinit(self: Turtle) void {
        c.SDL_DestroyTexture(self.image_texture);
    }

    fn forward(self: *Turtle, distance: f64) void {
        const a = math.degreesToRadians(self.angle);
        self.x += @cos(a) * distance;
        self.y += @sin(a) * distance;
    }

    fn backward(self: *Turtle, distance: f64) void {
        self.forward(-distance);
    }

    fn left(self: *Turtle, angle: f64) void {
        self.angle -= angle;
    }

    fn right(self: *Turtle, angle: f64) void {
        self.angle += angle;
    }

    fn position(self: Turtle) Point {
        return .{
            .x = @intFromFloat(self.x),
            .y = @intFromFloat(self.y),
        };
    }

    fn draw(self: Turtle, renderer: ?*c.SDL_Renderer) void {
        const rect = c.SDL_Rect{
            .x = @as(c_int, @intFromFloat(self.x)) - 10,
            .y = @as(c_int, @intFromFloat(self.y)) - 10,
            .w = 20,
            .h = 20,
        };
        _ = c.SDL_RenderCopyEx(renderer, self.image_texture, null, &rect, self.angle, null, c.SDL_FLIP_NONE);
    }
};

const Line = struct {
    start: Point,
    end: Point,
    color: c.SDL_Color,

    fn draw(self: Line, renderer: ?*c.SDL_Renderer) void {
        _ = c.SDL_SetRenderDrawColor(renderer, self.color.r, self.color.g, self.color.b, self.color.a);
        _ = c.SDL_RenderDrawLine(renderer, self.start.x, self.start.y, self.end.x, self.end.y);
    }
};
