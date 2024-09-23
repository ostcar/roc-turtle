const std = @import("std");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const LazyPath = std.Build.LazyPath;
const Compile = std.Build.Step.Compile;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    raylib_artifact.defineCMacro("SUPPORT_FILEFORMAT_PNG", null);

    // Build libapp.so
    const build_libapp_so = b.addSystemCommand(&.{"roc"});
    build_libapp_so.addArgs(&.{ "build", "--lib" });
    build_libapp_so.addFileArg(b.path("examples/roc/main.roc"));
    build_libapp_so.addArg("--output");
    const libapp_filename = build_libapp_so.addOutputFileArg("libapp.so");

    // Build dynhost
    const dynhost = b.addExecutable(.{
        .name = "dynhost",
        .root_source_file = b.path("host/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    dynhost.pie = true;
    dynhost.rdynamic = true;
    dynhost.bundle_compiler_rt = true;
    dynhost.linkLibC();
    dynhost.root_module.stack_check = false;

    dynhost.linkLibrary(raylib_artifact);
    dynhost.root_module.addImport("raylib", raylib);

    dynhost.addObjectFile(libapp_filename);

    // Copy dynhost to platform
    const copy_dynhost = b.addWriteFiles();
    //const copy_dynhost = b.addUpdateSourceFiles();
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
    const cmd_preprocess = b.step("surgical", "creates the files necessary for the surgical linker");
    cmd_preprocess.dependOn(&preprocess_host.step);

    // For legacy linker
    const lib = b.addStaticLibrary(.{
        .name = "linux-x86",
        .root_source_file = b.path("host/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    lib.root_module.addImport("raylib", raylib);

    lib.root_module.stack_check = false;

    // TODO: This is quite ugly. It creates .o files in some tmp directory.
    // Is it possible, to do this directly with zig?
    const tmp_dir = b.makeTempPath();

    const extract_raylib = b.addSystemCommand(&.{ "ar", "x" });
    extract_raylib.setCwd(Build.LazyPath{ .cwd_relative = tmp_dir });
    extract_raylib.addFileArg(raylib_artifact.getEmittedBin());
    lib.step.dependOn(&extract_raylib.step);
    const files = [_][]const u8{ "raudio.o", "raygui.o", "rcore.o", "rglfw.o", "rmodels.o", "rshapes.o", "rtext.o", "rtextures.o", "utils.o" };
    const od = std.fs.openDirAbsolute(tmp_dir, .{}) catch unreachable;
    od.setAsCwd() catch unreachable;
    for (files) |file| {
        lib.addObjectFile(Build.LazyPath{ .cwd_relative = file });
    }

    const copy_legacy = b.addWriteFiles();
    //const copy_legacy = b.addUpdateSourceFiles(); // for zig 0.14
    copy_legacy.addCopyFileToSource(lib.getEmittedBin(), "platform/linux-x64.a");
    copy_legacy.step.dependOn(&lib.step);

    // Command for legacy
    const cmd_legacy = b.step("legacy", "build for legacy");
    cmd_legacy.dependOn(&copy_legacy.step);
}
