const std = @import("std");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const LazyPath = std.Build.LazyPath;
const Compile = std.Build.Step.Compile;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build libapp.so
    const build_libapp_so = b.addSystemCommand(&.{"roc"});
    build_libapp_so.addArgs(&.{ "build", "--lib" });
    build_libapp_so.addFileArg(b.path("examples/roc/main.roc"));
    //build_libapp_so.addFileArg(.{ .path = "examples/roc/main.roc" });
    build_libapp_so.addArg("--output");
    const libapp_filename = build_libapp_so.addOutputFileArg("libapp.so");

    // Build dynhost
    const dynhost = b.addExecutable(.{
        .name = "dynhost",
        .root_source_file = b.path("host/main.zig"),
        //.root_source_file = .{ .path = "host/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    dynhost.pie = true;
    dynhost.rdynamic = true;
    dynhost.bundle_compiler_rt = true;
    dynhost.linkLibC();

    if (target.query.isNativeOs() and target.result.os.tag == .linux) {
        // The SDL package doesn't work for Linux yet, so we rely on system
        // packages for now.
        dynhost.linkSystemLibrary("SDL2");
        dynhost.linkSystemLibrary("sdl2_image");
    } else {
        const sdl_dep = b.dependency("sdl", .{
            .optimize = .ReleaseFast,
            .target = target,
        });
        dynhost.linkLibrary(sdl_dep.artifact("SDL2"));
    }

    // const roc_std = b.createModule(.{ .source_file = .{ .path = "roc-std/glue.zig" } });
    // dynhost.addModule("roc-std", roc_std);

    dynhost.addObjectFile(libapp_filename);

    // Copy dynhost to platform
    const copy_dynhost = b.addWriteFiles();
    copy_dynhost.addCopyFileToSource(dynhost.getEmittedBin(), "platform/dynhost");
    copy_dynhost.step.dependOn(&dynhost.step);

    // Preprocess host
    const preprocess_host = b.addSystemCommand(&.{"roc"});
    preprocess_host.addArg("preprocess-host");
    preprocess_host.addFileArg(dynhost.getEmittedBin());
    preprocess_host.addFileArg(b.path("platform/main.roc"));
    //preprocess_host.addFileArg(.{ .path = "platform/main.roc" });
    preprocess_host.addFileArg(libapp_filename);
    preprocess_host.step.dependOn(&copy_dynhost.step);

    // Command to preprocess host
    const cmd_preprocess = b.step("preprocess", "preprocess the platform");
    cmd_preprocess.dependOn(&preprocess_host.step);

    // For legacy linker
    const lib = b.addStaticLibrary(.{
        .name = "linux-x86_64",
        .root_source_file = b.path("host/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    // lib.linkSystemLibrary("SDL2");
    // lib.linkSystemLibrary("sdl2_image");
    const sdl_dep = b.dependency("sdl", .{
        .optimize = .ReleaseFast,
        .target = target,
        // doesn't support SDL_RENDERER_TARGETTEXTURE
        .render_driver_ogl_es = false,
        // doesn't support SDL_RENDERER_ACCELERATED
        .render_driver_software = false,
    });

    lib.linkLibrary(sdl_dep.artifact("SDL2"));
    lib.linkSystemLibrary("SDL2");
    lib.linkSystemLibrary("sdl2_image");
    //lib.pic = true;
    //lib.disable_stack_probing = true;

    // Copy legacy lib to platform
    const copy_legacy = b.addWriteFiles();
    copy_legacy.addCopyFileToSource(lib.getEmittedBin(), "platform/linux-x64.o");
    copy_legacy.step.dependOn(&lib.step);

    // Command for legacy
    const cmd_legacy = b.step("legacy", "build for legacy");
    cmd_legacy.dependOn(&copy_legacy.step);
}
