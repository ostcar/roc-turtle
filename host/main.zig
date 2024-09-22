const std = @import("std");
const ArrayList = std.ArrayList;
const math = std.math;

const rl = @import("raylib");

var commander: Commander = undefined;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const screenWidth = 800;
    const screenHeight = 600;

    rl.initWindow(screenWidth, screenHeight, "roc turtle");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    const ground = rl.loadRenderTexture(screenWidth, screenHeight);
    defer rl.unloadRenderTexture(ground);

    var turtle = try Turtle.init(ground, .{ .x = 200, .y = 200 }, 0);
    defer turtle.deinit();

    commander = Commander{
        .commands = ArrayList(Command).init(allocator),
        .cur = 0,
        .cur_done = 0,
    };

    try call_roc();

    while (!rl.windowShouldClose()) {
        commander.do(&turtle, rl.getFrameTime());

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        // NOTE: Render texture must be y-flipped due to default OpenGL coordinates (left-bottom)
        rl.drawTextureRec(
            ground.texture,
            .{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(ground.texture.width),
                .height = @floatFromInt(-ground.texture.height),
            },
            .{ .x = 0, .y = 0 },
            rl.Color.white,
        );
        turtle.draw();
    }
}

const Point = struct {
    x: c_int,
    y: c_int,
};

const Command = union(enum) {
    forward: f32,
    left: f32,
    goto: struct { x: f32, y: f32 },
    up,
    down,
};

const Commander = struct {
    commands: ArrayList(Command), // TODO: replace with some sort of fifo queue
    cur: usize,
    cur_done: f32,

    fn add(self: *Commander, cmd: Command) !void {
        try self.commands.append(cmd);
    }

    fn do(self: *Commander, turtle: *Turtle, time_elapsed: f32) void {
        if (self.cur >= self.commands.items.len) return;

        const done = switch (self.commands.items[self.cur]) {
            Command.forward => |distance| blk: {
                const step = @min(100 * time_elapsed, distance - self.cur_done);
                turtle.forward(step);
                self.cur_done += step;
                break :blk self.cur_done >= distance;
            },
            Command.left => |angle| blk: {
                const step = @min(90 * time_elapsed, angle - self.cur_done);
                turtle.left(step);
                self.cur_done += step;
                break :blk self.cur_done >= angle;
            },
            Command.goto => |point| blk: {
                const distance_x = (point.x - turtle.x);
                const distance_y = (point.y - turtle.y);

                const full_distance = @sqrt(distance_x * distance_x + distance_y * distance_y);
                const step_distance = 100 * time_elapsed;
                if (step_distance >= full_distance) {
                    turtle.goto(point.x, point.y);
                    break :blk true;
                }

                // TODO: Is this correct? I would have guessed something like squer(step_distance² / full_distance²)
                const rate = step_distance / full_distance; //@sqrt(step_distance * step_distance / full_distance * full_distance);
                const x = distance_x * rate;
                const y = distance_y * rate;

                turtle.goto(turtle.x + x, turtle.y + y);
                break :blk false;
            },
            Command.up => blk: {
                turtle.up();
                break :blk true;
            },
            Command.down => blk: {
                turtle.down();
                break :blk true;
            },
        };
        if (done) {
            self.cur += 1;
            self.cur_done = 0;
        }
    }
};

