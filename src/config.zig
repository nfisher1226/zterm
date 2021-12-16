const std = @import("std");
const gui = @import("gui.zig");
const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const known_folders = @import("known-folders");
const nt = @import("nestedtext");
const prefs = @import("prefs.zig");
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const fs = std.fs;
const path = fs.path;
const math = std.math;
const mem = std.mem;
const meta = std.meta;
const os = std.os;
const stderr = std.io.getStdErr().writer();

pub const known_folders_config = .{
    .xdg_on_mac = true,
};

pub fn parse_enum(comptime T: type, style: [*c]const u8) ?T {
    const len = mem.len(style);
    return meta.stringToEnum(T, style[0..len]);
}

pub fn getConfigDir(alloc: mem.Allocator) ?[]const u8 {
    const dir = known_folders.getPath(alloc, .local_configuration) catch return null;
    if (dir) |d| {
        return path.join(alloc, &[_][]const u8{ d, "zterm" }) catch return null;
    } else {
        return if (os.getenv("HOME")) |h| path.join(alloc, &[_][]const u8{ h, ".config/zterm"}) catch return null else null;
    }
}

fn getConfigDirHandle(dir: []const u8) ?std.fs.Dir {
    defer allocator.free(dir);
    if (fs.openDirAbsolute(dir, .{})) |d| {
            return d;
    } else |err| {
        switch (err) {
            fs.File.OpenError.FileNotFound => {
                os.mkdir(dir, 0o755) catch return null;
                if (fs.openDirAbsolute(dir, .{})) |d| {
                    return d;
                } else |new_err| {
                    std.debug.print("OpenDir: {s}\n", .{new_err});
                    return null;
                }
            },
            else => {
                std.debug.print("Create Directory: {s}\n", .{err});
                return null;
            },
        }
    }
}

pub fn getConfigFile(alloc: mem.Allocator) ?[]const u8 {
    const dir = known_folders.getPath(alloc, .local_configuration) catch return null;
    if (dir) |d| {
        return path.join(alloc, &[_][]const u8{ d, "zterm/config.nt" }) catch return null;
    } else {
        return if (os.getenv("HOME")) |h| path.join(alloc, &[_][]const u8{ h, ".config/zterm/config.nt" }) catch return null else null;
    }
}

pub const DynamicTitleStyle = enum {
    replaces_title,
    before_title,
    after_title,
    not_displayed,

    pub fn default() DynamicTitleStyle {
        return DynamicTitleStyle.after_title;
    }
};

pub const CustomCommand = union(enum) {
    none,
    command: []const u8,

    pub fn default() CustomCommand {
        return CustomCommand.none;
    }
};

pub const Scrollback = union(enum) {
    finite: f64,
    infinite,

    pub fn default() Scrollback {
        return Scrollback{ .finite = 1500 };
    }

    pub fn set(self: Scrollback, term: *c.VteTerminal) void {
        switch (self) {
            .finite => |v| c.vte_terminal_set_scrollback_lines(term, @floatToInt(c_long, v)),
            .infinite => c.vte_terminal_set_scrollback_lines(term, -1),
        }
    }
};

pub const Font = union(enum) {
    system,
    custom: []const u8,

    pub fn default() Font {
        return Font.system;
    }

    fn set(self: Font, term: *c.VteTerminal) void {
        switch (self) {
            .system => c.vte_terminal_set_font(term, null),
            .custom => |v| {
                const font = fmt.allocPrintZ(allocator, "{s}", .{v}) catch |e| {
                    stderr.print("{s}\n", .{e}) catch {};
                    c.vte_terminal_set_font(term, null);
                    return;
                };
                defer allocator.free(font);
                const fontdesc = c.pango_font_description_from_string(font.ptr);
                c.vte_terminal_set_font(term, fontdesc);
            },
        }
    }
};

pub const CursorStyle = enum {
    block,
    ibeam,
    underline,

    pub fn default() CursorStyle {
        return CursorStyle.block;
    }

    fn set(self: CursorStyle, term: *c.VteTerminal) void {
        switch (self) {
            .block => c.vte_terminal_set_cursor_shape(term, c.VTE_CURSOR_SHAPE_BLOCK),
            .ibeam => c.vte_terminal_set_cursor_shape(term, c.VTE_CURSOR_SHAPE_IBEAM),
            .underline => c.vte_terminal_set_cursor_shape(term, c.VTE_CURSOR_SHAPE_UNDERLINE),
        }
    }
};

