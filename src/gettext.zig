const VTE = @import("vte");
const c = VTE.c;
const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;

pub fn gettext(allocator: mem.Allocator, msg: [:0]const u8) ?[:0]const u8 {
    const val = c.gettext(msg.ptr);
    const len = mem.len(val);
    return fmt.allocPrintZ(allocator, "{s}", .{val[0..len]}) catch return null;
}
