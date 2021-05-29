const std = @import("std");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const mem = std.mem;
const meta = std.meta;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

var builder: *c.GtkBuilder = undefined;
var window: *c.GtkWidget = undefined;

const DynamicTitleStyle = enum {
    replaces_title,
    before_title,
    after_title,
    not_displayed,
};

const CursorStyle = enum {
    block,
    i_beam,
    underline,
};

const BackgroundStyle = enum {
    solid_color,
    image,
    transparent,
};

const ImageStyle = enum {
    tiled,
    centered,
    scaled,
    stretched,
};

pub fn run() void {
    builder = c.gtk_builder_new();
    const glade_str = @embedFile("prefs.glade");
    _ = c.gtk_builder_add_from_string(builder, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0));
    window = gtk.builder_get_widget(builder, "prefs_window").?;
    const window_ptr = @ptrCast(*c.GtkWindow, window);
    const custom_command_checkbox = gtk.builder_get_widget(builder, "custom_command_checkbox").?;
    const infinite_scrollback_checkbox = gtk.builder_get_widget(builder, "infinite_scrollback_checkbox").?;
    const system_font_checkbox = gtk.builder_get_widget(builder, "system_font_checkbox").?;
    const background_combobox = gtk.builder_get_widget(builder, "background_combobox").?;
    const close_button = gtk.builder_get_widget(builder, "close_button").?;

    _ = gtk.g_signal_connect(
        custom_command_checkbox,
        "toggled",
        @ptrCast(c.GCallback, toggle_custom_command),
        null,
    );

    _ = gtk.g_signal_connect(
        infinite_scrollback_checkbox,
        "toggled",
        @ptrCast(c.GCallback, toggle_scrollback),
        null,
    );

    _ = gtk.g_signal_connect(
        system_font_checkbox,
        "toggled",
        @ptrCast(c.GCallback, toggle_font),
        null,
    );

    _ = gtk.g_signal_connect(
        background_combobox,
        "changed",
        @ptrCast(c.GCallback, toggle_background),
        null,
    );

    _ = gtk.g_signal_connect(
        close_button,
        "clicked",
        @ptrCast(c.GCallback, save_and_close),
        null,
    );

    c.gtk_widget_show(window);
}

fn toggle_custom_command(custom_command_checkbox: *c.GtkCheckButton) void {
    const entry = gtk.builder_get_widget(builder, "custom_command_entry").?;
    const label = gtk.builder_get_widget(builder, "custom_command_label").?;
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, custom_command_checkbox));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, entry), state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, label), state);
}

fn toggle_scrollback(infinite_scrollback_checkbox: *c.GtkCheckButton) void {
    const label = gtk.builder_get_widget(builder, "scrollback_lines_label").?;
    const spinbox = gtk.builder_get_widget(builder, "scrollback_lines_spinbox").?;
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, infinite_scrollback_checkbox));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, label), !state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, spinbox), !state);
}

fn toggle_font(system_font_checkbox: *c.GtkCheckButton) void {
    const button = gtk.builder_get_widget(builder, "font_chooser_button").?;
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, system_font_checkbox));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, button), !state);
}

fn toggle_background(background_combobox: *c.GtkComboBox) void {
    const image_grid = gtk.builder_get_widget(builder, "background_image_grid").?;
    const opacity_box = gtk.builder_get_widget(builder, "background_style_opacity_box").?;
    const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, background_combobox));
    const style = parse_background_style(id).?;
    switch (style) {
        BackgroundStyle.solid_color => {
            gtk.widget_set_visible(image_grid, false);
            gtk.widget_set_visible(opacity_box, false);
        },
        BackgroundStyle.image => {
            gtk.widget_set_visible(image_grid, true);
            gtk.widget_set_visible(opacity_box, false);
        },
        BackgroundStyle.transparent => {
            gtk.widget_set_visible(image_grid, false);
            gtk.widget_set_visible(opacity_box, true);
        },
    }

}

fn parse_background_style(style: [*c]const u8) ?BackgroundStyle {
    const len = mem.len(style);
    inline for (meta.fields(BackgroundStyle)) |field| {
        if (mem.eql(u8, style[0..len], field.name)) {
            return @field(BackgroundStyle, field.name);
        }
    }
    return null;
}

fn parse_image_style(style: [*c]const u8) ?ImageStyle {
    const len = mem.len(style);
    inline for (std.meta.fields(ImageStyle)) |field| {
        if (std.mem.eql(u8, style[0..len], field.name)) {
            return @field(ImageStyle, field.name);
        }
    }
    return null;
}

fn save_and_close() void {
    c.gtk_window_close(@ptrCast(*c.GtkWindow, window));
    c.gtk_widget_destroy(window);
}