pub const Cursor = struct {
    cursor_style: CursorStyle,
    cursor_blinks: bool,

    pub fn default() Cursor {
        return Cursor{
            .cursor_style = CursorStyle.default(),
            .cursor_blinks = true,
        };
    }

    pub fn set(self: Cursor, term: *c.VteTerminal) void {
        self.cursor_style.set(term);
        if (self.cursor_blinks) {
            c.vte_terminal_set_cursor_blink_mode(term, c.VTE_CURSOR_BLINK_ON);
        } else {
            c.vte_terminal_set_cursor_blink_mode(term, c.VTE_CURSOR_BLINK_OFF);
        }
    }
};

pub const BackgroundStyle = enum {
    solid_color,
    image,
    transparent,

    pub fn default() BackgroundStyle {
        return BackgroundStyle.solid_color;
    }
};

pub const ImageStyle = enum {
    tiled,
    centered,
    scaled,
    stretched,

    pub fn default() ImageStyle {
        return ImageStyle.tiled;
    }
};

pub const BackgroundImage = struct {
    file: []const u8,
    style: ImageStyle,
};

pub const Background = union(BackgroundStyle) {
    solid_color: void,
    image: BackgroundImage,
    transparent: f64,

    pub fn default() Background {
        return Background.solid_color;
    }
};

pub const RGBColor = struct {
    red: u8,
    green: u8,
    blue: u8,

    pub fn default() RGBColor {
        return RGBColor{
            .red = 0,
            .blue = 0,
            .green = 0,
        };
    }

    pub fn from_widget(button: gtk.ColorButton) RGBColor {
        const rgba = button.as_color_chooser().get_rgba();
        return RGBColor{
            .red = @floatToInt(u8, math.round(rgba.red * 255.0)),
            .green = @floatToInt(u8, math.round(rgba.green * 255.0)),
            .blue = @floatToInt(u8, math.round(rgba.blue * 255.0)),
        };
    }

    fn to_hex(self: RGBColor) ?[]const u8 {
        const buf = fmt.allocPrintZ(allocator, "#{x}{x}{x}", .{ self.red, self.green, self.blue }) catch return null;
        return buf;
    }

    pub fn to_gdk(self: RGBColor) c.GdkRGBA {
        return c.GdkRGBA{
            .red = @intToFloat(f64, self.red) / 255.0,
            .green = @intToFloat(f64, self.green) / 255.0,
            .blue = @intToFloat(f64, self.blue) / 255.0,
            .alpha = 1.0,
        };
    }

    fn to_gdk_alpha(self: RGBColor, opacity: f64) c.GdkRGBA {
        return c.GdkRGBA{
            .red = @intToFloat(f64, self.red) / 255.0,
            .green = @intToFloat(f64, self.green) / 255.0,
            .blue = @intToFloat(f64, self.blue) / 255.0,
            .alpha = opacity,
        };
    }
};