const Turtle = struct {
    const roc_image = @embedFile("roc.png");
    x: f32,
    y: f32,
    angle: f32,
    image_texture: rl.Texture,
    ground_texture: rl.RenderTexture,
    pen_down: bool = true,

    fn init(ground: rl.RenderTexture, pos: Point, angle: f32) !Turtle {
        const image = rl.loadImageFromMemory(".png", Turtle.roc_image);
        defer rl.unloadImage(image);
        const texture = rl.loadTextureFromImage(image);

        return .{
            .x = @floatFromInt(pos.x),
            .y = @floatFromInt(pos.y),
            .angle = angle,
            .image_texture = texture,
            .ground_texture = ground,
        };
    }

    fn deinit(self: Turtle) void {
        rl.unloadTexture(self.image_texture);
    }

    fn goto(self: *Turtle, new_x: f32, new_y: f32) void {
        if (self.pen_down) {
            rl.beginTextureMode(self.ground_texture);
            defer rl.endTextureMode();
            rl.drawLine(
                @intFromFloat(self.x),
                @intFromFloat(self.y),
                @intFromFloat(new_x),
                @intFromFloat(new_y),
                rl.Color.black,
            );
        }
        self.x = new_x;
        self.y = new_y;
    }

    fn forward(self: *Turtle, distance: f32) void {
        const a = math.degreesToRadians(self.angle);
        const new_x = self.x + @cos(a) * distance;
        const new_y = self.y + @sin(a) * distance;
        self.goto(new_x, new_y);
    }

    fn backward(self: *Turtle, distance: f32) void {
        self.forward(-distance);
    }

    fn left(self: *Turtle, angle: f32) void {
        self.angle -= angle;
    }

    fn right(self: *Turtle, angle: f32) void {
        self.angle += angle;
    }

    fn up(self: *Turtle) void {
        self.pen_down = false;
    }

    fn down(self: *Turtle) void {
        self.pen_down = true;
    }

    fn position(self: Turtle) Point {
        return .{
            .x = @intFromFloat(self.x),
            .y = @intFromFloat(self.y),
        };
    }

    fn draw(self: Turtle) void {
        //const vec = rl.Vector2.init(self.x - 10, self.y - 10);
        //rl.drawTextureEx(self.image_texture, vec, self.angle, 1, rl.Color.white);

        const recSource = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.image_texture.width),
            .height = @floatFromInt(self.image_texture.height),
        };

        const recDestination = rl.Rectangle{
            .x = self.x,
            .y = self.y,
            .width = @floatFromInt(self.image_texture.width),
            .height = @floatFromInt(self.image_texture.height),
        };

        rl.drawTexturePro(
            self.image_texture,
            recSource,
            recDestination,
            .{ .x = 10, .y = 10 },
            self.angle,
            rl.Color.white,
        );
    }
};

// Roc task and functions
const str = @import("roc/str.zig");
const RocStr = str.RocStr;
const RocResult = @import("result.zig").RocResult;

extern fn roc__mainForHost_1_exposed_generic(*anyopaque) callconv(.C) void;
extern fn roc__mainForHost_1_exposed_size() callconv(.C) i64;

extern fn roc__mainForHost_0_caller(flags: *const u8, closure_data: *const u8, output: *RocResult(void, RocStr)) void;

fn call_roc() !void {
    const size = @as(usize, @intCast(roc__mainForHost_1_exposed_size()));
    const captures = roc_alloc(size, @alignOf(u128)).?;
    defer roc_dealloc(captures, @alignOf(u128));

    roc__mainForHost_1_exposed_generic(captures);

    try call_the_closure(@as(*const u8, @ptrCast(captures)));
}

fn call_the_closure(closure_data_ptr: *const u8) !void {
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
        .RocOk => return,
        .RocErr => return error.RocError,
    }
}

export fn roc_fx_forward(distance: f32) callconv(.C) RocResult(void, void) {
    commander.add(Command{ .forward = distance }) catch
        return .{ .payload = .{ .err = void{} }, .tag = .RocErr };
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_backward(distance: f32) callconv(.C) RocResult(void, void) {
    commander.add(Command{ .forward = -distance }) catch
        return .{ .payload = .{ .err = void{} }, .tag = .RocErr };
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_goto(x: f32, y: f32) callconv(.C) RocResult(void, void) {
    commander.add(Command{ .goto = .{ .x = x, .y = y } }) catch
        return .{ .payload = .{ .err = void{} }, .tag = .RocErr };
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_left(angle: f32) callconv(.C) RocResult(void, void) {
    commander.add(Command{ .left = angle }) catch
        return .{ .payload = .{ .err = void{} }, .tag = .RocErr };
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_right(angle: f32) callconv(.C) RocResult(void, void) {
    commander.add(Command{ .left = -angle }) catch
        return .{ .payload = .{ .err = void{} }, .tag = .RocErr };
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_up() callconv(.C) RocResult(void, void) {
    commander.add(Command.up) catch
        return .{ .payload = .{ .err = void{} }, .tag = .RocErr };
    return .{ .payload = .{ .ok = void{} }, .tag = .RocOk };
}

export fn roc_fx_down() callconv(.C) RocResult(void, void) {
    commander.add(Command.down) catch
        return .{ .payload = .{ .err = void{} }, .tag = .RocErr };
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
