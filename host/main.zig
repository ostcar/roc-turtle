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

var global_state: GlobalState = undefined;

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

    global_state = try GlobalState.init(allocator, renderer, screen_w, screen_h);
    defer global_state.deinit();

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
        const curPos = global_state.turtle.position();
        global_state.turtle.forward(100 * time_elapsed);
        global_state.turtle.right(90 * time_elapsed);
        try global_state.lines.append(.{ .start = curPos, .end = global_state.turtle.position(), .color = color_back });

        // Draw
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        _ = c.SDL_RenderClear(renderer);
        global_state.draw();

        c.SDL_RenderPresent(renderer);

        // Wait
        c.SDL_Delay(@intFromFloat(16.666 - time_elapsed / 1000));
    }
}

const Point = struct {
    x: c_int,
    y: c_int,
};

const GlobalState = struct {
    renderer: ?*c.SDL_Renderer,
    turtle: Turtle,
    lines: ArrayList(Line),

    fn init(allocator: std.mem.Allocator, renderer: ?*c.SDL_Renderer, screen_w: c_int, screen_h: c_int) !GlobalState {
        const turtle = try Turtle.init(renderer, .{ .x = @divFloor(screen_w, 2), .y = @divFloor(screen_h, 2) }, 0);
        const lines = ArrayList(Line).init(allocator);
        return .{
            .renderer = renderer,
            .turtle = turtle,
            .lines = lines,
        };
    }

    fn deinit(self: GlobalState) void {
        self.turtle.deinit();
        self.lines.deinit();
    }

    fn draw(self: GlobalState) void {
        self.turtle.draw(self.renderer);
        for (self.lines.items) |line| {
            line.draw(self.renderer);
        }
    }
};

const Command = union(enum) {
    forward: f64,
    backward: f64,
    left: f64,
    right: f64,
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

// Roc task and functions
const str = @import("roc/str.zig");
const RocStr = str.RocStr;
const RocResult = @import("result.zig").RocResult;

extern fn roc__mainForHost_1_exposed_generic(*anyopaque) callconv(.C) void;
extern fn roc__mainForHost_1_exposed_size() callconv(.C) i64;

extern fn roc__mainForHost_0_caller(flags: *const u8, closure_data: *const u8, output: *RocResult(void, RocStr)) void;

fn call_the_closure(closure_data_ptr: *const u8) callconv(.C) i32 {
    var out: RocResult(void, RocStr) = .{
        .payload = .{ .ok = void{} },
        .tag = .RocOk,
    };

    roc__mainForHost_0_caller(
        undefined, // TODO do we need the flags?
        closure_data_ptr,
        @as(*RocResult(void, RocStr), @ptrCast(&out)),
    );

    switch (out.tag) {
        .RocOk => return 0,
        .RocErr => return 5, // TODO: Do something with the str
    }
}

export fn roc_fx_forward(distance: u64) callconv(.C) RocResult(void, RocStr) {
    // TODO: manipulate global turtle
    _ = distance;
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_backward(distance: u64) callconv(.C) RocResult(void, RocStr) {
    // TODO: manipulate global turtle
    _ = distance;
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_left(distance: u64) callconv(.C) RocResult(void, RocStr) {
    // TODO: manipulate global turtle
    _ = distance;
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_right(distance: u64) callconv(.C) RocResult(void, RocStr) {
    // TODO: manipulate global turtle
    _ = distance;
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

// Roc memory stuff
const DEBUG: bool = false;

const Align = 2 * @alignOf(usize);
extern fn malloc(size: usize) callconv(.C) ?*align(Align) anyopaque;
extern fn realloc(c_ptr: [*]align(Align) u8, size: usize) callconv(.C) ?*anyopaque;
extern fn free(c_ptr: [*]align(Align) u8) callconv(.C) void;
extern fn memcpy(dst: [*]u8, src: [*]u8, size: usize) callconv(.C) void;
extern fn memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void;

export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        const ptr = malloc(size);
        const stdout = std.io.getStdOut().writer();
        stdout.print("alloc:   {d} (alignment {d}, size {d})\n", .{ ptr, alignment, size }) catch unreachable;
        return ptr;
    } else {
        return malloc(size);
    }
}

export fn roc_realloc(c_ptr: *anyopaque, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("realloc: {d} (alignment {d}, old_size {d})\n", .{ c_ptr, alignment, old_size }) catch unreachable;
    }

    return realloc(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))), new_size);
}

export fn roc_dealloc(c_ptr: *anyopaque, alignment: u32) callconv(.C) void {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("dealloc: {d} (alignment {d})\n", .{ c_ptr, alignment }) catch unreachable;
    }

    free(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))));
}

export fn roc_panic(msg: *RocStr, tag_id: u32) callconv(.C) void {
    const stderr = std.io.getStdErr().writer();
    switch (tag_id) {
        0 => {
            stderr.print("Roc standard library crashed with message\n\n    {s}\n\nShutting down\n", .{msg.asSlice()}) catch unreachable;
        },
        1 => {
            stderr.print("Application crashed with message\n\n    {s}\n\nShutting down\n", .{msg.asSlice()}) catch unreachable;
        },
        else => unreachable,
    }
    std.process.exit(1);
}

export fn roc_dbg(loc: *RocStr, msg: *RocStr, src: *RocStr) callconv(.C) void {
    const stderr = std.io.getStdErr().writer();
    stderr.print("[{s}] {s} = {s}\n", .{ loc.asSlice(), src.asSlice(), msg.asSlice() }) catch unreachable;
}

export fn roc_memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void {
    return memset(dst, value, size);
}

extern fn kill(pid: c_int, sig: c_int) c_int;
extern fn shm_open(name: *const i8, oflag: c_int, mode: c_uint) c_int;
extern fn mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) *anyopaque;
extern fn getppid() c_int;

fn roc_getppid() callconv(.C) c_int {
    return getppid();
}

fn roc_getppid_windows_stub() callconv(.C) c_int {
    return 0;
}

fn roc_shm_open(name: *const i8, oflag: c_int, mode: c_uint) callconv(.C) c_int {
    return shm_open(name, oflag, mode);
}
fn roc_mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) callconv(.C) *anyopaque {
    return mmap(addr, length, prot, flags, fd, offset);
}

comptime {
    const builtin = @import("builtin");
    if (builtin.os.tag == .macos or builtin.os.tag == .linux) {
        @export(roc_getppid, .{ .name = "roc_getppid", .linkage = .strong });
        @export(roc_mmap, .{ .name = "roc_mmap", .linkage = .strong });
        @export(roc_shm_open, .{ .name = "roc_shm_open", .linkage = .strong });
    }

    if (builtin.os.tag == .windows) {
        @export(roc_getppid_windows_stub, .{ .name = "roc_getppid", .linkage = .strong });
    }
}
