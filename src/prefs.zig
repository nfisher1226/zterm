const std = @import("std");
const config = @import("config.zig");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

pub const PrefWidgets = struct {
    window: *c.GtkWidget,
    initial_title_entry: *c.GtkWidget,
    dynamic_title_combobox: *c.GtkWidget,
    custom_command_checkbutton: *c.GtkWidget,
    custom_command_label: *c.GtkWidget,
    custom_command_entry: *c.GtkWidget,
    cursor_style_combobox: *c.GtkWidget,
    cursor_blinks_checkbutton: *c.GtkWidget,
    infinite_scrollback_checkbutton: *c.GtkWidget,
    scrollback_lines_label: *c.GtkWidget,
    scrollback_lines_spinbox: *c.GtkWidget,
    text_color: *c.GtkWidget,
    background_color: *c.GtkWidget,
    black_color: *c.GtkWidget,
    red_color: *c.GtkWidget,
    green_color: *c.GtkWidget,
    brown_color: *c.GtkWidget,
    blue_color: *c.GtkWidget,
    magenta_color: *c.GtkWidget,
    cyan_color: *c.GtkWidget,
    light_grey_color: *c.GtkWidget,
    dark_grey_color: *c.GtkWidget,
    light_red_color: *c.GtkWidget,
    light_green_color: *c.GtkWidget,
    yellow_color: *c.GtkWidget,
    light_blue_color: *c.GtkWidget,
    light_magenta_color: *c.GtkWidget,
    light_cyan_color: *c.GtkWidget,
    white_color: *c.GtkWidget,
    system_font_checkbutton: *c.GtkWidget,
    font_chooser_button: *c.GtkWidget,
    background_style_combobox: *c.GtkWidget,
    background_image_grid: *c.GtkWidget,
    background_image_file_button: *c.GtkWidget,
    background_image_style_combobox: *c.GtkWidget,
    background_style_opacity_box: *c.GtkWidget,
    background_style_opacity_scale: *c.GtkWidget,
    close_button: *c.GtkWidget,

    fn init(b: *c.GtkBuilder) PrefWidgets {
        return PrefWidgets {
            .window = gtk.builder_get_widget(builder, "window").?,
            .initial_title_entry = gtk.builder_get_widget(builder, "initial_title_entry").?,
            .dynamic_title_combobox = gtk.builder_get_widget(builder, "dynamic_title_combobox").?,
            .custom_command_checkbutton = gtk.builder_get_widget(builder, "custom_command_checkbutton").?,
            .custom_command_label = gtk.builder_get_widget(builder, "custom_command_label").?,
            .custom_command_entry = gtk.builder_get_widget(builder, "custom_command_entry").?,
            .cursor_style_combobox = gtk.builder_get_widget(builder, "cursor_style_combobox").?,
            .cursor_blinks_checkbutton = gtk.builder_get_widget(builder, "cursor_blinks_checkbutton").?,
            .infinite_scrollback_checkbutton = gtk.builder_get_widget(builder, "infinite_scrollback_checkbutton").?,
            .scrollback_lines_label = gtk.builder_get_widget(builder, "scrollback_lines_label").?,
            .scrollback_lines_spinbox = gtk.builder_get_widget(builder, "scrollback_lines_spinbox").?,
            .text_color = gtk.builder_get_widget(builder, "text_color").?,
            .background_color = gtk.builder_get_widget(builder, "background_color").?,
            .black_color = gtk.builder_get_widget(builder, "black_color").?,
            .red_color = gtk.builder_get_widget(builder, "red_color").?,
            .green_color = gtk.builder_get_widget(builder, "green_color").?,
            .brown_color = gtk.builder_get_widget(builder, "brown_color").?,
            .blue_color = gtk.builder_get_widget(builder, "blue_color").?,
            .magenta_color = gtk.builder_get_widget(builder, "magenta_color").?,
            .cyan_color = gtk.builder_get_widget(builder, "cyan_color").?,
            .light_grey_color = gtk.builder_get_widget(builder, "light_grey_color").?,
            .dark_grey_color = gtk.builder_get_widget(builder, "dark_grey_color").?,
            .light_red_color = gtk.builder_get_widget(builder, "light_red_color").?,
            .light_green_color = gtk.builder_get_widget(builder, "light_green_color").?,
            .yellow_color = gtk.builder_get_widget(builder, "yellow_color").?,
            .light_blue_color = gtk.builder_get_widget(builder, "light_blue_color").?,
            .light_magenta_color = gtk.builder_get_widget(builder, "light_magenta_color").?,
            .light_cyan_color = gtk.builder_get_widget(builder, "light_cyan_color").?,
            .white_color = gtk.builder_get_widget(builder, "white_color").?,
            .system_font_checkbutton = gtk.builder_get_widget(builder, "system_font_checkbutton").?,
            .font_chooser_button = gtk.builder_get_widget(builder, "font_chooser_button").?,
            .background_style_combobox = gtk.builder_get_widget(builder, "background_style_combobox").?,
            .background_image_grid = gtk.builder_get_widget(builder, "background_image_grid").?,
            .background_image_file_button = gtk.builder_get_widget(builder, "background_image_file_button").?,
            .background_image_style_combobox = gtk.builder_get_widget(builder, "background_image_style_combobox").?,
            .background_style_opacity_box = gtk.builder_get_widget(builder, "background_style_opacity_box").?,
            .background_style_opacity_scale = gtk.builder_get_widget(builder, "background_style_opacity_scale").?,
            .close_button = gtk.builder_get_widget(builder, "close_button").?,
        };
    }

    fn get_colors(self: PrefWidgets) config.Colors {
        //return config.Colors {
        //    .text_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.text_color)),
        //    .background_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.background_color)),
        //    .black_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.black_color)),
        //    .red_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.red_color)),
        //    .green_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.green_color)),
        //    .brown_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.brown_color)),
        //    .blue_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.blue_color)),
        //    .magenta_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.magenta_color)),
        //    .cyan_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.cyan_color)),
        //    .light_grey_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.light_grey_color)),
        //    .dark_grey_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.dark_grey_color)),
        //    .light_red_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.light_red_color)),
        //    .light_green_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.light_green_color)),
        //    .yellow_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.yellow_color)),
        //    .light_blue_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.light_blue_color)),
        //    .light_magenta_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.light_magenta_color)),
        //    .light_cyan_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.light_cyan_color)),
        //    .white_color = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, self.white_color)),
        //};
        var colors = config.Colors.default();
        inline for (std.meta.fields(config.Colors)) |color| {
            const widget = @field(self, color.name);
            //inline for (std.meta.fields(PrefWidgets)) |w| {
            //    if (mem.eql(u8, w.name, color.name)) {
            //        widget = @field(self, w.name);
            //    }
            //}
            const value = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, widget));
            @field(colors, color.name) = value;
        }
        return colors;
    }
};

