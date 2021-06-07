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

    pub fn default() DynamicTitleStyle {
        return DynamicTitleStyle.after_title;
    }
};

pub const CustomCommandType = enum {
    command,
    none,
};

pub const CustomCommand = union(CustomCommandType) {
    command: []const u8,
    none: void,

    pub fn default() CustomCommand {
        return CustomCommand.none;
    }
};

pub const ScrollbackType = enum {
    finite,
    infinite,
};

pub const Scrollback = union(ScrollbackType) {
    finite: u64,
    infinite: void,

    pub fn default() Scrollback {
        return Scrollback{ .finite = 500 };
    }
};

pub const FontType = enum {
    system,
    custom,
};

pub const Font = union(FontType) {
    system: void,
    custom: []const u8,

    pub fn default() Font {
        return Font.system;
    }
};

pub const CursorStyle = enum {
    block,
    i_beam,
    underline,

    pub fn default() CursorStyle {
        return CursorStyle.block;
    }
};

pub const Cursor = struct {
    cursor_style: CursorStyle,
    cursor_blinks: bool,

    pub fn default() Cursor {
        return Cursor {
            .cursor_style = CursorStyle.default(),
            .cursor_blinks = true,
        };
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
            .red = @floatToInt(u8, math.round(rgba.red * 255.0)),
            .green = @floatToInt(u8, math.round(rgba.green * 255.0)),
            .blue = @floatToInt(u8, math.round(rgba.blue * 255.0)),
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
        return widgets.get_colors();
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
        return Config {
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
};
