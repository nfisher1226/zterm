const std = @import("std");
const gui = @import("gui.zig");
const Gradient = @import("gradient.zig").Gradient;
const prefs = @import("prefs.zig");
const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const vte = VTE.vte;
const known_folders = @import("known-folders");
const nt = @import("nestedtext");
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

pub fn parseEnum(comptime T: type, str: [*c]const u8) ?T {
    const len = mem.len(str);
    return meta.stringToEnum(T, str[0..len]);
}

pub fn getConfigDir(alloc: mem.Allocator) ?[]const u8 {
    const dir = known_folders.getPath(alloc, .local_configuration) catch return null;
    if (dir) |d| {
        return path.join(alloc, &[_][]const u8{ d, "zterm" }) catch return null;
    } else {
        return if (os.getenv("HOME")) |h| path.join(alloc, &[_][]const u8{ h, ".config/zterm" }) catch return null else null;
    }
}

pub fn getConfigDirHandle(dir: []const u8) ?std.fs.Dir {
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
                    std.debug.print("OpenDir: {}\n", .{new_err});
                    return null;
                }
            },
            else => {
                std.debug.print("Create Directory: {}\n", .{err});
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

    const Self = @This();

    pub fn default() Self {
        return Self.after_title;
    }
};

pub const CustomCommand = union(enum) {
    none,
    command: []const u8,

    const Self = @This();

    pub fn default() Self {
        return Self.none;
    }
};

pub const Scrollback = union(enum) {
    finite: f64,
    infinite,

    const Self = @This();

    pub fn default() Self {
        return Self{ .finite = 1500 };
    }

    pub fn set(self: Self, term: *c.VteTerminal) void {
        switch (self) {
            .finite => |v| c.vte_terminal_set_scrollback_lines(term, @floatToInt(c_long, v)),
            .infinite => c.vte_terminal_set_scrollback_lines(term, -1),
        }
    }
};

