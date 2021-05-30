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

pub const RGBColor = struct {
    red: u64,
    green: u64,
    blue: u64,
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
};

pub const Cursor = struct {
    cursor_style: CursorStyle,
    cursor_blinks: bool,
};

pub const Background = struct {
    background_style: BackgroundStyle,
    background_image_file: ?[]const u8,
    background_image_style: ?ImageStyle,
    background_opacity: ?u64,
};

pub const Config = struct {
    initial_title: []const u8,
    dynamic_title_style: DynamicTitleStyle,
    custom_command_use: bool,
    custom_command: []const u8,
    infinite_scrollback: bool,
    scrollback_lines: u64,
    system_font_use: bool,
    font: []const u8,
    background: Background,
    colors: Colors,
    cursor: Cursor,
};
