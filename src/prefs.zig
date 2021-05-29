const std = @import("std");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

var builder: *c.GtkBuilder = undefined;
var window: [*]c.GtkWidget = undefined;

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

const BackgroundImageStyle = enum {
    tiled,
    centered,
    scaled,
    stretched,
};

pub fn run() void {
    builder = c.gtk_builder_new();
    const glade_str = @embedFile("prefs.glade");
    _ = c.gtk_builder_add_from_string(builder, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0));
    window = gtk.builder_get_widget(builder, "prefs_window");
    const window_ptr = @ptrCast(*c.GtkWindow, window);
    const custom_command_checkbox = gtk.builder_get_widget(builder, "custom_command_checkbox");
    const infinite_scrollback_checkbox = gtk.builder_get_widget(builder, "infinite_scrollback_checkbox");
    const background_combobox = gtk.builder_get_widget(builder, "background_combobox");

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
        background_combobox,
        "changed",
        @ptrCast(c.GCallback, toggle_background),
        null,
    );

    c.gtk_widget_show(window);
}

fn toggle_custom_command(custom_command_checkbox: *c.GtkCheckButton) void {
    const custom_command_entry = gtk.builder_get_widget(builder, "custom_command_entry");
    const custom_command_label = gtk.builder_get_widget(builder, "custom_command_label");
    const state = c.gtk_toggle_button_get_active(@ptrCast(*c.GtkToggleButton, custom_command_checkbox));
    c.gtk_widget_set_sensitive(custom_command_entry, state);
    c.gtk_widget_set_sensitive(custom_command_label, state);
}

fn toggle_scrollback(infinite_scrollback_checkbox: *c.GtkCheckButton) void {
    const scrollback_lines_label = gtk.builder_get_widget(builder, "scrollback_lines_label");
    const scrollback_lines_spinbox = gtk.builder_get_widget(builder, "scrollback_lines_spinbox");
    const state = c.gtk_toggle_button_get_active(@ptrCast(*c.GtkToggleButton, infinite_scrollback_checkbox));
    if (state == 0) {
        c.gtk_widget_set_sensitive(scrollback_lines_label, 1);
        c.gtk_widget_set_sensitive(scrollback_lines_spinbox, 1);
    } else {
        c.gtk_widget_set_sensitive(scrollback_lines_label, 0);
        c.gtk_widget_set_sensitive(scrollback_lines_spinbox, 0);
    }
}

fn toggle_background(background_combobox: *c.GtkComboBox) void {
    const background_image_grid = gtk.builder_get_widget(builder, "background_image_grid");
    const background_style_opacity_box = gtk.builder_get_widget(builder, "background_style_opacity_box");
    const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, background_combobox));
    const style = parse_background_style(id);
    switch (style) {
        BackgroundStyle.solid_color => {
            c.gtk_widget_set_visible(background_image_grid, 0);
            c.gtk_widget_set_visible(background_style_opacity_box, 0);
        },
        BackgroundStyle.image => {
            c.gtk_widget_set_visible(background_image_grid, 1);
            c.gtk_widget_set_visible(background_style_opacity_box, 0);
        },
        BackgroundStyle.transparent => {
            c.gtk_widget_set_visible(background_image_grid, 0);
            c.gtk_widget_set_visible(background_style_opacity_box, 1);
        },
    }

}

fn parse_background_style(style: [*c]const u8) BackgroundStyle {
    if (std.mem.eql(u8, style[0..11], "solid_color")) {
        return BackgroundStyle.solid_color;
    } else if (std.mem.eql(u8, style[0..5], "image")) {
        return BackgroundStyle.image;
    } else {
        return BackgroundStyle.transparent;
    }
}
