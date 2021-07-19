const Builder = @import("std").build.Builder;
const deps = @import("deps.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zterm", "src/main.zig");
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

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