pub const Colors = struct {
    text_color: RGBColor,
    background_color: RGBColor,
    black_color: RGBColor,
    red_color: RGBColor,
    green_color: RGBColor,
    brown_color: RGBColor,
    blue_color: RGBColor,
    magenta_color: RGBColor,
    cyan_color: RGBColor,
    light_grey_color: RGBColor,
    dark_grey_color: RGBColor,
    light_red_color: RGBColor,
    light_green_color: RGBColor,
    yellow_color: RGBColor,
    light_blue_color: RGBColor,
    light_magenta_color: RGBColor,
    light_cyan_color: RGBColor,
    white_color: RGBColor,

    pub fn default() Colors {
        return Colors{
            .text_color = RGBColor{ .red = 225, .green = 225, .blue = 225 },
            .background_color = RGBColor{ .red = 36, .green = 34, .blue = 34 },
            .black_color = RGBColor{ .red = 36, .green = 34, .blue = 34 },
            .red_color = RGBColor{ .red = 165, .green = 29, .blue = 45 },
            .green_color = RGBColor{ .red = 0, .green = 170, .blue = 0 },
            .brown_color = RGBColor{ .red = 99, .green = 69, .blue = 44 },
            .blue_color = RGBColor{ .red = 0, .green = 0, .blue = 170 },
            .magenta_color = RGBColor{ .red = 170, .green = 0, .blue = 170 },
            .cyan_color = RGBColor{ .red = 0, .green = 170, .blue = 170 },
            .light_grey_color = RGBColor{ .red = 170, .green = 170, .blue = 170 },
            .dark_grey_color = RGBColor{ .red = 85, .green = 85, .blue = 85 },
            .light_red_color = RGBColor{ .red = 255, .green = 85, .blue = 85 },
            .light_green_color = RGBColor{ .red = 85, .green = 255, .blue = 85 },
            .yellow_color = RGBColor{ .red = 225, .green = 189, .blue = 0 },
            .light_blue_color = RGBColor{ .red = 85, .green = 85, .blue = 255 },
            .light_magenta_color = RGBColor{ .red = 255, .green = 85, .blue = 255 },
            .light_cyan_color = RGBColor{ .red = 85, .green = 255, .blue = 255 },
            .white_color = RGBColor{ .red = 225, .green = 225, .blue = 225 },
        };
    }

    fn set(self: Colors, term: *c.VteTerminal) void {
        const fgcolor = self.text_color.to_gdk();
        const bgcolor = self.background_color.to_gdk();
        const palette = self.to_palette();
        c.vte_terminal_set_color_foreground(term, &fgcolor);
        c.vte_terminal_set_colors(term, &fgcolor, &bgcolor, &palette, 16);
    }

    fn set_bg(self: Colors, term: *c.VteTerminal) void {
        const bgcolor = self.background_color.to_gdk();
        c.vte_terminal_set_color_background(term, &bgcolor);
    }

    fn to_palette(self: Colors) [16]c.GdkRGBA {
        return [16]c.GdkRGBA{
            self.black_color.to_gdk(),
            self.red_color.to_gdk(),
            self.green_color.to_gdk(),
            self.yellow_color.to_gdk(),
            self.blue_color.to_gdk(),
            self.magenta_color.to_gdk(),
            self.cyan_color.to_gdk(),
            self.light_grey_color.to_gdk(),
            self.dark_grey_color.to_gdk(),
            self.brown_color.to_gdk(),
            self.light_red_color.to_gdk(),
            self.light_green_color.to_gdk(),
            self.light_blue_color.to_gdk(),
            self.light_magenta_color.to_gdk(),
            self.light_cyan_color.to_gdk(),
            self.white_color.to_gdk(),
        };
    }
};

pub const Config = struct {
    initial_title: []const u8,
    dynamic_title_style: DynamicTitleStyle,
    custom_command: CustomCommand,
    scrollback: Scrollback,
    font: Font,
    background: Background,
    colors: Colors,
    cursor: Cursor,

    pub fn default() Config {
        return Config{
            .initial_title = "Zterm",
            .dynamic_title_style = DynamicTitleStyle.default(),
            .custom_command = CustomCommand.default(),
            .scrollback = Scrollback.default(),
            .font = Font.default(),
            .background = Background.default(),
            .colors = Colors.default(),
            .cursor = Cursor.default(),
        };
    }

    pub fn fromFile(dir: []const u8) ?Config {
        if (getConfigDirHandle(dir)) |dir_fd| {
            const fd = dir_fd.openFile("config.nt", .{ .read = true }) catch return null;
            defer {
                fd.close();
                var dir_handle = dir_fd;
                dir_handle.close();
            }
            const text = fd.reader().readAllAlloc(allocator, math.maxInt(usize)) catch return null;
            defer allocator.free(text);
            var parser = nt.Parser.init(allocator, .{});
            @setEvalBranchQuota(4000);
            const cfg = parser.parseTyped(Config, text) catch return null;
            return cfg;
        }
        return null;
    }

    fn set_bg(self: Config, term: *c.VteTerminal) void {
        switch (self.background) {
            .solid_color => self.colors.set_bg(term),
            .image => {},
            .transparent => |percent| {
                const opacity = percent / 100.0;
                const rgba = self.colors.background_color.to_gdk_alpha(opacity);
                c.vte_terminal_set_color_background(term, &rgba);
            },
        }
    }

    pub fn set(self: Config, term: *c.VteTerminal) void {
        self.colors.set(term);
        self.set_bg(term);
        self.scrollback.set(term);
        self.font.set(term);
        self.cursor.set(term);
    }

    pub fn save(self: Config, dir: []const u8) void {
        const cfg_tree = nt.fromArbitraryType(allocator, self) catch return;
        defer cfg_tree.deinit();
        if (getConfigDirHandle(dir)) |h| {
            var handle = h;
            defer handle.close();
            if (handle.createFile("config.nt", .{ .truncate = true })) |file| {
                cfg_tree.stringify(.{}, file.writer()) catch return;
            } else |write_err| {
                std.debug.print("Write Error: {s}\n", .{write_err});
                return;
            }
        }
    }
};