var builder: *c.GtkBuilder = undefined;
var widgets: PrefWidgets = undefined;

pub fn run() void {
    builder = c.gtk_builder_new();
    const glade_str = @embedFile("prefs.glade");
    _ = c.gtk_builder_add_from_string(builder, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0));
    widgets = PrefWidgets.init(builder);

    _ = gtk.g_signal_connect(
        widgets.custom_command_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_custom_command),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.infinite_scrollback_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_scrollback),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.system_font_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_font),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.background_style_combobox,
        "changed",
        @ptrCast(c.GCallback, toggle_background),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.close_button,
        "clicked",
        @ptrCast(c.GCallback, save_and_close),
        null,
    );

    c.gtk_widget_show(widgets.window);
}

fn toggle_custom_command(custom_command_checkbutton: *c.GtkCheckButton, data: c.gpointer) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, custom_command_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.custom_command_entry), state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.custom_command_label), state);
}

fn toggle_scrollback(infinite_scrollback_checkbutton: *c.GtkCheckButton, data: c.gpointer) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, infinite_scrollback_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.scrollback_lines_label), !state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.scrollback_lines_spinbox), !state);
}

fn toggle_font(system_font_checkbutton: *c.GtkCheckButton, data: c.gpointer) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, system_font_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.font_chooser_button), !state);
}

fn toggle_background(background_combobox: *c.GtkComboBox, data: c.gpointer) void {
    const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, background_combobox));
    const style = parse_background_style(id).?;
    switch (style) {
        config.BackgroundStyle.solid_color => {
            gtk.widget_set_visible(widgets.background_image_grid, false);
            gtk.widget_set_visible(widgets.background_style_opacity_box, false);
        },
        config.BackgroundStyle.image => {
            gtk.widget_set_visible(widgets.background_image_grid, true);
            gtk.widget_set_visible(widgets.background_style_opacity_box, false);
        },
        config.BackgroundStyle.transparent => {
            gtk.widget_set_visible(widgets.background_image_grid, false);
            gtk.widget_set_visible(widgets.background_style_opacity_box, true);
        },
    }

}

fn parse_background_style(style: [*c]const u8) ?config.BackgroundStyle {
    const len = mem.len(style);
    inline for (meta.fields(config.BackgroundStyle)) |field| {
        if (mem.eql(u8, style[0..len], field.name)) {
            return @field(config.BackgroundStyle, field.name);
        }
    }
    return null;
}

fn parse_image_style(style: [*c]const u8) ?config.ImageStyle {
    const len = mem.len(style);
    inline for (meta.fields(config.ImageStyle)) |field| {
        if (mem.eql(u8, style[0..len], field.name)) {
            return @field(config.ImageStyle, field.name);
        }
    }
    return null;
}

fn save_and_close(b: *c.GtkButton, data: c.gpointer) void {
    var conf = config.Config.default();
    conf.colors = widgets.get_colors();
    std.debug.print("Config: {s}\n", .{conf});
    c.gtk_window_close(@ptrCast(*c.GtkWindow, widgets.window));
    c.gtk_widget_destroy(widgets.window);
}