pub const Font = union(enum) {
    system,
    custom: []const u8,

    const Self = @This();

    pub fn default() Self {
        return Self.system;
    }

    fn set(self: Self, term: *c.VteTerminal) void {
        switch (self) {
            .system => c.vte_terminal_set_font(term, null),
            .custom => |v| {
                const font = fmt.allocPrintZ(allocator, "{s}", .{v}) catch |e| {
                    stderr.print("{}\n", .{e}) catch {};
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

    const Self = @This();

    pub fn default() Self {
        return Self.block;
    }

    fn set(self: Self, term: *c.VteTerminal) void {
        switch (self) {
            .block => c.vte_terminal_set_cursor_shape(term, c.VTE_CURSOR_SHAPE_BLOCK),
            .ibeam => c.vte_terminal_set_cursor_shape(term, c.VTE_CURSOR_SHAPE_IBEAM),
            .underline => c.vte_terminal_set_cursor_shape(term, c.VTE_CURSOR_SHAPE_UNDERLINE),
        }
    }
};

pub const Cursor = struct {
    style: CursorStyle,
    blinks: bool,

    const Self = @This();

    pub fn default() Self {
        return Self{
            .style = CursorStyle.default(),
            .blinks = true,
        };
    }

    pub fn set(self: Cursor, term: *c.VteTerminal) void {
        self.style.set(term);
        if (self.blinks) {
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
    gradient,

    const Self = @This();

    pub fn default() Self {
        return Self.solid_color;
    }
};

pub const ImageStyle = enum {
    tiled,
    centered,
    scaled,
    stretched,

    const Self = @This();

    pub fn default() Self {
        return Self.tiled;
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
    gradient: Gradient,

    const Self = @This();

    pub fn default() Self {
        return Self.solid_color;
    }
};

pub const RGB = struct {
    red: u8,
    green: u8,
    blue: u8,

    const Self = @This();

    pub fn default() Self {
        return Self{
            .red = 0,
            .blue = 0,
            .green = 0,
        };
    }

    pub fn fromButton(button: gtk.ColorButton) Self {
        const rgba = button.as_color_chooser().get_rgba();
        return Self{
            .red = @floatToInt(u8, @round(rgba.red * 255.0)),
            .green = @floatToInt(u8, @round(rgba.green * 255.0)),
            .blue = @floatToInt(u8, @round(rgba.blue * 255.0)),
        };
    }

    pub fn toGdk(self: Self) c.GdkRGBA {
        return c.GdkRGBA{
            .red = @intToFloat(f64, self.red) / 255.0,
            .green = @intToFloat(f64, self.green) / 255.0,
            .blue = @intToFloat(f64, self.blue) / 255.0,
            .alpha = 1.0,
        };
    }

    fn toGdkAlpha(self: Self, opacity: f64) c.GdkRGBA {
        return c.GdkRGBA{
            .red = @intToFloat(f64, self.red) / 255.0,
            .green = @intToFloat(f64, self.green) / 255.0,
            .blue = @intToFloat(f64, self.blue) / 255.0,
            .alpha = opacity,
        };
    }
};

pub const Colors = struct {
    text_color: RGB,
    background_color: RGB,
    black_color: RGB,
    red_color: RGB,
    green_color: RGB,
    brown_color: RGB,
    blue_color: RGB,
    magenta_color: RGB,
    cyan_color: RGB,
    light_grey_color: RGB,
    dark_grey_color: RGB,
    light_red_color: RGB,
    light_green_color: RGB,
    yellow_color: RGB,
    light_blue_color: RGB,
    light_magenta_color: RGB,
    light_cyan_color: RGB,
    white_color: RGB,

    pub fn default() Colors {
        return Colors{
            .text_color = RGB{ .red = 225, .green = 225, .blue = 225 },
            .background_color = RGB{ .red = 36, .green = 34, .blue = 34 },
            .black_color = RGB{ .red = 36, .green = 34, .blue = 34 },
            .red_color = RGB{ .red = 165, .green = 29, .blue = 45 },
            .green_color = RGB{ .red = 0, .green = 170, .blue = 0 },
            .brown_color = RGB{ .red = 99, .green = 69, .blue = 44 },
            .blue_color = RGB{ .red = 0, .green = 0, .blue = 170 },
            .magenta_color = RGB{ .red = 170, .green = 0, .blue = 170 },
            .cyan_color = RGB{ .red = 0, .green = 170, .blue = 170 },
            .light_grey_color = RGB{ .red = 170, .green = 170, .blue = 170 },
            .dark_grey_color = RGB{ .red = 85, .green = 85, .blue = 85 },
            .light_red_color = RGB{ .red = 255, .green = 85, .blue = 85 },
            .light_green_color = RGB{ .red = 85, .green = 255, .blue = 85 },
            .yellow_color = RGB{ .red = 225, .green = 189, .blue = 0 },
            .light_blue_color = RGB{ .red = 85, .green = 85, .blue = 255 },
            .light_magenta_color = RGB{ .red = 255, .green = 85, .blue = 255 },
            .light_cyan_color = RGB{ .red = 85, .green = 255, .blue = 255 },
            .white_color = RGB{ .red = 225, .green = 225, .blue = 225 },
        };
    }

    fn set(self: Colors, term: *c.VteTerminal) void {
        const fgcolor = self.text_color.toGdk();
        const bgcolor = self.background_color.toGdk();
        const palette = self.toPalette();
        c.vte_terminal_set_color_foreground(term, &fgcolor);
        c.vte_terminal_set_colors(term, &fgcolor, &bgcolor, &palette, 16);
    }

    fn setBg(self: Colors, term: *c.VteTerminal) void {
        const bgcolor = self.background_color.toGdk();
        c.vte_terminal_set_color_background(term, &bgcolor);
    }

    fn toPalette(self: Colors) [16]c.GdkRGBA {
        return [16]c.GdkRGBA{
            self.black_color.toGdk(),
            self.red_color.toGdk(),
            self.green_color.toGdk(),
            self.yellow_color.toGdk(),
            self.blue_color.toGdk(),
            self.magenta_color.toGdk(),
            self.cyan_color.toGdk(),
            self.light_grey_color.toGdk(),
            self.dark_grey_color.toGdk(),
            self.brown_color.toGdk(),
            self.light_red_color.toGdk(),
            self.light_green_color.toGdk(),
            self.light_blue_color.toGdk(),
            self.light_magenta_color.toGdk(),
            self.light_cyan_color.toGdk(),
            self.white_color.toGdk(),
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
            const fd = dir_fd.openFile("config.nt", .{ .mode = fs.File.OpenMode.read_only }) catch return null;
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

    pub fn setBg(self: Config) void {
        const provider = gui.css_provider;
        const color = self.colors.background_color;
        var buf: [55]u8 = undefined;
        const bg_color = fmt.bufPrint(&buf, "\n    background-color: rgb({d}, {d}, {d});", .{ color.red, color.green, color.blue }) catch return;
        switch (self.background) {
            .solid_color => {
                const css_string = fmt.allocPrintZ(allocator, ".workview stack {{{s}\n    background-size: 100% 100%;}}", .{bg_color}) catch return;
                _ = c.gtk_css_provider_load_from_data(provider, css_string.ptr, -1, null);
            },
            .image => |img| {
                const file = fs.cwd().openFile(img.file, .{}) catch return;
                file.close();
                const centered =
                    \\    background-position: center;
                    \\    background-repeat: no-repeat;
                ;
                const scaled =
                    \\    background-size: contain;
                    \\    background-repeat: no-repeat;
                    \\    background-position: center;
                ;
                const styling = switch (img.style) {
                    .tiled => "    background-repeat: repeat;\n",
                    .centered => centered,
                    .scaled => scaled,
                    .stretched => "    background-size: 100% 100%;\n",
                };
                const css_string = fmt.allocPrintZ(allocator, ".workview stack {{\n    background-image: url(\"{s}\");{s}\n{s}}}", .{ img.file, bg_color, styling }) catch return;
                _ = c.gtk_css_provider_load_from_data(provider, css_string.ptr, -1, null);
            },
            .transparent => {},
            .gradient => |g| {
                if (g.toCss(".workview stack")) |css| {
                    defer allocator.free(css);
                    _ = c.gtk_css_provider_load_from_data(provider, css.ptr, -1, null);
                }
            },
        }
    }

    pub fn set(self: Config, term: *c.VteTerminal) void {
        self.colors.set(term);
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
                std.debug.print("Write Error: {}\n", .{write_err});
                return;
            }
        }
    }
};
