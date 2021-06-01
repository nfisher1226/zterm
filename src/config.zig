const std = @import("std");
const gui = @import("gui.zig");
const gtk = @import("gtk.zig");
const prefs = @import("prefs.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const fmt = std.fmt;
const math = std.math;

pub const DynamicTitleStyle = enum {
    replaces_title,
    before_title,
    after_title,
    not_displayed,
};

pub const CursorStyle = enum {
    block,
    i_beam,
    underline,
};

pub const BackgroundStyle = enum {
    solid_color,
    image,
    transparent,
};

pub const ImageStyle = enum {
    tiled,
    centered,
    scaled,
    stretched,
};

pub const BackgroundImage = struct {
    file: []const u8,
    style: ImageStyle,
};

pub const BackgroundValue = union(BackgroundStyle) {
    solid_color: void,
    image: BackgroundImage,
    transparent: f64,
};

pub const Background = struct {
    background_style: BackgroundStyle,
    background_value: BackgroundValue,

    pub fn default() Background {
        return Background {
            .background_style = BackgroundStyle.solid_color,
            .background_value = BackgroundValue.solid_color,
        };
    }
};

pub const RGBColor = struct {
    red: u64,
    green: u64,
    blue: u64,

    pub fn default() RGBColor {
        return RGBColor {
            .red = 0,
            .blue = 0,
            .green = 0,
        };
    }

    pub fn from_widget(button: *c.GtkColorButton) RGBColor {
        var rgba: c.GdkRGBA = undefined;
        _ = c.gtk_color_button_get_rgba(button, &rgba);
        return RGBColor {
            .red = @floatToInt(u64, math.round(rgba.red * 255.0)),
            .green = @floatToInt(u64, math.round(rgba.green * 255.0)),
            .blue = @floatToInt(u64, math.round(rgba.blue * 255.0)),
        };
    }

    pub fn to_hex(self: RGBColor) ?[]const u8 {
        const buf = fmt.allocPrintZ(
            allocator, "#{X}{X}{X}",
            .{self.red, self.green, self.blue}
        ) catch |e| { return null; };
        return buf;
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
        return Colors {
            .text_color = RGBColor{ .red = 255, .green = 255, .blue = 255 },
            .background_color = RGBColor{ .red = 0, .green = 0, .blue = 0 },
            .black_color = RGBColor{ .red = 0, .green = 0, .blue = 0 },
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
            .yellow_color = RGBColor{ .red = 255, .green = 255, .blue = 85 },
            .light_blue_color = RGBColor{ .red = 85, .green = 85, .blue = 255 },
            .light_magenta_color = RGBColor{ .red = 255, .green = 85, .blue = 255 },
            .light_cyan_color = RGBColor{ .red = 85, .green = 255, .blue = 255 },
            .white_color = RGBColor{ .red = 255, .green = 255, .blue = 255 },
        };
    }

    pub fn from_pref_widgets(widgets: prefs.PrefWidgets) Colors {
    }
};

pub const Cursor = struct {
    cursor_style: CursorStyle,
    cursor_blinks: bool,

    pub fn default() Cursor {
        return Cursor {
            .cursor_style = CursorStyle.block,
            .cursor_blinks = true,
        };
    }
};

pub const Config = struct {
    initial_title: []const u8,
    dynamic_title_style: DynamicTitleStyle,
    custom_command_use: bool,
    custom_command: ?[]const u8,
    infinite_scrollback: bool,
    scrollback_lines: ?u64,
    system_font_use: bool,
    font: ?[]const u8,
    background: Background,
    colors: Colors,
    cursor: Cursor,

    pub fn default() Config {
        return Config {
            .initial_title = "Zterm",
            .dynamic_title_style = DynamicTitleStyle.after_title,
            .custom_command_use = false,
            .custom_command = null,
            .infinite_scrollback = false,
            .scrollback_lines = 500,
            .system_font_use = true,
            .font = null,
            .background = Background.default(),
            .colors = Colors.default(),
            .cursor = Cursor.default(),
        };
    }
};
