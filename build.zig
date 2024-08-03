const Build = @import("std").Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "roc-turtle",
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = "host/main.zig" } },
        .target = target,
        .optimize = optimize,
    });
    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        // The SDL package doesn't work for Linux yet, so we rely on system
        // packages for now.
        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("sdl2_image");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("sdl", .{
            .optimize = .ReleaseFast,
            .target = target,
        });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));
    }

    b.installArtifact(exe);

    const run = b.step("run", "Run the demo");
    const run_cmd = b.addRunArtifact(exe);
    run.dependOn(&run_cmd.step);
}
