const std = @import("std");
const Builder = std.build.Builder;
const fs = std.fs;
const deps = @import("deps.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zt", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.linkSystemLibrary("gtk+-3.0");
    exe.linkSystemLibrary("vte-2.91");
    exe.install();

    // support both gyro and zigmod
    if (@hasDecl(deps, "addAllTo")) {
        deps.addAllTo(exe);
    } else {
        deps.pkgs.addAllTo(exe);
    }

    const datadir = b.option(
        []const u8,
        "datadir",
        "Path to install data files (relative tp prefix)"
    ) orelse "share";
    const desktop_path = fs.path.join(
        b.allocator,
        &[_][]const u8{ datadir, "/applications/zterm.desktop" },
    ) catch unreachable;
    const icon_path = fs.path.join(
        b.allocator,
        &[_][]const u8{ datadir, "/icons/hicolor/scalable/apps/zterm.svg" },
    ) catch unreachable;
    b.installFile("data/zterm.desktop", desktop_path);
    b.installFile("data/zterm.svg", icon_path);

    const strip = b.option(bool, "strip", "Strip the installed executable") orelse false;
    if (strip) {
        const cmd = b.addSystemCommand(&[_][]const u8{"strip", "-s"});
        cmd.addArtifactArg(exe);
        b.getInstallStep().dependOn(&cmd.step);
    }

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
