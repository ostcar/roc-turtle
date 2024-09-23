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
    dynhost.root_module.stack_check = false;

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    raylib_artifact.defineCMacro("SUPPORT_FILEFORMAT_PNG", null);

    dynhost.linkLibrary(raylib_artifact);
    dynhost.root_module.addImport("raylib", raylib);
    dynhost.root_module.addImport("raygui", raygui);

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
        .name = "linux-x86_64",
        .root_source_file = b.path("host/main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Copy legacy lib to platform
    const copy_legacy = b.addWriteFiles();
    //const copy_legacy = b.addUpdateSourceFiles(); // for zig 0.14
    copy_legacy.addCopyFileToSource(lib.getEmittedBin(), "platform/linux-x64.o");
    copy_legacy.step.dependOn(&lib.step);

    // Command for legacy
    const cmd_legacy = b.step("legacy", "build for legacy");
    cmd_legacy.dependOn(&copy_legacy.step);
}
